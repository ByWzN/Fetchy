package com.example.fetchy.quickfetch

import android.app.Activity
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.example.fetchy.domains.WatchedDomainStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// The Quick Fetch MethodChannel. Deliberately separate from the downloader
/// channel so the stable download engine keeps its own contract untouched.
///
/// Flutter owns the settings UI and navigation; this layer owns Android
/// permission state, capability reporting, and the single clipboard read that
/// happens after the user taps a quick action.
class QuickFetchChannelHandler(
    private val appContext: Context,
) : MethodChannel.MethodCallHandler {

    /// Set while an Activity is attached. Required for permission requests and
    /// for opening system settings screens; never retained beyond the Activity.
    var activity: Activity? = null

    private val notifier = QuickFetchNotifier(appContext)
    private val overlay = QuickFetchOverlay(appContext)
    private val watchedDomains = WatchedDomainStore(appContext)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_CAPABILITIES -> result.success(capabilities())

            METHOD_SET_ENABLED -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val style = QuickFetchActionStyle.fromName(
                    call.argument<String>("actionStyle"),
                )
                QuickFetchPrefs.setEnabled(appContext, enabled)
                QuickFetchPrefs.setActionStyle(appContext, style)
                if (!enabled) {
                    // Turning the feature off tears down every surface and
                    // forgets any pending candidate immediately.
                    QuickFetchPresenter.clear(appContext)
                }
                result.success(capabilities())
            }

            METHOD_SET_ACTION_STYLE -> {
                val style = QuickFetchActionStyle.fromName(
                    call.argument<String>("actionStyle"),
                )
                QuickFetchPrefs.setActionStyle(appContext, style)
                // Drop any surface belonging to the previous style.
                QuickFetchPresenter.clear(appContext)
                result.success(capabilities())
            }

            METHOD_REQUEST_NOTIFICATION_PERMISSION ->
                result.success(requestNotificationPermission())

            METHOD_OPEN_OVERLAY_SETTINGS -> result.success(openOverlaySettings())

            METHOD_OPEN_NOTIFICATION_SETTINGS ->
                result.success(openNotificationSettings())

            METHOD_OPEN_ACCESSIBILITY_SETTINGS ->
                result.success(openAccessibilitySettings())

            METHOD_DISMISS_PENDING -> {
                QuickFetchPresenter.clear(appContext)
                result.success(null)
            }

            METHOD_CONSUME_CLIPBOARD_LINK -> result.success(consumeClipboardLink())

            METHOD_GET_WATCHED_DOMAINS_TEXT -> result.success(watchedDomains.rawText())

            METHOD_SET_WATCHED_DOMAINS_TEXT -> {
                val text = call.argument<String>("text").orEmpty()
                result.success(watchedDomains.setFromText(text))
            }

            METHOD_RESET_WATCHED_DOMAINS -> result.success(watchedDomains.resetToDefaults())

            METHOD_IS_WATCHED_URL -> {
                val url = call.argument<String>("url")
                result.success(
                    url != null && QuickFetchSupportedSites.isWatchedUrl(url, appContext)
                )
            }

            else -> result.notImplemented()
        }
    }

    // --------------------------------------------------------- capabilities

    /// One honest snapshot of what this device actually allows, queried live
    /// rather than inferred from stored preferences.
    fun capabilities(): Map<String, Any?> {
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "enabled" to QuickFetchPrefs.isEnabled(appContext),
            "actionStyle" to QuickFetchActionStyle.toName(
                QuickFetchPrefs.actionStyle(appContext),
            ),
            // Detection is live only when the user switched the accessibility
            // service on AND the platform has actually bound it.
            "accessibilityEnabled" to
                QuickFetchAccessibilityService.isEnabledInSystemSettings(appContext),
            "accessibilityConnected" to QuickFetchAccessibilityService.isConnected,
            "canPostNotifications" to notifier.areNotificationsAllowed(),
            "needsNotificationPermission" to
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU),
            "canDrawOverlays" to overlay.canDrawOverlays(),
            "hasPendingCandidate" to (QuickFetchPresenter.pending != null),
        )
    }

    // ------------------------------------------------------------ clipboard

    /// The one and only clipboard read in Quick Fetch.
    ///
    /// Called from Dart after MainActivity has reported window focus, which is
    /// the condition Android requires for getPrimaryClip() to return anything
    /// on API 29+. Returns a supported URL, or null when the clipboard holds
    /// nothing usable — in which case the pending candidate is cleared so a
    /// false positive cannot linger.
    private fun consumeClipboardLink(): String? {
        val link = try {
            val manager = appContext.getSystemService(Context.CLIPBOARD_SERVICE)
                as? ClipboardManager ?: run {
                    Log.d(TAG, "consumeClipboardLink: no ClipboardManager")
                    return null.also { QuickFetchPresenter.clear(appContext) }
                }
            val clip = manager.primaryClip ?: run {
                Log.d(TAG, "consumeClipboardLink: getPrimaryClip() returned null")
                return null.also { QuickFetchPresenter.clear(appContext) }
            }
            if (clip.itemCount == 0) {
                Log.d(TAG, "consumeClipboardLink: clip has no items")
                return null.also { QuickFetchPresenter.clear(appContext) }
            }

            // Plain text only: never coerce a URI/intent clip into text.
            val text = clip.getItemAt(0)?.text?.toString()
            QuickFetchSupportedSites.candidateFrom(text, appContext)
        } catch (throwable: Throwable) {
            // A denied read surfaces as null or a SecurityException; treat both
            // as "nothing to fetch" rather than failing loudly.
            Log.d(TAG, "consumeClipboardLink: clipboard read threw", throwable)
            null
        }

        // Consumed or rejected, the candidate has served its purpose.
        QuickFetchPresenter.clear(appContext)

        return link?.url
    }

    // ---------------------------------------------------------- permissions

    /// Fires the POST_NOTIFICATIONS request. The grant is not plumbed back
    /// through a callback on purpose: Settings re-queries [capabilities] on
    /// resume, so the displayed state reflects reality, not an assumption.
    private fun requestNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        if (notifier.areNotificationsAllowed()) return true

        val host = activity ?: return false
        return try {
            host.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_POST_NOTIFICATIONS,
            )
            true
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not request the notification permission", throwable)
            false
        }
    }

    private fun openOverlaySettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true

        return launch(
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + appContext.packageName),
            ),
        )
    }

    private fun openNotificationSettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, appContext.packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:" + appContext.packageName)
            }
        }
        return launch(intent)
    }

    private fun openAccessibilitySettings(): Boolean {
        // Attempt 1: open the specific detail page for Fetchy's accessibility
        // service. This is supported on AOSP and most OEMs (API 21+) but is
        // NOT a stable public contract, so we must verify the intent resolves
        // before launching it to avoid a crash.
        //
        // The component name must match the AndroidManifest declaration
        // exactly: "<package>/<fully-qualified-class-name>".
        val componentName = "${appContext.packageName}/${QuickFetchAccessibilityService::class.java.name}"
        val detailIntent = Intent("com.android.settings.ACCESSIBILITY_SERVICE_DETAIL").apply {
            putExtra(
                "android.intent.extra.component_name",
                componentName,
            )
            // Required on some OEMs so the settings app treats this as a
            // proper navigation request rather than a general open.
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val resolves = try {
            val pm = appContext.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.resolveActivity(
                    detailIntent,
                    android.content.pm.PackageManager.ResolveInfoFlags.of(0)
                ) != null
            } else {
                @Suppress("DEPRECATION")
                pm.resolveActivity(detailIntent, 0) != null
            }
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not resolve accessibility detail intent", throwable)
            false
        }

        if (resolves && launch(detailIntent)) {
            Log.d(TAG, "Opened accessibility service detail for $componentName")
            return true
        }

        // Attempt 2: generic accessibility settings page.
        Log.d(TAG, "Falling back to generic accessibility settings (detail intent unavailable on this device)")
        return launch(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private fun launch(intent: Intent): Boolean {
        return try {
            val host = activity
            if (host != null) {
                host.startActivity(intent)
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
            }
            true
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not open the requested system settings screen", throwable)
            false
        }
    }

    companion object {
        private const val TAG = "QuickFetchChannel"

        /// Distinct from the downloader channel so the two never collide.
        const val CHANNEL = "app.fetchy/quickfetch"

        const val REQUEST_POST_NOTIFICATIONS = 4301

        private const val METHOD_GET_CAPABILITIES = "getCapabilities"
        private const val METHOD_SET_ENABLED = "setEnabled"
        private const val METHOD_SET_ACTION_STYLE = "setActionStyle"
        private const val METHOD_REQUEST_NOTIFICATION_PERMISSION =
            "requestNotificationPermission"
        private const val METHOD_OPEN_OVERLAY_SETTINGS = "openOverlaySettings"
        private const val METHOD_OPEN_NOTIFICATION_SETTINGS =
            "openNotificationSettings"
        private const val METHOD_OPEN_ACCESSIBILITY_SETTINGS =
            "openAccessibilitySettings"
        private const val METHOD_DISMISS_PENDING = "dismissPending"
        private const val METHOD_CONSUME_CLIPBOARD_LINK = "consumeClipboardLink"

        /// Link Auto-Detect: the single effective watched-domain list (see
        /// WatchedDomainStore) — seeded from built-in defaults, then fully
        /// user-editable as free-form, one-domain-per-line text.
        private const val METHOD_GET_WATCHED_DOMAINS_TEXT = "getWatchedDomainsText"
        private const val METHOD_SET_WATCHED_DOMAINS_TEXT = "setWatchedDomainsText"
        private const val METHOD_RESET_WATCHED_DOMAINS = "resetWatchedDomainsToDefault"
        private const val METHOD_IS_WATCHED_URL = "isWatchedUrl"

        /// Invoked on Dart once MainActivity is focused after a quick-action
        /// tap. Dart then calls back for the clipboard read.
        const val METHOD_ON_QUICK_FETCH_TAP = "onQuickFetchTap"
    }
}

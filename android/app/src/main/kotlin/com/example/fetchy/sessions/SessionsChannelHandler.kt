// android/app/src/main/kotlin/com/example/fetchy/sessions/SessionsChannelHandler.kt
package com.example.fetchy.sessions

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.browser.customtabs.CustomTabsClient
import androidx.browser.customtabs.CustomTabsIntent
import com.example.fetchy.domains.DomainNormalizer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Backs the "app.fetchy/sessions" channel: Connected Accounts/Sessions.
///
/// Advanced (cookies.txt import) always produces a usable Fetchy session.
/// Easy Connect's mechanism is chosen per platform based on real-device
/// evidence, not a single uniform approach:
///
///  - YouTube, Instagram, TikTok: [SessionLoginActivity], an embedded
///    WebView. Confirmed working by real-device testing for YouTube and
///    Instagram; TikTok additionally needed proper handling of its
///    non-http(s) login redirect (see that class). This path genuinely
///    captures a usable session via [android.webkit.CookieManager].
///  - X: a Custom Tab (real browser). X actively rejects embedded-browser
///    login ("Sorry, you are not allowed to log in at this time"), which
///    mirrors Google's own documented policy of blocking OAuth-style
///    sign-in inside WebViews specifically to stop credential theft via
///    injected JavaScript — a deliberate security control, not a bug.
///    Fetchy does not attempt to defeat it (e.g. by spoofing the
///    WebView's User-Agent), so a Custom Tab is used instead; it cannot
///    hand a session back to Fetchy (a Custom Tab runs in the browser's
///    own sandboxed process), and this handler does not claim otherwise.
///
/// Expert (root-assisted browser import) is reported unavailable — see
/// [capabilities]. Session cookies are wired into actual extraction/
/// download requests in [com.example.fetchy.EngineChannelHandler], not
/// here; this handler only manages the encrypted local store, the system
/// file picker, the Easy Connect launch, and session export.
class SessionsChannelHandler(
    private val appContext: Context,
) : MethodChannel.MethodCallHandler {

    var activity: Activity? = null

    private val store = PlatformSessionStore(appContext)
    private val customCookieStore = CustomCookieStore(appContext)

    private var pendingImportResult: MethodChannel.Result? = null
    private var pendingImportPlatform: SessionPlatform? = null

    private var pendingCustomImportResult: MethodChannel.Result? = null
    private var pendingCustomImportDomain: String? = null

    private var pendingEasyConnectResult: MethodChannel.Result? = null
    private var pendingEasyConnectPlatform: SessionPlatform? = null

    private var pendingExportResult: MethodChannel.Result? = null
    private var pendingExportPlatform: SessionPlatform? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_CAPABILITIES -> result.success(capabilities())

            METHOD_LIST_SESSIONS ->
                result.success(store.listSessions().map(::toMap))

            METHOD_PICK_AND_IMPORT_COOKIES_FILE -> {
                val platform = platformArgOrError(call, result) ?: return
                beginPickCookiesFile(platform, result)
            }

            METHOD_OPEN_BROWSER_LOGIN -> {
                val platform = platformArgOrError(call, result) ?: return
                // X actively rejects embedded-browser login; every other
                // platform is confirmed working via the WebView flow. See
                // the class doc comment for why this split exists.
                if (platform == SessionPlatform.X) {
                    openCustomTabLogin(platform, result)
                } else {
                    beginWebViewLogin(platform, result)
                }
            }

            METHOD_RECORD_VALIDATION_RESULT -> {
                val platform = platformArgOrError(call, result) ?: return
                val statusName = call.argument<String>("status")
                val status = statusName?.let { runCatching { SessionStatus.valueOf(it) }.getOrNull() }
                if (status == null) {
                    result.error(ERROR_UNKNOWN_STATUS, "Unknown status: $statusName", null)
                    return
                }
                result.success(toMap(store.recordValidation(platform, status)))
            }

            METHOD_EXPORT_SESSION -> {
                val platform = platformArgOrError(call, result) ?: return
                beginExportSession(platform, result)
            }

            METHOD_REMOVE_SESSION -> {
                val platform = platformArgOrError(call, result) ?: return
                store.removeSession(platform)
                result.success(null)
            }

            // --------------------------------- General Cookie Manager (custom sites)

            METHOD_LIST_CUSTOM_COOKIE_SITES ->
                result.success(customCookieStore.listRecords().map(::toCustomMap))

            METHOD_PICK_AND_IMPORT_CUSTOM_COOKIES_FILE -> {
                val domain = domainArgOrError(call, result) ?: return
                beginPickCustomCookiesFile(domain, result)
            }

            METHOD_IMPORT_CUSTOM_COOKIES_TEXT -> {
                val domain = domainArgOrError(call, result) ?: return
                val text = call.argument<String>("cookiesText").orEmpty()
                try {
                    result.success(toCustomMap(customCookieStore.importCookies(domain, text)))
                } catch (invalid: InvalidCookieFileException) {
                    result.error(ERROR_INVALID_COOKIE_FILE, invalid.message, null)
                } catch (throwable: Throwable) {
                    Log.e(TAG, "custom cookie text import failed", throwable)
                    result.error(
                        ERROR_IMPORT_FAILED,
                        throwable.message ?: "Couldn't import those cookies.",
                        null,
                    )
                }
            }

            METHOD_REMOVE_CUSTOM_COOKIE_SITE -> {
                val domain = domainArgOrError(call, result) ?: return
                customCookieStore.removeDomain(domain)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /// Handles Activity results from the SAF file picker, the WebView Easy
    /// Connect flow (YouTube/Instagram/TikTok), and the SAF "create
    /// document" export flow. (X's Custom Tab path has no result to wait
    /// for — see [openCustomTabLogin].) Returns true when it consumed the
    /// result.
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_PICK_COOKIES_FILE -> {
                handlePickCookiesResult(resultCode, data)
                true
            }
            REQUEST_CODE_EASY_CONNECT -> {
                handleEasyConnectResult(resultCode, data)
                true
            }
            REQUEST_CODE_EXPORT_SESSION -> {
                handleExportResult(resultCode, data)
                true
            }
            REQUEST_CODE_PICK_CUSTOM_COOKIES_FILE -> {
                handlePickCustomCookiesResult(resultCode, data)
                true
            }
            else -> false
        }
    }

    private fun handlePickCustomCookiesResult(resultCode: Int, data: Intent?) {
        val pendingResult = pendingCustomImportResult
        val domain = pendingCustomImportDomain
        pendingCustomImportResult = null
        pendingCustomImportDomain = null

        if (pendingResult == null || domain == null) return

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingResult.success(null) // user canceled the picker
            return
        }

        try {
            val text = readTextCapped(data.data!!)
            val record = customCookieStore.importCookies(domain, text)
            pendingResult.success(toCustomMap(record))
        } catch (invalid: InvalidCookieFileException) {
            pendingResult.error(ERROR_INVALID_COOKIE_FILE, invalid.message, null)
        } catch (throwable: Throwable) {
            Log.e(TAG, "custom cookie file import failed", throwable)
            pendingResult.error(
                ERROR_IMPORT_FAILED,
                throwable.message ?: "Couldn't read that file.",
                null,
            )
        }
    }

    private fun beginPickCustomCookiesFile(domain: String, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(ERROR_NO_ACTIVITY, "Fetchy isn't in the foreground.", null)
            return
        }

        pendingCustomImportResult = result
        pendingCustomImportDomain = domain

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }

        try {
            currentActivity.startActivityForResult(intent, REQUEST_CODE_PICK_CUSTOM_COOKIES_FILE)
        } catch (noPicker: android.content.ActivityNotFoundException) {
            pendingCustomImportResult = null
            pendingCustomImportDomain = null
            result.error(ERROR_NO_FILE_PICKER, "No file picker is available on this device.", null)
        }
    }

    /// Reads and normalizes the "domain" argument (free-form user text —
    /// "example.com", "https://example.com/path", etc.) via
    /// [DomainNormalizer]. Errors out rather than silently falling back to
    /// something else when the input doesn't resemble a real domain.
    private fun domainArgOrError(call: MethodCall, result: MethodChannel.Result): String? {
        val raw = call.argument<String>("domain")
        val normalized = raw?.let(DomainNormalizer::normalize)
        if (normalized == null) {
            result.error(ERROR_INVALID_DOMAIN, "That doesn't look like a website domain.", null)
            return null
        }
        return normalized
    }

    private fun toCustomMap(record: CustomCookieRecord): Map<String, Any?> = mapOf(
        "domain" to record.domain,
        "createdAtMillis" to record.createdAtMillis,
        "metadata" to record.metadata,
    )

    private fun handlePickCookiesResult(resultCode: Int, data: Intent?) {
        val pendingResult = pendingImportResult
        val platform = pendingImportPlatform
        pendingImportResult = null
        pendingImportPlatform = null

        if (pendingResult == null || platform == null) return

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingResult.success(null) // user canceled the picker
            return
        }

        try {
            val text = readTextCapped(data.data!!)
            val record = store.importCookies(platform, text)
            pendingResult.success(toMap(record))
        } catch (invalid: InvalidCookieFileException) {
            pendingResult.error(ERROR_INVALID_COOKIE_FILE, invalid.message, null)
        } catch (throwable: Throwable) {
            Log.e(TAG, "cookie import failed", throwable)
            pendingResult.error(
                ERROR_IMPORT_FAILED,
                throwable.message ?: "Couldn't read that file.",
                null,
            )
        }
    }

    /// [SessionLoginActivity] performs the import itself (see that class)
    /// so the captured cookies never round-trip through an Intent extra.
    /// This only has to re-read the now-current session and report it —
    /// null means the WebView flow was closed before a usable session was
    /// captured (canceled, or the platform's cookies never appeared).
    private fun handleEasyConnectResult(resultCode: Int, data: Intent?) {
        val pendingResult = pendingEasyConnectResult
        val platform = pendingEasyConnectPlatform
        pendingEasyConnectResult = null
        pendingEasyConnectPlatform = null

        if (pendingResult == null || platform == null) return

        if (resultCode != Activity.RESULT_OK) {
            pendingResult.success(null)
            return
        }

        pendingResult.success(toMap(store.getSession(platform)))
    }

    private fun handleExportResult(resultCode: Int, data: Intent?) {
        val pendingResult = pendingExportResult
        val platform = pendingExportPlatform
        pendingExportResult = null
        pendingExportPlatform = null

        if (pendingResult == null || platform == null) return

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingResult.success(false) // user canceled
            return
        }

        val text = store.exportCookiesText(platform)
        if (text == null) {
            pendingResult.error(ERROR_UNKNOWN_PLATFORM, "No session to export.", null)
            return
        }

        try {
            appContext.contentResolver.openOutputStream(data.data!!)?.use { stream ->
                stream.write(text.toByteArray(Charsets.UTF_8))
            }
            pendingResult.success(true)
        } catch (throwable: Throwable) {
            Log.e(TAG, "session export failed", throwable)
            pendingResult.error(ERROR_IMPORT_FAILED, "Couldn't write that file.", null)
        }
    }

    private fun beginPickCookiesFile(platform: SessionPlatform, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(ERROR_NO_ACTIVITY, "Fetchy isn't in the foreground.", null)
            return
        }

        pendingImportResult = result
        pendingImportPlatform = platform

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }

        try {
            currentActivity.startActivityForResult(intent, REQUEST_CODE_PICK_COOKIES_FILE)
        } catch (noPicker: android.content.ActivityNotFoundException) {
            pendingImportResult = null
            pendingImportPlatform = null
            result.error(ERROR_NO_FILE_PICKER, "No file picker is available on this device.", null)
        }
    }

    /// Launches [SessionLoginActivity] (the WebView flow) for [platform].
    /// Used for YouTube, Instagram, and TikTok — see the class doc comment
    /// for why X uses [openCustomTabLogin] instead.
    private fun beginWebViewLogin(platform: SessionPlatform, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(ERROR_NO_ACTIVITY, "Fetchy isn't in the foreground.", null)
            return
        }

        pendingEasyConnectResult = result
        pendingEasyConnectPlatform = platform

        val intent = Intent(currentActivity, SessionLoginActivity::class.java).apply {
            putExtra(SessionLoginActivity.EXTRA_PLATFORM_ID, platform.id)
        }
        currentActivity.startActivityForResult(intent, REQUEST_CODE_EASY_CONNECT)
    }

    /// Opens [platform]'s real login page in a Custom Tab — a real browser
    /// context, not an embedded WebView (see [SessionLoginTargets] for why
    /// that switch was necessary). This is a fire-and-forget launch: a
    /// Custom Tab has no result channel back to the launching app the way
    /// `startActivityForResult` does for a normal Activity, and Fetchy does
    /// not attempt to manufacture one (no bound `CustomTabsServiceConnection`
    /// snooping on navigation events). The method call resolves as soon as
    /// the browser opens — it does NOT mean, and must never be interpreted
    /// to mean, that Fetchy received a usable session. The Dart side shows
    /// the honest "use Advanced to bring your session in" guidance after
    /// this returns, regardless of what happens in the browser afterward.
    ///
    /// Two things keep this a genuine *browser* experience rather than a
    /// hand-off to whatever app claims an Android App Link for the
    /// destination domain (real-device testing showed YouTube's own app
    /// intercepting its login redirect this way):
    ///
    ///  - [CustomTabsIntent.setAlwaysUseBrowserUI] — an official, documented
    ///    androidx.browser flag whose entire purpose is telling Android's
    ///    resolver not to hand this navigation to an App-Link-verified
    ///    native app. This is not a workaround; it is the API Google ships
    ///    specifically for browser-based auth flows like this one.
    ///  - [CustomTabsClient.getPackageName] — resolves a real, installed
    ///    browser that actually supports Custom Tabs (preferring the
    ///    user's own default browser when it qualifies) and targets the
    ///    intent at that package explicitly, so resolution never falls to
    ///    an app chooser or an unrelated app.
    ///
    /// Neither disables App Links globally, changes any app's settings, or
    /// touches the YouTube (or any other) app in any way — both act only on
    /// this one Intent that Fetchy itself constructs.
    private fun openCustomTabLogin(platform: SessionPlatform, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(ERROR_NO_ACTIVITY, "Fetchy isn't in the foreground.", null)
            return
        }

        try {
            val customTabsIntent = CustomTabsIntent.Builder().build()
            CustomTabsIntent.setAlwaysUseBrowserUI(customTabsIntent.intent)

            val browserPackage = CustomTabsClient.getPackageName(currentActivity, emptyList(), false)
            if (browserPackage != null) {
                customTabsIntent.intent.setPackage(browserPackage)
            }

            customTabsIntent.launchUrl(currentActivity, Uri.parse(SessionLoginTargets.loginUrl(platform)))
            result.success(null)
        } catch (throwable: Throwable) {
            Log.e(TAG, "failed to open browser login", throwable)
            result.error(
                ERROR_NO_BROWSER,
                "Couldn't open a browser to sign in.",
                null,
            )
        }
    }

    /// Opens the system "create document" picker so the user chooses where
    /// an exported session file is written — Fetchy never picks a location
    /// (such as public Downloads) on its own.
    private fun beginExportSession(platform: SessionPlatform, result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(ERROR_NO_ACTIVITY, "Fetchy isn't in the foreground.", null)
            return
        }
        if (store.getSession(platform).status == SessionStatus.NOT_CONNECTED) {
            result.error(ERROR_UNKNOWN_PLATFORM, "No session to export.", null)
            return
        }

        pendingExportResult = result
        pendingExportPlatform = platform

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "text/plain"
            putExtra(Intent.EXTRA_TITLE, "${platform.id}_fetchy_session.txt")
        }

        try {
            currentActivity.startActivityForResult(intent, REQUEST_CODE_EXPORT_SESSION)
        } catch (noPicker: android.content.ActivityNotFoundException) {
            pendingExportResult = null
            pendingExportPlatform = null
            result.error(ERROR_NO_FILE_PICKER, "No file picker is available on this device.", null)
        }
    }

    /// Reads the picked document as UTF-8 text, capped well above any
    /// realistic cookies.txt size so a mis-picked large/binary file fails
    /// fast with a clear error instead of loading it wholesale.
    private fun readTextCapped(uri: android.net.Uri): String {
        val bytes = appContext.contentResolver.openInputStream(uri)?.use { stream ->
            stream.readBytes()
        } ?: throw InvalidCookieFileException("Couldn't open that file.")

        if (bytes.size > MAX_COOKIE_FILE_BYTES) {
            throw InvalidCookieFileException("That file is too large to be a cookies.txt export.")
        }

        return bytes.toString(Charsets.UTF_8)
    }

    private fun platformArgOrError(call: MethodCall, result: MethodChannel.Result): SessionPlatform? {
        val id = call.argument<String>("platform")
        val platform = id?.let(SessionPlatform::fromId)
        if (platform == null) {
            result.error(ERROR_UNKNOWN_PLATFORM, "Unknown platform: $id", null)
            return null
        }
        return platform
    }

    /// What the Connected Accounts UI shows for each of the three
    /// connection levels, capability-detected rather than assumed uniform.
    ///
    /// [easyReason] is deliberately generic because Easy Connect's actual
    /// mechanism differs per platform (see the class doc comment): YouTube/
    /// Instagram/TikTok genuinely capture a usable session; X only opens a
    /// browser. The specific outcome — "session connected" vs. "use
    /// Advanced instead" — is reported after the attempt completes (see
    /// [handleEasyConnectResult] and the Custom Tab path), based on
    /// whether a session was actually captured, not asserted here ahead of
    /// time for every platform alike.
    private fun capabilities(): Map<String, Any?> = mapOf(
        "easy" to true,
        "easyReason" to "Sign in securely using your browser.",
        "advanced" to true,
        "advancedReason" to null,
        "expert" to false,
        "expertReason" to "Android doesn't provide a safe, supported way for Fetchy to read " +
            "another app's browser session data. Advanced cookie import is the supported way " +
            "to bring in a session.",
    )

    private fun toMap(record: PlatformSessionRecord): Map<String, Any?> = mapOf(
        "platform" to record.platform.id,
        "status" to record.status.name,
        "createdAtMillis" to record.createdAtMillis,
        "lastValidatedAtMillis" to record.lastValidatedAtMillis,
        "metadata" to record.metadata,
    )

    companion object {
        const val CHANNEL = "app.fetchy/sessions"

        private const val METHOD_GET_CAPABILITIES = "getCapabilities"
        private const val METHOD_LIST_SESSIONS = "listSessions"
        private const val METHOD_PICK_AND_IMPORT_COOKIES_FILE = "pickAndImportCookiesFile"
        private const val METHOD_OPEN_BROWSER_LOGIN = "openBrowserLogin"
        private const val METHOD_RECORD_VALIDATION_RESULT = "recordValidationResult"
        private const val METHOD_EXPORT_SESSION = "exportSession"
        private const val METHOD_REMOVE_SESSION = "removeSession"

        /// General Cookie Manager: arbitrary/custom-site cookies. Same
        /// channel as the platform session methods above — an extension of
        /// the existing session system, not a second one.
        private const val METHOD_LIST_CUSTOM_COOKIE_SITES = "listCustomCookieSites"
        private const val METHOD_PICK_AND_IMPORT_CUSTOM_COOKIES_FILE =
            "pickAndImportCustomCookiesFile"
        private const val METHOD_IMPORT_CUSTOM_COOKIES_TEXT = "importCustomCookiesText"
        private const val METHOD_REMOVE_CUSTOM_COOKIE_SITE = "removeCustomCookieSite"

        private const val ERROR_UNKNOWN_PLATFORM = "unknown_platform"
        private const val ERROR_UNKNOWN_STATUS = "unknown_status"
        private const val ERROR_NO_ACTIVITY = "no_activity"
        private const val ERROR_NO_FILE_PICKER = "no_file_picker"
        private const val ERROR_NO_BROWSER = "no_browser"
        private const val ERROR_INVALID_COOKIE_FILE = "invalid_cookie_file"
        private const val ERROR_IMPORT_FAILED = "import_failed"
        private const val ERROR_INVALID_DOMAIN = "invalid_domain"

        private const val REQUEST_CODE_PICK_COOKIES_FILE = 5301
        private const val REQUEST_CODE_EASY_CONNECT = 5302
        private const val REQUEST_CODE_EXPORT_SESSION = 5303
        private const val REQUEST_CODE_PICK_CUSTOM_COOKIES_FILE = 5304
        private const val MAX_COOKIE_FILE_BYTES = 5 * 1024 * 1024

        private const val TAG = "FetchySessions"
    }
}

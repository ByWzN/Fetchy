package com.example.fetchy.quickfetch

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.os.SystemClock
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import com.example.fetchy.domains.BuiltInDetectedSites
import com.example.fetchy.domains.WatchedDomainStore

/// Detects that the user performed a *copy interaction* inside a supported
/// app, and nothing more.
///
/// What this service deliberately does NOT do:
///  - it never calls getPrimaryClip(); an accessibility service has no
///    clipboard privilege, and Android 10+ would return null anyway,
///  - it never traverses the accessibility node tree (canRetrieveWindowContent
///    is false in its config), so it cannot and does not scrape the screen,
///  - it never logs event text or clipboard contents,
///  - it does no network, no extraction, and never touches the downloader.
///
/// It only inspects the text that arrives *on the event itself* (the label of
/// the tapped control, or a copy-confirmation announcement) and matches it
/// against a short keyword regex. On a match it records a pending candidate
/// carrying just the source package and a timestamp.
class QuickFetchAccessibilityService : AccessibilityService() {

    /// The most recent supported app the user was in. A "Copy link" tap often
    /// belongs to the system share sheet or SystemUI rather than the app itself,
    /// so the candidate is attributed to this rather than to SystemUI.
    private var lastSourcePackage: String? = null
    private var lastSourceAtElapsedMs: Long = 0L

    /// Avoids posting duplicate candidates if both a View Click and a SystemUI
    /// announcement arrive within a fraction of a second for the same action.
    private var lastCandidateAtElapsedMs: Long = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        isConnected = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // The user can leave the accessibility service enabled in system
        // settings while Quick Fetch itself is off; respect the app switch.
        if (!QuickFetchPrefs.isEnabled(applicationContext)) return

        val packageId = event.packageName?.toString() ?: return
        val eventTypeName = AccessibilityEvent.eventTypeToString(event.eventType)
        val className = event.className?.toString() ?: "null"
        val hasText = event.text.any { !it.isNullOrEmpty() }
        val textLength = event.text.sumOf { it?.length ?: 0 }
        val hasContentDescription = !event.contentDescription.isNullOrEmpty()
        val contentDescLength = event.contentDescription?.length ?: 0

        // Cheapest path first: remember which supported app is in front.
        if (QuickFetchSourcePackages.isSupportedSource(packageId)) {
            lastSourcePackage = packageId
            lastSourceAtElapsedMs = SystemClock.elapsedRealtime()
        }

        val copySignal = isCopySignal(event)

        // Diagnostic: log every event from a watched package or share sheet,
        // logging only safe metadata (presence/counts), never arbitrary UI text,
        // clipboard contents, or URLs.
        if (QuickFetchSourcePackages.isSupportedSource(packageId) ||
            QuickFetchSourcePackages.isShareSheet(packageId) ||
            copySignal
        ) {
            Log.d(
                TAG,
                "source=$packageId " +
                    "event=$eventTypeName " +
                    "class=$className " +
                    "hasText=$hasText " +
                    "textLength=$textLength " +
                    "hasContentDescription=$hasContentDescription " +
                    "contentDescLength=$contentDescLength " +
                    "copySignal=$copySignal " +
                    "lastSource=$lastSourcePackage"
            )
        }

        if (!copySignal) return

        val sourcePackage = resolveSourcePackage(packageId) ?: run {
            Log.d(TAG, "copySignal=true but resolveSourcePackage returned null for package=$packageId")
            return
        }
        val platform = QuickFetchSourcePackages.platformFor(sourcePackage) ?: run {
            Log.d(TAG, "copySignal=true but no platform found for source=$sourcePackage")
            return
        }

        // Stage 1 cannot see the clipboard, so it cannot know which exact
        // domain is about to be copied — it can only ask whether the user
        // still watches *any* of this platform's domains. Without this
        // check, removing every one of a platform's domains from Settings
        // would stop the final Fetch (stage 2, at tap time) but the
        // notification/floating dot would still appear on every copy,
        // which is not "not detected" from the user's point of view.
        if (!isPlatformStillWatched(platform)) {
            Log.d(TAG, "candidateSuppressed=true source=$sourcePackage platform=$platform reason=notWatched")
            return
        }

        val now = SystemClock.elapsedRealtime()
        if (now - lastCandidateAtElapsedMs < DEDUPLICATION_WINDOW_MS) {
            Log.d(TAG, "Deduplicated rapid secondary copy signal for source=$sourcePackage")
            return
        }
        lastCandidateAtElapsedMs = now

        Log.d(TAG, "candidateCreated=true source=$sourcePackage platform=$platform")

        QuickFetchPresenter.present(
            applicationContext,
            QuickFetchPendingCandidate(
                sourcePackage = sourcePackage,
                platform = platform,
                detectedAtElapsedMs = now,
            ),
        )
    }

    override fun onInterrupt() {
        // Required override; this service performs no continuous work to stop.
    }

    override fun onDestroy() {
        isConnected = false
        lastSourcePackage = null
        // Do not leave a floating dot behind when detection stops.
        QuickFetchPresenter.releaseOverlay()
        super.onDestroy()
    }

    /// True when at least one of [platform]'s known domains (e.g. YouTube's
    /// "youtube.com"/"youtu.be") is still present in the user's effective
    /// watched-domain list — the same [WatchedDomainStore] that stage 2
    /// (the real clipboard/host check at tap time) uses. An unrecognized
    /// platform is never suppressed here; only the four built-in platforms
    /// this service watches by package name can ever reach this check.
    private fun isPlatformStillWatched(platform: String): Boolean {
        val platformDomains = BuiltInDetectedSites.byPlatform[platform] ?: return true
        val store = WatchedDomainStore(applicationContext)
        return platformDomains.any { store.matches(it) }
    }

    /// Attributes an event to a supported source app. A copy performed in the
    /// share sheet or SystemUI is credited to the app the user just came from,
    /// provided that was recent enough to be plausible.
    private fun resolveSourcePackage(eventPackage: String): String? {
        if (QuickFetchSourcePackages.isSupportedSource(eventPackage)) {
            return eventPackage
        }

        if (!QuickFetchSourcePackages.isShareSheet(eventPackage)) return null

        val recent = lastSourcePackage ?: return null
        val age = SystemClock.elapsedRealtime() - lastSourceAtElapsedMs
        return if (age <= SYSTEM_UI_CORRELATION_WINDOW_MS) recent else null
    }

    /// True when the event looks like a copy interaction.
    ///
    /// Only the event's own text/content-description is examined — this is the
    /// label of the control the user tapped, or the text of a copy
    /// confirmation. No surrounding screen content is read.
    private fun isCopySignal(event: AccessibilityEvent): Boolean {
        if (event.eventType !in COPY_SIGNAL_EVENT_TYPES) return false

        val builder = StringBuilder()
        for (part in event.text) {
            if (part != null) builder.append(part).append(' ')
        }
        val description = event.contentDescription
        if (!TextUtils.isEmpty(description)) builder.append(description)

        if (builder.isEmpty()) return false
        if (builder.length > MAX_SIGNAL_LENGTH) return false

        val text = builder.toString().trim()
        if (text.isEmpty()) return false

        return COPY_REGEX.containsMatchIn(text)
    }

    companion object {
        private const val TAG = "FetchyQuickFetch"

        /// Live state for Settings, so capability is reported from reality
        /// rather than from a stored preference.
        @Volatile
        @JvmStatic
        var isConnected: Boolean = false

        /// Time window during which a SystemUI / share-sheet copy event is
        /// correlated with the most recent supported source app (e.g. YouTube).
        private const val SYSTEM_UI_CORRELATION_WINDOW_MS = 10_000L

        /// Coalesces near-simultaneous events (e.g. YouTube click followed
        /// immediately by SystemUI toast/announcement) into one candidate.
        private const val DEDUPLICATION_WINDOW_MS = 2_000L

        /// The only event kinds that can carry a copy signal. Window-state
        /// events are received too (to track the front app) but never treated
        /// as a copy.
        private val COPY_SIGNAL_EVENT_TYPES: Set<Int> = setOf(
            AccessibilityEvent.TYPE_VIEW_CLICKED,
            AccessibilityEvent.TYPE_ANNOUNCEMENT,
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED,
        )

        /// Guards against matching an entire screenful of text.
        private const val MAX_SIGNAL_LENGTH = 200

        /// Matches copy-related interactions or announcements using word
        /// boundaries so words like "copyright" or "copilot" never match.
        private val COPY_REGEX = Regex(
            """\b(copy\s+(?:link|url|video\s+link|post\s+link|tweet\s+link|address|text)?|link\s+copied|copied(?:\s+to\s+(?:your\s+)?clipboard|\s+link)?)\b""",
            RegexOption.IGNORE_CASE,
        )

        /// Whether the user has switched this service on in system settings.
        /// Checked live because the user can revoke it at any time.
        fun isEnabledInSystemSettings(context: Context): Boolean {
            // Primary: ask the platform for the services it has actually
            // enabled and compare ComponentNames. This is the supported public
            // API for the question, and it compares structured identities
            // rather than parsing a delimited settings string.
            enabledViaAccessibilityManager(context)?.let { return it }

            // Fallback only: the Secure setting is still readable when the
            // AccessibilityManager is unavailable (it can be null very early
            // in process startup on some devices).
            val expected = componentName(context)
            val enabled = try {
                Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                )
            } catch (throwable: Throwable) {
                null
            } ?: return false

            return enabled.split(':').any {
                ComponentName.unflattenFromString(it.trim()) == expected
            }
        }

        /// Null when the platform could not answer at all, which is different
        /// from a confident "not enabled" — the caller falls back rather than
        /// reporting a state it cannot support.
        private fun enabledViaAccessibilityManager(context: Context): Boolean? {
            return try {
                val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE)
                    as? AccessibilityManager ?: return null
                val expected = componentName(context)

                manager
                    .getEnabledAccessibilityServiceList(
                        AccessibilityServiceInfo.FEEDBACK_ALL_MASK,
                    )
                    .any { info ->
                        val id = info.id ?: return@any false
                        ComponentName.unflattenFromString(id) == expected
                    }
            } catch (throwable: Throwable) {
                Log.w(TAG, "Could not query enabled accessibility services", throwable)
                null
            }
        }

        /// Fetchy's own Quick Fetch service, as a structured identity rather
        /// than a hand-built string.
        private fun componentName(context: Context): ComponentName =
            ComponentName(context.packageName, QuickFetchAccessibilityService::class.java.name)

        /// The flattened "<package>/<class>" form, for the system settings
        /// screens that take a component name as an intent extra.
        fun componentId(context: Context): String =
            componentName(context).flattenToString()
    }
}


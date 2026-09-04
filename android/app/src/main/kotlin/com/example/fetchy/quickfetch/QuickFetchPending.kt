package com.example.fetchy.quickfetch

import android.content.Context
import android.os.SystemClock

/// The pending Quick Fetch candidate.
///
/// Note what is *not* here: no URL, no clipboard text, nothing copied from the
/// source app. At detection time Fetchy genuinely does not know what the user
/// copied — only that a copy interaction happened in a supported app. The URL
/// is read from the clipboard later, once the user taps and Fetchy has focus.
data class QuickFetchPendingCandidate(
    val sourcePackage: String,
    val platform: String,
    val detectedAtElapsedMs: Long,
) {
    /// Candidates go stale so a tap on an old notification cannot silently
    /// consume an unrelated clipboard entry.
    fun isExpired(nowElapsedMs: Long = SystemClock.elapsedRealtime()): Boolean =
        nowElapsedMs - detectedAtElapsedMs > EXPIRY_MS

    companion object {
        const val EXPIRY_MS = 10 * 60 * 1000L
    }
}

/// Single owner of the pending candidate and of whichever surface is showing
/// it. The accessibility service, the dismiss receiver, and the method-channel
/// handler all go through here, so there is exactly one place that can create
/// or tear down a quick action.
///
/// Holds only the application context — never an Activity.
object QuickFetchPresenter {

    @Volatile
    private var pendingCandidate: QuickFetchPendingCandidate? = null

    private var overlay: QuickFetchOverlay? = null
    private var notifier: QuickFetchNotifier? = null

    /// The live pending candidate, or null when nothing is waiting.
    val pending: QuickFetchPendingCandidate?
        get() = pendingCandidate?.takeUnless { it.isExpired() }

    /// Shows the quick action for [candidate] using the user's chosen style.
    /// A newer candidate always replaces an older one (deterministic: latest
    /// wins), reusing the same notification id / overlay instance.
    fun present(context: Context, candidate: QuickFetchPendingCandidate) {
        val appContext = context.applicationContext
        pendingCandidate = candidate

        when (QuickFetchPrefs.actionStyle(appContext)) {
            QuickFetchActionStyle.FLOATING_DOT -> {
                val shown = overlayInstance(appContext).show()
                if (!shown) {
                    // Overlay permission revoked after the style was chosen —
                    // fall back rather than dropping the detection silently.
                    if (!notifierInstance(appContext).showCandidate(candidate)) {
                        pendingCandidate = null
                    }
                }
            }

            QuickFetchActionStyle.NOTIFICATION -> {
                if (!notifierInstance(appContext).showCandidate(candidate)) {
                    pendingCandidate = null
                }
            }
        }
    }

    /// Tears down every surface and forgets the candidate. Used when the user
    /// dismisses it, when it is consumed, and when Quick Fetch is turned off.
    fun clear(context: Context) {
        val appContext = context.applicationContext
        pendingCandidate = null
        overlay?.hide()
        notifierInstance(appContext).cancelCandidate()
    }

    /// Releases the overlay view without disturbing notifications — used when
    /// the accessibility service is being destroyed.
    fun releaseOverlay() {
        overlay?.hide()
        overlay = null
    }

    private fun overlayInstance(appContext: Context): QuickFetchOverlay {
        return overlay ?: QuickFetchOverlay(appContext).also { overlay = it }
    }

    private fun notifierInstance(appContext: Context): QuickFetchNotifier {
        return notifier ?: QuickFetchNotifier(appContext).also { notifier = it }
    }
}

package com.example.fetchy.quickfetch

import android.content.Context
import android.net.Uri
import android.util.Log
import com.example.fetchy.domains.BuiltInDetectedSites
import com.example.fetchy.domains.WatchedDomainStore

/// Stage 2 of Quick Fetch's validation: which *URLs* are ever treated as
/// supported once the clipboard is actually read (see
/// [QuickFetchSourcePackages] for stage 1, which is unchanged by this —
/// it still only watches YouTube/TikTok/Instagram/X's own apps for a copy
/// interaction; this stage only decides whether whatever ends up in the
/// clipboard by the time the user taps is accepted).
///
/// Backed by [WatchedDomainStore] — the single, user-editable effective
/// detection list (seeded from built-in defaults, but fully user
/// controlled from then on; see that class). This list is detection-only:
/// appearing here means Quick Fetch recognizes the link, never that
/// yt-dlp is guaranteed to extract it — that is decided solely by the
/// real Fetch/extraction attempt.
object QuickFetchSupportedSites {

    /// The cheap filter pipeline, in order: non-blank -> plausible URL shape
    /// -> parseable -> http(s) -> watched-domain match. Returns the cleaned
    /// URL only when every step passes, otherwise null.
    ///
    /// This is stage 2 of validation, applied to the clipboard text only
    /// after the user has tapped a quick action and Fetchy is in front. It
    /// does no network work and allocates almost nothing on the reject path.
    fun candidateFrom(rawText: String?, appContext: Context): QuickFetchValidatedLink? {
        val text = rawText?.trim() ?: return null
        if (text.isEmpty() || text.length > MAX_LENGTH) {
            Log.d(TAG, "candidateFrom: clipboard empty or unavailable")
            return null
        }

        // Cheapest possible early-out before any parsing.
        if (!text.startsWith("http://", ignoreCase = true) &&
            !text.startsWith("https://", ignoreCase = true)
        ) {
            Log.d(TAG, "candidateFrom: clipboard text is not an http(s) link")
            return null
        }

        // A copied link may arrive with trailing prose ("Check this out ...").
        // Take only the first whitespace-delimited token.
        val token = text.substringBefore(' ').substringBefore('\n').trim()
        if (token.isEmpty()) return null

        val uri = try {
            Uri.parse(token)
        } catch (ignored: Throwable) {
            Log.d(TAG, "candidateFrom: could not parse clipboard text as a URI")
            return null
        }

        val scheme = uri.scheme?.lowercase() ?: return null
        if (scheme != "http" && scheme != "https") return null

        val host = uri.host?.lowercase() ?: return null
        val store = WatchedDomainStore(appContext)
        val matched = store.matches(host)
        // Logs only the host and the currently configured watch list — never
        // the full URL/path/query, which could carry sensitive content.
        Log.d(
            TAG,
            "candidateFrom: host=$host matched=$matched watchedDomains=${store.domains()}",
        )
        if (!matched) return null

        // Best-effort label for a well-known built-in platform, purely for
        // this data class's own informational value — nothing downstream
        // currently branches on the exact string.
        val platform = BuiltInDetectedSites.platformFor(host) ?: "Detected site"

        return QuickFetchValidatedLink(url = token, host = host, platform = platform)
    }

    /// True when [url]'s host is currently watched — used by the Dart
    /// side's own defense-in-depth recheck (see
    /// `QuickFetchService.consumeClipboardLink`), which cannot enumerate
    /// the effective list itself since it is stored, and user-editable,
    /// only natively.
    fun isWatchedUrl(url: String, appContext: Context): Boolean {
        val uri = try {
            Uri.parse(url)
        } catch (ignored: Throwable) {
            return false
        }
        val host = uri.host?.lowercase() ?: return false
        return WatchedDomainStore(appContext).matches(host)
    }

    /// Guards against pathological clipboard payloads (whole documents).
    private const val MAX_LENGTH = 2048

    private const val TAG = "QuickFetchDetect"
}

/// A copied link that passed the allowlist. This is the only clipboard-derived
/// value Quick Fetch ever retains.
data class QuickFetchValidatedLink(
    val url: String,
    val host: String,
    val platform: String,
)

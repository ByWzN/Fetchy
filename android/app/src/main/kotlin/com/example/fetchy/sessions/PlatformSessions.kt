// android/app/src/main/kotlin/com/example/fetchy/sessions/PlatformSessions.kt
package com.example.fetchy.sessions

import android.net.Uri

/// The platforms Connected Accounts/Sessions supports. Kept separate from
/// Quick Fetch's own platform list and from the download-error mapper's
/// platform names — this enum is the session system's own vocabulary, not
/// shared state with either.
enum class SessionPlatform(val id: String, val displayName: String) {
    YOUTUBE("youtube", "YouTube"),
    TIKTOK("tiktok", "TikTok"),
    X("x", "X"),
    INSTAGRAM("instagram", "Instagram");

    companion object {
        fun fromId(id: String): SessionPlatform? = entries.firstOrNull { it.id == id }

        /// Which platform (if any) a media URL belongs to — used by
        /// [com.example.fetchy.EngineChannelHandler] to decide whether a
        /// stored session is even relevant to a given extraction/download
        /// request. Returns null for anything not one of the four
        /// supported platforms, which means no session is ever attached.
        fun fromUrl(url: String): SessionPlatform? {
            val host = Uri.parse(url).host?.lowercase() ?: return null
            return when {
                host.endsWith("youtube.com") || host == "youtu.be" -> YOUTUBE
                host.endsWith("tiktok.com") -> TIKTOK
                host.endsWith("twitter.com") || host.endsWith("x.com") -> X
                host.endsWith("instagram.com") -> INSTAGRAM
                else -> null
            }
        }
    }
}

/// Cookie-file domains that genuinely belong to each platform's session.
/// A cookie whose domain isn't in this list for the selected platform is
/// discarded during import — this is what "keep only cookies relevant to
/// the selected platform" means in practice.
///
/// YouTube is the one exception worth noting: its own sign-in cookies
/// (SID/HSID/SSID/APISID/SAPISID and the __Secure-* variants) are issued on
/// google.com, not youtube.com, because YouTube authentication is Google
/// account authentication. Both domains must be kept for a YouTube session
/// to actually carry sign-in state.
object PlatformCookieDomains {
    private val domains: Map<SessionPlatform, Set<String>> = mapOf(
        SessionPlatform.YOUTUBE to setOf("youtube.com", "google.com"),
        SessionPlatform.TIKTOK to setOf("tiktok.com"),
        SessionPlatform.X to setOf("twitter.com", "x.com"),
        SessionPlatform.INSTAGRAM to setOf("instagram.com"),
    )

    /// True when [cookieDomain] (as read from a Netscape cookie file, which
    /// may carry a leading ".") belongs to [platform].
    fun matches(platform: SessionPlatform, cookieDomain: String): Boolean {
        val normalized = cookieDomain.removePrefix(".").lowercase()
        val allowed = domains[platform] ?: return false
        return allowed.any { normalized == it || normalized.endsWith(".$it") }
    }

    /// The base domains [platform]'s session cookies live on — used by
    /// [SessionLoginActivity] to know which domains to read from
    /// [android.webkit.CookieManager] after a WebView-based sign-in.
    fun domainsFor(platform: SessionPlatform): Set<String> = domains[platform] ?: emptySet()
}

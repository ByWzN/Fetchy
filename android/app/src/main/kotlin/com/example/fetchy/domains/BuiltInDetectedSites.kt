// android/app/src/main/kotlin/com/example/fetchy/domains/BuiltInDetectedSites.kt
package com.example.fetchy.domains

/// Fetchy's default Link Auto-Detect domains — commonly used media sites.
///
/// This is seed data only: [WatchedDomainStore] copies it in once, the
/// first time it is ever read on a device, and from that point on the
/// user's stored list is the only thing consulted for matching. Nothing
/// here is re-consulted afterward, so removing a domain from the watched
/// list (even one that started here) genuinely stops Quick Fetch from
/// recognizing it — there is no separate, immutable list left to fall
/// back to.
object BuiltInDetectedSites {

    /// Root domains only — subdomain variants (www., m., vt., vm., ...) are
    /// all handled automatically by [DomainMatcher]'s subdomain rule, so
    /// e.g. TikTok's "vt.tiktok.com"/"vm.tiktok.com" short links and
    /// YouTube's "m.youtube.com" never need their own entry here — only a
    /// platform's genuinely separate *registrable* domains (a different
    /// domain entirely, not a subdomain of one already listed) are.
    val byPlatform: Map<String, List<String>> = mapOf(
        "YouTube" to listOf("youtube.com", "youtu.be"),
        "TikTok" to listOf("tiktok.com"),
        "Instagram" to listOf("instagram.com", "instagr.am"),
        "Facebook" to listOf("facebook.com", "fb.watch"),
        "X" to listOf("x.com", "twitter.com"),
        "Threads" to listOf("threads.net", "threads.com"),
        "Snapchat" to listOf("snapchat.com"),
        "SoundCloud" to listOf("soundcloud.com", "snd.sc"),
        "Reddit" to listOf("reddit.com", "redd.it"),
        "Pinterest" to listOf("pinterest.com", "pin.it"),
        "Vimeo" to listOf("vimeo.com"),
        "Bilibili" to listOf("bilibili.com", "b23.tv"),
        "Twitch" to listOf("twitch.tv"),
    )

    /// The platform label for [host], or null when it matches no built-in
    /// domain. Cosmetic only — labeling a link "YouTube" vs. "Detected
    /// site" in [QuickFetchValidatedLink]. Never used to gate detection;
    /// [WatchedDomainStore] is the only place that decides what matches.
    fun platformFor(host: String?): String? {
        if (host == null) return null
        for ((platform, domains) in byPlatform) {
            if (domains.any { DomainMatcher.matches(host, it) }) return platform
        }
        return null
    }
}

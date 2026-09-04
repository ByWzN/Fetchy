package com.example.fetchy.quickfetch

/// Stage 1 of the two-stage validation: which *apps* may generate a pending
/// Quick Fetch candidate.
///
/// This is deliberately separate from [QuickFetchSupportedSites], which is the
/// stage-2 hostname allowlist applied to the clipboard after the user taps.
/// A copy interaction seen here only says "the user probably copied something
/// in YouTube" — it never says what was copied.
object QuickFetchSourcePackages {

    /// Package ids are not a stable public contract, so each platform maps to
    /// a small list and new ids can be appended without touching logic.
    /// Regional/clone builds (TikTok Lite, YouTube Go, ...) can be added here.
    private val SOURCES: Map<String, List<String>> = mapOf(
        "YouTube" to listOf(
            "com.google.android.youtube",
            "com.google.android.apps.youtube.music",
            "com.google.android.youtube.tv",
        ),
        "TikTok" to listOf(
            // TikTok ships under different ids by region.
            "com.zhiliaoapp.musically",
            "com.ss.android.ugc.trill",
            "com.ss.android.ugc.aweme",
        ),
        "Instagram" to listOf(
            "com.instagram.android",
            "com.instagram.lite",
        ),
        "X" to listOf(
            "com.twitter.android",
            "com.twitter.android.lite",
        ),
    )

    /// Share-sheet hosts. A "Copy link" tap frequently belongs to the system
    /// share sheet rather than the app the user was in, so these are accepted
    /// as a copy *signal* only — the candidate is still attributed to the most
    /// recent supported source app, never to the share sheet itself.
    private val SHARE_SHEET_PACKAGES: Set<String> = setOf(
        "android",
        "com.android.intentresolver",
        "com.android.systemui",
    )

    private val PLATFORM_BY_PACKAGE: Map<String, String> = buildMap {
        for ((platform, packages) in SOURCES) {
            for (id in packages) put(id, platform)
        }
    }

    /// True when [packageId] is one of the watched source apps.
    fun isSupportedSource(packageId: String): Boolean =
        PLATFORM_BY_PACKAGE.containsKey(packageId)

    /// True when [packageId] is a share sheet that may host the Copy action.
    fun isShareSheet(packageId: String): Boolean =
        packageId in SHARE_SHEET_PACKAGES

    /// The display platform name for a source package, or null.
    fun platformFor(packageId: String): String? = PLATFORM_BY_PACKAGE[packageId]

    /// Every package the accessibility service should receive events from.
    /// Mirrored in res/xml/quick_fetch_accessibility_service.xml, which is the
    /// value the platform actually enforces.
    fun allWatchedPackages(): List<String> =
        PLATFORM_BY_PACKAGE.keys.toList() + SHARE_SHEET_PACKAGES.toList()
}

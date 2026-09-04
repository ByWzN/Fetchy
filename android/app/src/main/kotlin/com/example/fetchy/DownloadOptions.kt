// android/app/src/main/kotlin/com/example/fetchy/DownloadOptions.kt
package com.example.fetchy

/// What the user set in the Download Options sheet, if anything. Every
/// field is independently optional — this only ever adds to the default
/// download behavior, never replaces it. Absent/malformed input degrades
/// to [NONE], the exact same as not having Download Options at all.
data class DownloadOptions(
    /// Video mode only: a custom base filename (no extension) to use
    /// instead of the source title. Applied via yt-dlp's own `-o` output
    /// template — no post-processing involved.
    val filename: String?,
    /// Audio mode only: metadata to embed via [DownloadPostProcessor].
    /// Each is independently optional — an unset field means "leave
    /// whatever the source already has," never "clear it."
    val audioTitle: String?,
    val audioArtist: String?,
    val audioAlbum: String?,
    /// A local file path — already materialized (custom image copied from
    /// its SAF Uri) or already downloaded (source thumbnail fetched from
    /// its extraction-provided URL) by the Dart-side Download Options
    /// sheet before Save was pressed. Never a content:// Uri or remote URL
    /// here: by the time this reaches native, the "pick vs. pull" decision
    /// is already resolved to one concrete local file, so
    /// [DownloadPostProcessor] never needs to know which source it came
    /// from or perform any network/SAF access itself.
    val artworkImagePath: String?,
    /// Video mode only: the real yt-dlp language code (e.g. "en", "ar") of
    /// the subtitle/caption track to embed, from the actual `subtitles`/
    /// `automatic_captions` this media reported — never invented. Null
    /// means no subtitles at all, the same as not having this feature.
    val subtitleLanguage: String?,
    /// True when [subtitleLanguage] came from `automatic_captions` rather
    /// than `subtitles` — decides `--write-auto-subs` vs `--write-subs`.
    val subtitleIsAutomatic: Boolean
) {
    val hasAudioMetadata: Boolean
        get() = audioTitle != null || audioArtist != null || audioAlbum != null

    val hasArtwork: Boolean
        get() = artworkImagePath != null

    companion object {
        val NONE = DownloadOptions(
            filename = null,
            audioTitle = null,
            audioArtist = null,
            audioAlbum = null,
            artworkImagePath = null,
            subtitleLanguage = null,
            subtitleIsAutomatic = false
        )

        @Suppress("UNCHECKED_CAST")
        fun fromArgument(raw: Any?): DownloadOptions {
            val map = raw as? Map<String, Any?> ?: return NONE
            val audio = map["audio"] as? Map<String, Any?>
            val video = map["video"] as? Map<String, Any?>
            val artwork = map["artwork"] as? Map<String, Any?>

            return DownloadOptions(
                filename = video.trimmedStringOrNull("filename"),
                audioTitle = audio.trimmedStringOrNull("title"),
                audioArtist = audio.trimmedStringOrNull("artist"),
                audioAlbum = audio.trimmedStringOrNull("album"),
                artworkImagePath = artwork.trimmedStringOrNull("path"),
                subtitleLanguage = video.trimmedStringOrNull("subtitleLanguage"),
                subtitleIsAutomatic = (video?.get("subtitleIsAutomatic") as? Boolean) ?: false
            )
        }

        private fun Map<String, Any?>?.trimmedStringOrNull(key: String): String? {
            val value = (this?.get(key) as? String)?.trim()
            return value?.takeIf { it.isNotEmpty() }
        }
    }
}

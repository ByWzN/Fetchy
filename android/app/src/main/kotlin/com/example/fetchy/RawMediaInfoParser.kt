// android/app/src/main/kotlin/com/example/fetchy/RawMediaInfoParser.kt
package com.example.fetchy

import org.json.JSONObject

/// Turns yt-dlp's own `--dump-json` output into the same wire payload shape
/// [EngineChannelHandler] has always sent to Dart — plus a handful of
/// additional fields the bundled youtubedl-android wrapper's `VideoInfo`/
/// `VideoFormat` mapper never parsed at all (dynamic_range, language,
/// audio_channels, protocol, real vbr, subtitles, automatic_captions,
/// artist/album/track, has_drm).
///
/// This does not run yt-dlp a second time or duplicate extraction: it reads
/// the exact same `--dump-json` stdout that `YoutubeDL.getInfo()` itself
/// generates internally before discarding it (confirmed by inspecting the
/// library source — `getInfo()` is `addOption("--dump-json")` + `execute()`
/// + a Jackson parse of the response, nothing more). Calling `execute()`
/// directly and parsing the same output here costs nothing extra.
///
/// Every field is read defensively: a missing or JSON-null key becomes
/// Kotlin `null`, a field of an unexpected type is treated as absent rather
/// than throwing, and unknown keys already present in this schema are
/// simply not read — a single malformed field can never fail extraction.
object RawMediaInfoParser {

    /// [rawStdout] is yt-dlp's full stdout for one `--dump-json` invocation.
    /// The last non-blank line is used as the JSON document — yt-dlp's
    /// documented output is exactly one JSON object per requested URL, but
    /// stray notices on stdout are tolerated the same defensive way
    /// [EngineChannelHandler.executeRuntimeVersionCheck] already handles
    /// them for `--version`.
    fun parseMediaInfoPayload(rawStdout: String, sourceUrl: String): Map<String, Any?> {
        val jsonLine = rawStdout
            .trim()
            .lineSequence()
            .lastOrNull { it.isNotBlank() }
            ?: ""

        val json = JSONObject(jsonLine)
        return mediaInfoPayload(json, sourceUrl)
    }

    private fun mediaInfoPayload(json: JSONObject, sourceUrl: String): Map<String, Any?> {
        val title = json.stringOrNull("title") ?: json.stringOrNull("fulltitle")
        val thumbnailUrl = json.stringOrNull("thumbnail")
            ?: json.optJSONArray("thumbnails")?.optJSONObject(0)?.stringOrNull("url")
        val durationSeconds = json.doubleOrNull("duration")?.toInt()?.takeIf { it > 0 }

        val formats = mutableListOf<Map<String, Any?>>()
        json.optJSONArray("formats")?.let { array ->
            for (i in 0 until array.length()) {
                val formatObject = array.optJSONObject(i) ?: continue
                formats.add(formatPayload(formatObject))
            }
        }

        return mapOf(
            // --- existing fields: same keys, same semantics as the old
            // VideoInfo-based toPayload() ---
            "sourceUrl" to sourceUrl,
            "id" to json.stringOrNull("id"),
            "title" to title,
            "thumbnailUrl" to thumbnailUrl,
            "durationSeconds" to durationSeconds,
            "uploader" to json.stringOrNull("uploader"),
            "webpageUrl" to json.stringOrNull("webpage_url"),
            "formats" to formats,
            // --- new fields: only present when the extractor actually
            // reported them; absent for the vast majority of non-music
            // content, and that is the honest, expected state ---
            "artist" to json.stringOrNull("artist"),
            "album" to json.stringOrNull("album"),
            "track" to json.stringOrNull("track"),
            "genre" to json.stringOrNull("genre"),
            "hasDrm" to (json.boolOrNull("has_drm") ?: json.boolOrNull("_has_drm")),
            // yt-dlp's own 1-based index of this entry within a multi-entry
            // (playlist) extraction. Null for an ordinary single-video URL,
            // and that null is the signal: its mere presence is what tells
            // the download side that the URL resolves to several entries and
            // that only this one was chosen.
            //
            // It matters because a re-extraction at download time has no
            // memory of which entry was previewed. Some extractors give
            // every entry the same format_id, so "-f <id>" alone matches all
            // of them and yt-dlp downloads the lot. Carrying the index lets
            // the download target exactly the entry the user is looking at.
            //
            // Valid only for the extraction that produced it — it is not
            // persisted anywhere.
            "playlistIndex" to json.positiveIntOrNull("playlist_index"),
            "subtitles" to subtitleTrackList(json.optJSONObject("subtitles")),
            "automaticCaptions" to subtitleTrackList(json.optJSONObject("automatic_captions")),
        )
    }

    private fun formatPayload(format: JSONObject): Map<String, Any?> {
        // yt-dlp reports "filesize" only when it is exact, and
        // "filesize_approx" when it is an estimate. Kept separate, exactly
        // as the old mapper-based payload did.
        val exactSize = format.positiveLongOrNull("filesize")
        val approxSize = format.positiveLongOrNull("filesize_approx")
        val height = format.positiveIntOrNull("height")

        val formatNote = format.stringOrNull("format_note")
        val quality = formatNote ?: height?.let { "${it}p" }

        return mapOf(
            // --- existing fields ---
            "formatId" to format.stringOrNull("format_id"),
            "ext" to format.stringOrNull("ext"),
            "qualityLabel" to quality,
            "height" to height,
            "width" to format.positiveIntOrNull("width"),
            "fps" to format.positiveDoubleOrNull("fps"),
            "videoCodec" to format.stringOrNull("vcodec")?.takeIf { it.isNotBlank() },
            "audioCodec" to format.stringOrNull("acodec")?.takeIf { it.isNotBlank() },
            "audioBitrate" to format.positiveDoubleOrNull("abr"),
            "totalBitrate" to format.positiveDoubleOrNull("tbr"),
            "filesize" to exactSize,
            "filesizeApprox" to approxSize,
            // --- new fields: the wrapper's VideoFormat never exposed any
            // of these, even though yt-dlp reports them per format ---
            "videoBitrate" to format.positiveDoubleOrNull("vbr"),
            "dynamicRange" to format.stringOrNull("dynamic_range"),
            "language" to format.stringOrNull("language"),
            "audioChannels" to format.intOrNull("audio_channels"),
            "protocol" to format.stringOrNull("protocol"),
            "hasDrm" to format.boolOrNull("has_drm"),
        )
    }

    /// `subtitles`/`automatic_captions` are both `{lang_code: [{url, ext,
    /// name}, ...]}`. Only the language code, a display name (when
    /// present), and the set of available subtitle file formats are
    /// forwarded — actual subtitle URLs are never needed by Dart, since
    /// downloading/embedding is driven by language code alone via yt-dlp's
    /// own `--sub-langs`, not by fetching these URLs ourselves.
    private fun subtitleTrackList(subtitles: JSONObject?): List<Map<String, Any?>> {
        if (subtitles == null) return emptyList()

        val tracks = mutableListOf<Map<String, Any?>>()
        val languageCodes = subtitles.keys()
        while (languageCodes.hasNext()) {
            val languageCode = languageCodes.next()
            val entries = subtitles.optJSONArray(languageCode) ?: continue
            if (entries.length() == 0) continue

            var displayName: String? = null
            val formats = mutableListOf<String>()
            for (i in 0 until entries.length()) {
                val entry = entries.optJSONObject(i) ?: continue
                if (displayName == null) displayName = entry.stringOrNull("name")
                entry.stringOrNull("ext")?.let { ext -> if (!formats.contains(ext)) formats.add(ext) }
            }

            tracks.add(
                mapOf(
                    "language" to languageCode,
                    "name" to displayName,
                    "formats" to formats,
                )
            )
        }
        return tracks
    }

    // -------------------------------------------------------------- helpers

    private fun JSONObject.stringOrNull(key: String): String? {
        if (!has(key) || isNull(key)) return null
        return try {
            getString(key)
        } catch (malformed: Exception) {
            null
        }
    }

    private fun JSONObject.doubleOrNull(key: String): Double? {
        if (!has(key) || isNull(key)) return null
        return try {
            getDouble(key)
        } catch (malformed: Exception) {
            null
        }
    }

    private fun JSONObject.intOrNull(key: String): Int? = doubleOrNull(key)?.toInt()

    private fun JSONObject.positiveIntOrNull(key: String): Int? = intOrNull(key)?.takeIf { it > 0 }

    private fun JSONObject.positiveDoubleOrNull(key: String): Double? =
        doubleOrNull(key)?.takeIf { it > 0 }

    private fun JSONObject.positiveLongOrNull(key: String): Long? =
        doubleOrNull(key)?.toLong()?.takeIf { it > 0 }

    private fun JSONObject.boolOrNull(key: String): Boolean? {
        if (!has(key) || isNull(key)) return null
        return try {
            getBoolean(key)
        } catch (malformed: Exception) {
            null
        }
    }
}

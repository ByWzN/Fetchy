// android/app/src/main/kotlin/com/example/fetchy/DownloadPostProcessor.kt
package com.example.fetchy

import android.content.Context
import android.util.Log
import java.io.File

/// One shared, entirely OPTIONAL local post-processing step, run after
/// yt-dlp has already produced the final file and before it is published
/// to shared storage. It only runs when [DownloadOptions] genuinely
/// requires it — a normal download with no options set never reaches
/// ffmpeg here at all, exactly matching today's behavior (see
/// [applyIfNeeded]'s early return).
///
/// This exists because yt-dlp's own metadata flags (`--parse-metadata`)
/// are not safe for arbitrary user-typed text — its FROM:TO argument
/// splits on the first *unescaped* colon, so a title containing one (e.g.
/// "Interstellar: Docking Scene") would silently corrupt. Running our own
/// ffmpeg pass with each value as its own [ProcessBuilder] argv element
/// sidesteps that entirely: nothing here is a string that gets re-parsed,
/// so colons/quotes/percent signs/Unicode/Arabic text all survive intact.
///
/// Artwork embedding reuses this exact same pass rather than a second
/// pipeline: when both audio metadata and artwork are requested, one
/// ffmpeg invocation applies both. The one exception is a small, always-
/// cheap normalization pass (see [normalizeArtworkToJpeg]) that runs only
/// when artwork is actually requested — real device testing (not
/// assumption) showed this is necessary for correctness, not an
/// optimization: ffmpeg's own matroska demuxer fails to recognize a raw
/// WebP attachment as a picture ("unknown codec"), and its ogg/opus muxer
/// rejects an mjpeg stream outright ("Unsupported codec id"). Normalizing
/// every artwork source to real JPEG bytes first — regardless of whether
/// the user picked a JPG, PNG, or WebP file — sidesteps both failure modes
/// with one small, universal representation instead of per-format special
/// casing.
///
/// Reuses the exact ffmpeg binary and shared-library layout
/// youtubedl-android itself already unpacks for yt-dlp's own internal
/// merge step — confirmed by inspecting the bundled library's actual
/// compiled bytecode (constants `nativeLibraryDir`, `libffmpeg.so`,
/// `packages/ffmpeg/usr/lib`, the `--ffmpeg-location` flag it passes to
/// yt-dlp), not assumed from documentation. This is not a second FFmpeg
/// dependency.
object DownloadPostProcessor {
    private const val TAG = "FetchyPostProcess"

    /// Containers where a stream-based "attached picture" is both
    /// supported by the bundled ffmpeg's muxer AND actually recognized as
    /// cover art on playback — verified directly on-device (see the
    /// Thumbnail/Artwork investigation), not assumed from documentation.
    /// mp3/m4a/flac all confirmed via `ffmpeg -i` showing a
    /// "(attached pic)" video stream after embedding; ogg/opus confirmed
    /// to REJECT this outright ("Unsupported codec id in stream 1") and are
    /// deliberately excluded.
    private val ATTACHED_PIC_AUDIO_EXTENSIONS = setOf("mp3", "m4a", "flac")

    /// Containers where the source video plus a second "attached picture"
    /// video stream is supported — verified the same way. webm was tested
    /// and explicitly rejected by ffmpeg's own muxer log ("Stream 1 will be
    /// ignored as WebM doesn't support attachments"), so it is deliberately
    /// NOT included even though this app can produce webm downloads.
    private val ATTACHED_PIC_VIDEO_EXTENSIONS = setOf("mp4", "m4v")

    /// Matroska's own attachment mechanism (distinct from the
    /// attached-picture video stream used above) — verified working for a
    /// real JPEG attachment, recognized on read-back as an "(attached pic)"
    /// stream by ffmpeg's own matroska demuxer.
    private val MATROSKA_ATTACHMENT_EXTENSIONS = setOf("mkv", "webm")

    private val ARTWORK_SUPPORTED_EXTENSIONS =
        ATTACHED_PIC_AUDIO_EXTENSIONS + ATTACHED_PIC_VIDEO_EXTENSIONS + setOf("mkv")
    // webm is deliberately excluded here despite being in
    // MATROSKA_ATTACHMENT_EXTENSIONS above — ffmpeg's *webm* muxer profile
    // (as opposed to full matroska) silently drops attachments, confirmed
    // on-device. Only true .mkv output supports this.

    data class Result(
        val file: File,
        /// True only when artwork was actually embedded into the final
        /// file. False whenever artwork was requested but skipped for any
        /// reason (unsupported container, invalid image, processing
        /// failure) — the download itself is never blocked or failed by
        /// this, per the "no silent failure, but also no broken download"
        /// requirement.
        val artworkApplied: Boolean,
        /// Set only when [artworkApplied] is false but artwork was actually
        /// requested — a short, user-presentable reason. Null whenever
        /// artwork was never requested, or was requested and applied.
        val artworkWarning: String?
    )

    /// Applies [options]' audio metadata and/or artwork to [source]. Audio
    /// metadata uses one ffmpeg stream-copy pass (`-c copy` for every real
    /// media stream — never a re-encode of the actual audio/video). Returns
    /// [source] itself — same file, untouched bytes — when there is
    /// nothing to apply or the metadata/embedding pass itself fails; this
    /// step can only ever improve a successful download, never turn it
    /// into a failure.
    fun applyIfNeeded(context: Context, source: File, options: DownloadOptions): Result {
        if (!options.hasAudioMetadata && !options.hasArtwork) {
            return Result(source, artworkApplied = false, artworkWarning = null)
        }

        val ffmpegPath = resolveFfmpegExecutable(context)
        if (ffmpegPath == null) {
            Log.w(TAG, "ffmpeg binary not found; skipping post-processing")
            deleteArtworkSourceQuietly(options)
            return Result(
                source,
                artworkApplied = false,
                artworkWarning = if (options.hasArtwork) "Artwork could not be embedded." else null
            )
        }

        val extension = source.extension.lowercase()
        val artworkRequestedButUnsupported = options.hasArtwork && extension !in ARTWORK_SUPPORTED_EXTENSIONS

        var normalizedArtwork: File? = null
        if (options.hasArtwork && !artworkRequestedButUnsupported) {
            normalizedArtwork = normalizeArtworkToJpeg(context, ffmpegPath, options.artworkImagePath!!, source)
        }
        // The original picked/downloaded artwork file is never needed again
        // after normalization (or after we decide not to use it) — always
        // cleaned up here, on both success and failure, per the "no
        // unnecessary permanent copies" requirement.
        deleteArtworkSourceQuietly(options)

        val willEmbedArtwork = normalizedArtwork != null
        val artworkWarning = when {
            !options.hasArtwork -> null
            willEmbedArtwork -> null
            artworkRequestedButUnsupported -> "This file type (.$extension) does not support embedded artwork."
            else -> "The selected image could not be processed; artwork was not embedded."
        }

        if (!options.hasAudioMetadata && !willEmbedArtwork) {
            // Nothing left that ffmpeg needs to do — either only artwork
            // was requested and it could not be applied, or (impossible in
            // practice, but handled anyway) both ended up being no-ops.
            return Result(source, artworkApplied = false, artworkWarning = artworkWarning)
        }

        val tempOutput = File(source.parentFile, "${source.nameWithoutExtension}.tagged.${source.extension}")
        tempOutput.delete() // stale leftover from an earlier failed attempt, if any

        val args = buildEmbedArgs(ffmpegPath, source, tempOutput, options, extension, normalizedArtwork)
        val success = runFfmpeg(context, args)
        normalizedArtwork?.delete()

        if (!success || !tempOutput.exists() || tempOutput.length() <= 0L) {
            Log.w(TAG, "post-processing did not produce a usable file; keeping original")
            tempOutput.delete()
            return Result(
                source,
                artworkApplied = false,
                artworkWarning = if (willEmbedArtwork) {
                    "The download succeeded, but artwork could not be embedded."
                } else {
                    artworkWarning
                }
            )
        }

        // tempOutput and source are always in the same directory (the
        // app's own temp download dir), so this rename is a same-filesystem
        // POSIX rename — atomic, no window where the file is missing or
        // half-written. Only reached after tempOutput is fully verified.
        if (!tempOutput.renameTo(source)) {
            Log.w(TAG, "could not replace original with the processed copy; keeping original")
            tempOutput.delete()
            return Result(
                source,
                artworkApplied = false,
                artworkWarning = if (willEmbedArtwork) {
                    "The download succeeded, but artwork could not be embedded."
                } else {
                    artworkWarning
                }
            )
        }

        return Result(source, artworkApplied = willEmbedArtwork, artworkWarning = artworkWarning)
    }

    /// Re-encodes whatever image format the user picked/pulled (JPG, PNG,
    /// WebP — all confirmed decodable by the bundled ffmpeg build via
    /// `-decoders`) into a small, guaranteed-real JPEG file. Always runs in
    /// [source]'s own temp directory so the later embed step's rename stays
    /// on the same filesystem. Returns null on any failure — the caller
    /// treats that exactly like "no artwork requested" rather than failing
    /// the whole download.
    private fun normalizeArtworkToJpeg(
        context: Context,
        ffmpegPath: File,
        artworkSourcePath: String,
        downloadFile: File
    ): File? {
        val artworkSource = File(artworkSourcePath)
        if (!artworkSource.exists() || artworkSource.length() <= 0L) return null

        val normalized = File(downloadFile.parentFile, "artwork_${System.currentTimeMillis()}.jpg")
        val args = listOf(
            ffmpegPath.absolutePath,
            "-y",
            "-i", artworkSource.absolutePath,
            "-frames:v", "1",
            normalized.absolutePath
        )

        val success = runFfmpeg(context, args)
        if (!success || !normalized.exists() || normalized.length() <= 0L) {
            normalized.delete()
            return null
        }
        return normalized
    }

    private fun buildEmbedArgs(
        ffmpegPath: File,
        source: File,
        output: File,
        options: DownloadOptions,
        extension: String,
        normalizedArtwork: File?
    ): List<String> {
        val args = mutableListOf(ffmpegPath.absolutePath, "-y", "-i", source.absolutePath)

        if (normalizedArtwork != null && extension in MATROSKA_ATTACHMENT_EXTENSIONS) {
            // Matroska's own attachment mechanism: the image is attached as
            // an opaque file, not mapped/decoded as a stream. Verified
            // on-device to be recognized on read-back as an "(attached
            // pic)" stream by ffmpeg's own matroska demuxer.
            args.add("-map"); args.add("0")
            args.add("-c"); args.add("copy")
            args.add("-attach"); args.add(normalizedArtwork.absolutePath)
            args.add("-metadata:s:t:0"); args.add("mimetype=image/jpeg")
        } else if (normalizedArtwork != null && extension in ATTACHED_PIC_VIDEO_EXTENSIONS) {
            // Second input, second video stream, explicitly re-mapped only
            // that stream's codec — the original video/audio stay
            // stream-copied untouched. Verified on-device with a PNG source
            // image via the exact `-c:v:1` stream-specifier syntax below.
            args.add("-i"); args.add(normalizedArtwork.absolutePath)
            args.add("-map"); args.add("0")
            args.add("-map"); args.add("1")
            args.add("-c"); args.add("copy")
            args.add("-c:v:1"); args.add("copy")
            args.add("-disposition:v:1"); args.add("attached_pic")
        } else if (normalizedArtwork != null && extension in ATTACHED_PIC_AUDIO_EXTENSIONS) {
            args.add("-i"); args.add(normalizedArtwork.absolutePath)
            args.add("-map"); args.add("0:a")
            args.add("-map"); args.add("1")
            args.add("-c:a"); args.add("copy")
            args.add("-c:v"); args.add("copy")
            if (extension == "mp3") {
                args.add("-id3v2_version"); args.add("3")
            }
            args.add("-disposition:v"); args.add("attached_pic")
        } else {
            // No artwork to embed this pass (either none was requested, or
            // it could not be applied) — metadata-only, exactly as before.
            args.add("-map"); args.add("0")
            args.add("-c"); args.add("copy")
        }

        // Explicit rather than relying on ffmpeg's default, so every
        // existing tag the source already carries is kept — only the
        // fields the user actually set are added/overridden below. Each
        // value is its own argv element — never concatenated into a shared
        // string — so it survives byte-for-byte regardless of content
        // (colons, quotes, %, &, Arabic text, etc.).
        args.add("-map_metadata"); args.add("0")
        options.audioTitle?.let { args.add("-metadata"); args.add("title=$it") }
        options.audioArtist?.let { args.add("-metadata"); args.add("artist=$it") }
        options.audioAlbum?.let { args.add("-metadata"); args.add("album=$it") }

        args.add(output.absolutePath)
        return args
    }

    private fun deleteArtworkSourceQuietly(options: DownloadOptions) {
        options.artworkImagePath?.let { path ->
            try {
                File(path).delete()
            } catch (throwable: Throwable) {
                // Best-effort cleanup only; a leftover temp file here never
                // affects the download's own success or correctness.
            }
        }
    }

    private fun runFfmpeg(context: Context, args: List<String>): Boolean {
        return try {
            val processBuilder = ProcessBuilder(args)
            val environment = processBuilder.environment()
            environment["LD_LIBRARY_PATH"] = ffmpegLibraryPath(context)
            environment["TMPDIR"] = context.cacheDir.absolutePath
            processBuilder.redirectErrorStream(false)

            val process = processBuilder.start()
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                // ffmpeg's own diagnostic text (missing shared library,
                // codec/muxer errors, etc.) — never the user's metadata
                // values, which never appear in ffmpeg's own stderr output.
                val stderrTail = process.errorStream.bufferedReader().readText()
                    .lineSequence()
                    .filter { it.isNotBlank() }
                    .toList()
                    .takeLast(3)
                    .joinToString(" | ")
                Log.w(TAG, "ffmpeg exited with code $exitCode: $stderrTail")
            }
            exitCode == 0
        } catch (throwable: Throwable) {
            // Never log source/output paths' contents or the metadata
            // values themselves — only that the attempt failed.
            Log.e(TAG, "ffmpeg post-process invocation failed: ${throwable::class.simpleName}")
            false
        }
    }

    /// The same binary yt-dlp's own `--ffmpeg-location` already points at.
    /// See YoutubeDL.init() in the bundled library: it sets
    /// `ffmpegPath = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")`
    /// — confirmed directly from the compiled 0.18.1 bytecode's constant
    /// pool, not the library's docs. `nativeLibraryDir` is guaranteed to
    /// contain a real, executable file here (not just an APK-internal
    /// reference) because this project's own build.gradle.kts already sets
    /// `packaging.jniLibs.useLegacyPackaging = true`, and yt-dlp's own
    /// merge step already depends on that being true.
    private fun resolveFfmpegExecutable(context: Context): File? {
        val candidate = File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so")
        return if (candidate.exists()) candidate else null
    }

    /// Both the ffmpeg package's own shared libraries (libmp3lame, libx264,
    /// etc. — where FFmpeg.init() unzips libffmpeg.zip.so, per FFmpeg.kt's
    /// path constants) AND the python package's, because several of
    /// ffmpeg's own libraries (e.g. librubberband) dynamically link against
    /// libc++_shared.so, which is bundled with the *python* package, not
    /// ffmpeg's. Confirmed on a real device: running libffmpeg.so with only
    /// the ffmpeg dir on the path failed with "library libc++_shared.so
    /// not found"; adding the python dir fixed it. This is exactly why the
    /// bundled library's own LD_LIBRARY_PATH always combines python +
    /// ffmpeg (+ aria2c) rather than pointing at ffmpeg's directory alone.
    /// Both are always present by the time this runs: performEngineWarmup()
    /// already calls YoutubeDL.init() and FFmpeg.init() before any download
    /// can start.
    private fun ffmpegLibraryPath(context: Context): String {
        val packagesDir = File(context.noBackupFilesDir, "youtubedl-android/packages")
        val pythonLib = File(packagesDir, "python/usr/lib").absolutePath
        val ffmpegLib = File(packagesDir, "ffmpeg/usr/lib").absolutePath
        return "$pythonLib:$ffmpegLib"
    }
}

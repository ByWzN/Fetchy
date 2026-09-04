// android/app/src/main/kotlin/com/example/fetchy/EngineChannelHandler.kt
package com.example.fetchy

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.YoutubeDLResponse
import com.example.fetchy.sessions.CustomCookieStore
import com.example.fetchy.sessions.PlatformSessionStore
import com.example.fetchy.sessions.SessionPlatform
import com.example.fetchy.storage.StorageSettings
import com.example.fetchy.timing.FetchyTiming
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Collections
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future

class EngineChannelHandler(
    private val appContext: Context
) : MethodChannel.MethodCallHandler {

    // Connected Accounts/Sessions: optional, per-request, per-platform. No
    // session for a URL's platform means zero behavior change from before
    // this existed — see attachSessionCookiesIfAny().
    private val sessionStore = PlatformSessionStore(appContext)

    // General Cookie Manager: optional, per-request, per-arbitrary-domain.
    // Only ever consulted when the URL does not belong to one of the four
    // built-in platforms above — see attachSessionCookiesIfAny().
    private val customCookieStore = CustomCookieStore(appContext)

    private val extractExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    // Separate pool so a running download never blocks extraction.
    private val downloadExecutor: ExecutorService = Executors.newCachedThreadPool()

    private val mainHandler = Handler(Looper.getMainLooper())

    private val activeDownloads: MutableSet<String> =
        Collections.synchronizedSet(mutableSetOf<String>())

    // Single dedicated thread for the one-time engine warm-up (native init
    // + the automatic yt-dlp update check). Kept separate from
    // extractExecutor/downloadExecutor so warm-up itself is never queued
    // behind — or ahead of — an unrelated extraction/download task.
    private val warmupExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    /// Started the moment this handler is constructed (see MainActivity),
    /// i.e. at app/engine startup — not lazily on the user's first Fetch
    /// tap. By the time they actually paste a URL and tap Fetch, this has
    /// usually already finished during ordinary think-time on Home, so
    /// [ensureEngineReady]'s `.get()` returns immediately instead of
    /// blocking. See FetchyTiming checkpoints inside [performEngineWarmup]
    /// (run id "WARMUP" — this is a one-time, process-level operation, not
    /// tied to any single Fetch).
    private val engineWarmup: Future<*> = run {
        FetchyTiming.start(WARMUP_RUN_ID)
        FetchyTiming.checkpoint(WARMUP_RUN_ID, "ENGINE_WARMUP_TASK_CREATED")
        warmupExecutor.submit { performEngineWarmup() }
    }

    @Volatile
    private var engineReady = false

    /// Logged at most once per process — see ENGINE_RUNTIME_VERSION in
    /// [extractAsync].
    @Volatile
    private var runtimeVersionLogged = false

    /// Set by MainActivity so Kotlin can push events back to Dart.
    @Volatile
    var channel: MethodChannel? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_EXTRACT_MEDIA -> {
                val url = call.argument<String>("url")?.trim()
                if (url.isNullOrEmpty()) {
                    result.error(ERROR_UNSUPPORTED_URL, "No URL provided.", null)
                    return
                }
                val timingRunId = call.argument<String>("timingRunId")
                extractAsync(url, timingRunId, result)
            }

            METHOD_START_DOWNLOAD -> {
                val downloadId = call.argument<String>("downloadId")?.trim()
                val url = call.argument<String>("url")?.trim()
                // May be a plain format id ("22") or a yt-dlp format
                // expression ("137+bestaudio/best"). Dart decides which.
                val formatId = call.argument<String>("formatId")?.trim()

                if (downloadId.isNullOrEmpty() || url.isNullOrEmpty() || formatId.isNullOrEmpty()) {
                    result.error(ERROR_DOWNLOAD_FAILED, "Missing download parameters.", null)
                    return
                }

                if (!activeDownloads.add(downloadId)) {
                    result.error(ERROR_DOWNLOAD_FAILED, "Download already running.", null)
                    return
                }

                // Where the user wants the finished file to land. Absent or
                // malformed input degrades to the plain Android default —
                // see StorageSettings.fromArgument.
                val storageSettings = StorageSettings.fromArgument(call.argument<Any?>("storage"))

                // Optional Download Options (filename override, audio
                // metadata). Absent/malformed input degrades to
                // DownloadOptions.NONE — the exact same as today's
                // behavior with no options at all.
                val downloadOptions = DownloadOptions.fromArgument(call.argument<Any?>("downloadOptions"))

                // 1-based position of the entry the user actually previewed,
                // when extraction returned several. Absent for ordinary
                // single-video URLs — and then the yt-dlp invocation below is
                // left exactly as it was. Read as Number because the channel
                // codec may deliver a Dart int as either Int or Long.
                val playlistIndex = (call.argument<Number>("playlistIndex"))
                    ?.toInt()
                    ?.takeIf { it >= 1 }

                // Acknowledge immediately; the download reports via events.
                // Dart has already armed its event filter with this id
                // before invoking, so a STARTED event emitted before this
                // ack resolves cannot be lost.
                result.success(null)
                downloadAsync(
                    downloadId,
                    url,
                    formatId,
                    storageSettings,
                    downloadOptions,
                    playlistIndex
                )
            }

            METHOD_CANCEL_DOWNLOAD -> {
                val downloadId = call.argument<String>("downloadId")?.trim()
                if (downloadId.isNullOrEmpty()) {
                    result.success(false)
                    return
                }
                val canceled = try {
                    YoutubeDL.getInstance().destroyProcessById(downloadId)
                } catch (throwable: Throwable) {
                    Log.e(TAG, "cancel failed", throwable)
                    false
                }
                result.success(canceled)
            }

            METHOD_UPDATE_YTDLP -> updateYtDlpAsync(result)
            METHOD_GET_YTDLP_VERSION -> getYtDlpVersionAsync(result)

            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------- download

    private fun downloadAsync(
        downloadId: String,
        url: String,
        formatId: String,
        storageSettings: StorageSettings,
        downloadOptions: DownloadOptions,
        playlistIndex: Int?
    ) {
        downloadExecutor.execute {
            try {
                // Emitted before engine init on purpose: the first cold-start
                // init unzips Python and FFmpeg, which can take several
                // seconds with no other feedback otherwise.
                emit(downloadId, STATUS_STARTED)

                ensureEngineReady()

                downloadFormat(
                    downloadId,
                    url,
                    formatId,
                    storageSettings,
                    downloadOptions,
                    playlistIndex
                )
            } catch (canceled: YoutubeDL.CanceledException) {
                emit(downloadId, STATUS_CANCELED)
            } catch (interrupted: InterruptedException) {
                emit(downloadId, STATUS_CANCELED)
                Thread.currentThread().interrupt()
            } catch (throwable: Throwable) {
                Log.e(TAG, "download failed", throwable)
                emit(
                    downloadId,
                    STATUS_FAILED,
                    errorCode = classify(throwable),
                    errorMessage = throwable.message ?: "Download failed."
                )
            } finally {
                activeDownloads.remove(downloadId)
            }
        }
    }

    /// One yt-dlp process for the whole job. When [formatId] is a "+"
    /// expression, yt-dlp downloads the streams and merges them internally
    /// using its own FFmpeg — we never orchestrate that ourselves.
    private fun downloadFormat(
        downloadId: String,
        url: String,
        formatId: String,
        storageSettings: StorageSettings,
        downloadOptions: DownloadOptions,
        playlistIndex: Int?
    ) {
        // A custom filename replaces only the base name — %(ext)s is kept
        // so yt-dlp still picks the correct extension itself. A literal
        // "%" in the user's text is escaped first so it can never be
        // misread as the start of a yt-dlp template reference.
        //
        // Video mode has a dedicated "Filename" field (downloadOptions
        // .filename). Audio mode has no separate filename field — the
        // "Song title" the user edits doubles as the output name too,
        // exactly like the video field does; falling back to it here is
        // what makes that happen (previously this only ever looked at
        // .filename, so an audio-only title edit never renamed the file).
        val customBaseName = downloadOptions.filename ?: downloadOptions.audioTitle
        val baseName = customBaseName?.replace("%", "%%") ?: "%(title)s"
        val template = File(resolveTempDirectory(), "$baseName.%(ext)s").absolutePath

        val result = runYtDlpDownload(
            downloadId,
            url,
            formatId,
            template,
            downloadOptions,
            playlistIndex
        )

        when (result) {
            is YtDlpDownloadResult.Success ->
                publishAndFinish(downloadId, result.file, storageSettings, downloadOptions)

            is YtDlpDownloadResult.Failure ->
                emit(
                    downloadId,
                    STATUS_FAILED,
                    errorCode = ERROR_DOWNLOAD_FAILED,
                    errorMessage = result.message
                )
        }
    }

    private sealed class YtDlpDownloadResult {
        data class Success(val file: File) : YtDlpDownloadResult()
        data class Failure(val message: String) : YtDlpDownloadResult()
    }

    private fun runYtDlpDownload(
        downloadId: String,
        url: String,
        formatId: String,
        outputTemplate: String,
        downloadOptions: DownloadOptions,
        playlistIndex: Int?
    ): YtDlpDownloadResult {
        // DIAGNOSTIC — kept from the previous investigation, unrelated to
        // this change.
        Log.d(TAG, "starting yt-dlp format=$formatId")

        var intermediateDestination: String? = null
        var mergedDestination: String? = null
        var lastEmit = 0L
        var lastProgress = -1f
        var lastTotalBytes: Long? = null
        var lastSpeedBytesPerSecond: Long? = null

        var sessionCookieFile: File? = null
        val request = YoutubeDLRequest(url).apply {
            applyTikTokAppApiWorkaround(url)
            sessionCookieFile = attachSessionCookiesIfAny(this, url)
            addOption("-f", formatId)
            addOption("-o", outputTemplate)
            // Strips characters invalid on FAT/exFAT while preserving
            // non-Latin titles, unlike --restrict-filenames which would
            // flatten Arabic to nothing.
            addOption("--windows-filenames")
            addOption("--trim-filenames", TRIM_FILENAME_LENGTH.toString())
            addOption("--no-playlist")
            // --no-playlist is only honored by extractors that check it.
            // Generic-style extractors return every entry they found in the
            // page regardless, and when those entries share one format id
            // (Snapchat does: all "0"), `-f <id>` matches all of them and a
            // single failing entry fails the whole job. Naming the exact
            // entry the user previewed is what makes the download resolve to
            // that one item.
            //
            // Only ever set from a playlist_index the extraction itself
            // reported, so a single-video URL — where it is absent — is
            // downloaded with the identical arguments as before.
            if (playlistIndex != null) {
                addOption("--playlist-items", playlistIndex.toString())
            }
            addOption("--no-mtime")
            // Direct yt-dlp's own temporary files (fragments, partial
            // downloads, subtitle intermediates) to the app's private cache
            // directory. Without this, Python's tempfile falls back to /tmp,
            // which is a read-only filesystem root on Android, causing:
            //   [Errno 30] Read-only file system: '/tmpXXXXXX.tmp'
            // This flag does NOT affect the final output path, which
            // resolveTempDirectory() still controls via -o.
            addOption("--paths", "temp:${appContext.cacheDir.absolutePath}")

            // Advanced Download Options: Subtitles. Only ever set from a
            // real language code this exact media's own `subtitles`/
            // `automatic_captions` reported — see DownloadOptions.kt and
            // the Dart-side subtitle picker. --embed-subs is yt-dlp's own
            // well-established mechanism (requires ffmpeg, which is
            // already bundled and already used for merging); it embeds the
            // track into mp4/mkv/webm outputs and removes the standalone
            // subtitle file it downloads as an intermediate step, so the
            // publish step below still sees exactly one final file, same
            // as every other download. Nothing here re-encodes video or
            // audio — this is a container-level mux, identical in kind to
            // yt-dlp's own existing merge step.
            downloadOptions.subtitleLanguage?.let { language ->
                if (downloadOptions.subtitleIsAutomatic) {
                    addOption("--write-auto-subs")
                } else {
                    addOption("--write-subs")
                }
                addOption("--sub-langs", language)
                addOption("--embed-subs")
            }
        }

        try {
        // Four positional args: the two execute() overloads both end in
        // `callback`, so a trailing lambda is ambiguous.
        val response = YoutubeDL.getInstance().execute(
            request,
            downloadId,
            false
        ) { progress: Float, etaSeconds: Long, line: String ->
            // DIAGNOSTIC — kept from the previous investigation, unrelated
            // to this change.
            Log.d(TAG, "yt-dlp: $line")

            DESTINATION_REGEX.find(line)?.let { intermediateDestination = it.groupValues[1].trim() }
            ALREADY_DOWNLOADED_REGEX.find(line)?.let { intermediateDestination = it.groupValues[1].trim() }
            // For a "+" format expression, this line reports the true final
            // file after yt-dlp merges the intermediate streams. It must win
            // over any [download] Destination: line seen before or after it —
            // those point at streams yt-dlp deletes post-merge.
            MERGER_REGEX.find(line)?.let { mergedDestination = it.groupValues[1].trim() }

            // The raw line already carries the byte totals and the transfer
            // rate that the library's callback does not expose, so they are
            // read from it rather than measured or estimated here.
            TOTAL_SIZE_REGEX.find(line)?.let {
                parseByteSize(it.groupValues[1], it.groupValues[2])?.let { bytes ->
                    lastTotalBytes = bytes
                }
            }
            SPEED_REGEX.find(line)?.let {
                lastSpeedBytesPerSecond =
                    parseByteSize(it.groupValues[1], it.groupValues[2])
            }

            val now = System.currentTimeMillis()
            val movedEnough = progress - lastProgress >= PROGRESS_STEP
            val waitedEnough = now - lastEmit >= PROGRESS_INTERVAL_MS

            if (movedEnough || waitedEnough) {
                lastEmit = now
                lastProgress = progress
                emit(
                    downloadId,
                    STATUS_RUNNING,
                    progress = progress,
                    etaSeconds = etaSeconds,
                    totalBytes = lastTotalBytes,
                    speedBytesPerSecond = lastSpeedBytesPerSecond
                )
            }
        }

        if (mergedDestination == null) {
            mergedDestination = MERGER_REGEX.find(response.out)?.groupValues?.get(1)?.trim()
        }
        if (intermediateDestination == null) {
            intermediateDestination = DESTINATION_REGEX.find(response.out)
                ?.groupValues?.get(1)?.trim()
                ?: ALREADY_DOWNLOADED_REGEX.find(response.out)
                    ?.groupValues?.get(1)?.trim()
        }

        // The merger line, when present, is always the authoritative final
        // file — this is what prevents an intermediate video-only or
        // audio-only file from ever being published.
        val destination = mergedDestination ?: intermediateDestination

        // DIAGNOSTIC — kept from the previous investigation, unrelated to
        // this change.
        Log.d(
            TAG,
            "yt-dlp finished: exitCode=${response.exitCode} " +
                "intermediateDestination=$intermediateDestination " +
                "mergedDestination=$mergedDestination"
        )
        Log.d(TAG, "yt-dlp response.out:\n${response.out}")
        Log.d(TAG, "yt-dlp response.err:\n${response.err}")

        val failure = describeFailure(response, destination)
        return when {
            failure != null -> YtDlpDownloadResult.Failure(failure)
            destination == null -> YtDlpDownloadResult.Failure(
                "The download finished but its output file could not be located."
            )
            else -> YtDlpDownloadResult.Success(File(destination))
        }
        } finally {
            sessionCookieFile?.delete()
        }
    }

    /// Copies the completed temporary file into shared storage, per
    /// [storageSettings], and only then removes the temporary source. On any
    /// publication failure the temporary file is deliberately left in place
    /// so nothing is lost.
    private fun publishAndFinish(
        downloadId: String,
        tempFile: File,
        storageSettings: StorageSettings,
        downloadOptions: DownloadOptions
    ) {
        // Optional, local, and a no-op unless downloadOptions actually
        // carries audio metadata or artwork — see DownloadPostProcessor.
        // Runs on the private temp copy, before publishing, so the file
        // that reaches shared storage already has it.
        val postProcessResult = DownloadPostProcessor.applyIfNeeded(appContext, tempFile, downloadOptions)
        val processedFile = postProcessResult.file

        when (val outcome = MediaStorePublisher.publish(appContext, processedFile, storageSettings)) {
            is PublishOutcome.Success -> {
                if (!processedFile.delete()) {
                    Log.w(TAG, "Published but could not delete ${processedFile.absolutePath}")
                }

                emit(
                    downloadId,
                    STATUS_COMPLETED,
                    progress = 100f,
                    outputPath = outcome.displayPath,
                    outputUri = outcome.uri,
                    // The download itself always succeeded by this point —
                    // this is only ever a soft, non-fatal note (e.g.
                    // artwork not supported for this container), never an
                    // error. Null on the common path where nothing needs
                    // explaining.
                    warningMessage = postProcessResult.artworkWarning
                )
            }

            is PublishOutcome.Failure -> {
                Log.e(TAG, "publication failed: ${outcome.message}")
                emit(
                    downloadId,
                    STATUS_FAILED,
                    errorCode = ERROR_STORAGE_PUBLISH_FAILED,
                    errorMessage = outcome.message
                )
            }
        }
    }

    /// Returns null when the download genuinely succeeded, otherwise a
    /// human-readable reason. execute() normally throws on a non-zero exit,
    /// but ignoreErrors can let one through, so it is checked explicitly.
    private fun describeFailure(
        response: YoutubeDLResponse,
        destination: String?
    ): String? {
        if (response.exitCode != 0) {
            val detail = response.err.trim().ifEmpty { response.out.trim() }
            return if (detail.isEmpty()) {
                "yt-dlp exited with code ${response.exitCode}."
            } else {
                detail.takeLast(MAX_ERROR_CHARS)
            }
        }

        if (destination == null) return null

        val file = File(destination)
        if (!file.exists()) {
            return "Download reported success but no file was written to $destination"
        }
        if (file.length() <= 0L) {
            return "Download reported success but the file is empty: $destination"
        }

        return null
    }

    /// App-private staging area. yt-dlp needs a real filesystem path, so the
    /// file is written here first and copied into MediaStore afterwards.
    private fun resolveTempDirectory(): File {
        val base = appContext.getExternalFilesDir(null) ?: appContext.filesDir
        val dir = File(base, "downloads")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun emit(
        downloadId: String,
        status: String,
        progress: Float? = null,
        etaSeconds: Long? = null,
        totalBytes: Long? = null,
        speedBytesPerSecond: Long? = null,
        outputPath: String? = null,
        outputUri: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null,
        warningMessage: String? = null
    ) {
        val payload = mapOf(
            "downloadId" to downloadId,
            "status" to status,
            "progress" to progress?.toDouble(),
            "etaSeconds" to etaSeconds,
            "totalBytes" to totalBytes,
            "speedBytesPerSecond" to speedBytesPerSecond,
            "outputPath" to outputPath,
            "outputUri" to outputUri,
            "errorCode" to errorCode,
            "errorMessage" to errorMessage,
            "warningMessage" to warningMessage
        )

        mainHandler.post {
            channel?.invokeMethod(METHOD_ON_DOWNLOAD_EVENT, payload)
        }
    }

    // --------------------------------------------------------------- extract

    private fun extractAsync(url: String, timingRunId: String?, result: MethodChannel.Result) {
        // Falls back to a locally-generated id so native's own logs stay
        // usable even if Dart didn't supply one (e.g. an older build, or
        // diagnostics disabled on the Dart side only).
        val runId = timingRunId ?: "N${System.nanoTime() % 100000}"
        FetchyTiming.start(runId)
        val platform = FetchyTiming.sanitizedHost(url)
        FetchyTiming.checkpoint(runId, "NATIVE_REQUEST_RECEIVED", "platform=$platform")

        extractExecutor.execute {
            var sessionCookieFile: File? = null
            try {
                val readyWaitStartMs = FetchyTiming.elapsedMs(runId)
                ensureEngineReady(runId)
                val warmupWaitMs = FetchyTiming.elapsedMs(runId) - readyWaitStartMs

                // Logged at most once per process — reuses the cached
                // SharedPrefs value the update writes, never spawns a
                // yt-dlp process just for this log line.
                if (!runtimeVersionLogged) {
                    runtimeVersionLogged = true
                    val cachedVersion = try {
                        YoutubeDL.version(appContext)
                    } catch (throwable: Throwable) {
                        null
                    } ?: "unknown"
                    FetchyTiming.checkpoint(runId, "ENGINE_RUNTIME_VERSION", "version=$cachedVersion")
                }

                val sessionPrepStartMs = FetchyTiming.elapsedMs(runId)
                FetchyTiming.checkpoint(runId, "SESSION_CHECK_STARTED")
                val request = YoutubeDLRequest(url).apply {
                    applyTikTokAppApiWorkaround(url)
                    sessionCookieFile = attachSessionCookiesIfAny(this, url)
                }
                FetchyTiming.checkpoint(
                    runId,
                    "SESSION_COOKIES_ATTACHED",
                    "hasCookies=${sessionCookieFile != null}",
                )
                val sessionPrepMs = FetchyTiming.elapsedMs(runId) - sessionPrepStartMs
                FetchyTiming.checkpoint(runId, "SESSION_CHECK_FINISHED")

                FetchyTiming.checkpoint(runId, "METADATA_EXTRACTION_STARTED")
                val extractionStartMs = FetchyTiming.elapsedMs(runId)
                // Equivalent to YoutubeDL.getInstance().getInfo(request), which
                // internally does exactly this (addOption("--dump-json") +
                // execute() + a Jackson parse) then throws the raw JSON away.
                // Calling execute() ourselves and parsing that same stdout
                // costs nothing extra — it is the same single yt-dlp process —
                // and lets RawMediaInfoParser read fields (dynamic_range,
                // subtitles, audio_channels, artist/album/track, ...) that the
                // bundled wrapper's VideoInfo/VideoFormat classes never parse.
                request.addOption("--dump-json")
                val response = YoutubeDL.getInstance().execute(request, null, false, null)
                val extractionMs = FetchyTiming.elapsedMs(runId) - extractionStartMs
                FetchyTiming.checkpoint(runId, "METADATA_EXTRACTION_FINISHED")

                val payload = RawMediaInfoParser.parseMediaInfoPayload(response.out, url)
                mainHandler.post {
                    result.success(payload)
                    FetchyTiming.checkpoint(runId, "ENGINE_RESULT_DELIVERED_TO_DART")
                }

                FetchyTiming.summary(
                    runId = runId,
                    platform = platform,
                    success = true,
                    warmupWaitMs = warmupWaitMs,
                    sessionPrepMs = sessionPrepMs,
                    extractionMs = extractionMs,
                )
            } catch (throwable: Throwable) {
                val code = classify(throwable)
                // Sanitized: exception class + coarse code only — never
                // the raw exception message or request/response bodies
                // (which may carry cookies).
                FetchyTiming.checkpoint(
                    runId,
                    "EXTRACTION_FAILED",
                    "code=$code type=${throwable::class.simpleName}",
                )
                FetchyTiming.summary(
                    runId = runId,
                    platform = platform,
                    success = false,
                    failedStage = "METADATA_EXTRACTION",
                    errorCategory = code,
                )
                val message = throwable.message ?: "Extraction failed."
                mainHandler.post { result.error(code, message, null) }
            } finally {
                sessionCookieFile?.delete()
            }
        }
    }

    // ---------------------------------------------------- yt-dlp runtime version

    /// The single source of truth for the yt-dlp version.
    ///
    /// Runs `yt-dlp --version` through the same YoutubeDL engine instance
    /// used for extraction and downloads, rather than trusting
    /// YoutubeDL.version(appContext) — which only reflects a SharedPrefs
    /// value written after a successful update, not the actual installed
    /// runtime, and returns null until an update has ever run.
    private fun executeRuntimeVersionCheck(): String {
        Log.d(TAG, "checking runtime yt-dlp version")

        ensureEngineReady()

        // YoutubeDLRequest requires a URL even though --version never
        // reaches it (yt-dlp prints the version and exits before parsing
        // positionals). ".invalid" is the RFC 2606-reserved TLD reserved
        // exactly for placeholders that must never resolve or be contacted.
        val request = YoutubeDLRequest(VERSION_PROBE_URL).apply {
            addOption("--version")
        }

        val response = YoutubeDL.getInstance().execute(request, null, false, null)

        // Last non-blank line: yt-dlp may print update notices before the
        // version string itself.
        val version = response.out
            .trim()
            .lineSequence()
            .lastOrNull { it.isNotBlank() }
            ?.trim()
            .orEmpty()

        if (response.exitCode != 0 || version.isEmpty()) {
            val detail = response.err.trim().ifEmpty { response.out.trim() }
            throw YoutubeDLException(
                "yt-dlp --version exited with code ${response.exitCode}" +
                    if (detail.isNotEmpty()) ": $detail" else "."
            )
        }

        Log.d(TAG, "runtime yt-dlp version: $version")
        return version
    }

    private fun updateYtDlpAsync(result: MethodChannel.Result) {
        extractExecutor.execute {
            try {
                ensureEngineReady()

                // DIAGNOSTIC — investigating why the updater never records
                // dlpVersion in SharedPrefs. The updater only writes that
                // key after it has successfully replaced the binary below.
                val noBackupDir = appContext.noBackupFilesDir
                val expectedYtDlpFile = File(noBackupDir, "youtubedl-android/yt-dlp/yt-dlp")
                Log.d(TAG, "noBackupFilesDir=${noBackupDir.absolutePath}")
                Log.d(
                    TAG,
                    "expected yt-dlp path=${expectedYtDlpFile.absolutePath} " +
                        "exists=${expectedYtDlpFile.exists()} " +
                        "size=${if (expectedYtDlpFile.exists()) expectedYtDlpFile.length() else -1L}"
                )

                Log.d(TAG, "starting ytdlp runtime update")

                val status = YoutubeDL.getInstance().updateYoutubeDL(
                    appContext,
                    YoutubeDL.UpdateChannel.STABLE
                )

                Log.d(TAG, "update returned status=$status")
                Log.d(
                    TAG,
                    "after update: yt-dlp exists=${expectedYtDlpFile.exists()} " +
                        "size=${if (expectedYtDlpFile.exists()) expectedYtDlpFile.length() else -1L}"
                )
                Log.d(TAG, "yt-dlp update status: $status")

                // A failure here means the version probe itself failed, not
                // that the update failed — the update already succeeded
                // above, so it is reported as a non-fatal null rather than
                // turning a real success into an error.
                val versionAfterUpdate = try {
                    executeRuntimeVersionCheck()
                } catch (throwable: Throwable) {
                    Log.e(TAG, "Failed to read yt-dlp version after update", throwable)
                    null
                }
                Log.d(TAG, "yt-dlp version after update: $versionAfterUpdate")

                mainHandler.post {
                    result.success(
                        mapOf(
                            "status" to status?.name,
                            "version" to versionAfterUpdate
                        )
                    )
                }
            } catch (throwable: Throwable) {
                // DIAGNOSTIC — full stacktrace, plus the cause chain, since
                // YoutubeDLException wraps the underlying IOException that
                // would explain a failed GitHub fetch or file replacement.
                Log.e(TAG, "yt-dlp update failed", throwable)
                Log.e(TAG, "update failure stacktrace:\n${Log.getStackTraceString(throwable)}")
                var cause: Throwable? = throwable.cause
                while (cause != null) {
                    Log.e(TAG, "update failure cause: ${cause.javaClass.name}: ${cause.message}")
                    cause = cause.cause
                }

                mainHandler.post {
                    result.error(
                        ERROR_UPDATE_FAILED,
                        throwable.message ?: "Failed to update yt-dlp.",
                        null
                    )
                }
            }
        }
    }

    private fun getYtDlpVersionAsync(result: MethodChannel.Result) {
        extractExecutor.execute {
            try {
                val version = executeRuntimeVersionCheck()
                mainHandler.post { result.success(version) }
            } catch (throwable: Throwable) {
                Log.e(TAG, "Failed to get yt-dlp runtime version", throwable)
                mainHandler.post {
                    result.error(
                        ERROR_ENGINE_UNAVAILABLE,
                        throwable.message ?: "Unable to determine yt-dlp version.",
                        null
                    )
                }
            }
        }
    }

    /// Waits for the one-time engine warm-up ([engineWarmup], started at
    /// construction time — see MainActivity) to finish, then returns
    /// immediately. Called at the top of every extract/download so neither
    /// can ever run against a not-yet-initialized engine or a yt-dlp binary
    /// that is still mid-update; in the common case this warm-up already
    /// finished during the user's own think-time on Home, so this blocks
    /// for ~0ms. This is the single initialization path shared by
    /// extraction, downloads, and the runtime version check.
    ///
    /// [runId], when provided, brackets the wait with
    /// ENGINE_READY_WAIT_STARTED/ENGINE_READY checkpoints under that run's
    /// own id — comparing their delta against the WARMUP timeline's own
    /// ENGINE_WARMUP_FINISHED wall-clock time shows whether warm-up had
    /// already finished before this Fetch (wait ~0ms) or was still running
    /// (wait = however many ms were left).
    private fun ensureEngineReady(runId: String? = null) {
        if (runId != null) FetchyTiming.checkpoint(runId, "ENGINE_READY_WAIT_STARTED")
        engineWarmup.get()
        if (runId != null) FetchyTiming.checkpoint(runId, "ENGINE_READY")
    }

    /// Runs exactly once per process, on [warmupExecutor], starting the
    /// instant this handler is constructed. Native init is local/fast;
    /// updateYoutubeDL() is a network call and is the dominant cost of a
    /// cold start — see TIMING logs. An update failure must not block the
    /// app from using the bundled runtime, so it is caught and logged
    /// rather than rethrown; [engineReady] is set before the update runs,
    /// so extraction/download can still proceed on the bundled binary even
    /// if the network check itself never completes.
    private fun performEngineWarmup() {
        FetchyTiming.checkpoint(WARMUP_RUN_ID, "ENGINE_WARMUP_STARTED")

        FetchyTiming.checkpoint(WARMUP_RUN_ID, "ENGINE_INIT_STARTED")
        YoutubeDL.getInstance().init(appContext)
        FetchyTiming.checkpoint(WARMUP_RUN_ID, "ENGINE_INIT_FINISHED")

        FetchyTiming.checkpoint(WARMUP_RUN_ID, "FFMPEG_INIT_STARTED")
        FFmpeg.getInstance().init(appContext)
        FetchyTiming.checkpoint(WARMUP_RUN_ID, "FFMPEG_INIT_FINISHED")

        engineReady = true

        try {
            FetchyTiming.checkpoint(WARMUP_RUN_ID, "YTDLP_UPDATE_STARTED")
            val status = YoutubeDL.getInstance().updateYoutubeDL(
                appContext,
                YoutubeDL.UpdateChannel.STABLE
            )
            FetchyTiming.checkpoint(WARMUP_RUN_ID, "YTDLP_UPDATE_FINISHED", "status=$status")
        } catch (throwable: Throwable) {
            Log.e(TAG, "automatic yt-dlp update failed", throwable)
            FetchyTiming.checkpoint(
                WARMUP_RUN_ID,
                "YTDLP_UPDATE_FINISHED",
                "status=FAILED type=${throwable::class.simpleName}",
            )
        }

        FetchyTiming.checkpoint(WARMUP_RUN_ID, "ENGINE_WARMUP_FINISHED")
    }

    /// Converts a yt-dlp size token ("26.90", "MiB") into bytes. Returns null
    /// for anything unparseable, so an unrecognised unit shows as "unknown"
    /// rather than a wrong number.
    private fun parseByteSize(value: String, unit: String): Long? {
        val amount = value.toDoubleOrNull() ?: return null
        if (amount <= 0.0) return null

        val multiplier = when (unit) {
            "B" -> 1L
            "KiB" -> 1024L
            "MiB" -> 1024L * 1024
            "GiB" -> 1024L * 1024 * 1024
            "TiB" -> 1024L * 1024 * 1024 * 1024
            else -> return null
        }

        return (amount * multiplier).toLong()
    }

    /// yt-dlp's TikTok extractor normally scrapes the web page, which now
    /// sits behind an anti-bot challenge that fails without browser
    /// impersonation (unavailable in this bundle — see the "impersonate
    /// target" warning). The extractor also has a separate, built-in
    /// mobile-app-API path that avoids that page entirely, but only tries
    /// it when a "device_id" is configured — otherwise it goes straight to
    /// the web page. Supplying one costs nothing: the API path is only
    /// ever attempted *before* the existing web-scraping fallback, so a
    /// request that would have failed before still falls through to the
    /// same behavior as today if the API path also fails.
    private fun YoutubeDLRequest.applyTikTokAppApiWorkaround(url: String) {
        if (!isTikTokUrl(url)) return
        val deviceId = (7_250_000_000_000_000_000L..7_325_099_899_999_994_577L).random()
        addOption("--extractor-args", "tiktok:device_id=$deviceId")
    }

    private fun isTikTokUrl(url: String): Boolean {
        val host = Uri.parse(url).host?.lowercase() ?: return false
        return host == "tiktok.com" || host.endsWith(".tiktok.com")
    }

    /// Connected Accounts/Sessions, Phase 2 — plus the General Cookie
    /// Manager: if [url] belongs to one of the four built-in platforms
    /// with a stored session, materializes that session's cookies exactly
    /// as before. Otherwise, falls back to checking the General Cookie
    /// Manager's arbitrary-domain store for a domain matching [url]'s
    /// host. Either way, at most one cookie file is ever attached, and a
    /// URL matching neither returns null with the request untouched: the
    /// public/no-session path is bit-for-bit what it was before either
    /// system existed. The returned file (if any) must be deleted by the
    /// caller once the yt-dlp invocation that needed it has finished; it
    /// is never left on disk longer than that single request.
    ///
    /// Domain isolation is structural, not just a filtering rule: a
    /// built-in platform's own session is looked up by the fixed
    /// [SessionPlatform] the URL resolves to (never by host string
    /// matching), and the custom store is only ever consulted at all once
    /// that lookup has already returned null — so a built-in platform's
    /// session can never be shadowed by a custom entry, and a custom
    /// domain's cookies can never be handed to an unrelated built-in
    /// platform's request or vice versa.
    private fun attachSessionCookiesIfAny(request: YoutubeDLRequest, url: String): File? {
        val platform = SessionPlatform.fromUrl(url)
        val cookieFile = if (platform != null) {
            sessionStore.materializeCookiesFile(platform)
        } else {
            val host = try {
                Uri.parse(url).host?.lowercase()
            } catch (throwable: Throwable) {
                null
            }
            customCookieStore.materializeCookiesFileForHost(host)
        } ?: return null

        request.addOption("--cookies", cookieFile.absolutePath)
        return cookieFile
    }

    private fun classify(throwable: Throwable): String {
        val text = (throwable.message ?: "").lowercase()
        return when {
            text.contains("javascript runtime") ||
                text.contains("yt-dlp-ejs") -> ERROR_JS_RUNTIME_REQUIRED

            text.contains("sign in to confirm") ||
                text.contains("not a bot") ||
                text.contains("403") -> ERROR_BOT_PROTECTION

            text.contains("unsupported url") ||
                text.contains("is not a valid url") -> ERROR_UNSUPPORTED_URL

            text.contains("unable to download webpage") ||
                text.contains("timed out") ||
                text.contains("network") ||
                text.contains("connection") -> ERROR_NETWORK

            text.contains("instance not initialized") -> ERROR_ENGINE_UNAVAILABLE

            text.contains("no space left") ||
                text.contains("permission denied") -> ERROR_DOWNLOAD_FAILED

            else -> ERROR_EXTRACTION_FAILED
        }
    }

    fun dispose() {
        channel = null
        extractExecutor.shutdownNow()
        downloadExecutor.shutdownNow()
        warmupExecutor.shutdownNow()
    }

    companion object {
        private const val TAG = "FetchyEngine"

        /// Pseudo run-id for the one-time, process-level engine warm-up —
        /// it isn't tied to any single Fetch, so it doesn't get an F00N id.
        /// TEMPORARY, part of the Fetch timing diagnostics — see
        /// com.example.fetchy.timing.FetchyTiming.
        private const val WARMUP_RUN_ID = "WARMUP"

        const val ENGINE_CHANNEL = "app.fetchy/engine"

        private const val METHOD_EXTRACT_MEDIA = "extractMedia"
        private const val METHOD_START_DOWNLOAD = "startDownload"
        private const val METHOD_CANCEL_DOWNLOAD = "cancelDownload"
        private const val METHOD_ON_DOWNLOAD_EVENT = "onDownloadEvent"
        private const val METHOD_UPDATE_YTDLP = "updateYtDlp"
        private const val METHOD_GET_YTDLP_VERSION = "getYtDlpVersion"

        private const val STATUS_STARTED = "started"
        private const val STATUS_RUNNING = "running"
        private const val STATUS_COMPLETED = "completed"
        private const val STATUS_FAILED = "failed"
        private const val STATUS_CANCELED = "canceled"

        private const val ERROR_UPDATE_FAILED = "update_failed"
        private const val ERROR_ENGINE_UNAVAILABLE = "engine_unavailable"
        private const val ERROR_UNSUPPORTED_URL = "unsupported_url"
        private const val ERROR_NETWORK = "network"
        private const val ERROR_JS_RUNTIME_REQUIRED = "js_runtime_required"
        private const val ERROR_BOT_PROTECTION = "bot_protection"
        private const val ERROR_EXTRACTION_FAILED = "extraction_failed"
        private const val ERROR_DOWNLOAD_FAILED = "download_failed"
        private const val ERROR_STORAGE_PUBLISH_FAILED = "storage_publish_failed"

        private const val PROGRESS_INTERVAL_MS = 250L
        private const val PROGRESS_STEP = 0.5f
        private const val MAX_ERROR_CHARS = 500
        private const val TRIM_FILENAME_LENGTH = 120

        /// Never resolved or contacted — .invalid is reserved by RFC 2606
        /// specifically for placeholders like this. --version exits before
        /// yt-dlp would ever use it.
        private const val VERSION_PROBE_URL = "https://version-check.invalid"

        /// "[download]  4.2% of ~ 26.90MiB at 2.41MiB/s ETA 00:11"
        /// The optional "~" marks an approximate total, which yt-dlp reports
        /// for fragmented streams; it is still a real reported figure.
        private val TOTAL_SIZE_REGEX =
            Regex("""of\s+~?\s*([\d.]+)\s*(B|KiB|MiB|GiB|TiB)""")
        private val SPEED_REGEX =
            Regex("""at\s+([\d.]+)\s*(B|KiB|MiB|GiB|TiB)/s""")

        private val DESTINATION_REGEX =
            Regex("""\[download]\s+Destination:\s+(.+)""")
        private val ALREADY_DOWNLOADED_REGEX =
            Regex("""\[download]\s+(.+?)\s+has already been downloaded""")
        private val MERGER_REGEX =
            Regex("""\[Merger]\s+Merging formats into\s+"(.+)"""")
    }
}
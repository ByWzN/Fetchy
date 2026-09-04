// android/app/src/main/kotlin/com/example/fetchy/update/AppUpdateChannelHandler.kt
package com.example.fetchy.update

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future

/// Everything about the in-app update that only Android can answer or do.
///
/// Deliberately self-contained: it shares no state with the media
/// downloader, the yt-dlp engine, sessions, or MediaStore publishing. The
/// only thing it writes is one file in the app's own cache directory.
///
/// The install path is intentionally the ordinary, user-visible one — the
/// system package installer, which the user must confirm. There is no
/// silent install, no root path, and no signature bypass anywhere here.
class AppUpdateChannelHandler(
    private val appContext: Context
) : MethodChannel.MethodCallHandler {

    var activity: Activity? = null
    var channel: MethodChannel? = null

    private val downloadExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var downloadTask: Future<*>? = null

    @Volatile
    private var canceled = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_INSTALLED_VERSION -> result.success(installedVersionPayload())

            METHOD_CAN_REQUEST_INSTALLS -> result.success(canRequestPackageInstalls())

            METHOD_OPEN_INSTALL_SETTINGS -> result.success(openInstallPermissionSettings())

            METHOD_DOWNLOAD -> {
                val url = call.argument<String>("url")?.trim()
                val fileName = call.argument<String>("fileName")?.trim()
                val expectedSize = (call.argument<Number>("expectedSizeBytes"))?.toLong()

                if (url.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                    result.error(ERROR_DOWNLOAD_FAILED, "Missing download parameters.", null)
                    return
                }

                startDownload(url, fileName, expectedSize, result)
            }

            METHOD_CANCEL_DOWNLOAD -> {
                canceled = true
                downloadTask?.cancel(true)
                result.success(null)
            }

            METHOD_INSTALL -> {
                val path = call.argument<String>("path")?.trim()
                if (path.isNullOrEmpty()) {
                    result.error(ERROR_CORRUPT_DOWNLOAD, "No downloaded update to install.", null)
                    return
                }
                verifyAndLaunchInstaller(path, result)
            }

            else -> result.notImplemented()
        }
    }

    // ------------------------------------------------------------- version

    /// The app's own identity as Android reports it. versionCode is the
    /// value Android enforces monotonicity on and is what every safety
    /// check below compares against — versionName is only a label.
    private fun installedVersionPayload(): Map<String, Any?> {
        val info = installedPackageInfo()
        return mapOf(
            "versionName" to (info?.versionName ?: ""),
            "versionCode" to (info?.let { longVersionCodeOf(it) } ?: 0L),
            "packageName" to appContext.packageName
        )
    }

    private fun installedPackageInfo(flags: Int = 0): PackageInfo? = try {
        appContext.packageManager.getPackageInfo(appContext.packageName, flags)
    } catch (throwable: Throwable) {
        Log.w(TAG, "Could not read this app's own package info", throwable)
        null
    }

    @Suppress("DEPRECATION")
    private fun longVersionCodeOf(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
        else info.versionCode.toLong()

    // ---------------------------------------------------------- permission

    /// Below Android 8 "unknown sources" is a single device-wide setting
    /// with no per-app query, so there is nothing this app can check and
    /// the installer intent is simply attempted.
    private fun canRequestPackageInstalls(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        return try {
            appContext.packageManager.canRequestPackageInstalls()
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not query install permission", throwable)
            false
        }
    }

    /// Sends the user to the exact per-app "Install unknown apps" screen on
    /// Android 8+, falling back to the general security settings when the
    /// device has no such screen.
    private fun openInstallPermissionSettings(): Boolean {
        val host = activity ?: appContext

        val intents = mutableListOf<Intent>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intents += Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${appContext.packageName}")
            )
            intents += Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
        }
        intents += Intent(Settings.ACTION_SECURITY_SETTINGS)

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                host.startActivity(intent)
                return true
            } catch (ignored: ActivityNotFoundException) {
                // Try the next, less specific screen.
            } catch (throwable: Throwable) {
                Log.w(TAG, "Could not open install permission settings", throwable)
            }
        }

        return false
    }

    // ----------------------------------------------------------- download

    /// Downloads into the app's own cache directory — never into public
    /// Downloads. The file is a transient artifact of one update attempt,
    /// it is replaced on every attempt, and Android is free to reclaim it.
    private fun startDownload(
        url: String,
        fileName: String,
        expectedSizeBytes: Long?,
        result: MethodChannel.Result
    ) {
        if (downloadTask?.isDone == false) {
            result.error(ERROR_DOWNLOAD_FAILED, "An update download is already running.", null)
            return
        }

        canceled = false
        downloadTask = downloadExecutor.submit {
            try {
                val file = performDownload(url, fileName, expectedSizeBytes)
                mainHandler.post { result.success(file.absolutePath) }
            } catch (interrupted: InterruptedException) {
                mainHandler.post { result.error(ERROR_CANCELED, "Update download canceled.", null) }
            } catch (throwable: Throwable) {
                Log.w(TAG, "Update download failed", throwable)
                val code = if (canceled) ERROR_CANCELED else ERROR_DOWNLOAD_FAILED
                val message = if (canceled) {
                    "Update download canceled."
                } else {
                    throwable.message ?: "The update could not be downloaded."
                }
                mainHandler.post { result.error(code, message, null) }
            }
        }
    }

    private fun performDownload(
        rawUrl: String,
        fileName: String,
        expectedSizeBytes: Long?
    ): File {
        val parsed = URL(rawUrl)
        // Update payloads are only ever fetched over TLS. A plain-http
        // release URL is refused rather than downgraded.
        if (!parsed.protocol.equals("https", ignoreCase = true)) {
            throw IOException("Update downloads must use https.")
        }

        val directory = File(appContext.cacheDir, UPDATE_CACHE_DIR)
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Could not prepare the update cache directory.")
        }

        // One slot, reused every attempt: a stale or partial APK from a
        // previous try is never left behind to be installed by accident.
        directory.listFiles()?.forEach { it.delete() }

        val target = File(directory, sanitizeFileName(fileName))

        var connection = parsed.openConnection() as HttpURLConnection
        var redirects = 0
        try {
            while (true) {
                connection.instanceFollowRedirects = false
                connection.connectTimeout = CONNECT_TIMEOUT_MS
                connection.readTimeout = READ_TIMEOUT_MS
                connection.setRequestProperty("User-Agent", USER_AGENT)
                connection.setRequestProperty("Accept", "application/octet-stream")

                val status = connection.responseCode
                val isRedirect = status == HttpURLConnection.HTTP_MOVED_PERM ||
                    status == HttpURLConnection.HTTP_MOVED_TEMP ||
                    status == HttpURLConnection.HTTP_SEE_OTHER ||
                    status == 307 ||
                    status == 308

                if (!isRedirect) {
                    if (status != HttpURLConnection.HTTP_OK) {
                        throw IOException("GitHub returned HTTP $status for the update file.")
                    }
                    break
                }

                // GitHub serves release assets via a redirect to its object
                // storage, so redirects are followed manually in order to
                // re-assert the https-only rule on each hop.
                if (++redirects > MAX_REDIRECTS) {
                    throw IOException("Too many redirects while fetching the update.")
                }
                val location = connection.getHeaderField("Location")
                    ?: throw IOException("Update download redirect had no destination.")
                val next = URL(parsed, location)
                if (!next.protocol.equals("https", ignoreCase = true)) {
                    throw IOException("Update downloads must use https.")
                }
                connection.disconnect()
                connection = next.openConnection() as HttpURLConnection
            }

            val declaredLength = connection.contentLength.toLong().takeIf { it > 0 }
            val totalBytes = declaredLength ?: expectedSizeBytes
            if (totalBytes != null && totalBytes > MAX_APK_BYTES) {
                throw IOException("The update file is unexpectedly large.")
            }

            var received = 0L
            var lastReport = 0L

            connection.inputStream.use { input ->
                target.outputStream().use { output ->
                    val buffer = ByteArray(DOWNLOAD_BUFFER_BYTES)
                    while (true) {
                        if (canceled || Thread.currentThread().isInterrupted) {
                            throw InterruptedException()
                        }
                        val read = input.read(buffer)
                        if (read < 0) break

                        output.write(buffer, 0, read)
                        received += read

                        if (received > MAX_APK_BYTES) {
                            throw IOException("The update file is unexpectedly large.")
                        }

                        val now = System.currentTimeMillis()
                        if (now - lastReport >= PROGRESS_INTERVAL_MS) {
                            lastReport = now
                            emitProgress(received, totalBytes)
                        }
                    }
                    output.flush()
                }
            }

            emitProgress(received, totalBytes)

            if (received <= 0L) {
                throw IOException("The update file was empty.")
            }
            if (totalBytes != null && received != totalBytes) {
                throw IOException("The update file was incomplete.")
            }

            return target
        } catch (throwable: Throwable) {
            target.delete()
            throw throwable
        } finally {
            connection.disconnect()
        }
    }

    /// Only ever a basename, and only characters that are safe in one. The
    /// name comes from a GitHub asset, so it is treated as untrusted input
    /// and can never escape the cache directory.
    private fun sanitizeFileName(raw: String): String {
        val base = raw.substringAfterLast('/').substringAfterLast('\\')
        val cleaned = base.filter { it.isLetterOrDigit() || it == '.' || it == '-' || it == '_' }
        return if (cleaned.endsWith(".apk", ignoreCase = true) && cleaned.length > 4) {
            cleaned
        } else {
            DEFAULT_APK_NAME
        }
    }

    private fun emitProgress(receivedBytes: Long, totalBytes: Long?) {
        val payload = mapOf(
            "receivedBytes" to receivedBytes,
            "totalBytes" to totalBytes
        )
        mainHandler.post {
            channel?.invokeMethod(METHOD_ON_DOWNLOAD_PROGRESS, payload)
        }
    }

    // ------------------------------------------------------------- install

    /// Verifies the downloaded APK really is a newer build of *this* app,
    /// signed with the same key, and only then hands it to the system
    /// package installer for the user to confirm.
    ///
    /// Android performs its own signature check when installing an update;
    /// the check here does not replace it and never relaxes it. It exists
    /// so a mismatch is reported as a clear, understandable message before
    /// the user is sent into the installer, instead of as a bare system
    /// failure afterwards.
    private fun verifyAndLaunchInstaller(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists() || file.length() <= 0L) {
            result.error(ERROR_CORRUPT_DOWNLOAD, "The downloaded update is missing.", null)
            return
        }

        val packageManager = appContext.packageManager
        val archive = try {
            packageManager.getPackageArchiveInfo(path, signingCertificateFlag())?.also {
                // Required before signatures can be read off an archive.
                it.applicationInfo?.apply {
                    sourceDir = path
                    publicSourceDir = path
                }
            }
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not read the downloaded APK", throwable)
            null
        }

        if (archive == null) {
            result.error(ERROR_CORRUPT_DOWNLOAD, "The downloaded file is not a valid APK.", null)
            return
        }

        // 1. Identity: never install an APK for a different application id.
        if (archive.packageName != appContext.packageName) {
            result.error(
                ERROR_PACKAGE_MISMATCH,
                "That APK is for ${archive.packageName}, not Fetchy.",
                null
            )
            return
        }

        // 2. Monotonic versionCode, checked against the real value inside
        //    the APK rather than anything the release page claimed.
        val installed = installedPackageInfo()
        val installedCode = installed?.let { longVersionCodeOf(it) } ?: 0L
        val candidateCode = longVersionCodeOf(archive)
        if (candidateCode <= installedCode) {
            result.error(
                ERROR_NOT_NEWER,
                "That build is not newer than the installed one.",
                null
            )
            return
        }

        // 3. Same signing key. A mismatch means Android would reject the
        //    update, and it is reported here rather than bypassed.
        val installedSignatures = signingCertificatesOf(installedPackageInfo(signingCertificateFlag()))
        val candidateSignatures = signingCertificatesOf(archive)
        if (installedSignatures.isEmpty() || candidateSignatures.isEmpty() ||
            installedSignatures.intersect(candidateSignatures).isEmpty()
        ) {
            result.error(
                ERROR_SIGNATURE_MISMATCH,
                "The update is signed with a different key than the installed app.",
                null
            )
            return
        }

        // 4. The user must be able to approve an install at all.
        if (!canRequestPackageInstalls()) {
            result.error(
                ERROR_PERMISSION_REQUIRED,
                "Fetchy is not allowed to install apps on this device yet.",
                null
            )
            return
        }

        val contentUri = try {
            FileProvider.getUriForFile(
                appContext,
                "${appContext.packageName}.fileprovider",
                file
            )
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not share the update through FileProvider", throwable)
            null
        }

        if (contentUri == null) {
            result.error(ERROR_UNKNOWN, "The update could not be handed to the installer.", null)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            (activity ?: appContext).startActivity(intent)
            result.success(null)
        } catch (notFound: ActivityNotFoundException) {
            Log.w(TAG, "No package installer available", notFound)
            result.error(ERROR_UNKNOWN, "This device has no package installer available.", null)
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not launch the package installer", throwable)
            result.error(ERROR_UNKNOWN, throwable.message ?: "Could not start the installer.", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun signingCertificateFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) PackageManager.GET_SIGNING_CERTIFICATES
        else PackageManager.GET_SIGNATURES

    /// SHA-256 of each signing certificate, so two packages can be compared
    /// without holding raw certificate bytes around.
    @Suppress("DEPRECATION")
    private fun signingCertificatesOf(info: PackageInfo?): Set<String> {
        if (info == null) return emptySet()

        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signing = info.signingInfo ?: return emptySet()
            if (signing.hasMultipleSigners()) signing.apkContentsSigners
            else signing.signingCertificateHistory
        } else {
            info.signatures
        } ?: return emptySet()

        return signatures.mapNotNull { signature ->
            try {
                val digest = MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())
                digest.joinToString("") { "%02x".format(it) }
            } catch (throwable: Throwable) {
                Log.w(TAG, "Could not digest a signing certificate", throwable)
                null
            }
        }.toSet()
    }

    fun dispose() {
        canceled = true
        downloadTask?.cancel(true)
        downloadTask = null
        downloadExecutor.shutdownNow()
        channel = null
        activity = null
    }

    companion object {
        private const val TAG = "FetchyAppUpdate"

        const val CHANNEL = "app.fetchy/app_update"

        private const val METHOD_GET_INSTALLED_VERSION = "getInstalledVersion"
        private const val METHOD_CAN_REQUEST_INSTALLS = "canRequestPackageInstalls"
        private const val METHOD_OPEN_INSTALL_SETTINGS = "openInstallPermissionSettings"
        private const val METHOD_DOWNLOAD = "downloadUpdate"
        private const val METHOD_CANCEL_DOWNLOAD = "cancelUpdateDownload"
        private const val METHOD_INSTALL = "installUpdate"
        const val METHOD_ON_DOWNLOAD_PROGRESS = "onUpdateDownloadProgress"

        // Mirrored by UpdateInstallFailure on the Dart side.
        private const val ERROR_DOWNLOAD_FAILED = "download_failed"
        private const val ERROR_CANCELED = "canceled"
        private const val ERROR_CORRUPT_DOWNLOAD = "corrupt_download"
        private const val ERROR_PACKAGE_MISMATCH = "package_mismatch"
        private const val ERROR_NOT_NEWER = "not_newer"
        private const val ERROR_SIGNATURE_MISMATCH = "signature_mismatch"
        private const val ERROR_PERMISSION_REQUIRED = "permission_required"
        private const val ERROR_UNKNOWN = "unknown"

        private const val UPDATE_CACHE_DIR = "app_update"
        private const val DEFAULT_APK_NAME = "fetchy-update.apk"
        private const val APK_MIME_TYPE = "application/vnd.android.package-archive"
        private const val USER_AGENT = "Fetchy-Update-Downloader"

        private const val CONNECT_TIMEOUT_MS = 20_000
        private const val READ_TIMEOUT_MS = 60_000
        private const val MAX_REDIRECTS = 5
        private const val DOWNLOAD_BUFFER_BYTES = 64 * 1024
        private const val PROGRESS_INTERVAL_MS = 150L

        /// A sanity ceiling, not a real limit: Fetchy's APK is tens of
        /// megabytes, so anything past this is not a Fetchy build.
        private const val MAX_APK_BYTES = 512L * 1024L * 1024L
    }
}

// android/app/src/main/kotlin/com/example/fetchy/ArtworkChannelHandler.kt
package com.example.fetchy

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/// Thumbnail/Artwork support: picks a local image via Storage Access
/// Framework, or downloads the source thumbnail URL the extraction already
/// returned — never a second yt-dlp extraction, never re-downloading the
/// media itself. Both paths converge on the same result shape (a private,
/// already-validated local file path) so [DownloadOptions]/
/// [DownloadPostProcessor] never need to know which one produced it.
///
/// Follows the exact same activity-result pattern as
/// [com.example.fetchy.storage.StorageChannelHandler]: a request code owned
/// by this handler, dispatched from MainActivity.onActivityResult.
class ArtworkChannelHandler(
    private val appContext: Context
) : MethodChannel.MethodCallHandler {

    var activity: Activity? = null

    private var pendingPickResult: MethodChannel.Result? = null

    private val downloadExecutor: ExecutorService = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_PICK_CUSTOM_IMAGE -> pickCustomImage(result)

            METHOD_DOWNLOAD_SOURCE_THUMBNAIL -> {
                val url = call.argument<String>("url")?.trim()
                if (url.isNullOrEmpty()) {
                    result.error("INVALID_URL", "No thumbnail URL provided.", null)
                    return
                }
                downloadSourceThumbnail(url, result)
            }

            METHOD_DELETE_ARTWORK -> {
                deleteArtwork(call.argument<String>("path"))
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ------------------------------------------------------------ custom pick

    private fun pickCustomImage(result: MethodChannel.Result) {
        val host = activity
        if (host == null) {
            result.error("NO_ACTIVITY", "Fetchy is not in the foreground.", null)
            return
        }
        if (pendingPickResult != null) {
            result.error("BUSY", "An image picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            // Some galleries only honor an explicit MIME allow-list; the
            // three types below are the ones the bundled ffmpeg's own
            // `-decoders` output confirmed as actually decodable (mjpeg,
            // png, webp) — see the Thumbnail/Artwork investigation.
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/jpeg", "image/png", "image/webp"))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        pendingPickResult = result
        try {
            host.startActivityForResult(intent, REQUEST_CODE_PICK_IMAGE)
        } catch (throwable: Throwable) {
            pendingPickResult = null
            result.error("PICKER_UNAVAILABLE", "No image picker is available on this device.", null)
        }
    }

    /// Called from MainActivity.onActivityResult. Returns true when this
    /// handler owned the request code, so the caller knows not to look
    /// further.
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_IMAGE) return false

        val result = pendingPickResult
        pendingPickResult = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result?.success(null)
            return true
        }

        downloadExecutor.execute {
            val materialized = try {
                val displayName = queryDisplayName(uri)
                val extension = extensionFromMimeOrName(appContext.contentResolver.getType(uri), displayName)
                val destination = File(artworkCacheDir(), "custom_${System.currentTimeMillis()}.$extension")

                appContext.contentResolver.openInputStream(uri)?.use { input ->
                    destination.outputStream().use { output -> input.copyTo(output) }
                } ?: throw IllegalStateException("Could not open the selected image.")

                validateAsImage(destination)
            } catch (throwable: Throwable) {
                Log.w(TAG, "custom image pick failed: ${throwable::class.simpleName}")
                null
            }

            mainHandler.post {
                if (materialized == null) {
                    result?.error(
                        "INVALID_IMAGE",
                        "That file could not be used as an image.",
                        null
                    )
                } else {
                    result?.success(mapOf("path" to materialized.absolutePath))
                }
            }
        }
        return true
    }

    // ------------------------------------------------------- source thumbnail

    /// Downloads the thumbnail URL the original extraction already
    /// returned (see RawMediaInfoParser's "thumbnailUrl") into private
    /// cache storage. This is a plain HTTPS image fetch — never a yt-dlp
    /// process, never a second extraction, never a re-download of the
    /// media itself.
    private fun downloadSourceThumbnail(url: String, result: MethodChannel.Result) {
        downloadExecutor.execute {
            var connection: HttpURLConnection? = null
            val materialized: File? = try {
                connection = (URL(url).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 15_000
                    readTimeout = 15_000
                    instanceFollowRedirects = true
                }
                val responseCode = connection.responseCode
                if (responseCode !in 200..299) {
                    throw IllegalStateException("HTTP $responseCode")
                }

                val extension = extensionFromMimeOrName(connection.contentType, url)
                val destination = File(artworkCacheDir(), "source_${System.currentTimeMillis()}.$extension")

                connection.inputStream.use { input ->
                    destination.outputStream().use { output -> input.copyTo(output) }
                }

                validateAsImage(destination)
            } catch (throwable: Throwable) {
                Log.w(TAG, "source thumbnail download failed: ${throwable::class.simpleName}")
                null
            } finally {
                connection?.disconnect()
            }

            mainHandler.post {
                if (materialized == null) {
                    result.error(
                        "THUMBNAIL_UNAVAILABLE",
                        "The source thumbnail could not be downloaded.",
                        null
                    )
                } else {
                    result.success(mapOf("path" to materialized.absolutePath))
                }
            }
        }
    }

    // ------------------------------------------------------------- cleanup

    /// Deletes a temp artwork file the sheet materialized but never used
    /// (the user canceled, or switched to a different artwork choice
    /// before Save). Only ever deletes inside this handler's own cache
    /// subdirectory — never an arbitrary path — so a malformed argument can
    /// never delete anything outside it.
    private fun deleteArtwork(path: String?) {
        if (path.isNullOrBlank()) return
        try {
            val file = File(path)
            val cacheDir = artworkCacheDir().canonicalFile
            if (file.canonicalFile.parentFile == cacheDir) {
                file.delete()
            }
        } catch (throwable: Throwable) {
            // Best-effort cleanup only.
        }
    }

    private fun artworkCacheDir(): File {
        val dir = File(appContext.cacheDir, "artwork_picks")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    /// Confirms [file] genuinely decodes as an image before it is ever
    /// handed to the download pipeline — a corrupt or non-image file picked
    /// through a misbehaving file manager, or a URL that served an HTML
    /// error page instead of an image, is rejected here rather than
    /// surfacing as a confusing ffmpeg failure much later. Uses
    /// inJustDecodeBounds so the full image is never loaded into memory
    /// just to validate it.
    private fun validateAsImage(file: File): File? {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, options)
        return if (options.outWidth > 0 && options.outHeight > 0) {
            file
        } else {
            file.delete()
            null
        }
    }

    private fun queryDisplayName(uri: android.net.Uri): String? {
        return try {
            appContext.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index >= 0) cursor.getString(index) else null
                    } else {
                        null
                    }
                }
        } catch (throwable: Throwable) {
            null
        }
    }

    private fun extensionFromMimeOrName(mimeType: String?, nameOrUrl: String?): String {
        val normalizedMime = mimeType?.substringBefore(';')?.trim()?.lowercase()
        when (normalizedMime) {
            "image/jpeg", "image/jpg" -> return "jpg"
            "image/png" -> return "png"
            "image/webp" -> return "webp"
        }

        val fromName = nameOrUrl?.substringBeforeLast('?')?.substringAfterLast('.', "")?.lowercase()
        return when (fromName) {
            "jpg", "jpeg" -> "jpg"
            "png" -> "png"
            "webp" -> "webp"
            else -> "jpg" // validateAsImage() rejects it afterward if this guess is wrong.
        }
    }

    companion object {
        private const val TAG = "FetchyArtwork"
        const val CHANNEL = "app.fetchy/artwork"

        private const val METHOD_PICK_CUSTOM_IMAGE = "pickCustomImage"
        private const val METHOD_DOWNLOAD_SOURCE_THUMBNAIL = "downloadSourceThumbnail"
        private const val METHOD_DELETE_ARTWORK = "deleteArtwork"

        private const val REQUEST_CODE_PICK_IMAGE = 9423
    }
}

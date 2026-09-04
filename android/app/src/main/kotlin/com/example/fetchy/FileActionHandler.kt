package com.example.fetchy

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Handles opening, sharing, and checking existence of downloaded media files
/// using Android's standard Intent, MediaStore, and FileProvider APIs.
class FileActionHandler(
    private val appContext: Context,
) : MethodChannel.MethodCallHandler {

    var activity: Activity? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_OPEN_FILE -> {
                val uri = call.argument<String>("uri")
                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType")
                result.success(openFile(uri, path, mimeType))
            }
            METHOD_SHARE_FILE -> {
                val uri = call.argument<String>("uri")
                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType")
                result.success(shareFile(uri, path, mimeType))
            }
            METHOD_CHECK_FILE_EXISTS -> {
                val uri = call.argument<String>("uri")
                val path = call.argument<String>("path")
                result.success(checkFileExists(uri, path))
            }
            METHOD_OPEN_EXTERNAL_URL -> {
                val url = call.argument<String>("url")
                result.success(openExternalUrl(url))
            }
            else -> result.notImplemented()
        }
    }

    fun openFile(rawUri: String?, rawPath: String?, customMimeType: String?): Map<String, Any?> {
        val resolved = resolveContentUriAndMime(rawUri, rawPath, customMimeType)
            ?: return mapOf(
                "success" to false,
                "error" to "The file could not be found or is no longer accessible on this device."
            )

        val (contentUri, mimeType) = resolved

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val host = activity ?: appContext
        val chooser = Intent.createChooser(intent, host.getString(R.string.file_action_open_with)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            host.startActivity(chooser)
            mapOf("success" to true)
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "No compatible app found to open $contentUri with type $mimeType", e)
            mapOf(
                "success" to false,
                "error" to "No application found to play or view this media file."
            )
        } catch (t: Throwable) {
            Log.e(TAG, "Error opening file", t)
            mapOf("success" to false, "error" to (t.message ?: "Failed to open file."))
        }
    }

    fun shareFile(rawUri: String?, rawPath: String?, customMimeType: String?): Map<String, Any?> {
        val resolved = resolveContentUriAndMime(rawUri, rawPath, customMimeType)
            ?: return mapOf(
                "success" to false,
                "error" to "The file could not be found or is no longer accessible on this device."
            )

        val (contentUri, mimeType) = resolved

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, contentUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val host = activity ?: appContext
        val chooser = Intent.createChooser(intent, host.getString(R.string.file_action_share_media)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            host.startActivity(chooser)
            mapOf("success" to true)
        } catch (e: ActivityNotFoundException) {
            Log.w(TAG, "No app available to share $contentUri", e)
            mapOf("success" to false, "error" to "No compatible app found to share this file.")
        } catch (t: Throwable) {
            Log.e(TAG, "Error sharing file", t)
            mapOf("success" to false, "error" to (t.message ?: "Failed to share file."))
        }
    }

    /// Opens [rawUrl] (an https:// upstream link — yt-dlp/youtubedl-android/
    /// FFmpeg resources) in the user's browser via a plain ACTION_VIEW
    /// intent — no Custom Tab, no in-app WebView, since these are read-only
    /// documentation/issue pages the user leaves Fetchy to read, not a
    /// sign-in flow. Only ever accepts http(s) links.
    fun openExternalUrl(rawUrl: String?): Boolean {
        val url = rawUrl?.trim()
        if (url.isNullOrEmpty()) return false

        val uri = try {
            Uri.parse(url)
        } catch (throwable: Throwable) {
            return false
        }
        val scheme = uri.scheme?.lowercase()
        if (scheme != "http" && scheme != "https") return false

        return try {
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val host = activity ?: appContext
            host.startActivity(intent)
            true
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not open external URL", throwable)
            false
        }
    }

    fun checkFileExists(rawUri: String?, rawPath: String?): Map<String, Any?> {
        // 1. Check direct file path if available
        val file = resolvePhysicalFile(rawPath)
        if (file != null && file.exists() && file.length() > 0L) {
            return mapOf(
                "exists" to true,
                "sizeBytes" to file.length(),
                "displayPath" to file.absolutePath
            )
        }

        // 2. Check content URI via ContentResolver
        if (!rawUri.isNullOrBlank() && rawUri.startsWith("content://")) {
            try {
                val parsedUri = Uri.parse(rawUri)
                val resolver = appContext.contentResolver
                resolver.query(parsedUri, arrayOf(MediaStore.MediaColumns.SIZE, MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val sizeIndex = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                        val size = if (sizeIndex >= 0) cursor.getLong(sizeIndex) else -1L
                        val nameIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME)
                        val name = if (nameIndex >= 0) cursor.getString(nameIndex) else null
                        return mapOf(
                            "exists" to true,
                            "sizeBytes" to size,
                            "displayPath" to (rawPath ?: name)
                        )
                    }
                }
            } catch (t: Throwable) {
                Log.d(TAG, "Could not query content URI $rawUri: ${t.message}")
            }
        }

        return mapOf("exists" to false)
    }

    private fun resolveContentUriAndMime(
        rawUri: String?,
        rawPath: String?,
        customMimeType: String?
    ): Pair<Uri, String>? {
        // First try to locate physical file
        val file = resolvePhysicalFile(rawPath)
        if (file != null && file.exists() && file.length() > 0L) {
            val contentUri = try {
                FileProvider.getUriForFile(
                    appContext,
                    "${appContext.packageName}.fileprovider",
                    file
                )
            } catch (t: Throwable) {
                Log.w(TAG, "Could not get FileProvider URI for ${file.absolutePath}", t)
                null
            }

            if (contentUri != null) {
                val mime = customMimeType?.takeIf { it.isNotBlank() } ?: mimeTypeFor(file.name)
                return Pair(contentUri, mime)
            }
        }

        // Fall back to raw content URI
        if (!rawUri.isNullOrBlank() && rawUri.startsWith("content://")) {
            val parsedUri = Uri.parse(rawUri)
            val mime = customMimeType?.takeIf { it.isNotBlank() }
                ?: appContext.contentResolver.getType(parsedUri)
                ?: mimeTypeFor(rawPath ?: "file.mp4")
            return Pair(parsedUri, mime)
        }

        return null
    }

    private fun resolvePhysicalFile(rawPath: String?): File? {
        if (rawPath.isNullOrBlank()) return null

        val directFile = File(rawPath)
        if (directFile.exists()) return directFile

        val cleanPath = rawPath.trim()

        // If path is like "Download/Fetchy/video.mp4" or "Downloads/Fetchy/video.mp4"
        val subPath = if (cleanPath.startsWith("Download/", ignoreCase = true)) {
            cleanPath.substring("Download/".length)
        } else if (cleanPath.startsWith("Downloads/", ignoreCase = true)) {
            cleanPath.substring("Downloads/".length)
        } else {
            cleanPath
        }

        val publicDownloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val fileInDownloads = File(publicDownloads, subPath)
        if (fileInDownloads.exists()) return fileInDownloads

        val primaryExternal = Environment.getExternalStorageDirectory()
        val fileInExternal = File(primaryExternal, cleanPath)
        if (fileInExternal.exists()) return fileInExternal

        val appExternal = appContext.getExternalFilesDir(null)
        if (appExternal != null) {
            val fileInApp = File(appExternal, cleanPath)
            if (fileInApp.exists()) return fileInApp
        }

        return null
    }

    private fun mimeTypeFor(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        if (extension.isNotEmpty()) {
            val fromMap = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            if (!fromMap.isNullOrBlank()) return fromMap
        }

        return when (extension) {
            "mp4", "m4v" -> "video/mp4"
            "mkv" -> "video/x-matroska"
            "webm" -> "video/webm"
            "3gp" -> "video/3gpp"
            "mov" -> "video/quicktime"
            "avi" -> "video/x-msvideo"
            "mp3" -> "audio/mpeg"
            "m4a", "aac" -> "audio/mp4"
            "opus", "ogg", "oga" -> "audio/ogg"
            "wav" -> "audio/wav"
            "flac" -> "audio/flac"
            else -> "application/octet-stream"
        }
    }

    companion object {
        private const val TAG = "FetchyFileAction"
        const val CHANNEL = "app.fetchy/file_actions"

        private const val METHOD_OPEN_FILE = "openFile"
        private const val METHOD_SHARE_FILE = "shareFile"
        private const val METHOD_CHECK_FILE_EXISTS = "checkFileExists"
        private const val METHOD_OPEN_EXTERNAL_URL = "openExternalUrl"
    }
}


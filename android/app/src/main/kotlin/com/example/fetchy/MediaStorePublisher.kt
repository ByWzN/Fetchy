// android/app/src/main/kotlin/com/example/fetchy/MediaStorePublisher.kt
package com.example.fetchy

import android.Manifest
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import com.example.fetchy.storage.MediaKind
import com.example.fetchy.storage.ResolvedDestination
import com.example.fetchy.storage.StorageDestinationResolver
import com.example.fetchy.storage.StorageSettings
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

sealed class PublishOutcome {
    /// [uri] is the MediaStore/SAF content URI (or a file:// URI on legacy).
    /// [displayPath] is the user-facing location, e.g. "Movies/Fetchy/Videos/clip.mp4"
    /// or "My folder/clip.mp4" for a custom SAF destination.
    data class Success(val uri: String, val displayPath: String) : PublishOutcome()

    data class Failure(val message: String) : PublishOutcome()
}

/// Publishes a completed download from the app-private temporary directory
/// into shared storage, per the user's Download Location settings.
///
/// [settings] only decides *where* the already-finished file goes — see
/// [StorageDestinationResolver] for that decision and
/// com.example.fetchy.storage.StorageSettings for what the user configured.
/// yt-dlp/FFmpeg extraction is entirely finished by the time this runs.
///
/// The source file is never deleted here — the caller deletes it only after
/// receiving [PublishOutcome.Success].
object MediaStorePublisher {

    fun publish(context: Context, source: File, settings: StorageSettings): PublishOutcome {
        if (!source.exists()) {
            return PublishOutcome.Failure(
                "Temporary file no longer exists: ${source.absolutePath}"
            )
        }
        if (source.length() <= 0L) {
            return PublishOutcome.Failure(
                "Temporary file is empty: ${source.absolutePath}"
            )
        }

        val mimeType = mimeTypeFor(source.name)
        val mediaKind = StorageDestinationResolver.mediaKindFor(mimeType)

        return when (val destination = StorageDestinationResolver.resolve(settings, mediaKind)) {
            is ResolvedDestination.Unavailable -> PublishOutcome.Failure(destination.reason)

            is ResolvedDestination.CustomTreeTarget ->
                publishToCustomTree(
                    context,
                    source,
                    destination.treeUri,
                    destination.subfolderName,
                    mimeType
                )

            is ResolvedDestination.MediaStoreTarget ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    publishViaMediaStore(context, source, destination, mimeType)
                } else {
                    publishLegacy(context, source, destination, mimeType)
                }
        }
    }

    // ------------------------------------------------------------ API 29+

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun publishViaMediaStore(
        context: Context,
        source: File,
        destination: ResolvedDestination.MediaStoreTarget,
        mimeType: String
    ): PublishOutcome {
        val resolver = context.contentResolver
        val expectedSize = source.length()

        val pending = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, source.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, destination.relativePath)
            put(MediaStore.MediaColumns.SIZE, expectedSize)
            // Hidden from other apps until the copy is fully verified.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val collection = collectionFor(destination.mediaKind)

        val uri: Uri = try {
            resolver.insert(collection, pending)
        } catch (throwable: Throwable) {
            return PublishOutcome.Failure(
                "Could not create an entry in ${destination.relativePath}: ${throwable.message}"
            )
        } ?: return PublishOutcome.Failure(
            "Could not create an entry in ${destination.relativePath}."
        )

        // Copy
        try {
            val copied: Long = resolver.openOutputStream(uri, "w").use { output ->
                if (output == null) throw IOException("Could not open the destination stream.")
                FileInputStream(source).use { input -> input.copyTo(output) }
            }

            if (copied != expectedSize) {
                throw IOException("Copied $copied of $expectedSize bytes.")
            }
        } catch (throwable: Throwable) {
            discard(resolver, uri)
            return PublishOutcome.Failure(
                "Failed to copy into ${destination.relativePath}: ${throwable.message}"
            )
        }

        // Publish
        try {
            val finalize = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            val updated = resolver.update(uri, finalize, null, null)
            if (updated <= 0) throw IOException("The entry could not be finalized.")
        } catch (throwable: Throwable) {
            discard(resolver, uri)
            return PublishOutcome.Failure(
                "Failed to finalize the ${destination.relativePath} entry: ${throwable.message}"
            )
        }

        // MediaStore de-duplicates names itself, so read back what it actually used.
        val displayName = queryDisplayName(resolver, uri) ?: source.name

        return PublishOutcome.Success(
            uri = uri.toString(),
            displayPath = "${destination.relativePath}/$displayName"
        )
    }

    private fun collectionFor(mediaKind: MediaKind): Uri = when (mediaKind) {
        MediaKind.VIDEO -> MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        MediaKind.AUDIO -> MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        MediaKind.OTHER -> MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    }

    private fun discard(resolver: ContentResolver, uri: Uri) {
        try {
            resolver.delete(uri, null, null)
        } catch (throwable: Throwable) {
            Log.w(TAG, "Could not remove the pending entry", throwable)
        }
    }

    private fun queryDisplayName(resolver: ContentResolver, uri: Uri): String? {
        return try {
            resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (throwable: Throwable) {
            null
        }
    }

    // --------------------------------------------------------- API 24..28

    private fun publishLegacy(
        context: Context,
        source: File,
        destination: ResolvedDestination.MediaStoreTarget,
        mimeType: String
    ): PublishOutcome {
        // Runtime permission request UX is not implemented in this milestone.
        // Without the grant we fail clearly rather than silently losing the file.
        val granted = context.checkSelfPermission(
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED

        if (!granted) {
            return PublishOutcome.Failure(
                "Saving to shared storage on this Android version needs storage " +
                    "permission, which has not been granted."
            )
        }

        if (Environment.getExternalStorageState() != Environment.MEDIA_MOUNTED) {
            return PublishOutcome.Failure("Shared storage is not available.")
        }

        // destination.relativePath is an Environment.DIRECTORY_* value,
        // optionally with a "/Fetchy/..." suffix — both segments are valid
        // arguments to a nested File() the same way.
        val segments = destination.relativePath.split('/').filter { it.isNotBlank() }
        val topLevelPublic =
            Environment.getExternalStoragePublicDirectory(segments.first())
        var directory = topLevelPublic
        for (segment in segments.drop(1)) {
            directory = File(directory, segment)
        }

        if (!directory.exists() && !directory.mkdirs()) {
            return PublishOutcome.Failure(
                "Could not create ${directory.absolutePath}"
            )
        }

        val target = uniqueFile(directory, source.name)
        val expectedSize = source.length()

        try {
            FileInputStream(source).use { input ->
                FileOutputStream(target).use { output ->
                    val copied = input.copyTo(output)
                    output.flush()
                    output.fd.sync()
                    if (copied != expectedSize) {
                        throw IOException("Copied $copied of $expectedSize bytes.")
                    }
                }
            }
        } catch (throwable: Throwable) {
            runCatching { target.delete() }
            return PublishOutcome.Failure(
                "Failed to copy into ${destination.relativePath}: ${throwable.message}"
            )
        }

        // Makes the file visible to file managers and the media database.
        try {
            MediaScannerConnection.scanFile(
                context,
                arrayOf(target.absolutePath),
                arrayOf(mimeType),
                null
            )
        } catch (throwable: Throwable) {
            Log.w(TAG, "Media scan failed; the file is still on disk", throwable)
        }

        return PublishOutcome.Success(
            uri = Uri.fromFile(target).toString(),
            displayPath = "${destination.relativePath}/${target.name}"
        )
    }

    private fun uniqueFile(directory: File, fileName: String): File {
        val candidate = File(directory, fileName)
        if (!candidate.exists()) return candidate

        val base = fileName.substringBeforeLast('.', fileName)
        val extension = fileName.substringAfterLast('.', "")
        val suffix = if (extension.isEmpty()) "" else ".$extension"

        var index = 1
        while (index < MAX_NAME_ATTEMPTS) {
            val next = File(directory, "$base ($index)$suffix")
            if (!next.exists()) return next
            index++
        }

        return File(directory, "$base (${System.currentTimeMillis()})$suffix")
    }

    // --------------------------------------------------------- custom SAF

    /// Writes into a folder the user granted via ACTION_OPEN_DOCUMENT_TREE.
    /// Never falls back to MediaStore on failure — a stale/revoked/missing
    /// tree is reported as a clear failure so the user can re-select a
    /// folder in Settings, per the Download Location design.
    private fun publishToCustomTree(
        context: Context,
        source: File,
        treeUriString: String,
        subfolderName: String?,
        mimeType: String
    ): PublishOutcome {
        val treeUri = try {
            Uri.parse(treeUriString)
        } catch (throwable: Throwable) {
            return PublishOutcome.Failure(
                "The saved custom download folder is invalid. Choose a new " +
                    "folder in Settings → Download Location."
            )
        }

        val stillGranted = context.contentResolver.persistedUriPermissions.any {
            it.uri == treeUri && it.isWritePermission
        }
        if (!stillGranted) {
            return PublishOutcome.Failure(
                "Fetchy no longer has permission to write to the selected " +
                    "folder. Choose a new folder in Settings → Download Location."
            )
        }

        val treeDoc = try {
            DocumentFile.fromTreeUri(context, treeUri)
        } catch (throwable: Throwable) {
            null
        }
        if (treeDoc == null || !treeDoc.exists() || !treeDoc.isDirectory) {
            return PublishOutcome.Failure(
                "The selected custom download folder is no longer accessible. " +
                    "Choose a new folder in Settings → Download Location."
            )
        }

        // When Fetchy subfolders are on, get-or-create the Videos/Audio
        // directory directly under the granted tree — the persisted
        // permission on the tree already covers anything created beneath
        // it, so this needs no extra grant.
        val targetDir = if (subfolderName == null) {
            treeDoc
        } else {
            val existing = treeDoc.findFile(subfolderName)
            val dir = if (existing != null && existing.isDirectory) {
                existing
            } else {
                try {
                    treeDoc.createDirectory(subfolderName)
                } catch (throwable: Throwable) {
                    null
                }
            }
            dir ?: return PublishOutcome.Failure(
                "Could not create the \"$subfolderName\" folder inside the selected location."
            )
        }

        val displayName = uniqueDocumentName(targetDir, source.name)

        val child = try {
            targetDir.createFile(mimeType, displayName)
        } catch (throwable: Throwable) {
            return PublishOutcome.Failure(
                "Could not create a file in the selected folder: ${throwable.message}"
            )
        } ?: return PublishOutcome.Failure("Could not create a file in the selected folder.")

        val expectedSize = source.length()
        try {
            val copied: Long = context.contentResolver.openOutputStream(child.uri, "w").use { output ->
                if (output == null) throw IOException("Could not open the destination stream.")
                FileInputStream(source).use { input -> input.copyTo(output) }
            }
            if (copied != expectedSize) {
                throw IOException("Copied $copied of $expectedSize bytes.")
            }
        } catch (throwable: Throwable) {
            runCatching { child.delete() }
            return PublishOutcome.Failure(
                "Failed to write into the selected folder: ${throwable.message}"
            )
        }

        val rootLabel = treeDoc.name ?: "Custom folder"
        val folderLabel = if (subfolderName == null) rootLabel else "$rootLabel/$subfolderName"
        return PublishOutcome.Success(
            uri = child.uri.toString(),
            displayPath = "$folderLabel/$displayName"
        )
    }

    private fun uniqueDocumentName(dir: DocumentFile, fileName: String): String {
        if (dir.findFile(fileName) == null) return fileName

        val base = fileName.substringBeforeLast('.', fileName)
        val extension = fileName.substringAfterLast('.', "")
        val suffix = if (extension.isEmpty()) "" else ".$extension"

        var index = 1
        while (index < MAX_NAME_ATTEMPTS) {
            val candidate = "$base ($index)$suffix"
            if (dir.findFile(candidate) == null) return candidate
            index++
        }

        return "$base (${System.currentTimeMillis()})$suffix"
    }

    // -------------------------------------------------------------- shared

    private fun mimeTypeFor(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        if (extension.isEmpty()) return FALLBACK_MIME

        EXPLICIT_MIME_TYPES[extension]?.let { return it }

        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: FALLBACK_MIME
    }

    private const val TAG = "FetchyStorage"
    private const val FALLBACK_MIME = "application/octet-stream"
    private const val MAX_NAME_ATTEMPTS = 1000

    /// MimeTypeMap misses several containers yt-dlp commonly produces, so
    /// the ones we actually see are mapped explicitly. This is also the
    /// single source of truth for "is this file audio or video" — see
    /// StorageDestinationResolver.mediaKindFor.
    private val EXPLICIT_MIME_TYPES = mapOf(
        "mp4" to "video/mp4",
        "m4v" to "video/mp4",
        "webm" to "video/webm",
        "mkv" to "video/x-matroska",
        "mov" to "video/quicktime",
        "3gp" to "video/3gpp",
        "flv" to "video/x-flv",
        "ts" to "video/mp2t",
        "m4a" to "audio/mp4",
        "mp3" to "audio/mpeg",
        "opus" to "audio/opus",
        "ogg" to "audio/ogg",
        "oga" to "audio/ogg",
        "aac" to "audio/aac",
        "flac" to "audio/flac",
        "wav" to "audio/wav"
    )
}

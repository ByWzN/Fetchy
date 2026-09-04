// android/app/src/main/kotlin/com/example/fetchy/storage/StorageDestinationResolver.kt
package com.example.fetchy.storage

import android.os.Environment

/// The actual kind of the file yt-dlp/FFmpeg produced, read from its real
/// MIME type — never from the source platform or from what the UI asked
/// for. A YouTube URL that ends up as an MP3 is audio; a TikTok URL that
/// ends up as an MP4 is video.
enum class MediaKind { VIDEO, AUDIO, OTHER }

sealed class ResolvedDestination {
    /// Write via MediaStore into [relativePath] (an Environment.DIRECTORY_*
    /// value, optionally with a Fetchy subfolder appended).
    data class MediaStoreTarget(val mediaKind: MediaKind, val relativePath: String) :
        ResolvedDestination()

    /// Write via Storage Access Framework into this persisted tree URI.
    /// [subfolderName], when non-null, is a directory Fetchy creates (if
    /// it does not already exist) directly under the tree root before
    /// writing the file into it.
    data class CustomTreeTarget(val treeUri: String, val subfolderName: String?) :
        ResolvedDestination()

    /// Custom base was selected but no usable tree URI exists for this
    /// media kind — a real failure to report, never a silent downgrade to
    /// another location.
    data class Unavailable(val reason: String) : ResolvedDestination()
}

/// Turns (user storage settings, actual output media kind) into where the
/// completed file should be written. Kept separate from both yt-dlp
/// extraction and the actual MediaStore/SAF I/O in [MediaStorePublisher] —
/// this class only decides, it never touches a file or a ContentResolver.
object StorageDestinationResolver {

    fun mediaKindFor(mimeType: String): MediaKind = when {
        mimeType.startsWith("video/") -> MediaKind.VIDEO
        mimeType.startsWith("audio/") -> MediaKind.AUDIO
        else -> MediaKind.OTHER
    }

    fun resolve(settings: StorageSettings, mediaKind: MediaKind): ResolvedDestination {
        return if (settings.base == StorageBase.CUSTOM) {
            resolveCustom(settings, mediaKind)
        } else {
            resolveAndroidDefault(settings, mediaKind)
        }
    }

    private fun resolveCustom(settings: StorageSettings, mediaKind: MediaKind): ResolvedDestination {
        val treeUri = when (mediaKind) {
            MediaKind.VIDEO -> settings.videoTreeUri
            MediaKind.AUDIO -> settings.audioTreeUri
            // No dedicated "other" custom folder concept yet — prefer
            // whichever of the two the user actually set.
            MediaKind.OTHER -> settings.videoTreeUri ?: settings.audioTreeUri
        }

        if (treeUri.isNullOrBlank()) {
            return ResolvedDestination.Unavailable(
                "No custom download folder is set for this type of file. " +
                    "Choose one in Settings → Download Location."
            )
        }

        val subfolderName = if (settings.useFetchySubfolders) {
            when (mediaKind) {
                MediaKind.VIDEO -> "Videos"
                MediaKind.AUDIO -> "Audio"
                MediaKind.OTHER -> null
            }
        } else {
            null
        }

        return ResolvedDestination.CustomTreeTarget(treeUri, subfolderName)
    }

    private fun resolveAndroidDefault(
        settings: StorageSettings,
        mediaKind: MediaKind
    ): ResolvedDestination {
        val baseDir = when (mediaKind) {
            MediaKind.VIDEO -> Environment.DIRECTORY_MOVIES
            MediaKind.AUDIO -> Environment.DIRECTORY_MUSIC
            MediaKind.OTHER -> Environment.DIRECTORY_DOWNLOADS
        }

        val relativePath = if (settings.useFetchySubfolders) {
            when (mediaKind) {
                MediaKind.VIDEO -> "$baseDir/Fetchy/Videos"
                MediaKind.AUDIO -> "$baseDir/Fetchy/Audio"
                MediaKind.OTHER -> "$baseDir/Fetchy"
            }
        } else {
            baseDir
        }

        return ResolvedDestination.MediaStoreTarget(mediaKind, relativePath)
    }
}

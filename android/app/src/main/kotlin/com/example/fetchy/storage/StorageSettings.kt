// android/app/src/main/kotlin/com/example/fetchy/storage/StorageSettings.kt
package com.example.fetchy.storage

/// Where Fetchy looks for a destination folder. Resolved on the Dart side
/// (see StorageSettingsService) from the user's Download Location choice,
/// and passed down with every `startDownload` call so the publisher never
/// has to reach back into Flutter's own preferences.
///
/// Deliberately independent from [StorageSettings.useFetchySubfolders] —
/// "where" and "whether Fetchy organizes it" are two separate questions,
/// not one fixed combination. Every (base, useFetchySubfolders) pairing is
/// a valid, supported configuration.
enum class StorageBase {
    /// The plain Android media folders: Movies/, Music/.
    ANDROID_DEFAULT,

    /// A folder the user picked via Storage Access Framework
    /// (ACTION_OPEN_DOCUMENT_TREE). [StorageSettings.videoTreeUri] /
    /// [StorageSettings.audioTreeUri] carry the persisted tree URI to use
    /// for each media kind.
    CUSTOM;

    companion object {
        fun fromWire(raw: String?): StorageBase = if (raw == "custom") CUSTOM else ANDROID_DEFAULT
    }
}

data class StorageSettings(
    val base: StorageBase,
    /// Whether Fetchy creates its own Videos/Audio subfolder under [base]
    /// — applies the same way whether [base] is Android's own folders or
    /// a custom one.
    val useFetchySubfolders: Boolean,
    val videoTreeUri: String?,
    val audioTreeUri: String?
) {
    companion object {
        /// First-run default: Fetchy-organized Android media folders.
        val DEFAULT = StorageSettings(
            base = StorageBase.ANDROID_DEFAULT,
            useFetchySubfolders = true,
            videoTreeUri = null,
            audioTreeUri = null
        )

        /// Reads the `"storage"` argument map a `startDownload` call may
        /// carry. Missing or malformed input degrades to [DEFAULT] rather
        /// than failing the download — this setting only changes where a
        /// file lands, never whether extraction/download proceeds.
        @Suppress("UNCHECKED_CAST")
        fun fromArgument(raw: Any?): StorageSettings {
            val map = raw as? Map<String, Any?> ?: return DEFAULT
            return StorageSettings(
                base = StorageBase.fromWire(map["base"] as? String),
                useFetchySubfolders = map["useFetchySubfolders"] as? Boolean ?: true,
                videoTreeUri = map["videoTreeUri"] as? String,
                audioTreeUri = map["audioTreeUri"] as? String
            )
        }
    }
}

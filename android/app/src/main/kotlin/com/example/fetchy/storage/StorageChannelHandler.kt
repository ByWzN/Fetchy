// android/app/src/main/kotlin/com/example/fetchy/storage/StorageChannelHandler.kt
package com.example.fetchy.storage

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Download Location: lets the user grant Fetchy access to a folder of
/// their choosing via Storage Access Framework, and checks later whether
/// that grant is still usable. Never touches MediaStore or the download
/// pipeline itself — see [StorageDestinationResolver] and
/// `MediaStorePublisher` for that.
class StorageChannelHandler(
    private val appContext: Context
) : MethodChannel.MethodCallHandler {

    var activity: Activity? = null

    private var pendingResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_PICK_CUSTOM_DIRECTORY -> pickDirectory(result)

            METHOD_CHECK_TREE_ACCESSIBLE -> {
                val treeUri = call.argument<String>("treeUri")
                result.success(isTreeAccessible(treeUri))
            }

            METHOD_RELEASE_TREE -> {
                releaseTree(call.argument<String>("treeUri"))
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        val host = activity
        if (host == null) {
            result.error("NO_ACTIVITY", "Fetchy is not in the foreground.", null)
            return
        }
        if (pendingResult != null) {
            result.error("BUSY", "A folder picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }

        pendingResult = result
        try {
            host.startActivityForResult(intent, REQUEST_CODE_PICK_DIRECTORY)
        } catch (throwable: Throwable) {
            pendingResult = null
            result.error(
                "PICKER_UNAVAILABLE",
                "No folder picker is available on this device.",
                null
            )
        }
    }

    /// Called from MainActivity.onActivityResult. Returns true when this
    /// handler owned the request code, so the caller knows not to look
    /// further.
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_DIRECTORY) return false

        val result = pendingResult
        pendingResult = null

        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result?.success(null)
            return true
        }

        try {
            appContext.contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (throwable: Throwable) {
            result?.error(
                "PERMISSION_FAILED",
                "Could not keep access to the selected folder: ${throwable.message}",
                null
            )
            return true
        }

        val displayName = DocumentFile.fromTreeUri(appContext, treeUri)?.name
            ?: treeUri.lastPathSegment
            ?: "Selected folder"

        result?.success(mapOf("treeUri" to treeUri.toString(), "displayName" to displayName))
        return true
    }

    private fun isTreeAccessible(treeUriString: String?): Boolean {
        if (treeUriString.isNullOrBlank()) return false

        return try {
            val uri = Uri.parse(treeUriString)
            val stillGranted = appContext.contentResolver.persistedUriPermissions.any {
                it.uri == uri && it.isWritePermission
            }
            if (!stillGranted) return false

            val tree = DocumentFile.fromTreeUri(appContext, uri)
            tree != null && tree.exists() && tree.isDirectory
        } catch (throwable: Throwable) {
            false
        }
    }

    private fun releaseTree(treeUriString: String?) {
        if (treeUriString.isNullOrBlank()) return
        try {
            val uri = Uri.parse(treeUriString)
            appContext.contentResolver.releasePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (throwable: Throwable) {
            // Already released, or never actually held — nothing else to do.
        }
    }

    companion object {
        const val CHANNEL = "app.fetchy/storage"

        private const val METHOD_PICK_CUSTOM_DIRECTORY = "pickCustomDirectory"
        private const val METHOD_CHECK_TREE_ACCESSIBLE = "checkTreeAccessible"
        private const val METHOD_RELEASE_TREE = "releaseTree"

        private const val REQUEST_CODE_PICK_DIRECTORY = 9421
    }
}

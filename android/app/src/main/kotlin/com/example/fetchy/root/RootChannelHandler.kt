// android/app/src/main/kotlin/com/example/fetchy/root/RootChannelHandler.kt
package com.example.fetchy.root

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/// Backs the "app.fetchy/root" channel: Advanced/Root Features.
///
/// This intentionally does NOT implement any of the candidate root
/// features from the brief (browser-cookie extraction, diagnostics, file
/// access) — only capability detection and the explicit enable/gate flow.
/// See the Phase-2/3/4 report for why each candidate feature is deferred
/// rather than half-built: root-assisted browser cookie extraction in
/// particular depends on a specific browser's current on-disk storage
/// format/encryption, which cannot be verified from a development
/// environment without a real rooted device to inspect — implementing a
/// parser against an unverified assumption risks silently producing wrong
/// results or, worse, touching a real browser database incorrectly.
class RootChannelHandler(
    private val appContext: Context,
) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Never runs `su` — returns whatever was last recorded by an
            // explicit ENABLE call, or UNKNOWN ("not checked yet").
            METHOD_GET_STATUS -> {
                val cached = prefs.getString(KEY_STATUS, null)
                val status = cached?.let { runCatching { RootStatus.valueOf(it) }.getOrNull() }
                    ?: RootStatus.UNKNOWN
                result.success(status.name)
            }

            // The only method that actually attempts `su` — only ever
            // called after the user has seen and accepted the root safety
            // warning and explicitly tapped "Enable root features".
            METHOD_ENABLE -> {
                executor.execute {
                    val status = RootCapability.checkStatus()
                    prefs.edit().putString(KEY_STATUS, status.name).apply()
                    mainHandler.post { result.success(status.name) }
                }
            }

            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "app.fetchy/root"
        private const val METHOD_GET_STATUS = "getStatus"
        private const val METHOD_ENABLE = "enable"

        private const val PREFS_NAME = "fetchy_root_prefs"
        private const val KEY_STATUS = "status"
    }
}

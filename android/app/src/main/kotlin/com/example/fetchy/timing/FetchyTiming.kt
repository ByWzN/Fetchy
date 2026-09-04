// android/app/src/main/kotlin/com/example/fetchy/timing/FetchyTiming.kt
package com.example.fetchy.timing

import android.net.Uri
import android.os.SystemClock
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

/// TEMPORARY diagnostic timing instrumentation for the Fetch-latency
/// investigation. Every line uses the single tag [TAG] so the native side
/// can be pulled with `adb logcat -s FetchyTiming`. Safe to delete
/// entirely, along with every call site, once the bottleneck is found and
/// fixed — do not remove before then.
///
/// Flip [ENABLED] to false to fully disable: no logs, no bookkeeping
/// beyond one trivial branch per call — no behavior change either way.
object FetchyTiming {
    const val ENABLED = true

    const val TAG = "FetchyTiming"

    // SystemClock.elapsedRealtimeNanos() is monotonic (immune to wall-clock
    // adjustments, NTP sync, or timezone changes) — this is what all
    // elapsed/delta arithmetic is based on. The wall-clock string in each
    // line is for human readability only and never used for a duration.
    private val startNanos = ConcurrentHashMap<String, Long>()
    private val lastCheckpointNanos = ConcurrentHashMap<String, Long>()
    private val wallClockFormat = SimpleDateFormat("HH:mm:ss.SSS", Locale.US)

    /// Starts timing a new run identified by [runId] (e.g. "F001", or the
    /// fixed pseudo-id "WARMUP" for the one-time engine warm-up, which
    /// isn't tied to any single Fetch). Every checkpoint/summary call for
    /// the same operation must reuse this id so concurrent or sequential
    /// runs can never be mixed together in the captured logs.
    fun start(runId: String) {
        if (!ENABLED) return
        val now = SystemClock.elapsedRealtimeNanos()
        startNanos[runId] = now
        lastCheckpointNanos[runId] = now
    }

    /// Logs one checkpoint: wall-clock time (readability only), elapsed
    /// time since [start], and delta since the previous checkpoint for the
    /// same [runId]. [extra] must already be sanitized by the caller —
    /// this never inspects raw values (URLs, cookies, tokens) itself.
    fun checkpoint(runId: String, label: String, extra: String? = null) {
        if (!ENABLED) return
        val now = SystemClock.elapsedRealtimeNanos()
        val start = startNanos.getOrPut(runId) { now }
        val last = lastCheckpointNanos.getOrPut(runId) { now }
        val elapsedMs = (now - start) / 1_000_000
        val deltaMs = (now - last) / 1_000_000
        lastCheckpointNanos[runId] = now

        val wallClock = wallClockFormat.format(Date())
        val extraSuffix = if (extra != null) " | $extra" else ""
        Log.d(TAG, "[$runId] $wallClock | +${elapsedMs}ms | delta=${deltaMs}ms | $label$extraSuffix")
    }

    /// Elapsed time since [start] for [runId], in whole milliseconds.
    /// Returns 0 if [start] was never called for this id. Useful for
    /// computing a stage's own duration (e.g. session prep) without a
    /// dedicated checkpoint pair, by snapshotting this before and after.
    fun elapsedMs(runId: String): Long {
        if (!ENABLED) return 0
        val now = SystemClock.elapsedRealtimeNanos()
        val start = startNanos[runId] ?: return 0
        return (now - start) / 1_000_000
    }

    /// Prints the native-side summary block for [runId] and releases its
    /// bookkeeping — call exactly once per run, after the attempt has
    /// fully finished (success or failure). Only covers what native can
    /// actually measure (engine warm-up wait, session prep, extraction);
    /// Flutter-side stages (click→request, response→preview) are printed
    /// separately by the Dart-side FetchTiming — the two are correlated by
    /// [runId], not merged into one cross-process object.
    fun summary(
        runId: String,
        platform: String?,
        success: Boolean,
        warmupWaitMs: Long? = null,
        sessionPrepMs: Long? = null,
        extractionMs: Long? = null,
        failedStage: String? = null,
        errorCategory: String? = null
    ) {
        if (!ENABLED) {
            startNanos.remove(runId)
            lastCheckpointNanos.remove(runId)
            return
        }

        val total = elapsedMs(runId)
        val builder = StringBuilder()
        builder.append("\n==================================================\n")
        builder.append("FETCH TIMING SUMMARY (native) [$runId]\n")
        builder.append("Platform: ${platform ?: "Unknown"}\n")
        builder.append("Result: ${if (success) "SUCCESS" else "FAILED"}\n")
        builder.append("\n")

        if (success) {
            builder.append("Engine warm-up wait: ${warmupWaitMs ?: "?"} ms\n")
            builder.append("Session preparation: ${sessionPrepMs ?: "?"} ms\n")
            builder.append("yt-dlp extraction: ${extractionMs ?: "?"} ms\n")
            builder.append("Native total: $total ms\n")

            val stages = linkedMapOf<String, Long>()
            warmupWaitMs?.let { stages["ENGINE_WARMUP_WAIT"] = it }
            sessionPrepMs?.let { stages["SESSION_PREPARATION"] = it }
            extractionMs?.let { stages["METADATA_EXTRACTION"] = it }
            val slowest = stages.maxByOrNull { it.value }
            if (slowest != null) {
                builder.append("\nSlowest stage: ${slowest.key} = ${slowest.value} ms\n")
            }
        } else {
            builder.append("Failed stage: ${failedStage ?: "UNKNOWN"}\n")
            builder.append("Duration before failure: $total ms\n")
            builder.append("Error category: ${errorCategory ?: "unknown"}\n")
        }

        builder.append("==================================================")
        Log.d(TAG, builder.toString())

        startNanos.remove(runId)
        lastCheckpointNanos.remove(runId)
    }

    /// A short, non-identifying label for logs — host only, never the
    /// path or query string, so nothing sensitive from the URL reaches
    /// logcat.
    fun sanitizedHost(url: String): String {
        return try {
            Uri.parse(url).host ?: "unknown"
        } catch (throwable: Throwable) {
            "unknown"
        }
    }
}

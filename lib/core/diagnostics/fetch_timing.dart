import 'package:flutter/foundation.dart';

/// TEMPORARY diagnostic timing instrumentation for the Fetch-latency
/// investigation. Every line is prefixed with `[FetchyTiming]` so it can
/// be found in `adb logcat` even though `debugPrint` output surfaces under
/// Flutter's own log tag, not a custom Android one — grep/findstr for the
/// literal text `FetchyTiming` rather than `adb logcat -s FetchyTiming`
/// (that flag-based filter only matches the *native* side's `Log.d`
/// lines). Safe to delete entirely, along with every call site, once the
/// bottleneck is found and fixed — do not remove before then.
///
/// Flip to false to fully disable: no logs, no [Stopwatch] beyond one
/// already-cheap allocation, no behavior change either way.
const bool kFetchTimingDiagnostics = true;

/// One instance per Fetch attempt, identified by a short run id (F001,
/// F002, ...) that every log line for that attempt carries — including
/// the native side's, via the `timingRunId` argument threaded through the
/// engine channel — so concurrent or back-to-back test runs can never be
/// mixed together in the captured logs.
///
/// Uses [Stopwatch], which is backed by a monotonic clock, never wall-clock
/// differences — see `SystemClock.elapsedRealtimeNanos()` on the native
/// side for the same property there.
class FetchTiming {
  FetchTiming._(this.runId) : _stopwatch = Stopwatch()..start();

  static int _counter = 0;

  final String runId;
  final Stopwatch _stopwatch;
  int _lastCheckpointMs = 0;

  /// Starts a new timed Fetch run and returns its id-tagged logger.
  static FetchTiming start() {
    _counter += 1;
    final String id = 'F${_counter.toString().padLeft(3, '0')}';
    final FetchTiming timing = FetchTiming._(id);
    if (kFetchTimingDiagnostics) {
      debugPrint('[FetchyTiming] [$id] +0ms delta=0ms | FETCH_START');
    }
    return timing;
  }

  /// Logs one checkpoint with the elapsed time since [start] and the
  /// delta since the previous checkpoint. [extra] must already be
  /// sanitized by the caller (e.g. a platform display name, never a raw
  /// URL, cookie, or token).
  void checkpoint(String label, {String? extra}) {
    if (!kFetchTimingDiagnostics) return;
    final int elapsed = _stopwatch.elapsedMilliseconds;
    final int delta = elapsed - _lastCheckpointMs;
    _lastCheckpointMs = elapsed;
    final String suffix = extra == null ? '' : ' | $extra';
    debugPrint('[FetchyTiming] [$runId] +${elapsed}ms delta=${delta}ms | $label$suffix');
  }

  /// Elapsed time since [start], in milliseconds — used to compute stage
  /// durations that don't have their own checkpoint pair (e.g. "response
  /// -> preview shown" spans a gap between two checkpoints).
  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  /// Snapshot of [elapsedMs] at the moment this is called — pair two of
  /// these around a stage to get its own duration, the same pattern used
  /// natively (see FetchyTiming.elapsedMs on the Kotlin side).
  int mark() => _stopwatch.elapsedMilliseconds;

  /// Prints the Flutter-side summary block. Only covers what Dart can
  /// directly measure (click -> native request, native round trip as one
  /// figure, response -> preview shown); the native round trip's own
  /// internal breakdown (engine warm-up wait, session prep, extraction) is
  /// printed separately by the native FetchyTiming summary under the same
  /// [runId] — the two are meant to be read together, not merged into one
  /// cross-process object.
  ///
  /// [platform] and [errorCategory] must already be sanitized by the
  /// caller — this never inspects a raw URL or error message itself.
  void summary({
    required bool success,
    String? platform,
    required int clickToNativeRequestMs,
    int? nativeRoundTripMs,
    int? responseToPreviewShownMs,
    String? failedStage,
    String? errorCategory,
  }) {
    if (!kFetchTimingDiagnostics) return;
    final int total = _stopwatch.elapsedMilliseconds;
    final StringBuffer buffer = StringBuffer()
      ..writeln()
      ..writeln('==================================================')
      ..writeln('FETCH TIMING SUMMARY (flutter) [$runId]')
      ..writeln('Platform: ${platform ?? 'Unknown'}')
      ..writeln('Result: ${success ? 'SUCCESS' : 'FAILED'}')
      ..writeln()
      ..writeln('Flutter click -> native request: ${clickToNativeRequestMs}ms');

    if (success) {
      buffer
        ..writeln('Native round trip (request -> response): ${nativeRoundTripMs ?? '?'}ms')
        ..writeln('Native response -> preview shown: ${responseToPreviewShownMs ?? '?'}ms')
        ..writeln('Total (Flutter-visible): ${total}ms')
        ..writeln()
        ..writeln('(see the native FetchyTiming summary for this run\'s')
        ..writeln(' engine warm-up / session / extraction breakdown)');
    } else {
      buffer
        ..writeln('Native round trip before failure: ${nativeRoundTripMs ?? '?'}ms')
        ..writeln('Total (Flutter-visible): ${total}ms')
        ..writeln()
        ..writeln('Failed stage:')
        ..writeln('  ${failedStage ?? 'UNKNOWN'}')
        ..writeln()
        ..writeln('Error category:')
        ..writeln('  ${errorCategory ?? 'unknown'}');
    }

    buffer.write('==================================================');
    debugPrint(buffer.toString());
  }
}

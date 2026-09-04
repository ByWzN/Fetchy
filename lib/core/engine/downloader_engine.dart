import 'dart:async';

import 'package:flutter/services.dart';

import '../../features/media/media_info.dart';
import '../diagnostics/fetch_timing.dart';
import '../platform/platform_channels.dart';

enum EngineErrorCode {
  engineUnavailable,
  unsupportedUrl,
  network,
  jsRuntimeRequired,
  botProtection,
  extractionFailed,
  mergeNotSupported,
  downloadFailed,
  storagePublishFailed,
  videoDownloadFailed,
  audioDownloadFailed,
  ffmpegUnavailable,
  mergeFailed,
  outputMissing,
  unknown,
}

class EngineException implements Exception {
  const EngineException(this.code, this.message);

  final EngineErrorCode code;
  final String message;

  @override
  String toString() => 'EngineException(${code.name}): $message';
}

enum DownloadStatus { started, running, merging, completed, failed, canceled }

class DownloadEvent {
  const DownloadEvent({
    required this.downloadId,
    required this.status,
    this.progress,
    this.etaSeconds,
    this.totalBytes,
    this.speedBytesPerSecond,
    this.outputPath,
    this.outputUri,
    this.errorCode,
    this.errorMessage,
    this.warningMessage,
  });

  final String downloadId;
  final DownloadStatus status;

  /// 0.0–1.0, or null when unknown. During [DownloadStatus.merging] this is
  /// always null — FFmpeg statistics are not wired to the UI yet, so no
  /// percentage is invented for that phase.
  final double? progress;

  final int? etaSeconds;

  /// Total size of the stream currently being transferred, as reported by
  /// yt-dlp itself. Null when yt-dlp did not report one (some fragmented
  /// streams), in which case no total is shown rather than a guess.
  final int? totalBytes;

  /// Current transfer rate reported by yt-dlp, in bytes per second. Null
  /// while yt-dlp has not printed a rate yet.
  final int? speedBytesPerSecond;

  /// Bytes transferred so far, derived from the two real reported values
  /// (percentage x total). Null unless both are known.
  int? get downloadedBytes {
    final double? fraction = progress;
    final int? total = totalBytes;
    if (fraction == null || total == null || total <= 0) return null;
    return (total * fraction).round().clamp(0, total);
  }

  /// User-facing location, e.g. "Download/Fetchy/clip.mp4". Present only
  /// once the file has been published to shared storage.
  final String? outputPath;

  /// MediaStore content URI (or file:// on API < 29) for the published file.
  final String? outputUri;

  final EngineErrorCode? errorCode;
  final String? errorMessage;

  /// A soft, non-fatal note about this otherwise-successful download (e.g.
  /// "this file type does not support embedded artwork"). Never set
  /// together with [errorCode] — a warning only ever accompanies
  /// [DownloadStatus.completed].
  final String? warningMessage;

  bool get isTerminal =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.canceled;

  static DownloadEvent fromMap(Map<Object?, Object?> map) {
    final double? rawProgress = (map['progress'] as num?)?.toDouble();
    final int? rawEta = (map['etaSeconds'] as num?)?.toInt();

    return DownloadEvent(
      downloadId: (map['downloadId'] as String?) ?? '',
      status: _statusFrom(map['status'] as String?),
      progress: (rawProgress == null || rawProgress < 0)
          ? null
          : (rawProgress / 100.0).clamp(0.0, 1.0),
      etaSeconds: (rawEta == null || rawEta < 0) ? null : rawEta,
      totalBytes: _positiveOrNull(map['totalBytes']),
      speedBytesPerSecond: _positiveOrNull(map['speedBytesPerSecond']),
      outputPath: map['outputPath'] as String?,
      outputUri: map['outputUri'] as String?,
      errorCode: _errorCodeFrom(map['errorCode'] as String?),
      errorMessage: map['errorMessage'] as String?,
      warningMessage: map['warningMessage'] as String?,
    );
  }

  static int? _positiveOrNull(Object? raw) {
    final int? value = (raw as num?)?.toInt();
    return (value == null || value <= 0) ? null : value;
  }

  static DownloadStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'started':
        return DownloadStatus.started;
      case 'running':
        return DownloadStatus.running;
      case 'merging':
        return DownloadStatus.merging;
      case 'completed':
        return DownloadStatus.completed;
      case 'canceled':
        return DownloadStatus.canceled;
      default:
        return DownloadStatus.failed;
    }
  }

  static EngineErrorCode? _errorCodeFrom(String? raw) {
    if (raw == null) return null;
    return mapEngineErrorCode(raw);
  }
}

EngineErrorCode mapEngineErrorCode(String code) {
  switch (code) {
    case 'engine_unavailable':
      return EngineErrorCode.engineUnavailable;
    case 'unsupported_url':
      return EngineErrorCode.unsupportedUrl;
    case 'network':
      return EngineErrorCode.network;
    case 'js_runtime_required':
      return EngineErrorCode.jsRuntimeRequired;
    case 'bot_protection':
      return EngineErrorCode.botProtection;
    case 'extraction_failed':
      return EngineErrorCode.extractionFailed;
    case 'merge_not_supported':
      return EngineErrorCode.mergeNotSupported;
    case 'download_failed':
      return EngineErrorCode.downloadFailed;
    case 'storage_publish_failed':
      return EngineErrorCode.storagePublishFailed;
    case 'video_download_failed':
      return EngineErrorCode.videoDownloadFailed;
    case 'audio_download_failed':
      return EngineErrorCode.audioDownloadFailed;
    case 'ffmpeg_unavailable':
      return EngineErrorCode.ffmpegUnavailable;
    case 'merge_failed':
      return EngineErrorCode.mergeFailed;
    case 'output_missing':
      return EngineErrorCode.outputMissing;
    default:
      return EngineErrorCode.unknown;
  }
}

abstract class DownloaderEngine {
  /// [timingRunId] is TEMPORARY diagnostic-only plumbing — see
  /// core/diagnostics/fetch_timing.dart. It only tags native's own
  /// FetchyTiming log lines so they can be correlated with this Fetch
  /// attempt's Dart-side logs; it never affects extraction itself.
  Future<MediaInfo> extract(String url, {String? timingRunId});

  Stream<DownloadEvent> get downloadEvents;

  /// Starts a download. When [audioFormatId] is provided, the native side
  /// downloads both streams separately and merges them with FFmpeg before
  /// publishing; otherwise a single format is downloaded directly.
  ///
  /// [storage] is the current Download Location configuration (see
  /// `StorageSettings.toChannelArgument`) — it only affects where the
  /// finished file is published, never how it is extracted or downloaded.
  ///
  /// [downloadOptions] is the optional Download Options payload (see
  /// `DownloadOptions.toChannelArgument`) — null/omitted behaves exactly
  /// like a download with no options ever existed.
  Future<void> startDownload({
    required String downloadId,
    required String url,
    required String formatId,
    String? audioFormatId,
    Map<String, Object?>? storage,
    Map<String, Object?>? downloadOptions,
    int? playlistIndex,
  });

  Future<bool> cancelDownload(String downloadId);
}

class PlatformDownloaderEngine implements DownloaderEngine {
  PlatformDownloaderEngine._();

  static final PlatformDownloaderEngine instance = PlatformDownloaderEngine._();

  final StreamController<DownloadEvent> _eventsController =
      StreamController<DownloadEvent>.broadcast();

  bool _handlerInstalled = false;

  @override
  Stream<DownloadEvent> get downloadEvents {
    _ensureHandlerInstalled();
    return _eventsController.stream;
  }

  void _ensureHandlerInstalled() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    PlatformChannels.engineChannel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != PlatformChannels.onDownloadEvent) return;

    final Object? arguments = call.arguments;
    if (arguments is! Map<Object?, Object?>) return;
    if (_eventsController.isClosed) return;

    _eventsController.add(DownloadEvent.fromMap(arguments));
  }

  @override
  Future<MediaInfo> extract(String url, {String? timingRunId}) async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.engineChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.extractMedia,
            <String, Object?>{
              'url': url,
              if (kFetchTimingDiagnostics && timingRunId != null)
                'timingRunId': timingRunId,
            },
          );

      if (result == null) {
        throw const EngineException(
          EngineErrorCode.extractionFailed,
          'Engine returned no data.',
        );
      }

      return MediaInfo.fromMap(result);
    } on MissingPluginException {
      throw const EngineException(
        EngineErrorCode.engineUnavailable,
        'Native engine is not registered on this build.',
      );
    } on PlatformException catch (error) {
      throw EngineException(
        mapEngineErrorCode(error.code),
        error.message ?? 'Extraction failed.',
      );
    }
  }

  @override
  Future<void> startDownload({
    required String downloadId,
    required String url,
    required String formatId,
    String? audioFormatId,
    Map<String, Object?>? storage,
    Map<String, Object?>? downloadOptions,
    int? playlistIndex,
  }) async {
    _ensureHandlerInstalled();

    try {
      await PlatformChannels.engineChannel.invokeMethod<void>(
        PlatformChannels.startDownload,
        <String, Object?>{
          'downloadId': downloadId,
          'url': url,
          'formatId': formatId,
          'storage': storage,
          'downloadOptions': downloadOptions,
          // Omitted (null) for ordinary single-video URLs, which is what
          // keeps their command line byte-for-byte unchanged.
          'playlistIndex': playlistIndex,
        },
      );
    } on MissingPluginException {
      throw const EngineException(
        EngineErrorCode.engineUnavailable,
        'Native engine is not registered on this build.',
      );
    } on PlatformException catch (error) {
      throw EngineException(
        mapEngineErrorCode(error.code),
        error.message ?? 'Download failed to start.',
      );
    }
  }

  @override
  Future<bool> cancelDownload(String downloadId) async {
    try {
      final bool? canceled = await PlatformChannels.engineChannel
          .invokeMethod<bool>(
            PlatformChannels.cancelDownload,
            <String, Object?>{'downloadId': downloadId},
          );
      return canceled ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

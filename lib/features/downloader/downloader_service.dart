import 'package:flutter/foundation.dart';

import '../../core/diagnostics/fetch_timing.dart';
import '../../core/engine/downloader_engine.dart';
import '../../core/storage/storage_settings.dart';
import '../../core/storage/storage_settings_service.dart';
import '../media/format_selector.dart';
import '../media/media_info.dart';
import 'download_options.dart';

sealed class ExtractionResult {
  const ExtractionResult();
}

final class ExtractionSuccess extends ExtractionResult {
  const ExtractionSuccess(this.mediaInfo);

  final MediaInfo mediaInfo;
}

final class ExtractionFailure extends ExtractionResult {
  const ExtractionFailure(this.code, this.message);

  final EngineErrorCode code;
  final String message;
}

sealed class DownloadStartResult {
  const DownloadStartResult();
}

final class DownloadAccepted extends DownloadStartResult {
  const DownloadAccepted(this.downloadId);

  final String downloadId;
}

final class DownloadRejected extends DownloadStartResult {
  const DownloadRejected(this.code, this.message);

  final EngineErrorCode code;
  final String message;
}

class DownloaderService {
  DownloaderService({DownloaderEngine? engine})
    : _engine = engine ?? PlatformDownloaderEngine.instance;

  final DownloaderEngine _engine;

  Stream<DownloadEvent> get downloadEvents => _engine.downloadEvents;

  /// Allocates a download id up front so a caller can start filtering
  /// [downloadEvents] before any native call is made. Without this, the
  /// first event can be emitted before the caller knows the id and is
  /// silently dropped.
  String newDownloadId() => 'dl_${DateTime.now().microsecondsSinceEpoch}';

  /// [timing], when supplied, is TEMPORARY diagnostic-only plumbing — see
  /// core/diagnostics/fetch_timing.dart. It logs ENGINE_REQUEST_SENT here
  /// (right before the platform channel is actually invoked) and threads
  /// its run id down to native so both sides' logs can be correlated.
  Future<ExtractionResult> extract(String url, {FetchTiming? timing}) async {
    final String trimmed = url.trim();

    if (trimmed.isEmpty) {
      return const ExtractionFailure(
        EngineErrorCode.unsupportedUrl,
        'No URL provided.',
      );
    }

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return const ExtractionFailure(
        EngineErrorCode.unsupportedUrl,
        'That does not look like a valid link.',
      );
    }

    timing?.checkpoint('ENGINE_REQUEST_SENT');
    try {
      final MediaInfo info = await _engine.extract(trimmed, timingRunId: timing?.runId);
      return ExtractionSuccess(info);
    } on EngineException catch (error) {
      return ExtractionFailure(error.code, error.message);
    }
  }

  /// Starts a single download using an id obtained from [newDownloadId].
  ///
  /// Converts the selected [FormatCandidate] into one final yt-dlp format
  /// expression: what Fetchy shows the user is what gets requested.
  ///
  /// - [FormatSourceKind.combined] / [FormatSourceKind.audioOnly]: the
  ///   exact selected format id, unchanged.
  /// - [FormatSourceKind.merge]: the exact selected video format id, paired
  ///   with yt-dlp's own "bestaudio" resolution rather than
  ///   [FormatSelector]'s specific audio pick — yt-dlp is best placed to
  ///   choose an audio track that is actually mergeable with this video
  ///   format, and merging is now yt-dlp's own responsibility, not ours.
  /// - [FormatSourceKind.videoOnly]: rejected — no audio to pair with, so
  ///   publishing would produce a silent video.
  /// [playlistIndex] is the 1-based position of the entry that was actually
  /// previewed, when the extraction returned several. It is passed straight
  /// through so the download targets that one entry instead of re-resolving
  /// the URL and matching every entry it finds. Null for ordinary
  /// single-video URLs, and then nothing about the invocation changes.
  Future<DownloadStartResult> startDownload({
    required String downloadId,
    required String url,
    required FormatCandidate candidate,
    DownloadOptions? downloadOptions,
    int? playlistIndex,
  }) async {
    // The safety rule stays in force everywhere except one explicit path:
    // the Advanced "Include audio: OFF" toggle, which only ever reaches
    // here paired with a user-picked video-only format from
    // MediaSelectionCatalog.advancedVideoOnlyEntries. Every other caller —
    // Quick Fetch included — never sets includeAudio to false, so this
    // bypass is inert for them and the rejection below still applies.
    final bool explicitlyAllowedSilentVideo =
        candidate.kind == FormatSourceKind.videoOnly &&
        downloadOptions?.video?.includeAudio == false;

    if (candidate.kind == FormatSourceKind.videoOnly &&
        !explicitlyAllowedSilentVideo) {
      return const DownloadRejected(
        EngineErrorCode.mergeNotSupported,
        'This quality has no matching audio track available to combine '
        'it with. Pick a different quality.',
      );
    }

    final String? primaryFormatId = candidate.primary.formatId;
    if (primaryFormatId == null || primaryFormatId.trim().isEmpty) {
      return const DownloadRejected(
        EngineErrorCode.downloadFailed,
        'The selected format has no usable identifier.',
      );
    }

    final String formatExpression = candidate.kind == FormatSourceKind.merge
        ? '$primaryFormatId+bestaudio/best'
        : primaryFormatId;

    // DIAGNOSTIC — remove once the 1080p merge/download path is confirmed
    // working.
    debugPrint(
      'Fetchy[download]: downloadId=$downloadId '
      'kind=${candidate.kind} '
      'primaryFormatId=$primaryFormatId '
      'formatExpression=$formatExpression',
    );

    // Read fresh every time rather than cached: the user may have changed
    // Download Location since the app started, and this is cheap local
    // SharedPreferences access, not a storage scan.
    final StorageSettings storageSettings = await StorageSettingsService.instance.load();

    try {
      await _engine.startDownload(
        downloadId: downloadId,
        url: url,
        formatId: formatExpression,
        storage: storageSettings.toChannelArgument(),
        downloadOptions: downloadOptions?.toChannelArgument(),
        playlistIndex: playlistIndex,
      );
      return DownloadAccepted(downloadId);
    } on EngineException catch (error) {
      return DownloadRejected(error.code, error.message);
    }
  }

  Future<bool> cancelDownload(String downloadId) {
    return _engine.cancelDownload(downloadId);
  }
}

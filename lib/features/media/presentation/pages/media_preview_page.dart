import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/diagnostics/fetch_timing.dart';
import '../../../../core/engine/downloader_engine.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../downloader/downloader_service.dart';
import '../../../downloader/duplicate_check_dialog.dart';
import '../../../history/history_entry.dart';
import '../../../history/history_service.dart';
import '../../../downloader/extraction_error_mapper.dart';
import '../../../downloader/extraction_error_presentation.dart';
import '../../../downloader/presentation/download_status_cards.dart';
import '../../../sessions/platform_session.dart';
import '../../../sessions/presentation/pages/connected_accounts_page.dart';
import '../../../sessions/session_service.dart';
import '../media_preview.dart';

/// A standalone page that takes a URL and goes straight to quality selection.
///
/// This is the Quick Fetch landing screen: it deliberately skips Home, but it
/// runs the *same* pipeline — [DownloaderService.extract], the shared
/// [MediaPreview] widget, [DownloaderService.startDownload], and
/// [HistoryService]. No extraction, format, or download logic is duplicated
/// here; only the page scaffolding around them is new.
class MediaPreviewPage extends StatefulWidget {
  const MediaPreviewPage({super.key, required this.url});

  final String url;

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  final DownloaderService _downloaderService = DownloaderService();
  final HistoryService _historyService = HistoryService.instance;

  StreamSubscription<DownloadEvent>? _downloadSubscription;

  bool _isExtracting = true;
  ExtractionResult? _result;

  /// Mirrors HomePage's generic slow-fetch message — fires 6s into an
  /// extraction that's still running, for any site. Cancelled and nulled
  /// out the moment extraction ends or a new one begins.
  Timer? _slowFetchTimer;
  bool _showSlowFetchMessage = false;

  String? _activeDownloadId;
  DownloadEvent? _downloadEvent;
  String? _downloadRejection;
  DownloadSelection? _activeSelection;

  List<PlatformSession> _sessions = const <PlatformSession>[];

  @override
  void initState() {
    super.initState();
    _historyService.load();
    _downloadSubscription = _downloaderService.downloadEvents.listen(
      _onDownloadEvent,
    );
    _loadSessions();
    _extract();
  }

  Future<void> _loadSessions() async {
    final List<PlatformSession> sessions = await SessionService.instance
        .listSessions();
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  bool _hasSessionFor(String? platformDisplayName) {
    final SessionPlatform? platform = SessionPlatformInfo.fromDisplayName(
      platformDisplayName,
    );
    if (platform == null) return false;
    return _sessions.any(
      (PlatformSession s) => s.platform == platform && s.isConnected,
    );
  }

  Future<void> _openConnectedAccounts(SessionPlatform platform) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ConnectedAccountsPage(),
      ),
    );
    await _loadSessions();
  }

  @override
  void dispose() {
    _slowFetchTimer?.cancel();
    _downloadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _extract() async {
    // TIMING — temporary diagnostic instrumentation for the Fetch-latency
    // investigation; mirrors HomePage._onFetchPressed so Quick Fetch's
    // landing extraction is just as measurable. See
    // core/diagnostics/fetch_timing.dart. "FETCH_CLICK" here means
    // "extraction initiated" — Quick Fetch has no separate button tap of
    // its own, extraction starts as soon as this page opens.
    final FetchTiming timing = FetchTiming.start();
    final String? platform = ExtractionErrorMapper.platformForUrl(widget.url);
    timing.checkpoint('FETCH_CLICK', extra: platform == null ? null : 'platform=$platform');
    timing.checkpoint('FETCH_INPUT_VALIDATED');

    // A repeat extraction must never let a previous request's timer
    // surface its message against this new one.
    _slowFetchTimer?.cancel();

    setState(() {
      _isExtracting = true;
      _result = null;
      _showSlowFetchMessage = false;
    });

    // Purely informational UX — reuses this same extraction's own
    // lifecycle rather than a second fetch state system. Applies to any
    // site: only after 6s of this exact request still being in flight,
    // and only if it hasn't already finished.
    _slowFetchTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _isExtracting) {
        setState(() => _showSlowFetchMessage = true);
      }
    });

    final int clickToRequestMs = timing.mark();
    final ExtractionResult result = await _downloaderService.extract(
      widget.url,
      timing: timing,
    );
    final int roundTripMs = timing.mark() - clickToRequestMs;
    timing.checkpoint('ENGINE_RESPONSE_RECEIVED', extra: 'success=${result is ExtractionSuccess}');

    _slowFetchTimer?.cancel();
    _slowFetchTimer = null;

    if (!mounted) return;

    final int beforeSetStateMs = timing.mark();
    setState(() {
      _isExtracting = false;
      _result = result;
      _showSlowFetchMessage = false;
    });
    timing.checkpoint('MEDIA_PREVIEW_BUILD_SCHEDULED');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      timing.checkpoint('MEDIA_PREVIEW_SHOWN');
      final int responseToShownMs = timing.mark() - beforeSetStateMs;

      if (result is ExtractionSuccess) {
        timing.summary(
          success: true,
          platform: platform,
          clickToNativeRequestMs: clickToRequestMs,
          nativeRoundTripMs: roundTripMs,
          responseToPreviewShownMs: responseToShownMs,
        );
      } else if (result is ExtractionFailure) {
        timing.summary(
          success: false,
          platform: platform,
          clickToNativeRequestMs: clickToRequestMs,
          nativeRoundTripMs: roundTripMs,
          failedStage: 'METADATA_EXTRACTION',
          errorCategory: result.code.name,
        );
      }
    });
  }

  Future<void> _onDownloadRequested(DownloadSelection selection) async {
    if (_activeDownloadId != null) return;

    final DuplicateAction? duplicateAction =
        await DuplicateCheckHelper.checkAndPrompt(
          context: context,
          selection: selection,
          historyService: _historyService,
        );

    if (duplicateAction == DuplicateAction.cancel ||
        duplicateAction == DuplicateAction.open) {
      return;
    }

    final String downloadId = _downloaderService.newDownloadId();

    setState(() {
      _activeDownloadId = downloadId;
      _activeSelection = selection;
      _downloadEvent = null;
      _downloadRejection = null;
    });

    final DownloadStartResult start = await _downloaderService.startDownload(
      downloadId: downloadId,
      url: selection.mediaInfo.webpageUrl ?? selection.mediaInfo.sourceUrl,
      candidate: selection.candidate,
      downloadOptions: selection.downloadOptions,
      // Download exactly the entry that was previewed, for URLs that
      // resolved to several.
      playlistIndex: selection.mediaInfo.playlistIndex,
    );

    if (!mounted) return;

    if (start is DownloadRejected) {
      setState(() {
        _activeDownloadId = null;
        _downloadRejection = start.message;
      });
    }
  }

  Future<void> _onCancelPressed() async {
    final String? id = _activeDownloadId;
    if (id == null) return;
    await _downloaderService.cancelDownload(id);
  }

  void _onDownloadEvent(DownloadEvent event) {
    if (!mounted) return;
    if (event.downloadId != _activeDownloadId) return;

    setState(() {
      _downloadEvent = event;
      if (event.isTerminal) _activeDownloadId = null;
    });

    if (event.status == DownloadStatus.completed) {
      _recordHistoryEntry(event);
    }
  }

  Future<void> _recordHistoryEntry(DownloadEvent event) async {
    final DownloadSelection? selection = _activeSelection;
    if (selection == null) return;

    final bool isAudio = selection.isAudioOnly;
    final int? height = selection.candidate.height;
    final String? qualityLabel = isAudio
        ? selection.audioOutput?.label
        : (height != null ? '${height}p' : null);

    final String? outputPath = event.outputPath;
    final String? fileName = outputPath
        ?.split(RegExp(r'[\\/]'))
        .where((String s) => s.isNotEmpty)
        .lastOrNull;

    await _historyService.add(
      HistoryEntry(
        id: event.downloadId,
        title: selection.mediaInfo.title,
        sourceUrl: selection.mediaInfo.sourceUrl,
        downloadedAt: DateTime.now(),
        thumbnailUrl: selection.mediaInfo.thumbnailUrl,
        fileName: fileName,
        outputPath: outputPath,
        outputUri: event.outputUri,
        mediaType: isAudio ? 'audio' : 'video',
        qualityLabel: qualityLabel,
        fileSizeBytes: selection.candidate.filesize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyScaffold(
      title: strings.quickFetchTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          ..._buildSlowFetchMessage(strings),
          ..._buildResultSection(strings),
          ..._buildDownloadSection(strings),
        ],
      ),
    );
  }

  /// Purely reassuring, never an error — some sites genuinely take longer
  /// to extract than others. Mirrors HomePage's identical message.
  List<Widget> _buildSlowFetchMessage(AppLocalizations strings) {
    if (!_showSlowFetchMessage) return const <Widget>[];

    return <Widget>[
      FetchyBanner(message: strings.homeSlowFetchMessage),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  List<Widget> _buildResultSection(AppLocalizations strings) {
    if (_isExtracting) {
      return <Widget>[_ExtractingCard(message: strings.fetching)];
    }

    final ExtractionResult? result = _result;
    if (result == null) return const <Widget>[];

    if (result is ExtractionFailure) {
      final String? platform = ExtractionErrorMapper.platformForUrl(widget.url);
      final MappedExtractionError mapped = ExtractionErrorMapper.map(
        result.message,
        platform: platform,
        hasSession: _hasSessionFor(platform),
      );
      return <Widget>[
        DownloadMessageCard(
          title: strings.fetchFailed,
          message: extractionMessageFor(mapped, strings, platform: platform),
          isError: true,
          errorDetails: mapped,
          platform: platform,
          onRetry: _extract,
          onConnectAccount: _openConnectedAccounts,
        ),
        const SizedBox(height: AppSpacing.md),
        FetchyTonalButton(
          label: strings.commonTryAgain,
          icon: Icons.refresh_rounded,
          emphasis: true,
          onPressed: _extract,
        ),
      ];
    }

    if (result is ExtractionSuccess) {
      return <Widget>[
        MediaPreview(
          key: ValueKey<String>(result.mediaInfo.sourceUrl),
          mediaInfo: result.mediaInfo,
          onDownloadRequested: _onDownloadRequested,
          isDownloading: _activeDownloadId != null,
        ),
      ];
    }

    return const <Widget>[];
  }

  List<Widget> _buildDownloadSection(AppLocalizations strings) {
    final String? rejection = _downloadRejection;
    if (rejection != null) {
      return <Widget>[
        const SizedBox(height: AppSpacing.md),
        DownloadMessageCard(
          title: strings.downloadFailed,
          message: rejection,
          isError: true,
        ),
      ];
    }

    final DownloadEvent? event = _downloadEvent;
    final DownloadSelection? selection = _activeSelection;

    if (event == null) {
      if (_activeDownloadId == null) return const <Widget>[];
      return <Widget>[
        const SizedBox(height: AppSpacing.md),
        DownloadProgressCard(
          strings: strings,
          event: null,
          selection: selection,
          onCancel: _onCancelPressed,
        ),
      ];
    }

    switch (event.status) {
      case DownloadStatus.started:
      case DownloadStatus.running:
        return <Widget>[
          const SizedBox(height: AppSpacing.md),
          DownloadProgressCard(
            strings: strings,
            event: event,
            selection: selection,
            onCancel: _onCancelPressed,
          ),
        ];

      case DownloadStatus.merging:
        return <Widget>[
          const SizedBox(height: AppSpacing.md),
          DownloadMergingCard(strings: strings),
        ];

      case DownloadStatus.completed:
        return <Widget>[
          const SizedBox(height: AppSpacing.md),
          DownloadCompletedCard(event: event, selection: selection),
        ];

      case DownloadStatus.canceled:
        return <Widget>[
          const SizedBox(height: AppSpacing.md),
          DownloadMessageCard(
            title: strings.downloadCanceled,
            message: '',
            isError: false,
          ),
        ];

      case DownloadStatus.failed:
        final String? platform = ExtractionErrorMapper.platformForUrl(widget.url);
        final MappedExtractionError mapped = ExtractionErrorMapper.map(
          event.errorMessage,
          platform: platform,
          hasSession: _hasSessionFor(platform),
        );
        return <Widget>[
          const SizedBox(height: AppSpacing.md),
          DownloadMessageCard(
            title: strings.downloadFailed,
            message: extractionMessageFor(mapped, strings, platform: platform),
            isError: true,
            errorDetails: mapped,
            platform: platform,
            onConnectAccount: _openConnectedAccounts,
          ),
        ];
    }
  }
}

/// The single extraction-in-progress state for this page.
class _ExtractingCard extends StatelessWidget {
  const _ExtractingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FetchyCard(
      child: Row(
        children: <Widget>[
          // Sized to sit alongside the label as an equal, not as an
          // afterthought — this is the only thing happening on the screen
          // while an extraction runs.
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3.2),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

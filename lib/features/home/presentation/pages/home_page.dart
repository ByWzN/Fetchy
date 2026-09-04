import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/fetchy_hook_icon.dart';
import '../../../../app/theme/fetchy_wordmark.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/diagnostics/fetch_timing.dart';
import '../../../../core/engine/downloader_engine.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../features/downloader/downloader_service.dart';
import '../../../downloader/duplicate_check_dialog.dart';
import '../../../downloader/extraction_error_mapper.dart';
import '../../../downloader/extraction_error_presentation.dart';
import '../../../downloader/presentation/download_status_cards.dart';
import '../../../history/history_entry.dart';
import '../../../history/history_service.dart';
import '../../../history/presentation/pages/history_detail_page.dart';
import '../../../history/presentation/widgets/history_list_tile.dart';
import '../../../media/presentation/media_preview.dart';
import '../../../sessions/platform_session.dart';
import '../../../sessions/presentation/pages/connected_accounts_page.dart';
import '../../../sessions/session_service.dart';
import '../../../share/share_intent_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _linkController = TextEditingController();
  final ShareIntentService _shareIntentService = ShareIntentService.instance;
  final DownloaderService _downloaderService = DownloaderService();
  final HistoryService _historyService = HistoryService.instance;

  StreamSubscription<String>? _sharedLinkSubscription;
  StreamSubscription<DownloadEvent>? _downloadSubscription;

  bool _hasLink = false;
  bool _isExtracting = false;
  ExtractionResult? _result;

  /// The exact text that produced [_result]. Compared against the field on
  /// every keystroke so an edited or cleared link takes its own preview
  /// down with it — see [_onLinkChanged].
  String? _fetchedUrl;

  /// Fires 6s into any extraction that's still running — see
  /// _onFetchPressed. Cancelled and nulled out the moment extraction ends
  /// (success or failure) or a new Fetch begins, so a stale timer from a
  /// previous request can never surface its message against a different
  /// one.
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
    _linkController.addListener(_onLinkChanged);
    _initializeSharedLinkHandling();
    _historyService.load();
    _loadSessions();
    _downloadSubscription = _downloaderService.downloadEvents.listen(
      _onDownloadEvent,
    );
  }

  @override
  void dispose() {
    _slowFetchTimer?.cancel();
    _downloadSubscription?.cancel();
    _sharedLinkSubscription?.cancel();
    _linkController.removeListener(_onLinkChanged);
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _initializeSharedLinkHandling() async {
    _shareIntentService.start();
    _sharedLinkSubscription = _shareIntentService.sharedLinks.listen(
      _applySharedLink,
    );

    final String? initialLink = await _shareIntentService
        .consumeInitialSharedLink();
    if (!mounted || initialLink == null) {
      return;
    }
    _applySharedLink(initialLink);
  }

  void _applySharedLink(String link) {
    _linkController.text = link;
    _linkController.selection = TextSelection.collapsed(offset: link.length);
  }

  /// Keeps the page honest about which link the result on screen belongs to.
  ///
  /// Clearing or editing the field means whatever is previewed below no
  /// longer describes what is typed above, so the preview goes with it —
  /// otherwise an empty box can sit over a media card, as it could before.
  ///
  /// An in-flight or finished **download** is deliberately left alone: that
  /// is work the user already committed to, and tearing its card away
  /// because they touched the text field would lose them the progress and
  /// the Open/Share actions.
  void _onLinkChanged() {
    final String text = _linkController.text.trim();
    final bool hasLink = text.isNotEmpty;
    final bool staleResult =
        (_result != null || _downloadRejection != null) && text != _fetchedUrl;

    if (hasLink == _hasLink && !staleResult) return;

    setState(() {
      _hasLink = hasLink;
      if (staleResult) {
        _result = null;
        _downloadRejection = null;
        _showSlowFetchMessage = false;
        _fetchedUrl = null;
      }
    });
  }

  Future<void> _onPastePressed() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _linkController.text = text;
      _linkController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void _onClearPressed() {
    _linkController.clear();
  }

  Future<void> _loadSessions() async {
    final List<PlatformSession> sessions = await SessionService.instance
        .listSessions();
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  /// Whether a session is currently connected for the platform an error
  /// mapper detected — used to phrase the error honestly (session-expired
  /// vs. plain sign-in-required) and to decide whether the "Connect
  /// account" action makes sense at all.
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

  Future<void> _onFetchPressed() async {
    final String url = _linkController.text.trim();
    if (url.isEmpty || _isExtracting) {
      return;
    }

    // TIMING — temporary diagnostic instrumentation for the Fetch-latency
    // investigation; see core/diagnostics/fetch_timing.dart. Every
    // checkpoint for this attempt carries the same run id, including the
    // ones logged natively, so `adb logcat` output for concurrent/repeat
    // test runs never gets mixed up. Do not remove until the bottleneck
    // this was added to find has been identified and fixed.
    final FetchTiming timing = FetchTiming.start();
    final String? platform = ExtractionErrorMapper.platformForUrl(url);
    timing.checkpoint('FETCH_CLICK', extra: platform == null ? null : 'platform=$platform');
    timing.checkpoint('FETCH_INPUT_VALIDATED');

    // A repeat Fetch must never let a previous request's timer surface its
    // message against this new one.
    _slowFetchTimer?.cancel();

    setState(() {
      _isExtracting = true;
      _result = null;
      _fetchedUrl = url;
      _downloadEvent = null;
      _activeDownloadId = null;
      _activeSelection = null;
      _downloadRejection = null;
      _showSlowFetchMessage = false;
    });

    // Purely informational UX — reuses this same extraction's own
    // lifecycle (started above, ended below) rather than a second fetch
    // state system. Applies to any site now (previously YouTube-only):
    // only after 6s of this exact request still being in flight, and only
    // if it hasn't already finished.
    _slowFetchTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _isExtracting) {
        setState(() => _showSlowFetchMessage = true);
      }
    });

    final int clickToRequestMs = timing.mark();
    final ExtractionResult result = await _downloaderService.extract(url, timing: timing);
    final int roundTripMs = timing.mark() - clickToRequestMs;
    timing.checkpoint('ENGINE_RESPONSE_RECEIVED', extra: 'success=${result is ExtractionSuccess}');

    _slowFetchTimer?.cancel();
    _slowFetchTimer = null;

    if (!mounted) {
      return;
    }

    final int beforeSetStateMs = timing.mark();
    setState(() {
      _isExtracting = false;
      _result = result;
      _showSlowFetchMessage = false;
    });
    timing.checkpoint('MEDIA_PREVIEW_BUILD_SCHEDULED');

    // Fires after the frame that renders the just-scheduled rebuild (the
    // MediaPreview card on success, or the error card on failure) has
    // actually been laid out and painted — this is genuinely "shown", not
    // just "scheduled".
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

    // Check for duplicate before starting network-heavy download
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

    // Home has no app bar. The name belongs *in* the page, directly above
    // the sentence it introduces, rather than pinned to the top of the
    // window: pinned, it sat marooned away from everything else, and the
    // list scrolled underneath it so the tagline slid through the title.
    // As the first item in the list it keeps its place in the group and
    // scrolls away with the rest.
    return FetchyScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.hero + AppSpacing.xxl,
          AppSpacing.page,
          100,
        ),
        children: <Widget>[
          const Center(
            child: FetchyWordmark(fontSize: 34, includeMark: false),
          ),
          const SizedBox(height: AppSpacing.lg),
          _HomeTagline(strings: strings),
          const SizedBox(height: AppSpacing.xxxl),
          _LinkInputSection(
            controller: _linkController,
            hasLink: _hasLink,
            isExtracting: _isExtracting,
            strings: strings,
            onFetchPressed: _onFetchPressed,
            onPastePressed: _onPastePressed,
            onClearPressed: _onClearPressed,
          ),
          ..._buildSlowFetchMessage(strings),
          ..._buildResultSection(strings),
          ..._buildDownloadSection(strings),
          const SizedBox(height: AppSpacing.xxl),
          FetchySectionHeader(title: strings.recentDownloads),
          _RecentDownloadsSection(historyService: _historyService),
        ],
      ),
    );
  }

  /// Purely reassuring, never an error — some sites genuinely take longer
  /// to extract than others, and this just says so once a Fetch has been
  /// running a while. See _onFetchPressed for the 6-second timer that
  /// drives [_showSlowFetchMessage].
  List<Widget> _buildSlowFetchMessage(AppLocalizations strings) {
    if (!_showSlowFetchMessage) return const <Widget>[];

    return <Widget>[
      const SizedBox(height: AppSpacing.md),
      FetchyBanner(message: strings.homeSlowFetchMessage),
    ];
  }

  List<Widget> _buildResultSection(AppLocalizations strings) {
    // Single loading state: The Fetch button already reflects the loading spinner.
    if (_isExtracting) return const <Widget>[];

    final ExtractionResult? result = _result;
    if (result == null) return const <Widget>[];

    if (result is ExtractionFailure) {
      final String? platform = ExtractionErrorMapper.platformForUrl(
        _linkController.text,
      );
      final MappedExtractionError mapped = ExtractionErrorMapper.map(
        result.message,
        platform: platform,
        hasSession: _hasSessionFor(platform),
      );
      return <Widget>[
        const SizedBox(height: AppSpacing.lg),
        DownloadMessageCard(
          title: strings.fetchFailed,
          message: extractionMessageFor(mapped, strings, platform: platform),
          isError: true,
          errorDetails: mapped,
          platform: platform,
          onRetry: _onFetchPressed,
          onConnectAccount: _openConnectedAccounts,
        ),
      ];
    }

    if (result is ExtractionSuccess) {
      return <Widget>[
        const SizedBox(height: AppSpacing.lg),
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
        final String? platform = ExtractionErrorMapper.platformForUrl(
          _linkController.text,
        );
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

/// The single sentence under the masthead.
///
/// This replaced a heading plus a separate instruction ("Fetch any media
/// link" / "Paste a link or share it to Fetchy"). Two lines saying
/// overlapping things read as filler; one sentence that states the whole
/// promise — give it a link, get the media — does the same job and leaves
/// the screen calmer.
class _HomeTagline extends StatelessWidget {
  const _HomeTagline({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // One fixed size. It previously stepped between two sizes depending on
    // whether the page had a result on it, which meant the sentence — and
    // everything under it — jumped every time a fetch completed.
    return Text(
      strings.homeTagline,
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// The link field and the Fetch action.
///
/// Deliberately not wrapped in a card: the two controls sit directly on the
/// page wash so the primary action is the most prominent object on the
/// screen rather than one element inside a box. The field is a recessed
/// well and the button is the only gradient surface in the app, which is
/// the whole visual argument for where to tap first.
class _LinkInputSection extends StatelessWidget {
  const _LinkInputSection({
    required this.controller,
    required this.hasLink,
    required this.isExtracting,
    required this.strings,
    required this.onFetchPressed,
    required this.onPastePressed,
    required this.onClearPressed,
  });

  final TextEditingController controller;
  final bool hasLink;
  final bool isExtracting;
  final AppLocalizations strings;
  final VoidCallback onFetchPressed;
  final VoidCallback onPastePressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    final bool canFetch = hasLink && !isExtracting;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        TextField(
          controller: controller,
          enabled: !isExtracting,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => onFetchPressed(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: strings.linkFieldHint,
            prefixIcon: AnimatedContainer(
              duration: AppMotion.medium,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Icon(
                Icons.link_rounded,
                size: 20,
                color: hasLink
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: isExtracting
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                    child: hasLink
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 19),
                            onPressed: onClearPressed,
                            color: colorScheme.onSurfaceVariant,
                            tooltip: strings.linkFieldClear,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 19,
                            ),
                            onPressed: onPastePressed,
                            color: colorScheme.primary,
                            tooltip: strings.linkFieldPaste,
                          ),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: AppSpacing.lg + 2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FetchyPrimaryButton(
          label: strings.fetch,
          busyLabel: strings.fetching,
          busy: isExtracting,
          // The one control that carries the hook. Drawn in its own colour
          // when live; tinted only so it greys out with the rest of the
          // button when there is nothing to fetch.
          glyph: FetchyHookAsset(
            size: 22,
            color: canFetch
                ? null
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          onPressed: canFetch ? onFetchPressed : null,
        ),
      ],
    );
  }
}

class _RecentDownloadsSection extends StatelessWidget {
  const _RecentDownloadsSection({required this.historyService});

  final HistoryService historyService;

  /// Home shows only the newest few; the History tab is where the full list
  /// lives, so a long tail here just pushes everything else off the screen.
  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HistoryEntry>>(
      valueListenable: historyService.entries,
      builder: (BuildContext context, List<HistoryEntry> entries, _) {
        if (entries.isEmpty) {
          return const _EmptyDownloadsState();
        }

        final List<HistoryEntry> shown = entries.take(_maxShown).toList();

        return Column(
          children: <Widget>[
            for (final HistoryEntry entry in shown) ...<Widget>[
              HistoryListTile(
                entry: entry,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryDetailPage(entry: entry),
                  ),
                ),
              ),
              if (entry != shown.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyDownloadsState extends StatelessWidget {
  const _EmptyDownloadsState();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchyCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxl,
        horizontal: AppSpacing.xl,
      ),
      child: FetchyEmptyState(
        // Says what is missing — downloads — rather than showing the logo.
        icon: Icons.file_download_outlined,
        title: strings.noDownloadsYet,
        message: strings.noDownloadsDescription,
      ),
    );
  }
}

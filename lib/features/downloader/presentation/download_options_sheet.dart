import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/theme/app_dimens.dart';
import '../../../app/theme/fetchy_tokens.dart';
import '../../../app/widgets/fetchy_buttons.dart';
import '../../../app/widgets/fetchy_rows.dart';
import '../../../app/widgets/fetchy_selectors.dart';
import '../../../app/widgets/fetchy_sheet.dart';
import '../../../app/widgets/fetchy_surface.dart';
import '../../../core/platform/artwork_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../media/format_parser.dart';
import '../../media/media_info.dart';
import '../../media/media_selection_catalog.dart';
import '../../settings/presentation/widgets/settings_section.dart';
import '../download_options.dart';

/// What kind of output the user currently has selected in [MediaPreview] —
/// decides whether the sheet shows the Audio or the Video options group.
/// This is read from that existing selector, never a second one.
enum DownloadOptionsMediaMode { video, audio }

/// Opens Download Options for the current selection and returns whatever
/// the user set, or null if they dismissed it without saving. Basic fields
/// (audio title/artist/album; video filename) are fully functional here, as
/// is each mode's Advanced section — Format/Quality/FPS/Subtitles/Include
/// audio for Video, Format/Bitrate for Audio — all driven by
/// [catalog]/[mediaInfo]'s real engine data through the same drill-down
/// picker architecture, never hard-coded and never a second UI per mode.
Future<DownloadOptions?> showDownloadOptionsSheet(
  BuildContext context, {
  required DownloadOptionsMediaMode mode,
  required DownloadOptions initial,
  required MediaInfo mediaInfo,
  required MediaSelectionCatalog catalog,
}) {
  return showFetchySheet<DownloadOptions>(
    context,
    builder: (BuildContext context) => _DownloadOptionsSheet(
      mode: mode,
      initial: initial,
      mediaInfo: mediaInfo,
      catalog: catalog,
    ),
  );
}

/// The outcome of one Pull Info attempt, driving both the button's own
/// loading state and the in-sheet status banner.
enum _PullInfoStatus { idle, loading, success, partial, unavailable, error }

/// The outcome of one artwork pick/download attempt, driving the artwork
/// control's loading state and its own in-sheet status banner.
enum _ArtworkStatus { idle, loading, success, unavailable, error }

class _DownloadOptionsSheet extends StatefulWidget {
  const _DownloadOptionsSheet({
    required this.mode,
    required this.initial,
    required this.mediaInfo,
    required this.catalog,
  });

  final DownloadOptionsMediaMode mode;
  final DownloadOptions initial;
  final MediaInfo mediaInfo;
  final MediaSelectionCatalog catalog;

  @override
  State<_DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<_DownloadOptionsSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final TextEditingController _filenameController;

  _PullInfoStatus _pullInfoStatus = _PullInfoStatus.idle;
  String? _pullInfoMessage;
  Timer? _pullInfoAutoHideTimer;

  ArtworkKind _artworkKind = ArtworkKind.none;
  String? _artworkLocalPath;
  _ArtworkStatus _artworkStatus = _ArtworkStatus.idle;
  String? _artworkMessage;
  Timer? _artworkAutoHideTimer;

  /// Every local file this sheet instance has itself picked/downloaded —
  /// never the value it was opened with (`widget.initial.artwork`, which
  /// belongs to whoever set it and is never deleted from here). Used so
  /// Cancel/back and mid-session replacement can clean up exactly the
  /// files this session created and no longer needs, without ever risking
  /// deletion of a file still in use elsewhere.
  final Set<String> _ownedArtworkPaths = <String>{};
  bool _artworkSavedSuccessfully = false;

  /// Video mode Advanced state — see `_buildVideoAdvancedSection`. Null
  /// [_selectedAdvancedFormat] means "no override; use the ordinary
  /// quality selector," the same default as before this feature existed.
  bool _includeAudio = true;
  ResolutionOption? _selectedAdvancedFormat;
  SubtitleSelection? _selectedSubtitle;

  /// Audio mode Advanced state — see `_buildAudioAdvancedEntry`. Null
  /// means "no override; use the ordinary audio format selector," the
  /// same default pattern as Video's [_selectedAdvancedFormat].
  ParsedFormat? _selectedAdvancedAudioFormat;

  /// Drives the brief spinner on an Advanced sheet's Done button.
  ///
  /// Done used to close the sheet the instant it was pressed, which reads as
  /// the sheet having been dismissed rather than as the press having
  /// registered. Half a second of feedback first is enough to feel like a
  /// confirmation. Nothing is being waited on — the picks were already
  /// applied as they were made.
  bool _advancedDoneBusy = false;

  @override
  void initState() {
    super.initState();

    final ArtworkSelection? initialArtwork = widget.initial.artwork;
    if (initialArtwork != null && !initialArtwork.isEmpty) {
      _artworkKind = initialArtwork.kind;
      _artworkLocalPath = initialArtwork.localPath;
    }

    final VideoDownloadOptions? initialVideo = widget.initial.video;
    _includeAudio = initialVideo?.includeAudio ?? true;
    final AdvancedFormatSelection? initialAdvancedFormat = initialVideo?.advancedFormat;
    _selectedAdvancedFormat = initialAdvancedFormat == null
        ? null
        : widget.catalog.advancedEntryForFormatId(
            initialAdvancedFormat.formatId,
            includeAudio: _includeAudio,
          );
    _selectedSubtitle = initialVideo?.subtitle;

    final AdvancedFormatSelection? initialAdvancedAudioFormat =
        widget.initial.audio?.advancedFormat;
    _selectedAdvancedAudioFormat = initialAdvancedAudioFormat == null
        ? null
        : _findAudioFormat(initialAdvancedAudioFormat.formatId);
    // Only Title pre-fills automatically (from the plain source title —
    // never the music-specific "track" field). Artist and Album start
    // empty by default: the extractor may well have that data already,
    // but silently applying it would change the user's metadata without
    // them asking for it. Pull Info is the explicit, user-controlled way
    // to bring it in. `widget.initial` is different — it's what *this*
    // user already set in a previous visit to this sheet, so it always
    // wins over any default.
    _titleController = TextEditingController(
      text: widget.initial.audio?.title ?? widget.mediaInfo.title,
    );
    _artistController = TextEditingController(text: widget.initial.audio?.artist ?? '');
    _albumController = TextEditingController(text: widget.initial.audio?.album ?? '');
    _filenameController = TextEditingController(
      text: widget.initial.video?.filename ?? widget.mediaInfo.title,
    );
  }

  @override
  void dispose() {
    _pullInfoAutoHideTimer?.cancel();
    _artworkAutoHideTimer?.cancel();
    // Cancel/back without saving: discard every temp file this session
    // itself created. On a successful Save, the one surviving path (if
    // any) has already been handed off to the caller, so nothing here is
    // deleted in that case.
    if (!_artworkSavedSuccessfully) {
      for (final String path in _ownedArtworkPaths) {
        unawaited(ArtworkService.instance.deleteArtwork(path));
      }
    }
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  bool get _hasSourceThumbnail => (widget.mediaInfo.thumbnailUrl ?? '').isNotEmpty;

  /// Resolves one of the three artwork choices. [ArtworkKind.none] always
  /// succeeds immediately (nothing to fetch). [ArtworkKind.source]/
  /// [ArtworkKind.custom] each show a loading state for the duration of the
  /// download/pick, then either commit the new selection or restore the
  /// previous one with an in-sheet explanation — the control is never left
  /// looking like the tap did nothing.
  Future<void> _selectArtwork(ArtworkKind kind) async {
    if (kind == _artworkKind || _artworkLoading) return;
    _artworkAutoHideTimer?.cancel();

    if (kind == ArtworkKind.none) {
      _replaceArtworkPath(newPath: null, newKind: ArtworkKind.none);
      setState(() => _artworkStatus = _ArtworkStatus.idle);
      return;
    }

    if (kind == ArtworkKind.source && !_hasSourceThumbnail) {
      setState(() {
        _artworkStatus = _ArtworkStatus.unavailable;
        _artworkMessage = AppLocalizations.of(context).artworkNoSourceThumbnail;
      });
      _scheduleArtworkAutoHide();
      return;
    }

    setState(() {
      _artworkStatus = _ArtworkStatus.loading;
      _artworkMessage = null;
    });

    final ArtworkPickResult result = kind == ArtworkKind.source
        ? await ArtworkService.instance.downloadSourceThumbnail(widget.mediaInfo.thumbnailUrl!)
        : await ArtworkService.instance.pickCustomImage();

    if (!mounted) return;

    if (!result.isSuccess) {
      if (result.isCancelled) {
        // The user closed the picker without choosing anything — not an
        // error, just back to whatever was selected before.
        setState(() => _artworkStatus = _ArtworkStatus.idle);
        return;
      }
      setState(() {
        _artworkStatus = _ArtworkStatus.error;
        _artworkMessage = result.error ?? AppLocalizations.of(context).artworkCouldNotUseImage;
      });
      _scheduleArtworkAutoHide();
      return;
    }

    _replaceArtworkPath(newPath: result.path, newKind: kind);
    setState(() {
      _artworkStatus = _ArtworkStatus.success;
      _artworkMessage = kind == ArtworkKind.source
          ? AppLocalizations.of(context).artworkSourceSelectedMessage
          : AppLocalizations.of(context).artworkImageSelectedMessage;
    });
    _scheduleArtworkAutoHide();
  }

  /// Swaps in [newPath]/[newKind], deleting the previous path only when
  /// this session itself owns it (see [_ownedArtworkPaths]) — the value
  /// the sheet was opened with is never touched here.
  void _replaceArtworkPath({required String? newPath, required ArtworkKind newKind}) {
    final String? oldPath = _artworkLocalPath;
    setState(() {
      _artworkKind = newKind;
      _artworkLocalPath = newPath;
    });
    if (newPath != null) _ownedArtworkPaths.add(newPath);
    if (oldPath != null && oldPath != newPath && _ownedArtworkPaths.remove(oldPath)) {
      unawaited(ArtworkService.instance.deleteArtwork(oldPath));
    }
  }

  void _scheduleArtworkAutoHide() {
    _artworkAutoHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _artworkStatus = _ArtworkStatus.idle);
    });
  }

  bool get _artworkLoading => _artworkStatus == _ArtworkStatus.loading;

  /// Only sends a value when it differs from the pre-filled source
  /// default — leaving a field exactly as pre-filled means "use the
  /// source," not "explicitly re-apply the same text."
  String? _changedOrNull(String value, String sourceDefault) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == sourceDefault.trim()) return null;
    return trimmed;
  }

  String? _filledOrNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _nonEmptyOrNull(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Purely local: everything it reads was already returned by the one
  /// extraction that produced [widget.mediaInfo] — see RawMediaInfoParser
  /// on the native side. Never triggers a second engine request. Only
  /// fills a field when the source genuinely provided a value for it;
  /// fields with nothing available are left exactly as they were, never
  /// cleared. The brief delay before showing a result is deliberate: this
  /// is a local, effectively-instant read, but a result appearing with no
  /// perceivable loading state at all reads as "did my tap even work?" —
  /// see item 4 of the Download Options UX pass.
  Future<void> _pullInfo() async {
    _pullInfoAutoHideTimer?.cancel();
    setState(() {
      _pullInfoStatus = _PullInfoStatus.loading;
      _pullInfoMessage = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      final MediaInfo info = widget.mediaInfo;
      final String? pulledTrack = _nonEmptyOrNull(info.track);
      final String? pulledArtist = _nonEmptyOrNull(info.artist);
      final String? pulledAlbum = _nonEmptyOrNull(info.album);
      final int foundCount = <String?>[
        pulledTrack,
        pulledArtist,
        pulledAlbum,
      ].whereType<String>().length;

      final AppLocalizations strings = AppLocalizations.of(context);
      setState(() {
        if (pulledTrack != null) _titleController.text = pulledTrack;
        if (pulledArtist != null) _artistController.text = pulledArtist;
        if (pulledAlbum != null) _albumController.text = pulledAlbum;

        if (foundCount == 0) {
          _pullInfoStatus = _PullInfoStatus.unavailable;
          _pullInfoMessage = strings.pullInfoNoUsableMetadata;
        } else if (foundCount < 3) {
          _pullInfoStatus = _PullInfoStatus.partial;
          _pullInfoMessage = strings.pullInfoPartial;
        } else {
          _pullInfoStatus = _PullInfoStatus.success;
          _pullInfoMessage = strings.pullInfoFilledIn;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pullInfoStatus = _PullInfoStatus.error;
        _pullInfoMessage = AppLocalizations.of(context).pullInfoReadError;
      });
    }

    _pullInfoAutoHideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _pullInfoStatus = _PullInfoStatus.idle);
    });
  }

  /// Acknowledges the press, then closes the Advanced sheet.
  Future<void> _confirmAdvanced(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    if (_advancedDoneBusy) return;
    setSheetState(() => _advancedDoneBusy = true);

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Reset directly rather than through setSheetState: the sheet is about
    // to go, and the flag has to be clean for the next time it opens.
    _advancedDoneBusy = false;
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
  }

  void _save() {
    final ArtworkSelection artwork = (_artworkKind != ArtworkKind.none && _artworkLocalPath != null)
        ? ArtworkSelection(kind: _artworkKind, localPath: _artworkLocalPath)
        : ArtworkSelection.none;
    // The chosen path (if any) is now owned by the returned DownloadOptions
    // — dispose() must not delete it once this sheet closes.
    _artworkSavedSuccessfully = true;

    final DownloadOptions result = widget.mode == DownloadOptionsMediaMode.audio
        ? DownloadOptions(
            audio: AudioDownloadOptions(
              title: _changedOrNull(_titleController.text, widget.mediaInfo.title),
              artist: _filledOrNull(_artistController.text),
              album: _filledOrNull(_albumController.text),
              advancedFormat: _selectedAdvancedAudioFormat?.formatId == null
                  ? null
                  : AdvancedFormatSelection(
                      formatId: _selectedAdvancedAudioFormat!.formatId!,
                    ),
            ),
            artwork: artwork,
          )
        : DownloadOptions(
            video: VideoDownloadOptions(
              filename: _changedOrNull(_filenameController.text, widget.mediaInfo.title),
              includeAudio: _includeAudio,
              advancedFormat: _selectedAdvancedFormat?.candidate.primary.formatId == null
                  ? null
                  : AdvancedFormatSelection(
                      formatId: _selectedAdvancedFormat!.candidate.primary.formatId!,
                    ),
              subtitle: _selectedSubtitle,
            ),
            artwork: artwork,
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool isAudio = widget.mode == DownloadOptionsMediaMode.audio;

    // The keyboard is handled once for the whole sheet by [FetchySheet]:
    // the header, fields, and Save/Cancel row all live inside one
    // scrollable, so opening the keyboard just shrinks how much of that
    // scrollable is visible rather than shifting any single field.
    return FetchySheet(
      title: strings.downloadOptionsTitle,
      subtitle: isAudio
          ? strings.downloadOptionsAudioSubtitle
          : strings.downloadOptionsVideoSubtitle,
      footer: Row(
        children: <Widget>[
          Expanded(
            child: FetchyTonalButton(
              label: strings.commonCancel,
              height: 52,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FetchyPrimaryButton(
              label: strings.commonSave,
              icon: Icons.check_rounded,
              height: 52,
              onPressed: _save,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isAudio)
            _buildAudioFields(theme, strings)
          else
            _buildVideoFields(theme, strings),
          const SizedBox(height: AppSpacing.xl),
          _buildAdvancedSection(context, strings),
        ],
      ),
    );
  }

  Widget _buildAudioFields(ThemeData theme, AppLocalizations strings) {
    final bool isPulling = _pullInfoStatus == _PullInfoStatus.loading;

    return SettingsSection(
      title: strings.audioGroupTitle,
      icon: Icons.audiotrack_outlined,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FetchyTonalButton(
              label: strings.pullInfo,
              icon: Icons.auto_awesome_rounded,
              expand: false,
              height: 42,
              emphasis: true,
              busy: isPulling,
              onPressed: isPulling ? null : _pullInfo,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: strings.songTitleLabel),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: TextField(
            controller: _artistController,
            decoration: InputDecoration(
              labelText: strings.artistLabel,
              hintText: strings.commonNotSet,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _albumController,
            decoration: InputDecoration(
              labelText: strings.albumLabel,
              hintText: strings.commonNotSet,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildArtworkControl(theme, strings),
        _buildArtworkBanner(theme),
        _buildPullInfoBanner(theme),
      ],
    );
  }

  /// Shared by both Audio and Video modes — the choice and its embedding
  /// target differ (cover art vs. attached thumbnail), but the control
  /// itself is identical: None / Source / Custom, a preview once something
  /// is selected, and the same loading/result banner language used
  /// elsewhere in this sheet.
  Widget _buildArtworkControl(ThemeData theme, AppLocalizations strings) {
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isAudio = widget.mode == DownloadOptionsMediaMode.audio;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                isAudio ? strings.summaryLabelArtwork : strings.thumbnailLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_artworkLoading) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FetchySegmented<ArtworkKind>(
            selected: _artworkKind,
            onChanged: _artworkLoading ? null : _selectArtwork,
            dense: true,
            segments: <FetchySegment<ArtworkKind>>[
              FetchySegment<ArtworkKind>(
                value: ArtworkKind.none,
                label: strings.artworkNone,
              ),
              FetchySegment<ArtworkKind>(
                value: ArtworkKind.source,
                label: strings.artworkSource,
              ),
              FetchySegment<ArtworkKind>(
                value: ArtworkKind.custom,
                label: strings.artworkCustom,
              ),
            ],
          ),
          if (_artworkLocalPath != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            FetchySurface(
              tone: FetchyTone.sunken,
              borderRadius: AppShape.control,
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: AppShape.chip,
                    child: Image.file(
                      File(_artworkLocalPath!),
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 42,
                        height: 42,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _artworkKind == ArtworkKind.source
                          ? strings.artworkSourceSelected
                          : strings.artworkCustomSelected,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FetchyIconButton(
                    icon: Icons.close_rounded,
                    tooltip: strings.artworkRemoveTooltip,
                    size: 32,
                    iconSize: 16,
                    onPressed: _artworkLoading
                        ? null
                        : () => _selectArtwork(ArtworkKind.none),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPullInfoBanner(ThemeData theme) {
    final bool visible =
        _pullInfoStatus != _PullInfoStatus.idle && _pullInfoStatus != _PullInfoStatus.loading;

    final FetchyBannerTone tone = switch (_pullInfoStatus) {
      _PullInfoStatus.success => FetchyBannerTone.success,
      _PullInfoStatus.partial => FetchyBannerTone.info,
      _PullInfoStatus.error => FetchyBannerTone.error,
      _PullInfoStatus.unavailable ||
      _PullInfoStatus.idle ||
      _PullInfoStatus.loading => FetchyBannerTone.neutral,
    };

    return _buildStatusBanner(
      keyPrefix: 'pull-info',
      statusKey: _pullInfoStatus.name,
      visible: visible,
      tone: tone,
      message: _pullInfoMessage ?? '',
    );
  }

  Widget _buildArtworkBanner(ThemeData theme) {
    final bool visible =
        _artworkStatus != _ArtworkStatus.idle && _artworkStatus != _ArtworkStatus.loading;

    final FetchyBannerTone tone = switch (_artworkStatus) {
      _ArtworkStatus.success => FetchyBannerTone.success,
      _ArtworkStatus.error => FetchyBannerTone.error,
      _ArtworkStatus.unavailable ||
      _ArtworkStatus.idle ||
      _ArtworkStatus.loading => FetchyBannerTone.neutral,
    };

    return _buildStatusBanner(
      keyPrefix: 'artwork-status',
      statusKey: _artworkStatus.name,
      visible: visible,
      tone: tone,
      message: _artworkMessage ?? '',
    );
  }

  /// Transient, in-sheet only — never a SnackBar, which would render on
  /// the page's own Scaffold behind this sheet and read as if the sheet
  /// itself had closed or the message belonged to the wrong screen. Shared
  /// by Pull Info and the artwork control so both read as the same visual
  /// language.
  Widget _buildStatusBanner({
    required String keyPrefix,
    required String statusKey,
    required bool visible,
    required FetchyBannerTone tone,
    required String message,
  }) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      child: !visible
          ? SizedBox(width: double.infinity, key: ValueKey<String>('$keyPrefix-empty'))
          : Padding(
              key: ValueKey<String>('$keyPrefix-$statusKey'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: FetchyBanner(message: message, tone: tone),
            ),
    );
  }

  Widget _buildVideoFields(ThemeData theme, AppLocalizations strings) {
    return SettingsSection(
      title: strings.videoGroupTitle,
      icon: Icons.movie_outlined,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: TextField(
            controller: _filenameController,
            decoration: InputDecoration(labelText: strings.filenameLabel),
          ),
        ),
        const Divider(height: 1),
        _buildArtworkControl(theme, strings),
        _buildArtworkBanner(theme),
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context, AppLocalizations strings) {
    final ThemeData theme = Theme.of(context);
    return widget.mode == DownloadOptionsMediaMode.video
        ? _buildVideoAdvancedEntry(theme, strings)
        : _buildAudioAdvancedEntry(theme, strings);
  }

  /// The real, currently-selectable format pool: every combined format
  /// plus every video-only format paired with the best audio track when
  /// audio is included, or video-only formats alone when it is not — see
  /// `MediaSelectionCatalog.advancedVideoEntries`/`advancedVideoOnlyEntries`.
  List<ResolutionOption> get _advancedFormatPool => _includeAudio
      ? widget.catalog.advancedVideoEntries
      : widget.catalog.advancedVideoOnlyEntries;

  String? get _selectedExtension =>
      _selectedAdvancedFormat?.candidate.primary.extension?.toUpperCase();

  /// Every distinct container in [_advancedFormatPool] — the top of the
  /// Format → Quality → FPS hierarchy, so this is never filtered by
  /// whatever Quality/FPS happen to be selected already.
  List<String> get _availableFormatExtensions {
    final Set<String> extensions = <String>{};
    for (final ResolutionOption option in _advancedFormatPool) {
      final String? ext = option.candidate.primary.extension?.toUpperCase();
      if (ext != null && ext.isNotEmpty) extensions.add(ext);
    }
    final List<String> list = extensions.toList()..sort();
    return list;
  }

  /// Distinct real heights available, narrowed to the currently selected
  /// Format when one is set — so a format that genuinely has no 4K never
  /// offers 4K as a choice.
  List<int> get _availableQualityHeights {
    final String? extension = _selectedExtension;
    final Set<int> heights = <int>{};
    for (final ResolutionOption option in _advancedFormatPool) {
      if (extension != null &&
          (option.candidate.primary.extension ?? '').toUpperCase() != extension) {
        continue;
      }
      // The Advanced pools only ever contain options built from a real
      // positive height, but the field is nullable now, so this stays
      // defensive rather than asserting.
      final int? height = option.height;
      if (height != null) heights.add(height);
    }
    final List<int> list = heights.toList()..sort((int a, int b) => b.compareTo(a));
    return list;
  }

  /// Distinct real fps values available, narrowed to the currently
  /// selected Format and Quality — an empty list means fps genuinely isn't
  /// meaningful for this format/quality, never that it was omitted.
  List<double> get _availableFpsValues {
    final String? extension = _selectedExtension;
    final int? height = _selectedAdvancedFormat?.height;
    final Set<double> values = <double>{};
    for (final ResolutionOption option in _advancedFormatPool) {
      if (extension != null &&
          (option.candidate.primary.extension ?? '').toUpperCase() != extension) {
        continue;
      }
      if (height != null && option.height != height) continue;
      final double? fps = option.fps;
      if (fps != null && fps > 0) values.add(fps);
    }
    final List<double> list = values.toList()..sort((double a, double b) => b.compareTo(a));
    return list;
  }

  /// Resolves the one real [ResolutionOption] that matches as many of the
  /// given preferences as [pool] actually supports — the single function
  /// every Format/Quality/FPS/Include-audio change goes through, so there
  /// is exactly one source of truth for "what will actually be
  /// downloaded." Preferences are applied outer-to-inner (extension, then
  /// height, then fps); whenever a preference has zero matches, it is
  /// dropped rather than emptying the whole result — this is what lets a
  /// still-valid Quality/FPS survive a Format change, and what falls back
  /// to the best real match when it does not.
  ResolutionOption? _resolveBestMatch(
    List<ResolutionOption> pool, {
    String? preferExtension,
    int? preferHeight,
    double? preferFps,
  }) {
    Iterable<ResolutionOption> candidates = pool;

    if (preferExtension != null) {
      final List<ResolutionOption> filtered = candidates
          .where(
            (ResolutionOption o) =>
                (o.candidate.primary.extension ?? '').toUpperCase() == preferExtension,
          )
          .toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }
    if (preferHeight != null) {
      final List<ResolutionOption> filtered =
          candidates.where((ResolutionOption o) => o.height == preferHeight).toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }
    if (preferFps != null) {
      final List<ResolutionOption> filtered =
          candidates.where((ResolutionOption o) => o.fps == preferFps).toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }

    final List<ResolutionOption> list = candidates.toList();
    if (list.isEmpty) return null;
    list.sort(_compareBestFirst);
    return list.first;
  }

  /// Deterministic tie-break for [_resolveBestMatch]: higher resolution,
  /// then higher fps, then larger (higher-bitrate) file first.
  int _compareBestFirst(ResolutionOption a, ResolutionOption b) {
    // Coalesced the same way FormatSelector ranks video quality, so an
    // option with no reported height sorts last instead of throwing.
    final int heightCompare = (b.height ?? -1).compareTo(a.height ?? -1);
    if (heightCompare != 0) return heightCompare;
    final double aFps = a.fps ?? -1;
    final double bFps = b.fps ?? -1;
    final int fpsCompare = bFps.compareTo(aFps);
    if (fpsCompare != 0) return fpsCompare;
    final int aSize = a.candidate.primary.filesize ?? -1;
    final int bSize = b.candidate.primary.filesize ?? -1;
    return bSize.compareTo(aSize);
  }

  String get _fpsRowValue {
    final double? fps = _selectedAdvancedFormat?.fps;
    if (fps != null && fps > 0) return '${fps.round()} fps';
    final AppLocalizations strings = AppLocalizations.of(context);
    return _availableFpsValues.isEmpty ? strings.fpsNotAvailable : strings.commonAutomatic;
  }

  bool get _hasAnySubtitles =>
      widget.mediaInfo.subtitles.isNotEmpty || widget.mediaInfo.automaticCaptions.isNotEmpty;

  String _subtitleDisplayName(SubtitleSelection subtitle) {
    final List<MediaSubtitleTrack> tracks = subtitle.kind == SubtitleTrackKind.automatic
        ? widget.mediaInfo.automaticCaptions
        : widget.mediaInfo.subtitles;
    for (final MediaSubtitleTrack track in tracks) {
      if (track.language == subtitle.language) {
        final String? name = track.name?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return subtitle.language;
  }

  /// The collapsed entry point into Advanced — tapping it is the only way
  /// to reach Format/Quality/FPS/Subtitles/Include audio, so none of that
  /// is ever dumped directly into the main sheet body.
  Widget _buildVideoAdvancedEntry(ThemeData theme, AppLocalizations strings) {
    final List<String> active = <String>[];
    if (_selectedAdvancedFormat != null) active.add(strings.activeTagFormatQuality);
    if (!_includeAudio) active.add(strings.noAudioTag);
    if (_selectedSubtitle != null) active.add(strings.subtitlesTag);
    final String subtitle = active.isEmpty ? strings.commonDefaultSettings : active.join(' • ');
    final bool hasOverrides = active.isNotEmpty;

    return _AdvancedEntryRow(
      title: strings.advancedOptions,
      subtitle: subtitle,
      active: hasOverrides,
      onTap: _openAdvancedSheet,
    );
  }

  /// Opens the Advanced surface. Its own rows live in a [StatefulBuilder]
  /// so picking Format/Quality/FPS/Subtitles/Include-audio redraws it
  /// immediately without needing the main sheet underneath to rebuild —
  /// the one refresh after this returns is what updates the main sheet's
  /// "Advanced options" summary and, once Saved, the final preview in
  /// MediaPreview.
  Future<void> _openAdvancedSheet() async {
    await showFetchySheet<void>(
      context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return _buildAdvancedSheetBody(context, setSheetState);
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _buildAdvancedSheetBody(BuildContext context, StateSetter setSheetState) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return FetchySheet(
      title: strings.advancedOptions,
      titleTrailing: _selectedAdvancedFormat == null
          ? null
          : TextButton(
              onPressed: () => setSheetState(() => _selectedAdvancedFormat = null),
              child: Text(strings.useAutomatic),
            ),
      footer: FetchyPrimaryButton(
        label: strings.commonDone,
        icon: Icons.check_rounded,
        height: 52,
        busy: _advancedDoneBusy,
        onPressed: () => _confirmAdvanced(context, setSheetState),
      ),
      // Format/Quality/FPS are one decision made in three steps, so they
      // share a group; Subtitles and Include audio are independent of it
      // and of each other, so each gets its own. Grouping does the work
      // that a stack of outlined rows used to do with borders.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FetchySurface(
            tone: FetchyTone.sunken,
            elevated: false,
            borderRadius: AppShape.group,
            child: Column(
              children: <Widget>[
                _buildAdvancedRow(
                  label: strings.formatLabel,
                  value: _selectedAdvancedFormat == null
                      ? strings.commonAutomatic
                      : _selectedExtension!,
                  selected: _selectedAdvancedFormat != null,
                  onTap: _availableFormatExtensions.isEmpty
                      ? null
                      : () => _openFormatPicker(setSheetState),
                ),
                _buildAdvancedRow(
                  label: strings.qualityPickerLabel,
                  value: _selectedAdvancedFormat == null
                      ? strings.commonAutomatic
                      : _selectedAdvancedFormat!.standardLabel ??
                            strings.qualityUnavailable,
                  selected: _selectedAdvancedFormat != null,
                  onTap: _availableQualityHeights.isEmpty
                      ? null
                      : () => _openQualityPicker(setSheetState),
                ),
                _buildAdvancedRow(
                  label: strings.summaryLabelFps,
                  value: _fpsRowValue,
                  selected: (_selectedAdvancedFormat?.fps ?? 0) > 0,
                  onTap: _availableFpsValues.isEmpty
                      ? null
                      : () => _openFpsPicker(setSheetState),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FetchySurface(
            tone: FetchyTone.sunken,
            elevated: false,
            borderRadius: AppShape.group,
            child: _buildAdvancedRow(
              label: strings.subtitlesLabel,
              value: _selectedSubtitle == null
                  ? strings.subtitlesOff
                  : _subtitleDisplayName(_selectedSubtitle!),
              selected: _selectedSubtitle != null,
              onTap: _hasAnySubtitles ? () => _openSubtitlePicker(setSheetState) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FetchySurface(
            tone: FetchyTone.sunken,
            elevated: false,
            borderRadius: AppShape.group,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _buildIncludeAudioRow(theme, setSheetState, strings),
          ),
        ],
      ),
    );
  }

  /// One tappable Advanced row. A null [onTap] renders the row visibly
  /// disabled — the honest "this genuinely has nothing to pick" state
  /// (e.g. FPS with no reported values) rather than a dead-looking control
  /// with no explanation.
  Widget _buildAdvancedRow({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return FetchySelectorRow(
      label: label,
      value: value,
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _buildIncludeAudioRow(
    ThemeData theme,
    StateSetter setSheetState,
    AppLocalizations strings,
  ) {
    final ColorScheme colorScheme = theme.colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.includeAudioLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _includeAudio
                    ? strings.includeAudioOnDescription
                    : strings.includeAudioOffDescription,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch(
          value: _includeAudio,
          onChanged: (bool value) {
            setSheetState(() {
              _includeAudio = value;
              // The pool a pick came from just changed (combined+video-only
              // vs. video-only-alone). Try to keep the same
              // format/quality/fps if the new pool still has it; fall back
              // to the closest real match otherwise — never left pointing
              // at a combination that no longer exists in the new pool.
              final ResolutionOption? current = _selectedAdvancedFormat;
              _selectedAdvancedFormat = current == null
                  ? null
                  : _resolveBestMatch(
                      _advancedFormatPool,
                      preferExtension: current.candidate.primary.extension?.toUpperCase(),
                      preferHeight: current.height,
                      preferFps: current.fps,
                    );
            });
          },
        ),
      ],
    );
  }

  Future<void> _openFormatPicker(StateSetter setSheetState) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<String> extensions = _availableFormatExtensions;
    final _PickerSelection<String>? result = await showFetchySheet<_PickerSelection<String>>(
      context,
      builder: (BuildContext context) => _ChoicePickerSheet<String>(
        title: strings.formatLabel,
        currentValue: _selectedExtension,
        items: extensions
            .map((String ext) => _ChoiceItem<String>(value: ext, label: ext))
            .toList(growable: false),
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedAdvancedFormat = _resolveBestMatch(
        _advancedFormatPool,
        preferExtension: result.value,
        preferHeight: _selectedAdvancedFormat?.height,
        preferFps: _selectedAdvancedFormat?.fps,
      );
    });
  }

  Future<void> _openQualityPicker(StateSetter setSheetState) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<int> heights = _availableQualityHeights;
    final String? currentExtension = _selectedExtension;
    final _PickerSelection<int>? result = await showFetchySheet<_PickerSelection<int>>(
      context,
      builder: (BuildContext context) => _ChoicePickerSheet<int>(
        title: strings.qualityPickerLabel,
        currentValue: _selectedAdvancedFormat?.height,
        items: heights
            .map(
              (int height) => _ChoiceItem<int>(
                value: height,
                label: MediaSelectionCatalog.standardLabelForHeight(height),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedAdvancedFormat = _resolveBestMatch(
        _advancedFormatPool,
        preferExtension: currentExtension,
        preferHeight: result.value,
        preferFps: _selectedAdvancedFormat?.fps,
      );
    });
  }

  Future<void> _openFpsPicker(StateSetter setSheetState) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<double> values = _availableFpsValues;
    final String? currentExtension = _selectedExtension;
    final int? currentHeight = _selectedAdvancedFormat?.height;
    final _PickerSelection<double>? result = await showFetchySheet<_PickerSelection<double>>(
      context,
      builder: (BuildContext context) => _ChoicePickerSheet<double>(
        title: strings.summaryLabelFps,
        currentValue: _selectedAdvancedFormat?.fps,
        showAutomatic: true,
        items: values
            .map((double fps) => _ChoiceItem<double>(value: fps, label: '${fps.round()} fps'))
            .toList(growable: false),
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedAdvancedFormat = _resolveBestMatch(
        _advancedFormatPool,
        preferExtension: currentExtension,
        preferHeight: currentHeight,
        preferFps: result.isAutomatic ? null : result.value,
      );
    });
  }

  Future<void> _openSubtitlePicker(StateSetter setSheetState) async {
    final _SubtitlePick? result = await showFetchySheet<_SubtitlePick>(
      context,
      builder: (BuildContext context) => _SubtitlePickerSheet(
        regularTracks: widget.mediaInfo.subtitles,
        autoTracks: widget.mediaInfo.automaticCaptions,
        currentSelection: _selectedSubtitle,
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedSubtitle = result.isOff ? null : result.selection;
    });
  }

  // --------------------------------------------------------- Audio Advanced

  ParsedFormat? _findAudioFormat(String formatId) {
    for (final ParsedFormat format in widget.catalog.advancedAudioFormats) {
      if (format.formatId == formatId) return format;
    }
    return null;
  }

  /// Every distinct real audio format label (see
  /// `MediaSelectionCatalog.audioLabelFor`) available for this media — the
  /// Format dimension, unfiltered since it is the top of the Format →
  /// Bitrate hierarchy, mirroring Video's Format → Quality → FPS.
  List<String> get _availableAudioLabels {
    final Set<String> labels = <String>{};
    for (final ParsedFormat format in widget.catalog.advancedAudioFormats) {
      labels.add(MediaSelectionCatalog.audioLabelFor(format));
    }
    final List<String> list = labels.toList()..sort();
    return list;
  }

  /// Distinct real bitrates (`abr`, falling back to `tbr`), narrowed to the
  /// currently selected Format when one is set.
  List<double> get _availableAudioBitrates {
    final String? label = _selectedAdvancedAudioFormat == null
        ? null
        : MediaSelectionCatalog.audioLabelFor(_selectedAdvancedAudioFormat!);
    final Set<double> bitrates = <double>{};
    for (final ParsedFormat format in widget.catalog.advancedAudioFormats) {
      if (label != null && MediaSelectionCatalog.audioLabelFor(format) != label) continue;
      final double? bitrate = format.audioBitrate ?? format.totalBitrate;
      if (bitrate != null && bitrate > 0) bitrates.add(bitrate);
    }
    final List<double> list = bitrates.toList()..sort((double a, double b) => b.compareTo(a));
    return list;
  }

  /// True only when this media genuinely offers more than one real bitrate
  /// to choose between — Quality and Bitrate would be the same underlying
  /// selection here, so per the explicit instruction not to duplicate them,
  /// only Bitrate is shown, and only when it is a meaningful choice at all.
  bool get _audioHasMeaningfulBitrateChoice {
    final Set<double> allBitrates = <double>{};
    for (final ParsedFormat format in widget.catalog.advancedAudioFormats) {
      final double? bitrate = format.audioBitrate ?? format.totalBitrate;
      if (bitrate != null && bitrate > 0) allBitrates.add(bitrate);
    }
    return allBitrates.length > 1;
  }

  /// Mirrors [_resolveBestMatch] for the audio dimensions (label, bitrate)
  /// instead of (extension, height, fps) — same outer-to-inner preference
  /// logic, same fallback-to-best-real-match behavior, so Format/Bitrate
  /// picks and the underlying pool switch (there is only one audio pool,
  /// unlike Video's Include-audio-gated pair) never land on a combination
  /// this media doesn't actually have.
  ParsedFormat? _resolveBestAudioMatch(
    List<ParsedFormat> pool, {
    String? preferLabel,
    double? preferBitrate,
  }) {
    Iterable<ParsedFormat> candidates = pool;

    if (preferLabel != null) {
      final List<ParsedFormat> filtered = candidates
          .where((ParsedFormat f) => MediaSelectionCatalog.audioLabelFor(f) == preferLabel)
          .toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }
    if (preferBitrate != null) {
      final List<ParsedFormat> filtered = candidates
          .where((ParsedFormat f) => (f.audioBitrate ?? f.totalBitrate) == preferBitrate)
          .toList();
      if (filtered.isNotEmpty) candidates = filtered;
    }

    final List<ParsedFormat> list = candidates.toList();
    if (list.isEmpty) return null;
    list.sort(_compareBestAudioFirst);
    return list.first;
  }

  /// Deterministic tie-break for [_resolveBestAudioMatch]: higher bitrate,
  /// then larger file, first.
  int _compareBestAudioFirst(ParsedFormat a, ParsedFormat b) {
    final double aBitrate = a.audioBitrate ?? a.totalBitrate ?? -1;
    final double bBitrate = b.audioBitrate ?? b.totalBitrate ?? -1;
    final int bitrateCompare = bBitrate.compareTo(aBitrate);
    if (bitrateCompare != 0) return bitrateCompare;
    final int aSize = a.filesize ?? -1;
    final int bSize = b.filesize ?? -1;
    return bSize.compareTo(aSize);
  }

  String get _audioBitrateRowValue {
    final double? bitrate =
        _selectedAdvancedAudioFormat?.audioBitrate ?? _selectedAdvancedAudioFormat?.totalBitrate;
    final AppLocalizations strings = AppLocalizations.of(context);
    return (bitrate != null && bitrate > 0)
        ? strings.bitrateKbps(bitrate.round())
        : strings.bitrateBest;
  }

  /// The collapsed entry point into Audio Advanced — same pattern as
  /// [_buildVideoAdvancedEntry]: nothing is dumped into the main sheet
  /// body, tapping is the only way to reach Format/Bitrate.
  Widget _buildAudioAdvancedEntry(ThemeData theme, AppLocalizations strings) {
    final bool hasOverride = _selectedAdvancedAudioFormat != null;
    final String subtitle = hasOverride
        ? strings.activeTagFormatBitrate
        : strings.commonDefaultSettings;

    return _AdvancedEntryRow(
      title: strings.advancedOptions,
      subtitle: subtitle,
      active: hasOverride,
      onTap: _openAudioAdvancedSheet,
    );
  }

  Future<void> _openAudioAdvancedSheet() async {
    await showFetchySheet<void>(
      context,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return _buildAudioAdvancedSheetBody(context, setSheetState);
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _buildAudioAdvancedSheetBody(BuildContext context, StateSetter setSheetState) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool hasFormatChoice = _availableAudioLabels.length > 1;
    final bool hasBitrateChoice = _audioHasMeaningfulBitrateChoice;

    return FetchySheet(
      title: strings.advancedOptions,
      titleTrailing: _selectedAdvancedAudioFormat == null
          ? null
          : TextButton(
              onPressed: () =>
                  setSheetState(() => _selectedAdvancedAudioFormat = null),
              child: Text(strings.useAutomatic),
            ),
      footer: FetchyPrimaryButton(
        label: strings.commonDone,
        icon: Icons.check_rounded,
        height: 52,
        busy: _advancedDoneBusy,
        onPressed: () => _confirmAdvanced(context, setSheetState),
      ),
      child: FetchySurface(
        tone: FetchyTone.sunken,
        elevated: false,
        borderRadius: AppShape.group,
        child: Column(
          children: <Widget>[
            _buildAdvancedRow(
              label: strings.formatLabel,
              value: _selectedAdvancedAudioFormat == null
                  ? strings.commonAutomatic
                  : MediaSelectionCatalog.audioLabelFor(_selectedAdvancedAudioFormat!),
              selected: _selectedAdvancedAudioFormat != null,
              onTap: hasFormatChoice ? () => _openAudioFormatPicker(setSheetState) : null,
            ),
            if (hasBitrateChoice)
              _buildAdvancedRow(
                label: strings.bitrateLabel,
                value: _audioBitrateRowValue,
                selected:
                    (_selectedAdvancedAudioFormat?.audioBitrate ??
                            _selectedAdvancedAudioFormat?.totalBitrate ??
                            0) >
                        0,
                onTap: () => _openAudioBitratePicker(setSheetState),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAudioFormatPicker(StateSetter setSheetState) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<String> labels = _availableAudioLabels;
    final String? current = _selectedAdvancedAudioFormat == null
        ? null
        : MediaSelectionCatalog.audioLabelFor(_selectedAdvancedAudioFormat!);
    final _PickerSelection<String>? result = await showFetchySheet<_PickerSelection<String>>(
      context,
      builder: (BuildContext context) => _ChoicePickerSheet<String>(
        title: strings.formatLabel,
        currentValue: current,
        items: labels
            .map((String label) => _ChoiceItem<String>(value: label, label: label))
            .toList(growable: false),
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedAdvancedAudioFormat = _resolveBestAudioMatch(
        widget.catalog.advancedAudioFormats,
        preferLabel: result.value,
        preferBitrate:
            _selectedAdvancedAudioFormat?.audioBitrate ?? _selectedAdvancedAudioFormat?.totalBitrate,
      );
    });
  }

  Future<void> _openAudioBitratePicker(StateSetter setSheetState) async {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<double> bitrates = _availableAudioBitrates;
    final String? currentLabel = _selectedAdvancedAudioFormat == null
        ? null
        : MediaSelectionCatalog.audioLabelFor(_selectedAdvancedAudioFormat!);
    final double? currentBitrate =
        _selectedAdvancedAudioFormat?.audioBitrate ?? _selectedAdvancedAudioFormat?.totalBitrate;
    final _PickerSelection<double>? result = await showFetchySheet<_PickerSelection<double>>(
      context,
      builder: (BuildContext context) => _ChoicePickerSheet<double>(
        title: strings.bitrateLabel,
        currentValue: currentBitrate,
        showAutomatic: true,
        items: bitrates
            .map(
              (double bitrate) =>
                  _ChoiceItem<double>(value: bitrate, label: '${bitrate.round()} kbps'),
            )
            .toList(growable: false),
      ),
    );
    if (result == null) return;

    setSheetState(() {
      _selectedAdvancedAudioFormat = _resolveBestAudioMatch(
        widget.catalog.advancedAudioFormats,
        preferLabel: currentLabel,
        preferBitrate: result.isAutomatic ? null : result.value,
      );
    });
  }
}

/// A single leaf-picker's result: either the user tapped a real [value],
/// tapped "Automatic" ([isAutomatic]), or dismissed the sheet without
/// choosing anything (the whole object is null in that case) — three
/// distinct outcomes that a bare nullable return value could not tell
/// apart.
class _PickerSelection<T> {
  const _PickerSelection.value(T this.value) : isAutomatic = false;
  const _PickerSelection.automatic() : value = null, isAutomatic = true;

  final T? value;
  final bool isAutomatic;
}

class _ChoiceItem<T> {
  const _ChoiceItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A plain single-select list sheet shared by the Format, Quality, and FPS
/// pickers — every item traces back to a real value already filtered to
/// what this media/selection actually supports (see the getters in
/// `_DownloadOptionsSheetState`); this widget only renders and reports a
/// tap, it never invents or curates a value of its own.
class _ChoicePickerSheet<T> extends StatelessWidget {
  const _ChoicePickerSheet({
    required this.title,
    required this.items,
    required this.currentValue,
    this.showAutomatic = false,
  });

  final String title;
  final List<_ChoiceItem<T>> items;
  final T? currentValue;
  final bool showAutomatic;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);

    return FetchySheet(
      title: title,
      maxHeightFactor: 0.75,
      pinFooter: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showAutomatic)
            FetchyOptionTile(
              label: strings.automaticRecommended,
              isSelected: currentValue == null,
              onTap: () => Navigator.of(context).pop(_PickerSelection<T>.automatic()),
            ),
          ...items.map(
            (_ChoiceItem<T> item) => FetchyOptionTile(
              label: item.label,
              isSelected: item.value == currentValue,
              onTap: () =>
                  Navigator.of(context).pop(_PickerSelection<T>.value(item.value)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors [_PickerSelection] for the subtitle picker specifically: "Off"
/// is a real, explicit choice (clears the subtitle) distinct from
/// dismissing the sheet without choosing anything.
class _SubtitlePick {
  const _SubtitlePick.off() : selection = null, isOff = true;
  const _SubtitlePick.selected(SubtitleSelection this.selection) : isOff = false;

  final SubtitleSelection? selection;
  final bool isOff;
}

/// Subtitles get their own picker rather than the generic
/// [_ChoicePickerSheet] because creator-provided [regularTracks] and
/// [autoTracks] must never be presented as one mixed list — regular
/// tracks show as a plain list, and auto-generated captions collapse into
/// their own expandable group underneath, exactly so a media item with
/// dozens of auto-caption languages does not bury its two or three real
/// creator subtitles.
class _SubtitlePickerSheet extends StatefulWidget {
  const _SubtitlePickerSheet({
    required this.regularTracks,
    required this.autoTracks,
    required this.currentSelection,
  });

  final List<MediaSubtitleTrack> regularTracks;
  final List<MediaSubtitleTrack> autoTracks;
  final SubtitleSelection? currentSelection;

  @override
  State<_SubtitlePickerSheet> createState() => _SubtitlePickerSheetState();
}

class _SubtitlePickerSheetState extends State<_SubtitlePickerSheet> {
  late bool _autoExpanded = widget.currentSelection?.kind == SubtitleTrackKind.automatic;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool hasRegular = widget.regularTracks.isNotEmpty;
    final bool hasAuto = widget.autoTracks.isNotEmpty;

    return FetchySheet(
      title: strings.subtitlesLabel,
      maxHeightFactor: 0.8,
      pinFooter: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FetchyOptionTile(
            label: strings.subtitlesOff,
            isSelected: widget.currentSelection == null,
            onTap: () => Navigator.of(context).pop(const _SubtitlePick.off()),
          ),
          if (hasRegular)
            ...widget.regularTracks.map(
              (MediaSubtitleTrack track) => FetchyOptionTile(
                label: _nameFor(track),
                isSelected:
                    widget.currentSelection?.kind == SubtitleTrackKind.regular &&
                    widget.currentSelection?.language == track.language,
                onTap: () => Navigator.of(context).pop(
                  _SubtitlePick.selected(
                    SubtitleSelection(
                      language: track.language,
                      kind: SubtitleTrackKind.regular,
                    ),
                  ),
                ),
              ),
            )
          else if (hasAuto)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                strings.noCreatorSubtitlesAvailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (hasAuto) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: _autoExpanded,
                onExpansionChanged: (bool expanded) =>
                    setState(() => _autoExpanded = expanded),
                title: Text(
                  strings.autoGeneratedSubtitles,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                children: widget.autoTracks
                    .map(
                      (MediaSubtitleTrack track) => FetchyOptionTile(
                        label: _nameFor(track),
                        isSelected:
                            widget.currentSelection?.kind ==
                                SubtitleTrackKind.automatic &&
                            widget.currentSelection?.language == track.language,
                        onTap: () => Navigator.of(context).pop(
                          _SubtitlePick.selected(
                            SubtitleSelection(
                              language: track.language,
                              kind: SubtitleTrackKind.automatic,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _nameFor(MediaSubtitleTrack track) {
    final String? name = track.name?.trim();
    return (name != null && name.isNotEmpty) ? name : track.language;
  }
}

/// The collapsed doorway into an Advanced section.
///
/// Shared by Video and Audio so both read identically: a recessed row that
/// picks up the brand tint the moment anything inside it has been
/// overridden, so "I changed something in there" is visible without
/// opening it.
class _AdvancedEntryRow extends StatelessWidget {
  const _AdvancedEntryRow({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final Color foreground = active
        ? tokens.onSurfaceSelected
        : colorScheme.onSurface;

    return FetchySurface(
      tone: active ? FetchyTone.selected : FetchyTone.sunken,
      borderRadius: AppShape.group,
      elevated: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.tune_rounded, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: active
                        ? tokens.onSurfaceSelected.withValues(alpha: 0.85)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: foreground),
        ],
      ),
    );
  }
}

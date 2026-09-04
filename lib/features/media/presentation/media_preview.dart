import 'package:flutter/material.dart';

import '../../../app/theme/app_dimens.dart';
import '../../../app/theme/fetchy_tokens.dart';
import '../../../app/widgets/fetchy_buttons.dart';
import '../../../app/widgets/fetchy_rows.dart';
import '../../../app/widgets/fetchy_selectors.dart';
import '../../../app/widgets/fetchy_surface.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloader/download_options.dart';
import '../../downloader/presentation/download_options_sheet.dart';
import '../../history/format_helpers.dart';
import '../format_parser.dart';
import '../format_selector.dart';
import '../media_info.dart';
import '../media_selection_catalog.dart';
import '../media_size.dart';

/// What the user has chosen in the preview. Carried to the download layer
/// when that exists.
class DownloadSelection {
  const DownloadSelection({
    required this.mediaInfo,
    required this.candidate,
    this.audioOutput,
    this.downloadOptions,
  });

  final MediaInfo mediaInfo;
  final FormatCandidate candidate;

  /// Set only when the user chose an audio-only output.
  final AudioOutputOption? audioOutput;

  /// Whatever the user set in the Download Options sheet, if anything —
  /// null when they never opened it or saved it empty.
  final DownloadOptions? downloadOptions;

  bool get isAudioOnly => audioOutput != null;
  bool get requiresMerge => candidate.requiresMerge;

  /// What the user will actually see the file saved as: their custom
  /// filename (video mode) or custom song title (audio mode) when they set
  /// one, otherwise the source title — matching exactly what
  /// `EngineChannelHandler.downloadFormat` uses to name the real output
  /// file, so the progress UI never shows a name the download itself
  /// isn't using.
  String get effectiveTitle =>
      downloadOptions?.video?.filename ??
      downloadOptions?.audio?.title ??
      mediaInfo.title;
}

enum _MediaMode { videoAndAudio, audioOnly }

class MediaPreview extends StatefulWidget {
  const MediaPreview({
    super.key,
    required this.mediaInfo,
    required this.onDownloadRequested,
    this.isDownloading = false,
  });

  final MediaInfo mediaInfo;
  final ValueChanged<DownloadSelection> onDownloadRequested;

  /// Whether a download started from this preview is still running. Purely
  /// presentational: it puts the Download button into its busy state so the
  /// same download cannot be fired twice while the first is in flight.
  final bool isDownloading;

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  late MediaSelectionCatalog _catalog;
  late _MediaMode _mode;

  int? _selectedHeight;
  AudioOutputOption? _normalAudioOutputChoice;
  DownloadOptions _downloadOptions = DownloadOptions.none;

  /// Set only when the user picked a specific format from the Advanced
  /// format/quality browser in Download Options — see
  /// `_onDownloadOptionsPressed`. Takes precedence over [_selectedHeight]
  /// everywhere a resolution is needed (display and download alike), so
  /// there is exactly one source of truth for "what will actually be
  /// downloaded" rather than two selectors that could disagree.
  ResolutionOption? _advancedResolution;

  /// The audio-mode equivalent of [_advancedResolution] — set only when
  /// the user picked a specific format from Audio's Advanced Format/Bitrate
  /// browser. Takes precedence over [_normalAudioOutputChoice] via the
  /// [_selectedAudioOutput] getter below.
  AudioOutputOption? _advancedAudioOutput;

  @override
  void initState() {
    super.initState();
    _rebuildCatalog();
  }

  @override
  void didUpdateWidget(MediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.mediaInfo, oldWidget.mediaInfo)) {
      _rebuildCatalog();
    }
  }

  void _rebuildCatalog() {
    final ParsedFormatCollection parsed = FormatParser.parse(
      widget.mediaInfo.formats,
    );

    _catalog = MediaSelectionCatalog.from(parsed);

    _mode = _catalog.hasVideo ? _MediaMode.videoAndAudio : _MediaMode.audioOnly;
    _selectedHeight = _catalog.best?.height;
    _normalAudioOutputChoice = _catalog.audioOutputs.isEmpty
        ? null
        : _catalog.audioOutputs.first;
    // A new media item means any previously-set Download Options no longer
    // apply — they were entered against the old item's title/metadata.
    _downloadOptions = DownloadOptions.none;
    _advancedResolution = null;
    _advancedAudioOutput = null;
  }

  ResolutionOption? get _selectedResolution {
    if (_advancedResolution != null) return _advancedResolution;
    final int? height = _selectedHeight;
    // No height to key on. That is either "this media reported no usable
    // dimensions", in which case the catalog holds a single height-less
    // option to select, or "there is no video at all", in which case the
    // catalog returns null and nothing is selected — exactly as before.
    if (height == null) return _catalog.unknownQualityResolution;
    return _catalog.resolutionForHeight(height);
  }

  AudioOutputOption? get _selectedAudioOutput =>
      _advancedAudioOutput ?? _normalAudioOutputChoice;

  /// Picking a plain quality/resolution chip means "use the ordinary
  /// selector," so any Advanced format override is discarded along with
  /// it — otherwise the chip would visibly change but the actual download
  /// would silently keep using the old Advanced pick. `includeAudio` also
  /// resets to true: it only ever means something paired with an
  /// [AdvancedFormatSelection], and leaving it false here with no override
  /// active would be a false safety-check bypass sitting dormant in state.
  void _clearAdvancedFormatOverride() {
    _advancedResolution = null;
    final VideoDownloadOptions? video = _downloadOptions.video;
    if (video == null) return;
    if (video.advancedFormat == null && video.includeAudio) return;
    _downloadOptions = _downloadOptions.copyWith(
      video: VideoDownloadOptions(
        filename: video.filename,
        subtitle: video.subtitle,
      ),
    );
  }

  bool get _canDownload {
    if (_mode == _MediaMode.audioOnly) return _selectedAudioOutput != null;
    return _selectedResolution != null;
  }

  void _onDownloadPressed() {
    final DownloadOptions? options = _downloadOptions.isEmpty ? null : _downloadOptions;

    // Any artwork selection is a one-time local temp file: once a download
    // that carries it is dispatched, native either embeds it and deletes
    // that file, or the download fails before ever reaching that step (in
    // which case the file is untouched, but the safer assumption is still
    // "this selection has been used"). Clearing it here means a second
    // Download tap for the same media never silently references an
    // already-consumed file — the worst case is the user re-selects
    // Source/Custom again, which is always cheap and always safe. Audio
    // metadata/filename are plain strings and have no such lifecycle, so
    // they are left exactly as the user set them.
    if (options?.artwork != null && !options!.artwork!.isEmpty) {
      setState(() => _downloadOptions = _downloadOptions.copyWith(artwork: ArtworkSelection.none));
    }

    if (_mode == _MediaMode.audioOnly) {
      final AudioOutputOption? output = _selectedAudioOutput;
      if (output == null) return;

      widget.onDownloadRequested(
        DownloadSelection(
          mediaInfo: widget.mediaInfo,
          candidate: output.source,
          audioOutput: output,
          downloadOptions: options,
        ),
      );
      return;
    }

    final ResolutionOption? resolution = _selectedResolution;
    if (resolution == null) return;

    widget.onDownloadRequested(
      DownloadSelection(
        mediaInfo: widget.mediaInfo,
        candidate: resolution.candidate,
        downloadOptions: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return FetchySurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Thumbnail(mediaInfo: widget.mediaInfo),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.mediaInfo.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.mediaInfo.uploader != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.account_circle_outlined,
                        size: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.mediaInfo.uploader!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ..._buildSelectors(strings, theme),
                const SizedBox(height: AppSpacing.lg),
                _buildDownloadSummaryCard(theme, strings),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FetchyPrimaryButton(
                        label: strings.download,
                        busyLabel: strings.downloadStarting,
                        busy: widget.isDownloading,
                        onPressed: _canDownload ? _onDownloadPressed : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // The tuner sits beside the primary action rather than
                    // above it: Download Options refines the thing the
                    // button is about to do, so it should never look like a
                    // competing choice.
                    FetchyIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: strings.downloadOptionsTitle,
                      // Tinted once the user has set something, so an
                      // active override is visible without opening it.
                      emphasis: !_downloadOptions.isEmpty,
                      size: 54,
                      iconSize: 22,
                      borderRadius: AppShape.hero,
                      onPressed: _onDownloadOptionsPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What the file will actually be saved as — mirrors
  /// [DownloadSelection.effectiveTitle] exactly, so this preview and the
  /// eventual progress/completed cards never disagree.
  String get _effectiveTitle =>
      _downloadOptions.video?.filename ??
      _downloadOptions.audio?.title ??
      widget.mediaInfo.title;

  /// A real display name for one subtitle pick, looked up from whichever
  /// of `subtitles`/`automaticCaptions` it came from — the same source
  /// data the Download Options subtitle picker itself reads, never a
  /// separate/duplicated name.
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

  /// The complete "what Fetchy is actually going to download" summary.
  /// Every row reads directly from [_selectedResolution]/
  /// [_selectedAudioOutput] — the exact same objects [_onDownloadPressed]
  /// hands to the download layer — so this can never show a different
  /// selection than what actually gets requested (e.g. a video-only pick
  /// can never render as if it still had audio).
  Widget _buildDownloadSummaryCard(ThemeData theme, AppLocalizations strings) {
    final ColorScheme colorScheme = theme.colorScheme;
    final List<Widget> rows = <Widget>[];

    if (_mode == _MediaMode.audioOnly) {
      final AudioOutputOption? output = _selectedAudioOutput;
      if (output != null) {
        // Distinguishes a real source format from a (currently never
        // offered, but honestly labeled if it ever is) conversion target —
        // never silently presented as if they were the same thing.
        final String formatValue = output.requiresProcessing
            ? strings.convertToFormat(output.label)
            : output.label;
        rows.add(_SummaryRow(label: strings.summaryLabelFormat, value: formatValue));

        final double? bitrate = output.sourceBitrate;
        if (bitrate != null && bitrate > 0) {
          rows.add(
            _SummaryRow(
              label: strings.summaryLabelBitrate,
              value: strings.bitrateKbps(bitrate.round()),
            ),
          );
        }
      }

      final List<String> metadataParts = <String>[];
      if (_downloadOptions.audio?.title != null) metadataParts.add(strings.songTitleLabel);
      if (_downloadOptions.audio?.artist != null) metadataParts.add(strings.artistLabel);
      if (_downloadOptions.audio?.album != null) metadataParts.add(strings.albumLabel);
      if (metadataParts.isNotEmpty) {
        rows.add(
          _SummaryRow(label: strings.summaryLabelMetadata, value: metadataParts.join(' • ')),
        );
      }

      final ArtworkSelection? artwork = _downloadOptions.artwork;
      if (artwork != null && !artwork.isEmpty) {
        rows.add(
          _SummaryRow(
            label: strings.summaryLabelArtwork,
            value: artwork.kind == ArtworkKind.source
                ? strings.summaryValueSource
                : strings.summaryValueCustom,
          ),
        );
      }
    } else {
      final ResolutionOption? resolution = _selectedResolution;
      if (resolution != null) {
        rows.add(
          _SummaryRow(
            label: strings.summaryLabelFormat,
            value: (resolution.candidate.primary.extension ?? '').toUpperCase(),
          ),
        );
        rows.add(
          _SummaryRow(
            label: strings.summaryLabelQuality,
            value: resolution.standardLabel ?? strings.qualityUnavailable,
          ),
        );

        final double? fps = resolution.fps;
        if (fps != null && fps > 0) {
          rows.add(_SummaryRow(label: strings.summaryLabelFps, value: '${fps.round()}'));
        }

        rows.add(
          _SummaryRow(
            label: strings.summaryLabelAudio,
            value: resolution.candidate.hasAudio
                ? strings.summaryValueIncluded
                : strings.summaryValueNone,
          ),
        );
      }

      final SubtitleSelection? subtitle = _downloadOptions.video?.subtitle;
      if (subtitle != null) {
        rows.add(
          _SummaryRow(
            label: strings.summaryLabelSubtitles,
            value: _subtitleDisplayName(subtitle),
          ),
        );
      }
    }

    rows.add(
      _SummaryRow(
        label: strings.summaryLabelSize,
        value: _selectedSizeSummary(strings),
        emphasize: true,
      ),
    );

    // A recessed well rather than an outlined box: this is a read-only
    // restatement of what is about to happen, so it should sit *below* the
    // card's surface rather than being framed on top of it.
    return FetchySurface(
      tone: FetchyTone.sunken,
      borderRadius: AppShape.group,
      elevated: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _mode == _MediaMode.audioOnly
                    ? Icons.audiotrack_rounded
                    : Icons.movie_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _effectiveTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
        ],
      ),
    );
  }

  /// Opens the Download Options sheet, including its Advanced section —
  /// Format/Quality/FPS/Subtitles/Include audio in Video mode,
  /// Format/Bitrate in Audio mode. When the user picked a specific
  /// Advanced format, the real option it corresponds to is looked back up
  /// from [_catalog] (`advancedEntryForFormatId`/
  /// `advancedAudioEntryForFormatId`) so [_selectedResolution]/
  /// [_selectedAudioOutput] — and therefore the download itself and every
  /// size/label shown for it — reflect exactly that pick, not the
  /// ordinary selector.
  Future<void> _onDownloadOptionsPressed() async {
    final DownloadOptions? result = await showDownloadOptionsSheet(
      context,
      mode: _mode == _MediaMode.audioOnly
          ? DownloadOptionsMediaMode.audio
          : DownloadOptionsMediaMode.video,
      initial: _downloadOptions,
      mediaInfo: widget.mediaInfo,
      catalog: _catalog,
    );
    if (result == null || !mounted) return;

    // Confirm the save on the page underneath (the sheet's own context is
    // gone by now) — but only when something genuinely changed. Opening the
    // sheet and pressing Save without touching anything is not a change,
    // and saying "saved" then would be noise that teaches the user to
    // ignore the message.
    if (result != _downloadOptions) {
      final FetchyTokens tokens = FetchyTokens.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: tokens.successFg,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(AppLocalizations.of(context).downloadOptionsSaved),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }

    final AdvancedFormatSelection? advancedVideoFormat = result.video?.advancedFormat;
    final AdvancedFormatSelection? advancedAudioFormat = result.audio?.advancedFormat;
    setState(() {
      _downloadOptions = result;
      _advancedResolution = advancedVideoFormat == null
          ? null
          : _catalog.advancedEntryForFormatId(
              advancedVideoFormat.formatId,
              includeAudio: result.video?.includeAudio ?? true,
            );
      _advancedAudioOutput = advancedAudioFormat == null
          ? null
          : _catalog.advancedAudioEntryForFormatId(advancedAudioFormat.formatId);
    });
  }

  Duration? get _duration => widget.mediaInfo.duration;

  /// Renders a [MediaSize] as "42.8 MB" or "Size unavailable". Whether the
  /// number is exact or approximate stays in [MediaSize.accuracy] for
  /// logic/diagnostics — the format card itself always shows a plain
  /// number, without an approximation marker.
  static String _describeSize(MediaSize size, AppLocalizations strings) {
    if (!size.isKnown) return strings.sizeUnavailable;
    return formatFileSize(size.bytes!);
  }

  /// The compact form used inside a chip; unknown sizes are omitted there
  /// rather than making every chip wider.
  static String? _chipSize(MediaSize size) {
    if (!size.isKnown) return null;
    return formatFileSize(size.bytes!);
  }

  String _selectedSizeSummary(AppLocalizations strings) {
    if (_mode == _MediaMode.audioOnly) {
      final AudioOutputOption? output = _selectedAudioOutput;
      if (output == null) return strings.sizeUnavailable;
      return _describeSize(output.size(_duration), strings);
    }
    final ResolutionOption? option = _selectedResolution;
    if (option == null) return strings.sizeUnavailable;
    return _describeSize(option.size(_duration), strings);
  }

  List<Widget> _buildSelectors(AppLocalizations strings, ThemeData theme) {
    final List<Widget> children = <Widget>[];

    if (_catalog.hasVideo && _catalog.hasAudio) {
      children.addAll(<Widget>[
        _MediaModeSelector(
          mode: _mode,
          onChanged: (_MediaMode mode) => setState(() => _mode = mode),
          videoLabel: strings.mediaTypeVideoAudio,
          audioLabel: strings.mediaTypeAudioOnly,
        ),
        const SizedBox(height: AppSpacing.lg),
      ]);
    }

    if (_mode == _MediaMode.audioOnly) {
      children.addAll(_buildAudioSelectors(strings, theme));
    } else {
      children.addAll(_buildVideoSelectors(strings, theme));
    }

    return children;
  }

  List<Widget> _buildVideoSelectors(AppLocalizations strings, ThemeData theme) {
    final List<MapEntry<QualityTier, ResolutionOption>> tiers =
        _catalog.distinctTiers;

    final List<Widget> children = <Widget>[];

    if (tiers.length > 1) {
      children.addAll(<Widget>[
        _SectionLabel(text: strings.qualityLabel, theme: theme),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tiers
              .map((MapEntry<QualityTier, ResolutionOption> entry) {
                return FetchyChoiceChip(
                  label: _tierLabel(entry.key, strings),
                  // The size drops to a second line rather than being
                  // joined onto the label with a separator.
                  caption: _chipSize(entry.value.size(_duration)),
                  isSelected: _selectedHeight == entry.value.height,
                  onTap: () {
                    setState(() {
                      _selectedHeight = entry.value.height;
                      _clearAdvancedFormatOverride();
                    });
                  },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.xl),
      ]);
    }

    if (_catalog.resolutions.length > 1) {
      children.addAll(<Widget>[
        _SectionLabel(text: strings.resolutionLabel, theme: theme),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _catalog.resolutions
              .map((ResolutionOption option) {
                return FetchyChoiceChip(
                  label: option.standardLabel ?? strings.qualityUnavailable,
                  caption: _chipSize(option.size(_duration)),
                  isSelected: _selectedHeight == option.height,
                  onTap: () {
                    setState(() {
                      _selectedHeight = option.height;
                      _clearAdvancedFormatOverride();
                    });
                  },
                );
              })
              .toList(growable: false),
        ),
      ]);
    }

    return children;
  }

  List<Widget> _buildAudioSelectors(AppLocalizations strings, ThemeData theme) {
    if (_catalog.audioOutputs.length <= 1) return const <Widget>[];

    return <Widget>[
      _SectionLabel(text: strings.audioFormatLabel, theme: theme),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _catalog.audioOutputs
            .map((AudioOutputOption output) {
              return FetchyChoiceChip(
                label: output.label,
                caption: _chipSize(output.size(_duration)),
                isSelected: _selectedAudioOutput?.label == output.label,
                onTap: () {
                  // Picking a plain chip means "use the ordinary
                  // selector" — any Advanced format override is
                  // discarded, mirroring _clearAdvancedFormatOverride
                  // for video.
                  setState(() {
                    _normalAudioOutputChoice = output;
                    _advancedAudioOutput = null;
                  });
                },
              );
            })
            .toList(growable: false),
      ),
    ];
  }

  String _tierLabel(QualityTier tier, AppLocalizations strings) => tier.label(strings);
}

/// One label/value line inside [_MediaPreviewState._buildDownloadSummaryCard].
/// Purely presentational — every value it's given already traces back to
/// the one effective selection, never computed here.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return FetchyDetailRow(label: label, value: value, emphasize: emphasize);
  }
}

class _MediaModeSelector extends StatelessWidget {
  const _MediaModeSelector({
    required this.mode,
    required this.onChanged,
    required this.videoLabel,
    required this.audioLabel,
  });

  final _MediaMode mode;
  final ValueChanged<_MediaMode> onChanged;
  final String videoLabel;
  final String audioLabel;

  @override
  Widget build(BuildContext context) {
    return FetchySegmented<_MediaMode>(
      selected: mode,
      onChanged: onChanged,
      segments: <FetchySegment<_MediaMode>>[
        FetchySegment<_MediaMode>(
          value: _MediaMode.videoAndAudio,
          label: videoLabel,
          icon: Icons.movie_outlined,
        ),
        FetchySegment<_MediaMode>(
          value: _MediaMode.audioOnly,
          label: audioLabel,
          icon: Icons.audiotrack_rounded,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.mediaInfo});

  final MediaInfo mediaInfo;

  @override
  Widget build(BuildContext context) {
    final String? url = mediaInfo.thumbnailUrl;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (url == null)
            const _ThumbnailPlaceholder()
          else
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? progress,
                  ) {
                    if (progress == null) return child;
                    return const _ThumbnailPlaceholder();
                  },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 52,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Colors.transparent, Color(0x99000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (mediaInfo.duration != null)
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 1,
                  vertical: AppSpacing.xs - 1,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: AppShape.chip,
                ),
                child: Text(
                  _formatDuration(mediaInfo.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.3,
                  ),
                  // A duration is a figure, not prose: it stays
                  // left-to-right in every locale.
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final String paddedSeconds = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final String paddedMinutes = minutes.toString().padLeft(2, '0');
      return '$hours:$paddedMinutes:$paddedSeconds';
    }

    return '$minutes:$paddedSeconds';
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 36,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

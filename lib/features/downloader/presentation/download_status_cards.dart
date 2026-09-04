import 'package:flutter/material.dart';

import '../../../app/theme/app_dimens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/fetchy_tokens.dart';
import '../../../app/widgets/fetchy_buttons.dart';
import '../../../app/widgets/fetchy_progress.dart';
import '../../../app/widgets/fetchy_rows.dart';
import '../../../app/widgets/fetchy_surface.dart';
import '../../../core/engine/downloader_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/platform/file_action_service.dart';
import '../../history/format_helpers.dart';
import '../../media/presentation/media_preview.dart';
import '../../sessions/platform_session.dart';
import '../extraction_error_mapper.dart';
import 'error_info_dialog.dart';

/// The download-status surface shared by every entry point.
///
/// Home and Quick Fetch both render these, so the two flows are visually and
/// behaviourally identical once a URL is in hand — the only difference between
/// them is how that URL arrived.
///
/// Every figure shown here comes from a real reported value: the percentage
/// and byte totals come from yt-dlp's own progress output, and the format
/// metadata comes from the selected format. Nothing is estimated, and ETA is
/// deliberately not displayed.
///
/// The layout puts one thing at each level of the hierarchy: what is being
/// downloaded, how far along it is, what was chosen and how big it is, and
/// then the bar itself. The format descriptor and the byte figures sit
/// together on the trailing edge opposite the percentage, so the eye reads
/// "45% — of a 1080p MP4, 124 of 250 MB" in one pass rather than hunting a
/// chip on one side and a size on the other.
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    super.key,
    required this.strings,
    required this.event,
    required this.selection,
    required this.onCancel,
  });

  final AppLocalizations strings;
  final DownloadEvent? event;
  final DownloadSelection? selection;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // The engine can take several seconds between accepting a download and
    // reporting its first byte. Until then there is no percentage to show,
    // so rather than a stuck "0%" over an empty bar the card says what is
    // actually happening and runs the indeterminate bar underneath.
    final double? progress = event?.progress;
    final bool awaitingFirstByte = progress == null;
    final String percentLabel = awaitingFirstByte
        ? ''
        : '${(progress * 100).clamp(0, 100).round()}%';

    final String? sizeLabel = _sizeLabel();
    final String? speedLabel = _speedLabel();
    final String? qualityFormat = _qualityFormatLabel();

    return FetchyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  selection?.effectiveTitle ?? strings.downloadStarting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FetchyIconButton(
                icon: Icons.close_rounded,
                tooltip: strings.commonCancel,
                onPressed: onCancel,
                size: 34,
                iconSize: 17,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (awaitingFirstByte)
                Expanded(
                  child: Text(
                    strings.downloadWillStartSoon,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  percentLabel,
                  // Tabular figures so the bar below does not shift as the
                  // percentage crosses 9 to 10 to 100.
                  style: AppTypography.numeric(
                    theme.textTheme.displayLarge!.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                      height: 1,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (qualityFormat != null)
                      Text(
                        qualityFormat,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (sizeLabel != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        sizeLabel,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.numeric(
                          theme.textTheme.bodySmall!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FetchyProgressBar(value: progress),
          if (speedLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              speedLabel,
              style: AppTypography.numeric(
                theme.textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "36 MB / 100 MB" when yt-dlp reported a total, otherwise "36 MB
  /// downloaded", otherwise nothing. Prefers the live total reported during
  /// the transfer and falls back to the selected format's own metadata size.
  String? _sizeLabel() {
    final DownloadEvent? event = this.event;
    if (event == null) return null;

    final int? liveTotal = event.totalBytes;
    final int? metadataTotal = selection?.candidate.filesize;
    final int? total = (liveTotal != null && liveTotal > 0)
        ? liveTotal
        : ((metadataTotal != null && metadataTotal > 0) ? metadataTotal : null);

    final double? progress = event.progress;
    final int? downloaded = event.downloadedBytes ??
        ((total != null && progress != null)
            ? (total * progress).round()
            : null);

    if (downloaded == null) return null;
    if (total == null) return strings.sizeDownloadedSuffix(formatFileSize(downloaded));
    return '${formatFileSize(downloaded)} / ${formatFileSize(total)}';
  }

  /// Shown only when yt-dlp actually reported a transfer rate.
  String? _speedLabel() {
    final int? speed = event?.speedBytesPerSecond;
    if (speed == null || speed <= 0) return null;
    return formatSpeed(speed.toDouble());
  }

  String? _qualityFormatLabel() => describeSelection(selection);
}

/// The quality/format descriptor for a selection, e.g. "1080p • MP4" or
/// "M4A". Shared so the progress card, the completed card, and the preview
/// all describe a selection the same way.
String? describeSelection(DownloadSelection? selection) {
  if (selection == null) return null;

  final List<String> parts = <String>[];
  if (selection.isAudioOnly) {
    final String? label = selection.audioOutput?.label;
    if (label != null) parts.add(label);
  } else {
    final int? height = selection.candidate.height;
    if (height != null) parts.add('${height}p');
  }

  final String? extension = selection.candidate.primary.extension;
  if (extension != null && extension.trim().isNotEmpty) {
    parts.add(extension.trim().toUpperCase());
  }

  if (parts.isEmpty) return null;
  return parts.join(' • ');
}

/// The merge phase. yt-dlp performs the remux itself and reports no
/// percentage for it, so this stays indeterminate rather than inventing one.
class DownloadMergingCard extends StatelessWidget {
  const DownloadMergingCard({super.key, required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FetchyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.merge_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  strings.merging,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const FetchyProgressBar(value: null),
        ],
      ),
    );
  }
}

/// The completed state, with Open and Share acting on the real file.
class DownloadCompletedCard extends StatelessWidget {
  const DownloadCompletedCard({
    super.key,
    required this.event,
    required this.selection,
  });

  final DownloadEvent event;
  final DownloadSelection? selection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final int? filesize = selection?.candidate.filesize;
    final String? descriptor = describeSelection(selection);

    final String formatAndSize = <String>[
      ?descriptor,
      if (filesize != null && filesize > 0) formatFileSize(filesize),
    ].join(' • ');

    return FetchyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.successBg,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: tokens.successFg,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  strings.downloadComplete,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (selection != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              selection!.effectiveTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (formatAndSize.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FetchyTag(label: formatAndSize),
            ),
          ],
          if (event.outputPath != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings.savedToPath(event.outputPath!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (event.warningMessage != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            FetchyBanner(
              message: event.warningMessage!,
              tone: FetchyBannerTone.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: FetchyTonalButton(
                  label: strings.commonOpen,
                  icon: Icons.open_in_new_rounded,
                  emphasis: true,
                  onPressed: () => _openFile(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FetchyTonalButton(
                  label: strings.commonShare,
                  icon: Icons.share_rounded,
                  onPressed: () => _shareFile(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final FileActionResult result = await FileActionService.instance.openFile(
      uri: event.outputUri,
      path: event.outputPath,
    );
    if (!result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppLocalizations.of(context).couldNotOpenFile),
        ),
      );
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    final FileActionResult result = await FileActionService.instance.shareFile(
      uri: event.outputUri,
      path: event.outputPath,
    );
    if (!result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppLocalizations.of(context).couldNotShareFile),
        ),
      );
    }
  }
}

/// A neutral success/error message row (fetch failed, download canceled, ...).
///
/// When [errorDetails] is supplied, a "Why?" action opens the Error
/// Information Center (see error_info_dialog.dart) with the fuller
/// explanation, suggested next step, and sanitized technical detail — the
/// primary [message] shown here stays a single short sentence regardless.
class DownloadMessageCard extends StatelessWidget {
  const DownloadMessageCard({
    super.key,
    required this.title,
    required this.message,
    required this.isError,
    this.errorDetails,
    this.platform,
    this.onRetry,
    this.onConnectAccount,
  });

  final String title;
  final String message;
  final bool isError;

  final MappedExtractionError? errorDetails;
  final String? platform;
  final VoidCallback? onRetry;
  final ValueChanged<SessionPlatform>? onConnectAccount;

  @override
  Widget build(BuildContext context) {
    final MappedExtractionError? errorDetails = this.errorDetails;

    return FetchyBanner(
      title: title,
      message: message,
      tone: isError ? FetchyBannerTone.error : FetchyBannerTone.success,
      icon: isError
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded,
      action: errorDetails == null
          ? null
          : FetchyTonalButton(
              label: 'Why?',
              icon: Icons.help_outline_rounded,
              expand: false,
              height: 38,
              onPressed: () => showErrorInfoDialog(
                context,
                title: title,
                error: errorDetails,
                platform: platform,
                onRetry: onRetry,
                onConnectAccount: onConnectAccount,
              ),
            ),
    );
  }
}

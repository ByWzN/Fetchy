import 'package:flutter/material.dart';

import '../../app/theme/app_dimens.dart';
import '../../app/widgets/fetchy_surface.dart';
import '../../core/platform/file_action_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../history/format_helpers.dart';
import '../history/history_entry.dart';
import '../history/history_service.dart';
import '../media/presentation/media_preview.dart';

enum DuplicateAction { downloadAgain, cancel, open }

class DuplicateCheckHelper {
  const DuplicateCheckHelper._();

  /// Checks if a file matching [selection] has already been downloaded and still
  /// exists on the device storage. If found, prompts the user with choices:
  /// [DuplicateAction.open], [DuplicateAction.downloadAgain], or [DuplicateAction.cancel].
  ///
  /// Returns null if no existing duplicate is found (meaning proceed with download).
  static Future<DuplicateAction?> checkAndPrompt({
    required BuildContext context,
    required DownloadSelection selection,
    required HistoryService historyService,
  }) async {
    final List<HistoryEntry> entries = historyService.entries.value;
    if (entries.isEmpty) return null;

    final String sourceUrl = selection.mediaInfo.sourceUrl.trim();
    final String? webpageUrl = selection.mediaInfo.webpageUrl?.trim();
    final String title = selection.mediaInfo.title.trim().toLowerCase();
    final bool isAudio = selection.isAudioOnly;
    final int? height = selection.candidate.height;
    final String? qualityLabel = isAudio
        ? selection.audioOutput?.label
        : (height != null ? '${height}p' : null);

    HistoryEntry? matchingEntry;

    for (final HistoryEntry entry in entries) {
      final String entryUrl = entry.sourceUrl.trim();
      final bool urlMatches =
          entryUrl.isNotEmpty &&
          (entryUrl == sourceUrl ||
              (webpageUrl != null && entryUrl == webpageUrl));

      final bool titleMatches = entry.title.trim().toLowerCase() == title;

      // Identifying the same *media* is not enough: re-downloading the same
      // video at a different quality is a legitimate new download, so the
      // media type and quality must line up too before this counts as a
      // duplicate.
      final bool sameOutput =
          entry.mediaType == (isAudio ? 'audio' : 'video') &&
          (qualityLabel == null || entry.qualityLabel == qualityLabel);

      if ((urlMatches || titleMatches) && sameOutput) {
        matchingEntry = entry;
        break;
      }
    }

    if (matchingEntry == null) return null;

    final HistoryEntry duplicateEntry = matchingEntry;

    // Check if the physical file actually exists on device
    final FileStatusResult status = await FileActionService.instance
        .checkFileExists(
          uri: duplicateEntry.outputUri,
          path: duplicateEntry.outputPath,
        );

    if (!status.exists) return null;

    if (!context.mounted) return null;

    final DuplicateAction? chosen = await showDialog<DuplicateAction>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final AppLocalizations strings = AppLocalizations.of(dialogContext);
        final ThemeData theme = Theme.of(dialogContext);
        final ColorScheme colorScheme = theme.colorScheme;

        final String displayPath =
            status.displayPath ??
            duplicateEntry.outputPath ??
            duplicateEntry.fileName ??
            strings.duplicateDialogDefaultPath;

        final int? size = status.sizeBytes ?? duplicateEntry.fileSizeBytes;

        return AlertDialog(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: colorScheme.primary,
            size: 32,
          ),
          title: Text(strings.duplicateDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.duplicateDialogBody),
              const SizedBox(height: AppSpacing.md),
              FetchySurface(
                tone: FetchyTone.sunken,
                borderRadius: AppShape.control,
                elevated: false,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      duplicateEntry.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        if (duplicateEntry.qualityLabel != null) ...<Widget>[
                          FetchyTag(label: duplicateEntry.qualityLabel!),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (size != null)
                          Text(
                            formatFileSize(size),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      displayPath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(DuplicateAction.cancel),
              child: Text(strings.commonCancel),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop(DuplicateAction.open);
                await FileActionService.instance.openFile(
                  uri: duplicateEntry.outputUri,
                  path: status.displayPath ?? duplicateEntry.outputPath,
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(strings.commonOpen),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(DuplicateAction.downloadAgain),
              child: Text(strings.duplicateDialogDownloadAgain),
            ),
          ],
        );
      },
    );

    return chosen ?? DuplicateAction.cancel;
  }
}

import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/fetchy_tokens.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/platform/file_action_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../format_helpers.dart';
import '../../history_entry.dart';

/// One row in the Recent Downloads / History list. Reused by both the Home
/// page's "Recent downloads" section and the full History page so the two
/// maintain visual coherence.
///
/// The metadata below the title is deliberately one line of plain text with
/// a single tonal tag in front of it, rather than the row of five separate
/// pills it used to be. The quality/format tag is the only thing worth
/// singling out — platform, size, and age are context, and reading them as
/// one sentence is faster than parsing four boxes.
class HistoryListTile extends StatelessWidget {
  const HistoryListTile({super.key, required this.entry, this.onTap});

  final HistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool isAudio = entry.mediaType == 'audio';

    final String qualityAndFormat = <String>[
      if (entry.qualityLabel != null) entry.qualityLabel!,
      if (entry.extension != null) entry.extension!,
    ].join(' • ');

    // Platform, size, and age read as one quiet run of context.
    final String context_ = <String>[
      entry.platform,
      if (entry.fileSizeBytes != null) formatFileSize(entry.fileSizeBytes!),
      formatRelativeTime(entry.downloadedAt, strings),
    ].join('  ·  ');

    return FetchySurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          _Thumbnail(url: entry.thumbnailUrl, isAudio: isAudio),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  children: <Widget>[
                    if (qualityAndFormat.isNotEmpty) ...<Widget>[
                      FetchyTag(
                        label: qualityAndFormat,
                        // Audio picks up the cyan half of the brand so the
                        // two media types are distinguishable at a glance
                        // without either of them shouting.
                        background: isAudio
                            ? colorScheme.secondaryContainer
                            : tokens.surfaceSelected,
                        foreground: isAudio
                            ? colorScheme.onSecondaryContainer
                            : tokens.onSurfaceSelected,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        context_,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                _MissingFileBadge(entry: entry),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.isAudio});

  final String? url;
  final bool isAudio;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final Widget placeholder = Center(
      child: Icon(
        isAudio ? Icons.audiotrack_rounded : Icons.movie_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
    );

    return ClipRRect(
      borderRadius: AppShape.control,
      child: Container(
        width: 54,
        height: 54,
        color: tokens.surfaceSunken,
        child: url == null
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? progress,
                    ) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
              ),
      ),
    );
  }
}

/// Shows a "File missing" marker when the recorded download is no longer on
/// disk — the user may have deleted it outside Fetchy.
///
/// The history record is deliberately left intact; only its availability is
/// reported, so nothing is silently thrown away.
class _MissingFileBadge extends StatelessWidget {
  const _MissingFileBadge({required this.entry});

  final HistoryEntry entry;

  /// Results are memoised per entry so scrolling the list does not repeat the
  /// platform lookup for rows that have already been checked.
  static final Map<String, Future<FileStatusResult>> _cache =
      <String, Future<FileStatusResult>>{};

  static Future<FileStatusResult> _statusFor(HistoryEntry entry) {
    return _cache.putIfAbsent(
      entry.id,
      () => FileActionService.instance.checkFileExists(
        uri: entry.outputUri,
        path: entry.outputPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (entry.outputUri == null && entry.outputPath == null) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<FileStatusResult>(
      future: _statusFor(entry),
      builder: (BuildContext context, AsyncSnapshot<FileStatusResult> snapshot) {
        // Until the answer arrives, claim nothing.
        if (!snapshot.hasData || snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FetchyTag(
              label: AppLocalizations.of(context).historyFileMissing,
              icon: Icons.error_outline_rounded,
              background: colorScheme.errorContainer,
              foreground: colorScheme.onErrorContainer,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../app/widgets/fetchy_buttons.dart';
import '../../../../app/widgets/fetchy_rows.dart';
import '../../../../app/widgets/fetchy_surface.dart';
import '../../../../core/platform/file_action_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../format_helpers.dart';
import '../../history_entry.dart';

/// Detail screen for one history entry. Exposes the source URL, platform, file
/// information, and real working Open/Share actions via [FileActionService].
class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  FileStatusResult? _fileStatus;
  bool _isCheckingFile = true;

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    final FileStatusResult status = await FileActionService.instance
        .checkFileExists(
          uri: widget.entry.outputUri,
          path: widget.entry.outputPath,
        );

    if (mounted) {
      setState(() {
        _fileStatus = status;
        _isCheckingFile = false;
      });
    }
  }

  Future<void> _onOpenPressed() async {
    final FileActionResult result = await FileActionService.instance.openFile(
      uri: widget.entry.outputUri,
      path: _fileStatus?.displayPath ?? widget.entry.outputPath,
    );

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppLocalizations.of(context).couldNotOpenFile),
        ),
      );
    }
  }

  Future<void> _onSharePressed() async {
    final FileActionResult result = await FileActionService.instance.shareFile(
      uri: widget.entry.outputUri,
      path: _fileStatus?.displayPath ?? widget.entry.outputPath,
    );

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? AppLocalizations.of(context).couldNotShareFile),
        ),
      );
    }
  }

  Future<void> _copySourceUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.entry.sourceUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).historyLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final HistoryEntry entry = widget.entry;

    final bool fileExists = _fileStatus?.exists ?? false;
    final int? effectiveSize = _fileStatus?.sizeBytes ?? entry.fileSizeBytes;
    final String effectivePath =
        _fileStatus?.displayPath ?? entry.outputPath ?? entry.fileName ?? '';

    return FetchyScaffold(
      title: strings.historyDetailTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          Text(
            entry.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              FetchyTag(label: entry.platform),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatRelativeTime(entry.downloadedAt, strings),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // File status banner
          if (!_isCheckingFile)
            FetchyBanner(
              message: fileExists
                  ? strings.historyFileAvailable
                  : strings.historyFileMissingOrRemoved,
              tone: fileExists
                  ? FetchyBannerTone.success
                  : FetchyBannerTone.warning,
              icon: fileExists
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
            ),

          const SizedBox(height: AppSpacing.lg),
          FetchyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoRow(
                  icon: Icons.link_rounded,
                  label: strings.historySourceUrlLabel,
                  value: entry.sourceUrl,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.public_rounded,
                  label: strings.historyPlatformLabel,
                  value: entry.platform,
                ),
                if (entry.mediaType != null) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: strings.historyTypeLabel,
                    value: entry.mediaType!.toUpperCase(),
                  ),
                ],
                if (entry.qualityLabel != null) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.high_quality_rounded,
                    label: strings.historyQualityLabel,
                    value: entry.qualityLabel!,
                  ),
                ],
                if (entry.extension != null) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.extension_outlined,
                    label: strings.historyFormatLabel,
                    value: entry.extension!,
                  ),
                ],
                if (entry.fileName != null) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.insert_drive_file_outlined,
                    label: strings.historyFileNameLabel,
                    value: entry.fileName!,
                  ),
                ],
                if (effectiveSize != null && effectiveSize > 0) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.data_usage_rounded,
                    label: strings.historyFileSizeLabel,
                    value: formatFileSize(effectiveSize),
                  ),
                ],
                if (effectivePath.isNotEmpty) ...<Widget>[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.folder_outlined,
                    label: strings.historySavedToLabel,
                    value: effectivePath,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: FetchyTonalButton(
                  label: strings.commonOpen,
                  icon: Icons.open_in_new_rounded,
                  emphasis: true,
                  onPressed: fileExists ? _onOpenPressed : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FetchyTonalButton(
                  label: strings.commonShare,
                  icon: Icons.share_rounded,
                  onPressed: fileExists ? _onSharePressed : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FetchyTonalButton(
            label: strings.historyCopySourceUrl,
            icon: Icons.copy_rounded,
            onPressed: () => _copySourceUrl(context),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                // URLs, paths, and filenames stay left-to-right in every
                // locale; only their label is translated.
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

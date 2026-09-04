import 'package:flutter/material.dart';

import '../../../app/theme/app_dimens.dart';
import '../../../app/widgets/fetchy_buttons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../diagnostics/last_extraction_error.dart';
import '../../diagnostics/presentation/pages/developer_information_page.dart';
import '../../diagnostics/presentation/pages/diagnostics_page.dart';
import '../../sessions/platform_session.dart';
import '../extraction_error_mapper.dart';
import '../extraction_error_presentation.dart';

/// Error Information Center: the "Why?" detail view behind every download
/// failure. The primary message the user first sees stays a single short
/// sentence (rendered by [DownloadMessageCard]); this dialog is where the
/// fuller explanation, the suggested next step, and the sanitized technical
/// detail live — reached only if the user asks for it.
Future<void> showErrorInfoDialog(
  BuildContext context, {
  required String title,
  required MappedExtractionError error,
  String? platform,
  VoidCallback? onRetry,
  ValueChanged<SessionPlatform>? onConnectAccount,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) => _ErrorInfoDialog(
      title: title,
      error: error,
      platform: platform,
      onRetry: onRetry,
      onConnectAccount: onConnectAccount,
    ),
  );
}

class _ErrorInfoDialog extends StatefulWidget {
  const _ErrorInfoDialog({
    required this.title,
    required this.error,
    required this.platform,
    required this.onRetry,
    required this.onConnectAccount,
  });

  final String title;
  final MappedExtractionError error;
  final String? platform;
  final VoidCallback? onRetry;
  final ValueChanged<SessionPlatform>? onConnectAccount;

  @override
  State<_ErrorInfoDialog> createState() => _ErrorInfoDialogState();
}

class _ErrorInfoDialogState extends State<_ErrorInfoDialog> {
  @override
  void initState() {
    super.initState();
    // Recorded here — not just when Technical details is expanded — so the
    // Developer information page has real context whenever this dialog was
    // shown at all, even if the user closes it without expanding anything.
    LastExtractionError.instance.record(widget.error, platform: widget.platform);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MappedExtractionError error = widget.error;

    return AlertDialog(
      icon: Icon(
        Icons.help_outline_rounded,
        size: 28,
        color: colorScheme.primary,
      ),
      title: Text(extractionCategoryTitle(error.kind, strings)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              extractionMessageFor(error, strings, platform: widget.platform),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              strings.errorMorePossibleReasons,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...extractionPossibleReasons(
              error.kind,
              strings,
              platform: widget.platform,
            ).map((String reason) => _BulletLine(reason)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings.errorSettingsPointer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FetchyTonalButton(
              label: strings.errorMoreInformation,
              icon: Icons.info_outline_rounded,
              height: 42,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const DiagnosticsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            FetchyTonalButton(
              label: strings.errorDeveloperInformation,
              icon: Icons.code_rounded,
              height: 42,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const DeveloperInformationPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.commonClose),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ..._buildActionButtons(context, strings, colorScheme),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    AppLocalizations strings,
    ColorScheme colorScheme,
  ) {
    final MappedExtractionError error = widget.error;
    final SessionPlatform? sessionPlatform = SessionPlatformInfo.fromId(
      widget.platform?.toLowerCase(),
    );

    switch (error.suggestedAction) {
      case SuggestedAction.retry:
        if (widget.onRetry == null) return const <Widget>[];
        return <Widget>[
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRetry!();
            },
            child: Text(strings.commonRetry),
          ),
        ];

      case SuggestedAction.connectAccount:
        if (widget.onConnectAccount == null || sessionPlatform == null) {
          return const <Widget>[];
        }
        return <Widget>[
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConnectAccount!(sessionPlatform);
            },
            child: Text(strings.errorConnectedAccounts),
          ),
        ];

      case SuggestedAction.reconnect:
        if (widget.onConnectAccount == null || sessionPlatform == null) {
          return const <Widget>[];
        }
        // Both land on Connected Accounts, where reconnecting (Easy) and
        // importing a fresh cookies.txt (Advanced) both live — this is not
        // two separate flows, just two doors into the same place.
        return <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConnectAccount!(sessionPlatform);
            },
            child: Text(strings.errorImportSession),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConnectAccount!(sessionPlatform);
            },
            child: Text(strings.errorReconnect),
          ),
        ];

      case SuggestedAction.none:
        return const <Widget>[];
    }
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsetsDirectional.only(top: 7, end: AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

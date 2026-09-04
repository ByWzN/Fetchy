import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../quick_fetch_models.dart';
import '../../quick_fetch_service.dart';

/// The one place that turns Quick Fetch on or off.
///
/// Both the Settings page's master switch and the full Quick Fetch screen's
/// own switch call this — neither keeps its own copy of the enable/disable
/// flow, so there is exactly one source of truth for what happens when the
/// feature is toggled (the consent explanation before first turning it on,
/// the actual platform call, persisting the result, and the one-time
/// permission prompt right after).
///
/// Returns the resulting capabilities so the caller's UI reflects what
/// actually happened rather than what was requested.
Future<QuickFetchCapabilities> setQuickFetchEnabled(
  BuildContext context, {
  required bool enabled,
  required QuickFetchCapabilities capabilities,
}) async {
  if (enabled) {
    final bool accepted = await _showConsentDialog(context);
    if (!accepted) return capabilities;
  }

  final QuickFetchService quickFetch = QuickFetchService.instance;
  final QuickFetchCapabilities result = await quickFetch.setEnabled(
    enabled: enabled,
    actionStyle: capabilities.actionStyle,
  );
  await AppSettingsService.instance.saveQuickFetchEnabled(result.enabled);

  if (result.enabled &&
      result.actionStyle == QuickFetchActionStyle.notification &&
      !result.canPostNotifications) {
    await quickFetch.requestNotificationPermission();
  }

  return result;
}

Future<bool> _showConsentDialog(BuildContext context) async {
  final AppLocalizations strings = AppLocalizations.of(context);
  final bool? accepted = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      icon: Icon(
        Icons.bolt_rounded,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(strings.quickFetchConsentTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(strings.quickFetchConsent1),
            const SizedBox(height: AppSpacing.md),
            Text(strings.quickFetchConsent2),
            const SizedBox(height: AppSpacing.md),
            Text(strings.quickFetchConsent3),
            const SizedBox(height: AppSpacing.md),
            Text(strings.quickFetchConsent4),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.quickFetchTurnOn),
        ),
      ],
    ),
  );

  return accepted ?? false;
}

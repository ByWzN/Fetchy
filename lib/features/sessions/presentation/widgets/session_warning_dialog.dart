import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Shown before a user's first session connection/import. Returns true if
/// they chose to continue, false (or null, if dismissed) otherwise.
Future<bool> showSessionWarningDialog(BuildContext context) async {
  final AppLocalizations strings = AppLocalizations.of(context);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      // A leading glyph on every consequential dialog, matching the
      // duplicate-download and error dialogs, so the kind of decision being
      // asked for reads before the text does.
      icon: Icon(
        Icons.shield_outlined,
        size: 28,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(strings.sessionWarningTitle),
      content: Text(strings.sessionWarningBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.commonContinue),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}

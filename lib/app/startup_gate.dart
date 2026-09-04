import 'dart:async';

import 'package:flutter/material.dart';

import '../core/settings/locale_controller.dart';
import '../core/settings/theme_controller.dart';
import '../core/update/update_service.dart';
import '../features/quick_fetch/quick_fetch_service.dart';
import '../features/share/share_intent_service.dart';
import 'root_shell.dart';

/// Starts Fetchy's background detection services (Quick Fetch, share
/// intent) once at launch, then shows [RootShell] directly.
///
/// There is no in-app branding animation in this build -- only the native
/// Android launch screen (see the app's `android/app/src/main/res` splash
/// resources) runs before this.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    QuickFetchService.instance.start();
    ShareIntentService.instance.start();

    // The lightweight automatic update check. Deliberately fire-and-forget:
    // nothing here is awaited, so startup never waits on GitHub, and the
    // service returns immediately without a request unless a full cooldown
    // has passed since the last successful check. It shows nothing on its
    // own — the result is only recorded, for Settings to surface — so it
    // can never interrupt the user with a dialog.
    unawaited(UpdateService.instance.checkAutomatically());
  }

  @override
  Widget build(BuildContext context) {
    return RootShell(
      themeController: widget.themeController,
      localeController: widget.localeController,
    );
  }
}

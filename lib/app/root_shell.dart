import 'dart:async';

import 'package:flutter/material.dart';

import '../core/settings/locale_controller.dart';
import '../core/settings/theme_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'theme/fetchy_tokens.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/media/presentation/pages/media_preview_page.dart';
import '../features/quick_fetch/quick_fetch_service.dart';
import '../features/settings/presentation/pages/settings_page.dart';

/// Root navigation shell: switching between Home, History, and Settings.
/// Tab state is preserved via [IndexedStack].
///
/// This is also where a Quick Fetch tap lands. Because the shell is always
/// mounted, it pushes the media preview directly on top of whichever tab the
/// user was on — Home is never opened or navigated through first.
class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final QuickFetchService _quickFetch = QuickFetchService.instance;

  StreamSubscription<QuickFetchTapResult>? _quickFetchSubscription;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _quickFetch.start();
    _quickFetchSubscription = _quickFetch.taps.listen(_onQuickFetchTap);
  }

  @override
  void dispose() {
    _quickFetchSubscription?.cancel();
    super.dispose();
  }

  /// Runs once per quick-action tap. The clipboard has already been read
  /// natively at a moment when the Activity held focus; all that is left is to
  /// route the outcome.
  void _onQuickFetchTap(QuickFetchTapResult result) {
    if (!mounted) return;

    switch (result) {
      case QuickFetchLinkReady(:final String url):
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MediaPreviewPage(url: url),
          ),
        );

      case QuickFetchNoLink():
        // Expected whenever detection was a false positive or the user copied
        // something else in the meantime. Say so quietly and move on.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).homeNoSupportedLinkFound),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const HomePage(),
      const HistoryPage(),
      SettingsPage(
        themeController: widget.themeController,
        localeController: widget.localeController,
      ),
    ];

    final AppLocalizations strings = AppLocalizations.of(context);

    final FetchyTokens tokens = FetchyTokens.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(index: _index, children: pages),
      // A hairline rather than an elevation shadow: the bar is a sibling of
      // the content, not a layer floating over it.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int index) => setState(() => _index = index),
          // Outlined when resting, filled when selected — the same
          // convention in all three slots, so selection reads from the icon
          // as well as from the indicator.
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: strings.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: strings.navHistory,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: strings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

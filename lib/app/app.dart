import 'package:flutter/material.dart';

import '../core/localization/localization_config.dart';
import '../core/settings/locale_controller.dart';
import '../core/settings/theme_controller.dart';
import 'routes.dart';
import 'startup_gate.dart';
import 'theme/app_theme.dart';

class FetchyApp extends StatelessWidget {
  const FetchyApp({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[themeController, localeController]),
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'Fetchy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.flutterThemeMode,
          // Null (AppLanguageMode.system) leaves locale resolution entirely
          // to localeResolutionCallback, i.e. the device language — a
          // manual pick here overrides it.
          locale: localeController.locale,
          supportedLocales: LocalizationConfig.supportedLocales,
          localizationsDelegates: LocalizationConfig.delegates,
          localeResolutionCallback: LocalizationConfig.resolveLocale,
          // The theme is built before the locale is known, so the
          // locale-sensitive part of it (Latin tracking, which harms
          // Arabic's connected letterforms) is applied here, where the
          // resolved locale finally is known — whether it came from the
          // user's pick or from the device.
          builder: (BuildContext context, Widget? child) {
            if (child == null) return const SizedBox.shrink();
            return Theme(
              data: AppTheme.forLocale(
                Theme.of(context),
                Localizations.localeOf(context),
              ),
              child: child,
            );
          },
          initialRoute: AppRoutes.root,
          routes: <String, WidgetBuilder>{
            AppRoutes.root: (BuildContext context) => StartupGate(
              themeController: themeController,
              localeController: localeController,
            ),
          },
        );
      },
    );
  }
}

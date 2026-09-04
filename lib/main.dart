import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/settings/locale_controller.dart';
import 'core/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ThemeController themeController = ThemeController();
  final LocaleController localeController = LocaleController();
  await Future.wait(<Future<void>>[themeController.load(), localeController.load()]);

  runApp(
    FetchyApp(themeController: themeController, localeController: localeController),
  );
}

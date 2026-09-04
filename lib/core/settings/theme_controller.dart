import 'package:flutter/material.dart';

import 'app_settings_service.dart';

/// App-wide theme state. Loads the persisted [AppThemeMode] on startup and
/// notifies [FetchyApp] whenever the user changes it from Settings.
class ThemeController extends ChangeNotifier {
  ThemeController({AppSettingsService? settings})
    : _settings = settings ?? AppSettingsService.instance;

  final AppSettingsService _settings;

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  ThemeMode get flutterThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    _mode = await _settings.loadThemeMode();
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _settings.saveThemeMode(mode);
  }
}

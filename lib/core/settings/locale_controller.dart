import 'package:flutter/material.dart';

import '../localization/localization_config.dart';
import 'app_settings_service.dart';

/// App-wide language override. [AppLanguageMode.system] (the default) keeps
/// the device language as the source of truth — [locale] then returns null,
/// so `MaterialApp`'s own `localeResolutionCallback`
/// (`LocalizationConfig.resolveLocale`) resolves it exactly as if this
/// controller didn't exist. Picking English or Arabic explicitly overrides
/// that and is persisted the same way [ThemeController] persists the theme.
class LocaleController extends ChangeNotifier {
  LocaleController({AppSettingsService? settings})
    : _settings = settings ?? AppSettingsService.instance;

  final AppSettingsService _settings;

  AppLanguageMode _mode = AppLanguageMode.system;
  AppLanguageMode get mode => _mode;

  Locale? get locale {
    switch (_mode) {
      case AppLanguageMode.system:
        return null;
      case AppLanguageMode.english:
        return LocalizationConfig.english;
      case AppLanguageMode.arabic:
        return LocalizationConfig.arabic;
    }
  }

  Future<void> load() async {
    _mode = await _settings.loadLanguageMode();
    notifyListeners();
  }

  Future<void> setMode(AppLanguageMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _settings.saveLanguageMode(mode);
  }
}

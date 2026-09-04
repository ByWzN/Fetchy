import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable theme mode, persisted locally.
enum AppThemeMode { system, light, dark }

/// User-selectable language override, persisted locally. [system] (the
/// default) means the device language remains the source of truth — see
/// [LocaleController] and `LocalizationConfig.resolveLocale`.
enum AppLanguageMode { system, english, arabic }

/// Small local key-value persistence for app-wide preferences (appearance,
/// Quick Fetch, history toggle). Backed by [SharedPreferences] — no
/// database, no server. Download Location has its own service —
/// [StorageSettingsService] — since it also owns native folder-picking
/// calls, not just key-value storage.
class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const String _themeModeKey = 'fetchy.settings.themeMode';
  static const String _languageModeKey = 'fetchy.settings.languageMode';
  static const String _quickFetchKey = 'fetchy.settings.quickFetchEnabled';
  static const String _historyEnabledKey = 'fetchy.settings.historyEnabled';
  static const String _sessionWarningAckKey =
      'fetchy.settings.sessionWarningAcknowledged';

  Future<AppThemeMode> loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_themeModeKey);
    return _themeModeFrom(raw);
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<AppLanguageMode> loadLanguageMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_languageModeKey);
    return _languageModeFrom(raw);
  }

  Future<void> saveLanguageMode(AppLanguageMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageModeKey, mode.name);
  }

  Future<bool> loadQuickFetchEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quickFetchKey) ?? false;
  }

  Future<void> saveQuickFetchEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickFetchKey, enabled);
  }

  Future<bool> loadHistoryEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_historyEnabledKey) ?? true;
  }

  Future<void> saveHistoryEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_historyEnabledKey, enabled);
  }

  /// Whether the user has already seen and accepted the Connected
  /// Accounts/Sessions warning at least once. The warning is shown again
  /// once here, not on every import, but is never skipped the first time.
  Future<bool> loadSessionWarningAcknowledged() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionWarningAckKey) ?? false;
  }

  Future<void> saveSessionWarningAcknowledged(bool acknowledged) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionWarningAckKey, acknowledged);
  }

  static AppThemeMode _themeModeFrom(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  static AppLanguageMode _languageModeFrom(String? raw) {
    switch (raw) {
      case 'english':
        return AppLanguageMode.english;
      case 'arabic':
        return AppLanguageMode.arabic;
      default:
        return AppLanguageMode.system;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/generated/app_localizations.dart';

/// System language is the single source of truth for Fetchy's locale —
/// there is no in-app language switcher. [resolveLocale] matches on
/// language code only (e.g. any `ar-*` device locale, not just an exact
/// `ar-SA`), and always falls back to English for anything unsupported, so
/// a missing/partial Arabic string can never render as blank — see
/// [AppLocalizations]'s generated fallback behavior, which does the same
/// per-string.
class LocalizationConfig {
  const LocalizationConfig._();

  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  static const Locale fallbackLocale = english;

  static const List<Locale> supportedLocales = <Locale>[english, arabic];

  static const List<LocalizationsDelegate<dynamic>> delegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  /// Matches by language code alone (`ar-SA`, `ar-AE`, `ar-EG`, ... all
  /// resolve to `ar`) rather than requiring an exact locale match, per the
  /// requirement that every Arabic-language device gets Arabic regardless
  /// of country/region subtag.
  static Locale resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supported,
  ) {
    if (deviceLocale != null) {
      for (final Locale locale in supported) {
        if (locale.languageCode == deviceLocale.languageCode) {
          return locale;
        }
      }
    }
    return fallbackLocale;
  }
}

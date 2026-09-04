import 'package:flutter/services.dart';

import '../../core/platform/platform_channels.dart';
import '../../l10n/generated/app_localizations.dart';
import 'custom_cookie_site.dart';
import 'session_service.dart' show InvalidCookieFileError;

/// The Dart-side gateway to the native General Cookie Manager (arbitrary
/// custom-site cookies) — the same "app.fetchy/sessions" channel and the
/// same encrypted, on-device-only storage model as [SessionService], just
/// keyed by domain instead of a fixed platform. This never reads or
/// transmits cookie values itself; it only asks native to import/list/
/// remove them.
class CustomCookieService {
  CustomCookieService._();

  static final CustomCookieService instance = CustomCookieService._();

  Future<List<CustomCookieSite>> listSites() async {
    final List<Object?>? result = await PlatformChannels.sessionsChannel
        .invokeListMethod<Object?>(PlatformChannels.sessionsListCustomCookieSites);

    return (result ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(CustomCookieSite.fromMap)
        .toList(growable: false);
  }

  /// Opens the system file picker for a cookies.txt export and imports it
  /// for [domain] if the user picks one — accepts free-form input like
  /// "example.com" or "https://example.com/path"; normalization happens
  /// natively. Returns null if the user canceled the picker, which is not
  /// an error.
  Future<CustomCookieSite?> pickAndImportCookiesFile(
    String domain,
    AppLocalizations strings,
  ) async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.sessionsChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.sessionsPickAndImportCustomCookiesFile,
            <String, Object?>{'domain': domain},
          );
      if (result == null) return null; // user canceled
      return CustomCookieSite.fromMap(result);
    } on PlatformException catch (error) {
      throw _mapError(error, strings);
    }
  }

  /// Imports pasted cookie text (the same Netscape cookies.txt format the
  /// file import expects — see `NetscapeCookieFile`) for [domain]. Throws
  /// [InvalidCookieFileError] with a user-facing message when the text
  /// doesn't parse or nothing relevant to [domain] survives filtering —
  /// malformed input is never saved silently.
  Future<CustomCookieSite> importCookiesText({
    required String domain,
    required String cookiesText,
    required AppLocalizations strings,
  }) async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels.sessionsChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.sessionsImportCustomCookiesText,
            <String, Object?>{'domain': domain, 'cookiesText': cookiesText},
          );
      return CustomCookieSite.fromMap(result ?? const <Object?, Object?>{});
    } on PlatformException catch (error) {
      throw _mapError(error, strings);
    }
  }

  Future<void> removeSite(String domain) {
    return PlatformChannels.sessionsChannel.invokeMethod<void>(
      PlatformChannels.sessionsRemoveCustomCookieSite,
      <String, Object?>{'domain': domain},
    );
  }

  /// Native error messages here are English-only diagnostic prose (see
  /// `SessionsChannelHandler.kt`), so the code — not [error.message] — is
  /// what decides which localized text the user actually sees.
  Exception _mapError(PlatformException error, AppLocalizations strings) {
    if (error.code == 'invalid_domain') {
      return InvalidCookieFileError(strings.watchedDomainsInvalidDomain);
    }
    if (error.code == 'invalid_cookie_file') {
      return InvalidCookieFileError(strings.sessionsCustomCookieInvalid);
    }
    return error;
  }
}

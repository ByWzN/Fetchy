import 'package:flutter/services.dart';

import '../../core/engine/downloader_engine.dart';
import '../../core/platform/platform_channels.dart';
import '../../l10n/generated/app_localizations.dart';
import '../downloader/extraction_error_mapper.dart';
import '../downloader/extraction_error_presentation.dart';
import 'platform_session.dart';

/// Thrown when a picked file isn't a usable cookies export for the
/// requested platform. [message] is safe to show directly to the user.
class InvalidCookieFileError implements Exception {
  const InvalidCookieFileError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The Dart-side gateway to the native Connected Accounts/Sessions store.
/// Every session lives on-device only — there is no Fetchy backend to send
/// any of this to, and this class never reads or transmits cookie values
/// itself; it only asks native to import/list/remove them.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  Future<SessionConnectCapabilities> getCapabilities() async {
    final Map<Object?, Object?>? result = await PlatformChannels.sessionsChannel
        .invokeMapMethod<Object?, Object?>(
          PlatformChannels.sessionsGetCapabilities,
        );
    return SessionConnectCapabilities.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<List<PlatformSession>> listSessions() async {
    final List<Object?>? result = await PlatformChannels.sessionsChannel
        .invokeListMethod<Object?>(PlatformChannels.sessionsListSessions);

    return (result ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(PlatformSession.fromMap)
        .toList(growable: false);
  }

  /// Opens the system file picker for a cookies.txt export, and imports it
  /// for [platform] if the user picks one. Returns null if the user
  /// canceled the picker — that is not an error.
  Future<PlatformSession?> pickAndImportCookiesFile(
    SessionPlatform platform,
    AppLocalizations strings,
  ) async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels
          .sessionsChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.sessionsPickAndImportCookiesFile,
            <String, Object?>{'platform': platform.id},
          );
      if (result == null) return null; // user canceled
      return PlatformSession.fromMap(result);
    } on PlatformException catch (error) {
      // Native error messages here are English-only diagnostic prose (see
      // `SessionsChannelHandler.kt`), so the code decides the localized
      // text the user sees rather than [error.message].
      if (error.code == 'invalid_cookie_file') {
        throw InvalidCookieFileError(strings.sessionsCookieFileInvalid);
      }
      rethrow;
    }
  }

  /// Starts Easy Connect for [platform]. Which mechanism actually runs is
  /// decided natively per platform, based on real-device evidence (see
  /// native `SessionsChannelHandler`'s class doc comment):
  ///
  ///  - YouTube, Instagram, TikTok: an embedded WebView that genuinely
  ///    captures a usable session via cookies — confirmed working for
  ///    YouTube/Instagram, with TikTok's non-http(s) login redirect
  ///    handled safely. A non-null return means a real session was
  ///    captured and stored, exactly as if it had been imported via
  ///    Advanced.
  ///  - X: a Custom Tab (real browser). X actively rejects embedded-
  ///    browser login, mirroring Google's own policy of blocking OAuth-
  ///    style sign-in in WebViews to prevent credential theft — a
  ///    deliberate security control Fetchy does not attempt to defeat.
  ///    A Custom Tab cannot hand a session back to Fetchy at all, so this
  ///    always returns null for X regardless of what happens in the
  ///    browser.
  ///
  /// Callers must not assume success from a null return being absent —
  /// check the actual value: null means no usable session was captured
  /// (show "use Advanced" guidance); non-null means a real session now
  /// exists and Advanced is unnecessary.
  Future<PlatformSession?> openBrowserLogin(SessionPlatform platform) async {
    final Map<Object?, Object?>? result = await PlatformChannels.sessionsChannel
        .invokeMapMethod<Object?, Object?>(
          PlatformChannels.sessionsOpenBrowserLogin,
          <String, Object?>{'platform': platform.id},
        );
    if (result == null) return null;
    return PlatformSession.fromMap(result);
  }

  Future<PlatformSession> _recordValidationResult(
    SessionPlatform platform,
    SessionStatus status,
  ) async {
    final Map<Object?, Object?>? result = await PlatformChannels.sessionsChannel
        .invokeMapMethod<Object?, Object?>(
          PlatformChannels.sessionsRecordValidationResult,
          <String, Object?>{'platform': platform.id, 'status': status.wireValue},
        );
    return PlatformSession.fromMap(result ?? const <Object?, Object?>{});
  }

  /// Opens the "save file" picker and writes the raw stored session for
  /// [platform] to wherever the user chooses. Never picks a location (such
  /// as public Downloads) on its own — the user always chooses, and the
  /// warning dialog is shown by the caller before this is ever invoked.
  /// Returns false if the user canceled the picker.
  Future<bool> exportSession(SessionPlatform platform) async {
    final bool? result = await PlatformChannels.sessionsChannel.invokeMethod<bool>(
      PlatformChannels.sessionsExportSession,
      <String, Object?>{'platform': platform.id},
    );
    return result ?? false;
  }

  Future<void> removeSession(SessionPlatform platform) {
    return PlatformChannels.sessionsChannel.invokeMethod<void>(
      PlatformChannels.sessionsRemoveSession,
      <String, Object?>{'platform': platform.id},
    );
  }

  /// Runs a lightweight, real extraction (info only, no download) against
  /// [url] using the platform's existing engine pipeline — which, per
  /// Phase 2, automatically attaches [platform]'s stored cookies since
  /// [url] belongs to it. No second downloader, no duplicate yt-dlp
  /// invocation: this is the exact same call Home/MediaPreview make.
  ///
  /// A genuine success here — the session was actually attached and the
  /// extraction went through — is real, scoped evidence: it means
  /// [SessionStatus.sessionUsable], reported as "Session works for this
  /// test." That is deliberately narrower than "Session is valid
  /// everywhere": this one request succeeding says nothing about every
  /// other video on the platform, some of which may be public anyway. A
  /// genuine negative signal (the extraction hits an auth wall with the
  /// session attached) is recorded as [SessionStatus.sessionExpired] or
  /// [SessionStatus.sessionInvalid]; anything inconclusive (network error,
  /// ambiguous response) stays [SessionStatus.unknown] rather than
  /// guessing either way.
  Future<TestConnectionResult> testConnection(
    SessionPlatform platform,
    String url,
    AppLocalizations strings,
  ) async {
    try {
      await PlatformDownloaderEngine.instance.extract(url);
      final PlatformSession session = await _recordValidationResult(
        platform,
        SessionStatus.sessionUsable,
      );
      return TestConnectionResult(
        session: session,
        message: strings.sessionsTestWorks,
      );
    } on EngineException catch (error) {
      final MappedExtractionError mapped = ExtractionErrorMapper.map(
        error.message,
        platform: platform.displayName,
        hasSession: true,
      );

      final SessionStatus resolved = switch (mapped.kind) {
        ExtractionFailureKind.sessionExpired => SessionStatus.sessionExpired,
        ExtractionFailureKind.sessionInvalid => SessionStatus.sessionInvalid,
        ExtractionFailureKind.authRequired => SessionStatus.sessionInvalid,
        _ => SessionStatus.unknown,
      };

      final PlatformSession session = await _recordValidationResult(
        platform,
        resolved,
      );

      final String localizedMessage = extractionMessageFor(
        mapped,
        strings,
        platform: platform.displayName,
      );
      return TestConnectionResult(
        session: session,
        message: resolved == SessionStatus.unknown
            ? strings.sessionsTestStatusUnverified(localizedMessage)
            : localizedMessage,
      );
    }
  }
}

class TestConnectionResult {
  const TestConnectionResult({required this.session, required this.message});

  final PlatformSession session;
  final String message;
}

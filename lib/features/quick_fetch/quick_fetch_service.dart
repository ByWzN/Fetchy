import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/platform/platform_channels.dart';
import '../../core/settings/app_settings_service.dart';
import 'quick_fetch_models.dart';

/// The outcome of acting on a quick-action tap.
sealed class QuickFetchTapResult {
  const QuickFetchTapResult();
}

/// The clipboard held a supported link; route straight to the media preview.
final class QuickFetchLinkReady extends QuickFetchTapResult {
  const QuickFetchLinkReady(this.url);

  final String url;
}

/// The clipboard held nothing usable. Expected and harmless: accessibility
/// detection can produce false positives, and the user may have copied
/// something else since.
final class QuickFetchNoLink extends QuickFetchTapResult {
  const QuickFetchNoLink();
}

/// The Dart face of Quick Fetch.
///
/// Owns the dedicated `app.fetchy/quickfetch` channel and nothing else. It
/// never starts a download and never touches the downloader channel — its only
/// job is to turn a quick-action tap into a validated URL for the existing
/// extraction flow.
class QuickFetchService {
  QuickFetchService._();

  static final QuickFetchService instance = QuickFetchService._();

  final StreamController<QuickFetchTapResult> _tapsController =
      StreamController<QuickFetchTapResult>.broadcast();

  bool _isStarted = false;

  /// Emits once per quick-action tap, after the clipboard has been read.
  Stream<QuickFetchTapResult> get taps => _tapsController.stream;

  void start() {
    if (_isStarted) return;
    _isStarted = true;
    PlatformChannels.quickFetchChannel.setMethodCallHandler(_handleCall);
  }

  /// Native tells us the user tapped and the Activity now holds window focus.
  /// Only at that point is the clipboard read — the platform would return null
  /// otherwise on Android 10+, and reading earlier would be a privacy leak.
  Future<void> _handleCall(MethodCall call) async {
    if (call.method != PlatformChannels.onQuickFetchTap) return;
    if (_tapsController.isClosed) return;

    _tapsController.add(await consumeClipboardLink());
  }

  /// Performs the single post-tap clipboard read and applies the stage-2
  /// watched-domain check. The check itself always asks native (see
  /// [isWatchedUrl]) rather than keeping a local copy of the list: the
  /// effective list is fully user-editable now, so a local Dart copy could
  /// drift out of sync the moment the user edits it in Settings.
  Future<QuickFetchTapResult> consumeClipboardLink() async {
    final String? url = await _invoke<String>(
      PlatformChannels.quickFetchConsumeClipboardLink,
    );

    final String trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return const QuickFetchNoLink();

    // Re-validate here too: a URL should never reach extraction merely
    // because it arrived over a channel.
    if (await isWatchedUrl(trimmed)) return QuickFetchLinkReady(trimmed);

    return const QuickFetchNoLink();
  }

  // ------------------------------------------------------- Link Auto-Detect

  /// The current effective watched-domain list, as raw editable text — one
  /// domain per line, exactly as Settings shows and saves it back.
  Future<String> getWatchedDomainsText() async {
    return await _invoke<String>(PlatformChannels.quickFetchGetWatchedDomainsText) ?? '';
  }

  /// Replaces the whole list from free-form multi-line text. Each
  /// non-blank line is normalized independently natively; a line that
  /// doesn't resolve to a real domain is silently dropped. Returns the
  /// canonicalized text actually stored, so the caller can refresh its
  /// editor to match exactly what was saved.
  Future<String> setWatchedDomainsText(String text) async {
    return await _invoke<String>(
          PlatformChannels.quickFetchSetWatchedDomainsText,
          <String, Object?>{'text': text},
        ) ??
        text;
  }

  /// Restores the built-in defaults, discarding user edits. Returns the
  /// restored text.
  Future<String> resetWatchedDomainsToDefault() async {
    return await _invoke<String>(PlatformChannels.quickFetchResetWatchedDomains) ?? '';
  }

  Future<bool> isWatchedUrl(String url) async {
    return await _invoke<bool>(
          PlatformChannels.quickFetchIsWatchedUrl,
          <String, Object?>{'url': url},
        ) ??
        false;
  }

  Future<QuickFetchCapabilities> capabilities() async {
    final Map<Object?, Object?>? result = await _invokeMap(
      PlatformChannels.quickFetchGetCapabilities,
    );
    if (result == null) return QuickFetchCapabilities.unavailable;
    return QuickFetchCapabilities.fromMap(result);
  }

  /// Turns the feature on or off. Returns the resulting platform state so the
  /// UI reflects what actually happened rather than what was requested.
  Future<QuickFetchCapabilities> setEnabled({
    required bool enabled,
    required QuickFetchActionStyle actionStyle,
  }) async {
    final Map<Object?, Object?>? result = await _invokeMap(
      PlatformChannels.quickFetchSetEnabled,
      <String, Object?>{
        'enabled': enabled,
        'actionStyle': actionStyle.wireName,
      },
    );
    if (result == null) return QuickFetchCapabilities.unavailable;
    return QuickFetchCapabilities.fromMap(result);
  }

  Future<QuickFetchCapabilities> setActionStyle(
    QuickFetchActionStyle actionStyle,
  ) async {
    final Map<Object?, Object?>? result = await _invokeMap(
      PlatformChannels.quickFetchSetActionStyle,
      <String, Object?>{'actionStyle': actionStyle.wireName},
    );
    if (result == null) return QuickFetchCapabilities.unavailable;
    return QuickFetchCapabilities.fromMap(result);
  }

  /// Asks for POST_NOTIFICATIONS. The grant is not returned directly — the
  /// caller should re-read [capabilities] once the app resumes.
  Future<bool> requestNotificationPermission() async {
    return await _invoke<bool>(
          PlatformChannels.quickFetchRequestNotificationPermission,
        ) ??
        false;
  }

  Future<bool> openOverlaySettings() async =>
      await _invoke<bool>(PlatformChannels.quickFetchOpenOverlaySettings) ??
      false;

  Future<bool> openNotificationSettings() async =>
      await _invoke<bool>(PlatformChannels.quickFetchOpenNotificationSettings) ??
      false;

  /// Opens Android's Accessibility settings so the user can switch the
  /// background copy detector on.
  Future<bool> openAccessibilitySettings() async =>
      await _invoke<bool>(
        PlatformChannels.quickFetchOpenAccessibilitySettings,
      ) ??
      false;

  /// Stands the feature down while it is held back from a release (see
  /// [QuickFetchAvailability]).
  ///
  /// Clears any stored "on" state and tears down any surface left behind, so
  /// a device that had Quick Fetch switched on in an earlier build does not
  /// keep producing notifications or a floating dot. The implementation
  /// itself is untouched — this only turns it off.
  Future<void> disableForUnavailableFeature() async {
    await setEnabled(
      enabled: false,
      actionStyle: QuickFetchActionStyle.notification,
    );
    await AppSettingsService.instance.saveQuickFetchEnabled(false);
    await dismissPending();
  }

  /// Opens Fetchy's App Info screen. On Android 13+ that is where a
  /// sideloaded app's "Allow restricted settings" action lives, when the
  /// device shows one — Fetchy can only take the user there and explain,
  /// never grant it.
  Future<bool> openAppInfoSettings() async =>
      await _invoke<bool>(PlatformChannels.quickFetchOpenAppInfoSettings) ??
      false;

  /// Clears any pending notification / floating dot.
  Future<void> dismissPending() async {
    await _invoke<void>(PlatformChannels.quickFetchDismissPending);
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await PlatformChannels.quickFetchChannel.invokeMethod<T>(
        method,
        arguments,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<Map<Object?, Object?>?> _invokeMap(
    String method, [
    Object? arguments,
  ]) async {
    try {
      return await PlatformChannels.quickFetchChannel
          .invokeMapMethod<Object?, Object?>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> dispose() async {
    PlatformChannels.quickFetchChannel.setMethodCallHandler(null);
    _isStarted = false;
    await _tapsController.close();
  }
}

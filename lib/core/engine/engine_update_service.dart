import 'package:flutter/services.dart';

import '../platform/platform_channels.dart';

/// The outcome of a completed (non-throwing) update attempt.
enum EngineUpdateResultKind {
  /// A newer yt-dlp binary was installed and its version was verified.
  updated,

  /// No update was needed; the existing binary was already current.
  alreadyUpToDate,

  /// The update mechanism did not report a failure, but the runtime
  /// version could not be re-verified afterward — never shown to the user
  /// as a version change, since that would risk displaying a version that
  /// isn't actually what's installed.
  verificationFailed,
}

class EngineUpdateResult {
  const EngineUpdateResult({required this.kind, this.version});

  final EngineUpdateResultKind kind;

  /// The verified installed version, present for [EngineUpdateResultKind.
  /// updated] and [EngineUpdateResultKind.alreadyUpToDate]; always null for
  /// [EngineUpdateResultKind.verificationFailed].
  final String? version;
}

/// A plain-language update failure — never a raw stack trace. The native
/// side already reduces the real exception to a short message before this
/// is thrown.
class EngineUpdateFailure implements Exception {
  const EngineUpdateFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The single source of truth for the active yt-dlp runtime version, and
/// the single place that triggers a manual update.
///
/// Both the Settings "yt-dlp Engine" row and Technical information's
/// Engine section read the version through this service, and a manual
/// update from Settings runs through the exact same native methods
/// (`getYtDlpVersion`/`updateYtDlp` on the existing engine channel,
/// `EngineChannelHandler` on the Kotlin side) that the automatic update at
/// app startup already uses — there is no second updater and no second
/// version source.
class EngineUpdateService {
  EngineUpdateService._();

  static final EngineUpdateService instance = EngineUpdateService._();

  /// The actual installed runtime version, verified natively by running
  /// `yt-dlp --version` — never a value merely remembered from a past
  /// update. Returns null when it could not be determined (e.g. the
  /// engine has not finished initializing yet, or the probe failed);
  /// callers should show that as "unknown", not as an error.
  ///
  /// Calling this does not start engine initialization — it waits on
  /// whatever warm-up already began at app startup, exactly like every
  /// other caller of this native method.
  Future<String?> getVersion() async {
    try {
      return await PlatformChannels.engineChannel.invokeMethod<String>(
        PlatformChannels.getYtDlpVersion,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Runs the same runtime update mechanism used automatically at app
  /// startup (same `UpdateChannel`, same underlying `YoutubeDL` instance),
  /// then re-reads the real installed version afterward rather than
  /// trusting whatever the update call claims. Throws
  /// [EngineUpdateFailure] with a short, plain-language message on
  /// failure; a failed update never modifies the previously working
  /// runtime.
  Future<EngineUpdateResult> update() async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels
          .engineChannel
          .invokeMapMethod<Object?, Object?>(PlatformChannels.updateYtDlp);

      final String? status = result?['status'] as String?;
      final String? version = result?['version'] as String?;

      if (version == null) {
        return const EngineUpdateResult(
          kind: EngineUpdateResultKind.verificationFailed,
        );
      }
      return EngineUpdateResult(
        kind: status == 'ALREADY_UP_TO_DATE'
            ? EngineUpdateResultKind.alreadyUpToDate
            : EngineUpdateResultKind.updated,
        version: version,
      );
    } on MissingPluginException {
      throw const EngineUpdateFailure(
        'Native engine is not registered on this build.',
      );
    } on PlatformException catch (error) {
      throw EngineUpdateFailure(error.message ?? 'Failed to update yt-dlp.');
    }
  }
}

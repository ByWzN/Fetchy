import 'dart:async';

import 'package:flutter/services.dart';

import '../platform/platform_channels.dart';
import 'app_version.dart';

/// Progress of the APK download, in bytes. [totalBytes] is null when the
/// server did not declare a length, in which case the UI shows an
/// indeterminate bar rather than inventing a percentage.
class UpdateDownloadProgress {
  const UpdateDownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final int? total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

/// Why an update could not be downloaded or handed to the installer.
enum UpdateInstallFailure {
  /// The APK is for a different application id. Never installed.
  packageMismatch,

  /// The APK's versionCode is not greater than what is installed. This is
  /// the final monotonic gate — Android would reject a downgrade anyway,
  /// but the user gets a clear reason instead of a system error.
  notNewer,

  /// The APK is signed with a different key than the installed app, so
  /// Android would refuse the update. Signature verification is never
  /// bypassed; this only reports the mismatch early.
  signatureMismatch,

  /// The downloaded file could not be read as an APK at all.
  corruptDownload,

  /// "Install unknown apps" is not granted for Fetchy.
  permissionRequired,

  downloadFailed,
  canceled,
  unknown,
}

class UpdateInstallException implements Exception {
  const UpdateInstallException(this.failure, [this.detail]);

  final UpdateInstallFailure failure;

  /// Native's own short message, used only for logging/diagnostics — the UI
  /// shows a localized string chosen from [failure].
  final String? detail;

  @override
  String toString() => 'UpdateInstallException(${failure.name})';
}

/// Everything about the update that only Android can answer or do: this
/// build's real version, whether Fetchy may request package installs,
/// downloading the APK into app-private cache, and launching the system
/// package installer.
///
/// Abstract so `UpdateService` and the UI can be tested without a device.
abstract class UpdateInstaller {
  /// This build's own `versionName`/`versionCode`/`packageName`, straight
  /// from Android's PackageManager — never a constant compiled into Dart.
  Future<InstalledAppVersion?> installedVersion();

  /// Whether Android currently lets Fetchy request a package install.
  /// Always true below Android 8, where the setting is device-wide.
  Future<bool> canRequestPackageInstalls();

  /// Opens the system screen where the user grants "install unknown apps"
  /// for Fetchy. Returns false when no such screen could be opened.
  Future<bool> openInstallPermissionSettings();

  /// Downloads [url] into app-private cache and returns the local path.
  /// Progress is reported through [downloadProgress].
  Future<String> downloadApk({
    required String url,
    required String fileName,
    int? expectedSizeBytes,
  });

  Stream<UpdateDownloadProgress> get downloadProgress;

  Future<void> cancelDownload();

  /// Verifies the downloaded APK really is a newer, identically-signed
  /// build of *this* app, then launches Android's package installer so the
  /// user can confirm. Never installs anything silently.
  Future<void> verifyAndLaunchInstaller(String filePath);
}

class PlatformUpdateInstaller implements UpdateInstaller {
  PlatformUpdateInstaller._();

  static final PlatformUpdateInstaller instance = PlatformUpdateInstaller._();

  final StreamController<UpdateDownloadProgress> _progress =
      StreamController<UpdateDownloadProgress>.broadcast();

  bool _handlerInstalled = false;

  @override
  Stream<UpdateDownloadProgress> get downloadProgress {
    _ensureHandlerInstalled();
    return _progress.stream;
  }

  void _ensureHandlerInstalled() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    PlatformChannels.appUpdateChannel.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != PlatformChannels.appUpdateOnDownloadProgress) return;
    final Object? arguments = call.arguments;
    if (arguments is! Map<Object?, Object?>) return;
    if (_progress.isClosed) return;

    final int? received = (arguments['receivedBytes'] as num?)?.toInt();
    if (received == null) return;
    final int? total = (arguments['totalBytes'] as num?)?.toInt();

    _progress.add(
      UpdateDownloadProgress(
        receivedBytes: received,
        totalBytes: (total == null || total <= 0) ? null : total,
      ),
    );
  }

  @override
  Future<InstalledAppVersion?> installedVersion() async {
    try {
      final Map<Object?, Object?>? result = await PlatformChannels
          .appUpdateChannel
          .invokeMapMethod<Object?, Object?>(
            PlatformChannels.appUpdateGetInstalledVersion,
          );
      if (result == null) return null;
      return InstalledAppVersion.fromMap(result);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    try {
      final bool? allowed = await PlatformChannels.appUpdateChannel
          .invokeMethod<bool>(PlatformChannels.appUpdateCanRequestInstalls);
      return allowed ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    try {
      final bool? opened = await PlatformChannels.appUpdateChannel
          .invokeMethod<bool>(PlatformChannels.appUpdateOpenInstallSettings);
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String> downloadApk({
    required String url,
    required String fileName,
    int? expectedSizeBytes,
  }) async {
    _ensureHandlerInstalled();

    try {
      final String? path = await PlatformChannels.appUpdateChannel
          .invokeMethod<String>(PlatformChannels.appUpdateDownload, <String,
              Object?>{
            'url': url,
            'fileName': fileName,
            'expectedSizeBytes': expectedSizeBytes,
          });
      if (path == null || path.isEmpty) {
        throw const UpdateInstallException(UpdateInstallFailure.downloadFailed);
      }
      return path;
    } on MissingPluginException {
      throw const UpdateInstallException(UpdateInstallFailure.unknown);
    } on PlatformException catch (error) {
      throw UpdateInstallException(_failureFrom(error.code), error.message);
    }
  }

  @override
  Future<void> cancelDownload() async {
    try {
      await PlatformChannels.appUpdateChannel.invokeMethod<void>(
        PlatformChannels.appUpdateCancelDownload,
      );
    } on MissingPluginException {
      // Nothing was running.
    } on PlatformException {
      // Cancellation is best-effort by design.
    }
  }

  @override
  Future<void> verifyAndLaunchInstaller(String filePath) async {
    try {
      await PlatformChannels.appUpdateChannel.invokeMethod<void>(
        PlatformChannels.appUpdateInstall,
        <String, Object?>{'path': filePath},
      );
    } on MissingPluginException {
      throw const UpdateInstallException(UpdateInstallFailure.unknown);
    } on PlatformException catch (error) {
      throw UpdateInstallException(_failureFrom(error.code), error.message);
    }
  }

  static UpdateInstallFailure _failureFrom(String code) {
    switch (code) {
      case 'package_mismatch':
        return UpdateInstallFailure.packageMismatch;
      case 'not_newer':
        return UpdateInstallFailure.notNewer;
      case 'signature_mismatch':
        return UpdateInstallFailure.signatureMismatch;
      case 'corrupt_download':
        return UpdateInstallFailure.corruptDownload;
      case 'permission_required':
        return UpdateInstallFailure.permissionRequired;
      case 'download_failed':
        return UpdateInstallFailure.downloadFailed;
      case 'canceled':
        return UpdateInstallFailure.canceled;
      default:
        return UpdateInstallFailure.unknown;
    }
  }
}

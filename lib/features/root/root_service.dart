import '../../core/platform/platform_channels.dart';
import 'root_status.dart';

/// The Dart-side gateway to native root-capability detection. Every method
/// here is only ever called from an explicit user action on the Advanced/
/// Root Features settings page — never from app startup, and never as a
/// side effect of anything else.
class RootService {
  RootService._();

  static final RootService instance = RootService._();

  /// Returns the last-recorded status without ever invoking `su` — safe to
  /// call when the settings page opens, since it cannot trigger a root
  /// grant prompt by itself.
  Future<RootStatus> getStatus() async {
    final String? status = await PlatformChannels.rootChannel.invokeMethod<String>(
      PlatformChannels.rootGetStatus,
    );
    return rootStatusFromWire(status);
  }

  /// Actually attempts `su` — this is what can trigger the device's root
  /// manager (Magisk/KernelSU/etc.) grant prompt. Only call this after the
  /// user has seen and accepted the root safety warning.
  Future<RootStatus> enable() async {
    final String? status = await PlatformChannels.rootChannel.invokeMethod<String>(
      PlatformChannels.rootEnable,
    );
    return rootStatusFromWire(status);
  }
}

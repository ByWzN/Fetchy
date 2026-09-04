/// How a detected link is offered to the user.
enum QuickFetchActionStyle {
  /// A standard Android notification with a Download action.
  notification,

  /// A small draggable circle floating above other apps.
  floatingDot;

  String get wireName => switch (this) {
    QuickFetchActionStyle.notification => 'notification',
    QuickFetchActionStyle.floatingDot => 'floatingDot',
  };

  String get label => switch (this) {
    QuickFetchActionStyle.notification => 'Notification',
    QuickFetchActionStyle.floatingDot => 'Floating dot',
  };

  static QuickFetchActionStyle fromWireName(String? raw) {
    return raw == 'floatingDot'
        ? QuickFetchActionStyle.floatingDot
        : QuickFetchActionStyle.notification;
  }
}

/// An honest snapshot of what Quick Fetch can actually do on this device,
/// reported by the platform rather than assumed by the UI.
class QuickFetchCapabilities {
  const QuickFetchCapabilities({
    required this.sdkInt,
    required this.enabled,
    required this.actionStyle,
    required this.accessibilityEnabled,
    required this.accessibilityConnected,
    required this.canPostNotifications,
    required this.needsNotificationPermission,
    required this.canDrawOverlays,
    required this.hasPendingCandidate,
    this.available = true,
  });

  /// The state used before the platform has answered, and on any non-Android
  /// host where the native layer does not exist.
  static const QuickFetchCapabilities unavailable = QuickFetchCapabilities(
    sdkInt: 0,
    enabled: false,
    actionStyle: QuickFetchActionStyle.notification,
    accessibilityEnabled: false,
    accessibilityConnected: false,
    canPostNotifications: false,
    needsNotificationPermission: false,
    canDrawOverlays: false,
    hasPendingCandidate: false,
    available: false,
  );

  final int sdkInt;
  final bool enabled;
  final QuickFetchActionStyle actionStyle;

  /// Whether the user switched Fetchy's detector on in Android > Accessibility.
  final bool accessibilityEnabled;

  /// Whether the platform has actually bound the detector right now.
  final bool accessibilityConnected;

  final bool canPostNotifications;

  /// True on Android 13+, where POST_NOTIFICATIONS is a runtime grant.
  final bool needsNotificationPermission;

  final bool canDrawOverlays;

  /// True while a detected copy is waiting for the user to act on it.
  final bool hasPendingCandidate;

  /// False when the native Quick Fetch layer is not present at all.
  final bool available;

  /// Whether the currently selected style can actually surface a link.
  bool get selectedStyleReady => switch (actionStyle) {
    QuickFetchActionStyle.notification => canPostNotifications,
    QuickFetchActionStyle.floatingDot => canDrawOverlays,
  };

  /// Background detection only works when the accessibility detector is both
  /// switched on and bound. Everything else still works without it — the user
  /// can share a link or paste one on Home.
  bool get backgroundDetectionReady =>
      accessibilityEnabled && accessibilityConnected;

  /// The feature is fully operational end to end.
  bool get fullyReady => enabled && backgroundDetectionReady && selectedStyleReady;

  static QuickFetchCapabilities fromMap(Map<Object?, Object?> map) {
    return QuickFetchCapabilities(
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      enabled: map['enabled'] as bool? ?? false,
      actionStyle: QuickFetchActionStyle.fromWireName(
        map['actionStyle'] as String?,
      ),
      accessibilityEnabled: map['accessibilityEnabled'] as bool? ?? false,
      accessibilityConnected: map['accessibilityConnected'] as bool? ?? false,
      canPostNotifications: map['canPostNotifications'] as bool? ?? false,
      needsNotificationPermission:
          map['needsNotificationPermission'] as bool? ?? false,
      canDrawOverlays: map['canDrawOverlays'] as bool? ?? false,
      hasPendingCandidate: map['hasPendingCandidate'] as bool? ?? false,
    );
  }
}

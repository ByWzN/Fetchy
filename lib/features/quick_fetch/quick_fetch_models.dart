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

/// How this copy of Fetchy was installed, as reported by Android's public
/// `PackageManager.getInstallSourceInfo`.
///
/// Used for **wording only** — to decide whether the setup screen mentions
/// Android's extra security step for apps installed from an APK file. It
/// never affects what Fetchy requests or is allowed to do, and an installer
/// package is never treated as trustworthy merely because of its name.
enum QuickFetchInstallSource {
  /// Installed by an app store that performs its own installs.
  store,

  /// Installed from an APK file — the case where Android 13+ may apply
  /// Restricted Settings to the accessibility toggle.
  sideload,

  /// A recognized installer that is neither of the above.
  other,

  /// Android could not tell us, or the API is unavailable on this version.
  /// The UI uses generic wording here rather than guessing.
  unknown;

  static QuickFetchInstallSource fromWireName(String? raw) => switch (raw) {
    'store' => QuickFetchInstallSource.store,
    'sideload' => QuickFetchInstallSource.sideload,
    'other' => QuickFetchInstallSource.other,
    _ => QuickFetchInstallSource.unknown,
  };

  /// Whether the setup screen should mention Android's Restricted Settings
  /// step. Shown for a known sideload, and also when the source is unknown —
  /// where generic wording is safer than silence.
  bool get mayNeedRestrictedSettingsStep =>
      this == QuickFetchInstallSource.sideload ||
      this == QuickFetchInstallSource.unknown;
}

/// What the app can honestly say about background detection right now.
///
/// Deliberately only two states. Android tells us whether our accessibility
/// service is enabled; it does **not** tell us *why* it isn't — "the user
/// hasn't turned it on yet" and "Restricted Settings blocked the toggle"
/// look identical from here, so no third state pretends otherwise.
enum QuickFetchSetupState {
  /// The service is enabled and the platform has bound it.
  ready,

  /// The service is not currently active. The reason is not knowable.
  notEnabled,
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
    this.installSource = QuickFetchInstallSource.unknown,
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

  /// How Fetchy was installed. Guidance wording only.
  final QuickFetchInstallSource installSource;

  /// False when the native Quick Fetch layer is not present at all.
  final bool available;

  /// The two-state answer the platform can actually support — see
  /// [QuickFetchSetupState].
  QuickFetchSetupState get setupState => backgroundDetectionReady
      ? QuickFetchSetupState.ready
      : QuickFetchSetupState.notEnabled;

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
      installSource: QuickFetchInstallSource.fromWireName(
        map['installSource'] as String?,
      ),
    );
  }
}

/// ============================================================================
/// THE SINGLE SWITCH THAT DECIDES WHETHER QUICK FETCH SHIPS.
///
/// Quick Fetch's implementation is complete and still present in the project —
/// the Dart service, the settings screens, the platform channel, and the
/// Android AccessibilityService are all untouched. It is held back from this
/// release only because automatic copy detection is not yet reliable enough
/// across Android versions and OEM builds to put in front of users.
///
/// While [isAvailable] is false:
///   - the Settings entry stays visible, but reads "Coming soon" and has no
///     switch to toggle,
///   - the Quick Fetch screen shows an "under development" state instead of
///     its controls,
///   - nothing asks the user to grant Accessibility access,
///   - the detector is not started, and any stored "on" state left over from
///     an earlier build is cleared at startup.
///
/// TO RE-ENABLE: set [isAvailable] to true. Nothing else needs changing —
/// every screen and service reads this one flag.
/// ============================================================================
library;

class QuickFetchAvailability {
  const QuickFetchAvailability._();

  /// Whether Quick Fetch is offered to users in this build.
  static const bool isAvailable = false;
}

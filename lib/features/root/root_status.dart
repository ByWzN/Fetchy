/// Root capability state, as actually determined by attempting `su`
/// (see native `RootCapability.checkStatus`) — never inferred from the
/// mere presence of a file like `/system/xbin/su`.
enum RootStatus {
  /// `su` was invoked and granted; the device is genuinely rooted and
  /// Fetchy has been granted access.
  available,

  /// No root manager / `su` binary is reachable on this device.
  unavailable,

  /// A root manager exists but the user (or a prior policy) denied
  /// Fetchy's request.
  denied,

  /// Not yet checked, or the check was inconclusive.
  unknown,
}

RootStatus rootStatusFromWire(String? value) {
  switch (value) {
    case 'AVAILABLE':
      return RootStatus.available;
    case 'UNAVAILABLE':
      return RootStatus.unavailable;
    case 'DENIED':
      return RootStatus.denied;
    case 'UNKNOWN':
    default:
      return RootStatus.unknown;
  }
}

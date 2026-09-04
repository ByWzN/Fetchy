/// The platforms Connected Accounts/Sessions supports. Kept as a fixed,
/// generic list — the session manager itself does not special-case any one
/// platform's behavior.
enum SessionPlatform { youtube, tiktok, x, instagram }

extension SessionPlatformInfo on SessionPlatform {
  String get id {
    switch (this) {
      case SessionPlatform.youtube:
        return 'youtube';
      case SessionPlatform.tiktok:
        return 'tiktok';
      case SessionPlatform.x:
        return 'x';
      case SessionPlatform.instagram:
        return 'instagram';
    }
  }

  String get displayName {
    switch (this) {
      case SessionPlatform.youtube:
        return 'YouTube';
      case SessionPlatform.tiktok:
        return 'TikTok';
      case SessionPlatform.x:
        return 'X';
      case SessionPlatform.instagram:
        return 'Instagram';
    }
  }

  static SessionPlatform? fromId(String? id) {
    for (final SessionPlatform platform in SessionPlatform.values) {
      if (platform.id == id) return platform;
    }
    return null;
  }

  /// Matches `ExtractionErrorMapper.platformForUrl`'s output ("TikTok",
  /// "YouTube", "X", "Instagram") back to a [SessionPlatform] — used to
  /// decide whether a session exists for the platform an error came from.
  static SessionPlatform? fromDisplayName(String? name) {
    if (name == null) return null;
    for (final SessionPlatform platform in SessionPlatform.values) {
      if (platform.displayName == name) return platform;
    }
    return null;
  }
}

/// A session's trust state.
///
/// Importing a cookies file or completing Easy Connect produces
/// [sessionImported] — stored, but not yet proven to actually work. Test
/// Connection (see `SessionService.testConnection`) is what can move a
/// session further:
///  - a genuine successful extraction using this session → [sessionUsable]
///    ("Session works for this test" — never "Session is valid everywhere")
///  - a genuine auth-shaped failure with the session attached →
///    [sessionExpired] or [sessionInvalid]
///  - an inconclusive attempt (network error, ambiguous response) → stays
///    [unknown] rather than guessing either way
enum SessionStatus {
  notConnected,
  sessionImported,
  sessionUsable,
  sessionExpired,
  sessionInvalid,
  unknown,
}

SessionStatus _statusFromWire(String? value) {
  switch (value) {
    case 'SESSION_IMPORTED':
      return SessionStatus.sessionImported;
    case 'SESSION_USABLE':
      return SessionStatus.sessionUsable;
    case 'SESSION_EXPIRED':
      return SessionStatus.sessionExpired;
    case 'SESSION_INVALID':
      return SessionStatus.sessionInvalid;
    case 'UNKNOWN':
      return SessionStatus.unknown;
    case 'NOT_CONNECTED':
    default:
      return SessionStatus.notConnected;
  }
}

extension SessionStatusWire on SessionStatus {
  /// The wire value native's `recordValidationResult` expects.
  String get wireValue {
    switch (this) {
      case SessionStatus.sessionImported:
        return 'SESSION_IMPORTED';
      case SessionStatus.sessionUsable:
        return 'SESSION_USABLE';
      case SessionStatus.sessionExpired:
        return 'SESSION_EXPIRED';
      case SessionStatus.sessionInvalid:
        return 'SESSION_INVALID';
      case SessionStatus.unknown:
        return 'UNKNOWN';
      case SessionStatus.notConnected:
        return 'NOT_CONNECTED';
    }
  }
}

/// One platform's session record, as reported by the native encrypted
/// store. Never carries cookie values — only status and non-sensitive
/// metadata (a domain/count summary), which is all the UI needs.
class PlatformSession {
  const PlatformSession({
    required this.platform,
    required this.status,
    this.createdAt,
    this.lastValidatedAt,
    this.metadata,
  });

  final SessionPlatform platform;
  final SessionStatus status;
  final DateTime? createdAt;
  final DateTime? lastValidatedAt;

  /// A short, human-readable, non-sensitive summary (e.g. cookie count and
  /// domains) — never the cookie values themselves.
  final String? metadata;

  /// True whenever *some* session is stored for this platform, regardless
  /// of its trust level — [SessionStatus.sessionExpired]/[sessionInvalid]/
  /// [unknown] still mean there is a session to show, test again, or
  /// remove; only [SessionStatus.notConnected] means nothing is stored.
  bool get isConnected => status != SessionStatus.notConnected;

  static PlatformSession fromMap(Map<Object?, Object?> map) {
    final SessionPlatform platform =
        SessionPlatformInfo.fromId(map['platform'] as String?) ??
        SessionPlatform.youtube;

    int? asMillis(Object? value) => (value as num?)?.toInt();

    return PlatformSession(
      platform: platform,
      status: _statusFromWire(map['status'] as String?),
      createdAt: _millisToDate(asMillis(map['createdAtMillis'])),
      lastValidatedAt: _millisToDate(asMillis(map['lastValidatedAtMillis'])),
      metadata: map['metadata'] as String?,
    );
  }

  static DateTime? _millisToDate(int? millis) =>
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

/// Which of the three connection levels are actually usable, detected from
/// the platform rather than assumed. A level being unavailable always comes
/// with a plain-language [reason] to show the user instead of hiding it.
class SessionConnectCapabilities {
  const SessionConnectCapabilities({
    required this.easy,
    this.easyReason,
    required this.advanced,
    this.advancedReason,
    required this.expert,
    this.expertReason,
  });

  final bool easy;
  final String? easyReason;
  final bool advanced;
  final String? advancedReason;
  final bool expert;
  final String? expertReason;

  static SessionConnectCapabilities fromMap(Map<Object?, Object?> map) {
    return SessionConnectCapabilities(
      easy: map['easy'] as bool? ?? false,
      easyReason: map['easyReason'] as String?,
      advanced: map['advanced'] as bool? ?? false,
      advancedReason: map['advancedReason'] as String?,
      expert: map['expert'] as bool? ?? false,
      expertReason: map['expertReason'] as String?,
    );
  }
}

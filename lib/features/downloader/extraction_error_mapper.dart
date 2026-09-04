/// What went wrong, in terms a user can act on.
///
/// This is Fetchy's central error-category engine: every extraction and
/// download failure is classified into exactly one of these, purely from
/// the engine's own stderr/exception text — never guessed from the
/// platform name alone (a platform hint only phrases the message, it never
/// decides the category).
enum ExtractionFailureKind {
  /// No session is connected for this platform, and the platform wants one.
  authRequired,

  /// A session IS connected for this platform, but the failure looks like
  /// the same auth wall — and the raw text specifically suggests the
  /// session has timed out rather than being simply wrong.
  sessionExpired,

  /// A session is connected, but the failure looks like an auth wall the
  /// session doesn't clear (and it doesn't specifically look like expiry).
  sessionInvalid,

  /// The content itself is restricted by platform policy — removed,
  /// geo-blocked, or taken down — not an authentication problem.
  platformRestricted,

  /// Generic bot-detection: rate limiting, CAPTCHA walls, "unusual
  /// traffic" — distinct from the specific impersonation case below.
  antiBot,

  /// The extractor needs browser TLS impersonation (curl_cffi) that this
  /// bundle does not have — an environment limitation, not a bug and not
  /// something a connected session fixes. Kept as its own category rather
  /// than folded into [antiBot] because it has a specific, evidenced raw
  /// signal and a specific, already-verified message.
  impersonationUnavailable,

  /// The device could not reach the platform at all.
  networkError,

  /// The link itself is not something this app can handle.
  unsupported,

  /// The extractor reached the platform but failed for a technical reason
  /// not covered by the more specific categories above.
  extractorError,

  /// Anything not confidently recognised.
  unknown,
}

/// What the error-detail UI can offer for a given [ExtractionFailureKind].
/// A category not worth acting on (e.g. [ExtractionFailureKind.unsupported])
/// gets [none] rather than a button that can't help.
enum SuggestedAction { connectAccount, reconnect, retry, none }

extension _SuggestedActionFor on ExtractionFailureKind {
  SuggestedAction get suggestedAction {
    switch (this) {
      case ExtractionFailureKind.authRequired:
        return SuggestedAction.connectAccount;
      case ExtractionFailureKind.sessionExpired:
      case ExtractionFailureKind.sessionInvalid:
        return SuggestedAction.reconnect;
      case ExtractionFailureKind.antiBot:
      case ExtractionFailureKind.networkError:
      case ExtractionFailureKind.extractorError:
      case ExtractionFailureKind.unknown:
        return SuggestedAction.retry;
      case ExtractionFailureKind.platformRestricted:
      case ExtractionFailureKind.impersonationUnavailable:
      case ExtractionFailureKind.unsupported:
        return SuggestedAction.none;
    }
  }
}

/// A user-facing message plus the raw engine output, kept apart.
///
/// yt-dlp's stderr is long, contains flags the user cannot pass, and buries
/// the real reason. The headline is what belongs on screen; [details] stays
/// available for a diagnostics view without dominating the UI, and is
/// sanitized before display — see [MappedExtractionError.sanitizedDetails].
class MappedExtractionError {
  const MappedExtractionError({
    required this.kind,
    required this.message,
    required this.details,
  });

  final ExtractionFailureKind kind;
  final String message;

  /// The original engine text, unmodified. Never shown as the headline —
  /// use [sanitizedDetails] for anything actually rendered on screen.
  final String details;

  SuggestedAction get suggestedAction => kind.suggestedAction;

  /// [details] with anything resembling a cookie/token/header value
  /// stripped, for the Technical Details view. yt-dlp's own error text does
  /// not normally echo cookies, but request headers occasionally appear in
  /// verbose failures, so this is a defensive scrub, not decoration.
  String get sanitizedDetails {
    String scrubbed = details;
    for (final RegExp pattern in _sensitivePatterns) {
      scrubbed = scrubbed.replaceAll(pattern, '[redacted]');
    }
    return scrubbed;
  }

  static final List<RegExp> _sensitivePatterns = <RegExp>[
    RegExp(r'cookie:\s*\S+', caseSensitive: false),
    RegExp(r'authorization:\s*\S+', caseSensitive: false),
    RegExp(r'set-cookie:\s*\S+', caseSensitive: false),
    RegExp(r'bearer\s+\S+', caseSensitive: false),
  ];
}

/// Translates raw engine output into a short, honest, actionable sentence.
///
/// Matching is done on stable substrings that yt-dlp itself emits — never
/// on the platform name alone, which only phrases the message. Anything
/// unrecognised falls through to [ExtractionFailureKind.unknown], which
/// shows a generic line rather than pretending to know the cause.
class ExtractionErrorMapper {
  const ExtractionErrorMapper._();

  /// [hasSession] should be true when a session is currently connected for
  /// [platform] — it retargets an auth-wall signal from "you need to sign
  /// in" (which would be misleading, since a session already exists) to
  /// "your session may have expired/isn't working," which is the honest
  /// framing when cookies were attached and the platform still refused.
  static MappedExtractionError map(
    String? raw, {
    String? platform,
    bool hasSession = false,
  }) {
    final String details = (raw ?? '').trim();
    final String text = details.toLowerCase();
    final String subject = platform ?? 'This link';

    if (text.isEmpty) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.unknown,
        message: '$subject could not be fetched.',
        details: details,
      );
    }

    // --- Authentication / restriction -----------------------------------
    // Covers TikTok's sensitive-content gate, YouTube's sign-in prompts,
    // and private posts generally.
    const List<String> authSignals = <String>[
      'log in for access',
      'login required',
      'requires authentication',
      'sign in to confirm',
      'this post may not be comfortable',
      'private video',
      'members-only',
      'age-restricted',
      'confirm your age',
      'use --cookies',
      'cookies-from-browser',
      'account associated',
    ];
    if (authSignals.any(text.contains)) {
      if (hasSession) {
        final bool looksExpired =
            text.contains('expired') || text.contains('token expired');
        return MappedExtractionError(
          kind: looksExpired
              ? ExtractionFailureKind.sessionExpired
              : ExtractionFailureKind.sessionInvalid,
          message: looksExpired
              ? 'Your saved session may have expired. Reconnect it and try again.'
              : 'This saved session is no longer valid.',
          details: details,
        );
      }

      return MappedExtractionError(
        kind: ExtractionFailureKind.authRequired,
        message: platform == 'TikTok'
            ? 'This TikTok is restricted or requires login.'
            : 'This content may require you to be signed in.',
        details: details,
      );
    }

    // --- Impersonation-unavailable ----------------------------------------
    // A specific, evidenced environment limitation (no curl_cffi in this
    // bundle) — kept ahead of the generic anti-bot bucket below so this
    // already-verified TikTok message never regresses.
    const List<String> impersonationSignals = <String>[
      'impersonate target is available',
      'impersonation',
    ];
    if (impersonationSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.impersonationUnavailable,
        message: platform == null
            ? "This video couldn't be retrieved right now."
            : "$platform couldn't provide this video right now.",
        details: details,
      );
    }

    // --- Generic anti-bot --------------------------------------------------
    const List<String> antiBotSignals = <String>[
      'unusual traffic',
      'are you a robot',
      'captcha',
      'too many requests',
      'http error 429',
      'rate-limited',
      'rate limited',
    ];
    if (antiBotSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.antiBot,
        message: 'The platform is currently blocking this type of request.',
        details: details,
      );
    }

    // --- Platform-restricted content ---------------------------------------
    const List<String> platformRestrictedSignals = <String>[
      'video unavailable',
      'content is not available',
      'not available in your country',
      'video is no longer available',
      'video has been removed',
      'removed by the uploader',
      'account has been terminated',
      'community guidelines',
      'this video is unavailable',
    ];
    if (platformRestrictedSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.platformRestricted,
        message: 'This content is restricted by the platform.',
        details: details,
      );
    }

    // --- Network ---------------------------------------------------------
    const List<String> networkSignals = <String>[
      'unable to download webpage',
      'failed to resolve',
      'connection reset',
      'connection refused',
      'network is unreachable',
      'timed out',
      'temporary failure in name resolution',
      'no address associated',
    ];
    if (networkSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.networkError,
        message: platform == null
            ? "Couldn't reach the server. Check your connection and try again."
            : "Couldn't reach $platform. Check your connection and try again.",
        details: details,
      );
    }

    // --- Unsupported link ------------------------------------------------
    const List<String> unsupportedSignals = <String>[
      'unsupported url',
      'is not a valid url',
      'no video formats found',
      'does not pass filter',
      'no media found',
    ];
    if (unsupportedSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.unsupported,
        message: platform == 'TikTok'
            ? 'This TikTok link is not supported.'
            : '$subject is not supported.',
        details: details,
      );
    }

    // --- Extractor technical failure ---------------------------------------
    const List<String> extractorSignals = <String>[
      'unable to extract',
      'unable to download api page',
      'failed to parse json',
      'unexpected response from webpage request',
      'http error 4',
      'http error 5',
    ];
    if (extractorSignals.any(text.contains)) {
      return MappedExtractionError(
        kind: ExtractionFailureKind.extractorError,
        message: "This couldn't be extracted right now.",
        details: details,
      );
    }

    return MappedExtractionError(
      kind: ExtractionFailureKind.unknown,
      message: 'Something went wrong while fetching this media.',
      details: details,
    );
  }

  /// Best-effort platform name from a URL, used only to phrase the message.
  static String? platformForUrl(String? url) {
    if (url == null) return null;
    final String host = Uri.tryParse(url.trim())?.host.toLowerCase() ?? '';
    if (host.isEmpty) return null;

    if (host.contains('tiktok.')) return 'TikTok';
    if (host.contains('youtube.') || host.contains('youtu.be')) return 'YouTube';
    if (host.contains('instagram.')) return 'Instagram';
    if (host.contains('twitter.') || host == 'x.com' || host.endsWith('.x.com')) {
      return 'X';
    }
    return null;
  }
}

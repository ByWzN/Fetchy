/// Shared by Link Auto-Detect and the General Cookie Manager — both need
/// the same two operations: turning free-form user text into a canonical
/// domain, and deciding whether a real URL's host belongs to that
/// domain's site family. Mirrors `DomainNormalizer`/`DomainMatcher` on the
/// native side exactly, so both layers agree on what counts as a match.
class DomainNormalizer {
  const DomainNormalizer._();

  /// Extracts and normalizes a bare host from free-form user input —
  /// "example.com", "https://example.com/some/path", "www.example.com",
  /// "M.Example.COM" all normalize to "example.com". Returns null when
  /// nothing resembling a real host can be extracted.
  static String? normalize(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final String withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final Uri? uri = Uri.tryParse(withScheme);
    final String? host = uri?.host;
    if (host == null || host.isEmpty) return null;

    final String normalized = normalizeHost(host);
    return (normalized.isNotEmpty && normalized.contains('.')) ? normalized : null;
  }

  /// The same www./m. stripping as [normalize], applied to a host that is
  /// already known to be real (e.g. from `Uri.parse(url).host`) rather
  /// than free-form user text.
  static String normalizeHost(String host) {
    String normalized = host.trim().toLowerCase();
    if (normalized.startsWith('www.')) normalized = normalized.substring(4);
    if (normalized.startsWith('m.')) normalized = normalized.substring(2);
    return normalized;
  }
}

/// Real, domain-aware host matching — never a substring/`contains` check.
class DomainMatcher {
  const DomainMatcher._();

  /// True when [candidateHost] belongs to the same site family as
  /// [registeredDomain]: an exact match, or a genuine subdomain of it
  /// (e.g. "www.example.com"/"m.example.com" both match "example.com") —
  /// never the reverse, and never an unrelated domain that merely shares a
  /// suffix in the wrong place (e.g. "fakeexample.com" never matches
  /// "example.com": the required "." boundary before the suffix rules
  /// that out).
  static bool matches(String? candidateHost, String registeredDomain) {
    if (candidateHost == null || candidateHost.trim().isEmpty) return false;
    final String candidate = _stripLeadingDot(candidateHost).trim().toLowerCase();
    final String registered = _stripLeadingDot(registeredDomain).trim().toLowerCase();
    if (registered.isEmpty) return false;
    return candidate == registered || candidate.endsWith('.$registered');
  }

  static String _stripLeadingDot(String value) =>
      value.startsWith('.') ? value.substring(1) : value;
}

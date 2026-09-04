/// One custom-site cookie record, as reported by the native encrypted
/// store (`CustomCookieStore.kt`). Never carries cookie values — only the
/// domain and a non-sensitive summary, exactly like [PlatformSession].
class CustomCookieSite {
  const CustomCookieSite({
    required this.domain,
    required this.createdAt,
    this.metadata,
  });

  final String domain;
  final DateTime createdAt;

  /// A short, human-readable, non-sensitive summary (e.g. cookie count and
  /// domains) — never the cookie values themselves.
  final String? metadata;

  static CustomCookieSite fromMap(Map<Object?, Object?> map) {
    final int millis = (map['createdAtMillis'] as num?)?.toInt() ?? 0;
    return CustomCookieSite(
      domain: map['domain'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(millis),
      metadata: map['metadata'] as String?,
    );
  }
}

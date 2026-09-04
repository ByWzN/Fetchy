// android/app/src/main/kotlin/com/example/fetchy/domains/DomainUtils.kt
package com.example.fetchy.domains

import android.net.Uri

/// Shared by the General Cookie Manager (arbitrary-site cookies) and Link
/// Auto-Detect (built-in + custom sites) — both need the same two
/// operations: turning free-form user text into a canonical domain, and
/// deciding whether a real request URL's host belongs to that domain's
/// site family. Neither existed as a shared abstraction before; both
/// systems previously would have needed to invent their own copy.
object DomainNormalizer {

    /// Extracts and normalizes a bare host from free-form user input —
    /// "example.com", "https://example.com/some/path", "www.example.com",
    /// "M.Example.COM" all normalize to "example.com". Returns null when
    /// nothing resembling a real host can be extracted, so a caller never
    /// stores garbage as if it were a domain.
    fun normalize(input: String): String? {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return null

        // Uri.parse only populates .host when a scheme is present.
        val withScheme = if (trimmed.contains("://")) trimmed else "https://$trimmed"
        val host = try {
            Uri.parse(withScheme).host
        } catch (throwable: Throwable) {
            null
        } ?: return null

        return normalizeHost(host).takeIf { it.isNotEmpty() && it.contains(".") }
    }

    /// The same www./m. stripping as [normalize], applied to a host that
    /// is already known to be a real host (e.g. from `Uri.parse(url).host`
    /// on an incoming request) rather than free-form user text.
    fun normalizeHost(host: String): String {
        var normalized = host.trim().lowercase()
        if (normalized.startsWith("www.")) normalized = normalized.removePrefix("www.")
        if (normalized.startsWith("m.")) normalized = normalized.removePrefix("m.")
        return normalized
    }
}

/// Real, domain-aware host matching — never a substring/`contains` check.
object DomainMatcher {

    /// True when [candidateHost] belongs to the same site family as
    /// [registeredDomain]: an exact match, or a genuine subdomain of it
    /// (e.g. "www.example.com"/"m.example.com"/"static.example.com" all
    /// match "example.com") — never the reverse, and never an unrelated
    /// domain that merely shares a suffix in the wrong place. The
    /// `endsWith(".$registered")` check requires a literal dot boundary,
    /// so "fakeexample.com" can never match "example.com" the way a naive
    /// `contains`/`endsWith` check without the dot would allow.
    fun matches(candidateHost: String?, registeredDomain: String): Boolean {
        if (candidateHost.isNullOrBlank()) return false
        val candidate = candidateHost.removePrefix(".").trim().lowercase()
        val registered = registeredDomain.removePrefix(".").trim().lowercase()
        if (registered.isEmpty()) return false
        return candidate == registered || candidate.endsWith(".$registered")
    }
}

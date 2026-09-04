// android/app/src/main/kotlin/com/example/fetchy/domains/WatchedDomainStore.kt
package com.example.fetchy.domains

import android.content.Context

/// The single, effective Link Auto-Detect list — replaces the earlier
/// split between an immutable built-in list and a separate user-added
/// list with ONE user-editable list, seeded from [BuiltInDetectedSites]'
/// domains the first time it is ever read. From that point on, this store
/// alone decides what Quick Fetch detects: a user who removes a
/// once-built-in domain genuinely stops Quick Fetch from recognizing it,
/// and there is no second list anywhere that could still match it.
///
/// Plain (unencrypted) `SharedPreferences` — domain names are not
/// sensitive the way session cookie values are.
class WatchedDomainStore(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /// The raw, editable text — one domain per line, in the order the user
    /// left them — exactly what the Settings text editor shows and saves
    /// back. Seeds from [BuiltInDetectedSites] on first-ever read.
    fun rawText(): String {
        val existing = prefs.getString(KEY_TEXT, null)
        if (existing != null) return existing

        val defaults = defaultText()
        prefs.edit().putString(KEY_TEXT, defaults).apply()
        return defaults
    }

    /// Every distinct, normalized domain currently watched — parsed fresh
    /// from [rawText] each call rather than kept as a separate stored
    /// list, so the text the user edits is always the one source of
    /// truth; there is no second representation that could drift from it.
    fun domains(): List<String> = parseAndNormalize(rawText())

    /// Replaces the whole list from free-form multi-line text — each
    /// non-blank line is normalized independently via [DomainNormalizer];
    /// a line that doesn't resolve to a real domain is silently dropped
    /// rather than rejecting the whole save, matching a plain text-editor
    /// feel rather than a validation form. Returns the canonicalized text
    /// actually stored, so the caller can refresh its editor to match
    /// exactly what was saved.
    fun setFromText(rawInput: String): String {
        val normalized = parseAndNormalize(rawInput)
        val canonical = normalized.joinToString("\n")
        prefs.edit().putString(KEY_TEXT, canonical).apply()
        return canonical
    }

    /// Restores the built-in defaults, discarding any user edits. Returns
    /// the restored text.
    fun resetToDefaults(): String {
        val defaults = defaultText()
        prefs.edit().putString(KEY_TEXT, defaults).apply()
        return defaults
    }

    fun matches(host: String?): Boolean = domains().any { DomainMatcher.matches(host, it) }

    private fun defaultText(): String =
        BuiltInDetectedSites.byPlatform.values.flatten().joinToString("\n")

    private fun parseAndNormalize(text: String): List<String> {
        val seen = LinkedHashSet<String>()
        for (line in text.lineSequence()) {
            val normalized = DomainNormalizer.normalize(line) ?: continue
            seen.add(normalized)
        }
        return seen.toList()
    }

    companion object {
        private const val PREFS_NAME = "fetchy_watched_domains"
        private const val KEY_TEXT = "text"
    }
}

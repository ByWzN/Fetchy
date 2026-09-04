// android/app/src/main/kotlin/com/example/fetchy/sessions/CustomCookieStore.kt
package com.example.fetchy.sessions

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.example.fetchy.domains.DomainMatcher
import java.io.File

/// What Dart is shown for one custom-site cookie record. Never carries
/// cookie values — only the domain and a non-sensitive summary, exactly
/// like [PlatformSessionRecord].
data class CustomCookieRecord(
    val domain: String,
    val createdAtMillis: Long,
    val metadata: String?,
)

/// The General Cookie Manager's store: cookies for arbitrary, user-added
/// websites, keyed by normalized domain instead of a fixed
/// [SessionPlatform]. Everything below mirrors [PlatformSessionStore] as
/// closely as the different key shape allows — same
/// [EncryptedSharedPreferences]/[MasterKey] setup (a different prefs file
/// so the two stores can never collide), same
/// parse-then-filter-then-store flow via [NetscapeCookieFile], same
/// materialize-to-cache-file contract for the extraction pipeline. This is
/// deliberately an extension of the existing session system, not a
/// competing one.
class CustomCookieStore(private val appContext: Context) {

    private val prefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        EncryptedSharedPreferences.create(
            appContext,
            PREFS_FILE_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    /// Parses [rawCookieText] (a Netscape cookies.txt file, or pasted text
    /// in the same format), keeps only rows whose domain genuinely belongs
    /// to [domain]'s site family (see [DomainMatcher] — the arbitrary-site
    /// equivalent of [PlatformCookieDomains.matches]), then stores the
    /// result encrypted. Throws [InvalidCookieFileException] when nothing
    /// parses or nothing relevant to [domain] survives filtering — an
    /// import is never accepted silently as a no-op.
    fun importCookies(domain: String, rawCookieText: String): CustomCookieRecord {
        val allRows = NetscapeCookieFile.parse(rawCookieText)
        val filtered = allRows.filter { DomainMatcher.matches(it.domain.removePrefix("."), domain) }

        if (filtered.isEmpty()) {
            throw InvalidCookieFileException("No cookies matching $domain were found in this data.")
        }

        val serialized = NetscapeCookieFile.serialize(filtered)
        val summary = NetscapeCookieFile.summarize(filtered)
        val now = System.currentTimeMillis()

        prefs.edit()
            .putString(cookiesKey(domain), serialized)
            .putLong(createdAtKey(domain), now)
            .putString(metadataKey(domain), summary)
            .apply()
        addToIndex(domain)

        return CustomCookieRecord(domain = domain, createdAtMillis = now, metadata = summary)
    }

    fun listRecords(): List<CustomCookieRecord> = domainIndex().sorted().mapNotNull(::getRecord)

    fun getRecord(domain: String): CustomCookieRecord? {
        val createdAt = prefs.getLong(createdAtKey(domain), 0L).takeIf { it > 0 } ?: return null
        return CustomCookieRecord(
            domain = domain,
            createdAtMillis = createdAt,
            metadata = prefs.getString(metadataKey(domain), null),
        )
    }

    /// Securely removes every stored value for [domain]. Because the
    /// backing store is [EncryptedSharedPreferences], the removed entries
    /// are gone from the underlying file, not merely unreferenced.
    fun removeDomain(domain: String) {
        prefs.edit()
            .remove(cookiesKey(domain))
            .remove(createdAtKey(domain))
            .remove(metadataKey(domain))
            .apply()
        removeFromIndex(domain)
        cookiesFileFor(domain).takeIf { it.exists() }?.delete()
    }

    /// Writes the stored cookies for [domain] to a private-cache file
    /// yt-dlp's `--cookies` option can read — the same contract as
    /// [PlatformSessionStore.cookiesFileFor]. Callers delete it once the
    /// yt-dlp invocation that needed it has finished.
    fun cookiesFileFor(domain: String): File {
        val dir = File(appContext.cacheDir, "custom_cookies").apply { mkdirs() }
        return File(dir, "${domain}_cookies.txt")
    }

    fun materializeCookiesFile(domain: String): File? {
        val serialized = prefs.getString(cookiesKey(domain), null) ?: return null
        val file = cookiesFileFor(domain)
        file.writeText(serialized)
        return file
    }

    /// Finds the stored custom-cookie domain whose site family [host]
    /// belongs to, if any, and materializes its cookie file. This is the
    /// arbitrary-domain equivalent of
    /// [PlatformSessionStore.materializeCookiesFile] — called from
    /// [com.example.fetchy.EngineChannelHandler] only after
    /// [SessionPlatform.fromUrl] has already returned null, so a built-in
    /// platform's own session always takes priority and this can never
    /// shadow it.
    fun materializeCookiesFileForHost(host: String?): File? {
        if (host.isNullOrBlank()) return null
        val domain = domainIndex().firstOrNull { DomainMatcher.matches(host, it) } ?: return null
        return materializeCookiesFile(domain)
    }

    /// Raw stored Netscape cookie text for [domain], for explicit
    /// user-requested export only — never called from the extraction/
    /// download path and never logged.
    fun exportCookiesText(domain: String): String? = prefs.getString(cookiesKey(domain), null)

    private fun domainIndex(): Set<String> = prefs.getStringSet(INDEX_KEY, emptySet()) ?: emptySet()

    private fun addToIndex(domain: String) {
        val current = domainIndex().toMutableSet()
        current.add(domain)
        prefs.edit().putStringSet(INDEX_KEY, current).apply()
    }

    private fun removeFromIndex(domain: String) {
        val current = domainIndex().toMutableSet()
        current.remove(domain)
        prefs.edit().putStringSet(INDEX_KEY, current).apply()
    }

    private fun cookiesKey(domain: String) = "$domain.cookies"
    private fun createdAtKey(domain: String) = "$domain.createdAt"
    private fun metadataKey(domain: String) = "$domain.metadata"

    companion object {
        private const val PREFS_FILE_NAME = "fetchy_custom_cookies_secure"
        private const val INDEX_KEY = "domains"
    }
}

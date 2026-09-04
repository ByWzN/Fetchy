// android/app/src/main/kotlin/com/example/fetchy/sessions/PlatformSessionStore.kt
package com.example.fetchy.sessions

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.io.File

/// [SESSION_USABLE] means Test Connection actually extracted media using
/// this stored session — "Session works for this test," never "Session is
/// valid everywhere." A fresh import is [SESSION_IMPORTED] (stored, never
/// tested) until a real Test Connection attempt proves it one way or the
/// other: [SESSION_USABLE] on a genuine success, [SESSION_EXPIRED]/
/// [SESSION_INVALID] on a genuine auth-shaped failure, or [UNKNOWN] when
/// the attempt was inconclusive (network error, ambiguous response) rather
/// than a real signal either way.
enum class SessionStatus {
    NOT_CONNECTED,
    SESSION_IMPORTED,
    SESSION_USABLE,
    SESSION_EXPIRED,
    SESSION_INVALID,
    UNKNOWN,
}

/// What Dart is shown for one platform. [metadata] is a short, non-sensitive
/// summary (domain names and a cookie count) — the actual cookie values
/// never leave [PlatformSessionStore].
data class PlatformSessionRecord(
    val platform: SessionPlatform,
    val status: SessionStatus,
    val createdAtMillis: Long?,
    val lastValidatedAtMillis: Long?,
    val metadata: String?,
)

/// The local, encrypted, per-platform session store. Everything here stays
/// on-device: there is no Fetchy server to send any of this to.
///
/// Cookie payloads are stored inside [EncryptedSharedPreferences], which
/// encrypts both keys and values with AES256-GCM using a key that itself
/// never leaves the Android Keystore (via [MasterKey]) — the app process
/// never handles raw key material, only the Keystore-backed wrapper does.
/// This is deliberately the smallest dependency that provides genuine
/// Keystore-backed encryption at rest, rather than a bespoke crypto
/// implementation.
class PlatformSessionStore(private val appContext: Context) {

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

    /// Parses, validates, and filters [rawCookieFileText] to only the
    /// cookies [platform] actually needs, then stores the result encrypted.
    /// Throws [InvalidCookieFileException] when the file doesn't parse, or
    /// when nothing relevant to [platform] survives filtering — an import
    /// is never accepted silently as a no-op session.
    fun importCookies(platform: SessionPlatform, rawCookieFileText: String): PlatformSessionRecord {
        val allRows = NetscapeCookieFile.parse(rawCookieFileText)
        val filtered = NetscapeCookieFile.filterFor(allRows, platform)

        if (filtered.isEmpty()) {
            throw InvalidCookieFileException(
                "No ${platform.displayName} cookies were found in this file."
            )
        }

        val serialized = NetscapeCookieFile.serialize(filtered)
        val summary = NetscapeCookieFile.summarize(filtered)
        val now = System.currentTimeMillis()

        prefs.edit()
            .putString(cookiesKey(platform), serialized)
            .putString(statusKey(platform), SessionStatus.SESSION_IMPORTED.name)
            .putLong(createdAtKey(platform), now)
            .remove(lastValidatedAtKey(platform))
            .putString(metadataKey(platform), summary)
            .apply()

        return PlatformSessionRecord(
            platform = platform,
            status = SessionStatus.SESSION_IMPORTED,
            createdAtMillis = now,
            lastValidatedAtMillis = null,
            metadata = summary,
        )
    }

    fun getSession(platform: SessionPlatform): PlatformSessionRecord {
        val statusName = prefs.getString(statusKey(platform), null)
        // runCatching guards against a status name stored by a previous
        // version of this enum (e.g. "CONNECTED"/"VALID") — treated as
        // NOT_CONNECTED rather than crashing, since a session record with
        // an unparseable status is not one Fetchy can trust anyway.
        val status = statusName
            ?.let { runCatching { SessionStatus.valueOf(it) }.getOrNull() }
            ?: SessionStatus.NOT_CONNECTED

        return PlatformSessionRecord(
            platform = platform,
            status = status,
            createdAtMillis = prefs.getLong(createdAtKey(platform), 0L).takeIf { it > 0 },
            lastValidatedAtMillis = prefs.getLong(lastValidatedAtKey(platform), 0L).takeIf { it > 0 },
            metadata = prefs.getString(metadataKey(platform), null),
        )
    }

    fun listSessions(): List<PlatformSessionRecord> = SessionPlatform.entries.map(::getSession)

    /// Records the outcome of a Test Connection attempt. Only updates
    /// status and [lastValidatedAtMillis] — never touches the stored
    /// cookies, so a failed validation never destroys a session the user
    /// might reconnect or retry later without re-importing.
    fun recordValidation(platform: SessionPlatform, status: SessionStatus): PlatformSessionRecord {
        val now = System.currentTimeMillis()
        prefs.edit()
            .putString(statusKey(platform), status.name)
            .putLong(lastValidatedAtKey(platform), now)
            .apply()
        return getSession(platform)
    }

    /// Securely removes every stored value for [platform]. Because the
    /// backing store is [EncryptedSharedPreferences], the removed entries
    /// are gone from the underlying file, not merely unreferenced.
    fun removeSession(platform: SessionPlatform) {
        prefs.edit()
            .remove(cookiesKey(platform))
            .remove(statusKey(platform))
            .remove(createdAtKey(platform))
            .remove(lastValidatedAtKey(platform))
            .remove(metadataKey(platform))
            .apply()

        cookiesFileFor(platform).takeIf { it.exists() }?.delete()
    }

    /// Writes the stored cookies for [platform] to a private-cache file yt-
    /// dlp's `--cookies` option can read, and returns it — or null when no
    /// session is stored. The file lives under [Context.getCacheDir], the
    /// same private, app-only directory the existing downloader already
    /// uses for yt-dlp's own temp files, and is overwritten on every call
    /// rather than left stale. Callers are responsible for deleting it once
    /// the yt-dlp invocation that needed it has finished.
    ///
    /// Called from [com.example.fetchy.EngineChannelHandler] on every
    /// extraction/download request for a platform with a stored session —
    /// see [materializeCookiesFile]. The caller deletes this file again as
    /// soon as the yt-dlp invocation that needed it finishes.
    fun cookiesFileFor(platform: SessionPlatform): File {
        val dir = File(appContext.cacheDir, "sessions").apply { mkdirs() }
        return File(dir, "${platform.id}_cookies.txt")
    }

    /// Materializes the current cookie file for [platform] on disk (see
    /// [cookiesFileFor]), or returns null when nothing is stored.
    fun materializeCookiesFile(platform: SessionPlatform): File? {
        val serialized = prefs.getString(cookiesKey(platform), null) ?: return null
        val file = cookiesFileFor(platform)
        file.writeText(serialized)
        return file
    }

    /// Returns the raw stored Netscape cookie text for [platform], for
    /// explicit user-requested export only — never called from the
    /// extraction/download path (that uses [materializeCookiesFile]) and
    /// never logged by any caller.
    fun exportCookiesText(platform: SessionPlatform): String? =
        prefs.getString(cookiesKey(platform), null)

    private fun statusKey(platform: SessionPlatform) = "${platform.id}.status"
    private fun createdAtKey(platform: SessionPlatform) = "${platform.id}.createdAt"
    private fun lastValidatedAtKey(platform: SessionPlatform) = "${platform.id}.lastValidatedAt"
    private fun metadataKey(platform: SessionPlatform) = "${platform.id}.metadata"
    private fun cookiesKey(platform: SessionPlatform) = "${platform.id}.cookies"

    companion object {
        private const val PREFS_FILE_NAME = "fetchy_sessions_secure"
    }
}

// android/app/src/main/kotlin/com/example/fetchy/sessions/NetscapeCookieFile.kt
package com.example.fetchy.sessions

/// One row of a Netscape-format cookie file:
/// domain \t includeSubdomains \t path \t secure \t expiry \t name \t value
///
/// [httpOnly] captures the common `#HttpOnly_<domain>` prefix some browsers
/// and extensions write for HttpOnly cookies — it is not a comment despite
/// starting with "#", and must round-trip correctly or session cookies
/// silently vanish.
data class NetscapeCookieRow(
    val domain: String,
    val includeSubdomains: String,
    val path: String,
    val secure: String,
    val expiry: String,
    val name: String,
    val value: String,
    val httpOnly: Boolean,
) {
    fun toLine(): String {
        val domainField = if (httpOnly) "#HttpOnly_$domain" else domain
        return listOf(domainField, includeSubdomains, path, secure, expiry, name, value)
            .joinToString("\t")
    }
}

class InvalidCookieFileException(message: String) : Exception(message)

/// Parses and filters Netscape-format cookie files (the "cookies.txt"
/// format yt-dlp and browser cookie-export extensions use). Never touches
/// disk itself — callers decide what happens to the parsed/filtered rows.
object NetscapeCookieFile {
    private const val HTTP_ONLY_PREFIX = "#HttpOnly_"

    /// Throws [InvalidCookieFileException] when the text does not look like
    /// a genuine Netscape cookie file, so an unrelated or corrupt file is
    /// rejected before anything is stored.
    fun parse(text: String): List<NetscapeCookieRow> {
        val rows = mutableListOf<NetscapeCookieRow>()

        for (rawLine in text.lineSequence()) {
            val line = rawLine.trimEnd('\r', '\n')
            if (line.isBlank()) continue

            val httpOnly = line.startsWith(HTTP_ONLY_PREFIX)
            val effective = if (httpOnly) line.removePrefix(HTTP_ONLY_PREFIX) else line

            // A real comment/header line, not an HttpOnly-prefixed cookie.
            if (!httpOnly && effective.startsWith("#")) continue

            val fields = effective.split("\t")
            if (fields.size != 7) continue

            rows.add(
                NetscapeCookieRow(
                    domain = fields[0],
                    includeSubdomains = fields[1],
                    path = fields[2],
                    secure = fields[3],
                    expiry = fields[4],
                    name = fields[5],
                    value = fields[6],
                    httpOnly = httpOnly,
                )
            )
        }

        if (rows.isEmpty()) {
            throw InvalidCookieFileException(
                "This doesn't look like a cookies.txt file — no valid cookie lines were found."
            )
        }

        return rows
    }

    /// Keeps only cookies whose domain belongs to [platform], per
    /// [PlatformCookieDomains]. Everything else is discarded, not stored.
    fun filterFor(rows: List<NetscapeCookieRow>, platform: SessionPlatform): List<NetscapeCookieRow> {
        return rows.filter { PlatformCookieDomains.matches(platform, it.domain) }
    }

    /// Serializes rows back into a real Netscape cookie file yt-dlp's
    /// `--cookies` option can read.
    fun serialize(rows: List<NetscapeCookieRow>): String {
        val builder = StringBuilder("# Netscape HTTP Cookie File\n")
        for (row in rows) {
            builder.append(row.toLine()).append('\n')
        }
        return builder.toString()
    }

    /// A short, non-sensitive summary safe to store as session metadata and
    /// to show in the UI — domains and a count, never cookie values.
    fun summarize(rows: List<NetscapeCookieRow>): String {
        val domains = rows.map { it.domain.removePrefix(".") }.toSortedSet()
        return "${rows.size} cookie(s) across ${domains.size} domain(s): ${domains.joinToString(", ")}"
    }
}

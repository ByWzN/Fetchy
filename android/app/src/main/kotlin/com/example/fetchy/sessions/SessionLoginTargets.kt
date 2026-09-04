// android/app/src/main/kotlin/com/example/fetchy/sessions/SessionLoginTargets.kt
package com.example.fetchy.sessions

import android.net.Uri

/// Per-platform Easy Connect login URLs and "sign-in appears complete"
/// detection.
///
/// [loginUrl] is used by both Easy Connect mechanisms (see
/// [SessionsChannelHandler]'s class doc comment for which platform uses
/// which): [SessionLoginActivity]'s WebView flow for YouTube/Instagram/
/// TikTok, and a Custom Tab for X.
///
/// [isAuthenticatedUrl] is used only by [SessionLoginActivity], as a gate
/// before it ever reads cookies: a login page sets *some* cookies (CSRF
/// tokens, an anonymous session id, locale prefs) long before the user
/// actually signs in, and those would still match the platform's cookie-
/// domain filter. Without this gate, the WebView flow could capture and
/// store a non-authenticated cookie jar as if it were a real session. It
/// is a heuristic based on each platform's current, long-standing
/// post-login redirect target — not an API contract any platform
/// guarantees — so it fails safe: an unexpected interstitial (2FA, a
/// consent screen) simply means capture never triggers rather than
/// capturing something wrong.
object SessionLoginTargets {

    fun loginUrl(platform: SessionPlatform): String = when (platform) {
        SessionPlatform.YOUTUBE ->
            "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/"
        SessionPlatform.TIKTOK -> "https://www.tiktok.com/login"
        SessionPlatform.X -> "https://x.com/login"
        SessionPlatform.INSTAGRAM -> "https://www.instagram.com/accounts/login/"
    }

    fun isAuthenticatedUrl(platform: SessionPlatform, url: String): Boolean {
        val uri = Uri.parse(url)
        val host = uri.host?.lowercase() ?: return false
        val path = uri.path?.lowercase() ?: ""

        return when (platform) {
            SessionPlatform.YOUTUBE ->
                host.endsWith("youtube.com") && !path.contains("signin") && !path.contains("servicelogin")

            SessionPlatform.TIKTOK ->
                host.endsWith("tiktok.com") && !path.contains("login")

            SessionPlatform.X ->
                (host == "x.com" || host.endsWith(".x.com") ||
                    host == "twitter.com" || host.endsWith(".twitter.com")) &&
                    path.startsWith("/home")

            SessionPlatform.INSTAGRAM ->
                host.endsWith("instagram.com") && !path.contains("accounts/login")
        }
    }
}

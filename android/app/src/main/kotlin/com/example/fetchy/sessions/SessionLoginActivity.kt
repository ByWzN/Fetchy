// android/app/src/main/kotlin/com/example/fetchy/sessions/SessionLoginActivity.kt
package com.example.fetchy.sessions

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.PopupMenu
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import com.example.fetchy.R

/// Easy Connect's WebView-based sign-in flow — used only for platforms
/// where this is known, from real-device testing, to actually work
/// (YouTube, Instagram, TikTok). X is deliberately excluded: it actively
/// rejects embedded-browser login ("Sorry, you are not allowed to log in
/// at this time"), which mirrors Google's own documented policy of
/// blocking OAuth-style sign-in inside embedded WebViews specifically to
/// stop malicious apps from stealing credentials via injected JavaScript.
/// That is a deliberate security control, not a bug — Fetchy does not
/// attempt to defeat it (e.g. by spoofing the User-Agent), for X or for
/// anything else. See [SessionsChannelHandler] for the per-platform
/// routing between this Activity and the Custom Tab path.
///
/// The user signs in through the platform's own real login page — Fetchy
/// never sees the password, only whatever cookies the platform's server
/// sets once it decides the user is authenticated, read back via
/// [CookieManager] and filtered to the platform's own domains through the
/// exact same [PlatformSessionStore.importCookies] path cookies.txt import
/// uses.
///
/// TikTok's login flow redirects to a native-app URI scheme
/// ("snssdk1233://...") that a WebView cannot load as a page. That
/// redirect is a "would you like to open the app" convenience, not a
/// signal that login failed — by the time it fires, TikTok has generally
/// already set the session cookies on tiktok.com. [shouldOverrideUrlLoading]
/// below simply declines to load any non-http(s) URL in the WebView
/// (never launching another app on the user's behalf) so navigation fails
/// safely instead of surfacing net::ERR_UNKNOWN_URL_SCHEME, and checks for
/// usable cookies immediately after.
class SessionLoginActivity : Activity() {

    private var platform: SessionPlatform? = null
    private var completed = false
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val platformId = intent.getStringExtra(EXTRA_PLATFORM_ID)
        val resolvedPlatform = platformId?.let(SessionPlatform::fromId)
        if (resolvedPlatform == null) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        platform = resolvedPlatform

        setContentView(buildLayout(resolvedPlatform))
    }

    private fun buildLayout(platform: SessionPlatform): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
        }

        val progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            isIndeterminate = true
            visibility = View.VISIBLE
        }

        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(24, 24, 24, 24)
        }
        val closeText = TextView(this).apply {
            text = "✕"
            textSize = 20f
            setPadding(16, 16, 16, 16)
            setOnClickListener { cancelAndFinish() }
        }
        val title = TextView(this).apply {
            text = getString(R.string.session_login_sign_in_to, platform.displayName)
            textSize = 16f
            setPadding(16, 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        val overflowText = TextView(this).apply {
            text = "⋮"
            textSize = 20f
            setPadding(16, 16, 16, 16)
            setOnClickListener { showOverflowMenu(this, platform) }
        }
        topBar.addView(closeText)
        topBar.addView(title)
        topBar.addView(overflowText)

        webView = WebView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f,
            )
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            // Hardening: this WebView only ever needs to render each
            // platform's real login page over https — it has no reason to
            // load local files, and disabling this closes a real gap on
            // API 24-29, where WebSettings.allowFileAccess defaults to
            // true (it only defaults to false starting API 30).
            settings.allowFileAccess = false
        }

        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        cookieManager.setAcceptThirdPartyCookies(webView, true)

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?,
                request: WebResourceRequest?,
            ): Boolean {
                val url = request?.url ?: return false
                if (url.scheme == "http" || url.scheme == "https") return false

                // A non-web scheme (e.g. TikTok's "snssdk1233://"). Never
                // launch another app on the user's behalf here — just
                // decline to load it. By the time a platform tries this
                // redirect it has generally already set session cookies on
                // the *current* page, which is what is checked here — not
                // the declined target, which isn't a real page at all.
                Log.d(TAG, "declining non-http(s) redirect scheme=${url.scheme}")
                val currentUrl = view?.url
                if (currentUrl != null && SessionLoginTargets.isAuthenticatedUrl(platform, currentUrl)) {
                    checkForUsableSession(platform)
                }
                return true
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                progressBar.visibility = View.GONE
                if (url != null && SessionLoginTargets.isAuthenticatedUrl(platform, url)) {
                    checkForUsableSession(platform)
                }
            }
        }

        webView.loadUrl(SessionLoginTargets.loginUrl(platform))

        root.addView(topBar)
        if (platform == SessionPlatform.TIKTOK) {
            root.addView(buildTikTokGoogleLoginNotice())
        }
        root.addView(progressBar)
        root.addView(webView)
        return root
    }

    /// TikTok's own "Sign in with Google" button opens a popup-style flow
    /// this WebView doesn't support, and even with popup support Google's
    /// own anti-phishing policy would likely still refuse it inside an
    /// embedded WebView — the same deliberate security boundary X's
    /// rejection reflects. Fetchy does not attempt to make this work (no
    /// popup-window hack, no credential interception); this is a static
    /// notice, not a detector — it does not inspect page content or clicks.
    private fun buildTikTokGoogleLoginNotice(): View {
        return TextView(this).apply {
            text = getString(R.string.session_login_tiktok_google_notice)
            textSize = 13f
            setPadding(24, 16, 24, 16)
            setBackgroundColor(Color.parseColor("#FFF3E0"))
        }
    }

    /// Called only once navigation has actually reached a URL
    /// [SessionLoginTargets.isAuthenticatedUrl] recognizes as post-login —
    /// callers gate on that before invoking this, so a login page's own
    /// pre-auth cookies (CSRF tokens, an anonymous session id) are never
    /// mistaken for a real session. Even so, the first authenticated-URL
    /// hit is not guaranteed to have every relevant cookie set yet, so an
    /// empty result here still just means "keep waiting," not an error.
    private fun checkForUsableSession(platform: SessionPlatform) {
        if (completed) return

        try {
            val rows = capturePlatformCookies(platform)
            if (rows.isEmpty()) return // nothing usable yet; keep waiting

            val text = NetscapeCookieFile.serialize(rows)
            PlatformSessionStore(applicationContext).importCookies(platform, text)

            completed = true
            setResult(RESULT_OK)
            finish()
        } catch (invalid: InvalidCookieFileException) {
            // Filtering found nothing usable from this page yet.
        } catch (throwable: Throwable) {
            Log.e(TAG, "session capture failed", throwable)
        }
    }

    /// Reads cookies from [CookieManager] for each domain
    /// [PlatformCookieDomains] considers relevant to [platform], and turns
    /// them into Netscape rows.
    ///
    /// Known, documented approximation: [CookieManager.getCookie] returns
    /// only "name=value" pairs — Android's public WebView API does not
    /// expose a cookie's real path, expiry, or HttpOnly flag. Path is set
    /// to "/", secure is set to true, and expiry is approximated as one
    /// year out. This is sufficient for yt-dlp, which only reads cookie
    /// values, but it is not a byte-for-byte copy of the platform's real
    /// cookies.
    private fun capturePlatformCookies(platform: SessionPlatform): List<NetscapeCookieRow> {
        val cookieManager = CookieManager.getInstance()
        val rows = mutableListOf<NetscapeCookieRow>()
        val farFutureExpiry = ((System.currentTimeMillis() / 1000) + 365L * 24 * 3600).toString()

        for (domain in PlatformCookieDomains.domainsFor(platform)) {
            val cookieHeader = cookieManager.getCookie("https://$domain/") ?: continue
            for (pair in cookieHeader.split(";")) {
                val separatorIndex = pair.indexOf('=')
                if (separatorIndex <= 0) continue
                val name = pair.substring(0, separatorIndex).trim()
                val value = pair.substring(separatorIndex + 1).trim()
                if (name.isEmpty()) continue

                rows.add(
                    NetscapeCookieRow(
                        domain = ".$domain",
                        includeSubdomains = "TRUE",
                        path = "/",
                        secure = "TRUE",
                        expiry = farFutureExpiry,
                        name = name,
                        value = value,
                        httpOnly = false,
                    )
                )
            }
        }

        return rows
    }

    private fun cancelAndFinish() {
        setResult(RESULT_CANCELED)
        finish()
    }

    /// The Telegram-style overflow menu: "Open in browser" (an escape
    /// hatch to the user's own browser, outside this WebView entirely —
    /// plain external navigation, not part of the session-capture flow)
    /// and "Clear session" (wipe this WebView's cookies/cache and reload
    /// the login page fresh, e.g. to sign in as a different account).
    private fun showOverflowMenu(anchor: View, platform: SessionPlatform) {
        val menu = PopupMenu(this, anchor)
        menu.menu.add(
            android.view.Menu.NONE,
            MENU_ID_OPEN_IN_BROWSER,
            0,
            getString(R.string.session_login_menu_open_in_browser),
        )
        menu.menu.add(
            android.view.Menu.NONE,
            MENU_ID_CLEAR_SESSION,
            1,
            getString(R.string.session_login_menu_clear_session),
        )
        menu.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                MENU_ID_OPEN_IN_BROWSER -> {
                    openCurrentUrlInBrowser()
                    true
                }
                MENU_ID_CLEAR_SESSION -> {
                    clearWebViewSession(platform)
                    true
                }
                else -> false
            }
        }
        menu.show()
    }

    private fun openCurrentUrlInBrowser() {
        val url = webView.url ?: SessionLoginTargets.loginUrl(platform ?: return)
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        } catch (noBrowser: ActivityNotFoundException) {
            Toast.makeText(this, getString(R.string.session_login_no_browser), Toast.LENGTH_SHORT).show()
        }
    }

    /// Wipes this login attempt's cookies/cache and reloads the login page
    /// fresh — does not touch anything already stored in
    /// [PlatformSessionStore]; only a subsequent successful capture
    /// replaces a previously saved session.
    private fun clearWebViewSession(platform: SessionPlatform) {
        CookieManager.getInstance().removeAllCookies(null)
        webView.clearCache(true)
        webView.clearFormData()
        completed = false
        webView.loadUrl(SessionLoginTargets.loginUrl(platform))
        Toast.makeText(this, getString(R.string.session_login_session_cleared), Toast.LENGTH_SHORT).show()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (::webView.isInitialized && webView.canGoBack()) {
            webView.goBack()
        } else {
            cancelAndFinish()
        }
    }

    override fun onDestroy() {
        if (::webView.isInitialized) {
            (webView.parent as? LinearLayout)?.removeView(webView)
            webView.destroy()
        }
        super.onDestroy()
    }

    companion object {
        const val EXTRA_PLATFORM_ID = "platform_id"
        private const val TAG = "FetchySessionLogin"

        private const val MENU_ID_OPEN_IN_BROWSER = 1
        private const val MENU_ID_CLEAR_SESSION = 2
    }
}

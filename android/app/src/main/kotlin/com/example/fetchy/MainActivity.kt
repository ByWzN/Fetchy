package com.example.fetchy

import android.content.Intent
import com.example.fetchy.quickfetch.QuickFetchChannelHandler
import com.example.fetchy.quickfetch.QuickFetchContract
import com.example.fetchy.root.RootChannelHandler
import com.example.fetchy.sessions.SessionsChannelHandler
import com.example.fetchy.storage.StorageChannelHandler
import com.example.fetchy.update.AppUpdateChannelHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var shareChannel: MethodChannel? = null
    private var engineChannel: MethodChannel? = null
    private var engineHandler: EngineChannelHandler? = null
    private var pendingSharedText: String? = null

    private var quickFetchChannel: MethodChannel? = null
    private var quickFetchHandler: QuickFetchChannelHandler? = null

    private var fileActionChannel: MethodChannel? = null
    private var fileActionHandler: FileActionHandler? = null

    private var sessionsChannel: MethodChannel? = null
    private var sessionsHandler: SessionsChannelHandler? = null

    private var rootChannel: MethodChannel? = null

    private var storageChannel: MethodChannel? = null
    private var storageHandler: StorageChannelHandler? = null

    private var artworkChannel: MethodChannel? = null
    private var artworkHandler: ArtworkChannelHandler? = null

    private var appUpdateChannel: MethodChannel? = null
    private var appUpdateHandler: AppUpdateChannelHandler? = null

    /// Set when a quick action launched or resumed this Activity, cleared once
    /// the tap has been delivered to Dart.
    private var quickFetchTapPending = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingSharedText = extractSharedText(intent)

        shareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_GET_INITIAL_SHARED_TEXT -> {
                        result.success(pendingSharedText)
                        pendingSharedText = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        val handler = EngineChannelHandler(applicationContext)
        engineHandler = handler

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EngineChannelHandler.ENGINE_CHANNEL
        )
        channel.setMethodCallHandler(handler)

        // Required so the handler can push download events back to Dart.
        handler.channel = channel
        engineChannel = channel

        // --- Quick Fetch: an independent channel; the downloader contract
        // above is untouched. ---
        val quickFetch = QuickFetchChannelHandler(applicationContext)
        quickFetch.activity = this
        quickFetchHandler = quickFetch

        // A cold start from a quick action: remember the tap and deliver it
        // once the window is genuinely focused (see onWindowFocusChanged).
        if (isQuickFetchTap(intent)) quickFetchTapPending = true

        quickFetchChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QuickFetchChannelHandler.CHANNEL
        ).apply {
            setMethodCallHandler(quickFetch)
        }
        // --- File Actions: Opening, sharing, and checking downloaded files ---
        val fileActions = FileActionHandler(applicationContext)
        fileActions.activity = this
        fileActionHandler = fileActions

        fileActionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FileActionHandler.CHANNEL
        ).apply {
            setMethodCallHandler(fileActions)
        }

        // --- Connected Accounts/Sessions: local, encrypted, optional ---
        val sessions = SessionsChannelHandler(applicationContext)
        sessions.activity = this
        sessionsHandler = sessions

        sessionsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SessionsChannelHandler.CHANNEL
        ).apply {
            setMethodCallHandler(sessions)
        }

        // --- Advanced/Root Features: capability detection + explicit gate
        // only. No privileged feature runs through this channel. ---
        rootChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RootChannelHandler.CHANNEL
        ).apply {
            setMethodCallHandler(RootChannelHandler(applicationContext))
        }

        // --- Download Location: Storage Access Framework folder picking
        // only. MediaStore/SAF publishing itself lives in
        // MediaStorePublisher, invoked from EngineChannelHandler. ---
        val storage = StorageChannelHandler(applicationContext)
        storage.activity = this
        storageHandler = storage

        storageChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            StorageChannelHandler.CHANNEL
        ).apply {
            setMethodCallHandler(storage)
        }

        // --- Thumbnail/Artwork: SAF custom image picking + source
        // thumbnail download only. Embedding itself happens natively as
        // part of the download pipeline — see DownloadPostProcessor. ---
        val artwork = ArtworkChannelHandler(applicationContext)
        artwork.activity = this
        artworkHandler = artwork

        artworkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ArtworkChannelHandler.CHANNEL
        ).apply {
            setMethodCallHandler(artwork)
        }

        // --- In-app update (GitHub Releases): the app's own version, the
        // release APK download into app-private cache, and the handover to
        // Android's package installer. Entirely separate from the yt-dlp
        // engine update on the engine channel above. ---
        val appUpdate = AppUpdateChannelHandler(applicationContext)
        appUpdate.activity = this
        appUpdateHandler = appUpdate

        val appUpdateMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppUpdateChannelHandler.CHANNEL
        )
        appUpdateMethodChannel.setMethodCallHandler(appUpdate)
        // Required so the handler can push download progress back to Dart.
        appUpdate.channel = appUpdateMethodChannel
        appUpdateChannel = appUpdateMethodChannel
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        sessionsHandler?.onActivityResult(requestCode, resultCode, data)
        storageHandler?.onActivityResult(requestCode, resultCode, data)
        artworkHandler?.onActivityResult(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Quick Fetch taps arrive here because MainActivity is singleTask.
        if (isQuickFetchTap(intent)) {
            quickFetchTapPending = true
            // If the window already has focus (app was merely backgrounded),
            // there will be no focus callback, so deliver immediately.
            if (hasWindowFocus()) deliverQuickFetchTap()
            return
        }

        val sharedText = extractSharedText(intent) ?: return
        val channel = shareChannel

        if (channel != null) {
            channel.invokeMethod(METHOD_ON_SHARED_TEXT, sharedText)
        } else {
            pendingSharedText = sharedText
        }
    }

    override fun onResume() {
        super.onResume()
        quickFetchHandler?.activity = this
        fileActionHandler?.activity = this
        sessionsHandler?.activity = this
        storageHandler?.activity = this
        artworkHandler?.activity = this
        appUpdateHandler?.activity = this
    }

    /// The clipboard is only readable while this window holds input focus
    /// (Android 10+ enforces exactly that), so the quick-action tap is not
    /// handed to Dart until focus is confirmed here.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) deliverQuickFetchTap()
    }

    private fun deliverQuickFetchTap() {
        if (!quickFetchTapPending) return
        val channel = quickFetchChannel ?: return
        quickFetchTapPending = false
        channel.invokeMethod(QuickFetchChannelHandler.METHOD_ON_QUICK_FETCH_TAP, null)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        shareChannel?.setMethodCallHandler(null)
        shareChannel = null
        engineChannel?.setMethodCallHandler(null)
        engineChannel = null
        engineHandler?.dispose()
        engineHandler = null

        quickFetchChannel?.setMethodCallHandler(null)
        quickFetchChannel = null
        // Drop the Activity reference so the handler cannot leak it.
        quickFetchHandler?.activity = null
        quickFetchHandler = null

        fileActionChannel?.setMethodCallHandler(null)
        fileActionChannel = null
        fileActionHandler?.activity = null
        fileActionHandler = null

        sessionsChannel?.setMethodCallHandler(null)
        sessionsChannel = null
        sessionsHandler?.activity = null
        sessionsHandler = null

        rootChannel?.setMethodCallHandler(null)
        rootChannel = null

        storageChannel?.setMethodCallHandler(null)
        storageChannel = null
        storageHandler?.activity = null
        storageHandler = null

        artworkChannel?.setMethodCallHandler(null)
        artworkChannel = null
        artworkHandler?.activity = null
        artworkHandler = null

        appUpdateChannel?.setMethodCallHandler(null)
        appUpdateChannel = null
        appUpdateHandler?.dispose()
        appUpdateHandler = null

        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        quickFetchHandler?.activity = null
        fileActionHandler?.activity = null
        sessionsHandler?.activity = null
        storageHandler?.activity = null
        artworkHandler?.activity = null
        appUpdateHandler?.activity = null
        super.onDestroy()
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
        intent.removeExtra(Intent.EXTRA_TEXT)

        return if (text.isNullOrEmpty()) null else text
    }

    /// A quick-action tap carries no URL by design — only the fact that the
    /// user asked Fetchy to look at the clipboard.
    private fun isQuickFetchTap(intent: Intent?): Boolean =
        intent != null && intent.action == QuickFetchContract.ACTION_OPEN

    companion object {
        private const val SHARE_CHANNEL = "app.fetchy/share"
        private const val METHOD_GET_INITIAL_SHARED_TEXT = "getInitialSharedText"
        private const val METHOD_ON_SHARED_TEXT = "onSharedText"
    }
}

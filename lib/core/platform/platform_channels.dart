import 'package:flutter/services.dart';

class PlatformChannels {
  const PlatformChannels._();

  static const String shareChannelName = 'app.fetchy/share';
  static const String engineChannelName = 'app.fetchy/engine';

  /// Quick Fetch has its own channel so the stable downloader contract above
  /// is never mixed with optional-feature state.
  static const String quickFetchChannelName = 'app.fetchy/quickfetch';

  /// Connected Accounts/Sessions: entirely local, entirely optional. Its
  /// own channel so the stable downloader contract above is never mixed
  /// with session state.
  static const String sessionsChannelName = 'app.fetchy/sessions';

  static const MethodChannel shareChannel = MethodChannel(shareChannelName);
  static const MethodChannel engineChannel = MethodChannel(engineChannelName);
  static const MethodChannel quickFetchChannel = MethodChannel(
    quickFetchChannelName,
  );
  static const MethodChannel sessionsChannel = MethodChannel(
    sessionsChannelName,
  );

  static const String getInitialSharedText = 'getInitialSharedText';
  static const String onSharedText = 'onSharedText';

  static const String extractMedia = 'extractMedia';

  static const String startDownload = 'startDownload';
  static const String cancelDownload = 'cancelDownload';
  static const String onDownloadEvent = 'onDownloadEvent';

  // yt-dlp engine version/update — see EngineUpdateService, the one shared
  // place both the Settings update row and Technical information read
  // this through.
  static const String updateYtDlp = 'updateYtDlp';
  static const String getYtDlpVersion = 'getYtDlpVersion';

  // Never implemented natively; retained only so a stale reference doesn't
  // silently reappear elsewhere.
  static const String getActualYtDlpVersion = 'getActualYtDlpVersion';

  // --- Quick Fetch (optional feature) ---
  static const String quickFetchGetCapabilities = 'getCapabilities';
  static const String quickFetchSetEnabled = 'setEnabled';
  static const String quickFetchSetActionStyle = 'setActionStyle';
  static const String quickFetchRequestNotificationPermission =
      'requestNotificationPermission';
  static const String quickFetchOpenOverlaySettings = 'openOverlaySettings';
  static const String quickFetchOpenNotificationSettings =
      'openNotificationSettings';
  static const String quickFetchOpenAccessibilitySettings =
      'openAccessibilitySettings';
  static const String quickFetchDismissPending = 'dismissPending';

  /// The single post-tap clipboard read. Native returns a supported URL or
  /// null; it is never called before the user taps a quick action.
  static const String quickFetchConsumeClipboardLink = 'consumeClipboardLink';

  /// Native -> Dart: the user tapped a quick action and the Activity now has
  /// window focus, so the clipboard may legally be read.
  static const String onQuickFetchTap = 'onQuickFetchTap';

  // --- Link Auto-Detect: the single effective watched-domain list, seeded
  // from built-in defaults natively and fully user-editable from then on
  // as free-form, one-domain-per-line text (see WatchedDomainStore). ---
  static const String quickFetchGetWatchedDomainsText = 'getWatchedDomainsText';
  static const String quickFetchSetWatchedDomainsText = 'setWatchedDomainsText';
  static const String quickFetchResetWatchedDomains = 'resetWatchedDomainsToDefault';
  static const String quickFetchIsWatchedUrl = 'isWatchedUrl';

  // --- Connected Accounts/Sessions (optional feature) ---
  static const String sessionsGetCapabilities = 'getCapabilities';
  static const String sessionsListSessions = 'listSessions';
  static const String sessionsPickAndImportCookiesFile =
      'pickAndImportCookiesFile';
  static const String sessionsOpenBrowserLogin = 'openBrowserLogin';
  static const String sessionsRecordValidationResult =
      'recordValidationResult';
  static const String sessionsExportSession = 'exportSession';
  static const String sessionsRemoveSession = 'removeSession';

  // --- General Cookie Manager: cookies for arbitrary (custom) sites, on
  // the same channel as the built-in platform session methods above. ---
  static const String sessionsListCustomCookieSites = 'listCustomCookieSites';
  static const String sessionsPickAndImportCustomCookiesFile =
      'pickAndImportCustomCookiesFile';
  static const String sessionsImportCustomCookiesText = 'importCustomCookiesText';
  static const String sessionsRemoveCustomCookieSite = 'removeCustomCookieSite';

  // --- Root/Advanced (optional feature) ---
  static const String rootChannelName = 'app.fetchy/root';
  static const MethodChannel rootChannel = MethodChannel(rootChannelName);
  static const String rootGetStatus = 'getStatus';
  static const String rootEnable = 'enable';

  // --- Download Location (Storage Access Framework folder picking only;
  // MediaStore/SAF publishing itself is native-internal, invoked from the
  // engine channel's startDownload). ---
  static const String storageChannelName = 'app.fetchy/storage';
  static const MethodChannel storageChannel = MethodChannel(storageChannelName);
  static const String storagePickCustomDirectory = 'pickCustomDirectory';
  static const String storageCheckTreeAccessible = 'checkTreeAccessible';
  static const String storageReleaseTree = 'releaseTree';

  // --- In-app update (GitHub Releases): reads this build's own version,
  // downloads a release APK into app-private cache, and hands it to
  // Android's package installer. Entirely separate from the yt-dlp engine
  // update above, which updates the extractor runtime, not the app. ---
  static const String appUpdateChannelName = 'app.fetchy/app_update';
  static const MethodChannel appUpdateChannel = MethodChannel(
    appUpdateChannelName,
  );
  static const String appUpdateGetInstalledVersion = 'getInstalledVersion';
  static const String appUpdateCanRequestInstalls = 'canRequestPackageInstalls';
  static const String appUpdateOpenInstallSettings =
      'openInstallPermissionSettings';
  static const String appUpdateDownload = 'downloadUpdate';
  static const String appUpdateCancelDownload = 'cancelUpdateDownload';
  static const String appUpdateInstall = 'installUpdate';

  /// Native -> Dart: bytes-so-far for the running update download.
  static const String appUpdateOnDownloadProgress = 'onUpdateDownloadProgress';

  // --- Thumbnail/Artwork: SAF custom image picking + source thumbnail
  // download only. Embedding itself is native-internal, invoked from the
  // engine channel's startDownload via DownloadOptions' artwork path. ---
  static const String artworkChannelName = 'app.fetchy/artwork';
  static const MethodChannel artworkChannel = MethodChannel(artworkChannelName);
  static const String artworkPickCustomImage = 'pickCustomImage';
  static const String artworkDownloadSourceThumbnail = 'downloadSourceThumbnail';
  static const String artworkDeleteArtwork = 'deleteArtwork';
}

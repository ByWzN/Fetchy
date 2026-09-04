// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fetchy';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonNext => 'Next';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonShare => 'Share';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonChoose => 'Choose';

  @override
  String get commonChange => 'Change';

  @override
  String get commonImport => 'Import';

  @override
  String get commonTest => 'Test';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonAll => 'All';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonNotAvailable => 'Not available';

  @override
  String get commonAutomatic => 'Automatic';

  @override
  String get commonDefaultSettings => 'Default settings';

  @override
  String get commonNotAvailableOnDevice => 'Not available on this device.';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Fetch a media from any link';

  @override
  String get homeSubtitle => 'Paste a link or share it to Fetchy.';

  @override
  String get linkFieldHint => 'Paste a link';

  @override
  String get linkFieldClear => 'Clear';

  @override
  String get linkFieldPaste => 'Paste';

  @override
  String get fetch => 'Fetch';

  @override
  String get fetching => 'Getting media info...';

  @override
  String get fetchFailed => 'Couldn\'t fetch this link';

  @override
  String get recentDownloads => 'Recent downloads';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get noDownloadsDescription => 'Your downloads will appear here.';

  @override
  String get homeSlowFetchMessage =>
      'Some sites take a little longer to fetch. Please wait, it should appear shortly.';

  @override
  String get homeNoSupportedLinkFound => 'No supported video link found.';

  @override
  String get mediaTypeVideoAudio => 'Video';

  @override
  String get mediaTypeAudioOnly => 'Audio only';

  @override
  String get qualityLabel => 'Quality';

  @override
  String get resolutionLabel => 'Resolution';

  @override
  String get audioFormatLabel => 'Format';

  @override
  String get qualityTierBestQuality => 'Best Quality';

  @override
  String get qualityTierVeryHigh => 'Very High';

  @override
  String get qualityTierHigh => 'High';

  @override
  String get qualityTierMedium => 'Medium';

  @override
  String get qualityTierLow => 'Low';

  @override
  String get qualityTierVeryLow => 'Very Low';

  @override
  String get download => 'Download';

  @override
  String get downloadOptionsSaved => 'Your options have been saved.';

  @override
  String get homeTagline =>
      'Paste any link and Fetchy will bring you the media.';

  @override
  String get downloadStarting => 'Starting download...';

  @override
  String get downloadWillStartSoon => 'Download will start soon';

  @override
  String get downloading => 'Downloading';

  @override
  String get merging => 'Merging video and audio...';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadCanceled => 'Download canceled';

  @override
  String savedToPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get couldNotOpenFile => 'Could not open this file.';

  @override
  String get couldNotShareFile => 'Could not share this file.';

  @override
  String get summaryLabelFormat => 'Format';

  @override
  String get summaryLabelBitrate => 'Bitrate';

  @override
  String get summaryLabelMetadata => 'Metadata';

  @override
  String get summaryLabelArtwork => 'Artwork';

  @override
  String get summaryLabelQuality => 'Quality';

  @override
  String get summaryLabelFps => 'FPS';

  @override
  String get summaryLabelAudio => 'Audio';

  @override
  String get summaryLabelSubtitles => 'Subtitles';

  @override
  String get summaryLabelSize => 'Size';

  @override
  String get summaryValueSource => 'Source';

  @override
  String get summaryValueCustom => 'Custom';

  @override
  String get summaryValueIncluded => 'Included';

  @override
  String get summaryValueNone => 'None';

  @override
  String get sizeUnavailable => 'Size unavailable';

  @override
  String get qualityUnavailable => 'Quality unavailable';

  @override
  String convertToFormat(String format) {
    return 'Convert to $format';
  }

  @override
  String sizeDownloadedSuffix(String size) {
    return '$size downloaded';
  }

  @override
  String get downloadOptionsTitle => 'Download Options';

  @override
  String get downloadOptionsAudioSubtitle =>
      'Optionally override the song title, artist, and album metadata for this download.';

  @override
  String get downloadOptionsVideoSubtitle =>
      'Optionally override the filename this video is saved as.';

  @override
  String get audioGroupTitle => 'Audio';

  @override
  String get videoGroupTitle => 'Video';

  @override
  String get pullInfo => 'Pull info';

  @override
  String get songTitleLabel => 'Song title';

  @override
  String get artistLabel => 'Artist';

  @override
  String get albumLabel => 'Album';

  @override
  String get filenameLabel => 'Filename';

  @override
  String get thumbnailLabel => 'Thumbnail';

  @override
  String get artworkNone => 'None';

  @override
  String get artworkSource => 'Source';

  @override
  String get artworkCustom => 'Custom';

  @override
  String get artworkSourceSelected => 'Source artwork';

  @override
  String get artworkCustomSelected => 'Custom image';

  @override
  String get artworkRemoveTooltip => 'Remove';

  @override
  String get artworkNoSourceThumbnail =>
      'This media has no source thumbnail to use.';

  @override
  String get artworkCouldNotUseImage => 'Could not use that image.';

  @override
  String get artworkSourceSelectedMessage => 'Source artwork selected.';

  @override
  String get artworkImageSelectedMessage => 'Image selected.';

  @override
  String get pullInfoNoUsableMetadata =>
      'This media doesn\'t have usable music info.';

  @override
  String get pullInfoPartial =>
      'Only some information was available and has been filled in.';

  @override
  String get pullInfoFilledIn => 'Metadata filled in from the source.';

  @override
  String get pullInfoReadError => 'Couldn\'t read metadata from this media.';

  @override
  String get advancedOptions => 'Advanced options';

  @override
  String get useAutomatic => 'Use automatic';

  @override
  String get formatLabel => 'Format';

  @override
  String get qualityPickerLabel => 'Quality';

  @override
  String get subtitlesLabel => 'Subtitles';

  @override
  String get bitrateLabel => 'Bitrate';

  @override
  String get bitrateBest => 'Best';

  @override
  String bitrateKbps(int value) {
    return '$value kbps';
  }

  @override
  String get includeAudioLabel => 'Include audio';

  @override
  String get includeAudioOnDescription =>
      'Downloads video with audio, as usual.';

  @override
  String get includeAudioOffDescription =>
      'Downloads video only, with no sound.';

  @override
  String get noAudioTag => 'No audio';

  @override
  String get subtitlesTag => 'Subtitles';

  @override
  String get automaticRecommended => 'Automatic (recommended)';

  @override
  String get noCreatorSubtitlesAvailable => 'No creator subtitles available';

  @override
  String get autoGeneratedSubtitles => 'Auto-generated';

  @override
  String get fpsNotAvailable => 'Not available';

  @override
  String get subtitlesOff => 'Off';

  @override
  String get activeTagFormatQuality => 'Format & quality';

  @override
  String get activeTagFormatBitrate => 'Format & bitrate';

  @override
  String get engineTitle => 'Engine';

  @override
  String get engineYtDlpLabel => 'yt-dlp';

  @override
  String engineCurrentVersion(String version) {
    return 'Current version: $version';
  }

  @override
  String get engineCheckingVersion => 'Checking version…';

  @override
  String get engineVersionUnknown => 'Unknown';

  @override
  String get engineBundledInfo => 'yt-dlp (bundled) via youtubedl-android';

  @override
  String get engineCheckForUpdates => 'Check for updates';

  @override
  String get engineUpdating => 'Updating…';

  @override
  String get engineUpdatingStatus => 'Updating yt-dlp…';

  @override
  String get engineAlreadyUpToDate => 'yt-dlp is already up to date.';

  @override
  String get engineUpdatedSuccessfully => 'yt-dlp updated successfully.';

  @override
  String get engineVerificationFailed =>
      'yt-dlp was updated, but the new version could not be verified.';

  @override
  String get engineUpdateFailed => 'yt-dlp update failed.';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get quickFetchTitle => 'Quick Fetch';

  @override
  String get quickFetchMasterDescription =>
      'Detect supported copied links automatically.';

  @override
  String get quickFetchIntro =>
      'Detects video links you copy in supported apps, and gives you a quick way to fetch them.';

  @override
  String get quickFetchEnableTitle => 'Enable Quick Fetch';

  @override
  String get quickFetchOnDescription =>
      'On, Fetchy is watching for copies in supported apps.';

  @override
  String get quickFetchOffDescription =>
      'Off, Fetchy won\'t touch your clipboard.';

  @override
  String get quickFetchActionStyleTitle => 'Action style';

  @override
  String get quickFetchStyleNotification => 'Notification';

  @override
  String get quickFetchStyleFloatingDot => 'Floating dot';

  @override
  String get quickFetchStyleNotificationDescription =>
      'Uses Android notifications.';

  @override
  String get quickFetchStyleOverlayDescription =>
      'Requires Display over other apps permission.';

  @override
  String get quickFetchStatusTitle => 'Status';

  @override
  String get quickFetchBackgroundEnabledTitle =>
      'Background detection: Enabled';

  @override
  String get quickFetchBackgroundEnabledMessage =>
      'Fetchy will notice when you copy a link in a supported app.';

  @override
  String get quickFetchBackgroundDisabledTitle =>
      'Background detection: Disabled';

  @override
  String get quickFetchBackgroundDisabledMessage =>
      'Quick Fetch uses Accessibility access only to detect copy interactions in supported apps. Fetchy reads the clipboard only after you tap the Quick Fetch action.\n\nWithout it you can still share a link to Fetchy or paste one on the Home screen.\n\nIf the system shows a list instead of opening Fetchy directly, tap Downloaded apps → Fetchy → turn it on.';

  @override
  String get quickFetchEnableAccessibility => 'Enable accessibility detection';

  @override
  String get quickFetchNotificationAllowedTitle => 'Notification: Allowed';

  @override
  String get quickFetchNotificationAllowedMessage =>
      'Detected copies appear as a notification.';

  @override
  String get quickFetchNotificationNotAllowedTitle =>
      'Notification: Not allowed';

  @override
  String get quickFetchNotificationNotAllowedMessage =>
      'Notification mode needs permission to post notifications, otherwise no quick action can be shown.';

  @override
  String get quickFetchOpenNotificationSettings => 'Open notification settings';

  @override
  String get quickFetchOverlayAllowedTitle => 'Overlay: Allowed';

  @override
  String get quickFetchOverlayAllowedMessage =>
      'A small dot appears over other apps when a copy is detected, and disappears once you use or dismiss it.';

  @override
  String get quickFetchOverlayNotAllowedTitle => 'Overlay: Not allowed';

  @override
  String get quickFetchOverlayNotAllowedMessage =>
      'Floating dot requires permission to appear above other apps. Until it is granted, Fetchy falls back to a notification.';

  @override
  String get quickFetchEnableOverlay => 'Enable display over other apps';

  @override
  String get quickFetchHowItWorksTitle => 'How it works';

  @override
  String get quickFetchHowItWorks1 =>
      'Accessibility access detects only that you performed a copy in a supported app, plus which app it was.';

  @override
  String get quickFetchHowItWorks2 =>
      'Android doesn\'t let any app read the clipboard in the background, and Fetchy doesn\'t try. The clipboard is read once, after you tap the quick action, with Fetchy open.';

  @override
  String get quickFetchHowItWorks3 =>
      'Only the watched sites below are accepted. Anything else is discarded and you\'re told no link was found.';

  @override
  String get quickFetchHowItWorks4 =>
      'Copying a link never starts a download. Nothing happens until you tap, and you still choose the quality.';

  @override
  String get quickFetchHowItWorks5 =>
      'Nothing is uploaded anywhere. No copied text is stored.';

  @override
  String get quickFetchWatchedSitesTitle => 'Watched sites';

  @override
  String get quickFetchNoSitesWatched =>
      'No sites watched. Tap Edit to add one.';

  @override
  String get quickFetchWatchedSitesFooter =>
      'Editing this list changes what Quick Fetch detects, including the built-in sites above.';

  @override
  String get quickFetchConsentTitle => 'Turn on Quick Fetch?';

  @override
  String get quickFetchConsent1 =>
      'Quick Fetch notices when you copy a link in a supported app, and offers a quick way to fetch it.';

  @override
  String get quickFetchConsent2 =>
      'It needs Accessibility access to detect copies in the background. That access only tells Fetchy that you copied something, and which app you were in. It can\'t read your clipboard in the background, and it never reads your screen.';

  @override
  String get quickFetchConsent3 =>
      'Your clipboard is only read after you tap the action, while Fetchy is open. Nothing is ever uploaded.';

  @override
  String get quickFetchConsent4 =>
      'Background detection uses a small amount of battery.';

  @override
  String get quickFetchTurnOn => 'Turn on';

  @override
  String get quickFetchSetupReadyTitle => 'Quick Fetch is ready';

  @override
  String get quickFetchSetupReadyMessage =>
      'Fetchy will notice when you copy a link in a watched app and offer a quick way to fetch it.';

  @override
  String get quickFetchSetupNeededTitle => 'Quick Fetch needs setup';

  @override
  String get quickFetchSetupNeededMessage =>
      'Quick Fetch can automatically detect copied media links. Android may require an additional security step for apps installed from APK files.';

  @override
  String get quickFetchSetupNotYetEnabledTitle =>
      'Quick Fetch isn\'t enabled yet';

  @override
  String get quickFetchSetupNotYetEnabledMessage =>
      'Fetchy\'s detector still isn\'t switched on in Android\'s Accessibility settings. You can try again, or open the screens below.';

  @override
  String get quickFetchEnableCta => 'Enable Quick Fetch';

  @override
  String get quickFetchTryAgain => 'Try again';

  @override
  String get quickFetchOpenAccessibilitySettings =>
      'Open Accessibility settings';

  @override
  String get quickFetchOpenAppInfo => 'Open Fetchy App Info';

  @override
  String get quickFetchEnableExplainTitle => 'Before you continue';

  @override
  String get quickFetchEnableExplainBody =>
      'Android will open its Accessibility settings. Find Fetchy in the list and turn it on, then come back here.\n\nFetchy can only open that screen for you — it can\'t switch the setting on itself.';

  @override
  String get quickFetchEnableExplainContinue => 'Open settings';

  @override
  String get quickFetchRestrictedHelpTitle =>
      'If Android says the setting is restricted';

  @override
  String get quickFetchRestrictedHelpBody =>
      'On Android 13 and newer, apps installed from APK files may be blocked by Android\'s Restricted Settings protection. If Android shows \"Restricted setting\", open Fetchy App Info and look for \"Allow restricted settings\", then return here and enable Quick Fetch.';

  @override
  String get quickFetchRestrictedHelpNote =>
      'On some Android versions, you may see \"Allow restricted settings\" in the App Info menu. Wording and menu placement differ between devices and manufacturers.';

  @override
  String get quickFetchHelpShow => 'Setup help';

  @override
  String get quickFetchOptionalNote =>
      'Quick Fetch is optional. You can always use Share → Fetchy without enabling it.';

  @override
  String get quickFetchShareFallbackTitle => 'Share to Fetchy';

  @override
  String get quickFetchShareFallbackSubtitle =>
      'Works without Quick Fetch permissions';

  @override
  String get quickFetchShareFallbackMessage =>
      'In any app, tap Share and pick Fetchy. The link opens straight into Fetchy\'s normal preview and download flow — no extra permission needed.';

  @override
  String get quickFetchAutoDetectLabel => 'Automatically detect copied links';

  @override
  String get quickFetchComingSoonTag => 'Coming soon';

  @override
  String get quickFetchComingSoonSubtitle => 'Coming soon';

  @override
  String get quickFetchComingSoonBody =>
      'Automatic copied-link detection is currently under development. It will let Fetchy notice when you copy a video link in a supported app and offer a quick way to fetch it.\n\nIt isn\'t ready yet, so it\'s switched off in this release.';

  @override
  String get quickFetchComingSoonMeanwhile =>
      'Everything else works as usual: paste a link on the Home screen, or share a link to Fetchy from any app.';

  @override
  String get watchedDomainsEditTitle => 'Edit watched sites';

  @override
  String get watchedDomainsOnePerLine => 'One domain per line.';

  @override
  String get watchedDomainsAddUrl => 'Add URL';

  @override
  String get watchedDomainsExampleHint => 'example.com';

  @override
  String get watchedDomainsInvalidDomain =>
      'That doesn\'t look like a website domain.';

  @override
  String get watchedDomainsResetToDefaults => 'Reset to defaults';

  @override
  String get watchedDomainsResetConfirmTitle => 'Reset to defaults?';

  @override
  String get watchedDomainsResetConfirmBody =>
      'This discards any sites you added or removed and restores the built-in list.';

  @override
  String get watchedDomainsDiscardTitle => 'Discard changes?';

  @override
  String get watchedDomainsDiscardBody => 'Your edits have not been saved.';

  @override
  String get watchedDomainsKeepEditing => 'Keep editing';

  @override
  String get watchedDomainsDiscard => 'Discard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get sectionDownloads => 'Downloads';

  @override
  String get downloadLocationTitle => 'Download Location';

  @override
  String get sectionAccounts => 'Accounts';

  @override
  String get connectedAccountsTitle => 'Connected Accounts / Sessions';

  @override
  String get connectedAccountsSubtitle =>
      'Optional: connect a platform session for account-required content.';

  @override
  String get sectionHistory => 'History';

  @override
  String get historySaveEnabled => 'Save download history';

  @override
  String get historySaveDescription => 'Keep a local record of your downloads.';

  @override
  String get historyClearAction => 'Clear history';

  @override
  String get sectionAdvanced => 'Advanced';

  @override
  String get rootFeaturesTitle => 'Root Features';

  @override
  String get rootFeaturesComingSoon => 'Coming soon, not available yet.';

  @override
  String get sectionDiagnostics => 'Diagnostics';

  @override
  String get technicalInformationTitle => 'Technical information';

  @override
  String get technicalInformationSubtitle =>
      'Known platform limitations, developer information, and what to do when a download fails.';

  @override
  String get sectionAbout => 'About';

  @override
  String downloadLocationSummary(
    String organization,
    String video,
    String audio,
  ) {
    return '$organization · Video: $video · Audio: $audio';
  }

  @override
  String get engineTileTitle => 'Engine';

  @override
  String get diagnosticsLimitationsTitle => 'Limitations';

  @override
  String get diagnosticsLimitationsBody =>
      'A download can fail for a few reasons:\n1. The site needs you to be signed in.\n2. The content is restricted.\n3. The site is temporarily blocking requests like this.\n4. This type of content isn\'t fully supported yet.\n\nSigning in or adding cookies can help sometimes, but it won\'t make every video downloadable.';

  @override
  String get diagnosticsDeveloperInfoTitle => 'Developer information';

  @override
  String get diagnosticsDeveloperInfoSubtitle =>
      'For advanced users investigating extraction problems.';

  @override
  String get diagnosticsSessionsPrivacy =>
      'Sessions are stored locally on this device and encrypted with Android Keystore protection. Fetchy has no server and does not upload sessions or cookies.';

  @override
  String get diagnosticsUpstreamResourcesTitle => 'Upstream resources';

  @override
  String get diagnosticsEngineFindInSettings =>
      'Find these in Settings, under Engine.';

  @override
  String get diagnosticsEngineFfmpegBundled => 'Bundled with the app';

  @override
  String get developerInfoTitle => 'Developer information';

  @override
  String get developerInfoIntro =>
      'For advanced users investigating extraction problems. This is safe to paste into a GitHub issue.';

  @override
  String get developerInfoEmptyState =>
      'No recent Fetch failure to show. Details appear here after a Fetch fails and you open this from that failure\'s Info button.';

  @override
  String get developerInfoCopyTechnicalDetails => 'Copy technical details';

  @override
  String get developerInfoTechnicalDetailsCopied => 'Technical details copied.';

  @override
  String get developerInfoPlatformLabel => 'Platform';

  @override
  String get developerInfoExtractorLabel => 'Extractor';

  @override
  String get developerInfoVersionLabel => 'yt-dlp version';

  @override
  String get developerInfoAppVersionLabel => 'App version';

  @override
  String get developerInfoErrorCategoryLabel => 'Error category';

  @override
  String get developerInfoSanitizedMessageTitle => 'Sanitized message';

  @override
  String get developerInfoKnownLimitationTitle => 'Relevant known limitation';

  @override
  String get developerInfoUpstreamIssueTitle => 'Possible upstream issue';

  @override
  String get developerInfoDetailTitle => 'Detail';

  @override
  String get developerInfoNoAdditionalDetail => '(no additional detail)';

  @override
  String get developerInfoNotApplicable => 'Not applicable';

  @override
  String developerInfoUpstreamIssueHint(String url) {
    return 'Could be a known yt-dlp limitation. Check $url';
  }

  @override
  String get developerInfoUnknown => 'Unknown';

  @override
  String get errorMorePossibleReasons => 'Possible reasons';

  @override
  String get errorMoreInformation => 'More information';

  @override
  String get errorSettingsPointer => 'Settings → Technical information';

  @override
  String get errorDeveloperInformation => 'Developer information';

  @override
  String get errorWhy => 'Why?';

  @override
  String get errorConnectedAccounts => 'Connected Accounts';

  @override
  String get errorImportSession => 'Import session';

  @override
  String get errorReconnect => 'Reconnect';

  @override
  String get errorTitleAuthRequired => 'Sign-in may be required';

  @override
  String get errorTitleSessionExpired => 'Your session may have expired';

  @override
  String get errorTitleSessionInvalid => 'Your session may no longer be valid';

  @override
  String get errorTitlePlatformRestricted => 'This content is restricted';

  @override
  String get errorTitleAntiBot => 'The platform is blocking this request';

  @override
  String get errorTitleNetworkError => 'Couldn\'t reach the platform';

  @override
  String get errorTitleUnsupported => 'This link isn\'t supported';

  @override
  String get errorTitleExtractorError => 'Couldn\'t process this media';

  @override
  String get errorTitleUnknown => 'Something went wrong';

  @override
  String get errorReasonAuthRequired1 =>
      'This content may require you to be signed in.';

  @override
  String errorReasonAuthRequired2(String subject) {
    return '$subject may restrict it to logged-in accounts.';
  }

  @override
  String get errorReasonAuthRequired3 =>
      'Signing in can help with some restricted content, but it doesn\'t guarantee access.';

  @override
  String get errorReasonSessionExpired1 =>
      'Your saved session may have expired.';

  @override
  String errorReasonSessionExpired2(String subject) {
    return '$subject may have signed the session out.';
  }

  @override
  String errorReasonSessionInvalid1(String subject) {
    return 'This saved session may no longer carry the right access for $subject.';
  }

  @override
  String get errorReasonSessionInvalid2 =>
      'It may have been revoked or replaced by a newer sign-in elsewhere.';

  @override
  String get errorReasonPlatformRestricted1 =>
      'The content may have been removed or made private.';

  @override
  String get errorReasonPlatformRestricted2 =>
      'It may be restricted in your region.';

  @override
  String errorReasonPlatformRestricted3(String subject) {
    return '$subject may have taken it down for a policy reason.';
  }

  @override
  String errorReasonAntiBot1(String subject) {
    return '$subject may be rate-limiting or challenging this type of request.';
  }

  @override
  String get errorReasonAntiBot2 => 'This is often temporary.';

  @override
  String get errorReasonAntiBot3 =>
      'This is a limitation of the platform\'s protection system. Signing in may not solve it.';

  @override
  String errorReasonImpersonation1(String subject) {
    return '$subject may have changed its delivery system.';
  }

  @override
  String get errorReasonImpersonation2 =>
      'This is an environment limitation, not an account or content issue.';

  @override
  String get errorReasonNetwork1 => 'Your device may be offline.';

  @override
  String errorReasonNetwork2(String subject) {
    return '$subject\'s servers may be temporarily unreachable.';
  }

  @override
  String get errorReasonUnsupported1 =>
      'This link format is not currently supported.';

  @override
  String errorReasonExtractor1(String subject) {
    return '$subject may have changed how it delivers this content.';
  }

  @override
  String get errorReasonExtractor2 =>
      'This can sometimes resolve itself on retry.';

  @override
  String errorReasonUnknown1(String subject) {
    return '$subject might need you to sign in.';
  }

  @override
  String get errorReasonUnknown2 => 'The content could be restricted.';

  @override
  String errorReasonUnknown3(String subject) {
    return '$subject may be temporarily blocking this request.';
  }

  @override
  String get errorReasonUnknown4 =>
      'This type of content might not be supported yet.';

  @override
  String get errorReasonUnknown5 =>
      'Signing in or adding cookies could help, but not always.';

  @override
  String get errorLimitationAuthRequired =>
      'The extractor requires an authenticated session for this content and none is attached.';

  @override
  String get errorLimitationSessionExpired =>
      'The attached session cookies appear to have expired.';

  @override
  String get errorLimitationSessionInvalid =>
      'The attached session cookies are being rejected as invalid.';

  @override
  String get errorLimitationPlatformRestricted =>
      'The platform reports this content as unavailable (removed, private, or geo-restricted).';

  @override
  String get errorLimitationAntiBot =>
      'The platform\'s bot-detection or rate-limiting rejected this request.';

  @override
  String get errorLimitationImpersonation =>
      'This extractor requires TLS client impersonation (curl_cffi) not present in this build.';

  @override
  String get errorLimitationNetwork =>
      'The request could not reach the platform (connectivity or DNS failure).';

  @override
  String get errorLimitationUnsupported =>
      'No extractor in this yt-dlp build recognizes this URL.';

  @override
  String get errorLimitationExtractor =>
      'The platform\'s page or response format was not what the extractor expected, likely a recent platform-side change.';

  @override
  String get errorLimitationUnknown =>
      'The failure text did not match any recognized category.';

  @override
  String get errorMessageAuthRequiredGeneric =>
      'This content may require you to be signed in.';

  @override
  String get errorMessageAuthRequiredTikTok =>
      'This TikTok is restricted or requires login.';

  @override
  String get errorMessageSessionExpired =>
      'Your saved session may have expired. Reconnect it and try again.';

  @override
  String get errorMessageSessionInvalid =>
      'This saved session is no longer valid.';

  @override
  String errorMessageImpersonationWithPlatform(String platform) {
    return '$platform couldn\'t provide this video right now.';
  }

  @override
  String get errorMessageImpersonationGeneric =>
      'This video couldn\'t be retrieved right now.';

  @override
  String get errorMessageAntiBot =>
      'The platform is currently blocking this type of request.';

  @override
  String get errorMessagePlatformRestricted =>
      'This content is restricted by the platform.';

  @override
  String errorMessageNetworkWithPlatform(String platform) {
    return 'Couldn\'t reach $platform. Check your connection and try again.';
  }

  @override
  String get errorMessageNetworkGeneric =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get errorMessageUnsupportedTikTok =>
      'This TikTok link isn\'t supported.';

  @override
  String errorMessageUnsupportedWithSubject(String subject) {
    return '$subject isn\'t supported.';
  }

  @override
  String get errorMessageExtractor => 'This couldn\'t be extracted right now.';

  @override
  String errorMessageUnknownEmpty(String subject) {
    return '$subject could not be fetched.';
  }

  @override
  String get errorMessageUnknownGeneric =>
      'Something went wrong while fetching this media.';

  @override
  String get errorSubjectFallback => 'The platform';

  @override
  String get errorSubjectThisLink => 'This link';

  @override
  String get upstreamYtDlpRepo => 'GitHub repository';

  @override
  String get upstreamYtDlpIssues => 'Report an issue';

  @override
  String get upstreamDocumentation => 'Documentation';

  @override
  String get sessionsPageTitle => 'Connected Accounts';

  @override
  String get sessionsPrivacyNotice =>
      'Fetchy is offline first. Your sessions are stored locally on this device. Fetchy does not upload your sessions to a Fetchy server.\n\nA connected session may help with account-required content, but it cannot bypass every platform restriction.';

  @override
  String get sessionsPlatformsSection => 'Platforms';

  @override
  String get sessionsOtherSitesSection => 'Other sites';

  @override
  String get sessionsNoCustomSites => 'No custom sites yet.';

  @override
  String get sessionsAddCookiesForOtherSites => 'Add cookies for other sites';

  @override
  String get sessionsConnected => 'Connected';

  @override
  String sessionsRemoveSiteConfirmTitle(String domain) {
    return 'Remove $domain?';
  }

  @override
  String get sessionsRemoveSiteConfirmBody =>
      'This securely deletes the stored cookies for this site from this device. You can add it again at any time.';

  @override
  String get sessionsAddCookiesDialogTitle => 'Add cookies for other sites';

  @override
  String get sessionsEnterWebsite =>
      'Enter the website these cookies belong to.';

  @override
  String get sessionsWebsiteLabel => 'Website';

  @override
  String get sessionsWebsiteHint => 'example.com';

  @override
  String sessionsCookiesImportedMessage(String domain) {
    return '$domain cookies imported.';
  }

  @override
  String get sessionsCouldNotImportCookies => 'Couldn\'t import those cookies.';

  @override
  String sessionsPasteCookiesForWebsite(String website) {
    return 'Paste cookies for $website';
  }

  @override
  String get sessionsPasteCookiesHelp =>
      'Paste the contents of a Netscape-format cookies.txt export, the same format browser cookie-export extensions produce.';

  @override
  String get sessionsCookieFileHint => '# Netscape HTTP Cookie File\n...';

  @override
  String sessionsSessionConnectedMessage(String platform) {
    return '$platform session connected.';
  }

  @override
  String get sessionsCouldNotOpenBrowser =>
      'Couldn\'t open a browser to sign in.';

  @override
  String get sessionsBrowserUnconfirmedTitle =>
      'Fetchy can\'t confirm what happened in your browser';

  @override
  String get sessionsBrowserUnconfirmedBody =>
      'If you signed in, this browser session can\'t be transferred to Fetchy automatically on this device. To use that account in Fetchy, import your session cookies using Advanced.';

  @override
  String get sessionsNotNow => 'Not now';

  @override
  String get sessionsImportCookiesNow => 'Import cookies now';

  @override
  String sessionsSessionImportedMessage(String platform) {
    return '$platform session imported.';
  }

  @override
  String get sessionsCouldNotImportSession => 'Couldn\'t import that session.';

  @override
  String get sessionsCouldNotCompleteTest => 'Couldn\'t complete the test.';

  @override
  String get sessionsTestConnectionTitle => 'Test connection';

  @override
  String sessionsTestConnectionResultTitle(String platform) {
    return '$platform test connection';
  }

  @override
  String sessionsTestUrlPrompt(String platform) {
    return 'Paste a $platform link to test this session against. This just does a quick lookup, nothing is downloaded.';
  }

  @override
  String get sessionsUrlHint => 'https://…';

  @override
  String get sessionsExportSessionTitle => 'Export session?';

  @override
  String get sessionsExportSessionBody =>
      'The exported file contains login details for your account. Anyone with this file can access your account on this platform.\n\nDon\'t share it with anyone. Fetchy never uploads it anywhere, you choose where it gets saved.';

  @override
  String get sessionsSessionExported => 'Session exported.';

  @override
  String get sessionsCouldNotExportSession => 'Couldn\'t export that session.';

  @override
  String sessionsRemoveSessionConfirmTitle(String platform) {
    return 'Remove $platform session?';
  }

  @override
  String get sessionsRemoveSessionConfirmBody =>
      'This securely deletes the stored session from this device. You can reconnect at any time.';

  @override
  String get sessionsExperimentalTag => 'Experimental';

  @override
  String get sessionsImportRequiredTag => 'Session import required';

  @override
  String get sessionsNotConnected => 'Not connected';

  @override
  String get sessionsXBlocksInAppBrowser =>
      'X blocks in-app browser sign-in from carrying a session into apps like Fetchy. Import cookies.txt below to use a signed-in session here.';

  @override
  String get sessionsImportCookiesTxtTitle => 'Import cookies.txt';

  @override
  String get sessionsImportCookiesTxtSubtitleAvailable =>
      'The practical way to use X on Fetchy: export cookies.txt from your signed-in browser and import it here.';

  @override
  String get sessionsOpenInBrowserTitle => 'Open in browser';

  @override
  String get sessionsOpenInBrowserSubtitle =>
      'Opens X in your regular browser, for convenience only. This doesn\'t import a session into Fetchy. Use Import cookies.txt above for that.';

  @override
  String get sessionsSignInBrowserTitle => 'Sign in using your browser';

  @override
  String get sessionsSignInBrowserTitleExperimental =>
      'Sign in using your browser (Experimental)';

  @override
  String get sessionsSignInTikTokRedirectWarning =>
      'TikTok\'s login page may redirect to the TikTok app before Fetchy can capture a session. If that happens, use Import cookies / session file below instead. It always works.';

  @override
  String sessionsSignInGenericSubtitle(String platform) {
    return 'Sign in through $platform\'s own login page in your browser.';
  }

  @override
  String get sessionsImportCookiesFileTitle => 'Import cookies / session file';

  @override
  String get sessionsImportCookiesFileSubtitle =>
      'For advanced users: import a cookies.txt export.';

  @override
  String get sessionsRootAssistedTitle =>
      'Root-assisted browser/session import';

  @override
  String sessionsRootAssistedSubtitle(String platform) {
    return 'Fetchy doesn\'t decrypt Chrome or other browser databases directly. That needs specialized, device-specific tools Fetchy can\'t safely automate. If you\'ve used a root tool to extract a cookie file for $platform, convert it to cookies.txt format and bring it in with \'Import cookies / session file\' above. It\'s the same path either way.';
  }

  @override
  String get sessionsTestConnectionTileTitle => 'Test connection';

  @override
  String get sessionsTestConnectionAvailableSubtitle =>
      'Run a lightweight check using a link you provide.';

  @override
  String get sessionsTestConnectionUnavailableSubtitle =>
      'Connect a session first.';

  @override
  String get sessionsExportSessionTileTitle => 'Export session';

  @override
  String get sessionsExportSessionTileSubtitle =>
      'Only if you explicitly need a copy. Handle with care.';

  @override
  String get sessionsRemoveSessionTileTitle => 'Remove session';

  @override
  String get sessionsRemoveSessionTileSubtitle =>
      'Securely deletes the stored session from this device.';

  @override
  String get sessionsCookieSourceTitle => 'Cookie source';

  @override
  String sessionsCookieSourcePrompt(String website) {
    return 'How do you want to bring in cookies for $website?';
  }

  @override
  String get sessionsImportCookieFileTitle => 'Import cookie file';

  @override
  String get sessionsImportCookieFileSubtitle =>
      'Import a cookies.txt export for this site.';

  @override
  String get sessionsPasteCookiesTitle => 'Paste cookies';

  @override
  String get sessionsPasteCookiesSubtitle =>
      'Paste Netscape-format cookie text directly.';

  @override
  String get sessionsStatusConnected => 'Connected';

  @override
  String get sessionsStatusConnectedWorks => 'Connected · Session works';

  @override
  String get sessionsStatusConnectedUnverified =>
      'Connected · Status couldn\'t be verified';

  @override
  String get sessionsStatusExpired => 'Expired';

  @override
  String get sessionsStatusInvalid => 'Invalid';

  @override
  String get sessionsStatusNotConnected => 'Not connected';

  @override
  String get sessionsStatusImportRequired => 'Session import required';

  @override
  String get sessionsTestWorks => 'Session works for this test.';

  @override
  String sessionsTestStatusUnverified(String message) {
    return 'Session status couldn\'t be verified: $message';
  }

  @override
  String get sessionsCookieFileInvalid =>
      'That file could not be used as a session.';

  @override
  String get sessionsCustomCookieInvalid => 'Those cookies could not be used.';

  @override
  String get sessionWarningTitle => 'Connect a platform session?';

  @override
  String get sessionWarningBody =>
      'Your session can include login details for your account.\n\nFetchy stores it on this device only, and it\'s encrypted.\n\nIf you ever export a session file, don\'t share it with anyone.\n\nConnecting a session doesn\'t guarantee restricted or protected content will download.';

  @override
  String get duplicateDialogTitle => 'Already downloaded';

  @override
  String get duplicateDialogBody => 'This file already exists on your device:';

  @override
  String get duplicateDialogDownloadAgain => 'Download again';

  @override
  String get duplicateDialogDefaultPath => 'Downloads/Fetchy';

  @override
  String get downloadLocationTitleLabel => 'Download Location';

  @override
  String get downloadLocationIntro =>
      'Choose where videos and audio are saved, and whether Fetchy keeps them organized in its own folders. This only changes where files go. Filename and quality are separate settings.';

  @override
  String get downloadLocationVideoLabel => 'Video';

  @override
  String get downloadLocationAudioLabel => 'Audio';

  @override
  String get downloadLocationBaseFolderTitle => 'Base folder';

  @override
  String get downloadLocationVideoLocationTitle => 'Video location';

  @override
  String get downloadLocationAudioLocationTitle => 'Audio location';

  @override
  String get downloadLocationSameAsVideo => 'Same as video';

  @override
  String get downloadLocationDifferentFolder => 'Use different folder';

  @override
  String get downloadLocationSameFolderAsVideo => 'Same folder as video';

  @override
  String get downloadLocationFolderInaccessible =>
      'This folder is no longer accessible. Choose a new one.';

  @override
  String get downloadLocationNoFolderChosen => 'No folder chosen';

  @override
  String get downloadLocationChooseFolder => 'Choose folder';

  @override
  String get downloadLocationOrganizationTitle => 'Organization';

  @override
  String get downloadLocationUseSubfolders => 'Use Fetchy subfolders';

  @override
  String get downloadLocationUseSubfoldersOnDescription =>
      'Fetchy creates its own Videos and Audio subfolders inside the base folder above.';

  @override
  String get downloadLocationUseSubfoldersOffDescription =>
      'Files are saved directly in the base folder above, with no Fetchy subfolder.';

  @override
  String get storageBaseAndroidDefaultLabel => 'Android default folders';

  @override
  String get storageBaseAndroidDefaultDescription =>
      'Movies and Music, the same folders other apps use.';

  @override
  String get storageBaseCustomLabel => 'Custom folder';

  @override
  String get storageBaseCustomDescription =>
      'Choose exactly where files are saved.';

  @override
  String get storageSelectedFolderFallback => 'Selected folder';

  @override
  String storageVideoLocationCustom(String folder) {
    return '$folder / Videos';
  }

  @override
  String storageAudioLocationCustom(String folder) {
    return '$folder / Audio';
  }

  @override
  String get storageVideoLocationDefaultSubfolders =>
      'Movies / Fetchy / Videos';

  @override
  String get storageVideoLocationDefault => 'Movies';

  @override
  String get storageAudioLocationDefaultSubfolders => 'Music / Fetchy / Audio';

  @override
  String get storageAudioLocationDefault => 'Music';

  @override
  String storageOrganizedSummary(String baseLabel) {
    return 'Fetchy-organized · $baseLabel';
  }

  @override
  String get storageSummaryDefault => 'Default';

  @override
  String get storageSummaryCustom => 'Custom';

  @override
  String get historyPageTitle => 'History';

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get historyClearHistoryTooltip => 'Clear history';

  @override
  String get historyClearHistoryTitle => 'Clear history?';

  @override
  String get historyClearHistoryBody =>
      'This removes all recorded downloads from this device. It does not delete the downloaded files themselves.';

  @override
  String get historyNoMatchingDownloads => 'No matching downloads';

  @override
  String get historyTryChangingFilters =>
      'Try changing your search terms or filters.';

  @override
  String get historyResetFilters => 'Reset filters';

  @override
  String get historyNoHistoryYet => 'No history yet';

  @override
  String get historyDownloadsWillShowHere =>
      'Downloads you complete will show up here.';

  @override
  String get historyFilterTooltip => 'Filter';

  @override
  String get historyMediaTypeLabel => 'Media type';

  @override
  String get historySourceLabel => 'Source';

  @override
  String get historyMediaTypeVideo => 'Video';

  @override
  String get historyMediaTypeAudio => 'Audio';

  @override
  String get historySourceOther => 'Other';

  @override
  String get historyFileMissing => 'File missing';

  @override
  String get historyJustNow => 'Just now';

  @override
  String historyMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String historyHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String historyDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get historyDetailTitle => 'Download details';

  @override
  String get historyFileAvailable => 'File available on device';

  @override
  String get historyFileMissingOrRemoved =>
      'File missing or removed from storage';

  @override
  String get historySourceUrlLabel => 'Source URL';

  @override
  String get historyPlatformLabel => 'Platform';

  @override
  String get historyTypeLabel => 'Type';

  @override
  String get historyQualityLabel => 'Quality';

  @override
  String get historyFormatLabel => 'Format';

  @override
  String get historyFileNameLabel => 'File name';

  @override
  String get historyFileSizeLabel => 'File size';

  @override
  String get historySavedToLabel => 'Saved to';

  @override
  String get historyCopySourceUrl => 'Copy source URL';

  @override
  String get historyLinkCopied => 'Link copied.';

  @override
  String get rootFeaturesPageTitle => 'Advanced / Root Features';

  @override
  String get rootFeaturesComingSoonTag => 'COMING SOON';

  @override
  String get rootFeaturesDescription =>
      'Root-assisted features are planned for a future release. This build doesn\'t check for root, request root access, or run any root command. Fetchy behaves like a normal app without root.';

  @override
  String get rootFeaturesSectionTitle => 'Root features';

  @override
  String get rootFeaturesBrowserImportTitle => 'Browser session import helper';

  @override
  String get rootFeaturesBrowserImportReason =>
      'this is deliberate, not a gap to close later. Modern Chrome/Chromium stores cookies in an encrypted database tied to the Android Keystore. Decrypting it isn\'t something Fetchy can do safely or reliably on its own, even with root access, and getting it wrong risks corrupting a real browser\'s data.';

  @override
  String get rootFeaturesDiagnosticsTitle => 'Advanced diagnostics';

  @override
  String get rootFeaturesDiagnosticsReason =>
      'Not implemented. No specific diagnostic data has been scoped yet.';

  @override
  String get rootFeaturesFileAccessTitle => 'Optional file access improvements';

  @override
  String get rootFeaturesFileAccessReason =>
      'Not implemented. Normal Android storage access (SAF/MediaStore) already covers what Fetchy needs, so nothing currently requires this.';

  @override
  String get rootFeaturesSessionImportTitle => 'Root-assisted session import';

  @override
  String get rootFeaturesSessionImportReason =>
      'it reuses the same Advanced cookies.txt import already available in Connected Accounts. Extract a cookie file with an external root tool, convert it to cookies.txt format, and import it there. No dedicated in-app extraction is planned.';

  @override
  String rootFeaturesNotBuiltYet(String reason) {
    return 'Not built yet. $reason';
  }

  @override
  String get rootFeaturesAccessDescription =>
      'Root access gives Fetchy elevated access to files on this device.\n\nOnly enable this if you understand and trust the feature. Fetchy will use root only for the selected advanced operation.';

  @override
  String get rootFeaturesEnableButton => 'Enable root features';

  @override
  String get rootFeaturesEnableConfirmTitle => 'Enable root features?';

  @override
  String get rootFeaturesBypassNotice =>
      'Root access may provide additional local access, but it does not guarantee bypassing platform anti-bot protection, authentication requirements, DRM, or server-side restrictions.';

  @override
  String get rootStatusAvailable => 'Root: available';

  @override
  String get rootStatusUnavailable => 'Root: not available on this device';

  @override
  String get rootStatusDenied => 'Root: access denied';

  @override
  String get rootStatusUnknown => 'Root: not checked yet';

  @override
  String get updatesTitle => 'Updates';

  @override
  String get updatesSettingsRowSubtitle =>
      'Check for a newer version of Fetchy';

  @override
  String get updatesCurrentVersionLabel => 'Current version';

  @override
  String get updatesNewVersionLabel => 'New version';

  @override
  String get updatesCheckAction => 'Check for updates';

  @override
  String get updatesCheckingStatus => 'Checking for updates…';

  @override
  String get updatesUpToDateTitle => 'You\'re up to date';

  @override
  String updatesUpToDateBody(String version) {
    return 'Fetchy $version is the newest published release.';
  }

  @override
  String get updatesNeverChecked => 'Not checked yet';

  @override
  String get updatesLastCheckedNever =>
      'Fetchy hasn\'t checked for updates yet.';

  @override
  String get updatesAvailableTitle => 'Update available';

  @override
  String updatesAvailableBody(String version) {
    return 'Fetchy $version is available to install.';
  }

  @override
  String get updatesReleaseNotesTitle => 'What\'s new';

  @override
  String get updatesNoReleaseNotes => 'This release has no notes.';

  @override
  String updatesPublishedOn(String date) {
    return 'Published $date';
  }

  @override
  String get updatesDownloadAction => 'Download update';

  @override
  String updatesDownloadSize(String size) {
    return 'Download size: $size';
  }

  @override
  String get updatesDownloadingStatus => 'Downloading update…';

  @override
  String updatesDownloadedAmount(String received, String total) {
    return '$received of $total';
  }

  @override
  String get updatesDownloadCancelAction => 'Cancel download';

  @override
  String get updatesReadyTitle => 'Ready to install';

  @override
  String updatesReadyBody(String version) {
    return 'Fetchy $version has been downloaded. Android will ask you to confirm the installation.';
  }

  @override
  String get updatesInstallAction => 'Install update';

  @override
  String get updatesPermissionTitle => 'Installation permission required';

  @override
  String get updatesPermissionBody =>
      'Android only lets an app open the installer once you allow it. Turn on \"Install unknown apps\" for Fetchy, then come back here and continue.';

  @override
  String get updatesOpenAndroidSettingsAction => 'Open Android settings';

  @override
  String get updatesContinueInstallAction => 'Continue installation';

  @override
  String get updatesFailedTitle => 'Update failed';

  @override
  String get updatesGithubUnavailableTitle => 'GitHub unavailable';

  @override
  String get updatesNoApkTitle => 'No installable file';

  @override
  String updatesNoApkBody(String version) {
    return 'Release $version doesn\'t include an Android APK, so there is nothing to install from it.';
  }

  @override
  String get updatesViewOnGithubAction => 'View on GitHub';

  @override
  String get updatesErrorNotConfigured =>
      'This build has no update source configured yet, so Fetchy can\'t check for updates.';

  @override
  String get updatesErrorNoNetwork => 'No internet connection.';

  @override
  String get updatesErrorTimeout => 'GitHub didn\'t respond in time.';

  @override
  String get updatesErrorRateLimited =>
      'GitHub is limiting requests right now. Please try again later.';

  @override
  String get updatesErrorHttp => 'GitHub returned an unexpected response.';

  @override
  String get updatesErrorMalformed => 'GitHub\'s response couldn\'t be read.';

  @override
  String get updatesErrorNoRelease => 'There are no published releases yet.';

  @override
  String get updatesErrorUnknown =>
      'Something went wrong while checking for updates.';

  @override
  String get updatesInstallErrorPackageMismatch =>
      'That file isn\'t a Fetchy build, so it was not installed.';

  @override
  String get updatesInstallErrorNotNewer =>
      'The downloaded build isn\'t newer than the one installed.';

  @override
  String get updatesInstallErrorSignature =>
      'The update is signed with a different key than the installed app, so Android would refuse it. Download Fetchy from the same source you installed it from.';

  @override
  String get updatesInstallErrorCorrupt =>
      'The downloaded file isn\'t a valid Android package.';

  @override
  String get updatesInstallErrorDownloadFailed =>
      'The update couldn\'t be downloaded.';

  @override
  String get updatesInstallErrorCanceled => 'Download canceled.';

  @override
  String get updatesInstallErrorUnknown => 'The installer couldn\'t be opened.';

  @override
  String get updatesPrivacyNote =>
      'Checking for updates contacts GitHub only. No account, session, clipboard, or download history is ever sent.';
}

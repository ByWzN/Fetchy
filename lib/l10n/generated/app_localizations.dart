import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fetchy'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get commonChoose;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get commonTest;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get commonNotAvailable;

  /// No description provided for @commonAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get commonAutomatic;

  /// No description provided for @commonDefaultSettings.
  ///
  /// In en, this message translates to:
  /// **'Default settings'**
  String get commonDefaultSettings;

  /// No description provided for @commonNotAvailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get commonNotAvailableOnDevice;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch a media from any link'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste a link or share it to Fetchy.'**
  String get homeSubtitle;

  /// No description provided for @linkFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get linkFieldHint;

  /// No description provided for @linkFieldClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get linkFieldClear;

  /// No description provided for @linkFieldPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get linkFieldPaste;

  /// No description provided for @fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// No description provided for @fetching.
  ///
  /// In en, this message translates to:
  /// **'Getting media info...'**
  String get fetching;

  /// No description provided for @fetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch this link'**
  String get fetchFailed;

  /// No description provided for @recentDownloads.
  ///
  /// In en, this message translates to:
  /// **'Recent downloads'**
  String get recentDownloads;

  /// No description provided for @noDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloadsYet;

  /// No description provided for @noDownloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your downloads will appear here.'**
  String get noDownloadsDescription;

  /// No description provided for @homeSlowFetchMessage.
  ///
  /// In en, this message translates to:
  /// **'Some sites take a little longer to fetch. Please wait, it should appear shortly.'**
  String get homeSlowFetchMessage;

  /// No description provided for @homeNoSupportedLinkFound.
  ///
  /// In en, this message translates to:
  /// **'No supported video link found.'**
  String get homeNoSupportedLinkFound;

  /// No description provided for @mediaTypeVideoAudio.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaTypeVideoAudio;

  /// No description provided for @mediaTypeAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get mediaTypeAudioOnly;

  /// No description provided for @qualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualityLabel;

  /// No description provided for @resolutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolutionLabel;

  /// No description provided for @audioFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get audioFormatLabel;

  /// No description provided for @qualityTierBestQuality.
  ///
  /// In en, this message translates to:
  /// **'Best Quality'**
  String get qualityTierBestQuality;

  /// No description provided for @qualityTierVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get qualityTierVeryHigh;

  /// No description provided for @qualityTierHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityTierHigh;

  /// No description provided for @qualityTierMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get qualityTierMedium;

  /// No description provided for @qualityTierLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qualityTierLow;

  /// No description provided for @qualityTierVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get qualityTierVeryLow;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Confirmation shown after saving the Download Options sheet, so pressing Save visibly does something rather than just closing the sheet.
  ///
  /// In en, this message translates to:
  /// **'Your options have been saved.'**
  String get downloadOptionsSaved;

  /// The single line under the app name on Home. Replaces the old homeTitle/homeSubtitle pair: one sentence stating the whole promise rather than a heading plus an instruction.
  ///
  /// In en, this message translates to:
  /// **'Paste any link and Fetchy will bring you the media.'**
  String get homeTagline;

  /// No description provided for @downloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get downloadStarting;

  /// Shown on the download card in place of a percentage during the gap between requesting a download and the engine reporting its first byte, which can be several seconds. The bar is indeterminate while this shows.
  ///
  /// In en, this message translates to:
  /// **'Download will start soon'**
  String get downloadWillStartSoon;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @merging.
  ///
  /// In en, this message translates to:
  /// **'Merging video and audio...'**
  String get merging;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadCanceled.
  ///
  /// In en, this message translates to:
  /// **'Download canceled'**
  String get downloadCanceled;

  /// No description provided for @savedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String savedToPath(String path);

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open this file.'**
  String get couldNotOpenFile;

  /// No description provided for @couldNotShareFile.
  ///
  /// In en, this message translates to:
  /// **'Could not share this file.'**
  String get couldNotShareFile;

  /// No description provided for @summaryLabelFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get summaryLabelFormat;

  /// No description provided for @summaryLabelBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get summaryLabelBitrate;

  /// No description provided for @summaryLabelMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get summaryLabelMetadata;

  /// No description provided for @summaryLabelArtwork.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get summaryLabelArtwork;

  /// No description provided for @summaryLabelQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get summaryLabelQuality;

  /// No description provided for @summaryLabelFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get summaryLabelFps;

  /// No description provided for @summaryLabelAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get summaryLabelAudio;

  /// No description provided for @summaryLabelSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get summaryLabelSubtitles;

  /// No description provided for @summaryLabelSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get summaryLabelSize;

  /// No description provided for @summaryValueSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get summaryValueSource;

  /// No description provided for @summaryValueCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get summaryValueCustom;

  /// No description provided for @summaryValueIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get summaryValueIncluded;

  /// No description provided for @summaryValueNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get summaryValueNone;

  /// No description provided for @sizeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Size unavailable'**
  String get sizeUnavailable;

  /// Shown in place of a resolution label (e.g. '1080p') when the extractor reported no usable dimensions for a format that is still downloadable. Deliberately not a guessed number.
  ///
  /// In en, this message translates to:
  /// **'Quality unavailable'**
  String get qualityUnavailable;

  /// No description provided for @convertToFormat.
  ///
  /// In en, this message translates to:
  /// **'Convert to {format}'**
  String convertToFormat(String format);

  /// No description provided for @sizeDownloadedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{size} downloaded'**
  String sizeDownloadedSuffix(String size);

  /// No description provided for @downloadOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Options'**
  String get downloadOptionsTitle;

  /// No description provided for @downloadOptionsAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally override the song title, artist, and album metadata for this download.'**
  String get downloadOptionsAudioSubtitle;

  /// No description provided for @downloadOptionsVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally override the filename this video is saved as.'**
  String get downloadOptionsVideoSubtitle;

  /// No description provided for @audioGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioGroupTitle;

  /// No description provided for @videoGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoGroupTitle;

  /// No description provided for @pullInfo.
  ///
  /// In en, this message translates to:
  /// **'Pull info'**
  String get pullInfo;

  /// No description provided for @songTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get songTitleLabel;

  /// No description provided for @artistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistLabel;

  /// No description provided for @albumLabel.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumLabel;

  /// No description provided for @filenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filenameLabel;

  /// No description provided for @thumbnailLabel.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get thumbnailLabel;

  /// No description provided for @artworkNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get artworkNone;

  /// No description provided for @artworkSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get artworkSource;

  /// No description provided for @artworkCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get artworkCustom;

  /// No description provided for @artworkSourceSelected.
  ///
  /// In en, this message translates to:
  /// **'Source artwork'**
  String get artworkSourceSelected;

  /// No description provided for @artworkCustomSelected.
  ///
  /// In en, this message translates to:
  /// **'Custom image'**
  String get artworkCustomSelected;

  /// No description provided for @artworkRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get artworkRemoveTooltip;

  /// No description provided for @artworkNoSourceThumbnail.
  ///
  /// In en, this message translates to:
  /// **'This media has no source thumbnail to use.'**
  String get artworkNoSourceThumbnail;

  /// No description provided for @artworkCouldNotUseImage.
  ///
  /// In en, this message translates to:
  /// **'Could not use that image.'**
  String get artworkCouldNotUseImage;

  /// No description provided for @artworkSourceSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Source artwork selected.'**
  String get artworkSourceSelectedMessage;

  /// No description provided for @artworkImageSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Image selected.'**
  String get artworkImageSelectedMessage;

  /// No description provided for @pullInfoNoUsableMetadata.
  ///
  /// In en, this message translates to:
  /// **'This media doesn\'t have usable music info.'**
  String get pullInfoNoUsableMetadata;

  /// No description provided for @pullInfoPartial.
  ///
  /// In en, this message translates to:
  /// **'Only some information was available and has been filled in.'**
  String get pullInfoPartial;

  /// No description provided for @pullInfoFilledIn.
  ///
  /// In en, this message translates to:
  /// **'Metadata filled in from the source.'**
  String get pullInfoFilledIn;

  /// No description provided for @pullInfoReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read metadata from this media.'**
  String get pullInfoReadError;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get advancedOptions;

  /// No description provided for @useAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Use automatic'**
  String get useAutomatic;

  /// No description provided for @formatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @qualityPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualityPickerLabel;

  /// No description provided for @subtitlesLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitlesLabel;

  /// No description provided for @bitrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get bitrateLabel;

  /// No description provided for @bitrateBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get bitrateBest;

  /// No description provided for @bitrateKbps.
  ///
  /// In en, this message translates to:
  /// **'{value} kbps'**
  String bitrateKbps(int value);

  /// No description provided for @includeAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Include audio'**
  String get includeAudioLabel;

  /// No description provided for @includeAudioOnDescription.
  ///
  /// In en, this message translates to:
  /// **'Downloads video with audio, as usual.'**
  String get includeAudioOnDescription;

  /// No description provided for @includeAudioOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Downloads video only, with no sound.'**
  String get includeAudioOffDescription;

  /// No description provided for @noAudioTag.
  ///
  /// In en, this message translates to:
  /// **'No audio'**
  String get noAudioTag;

  /// No description provided for @subtitlesTag.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitlesTag;

  /// No description provided for @automaticRecommended.
  ///
  /// In en, this message translates to:
  /// **'Automatic (recommended)'**
  String get automaticRecommended;

  /// No description provided for @noCreatorSubtitlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No creator subtitles available'**
  String get noCreatorSubtitlesAvailable;

  /// No description provided for @autoGeneratedSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated'**
  String get autoGeneratedSubtitles;

  /// No description provided for @fpsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get fpsNotAvailable;

  /// No description provided for @subtitlesOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get subtitlesOff;

  /// No description provided for @activeTagFormatQuality.
  ///
  /// In en, this message translates to:
  /// **'Format & quality'**
  String get activeTagFormatQuality;

  /// No description provided for @activeTagFormatBitrate.
  ///
  /// In en, this message translates to:
  /// **'Format & bitrate'**
  String get activeTagFormatBitrate;

  /// No description provided for @engineTitle.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get engineTitle;

  /// No description provided for @engineYtDlpLabel.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp'**
  String get engineYtDlpLabel;

  /// No description provided for @engineCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version: {version}'**
  String engineCurrentVersion(String version);

  /// No description provided for @engineCheckingVersion.
  ///
  /// In en, this message translates to:
  /// **'Checking version…'**
  String get engineCheckingVersion;

  /// No description provided for @engineVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get engineVersionUnknown;

  /// No description provided for @engineBundledInfo.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp (bundled) via youtubedl-android'**
  String get engineBundledInfo;

  /// No description provided for @engineCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get engineCheckForUpdates;

  /// No description provided for @engineUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get engineUpdating;

  /// No description provided for @engineUpdatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Updating yt-dlp…'**
  String get engineUpdatingStatus;

  /// No description provided for @engineAlreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp is already up to date.'**
  String get engineAlreadyUpToDate;

  /// No description provided for @engineUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp updated successfully.'**
  String get engineUpdatedSuccessfully;

  /// No description provided for @engineVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp was updated, but the new version could not be verified.'**
  String get engineVerificationFailed;

  /// No description provided for @engineUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp update failed.'**
  String get engineUpdateFailed;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @quickFetchTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Fetch'**
  String get quickFetchTitle;

  /// No description provided for @quickFetchMasterDescription.
  ///
  /// In en, this message translates to:
  /// **'Detect supported copied links automatically.'**
  String get quickFetchMasterDescription;

  /// No description provided for @quickFetchIntro.
  ///
  /// In en, this message translates to:
  /// **'Detects video links you copy in supported apps, and gives you a quick way to fetch them.'**
  String get quickFetchIntro;

  /// No description provided for @quickFetchEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Quick Fetch'**
  String get quickFetchEnableTitle;

  /// No description provided for @quickFetchOnDescription.
  ///
  /// In en, this message translates to:
  /// **'On, Fetchy is watching for copies in supported apps.'**
  String get quickFetchOnDescription;

  /// No description provided for @quickFetchOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Off, Fetchy won\'t touch your clipboard.'**
  String get quickFetchOffDescription;

  /// No description provided for @quickFetchActionStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Action style'**
  String get quickFetchActionStyleTitle;

  /// No description provided for @quickFetchStyleNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get quickFetchStyleNotification;

  /// No description provided for @quickFetchStyleFloatingDot.
  ///
  /// In en, this message translates to:
  /// **'Floating dot'**
  String get quickFetchStyleFloatingDot;

  /// No description provided for @quickFetchStyleNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Uses Android notifications.'**
  String get quickFetchStyleNotificationDescription;

  /// No description provided for @quickFetchStyleOverlayDescription.
  ///
  /// In en, this message translates to:
  /// **'Requires Display over other apps permission.'**
  String get quickFetchStyleOverlayDescription;

  /// No description provided for @quickFetchStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get quickFetchStatusTitle;

  /// No description provided for @quickFetchBackgroundEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Background detection: Enabled'**
  String get quickFetchBackgroundEnabledTitle;

  /// No description provided for @quickFetchBackgroundEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Fetchy will notice when you copy a link in a supported app.'**
  String get quickFetchBackgroundEnabledMessage;

  /// No description provided for @quickFetchBackgroundDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Background detection: Disabled'**
  String get quickFetchBackgroundDisabledTitle;

  /// No description provided for @quickFetchBackgroundDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Quick Fetch uses Accessibility access only to detect copy interactions in supported apps. Fetchy reads the clipboard only after you tap the Quick Fetch action.\n\nWithout it you can still share a link to Fetchy or paste one on the Home screen.\n\nIf the system shows a list instead of opening Fetchy directly, tap Downloaded apps → Fetchy → turn it on.'**
  String get quickFetchBackgroundDisabledMessage;

  /// No description provided for @quickFetchEnableAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Enable accessibility detection'**
  String get quickFetchEnableAccessibility;

  /// No description provided for @quickFetchNotificationAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification: Allowed'**
  String get quickFetchNotificationAllowedTitle;

  /// No description provided for @quickFetchNotificationAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'Detected copies appear as a notification.'**
  String get quickFetchNotificationAllowedMessage;

  /// No description provided for @quickFetchNotificationNotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification: Not allowed'**
  String get quickFetchNotificationNotAllowedTitle;

  /// No description provided for @quickFetchNotificationNotAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification mode needs permission to post notifications, otherwise no quick action can be shown.'**
  String get quickFetchNotificationNotAllowedMessage;

  /// No description provided for @quickFetchOpenNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get quickFetchOpenNotificationSettings;

  /// No description provided for @quickFetchOverlayAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Overlay: Allowed'**
  String get quickFetchOverlayAllowedTitle;

  /// No description provided for @quickFetchOverlayAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'A small dot appears over other apps when a copy is detected, and disappears once you use or dismiss it.'**
  String get quickFetchOverlayAllowedMessage;

  /// No description provided for @quickFetchOverlayNotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Overlay: Not allowed'**
  String get quickFetchOverlayNotAllowedTitle;

  /// No description provided for @quickFetchOverlayNotAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'Floating dot requires permission to appear above other apps. Until it is granted, Fetchy falls back to a notification.'**
  String get quickFetchOverlayNotAllowedMessage;

  /// No description provided for @quickFetchEnableOverlay.
  ///
  /// In en, this message translates to:
  /// **'Enable display over other apps'**
  String get quickFetchEnableOverlay;

  /// No description provided for @quickFetchHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get quickFetchHowItWorksTitle;

  /// No description provided for @quickFetchHowItWorks1.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access detects only that you performed a copy in a supported app, plus which app it was.'**
  String get quickFetchHowItWorks1;

  /// No description provided for @quickFetchHowItWorks2.
  ///
  /// In en, this message translates to:
  /// **'Android doesn\'t let any app read the clipboard in the background, and Fetchy doesn\'t try. The clipboard is read once, after you tap the quick action, with Fetchy open.'**
  String get quickFetchHowItWorks2;

  /// No description provided for @quickFetchHowItWorks3.
  ///
  /// In en, this message translates to:
  /// **'Only the watched sites below are accepted. Anything else is discarded and you\'re told no link was found.'**
  String get quickFetchHowItWorks3;

  /// No description provided for @quickFetchHowItWorks4.
  ///
  /// In en, this message translates to:
  /// **'Copying a link never starts a download. Nothing happens until you tap, and you still choose the quality.'**
  String get quickFetchHowItWorks4;

  /// No description provided for @quickFetchHowItWorks5.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded anywhere. No copied text is stored.'**
  String get quickFetchHowItWorks5;

  /// No description provided for @quickFetchWatchedSitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Watched sites'**
  String get quickFetchWatchedSitesTitle;

  /// No description provided for @quickFetchNoSitesWatched.
  ///
  /// In en, this message translates to:
  /// **'No sites watched. Tap Edit to add one.'**
  String get quickFetchNoSitesWatched;

  /// No description provided for @quickFetchWatchedSitesFooter.
  ///
  /// In en, this message translates to:
  /// **'Editing this list changes what Quick Fetch detects, including the built-in sites above.'**
  String get quickFetchWatchedSitesFooter;

  /// No description provided for @quickFetchConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Quick Fetch?'**
  String get quickFetchConsentTitle;

  /// No description provided for @quickFetchConsent1.
  ///
  /// In en, this message translates to:
  /// **'Quick Fetch notices when you copy a link in a supported app, and offers a quick way to fetch it.'**
  String get quickFetchConsent1;

  /// No description provided for @quickFetchConsent2.
  ///
  /// In en, this message translates to:
  /// **'It needs Accessibility access to detect copies in the background. That access only tells Fetchy that you copied something, and which app you were in. It can\'t read your clipboard in the background, and it never reads your screen.'**
  String get quickFetchConsent2;

  /// No description provided for @quickFetchConsent3.
  ///
  /// In en, this message translates to:
  /// **'Your clipboard is only read after you tap the action, while Fetchy is open. Nothing is ever uploaded.'**
  String get quickFetchConsent3;

  /// No description provided for @quickFetchConsent4.
  ///
  /// In en, this message translates to:
  /// **'Background detection uses a small amount of battery.'**
  String get quickFetchConsent4;

  /// No description provided for @quickFetchTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get quickFetchTurnOn;

  /// No description provided for @watchedDomainsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit watched sites'**
  String get watchedDomainsEditTitle;

  /// No description provided for @watchedDomainsOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One domain per line.'**
  String get watchedDomainsOnePerLine;

  /// No description provided for @watchedDomainsAddUrl.
  ///
  /// In en, this message translates to:
  /// **'Add URL'**
  String get watchedDomainsAddUrl;

  /// No description provided for @watchedDomainsExampleHint.
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get watchedDomainsExampleHint;

  /// No description provided for @watchedDomainsInvalidDomain.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a website domain.'**
  String get watchedDomainsInvalidDomain;

  /// No description provided for @watchedDomainsResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get watchedDomainsResetToDefaults;

  /// No description provided for @watchedDomainsResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults?'**
  String get watchedDomainsResetConfirmTitle;

  /// No description provided for @watchedDomainsResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This discards any sites you added or removed and restores the built-in list.'**
  String get watchedDomainsResetConfirmBody;

  /// No description provided for @watchedDomainsDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get watchedDomainsDiscardTitle;

  /// No description provided for @watchedDomainsDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved.'**
  String get watchedDomainsDiscardBody;

  /// No description provided for @watchedDomainsKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get watchedDomainsKeepEditing;

  /// No description provided for @watchedDomainsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get watchedDomainsDiscard;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Caption above the System/Light/Dark selector in Settings > Appearance. Sits alongside the Language caption, which is why the group now needs a label of its own.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @sectionDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get sectionDownloads;

  /// No description provided for @downloadLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocationTitle;

  /// No description provided for @sectionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get sectionAccounts;

  /// No description provided for @connectedAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts / Sessions'**
  String get connectedAccountsTitle;

  /// No description provided for @connectedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: connect a platform session for account-required content.'**
  String get connectedAccountsSubtitle;

  /// No description provided for @sectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sectionHistory;

  /// No description provided for @historySaveEnabled.
  ///
  /// In en, this message translates to:
  /// **'Save download history'**
  String get historySaveEnabled;

  /// No description provided for @historySaveDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep a local record of your downloads.'**
  String get historySaveDescription;

  /// No description provided for @historyClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClearAction;

  /// No description provided for @sectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get sectionAdvanced;

  /// No description provided for @rootFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Root Features'**
  String get rootFeaturesTitle;

  /// No description provided for @rootFeaturesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon, not available yet.'**
  String get rootFeaturesComingSoon;

  /// No description provided for @sectionDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get sectionDiagnostics;

  /// No description provided for @technicalInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical information'**
  String get technicalInformationTitle;

  /// No description provided for @technicalInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Known platform limitations, developer information, and what to do when a download fails.'**
  String get technicalInformationSubtitle;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @downloadLocationSummary.
  ///
  /// In en, this message translates to:
  /// **'{organization} · Video: {video} · Audio: {audio}'**
  String downloadLocationSummary(
    String organization,
    String video,
    String audio,
  );

  /// No description provided for @engineTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get engineTileTitle;

  /// No description provided for @diagnosticsLimitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitations'**
  String get diagnosticsLimitationsTitle;

  /// No description provided for @diagnosticsLimitationsBody.
  ///
  /// In en, this message translates to:
  /// **'A download can fail for a few reasons:\n1. The site needs you to be signed in.\n2. The content is restricted.\n3. The site is temporarily blocking requests like this.\n4. This type of content isn\'t fully supported yet.\n\nSigning in or adding cookies can help sometimes, but it won\'t make every video downloadable.'**
  String get diagnosticsLimitationsBody;

  /// No description provided for @diagnosticsDeveloperInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer information'**
  String get diagnosticsDeveloperInfoTitle;

  /// No description provided for @diagnosticsDeveloperInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For advanced users investigating extraction problems.'**
  String get diagnosticsDeveloperInfoSubtitle;

  /// No description provided for @diagnosticsSessionsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Sessions are stored locally on this device and encrypted with Android Keystore protection. Fetchy has no server and does not upload sessions or cookies.'**
  String get diagnosticsSessionsPrivacy;

  /// No description provided for @diagnosticsUpstreamResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upstream resources'**
  String get diagnosticsUpstreamResourcesTitle;

  /// No description provided for @diagnosticsEngineFindInSettings.
  ///
  /// In en, this message translates to:
  /// **'Find these in Settings, under Engine.'**
  String get diagnosticsEngineFindInSettings;

  /// No description provided for @diagnosticsEngineFfmpegBundled.
  ///
  /// In en, this message translates to:
  /// **'Bundled with the app'**
  String get diagnosticsEngineFfmpegBundled;

  /// No description provided for @developerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer information'**
  String get developerInfoTitle;

  /// No description provided for @developerInfoIntro.
  ///
  /// In en, this message translates to:
  /// **'For advanced users investigating extraction problems. This is safe to paste into a GitHub issue.'**
  String get developerInfoIntro;

  /// No description provided for @developerInfoEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No recent Fetch failure to show. Details appear here after a Fetch fails and you open this from that failure\'s Info button.'**
  String get developerInfoEmptyState;

  /// No description provided for @developerInfoCopyTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy technical details'**
  String get developerInfoCopyTechnicalDetails;

  /// No description provided for @developerInfoTechnicalDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Technical details copied.'**
  String get developerInfoTechnicalDetailsCopied;

  /// No description provided for @developerInfoPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get developerInfoPlatformLabel;

  /// No description provided for @developerInfoExtractorLabel.
  ///
  /// In en, this message translates to:
  /// **'Extractor'**
  String get developerInfoExtractorLabel;

  /// No description provided for @developerInfoVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp version'**
  String get developerInfoVersionLabel;

  /// No description provided for @developerInfoAppVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get developerInfoAppVersionLabel;

  /// No description provided for @developerInfoErrorCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Error category'**
  String get developerInfoErrorCategoryLabel;

  /// No description provided for @developerInfoSanitizedMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sanitized message'**
  String get developerInfoSanitizedMessageTitle;

  /// No description provided for @developerInfoKnownLimitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Relevant known limitation'**
  String get developerInfoKnownLimitationTitle;

  /// No description provided for @developerInfoUpstreamIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible upstream issue'**
  String get developerInfoUpstreamIssueTitle;

  /// No description provided for @developerInfoDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get developerInfoDetailTitle;

  /// No description provided for @developerInfoNoAdditionalDetail.
  ///
  /// In en, this message translates to:
  /// **'(no additional detail)'**
  String get developerInfoNoAdditionalDetail;

  /// No description provided for @developerInfoNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get developerInfoNotApplicable;

  /// No description provided for @developerInfoUpstreamIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Could be a known yt-dlp limitation. Check {url}'**
  String developerInfoUpstreamIssueHint(String url);

  /// No description provided for @developerInfoUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get developerInfoUnknown;

  /// No description provided for @errorMorePossibleReasons.
  ///
  /// In en, this message translates to:
  /// **'Possible reasons'**
  String get errorMorePossibleReasons;

  /// No description provided for @errorMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'More information'**
  String get errorMoreInformation;

  /// No description provided for @errorSettingsPointer.
  ///
  /// In en, this message translates to:
  /// **'Settings → Technical information'**
  String get errorSettingsPointer;

  /// No description provided for @errorDeveloperInformation.
  ///
  /// In en, this message translates to:
  /// **'Developer information'**
  String get errorDeveloperInformation;

  /// No description provided for @errorWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get errorWhy;

  /// No description provided for @errorConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get errorConnectedAccounts;

  /// No description provided for @errorImportSession.
  ///
  /// In en, this message translates to:
  /// **'Import session'**
  String get errorImportSession;

  /// No description provided for @errorReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get errorReconnect;

  /// No description provided for @errorTitleAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in may be required'**
  String get errorTitleAuthRequired;

  /// No description provided for @errorTitleSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session may have expired'**
  String get errorTitleSessionExpired;

  /// No description provided for @errorTitleSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Your session may no longer be valid'**
  String get errorTitleSessionInvalid;

  /// No description provided for @errorTitlePlatformRestricted.
  ///
  /// In en, this message translates to:
  /// **'This content is restricted'**
  String get errorTitlePlatformRestricted;

  /// No description provided for @errorTitleAntiBot.
  ///
  /// In en, this message translates to:
  /// **'The platform is blocking this request'**
  String get errorTitleAntiBot;

  /// No description provided for @errorTitleNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the platform'**
  String get errorTitleNetworkError;

  /// No description provided for @errorTitleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t supported'**
  String get errorTitleUnsupported;

  /// No description provided for @errorTitleExtractorError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t process this media'**
  String get errorTitleExtractorError;

  /// No description provided for @errorTitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitleUnknown;

  /// No description provided for @errorReasonAuthRequired1.
  ///
  /// In en, this message translates to:
  /// **'This content may require you to be signed in.'**
  String get errorReasonAuthRequired1;

  /// No description provided for @errorReasonAuthRequired2.
  ///
  /// In en, this message translates to:
  /// **'{subject} may restrict it to logged-in accounts.'**
  String errorReasonAuthRequired2(String subject);

  /// No description provided for @errorReasonAuthRequired3.
  ///
  /// In en, this message translates to:
  /// **'Signing in can help with some restricted content, but it doesn\'t guarantee access.'**
  String get errorReasonAuthRequired3;

  /// No description provided for @errorReasonSessionExpired1.
  ///
  /// In en, this message translates to:
  /// **'Your saved session may have expired.'**
  String get errorReasonSessionExpired1;

  /// No description provided for @errorReasonSessionExpired2.
  ///
  /// In en, this message translates to:
  /// **'{subject} may have signed the session out.'**
  String errorReasonSessionExpired2(String subject);

  /// No description provided for @errorReasonSessionInvalid1.
  ///
  /// In en, this message translates to:
  /// **'This saved session may no longer carry the right access for {subject}.'**
  String errorReasonSessionInvalid1(String subject);

  /// No description provided for @errorReasonSessionInvalid2.
  ///
  /// In en, this message translates to:
  /// **'It may have been revoked or replaced by a newer sign-in elsewhere.'**
  String get errorReasonSessionInvalid2;

  /// No description provided for @errorReasonPlatformRestricted1.
  ///
  /// In en, this message translates to:
  /// **'The content may have been removed or made private.'**
  String get errorReasonPlatformRestricted1;

  /// No description provided for @errorReasonPlatformRestricted2.
  ///
  /// In en, this message translates to:
  /// **'It may be restricted in your region.'**
  String get errorReasonPlatformRestricted2;

  /// No description provided for @errorReasonPlatformRestricted3.
  ///
  /// In en, this message translates to:
  /// **'{subject} may have taken it down for a policy reason.'**
  String errorReasonPlatformRestricted3(String subject);

  /// No description provided for @errorReasonAntiBot1.
  ///
  /// In en, this message translates to:
  /// **'{subject} may be rate-limiting or challenging this type of request.'**
  String errorReasonAntiBot1(String subject);

  /// No description provided for @errorReasonAntiBot2.
  ///
  /// In en, this message translates to:
  /// **'This is often temporary.'**
  String get errorReasonAntiBot2;

  /// No description provided for @errorReasonAntiBot3.
  ///
  /// In en, this message translates to:
  /// **'This is a limitation of the platform\'s protection system. Signing in may not solve it.'**
  String get errorReasonAntiBot3;

  /// No description provided for @errorReasonImpersonation1.
  ///
  /// In en, this message translates to:
  /// **'{subject} may have changed its delivery system.'**
  String errorReasonImpersonation1(String subject);

  /// No description provided for @errorReasonImpersonation2.
  ///
  /// In en, this message translates to:
  /// **'This is an environment limitation, not an account or content issue.'**
  String get errorReasonImpersonation2;

  /// No description provided for @errorReasonNetwork1.
  ///
  /// In en, this message translates to:
  /// **'Your device may be offline.'**
  String get errorReasonNetwork1;

  /// No description provided for @errorReasonNetwork2.
  ///
  /// In en, this message translates to:
  /// **'{subject}\'s servers may be temporarily unreachable.'**
  String errorReasonNetwork2(String subject);

  /// No description provided for @errorReasonUnsupported1.
  ///
  /// In en, this message translates to:
  /// **'This link format is not currently supported.'**
  String get errorReasonUnsupported1;

  /// No description provided for @errorReasonExtractor1.
  ///
  /// In en, this message translates to:
  /// **'{subject} may have changed how it delivers this content.'**
  String errorReasonExtractor1(String subject);

  /// No description provided for @errorReasonExtractor2.
  ///
  /// In en, this message translates to:
  /// **'This can sometimes resolve itself on retry.'**
  String get errorReasonExtractor2;

  /// No description provided for @errorReasonUnknown1.
  ///
  /// In en, this message translates to:
  /// **'{subject} might need you to sign in.'**
  String errorReasonUnknown1(String subject);

  /// No description provided for @errorReasonUnknown2.
  ///
  /// In en, this message translates to:
  /// **'The content could be restricted.'**
  String get errorReasonUnknown2;

  /// No description provided for @errorReasonUnknown3.
  ///
  /// In en, this message translates to:
  /// **'{subject} may be temporarily blocking this request.'**
  String errorReasonUnknown3(String subject);

  /// No description provided for @errorReasonUnknown4.
  ///
  /// In en, this message translates to:
  /// **'This type of content might not be supported yet.'**
  String get errorReasonUnknown4;

  /// No description provided for @errorReasonUnknown5.
  ///
  /// In en, this message translates to:
  /// **'Signing in or adding cookies could help, but not always.'**
  String get errorReasonUnknown5;

  /// No description provided for @errorLimitationAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'The extractor requires an authenticated session for this content and none is attached.'**
  String get errorLimitationAuthRequired;

  /// No description provided for @errorLimitationSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'The attached session cookies appear to have expired.'**
  String get errorLimitationSessionExpired;

  /// No description provided for @errorLimitationSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'The attached session cookies are being rejected as invalid.'**
  String get errorLimitationSessionInvalid;

  /// No description provided for @errorLimitationPlatformRestricted.
  ///
  /// In en, this message translates to:
  /// **'The platform reports this content as unavailable (removed, private, or geo-restricted).'**
  String get errorLimitationPlatformRestricted;

  /// No description provided for @errorLimitationAntiBot.
  ///
  /// In en, this message translates to:
  /// **'The platform\'s bot-detection or rate-limiting rejected this request.'**
  String get errorLimitationAntiBot;

  /// No description provided for @errorLimitationImpersonation.
  ///
  /// In en, this message translates to:
  /// **'This extractor requires TLS client impersonation (curl_cffi) not present in this build.'**
  String get errorLimitationImpersonation;

  /// No description provided for @errorLimitationNetwork.
  ///
  /// In en, this message translates to:
  /// **'The request could not reach the platform (connectivity or DNS failure).'**
  String get errorLimitationNetwork;

  /// No description provided for @errorLimitationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'No extractor in this yt-dlp build recognizes this URL.'**
  String get errorLimitationUnsupported;

  /// No description provided for @errorLimitationExtractor.
  ///
  /// In en, this message translates to:
  /// **'The platform\'s page or response format was not what the extractor expected, likely a recent platform-side change.'**
  String get errorLimitationExtractor;

  /// No description provided for @errorLimitationUnknown.
  ///
  /// In en, this message translates to:
  /// **'The failure text did not match any recognized category.'**
  String get errorLimitationUnknown;

  /// No description provided for @errorMessageAuthRequiredGeneric.
  ///
  /// In en, this message translates to:
  /// **'This content may require you to be signed in.'**
  String get errorMessageAuthRequiredGeneric;

  /// No description provided for @errorMessageAuthRequiredTikTok.
  ///
  /// In en, this message translates to:
  /// **'This TikTok is restricted or requires login.'**
  String get errorMessageAuthRequiredTikTok;

  /// No description provided for @errorMessageSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your saved session may have expired. Reconnect it and try again.'**
  String get errorMessageSessionExpired;

  /// No description provided for @errorMessageSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This saved session is no longer valid.'**
  String get errorMessageSessionInvalid;

  /// No description provided for @errorMessageImpersonationWithPlatform.
  ///
  /// In en, this message translates to:
  /// **'{platform} couldn\'t provide this video right now.'**
  String errorMessageImpersonationWithPlatform(String platform);

  /// No description provided for @errorMessageImpersonationGeneric.
  ///
  /// In en, this message translates to:
  /// **'This video couldn\'t be retrieved right now.'**
  String get errorMessageImpersonationGeneric;

  /// No description provided for @errorMessageAntiBot.
  ///
  /// In en, this message translates to:
  /// **'The platform is currently blocking this type of request.'**
  String get errorMessageAntiBot;

  /// No description provided for @errorMessagePlatformRestricted.
  ///
  /// In en, this message translates to:
  /// **'This content is restricted by the platform.'**
  String get errorMessagePlatformRestricted;

  /// No description provided for @errorMessageNetworkWithPlatform.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {platform}. Check your connection and try again.'**
  String errorMessageNetworkWithPlatform(String platform);

  /// No description provided for @errorMessageNetworkGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get errorMessageNetworkGeneric;

  /// No description provided for @errorMessageUnsupportedTikTok.
  ///
  /// In en, this message translates to:
  /// **'This TikTok link isn\'t supported.'**
  String get errorMessageUnsupportedTikTok;

  /// No description provided for @errorMessageUnsupportedWithSubject.
  ///
  /// In en, this message translates to:
  /// **'{subject} isn\'t supported.'**
  String errorMessageUnsupportedWithSubject(String subject);

  /// No description provided for @errorMessageExtractor.
  ///
  /// In en, this message translates to:
  /// **'This couldn\'t be extracted right now.'**
  String get errorMessageExtractor;

  /// No description provided for @errorMessageUnknownEmpty.
  ///
  /// In en, this message translates to:
  /// **'{subject} could not be fetched.'**
  String errorMessageUnknownEmpty(String subject);

  /// No description provided for @errorMessageUnknownGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while fetching this media.'**
  String get errorMessageUnknownGeneric;

  /// No description provided for @errorSubjectFallback.
  ///
  /// In en, this message translates to:
  /// **'The platform'**
  String get errorSubjectFallback;

  /// No description provided for @errorSubjectThisLink.
  ///
  /// In en, this message translates to:
  /// **'This link'**
  String get errorSubjectThisLink;

  /// No description provided for @upstreamYtDlpRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get upstreamYtDlpRepo;

  /// No description provided for @upstreamYtDlpIssues.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get upstreamYtDlpIssues;

  /// No description provided for @upstreamDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get upstreamDocumentation;

  /// No description provided for @sessionsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get sessionsPageTitle;

  /// No description provided for @sessionsPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Fetchy is offline first. Your sessions are stored locally on this device. Fetchy does not upload your sessions to a Fetchy server.\n\nA connected session may help with account-required content, but it cannot bypass every platform restriction.'**
  String get sessionsPrivacyNotice;

  /// No description provided for @sessionsPlatformsSection.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get sessionsPlatformsSection;

  /// No description provided for @sessionsOtherSitesSection.
  ///
  /// In en, this message translates to:
  /// **'Other sites'**
  String get sessionsOtherSitesSection;

  /// No description provided for @sessionsNoCustomSites.
  ///
  /// In en, this message translates to:
  /// **'No custom sites yet.'**
  String get sessionsNoCustomSites;

  /// No description provided for @sessionsAddCookiesForOtherSites.
  ///
  /// In en, this message translates to:
  /// **'Add cookies for other sites'**
  String get sessionsAddCookiesForOtherSites;

  /// No description provided for @sessionsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sessionsConnected;

  /// No description provided for @sessionsRemoveSiteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {domain}?'**
  String sessionsRemoveSiteConfirmTitle(String domain);

  /// No description provided for @sessionsRemoveSiteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This securely deletes the stored cookies for this site from this device. You can add it again at any time.'**
  String get sessionsRemoveSiteConfirmBody;

  /// No description provided for @sessionsAddCookiesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add cookies for other sites'**
  String get sessionsAddCookiesDialogTitle;

  /// No description provided for @sessionsEnterWebsite.
  ///
  /// In en, this message translates to:
  /// **'Enter the website these cookies belong to.'**
  String get sessionsEnterWebsite;

  /// No description provided for @sessionsWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get sessionsWebsiteLabel;

  /// No description provided for @sessionsWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get sessionsWebsiteHint;

  /// No description provided for @sessionsCookiesImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'{domain} cookies imported.'**
  String sessionsCookiesImportedMessage(String domain);

  /// No description provided for @sessionsCouldNotImportCookies.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import those cookies.'**
  String get sessionsCouldNotImportCookies;

  /// No description provided for @sessionsPasteCookiesForWebsite.
  ///
  /// In en, this message translates to:
  /// **'Paste cookies for {website}'**
  String sessionsPasteCookiesForWebsite(String website);

  /// No description provided for @sessionsPasteCookiesHelp.
  ///
  /// In en, this message translates to:
  /// **'Paste the contents of a Netscape-format cookies.txt export, the same format browser cookie-export extensions produce.'**
  String get sessionsPasteCookiesHelp;

  /// No description provided for @sessionsCookieFileHint.
  ///
  /// In en, this message translates to:
  /// **'# Netscape HTTP Cookie File\n...'**
  String get sessionsCookieFileHint;

  /// No description provided for @sessionsSessionConnectedMessage.
  ///
  /// In en, this message translates to:
  /// **'{platform} session connected.'**
  String sessionsSessionConnectedMessage(String platform);

  /// No description provided for @sessionsCouldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a browser to sign in.'**
  String get sessionsCouldNotOpenBrowser;

  /// No description provided for @sessionsBrowserUnconfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fetchy can\'t confirm what happened in your browser'**
  String get sessionsBrowserUnconfirmedTitle;

  /// No description provided for @sessionsBrowserUnconfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'If you signed in, this browser session can\'t be transferred to Fetchy automatically on this device. To use that account in Fetchy, import your session cookies using Advanced.'**
  String get sessionsBrowserUnconfirmedBody;

  /// No description provided for @sessionsNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get sessionsNotNow;

  /// No description provided for @sessionsImportCookiesNow.
  ///
  /// In en, this message translates to:
  /// **'Import cookies now'**
  String get sessionsImportCookiesNow;

  /// No description provided for @sessionsSessionImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'{platform} session imported.'**
  String sessionsSessionImportedMessage(String platform);

  /// No description provided for @sessionsCouldNotImportSession.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import that session.'**
  String get sessionsCouldNotImportSession;

  /// No description provided for @sessionsCouldNotCompleteTest.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete the test.'**
  String get sessionsCouldNotCompleteTest;

  /// No description provided for @sessionsTestConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get sessionsTestConnectionTitle;

  /// No description provided for @sessionsTestConnectionResultTitle.
  ///
  /// In en, this message translates to:
  /// **'{platform} test connection'**
  String sessionsTestConnectionResultTitle(String platform);

  /// No description provided for @sessionsTestUrlPrompt.
  ///
  /// In en, this message translates to:
  /// **'Paste a {platform} link to test this session against. This just does a quick lookup, nothing is downloaded.'**
  String sessionsTestUrlPrompt(String platform);

  /// No description provided for @sessionsUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get sessionsUrlHint;

  /// No description provided for @sessionsExportSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Export session?'**
  String get sessionsExportSessionTitle;

  /// No description provided for @sessionsExportSessionBody.
  ///
  /// In en, this message translates to:
  /// **'The exported file contains login details for your account. Anyone with this file can access your account on this platform.\n\nDon\'t share it with anyone. Fetchy never uploads it anywhere, you choose where it gets saved.'**
  String get sessionsExportSessionBody;

  /// No description provided for @sessionsSessionExported.
  ///
  /// In en, this message translates to:
  /// **'Session exported.'**
  String get sessionsSessionExported;

  /// No description provided for @sessionsCouldNotExportSession.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export that session.'**
  String get sessionsCouldNotExportSession;

  /// No description provided for @sessionsRemoveSessionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {platform} session?'**
  String sessionsRemoveSessionConfirmTitle(String platform);

  /// No description provided for @sessionsRemoveSessionConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This securely deletes the stored session from this device. You can reconnect at any time.'**
  String get sessionsRemoveSessionConfirmBody;

  /// No description provided for @sessionsExperimentalTag.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get sessionsExperimentalTag;

  /// No description provided for @sessionsImportRequiredTag.
  ///
  /// In en, this message translates to:
  /// **'Session import required'**
  String get sessionsImportRequiredTag;

  /// No description provided for @sessionsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get sessionsNotConnected;

  /// No description provided for @sessionsXBlocksInAppBrowser.
  ///
  /// In en, this message translates to:
  /// **'X blocks in-app browser sign-in from carrying a session into apps like Fetchy. Import cookies.txt below to use a signed-in session here.'**
  String get sessionsXBlocksInAppBrowser;

  /// No description provided for @sessionsImportCookiesTxtTitle.
  ///
  /// In en, this message translates to:
  /// **'Import cookies.txt'**
  String get sessionsImportCookiesTxtTitle;

  /// No description provided for @sessionsImportCookiesTxtSubtitleAvailable.
  ///
  /// In en, this message translates to:
  /// **'The practical way to use X on Fetchy: export cookies.txt from your signed-in browser and import it here.'**
  String get sessionsImportCookiesTxtSubtitleAvailable;

  /// No description provided for @sessionsOpenInBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get sessionsOpenInBrowserTitle;

  /// No description provided for @sessionsOpenInBrowserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens X in your regular browser, for convenience only. This doesn\'t import a session into Fetchy. Use Import cookies.txt above for that.'**
  String get sessionsOpenInBrowserSubtitle;

  /// No description provided for @sessionsSignInBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your browser'**
  String get sessionsSignInBrowserTitle;

  /// No description provided for @sessionsSignInBrowserTitleExperimental.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your browser (Experimental)'**
  String get sessionsSignInBrowserTitleExperimental;

  /// No description provided for @sessionsSignInTikTokRedirectWarning.
  ///
  /// In en, this message translates to:
  /// **'TikTok\'s login page may redirect to the TikTok app before Fetchy can capture a session. If that happens, use Import cookies / session file below instead. It always works.'**
  String get sessionsSignInTikTokRedirectWarning;

  /// No description provided for @sessionsSignInGenericSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in through {platform}\'s own login page in your browser.'**
  String sessionsSignInGenericSubtitle(String platform);

  /// No description provided for @sessionsImportCookiesFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Import cookies / session file'**
  String get sessionsImportCookiesFileTitle;

  /// No description provided for @sessionsImportCookiesFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For advanced users: import a cookies.txt export.'**
  String get sessionsImportCookiesFileSubtitle;

  /// No description provided for @sessionsRootAssistedTitle.
  ///
  /// In en, this message translates to:
  /// **'Root-assisted browser/session import'**
  String get sessionsRootAssistedTitle;

  /// No description provided for @sessionsRootAssistedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetchy doesn\'t decrypt Chrome or other browser databases directly. That needs specialized, device-specific tools Fetchy can\'t safely automate. If you\'ve used a root tool to extract a cookie file for {platform}, convert it to cookies.txt format and bring it in with \'Import cookies / session file\' above. It\'s the same path either way.'**
  String sessionsRootAssistedSubtitle(String platform);

  /// No description provided for @sessionsTestConnectionTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get sessionsTestConnectionTileTitle;

  /// No description provided for @sessionsTestConnectionAvailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run a lightweight check using a link you provide.'**
  String get sessionsTestConnectionAvailableSubtitle;

  /// No description provided for @sessionsTestConnectionUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a session first.'**
  String get sessionsTestConnectionUnavailableSubtitle;

  /// No description provided for @sessionsExportSessionTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Export session'**
  String get sessionsExportSessionTileTitle;

  /// No description provided for @sessionsExportSessionTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only if you explicitly need a copy. Handle with care.'**
  String get sessionsExportSessionTileSubtitle;

  /// No description provided for @sessionsRemoveSessionTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove session'**
  String get sessionsRemoveSessionTileTitle;

  /// No description provided for @sessionsRemoveSessionTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Securely deletes the stored session from this device.'**
  String get sessionsRemoveSessionTileSubtitle;

  /// No description provided for @sessionsCookieSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie source'**
  String get sessionsCookieSourceTitle;

  /// No description provided for @sessionsCookieSourcePrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you want to bring in cookies for {website}?'**
  String sessionsCookieSourcePrompt(String website);

  /// No description provided for @sessionsImportCookieFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Import cookie file'**
  String get sessionsImportCookieFileTitle;

  /// No description provided for @sessionsImportCookieFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import a cookies.txt export for this site.'**
  String get sessionsImportCookieFileSubtitle;

  /// No description provided for @sessionsPasteCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste cookies'**
  String get sessionsPasteCookiesTitle;

  /// No description provided for @sessionsPasteCookiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste Netscape-format cookie text directly.'**
  String get sessionsPasteCookiesSubtitle;

  /// No description provided for @sessionsStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sessionsStatusConnected;

  /// No description provided for @sessionsStatusConnectedWorks.
  ///
  /// In en, this message translates to:
  /// **'Connected · Session works'**
  String get sessionsStatusConnectedWorks;

  /// No description provided for @sessionsStatusConnectedUnverified.
  ///
  /// In en, this message translates to:
  /// **'Connected · Status couldn\'t be verified'**
  String get sessionsStatusConnectedUnverified;

  /// No description provided for @sessionsStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get sessionsStatusExpired;

  /// No description provided for @sessionsStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get sessionsStatusInvalid;

  /// No description provided for @sessionsStatusNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get sessionsStatusNotConnected;

  /// No description provided for @sessionsStatusImportRequired.
  ///
  /// In en, this message translates to:
  /// **'Session import required'**
  String get sessionsStatusImportRequired;

  /// No description provided for @sessionsTestWorks.
  ///
  /// In en, this message translates to:
  /// **'Session works for this test.'**
  String get sessionsTestWorks;

  /// No description provided for @sessionsTestStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Session status couldn\'t be verified: {message}'**
  String sessionsTestStatusUnverified(String message);

  /// No description provided for @sessionsCookieFileInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file could not be used as a session.'**
  String get sessionsCookieFileInvalid;

  /// No description provided for @sessionsCustomCookieInvalid.
  ///
  /// In en, this message translates to:
  /// **'Those cookies could not be used.'**
  String get sessionsCustomCookieInvalid;

  /// No description provided for @sessionWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a platform session?'**
  String get sessionWarningTitle;

  /// No description provided for @sessionWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Your session can include login details for your account.\n\nFetchy stores it on this device only, and it\'s encrypted.\n\nIf you ever export a session file, don\'t share it with anyone.\n\nConnecting a session doesn\'t guarantee restricted or protected content will download.'**
  String get sessionWarningBody;

  /// No description provided for @duplicateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get duplicateDialogTitle;

  /// No description provided for @duplicateDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This file already exists on your device:'**
  String get duplicateDialogBody;

  /// No description provided for @duplicateDialogDownloadAgain.
  ///
  /// In en, this message translates to:
  /// **'Download again'**
  String get duplicateDialogDownloadAgain;

  /// No description provided for @duplicateDialogDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Downloads/Fetchy'**
  String get duplicateDialogDefaultPath;

  /// No description provided for @downloadLocationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Download Location'**
  String get downloadLocationTitleLabel;

  /// No description provided for @downloadLocationIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose where videos and audio are saved, and whether Fetchy keeps them organized in its own folders. This only changes where files go. Filename and quality are separate settings.'**
  String get downloadLocationIntro;

  /// No description provided for @downloadLocationVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get downloadLocationVideoLabel;

  /// No description provided for @downloadLocationAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get downloadLocationAudioLabel;

  /// No description provided for @downloadLocationBaseFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Base folder'**
  String get downloadLocationBaseFolderTitle;

  /// No description provided for @downloadLocationVideoLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Video location'**
  String get downloadLocationVideoLocationTitle;

  /// No description provided for @downloadLocationAudioLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio location'**
  String get downloadLocationAudioLocationTitle;

  /// No description provided for @downloadLocationSameAsVideo.
  ///
  /// In en, this message translates to:
  /// **'Same as video'**
  String get downloadLocationSameAsVideo;

  /// No description provided for @downloadLocationDifferentFolder.
  ///
  /// In en, this message translates to:
  /// **'Use different folder'**
  String get downloadLocationDifferentFolder;

  /// No description provided for @downloadLocationSameFolderAsVideo.
  ///
  /// In en, this message translates to:
  /// **'Same folder as video'**
  String get downloadLocationSameFolderAsVideo;

  /// No description provided for @downloadLocationFolderInaccessible.
  ///
  /// In en, this message translates to:
  /// **'This folder is no longer accessible. Choose a new one.'**
  String get downloadLocationFolderInaccessible;

  /// No description provided for @downloadLocationNoFolderChosen.
  ///
  /// In en, this message translates to:
  /// **'No folder chosen'**
  String get downloadLocationNoFolderChosen;

  /// No description provided for @downloadLocationChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get downloadLocationChooseFolder;

  /// No description provided for @downloadLocationOrganizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get downloadLocationOrganizationTitle;

  /// No description provided for @downloadLocationUseSubfolders.
  ///
  /// In en, this message translates to:
  /// **'Use Fetchy subfolders'**
  String get downloadLocationUseSubfolders;

  /// No description provided for @downloadLocationUseSubfoldersOnDescription.
  ///
  /// In en, this message translates to:
  /// **'Fetchy creates its own Videos and Audio subfolders inside the base folder above.'**
  String get downloadLocationUseSubfoldersOnDescription;

  /// No description provided for @downloadLocationUseSubfoldersOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Files are saved directly in the base folder above, with no Fetchy subfolder.'**
  String get downloadLocationUseSubfoldersOffDescription;

  /// No description provided for @storageBaseAndroidDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Android default folders'**
  String get storageBaseAndroidDefaultLabel;

  /// No description provided for @storageBaseAndroidDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Movies and Music, the same folders other apps use.'**
  String get storageBaseAndroidDefaultDescription;

  /// No description provided for @storageBaseCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom folder'**
  String get storageBaseCustomLabel;

  /// No description provided for @storageBaseCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose exactly where files are saved.'**
  String get storageBaseCustomDescription;

  /// No description provided for @storageSelectedFolderFallback.
  ///
  /// In en, this message translates to:
  /// **'Selected folder'**
  String get storageSelectedFolderFallback;

  /// No description provided for @storageVideoLocationCustom.
  ///
  /// In en, this message translates to:
  /// **'{folder} / Videos'**
  String storageVideoLocationCustom(String folder);

  /// No description provided for @storageAudioLocationCustom.
  ///
  /// In en, this message translates to:
  /// **'{folder} / Audio'**
  String storageAudioLocationCustom(String folder);

  /// No description provided for @storageVideoLocationDefaultSubfolders.
  ///
  /// In en, this message translates to:
  /// **'Movies / Fetchy / Videos'**
  String get storageVideoLocationDefaultSubfolders;

  /// No description provided for @storageVideoLocationDefault.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get storageVideoLocationDefault;

  /// No description provided for @storageAudioLocationDefaultSubfolders.
  ///
  /// In en, this message translates to:
  /// **'Music / Fetchy / Audio'**
  String get storageAudioLocationDefaultSubfolders;

  /// No description provided for @storageAudioLocationDefault.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get storageAudioLocationDefault;

  /// No description provided for @storageOrganizedSummary.
  ///
  /// In en, this message translates to:
  /// **'Fetchy-organized · {baseLabel}'**
  String storageOrganizedSummary(String baseLabel);

  /// One-word summary shown on the Settings row for the Download Location, when the Android default media folders are in use. The full configuration is shown on the Download Location screen itself.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get storageSummaryDefault;

  /// One-word summary shown on the Settings row for the Download Location, when a user-picked folder is in use.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get storageSummaryCustom;

  /// No description provided for @historyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyPageTitle;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get historySearchHint;

  /// No description provided for @historyClearHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClearHistoryTooltip;

  /// No description provided for @historyClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get historyClearHistoryTitle;

  /// No description provided for @historyClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all recorded downloads from this device. It does not delete the downloaded files themselves.'**
  String get historyClearHistoryBody;

  /// No description provided for @historyNoMatchingDownloads.
  ///
  /// In en, this message translates to:
  /// **'No matching downloads'**
  String get historyNoMatchingDownloads;

  /// No description provided for @historyTryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search terms or filters.'**
  String get historyTryChangingFilters;

  /// No description provided for @historyResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get historyResetFilters;

  /// No description provided for @historyNoHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyNoHistoryYet;

  /// No description provided for @historyDownloadsWillShowHere.
  ///
  /// In en, this message translates to:
  /// **'Downloads you complete will show up here.'**
  String get historyDownloadsWillShowHere;

  /// No description provided for @historyFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get historyFilterTooltip;

  /// No description provided for @historyMediaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Media type'**
  String get historyMediaTypeLabel;

  /// No description provided for @historySourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get historySourceLabel;

  /// No description provided for @historyMediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get historyMediaTypeVideo;

  /// No description provided for @historyMediaTypeAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get historyMediaTypeAudio;

  /// No description provided for @historySourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get historySourceOther;

  /// No description provided for @historyFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get historyFileMissing;

  /// No description provided for @historyJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get historyJustNow;

  /// No description provided for @historyMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String historyMinutesAgo(int minutes);

  /// No description provided for @historyHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String historyHoursAgo(int hours);

  /// No description provided for @historyDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String historyDaysAgo(int days);

  /// No description provided for @historyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Download details'**
  String get historyDetailTitle;

  /// No description provided for @historyFileAvailable.
  ///
  /// In en, this message translates to:
  /// **'File available on device'**
  String get historyFileAvailable;

  /// No description provided for @historyFileMissingOrRemoved.
  ///
  /// In en, this message translates to:
  /// **'File missing or removed from storage'**
  String get historyFileMissingOrRemoved;

  /// No description provided for @historySourceUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Source URL'**
  String get historySourceUrlLabel;

  /// No description provided for @historyPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get historyPlatformLabel;

  /// No description provided for @historyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get historyTypeLabel;

  /// No description provided for @historyQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get historyQualityLabel;

  /// No description provided for @historyFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get historyFormatLabel;

  /// No description provided for @historyFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get historyFileNameLabel;

  /// No description provided for @historyFileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get historyFileSizeLabel;

  /// No description provided for @historySavedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get historySavedToLabel;

  /// No description provided for @historyCopySourceUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy source URL'**
  String get historyCopySourceUrl;

  /// No description provided for @historyLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get historyLinkCopied;

  /// No description provided for @rootFeaturesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced / Root Features'**
  String get rootFeaturesPageTitle;

  /// No description provided for @rootFeaturesComingSoonTag.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get rootFeaturesComingSoonTag;

  /// No description provided for @rootFeaturesDescription.
  ///
  /// In en, this message translates to:
  /// **'Root-assisted features are planned for a future release. This build doesn\'t check for root, request root access, or run any root command. Fetchy behaves like a normal app without root.'**
  String get rootFeaturesDescription;

  /// No description provided for @rootFeaturesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Root features'**
  String get rootFeaturesSectionTitle;

  /// No description provided for @rootFeaturesBrowserImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Browser session import helper'**
  String get rootFeaturesBrowserImportTitle;

  /// No description provided for @rootFeaturesBrowserImportReason.
  ///
  /// In en, this message translates to:
  /// **'this is deliberate, not a gap to close later. Modern Chrome/Chromium stores cookies in an encrypted database tied to the Android Keystore. Decrypting it isn\'t something Fetchy can do safely or reliably on its own, even with root access, and getting it wrong risks corrupting a real browser\'s data.'**
  String get rootFeaturesBrowserImportReason;

  /// No description provided for @rootFeaturesDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced diagnostics'**
  String get rootFeaturesDiagnosticsTitle;

  /// No description provided for @rootFeaturesDiagnosticsReason.
  ///
  /// In en, this message translates to:
  /// **'Not implemented. No specific diagnostic data has been scoped yet.'**
  String get rootFeaturesDiagnosticsReason;

  /// No description provided for @rootFeaturesFileAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional file access improvements'**
  String get rootFeaturesFileAccessTitle;

  /// No description provided for @rootFeaturesFileAccessReason.
  ///
  /// In en, this message translates to:
  /// **'Not implemented. Normal Android storage access (SAF/MediaStore) already covers what Fetchy needs, so nothing currently requires this.'**
  String get rootFeaturesFileAccessReason;

  /// No description provided for @rootFeaturesSessionImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Root-assisted session import'**
  String get rootFeaturesSessionImportTitle;

  /// No description provided for @rootFeaturesSessionImportReason.
  ///
  /// In en, this message translates to:
  /// **'it reuses the same Advanced cookies.txt import already available in Connected Accounts. Extract a cookie file with an external root tool, convert it to cookies.txt format, and import it there. No dedicated in-app extraction is planned.'**
  String get rootFeaturesSessionImportReason;

  /// No description provided for @rootFeaturesNotBuiltYet.
  ///
  /// In en, this message translates to:
  /// **'Not built yet. {reason}'**
  String rootFeaturesNotBuiltYet(String reason);

  /// No description provided for @rootFeaturesAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Root access gives Fetchy elevated access to files on this device.\n\nOnly enable this if you understand and trust the feature. Fetchy will use root only for the selected advanced operation.'**
  String get rootFeaturesAccessDescription;

  /// No description provided for @rootFeaturesEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable root features'**
  String get rootFeaturesEnableButton;

  /// No description provided for @rootFeaturesEnableConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable root features?'**
  String get rootFeaturesEnableConfirmTitle;

  /// No description provided for @rootFeaturesBypassNotice.
  ///
  /// In en, this message translates to:
  /// **'Root access may provide additional local access, but it does not guarantee bypassing platform anti-bot protection, authentication requirements, DRM, or server-side restrictions.'**
  String get rootFeaturesBypassNotice;

  /// No description provided for @rootStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Root: available'**
  String get rootStatusAvailable;

  /// No description provided for @rootStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Root: not available on this device'**
  String get rootStatusUnavailable;

  /// No description provided for @rootStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Root: access denied'**
  String get rootStatusDenied;

  /// No description provided for @rootStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Root: not checked yet'**
  String get rootStatusUnknown;

  /// No description provided for @updatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTitle;

  /// No description provided for @updatesSettingsRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for a newer version of Fetchy'**
  String get updatesSettingsRowSubtitle;

  /// No description provided for @updatesCurrentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get updatesCurrentVersionLabel;

  /// No description provided for @updatesNewVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get updatesNewVersionLabel;

  /// No description provided for @updatesCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updatesCheckAction;

  /// No description provided for @updatesCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updatesCheckingStatus;

  /// No description provided for @updatesUpToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updatesUpToDateTitle;

  /// No description provided for @updatesUpToDateBody.
  ///
  /// In en, this message translates to:
  /// **'Fetchy {version} is the newest published release.'**
  String updatesUpToDateBody(String version);

  /// No description provided for @updatesNeverChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get updatesNeverChecked;

  /// No description provided for @updatesLastCheckedNever.
  ///
  /// In en, this message translates to:
  /// **'Fetchy hasn\'t checked for updates yet.'**
  String get updatesLastCheckedNever;

  /// No description provided for @updatesAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updatesAvailableTitle;

  /// No description provided for @updatesAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Fetchy {version} is available to install.'**
  String updatesAvailableBody(String version);

  /// No description provided for @updatesReleaseNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updatesReleaseNotesTitle;

  /// No description provided for @updatesNoReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'This release has no notes.'**
  String get updatesNoReleaseNotes;

  /// No description provided for @updatesPublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String updatesPublishedOn(String date);

  /// No description provided for @updatesDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get updatesDownloadAction;

  /// No description provided for @updatesDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download size: {size}'**
  String updatesDownloadSize(String size);

  /// No description provided for @updatesDownloadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get updatesDownloadingStatus;

  /// No description provided for @updatesDownloadedAmount.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String updatesDownloadedAmount(String received, String total);

  /// No description provided for @updatesDownloadCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get updatesDownloadCancelAction;

  /// No description provided for @updatesReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to install'**
  String get updatesReadyTitle;

  /// No description provided for @updatesReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Fetchy {version} has been downloaded. Android will ask you to confirm the installation.'**
  String updatesReadyBody(String version);

  /// No description provided for @updatesInstallAction.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get updatesInstallAction;

  /// No description provided for @updatesPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Installation permission required'**
  String get updatesPermissionTitle;

  /// No description provided for @updatesPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Android only lets an app open the installer once you allow it. Turn on \"Install unknown apps\" for Fetchy, then come back here and continue.'**
  String get updatesPermissionBody;

  /// No description provided for @updatesOpenAndroidSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Android settings'**
  String get updatesOpenAndroidSettingsAction;

  /// No description provided for @updatesContinueInstallAction.
  ///
  /// In en, this message translates to:
  /// **'Continue installation'**
  String get updatesContinueInstallAction;

  /// No description provided for @updatesFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updatesFailedTitle;

  /// No description provided for @updatesGithubUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'GitHub unavailable'**
  String get updatesGithubUnavailableTitle;

  /// No description provided for @updatesNoApkTitle.
  ///
  /// In en, this message translates to:
  /// **'No installable file'**
  String get updatesNoApkTitle;

  /// No description provided for @updatesNoApkBody.
  ///
  /// In en, this message translates to:
  /// **'Release {version} doesn\'t include an Android APK, so there is nothing to install from it.'**
  String updatesNoApkBody(String version);

  /// No description provided for @updatesViewOnGithubAction.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get updatesViewOnGithubAction;

  /// No description provided for @updatesErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build has no update source configured yet, so Fetchy can\'t check for updates.'**
  String get updatesErrorNotConfigured;

  /// No description provided for @updatesErrorNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get updatesErrorNoNetwork;

  /// No description provided for @updatesErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'GitHub didn\'t respond in time.'**
  String get updatesErrorTimeout;

  /// No description provided for @updatesErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'GitHub is limiting requests right now. Please try again later.'**
  String get updatesErrorRateLimited;

  /// No description provided for @updatesErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'GitHub returned an unexpected response.'**
  String get updatesErrorHttp;

  /// No description provided for @updatesErrorMalformed.
  ///
  /// In en, this message translates to:
  /// **'GitHub\'s response couldn\'t be read.'**
  String get updatesErrorMalformed;

  /// No description provided for @updatesErrorNoRelease.
  ///
  /// In en, this message translates to:
  /// **'There are no published releases yet.'**
  String get updatesErrorNoRelease;

  /// No description provided for @updatesErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while checking for updates.'**
  String get updatesErrorUnknown;

  /// No description provided for @updatesInstallErrorPackageMismatch.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a Fetchy build, so it was not installed.'**
  String get updatesInstallErrorPackageMismatch;

  /// No description provided for @updatesInstallErrorNotNewer.
  ///
  /// In en, this message translates to:
  /// **'The downloaded build isn\'t newer than the one installed.'**
  String get updatesInstallErrorNotNewer;

  /// No description provided for @updatesInstallErrorSignature.
  ///
  /// In en, this message translates to:
  /// **'The update is signed with a different key than the installed app, so Android would refuse it. Download Fetchy from the same source you installed it from.'**
  String get updatesInstallErrorSignature;

  /// No description provided for @updatesInstallErrorCorrupt.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file isn\'t a valid Android package.'**
  String get updatesInstallErrorCorrupt;

  /// No description provided for @updatesInstallErrorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The update couldn\'t be downloaded.'**
  String get updatesInstallErrorDownloadFailed;

  /// No description provided for @updatesInstallErrorCanceled.
  ///
  /// In en, this message translates to:
  /// **'Download canceled.'**
  String get updatesInstallErrorCanceled;

  /// No description provided for @updatesInstallErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'The installer couldn\'t be opened.'**
  String get updatesInstallErrorUnknown;

  /// No description provided for @updatesPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates contacts GitHub only. No account, session, clipboard, or download history is ever sent.'**
  String get updatesPrivacyNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

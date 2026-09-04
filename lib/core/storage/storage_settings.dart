import '../../l10n/generated/app_localizations.dart';

/// Where Fetchy looks for a destination folder. Mirrors the native
/// `StorageBase` enum exactly — see
/// `com.example.fetchy.storage.StorageSettings` on the Android side.
///
/// This is deliberately independent from whether Fetchy adds its own
/// subfolder underneath (see [StorageSettings.useFetchySubfolders]) —
/// "where" and "whether Fetchy organizes it" are two separate questions,
/// not one fixed combination.
enum StorageBase {
  /// The plain Android media folders: Movies, Music.
  androidDefault,

  /// A folder the user picked via the system folder picker (Storage
  /// Access Framework).
  custom;

  String get wireValue => switch (this) {
    StorageBase.androidDefault => 'androidDefault',
    StorageBase.custom => 'custom',
  };

  static StorageBase fromWire(String? raw) =>
      raw == 'custom' ? StorageBase.custom : StorageBase.androidDefault;

  /// Takes [AppLocalizations] rather than being a plain getter — this is a
  /// user-facing label, and the model layer has no [BuildContext] of its
  /// own to look one up with.
  String label(AppLocalizations strings) => switch (this) {
    StorageBase.androidDefault => strings.storageBaseAndroidDefaultLabel,
    StorageBase.custom => strings.storageBaseCustomLabel,
  };

  String description(AppLocalizations strings) => switch (this) {
    StorageBase.androidDefault => strings.storageBaseAndroidDefaultDescription,
    StorageBase.custom => strings.storageBaseCustomDescription,
  };
}

/// A folder the user granted access to via the system folder picker,
/// persisted as a content:// tree URI — see [StorageSettingsService].
class CustomFolder {
  const CustomFolder({required this.treeUri, this.displayName});

  final String treeUri;

  /// Null when native couldn't report a name for the folder (or none was
  /// ever persisted) — callers fall back to [AppLocalizations.storageSelectedFolderFallback]
  /// rather than baking a placeholder English string in here, since this is
  /// a plain data class with no [AppLocalizations] of its own to reach for.
  final String? displayName;
}

/// The user's full Download Location configuration: a base destination,
/// plus an independent choice of whether Fetchy organizes it into Videos/
/// and Audio/ subfolders. Persisted by [StorageSettingsService] and read
/// fresh before every download.
class StorageSettings {
  const StorageSettings({
    required this.base,
    required this.useFetchySubfolders,
    this.videoFolder,
    this.audioFolder,
    this.audioSameAsVideo = false,
  });

  /// First-run default: Fetchy-organized Android media folders — no setup
  /// needed, and no permission dialog, since it never touches SAF.
  static const StorageSettings defaults = StorageSettings(
    base: StorageBase.androidDefault,
    useFetchySubfolders: true,
  );

  final StorageBase base;

  /// Whether Fetchy creates its own Videos/Audio subfolder under [base] —
  /// applies the same way whether [base] is Android's own folders or a
  /// custom one.
  final bool useFetchySubfolders;

  /// Only meaningful when [base] is [StorageBase.custom].
  final CustomFolder? videoFolder;

  /// Only meaningful when [base] is [StorageBase.custom] and
  /// [audioSameAsVideo] is false.
  final CustomFolder? audioFolder;

  /// When true, audio is written to [videoFolder] instead of picking a
  /// second folder — avoids a redundant picker dialog for the common case
  /// of wanting everything in one place.
  final bool audioSameAsVideo;

  /// The folder actually used for audio once [audioSameAsVideo] is
  /// resolved.
  CustomFolder? get effectiveAudioFolder => audioSameAsVideo ? videoFolder : audioFolder;

  /// The map shape sent to native with every `startDownload` call. Native
  /// decides which of the two tree URIs actually applies (and whether to
  /// nest a Videos/Audio subfolder under it), based on the real output
  /// file's media type — see StorageDestinationResolver.
  Map<String, Object?> toChannelArgument() => <String, Object?>{
    'base': base.wireValue,
    'useFetchySubfolders': useFetchySubfolders,
    'videoTreeUri': base == StorageBase.custom ? videoFolder?.treeUri : null,
    'audioTreeUri': base == StorageBase.custom ? effectiveAudioFolder?.treeUri : null,
  };

  /// Friendly one-line description of where video actually lands, for the
  /// Settings summary and the Download Location page.
  String videoLocationLabel(AppLocalizations strings) {
    if (base == StorageBase.custom) {
      final String folder = videoFolder == null
          ? strings.commonNotSet
          : (videoFolder!.displayName ?? strings.storageSelectedFolderFallback);
      return useFetchySubfolders ? strings.storageVideoLocationCustom(folder) : folder;
    }
    return useFetchySubfolders
        ? strings.storageVideoLocationDefaultSubfolders
        : strings.storageVideoLocationDefault;
  }

  String audioLocationLabel(AppLocalizations strings) {
    if (base == StorageBase.custom) {
      final String folder = effectiveAudioFolder == null
          ? strings.commonNotSet
          : (effectiveAudioFolder!.displayName ?? strings.storageSelectedFolderFallback);
      return useFetchySubfolders ? strings.storageAudioLocationCustom(folder) : folder;
    }
    return useFetchySubfolders
        ? strings.storageAudioLocationDefaultSubfolders
        : strings.storageAudioLocationDefault;
  }

  /// The one-word summary shown on the Settings row — "Default" or
  /// "Custom", nothing more.
  ///
  /// The pattern throughout Settings is a compact summary outside and the
  /// full configuration inside: the exact folders, the subfolder choice,
  /// and any accessibility problem all live on the Download Location
  /// screen, so the row that opens it stays a single scannable word.
  String compactSummaryLabel(AppLocalizations strings) => switch (base) {
    StorageBase.androidDefault => strings.storageSummaryDefault,
    StorageBase.custom => strings.storageSummaryCustom,
  };

  /// One-line summary for the Settings entry point.
  String organizationSummaryLabel(AppLocalizations strings) {
    final String baseLabel = base.label(strings);
    return useFetchySubfolders ? strings.storageOrganizedSummary(baseLabel) : baseLabel;
  }

  StorageSettings copyWith({
    StorageBase? base,
    bool? useFetchySubfolders,
    CustomFolder? videoFolder,
    bool clearVideoFolder = false,
    CustomFolder? audioFolder,
    bool clearAudioFolder = false,
    bool? audioSameAsVideo,
  }) {
    return StorageSettings(
      base: base ?? this.base,
      useFetchySubfolders: useFetchySubfolders ?? this.useFetchySubfolders,
      videoFolder: clearVideoFolder ? null : (videoFolder ?? this.videoFolder),
      audioFolder: clearAudioFolder ? null : (audioFolder ?? this.audioFolder),
      audioSameAsVideo: audioSameAsVideo ?? this.audioSameAsVideo,
    );
  }
}

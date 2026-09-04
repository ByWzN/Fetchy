/// What the user set in the Download Options sheet, if anything. Every
/// field is independently optional and additive — leaving a field unset
/// means "keep whatever the source/default already provides," never
/// "clear it." See `DownloadPostProcessor` (native) for how audio metadata
/// is actually applied, and the `-o` template override for filename.
class AudioDownloadOptions {
  const AudioDownloadOptions({this.title, this.artist, this.album, this.advancedFormat});

  final String? title;
  final String? artist;
  final String? album;

  /// An explicit pick from the Advanced Format/Bitrate browser — a real
  /// yt-dlp format_id traced back to one entry in
  /// `MediaSelectionCatalog.advancedAudioFormats`. Null (the default)
  /// means "use whatever the ordinary audio format selector already
  /// picked." Reuses the same class Video's Advanced format override
  /// uses — one shared model for "an explicit real-format pick," not a
  /// second one per mode.
  final AdvancedFormatSelection? advancedFormat;

  bool get isEmpty =>
      title == null && artist == null && album == null && advancedFormat == null;

  /// Only [title]/[artist]/[album] ever reach native — [advancedFormat] is
  /// resolved entirely on the Dart side into the one real format
  /// expression `DownloaderService.startDownload` already sends via the
  /// existing `formatId` channel argument, exactly like Video's.
  Map<String, Object?> toChannelArgument() => <String, Object?>{
    'title': title,
    'artist': artist,
    'album': album,
  };

  AudioDownloadOptions copyWith({
    String? title,
    String? artist,
    String? album,
    AdvancedFormatSelection? advancedFormat,
  }) {
    return AudioDownloadOptions(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      advancedFormat: advancedFormat ?? this.advancedFormat,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AudioDownloadOptions &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.advancedFormat == advancedFormat;

  @override
  int get hashCode => Object.hash(title, artist, album, advancedFormat);
}

/// An explicit pick from the Advanced format/quality browser — a real
/// yt-dlp format_id traced back to one [ResolutionOption] in
/// `MediaSelectionCatalog.advancedVideoEntries`/`advancedVideoOnlyEntries`.
/// Null `VideoDownloadOptions.advancedFormat` (the default) means "use
/// whatever the ordinary quality selector already picked" — Advanced only
/// ever overrides when the user explicitly chose something from it.
class AdvancedFormatSelection {
  const AdvancedFormatSelection({required this.formatId});

  final String formatId;

  @override
  bool operator ==(Object other) =>
      other is AdvancedFormatSelection && other.formatId == formatId;

  @override
  int get hashCode => formatId.hashCode;
}

/// Regular (manually authored) subtitles vs. automatically generated
/// captions — kept distinct because their accuracy differs; a regular
/// track is always preferred when both exist for the same language (see
/// `download_options_sheet.dart`'s subtitle list builder).
enum SubtitleTrackKind { regular, automatic }

/// One subtitle track the user explicitly chose to embed. Null
/// `VideoDownloadOptions.subtitle` (the default) means no subtitles at
/// all — Fetchy never embeds a caption track the user didn't ask for.
class SubtitleSelection {
  const SubtitleSelection({required this.language, required this.kind});

  /// The real language code yt-dlp reported (e.g. "en", "ar") — passed
  /// back verbatim as `--sub-langs`, never translated or guessed.
  final String language;
  final SubtitleTrackKind kind;

  @override
  bool operator ==(Object other) =>
      other is SubtitleSelection &&
      other.language == language &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(language, kind);
}

class VideoDownloadOptions {
  const VideoDownloadOptions({
    this.filename,
    this.includeAudio = true,
    this.advancedFormat,
    this.subtitle,
  });

  final String? filename;

  /// The "Include audio" Advanced control. True (the default) preserves
  /// today's behavior in every way. False is only ever set by that
  /// explicit toggle, and only takes effect together with an
  /// [advancedFormat] pick from the video-only pool — see
  /// `DownloaderService.startDownload`, which is the one place this
  /// bypasses the normal "no accidental silent video" safety check.
  final bool includeAudio;

  final AdvancedFormatSelection? advancedFormat;
  final SubtitleSelection? subtitle;

  bool get isEmpty =>
      filename == null &&
      includeAudio == true &&
      advancedFormat == null &&
      subtitle == null;

  /// Only [filename] and [subtitle] ever reach native — [includeAudio]
  /// and [advancedFormat] are resolved entirely on the Dart side into the
  /// one real format expression `DownloaderService.startDownload` already
  /// sends via the existing `formatId` channel argument, so native never
  /// needs to know about them separately.
  Map<String, Object?> toChannelArgument() => <String, Object?>{
    'filename': filename,
    if (subtitle != null) 'subtitleLanguage': subtitle!.language,
    if (subtitle != null)
      'subtitleIsAutomatic': subtitle!.kind == SubtitleTrackKind.automatic,
  };

  VideoDownloadOptions copyWith({
    String? filename,
    bool? includeAudio,
    AdvancedFormatSelection? advancedFormat,
    SubtitleSelection? subtitle,
  }) {
    return VideoDownloadOptions(
      filename: filename ?? this.filename,
      includeAudio: includeAudio ?? this.includeAudio,
      advancedFormat: advancedFormat ?? this.advancedFormat,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VideoDownloadOptions &&
      other.filename == filename &&
      other.includeAudio == includeAudio &&
      other.advancedFormat == advancedFormat &&
      other.subtitle == subtitle;

  @override
  int get hashCode =>
      Object.hash(filename, includeAudio, advancedFormat, subtitle);
}

/// Which of the three artwork choices is currently selected. [none] is the
/// default and the only state that existed before Thumbnail/Artwork
/// support — selecting [source] or [custom] always requires an explicit
/// user action (never applied just because the source happens to have a
/// thumbnail).
enum ArtworkKind { none, source, custom }

/// One resolved artwork choice, ready to hand to the download pipeline.
/// [localPath] is already a private local file by the time this exists —
/// whichever of "pick a custom image" or "download the source thumbnail"
/// produced it has already run (see `ArtworkService`), so native never
/// needs SAF or network access of its own to apply it.
class ArtworkSelection {
  const ArtworkSelection({required this.kind, this.localPath});

  static const ArtworkSelection none = ArtworkSelection(kind: ArtworkKind.none);

  final ArtworkKind kind;
  final String? localPath;

  bool get isEmpty => kind == ArtworkKind.none || localPath == null;

  Map<String, Object?>? toChannelArgument() {
    if (isEmpty) return null;
    return <String, Object?>{'path': localPath};
  }

  @override
  bool operator ==(Object other) =>
      other is ArtworkSelection &&
      other.kind == kind &&
      other.localPath == localPath;

  @override
  int get hashCode => Object.hash(kind, localPath);
}

/// The full set of Download Options for one download — at most one of
/// [audio]/[video] is ever meaningful at a time, matching whichever mode
/// `MediaPreview`'s existing Video/Audio selector is in. This never
/// creates a second mode selector; it just carries that same choice's
/// details. [artwork] applies to whichever mode is active — audio embeds
/// it as cover art, video embeds it as an attached thumbnail.
class DownloadOptions {
  const DownloadOptions({this.audio, this.video, this.artwork});

  static const DownloadOptions none = DownloadOptions();

  final AudioDownloadOptions? audio;
  final VideoDownloadOptions? video;
  final ArtworkSelection? artwork;

  bool get isEmpty =>
      (audio?.isEmpty ?? true) && (video?.isEmpty ?? true) && (artwork?.isEmpty ?? true);

  /// Null when there is nothing to send — the native side treats a missing
  /// `downloadOptions` argument exactly like an empty one, but omitting it
  /// entirely keeps the channel call's normal shape unchanged when Download
  /// Options was never touched.
  Map<String, Object?>? toChannelArgument() {
    if (isEmpty) return null;
    return <String, Object?>{
      if (audio != null && !audio!.isEmpty) 'audio': audio!.toChannelArgument(),
      if (video != null && !video!.isEmpty) 'video': video!.toChannelArgument(),
      if (artwork != null && !artwork!.isEmpty) 'artwork': artwork!.toChannelArgument(),
    };
  }

  DownloadOptions copyWith({
    AudioDownloadOptions? audio,
    VideoDownloadOptions? video,
    ArtworkSelection? artwork,
  }) {
    return DownloadOptions(
      audio: audio ?? this.audio,
      video: video ?? this.video,
      artwork: artwork ?? this.artwork,
    );
  }

  /// Value equality across the whole tree, so callers can ask the one
  /// question that matters after the sheet closes: did anything actually
  /// change? Without it every Save looked like a change, and the
  /// confirmation fired even when the user had only opened the sheet and
  /// closed it again.
  @override
  bool operator ==(Object other) =>
      other is DownloadOptions &&
      other.audio == audio &&
      other.video == video &&
      other.artwork == artwork;

  @override
  int get hashCode => Object.hash(audio, video, artwork);
}

/// One subtitle or automatic-caption track, as reported by yt-dlp's own
/// `subtitles`/`automatic_captions` maps. [language] is the raw language
/// code yt-dlp uses (e.g. "en", "en-US") — the same code must be passed
/// back for `--sub-langs` when downloading, it is not for display alone.
class MediaSubtitleTrack {
  const MediaSubtitleTrack({required this.language, this.name, this.formats = const <String>[]});

  final String language;

  /// A human-readable name when the extractor reports one (e.g.
  /// "English"); null when only the language code is known.
  final String? name;

  /// Subtitle file extensions available for this language (e.g. "vtt",
  /// "srt"). Never used to fetch a URL directly — downloading/embedding
  /// goes through yt-dlp's own `--sub-langs`/`--write-subs`/`--embed-subs`.
  final List<String> formats;

  static MediaSubtitleTrack? fromMap(Map<Object?, Object?> map) {
    final String? language = map['language'] as String?;
    if (language == null || language.isEmpty) return null;

    final Object? rawFormats = map['formats'];
    final List<String> formats = rawFormats is List
        ? rawFormats.whereType<String>().toList(growable: false)
        : const <String>[];

    return MediaSubtitleTrack(language: language, name: map['name'] as String?, formats: formats);
  }
}

class MediaFormat {
  const MediaFormat({
    this.formatId,
    this.extension,
    this.qualityLabel,
    this.height,
    this.width,
    this.fps,
    this.videoCodec,
    this.audioCodec,
    this.videoBitrate,
    this.audioBitrate,
    this.totalBitrate,
    this.filesize,
    this.filesizeApprox,
    this.dynamicRange,
    this.language,
    this.audioChannels,
    this.protocol,
    this.hasDrm,
  });

  final String? formatId;
  final String? extension;
  final String? qualityLabel;
  final int? height;
  final int? width;
  final double? fps;
  final String? videoCodec;
  final String? audioCodec;
  final double? videoBitrate;
  final double? audioBitrate;
  final double? totalBitrate;
  /// Exact size, present only when yt-dlp reported "filesize".
  final int? filesize;

  /// yt-dlp's own estimate ("filesize_approx"), kept separate so the UI can
  /// mark it as approximate instead of presenting it as exact.
  final int? filesizeApprox;

  /// yt-dlp's "dynamic_range" for this specific format (e.g. "SDR",
  /// "HDR10", "HLG"). Null whenever the extractor didn't report one —
  /// treat that as "unknown", never as "definitely SDR".
  final String? dynamicRange;

  /// yt-dlp's per-format "language" (e.g. for a dubbed audio track). Null
  /// for the vast majority of formats, which carry no language tag at all.
  final String? language;

  final int? audioChannels;

  /// yt-dlp's transport "protocol" for this format (e.g. "https",
  /// "m3u8_native", "dash"). Informational — not currently used to gate
  /// any decision, but real and available for future format-achievability
  /// logic (e.g. HLS renditions needing different remux handling).
  final String? protocol;

  /// True only when yt-dlp explicitly reported this specific format as
  /// DRM-protected. Null means "not reported", not "confirmed DRM-free".
  final bool? hasDrm;

  static MediaFormat fromMap(Map<Object?, Object?> map) {
    return MediaFormat(
      formatId: map['formatId'] as String?,
      extension: map['ext'] as String?,
      qualityLabel: map['qualityLabel'] as String?,
      height: (map['height'] as num?)?.toInt(),
      width: (map['width'] as num?)?.toInt(),
      fps: (map['fps'] as num?)?.toDouble(),
      videoCodec: map['videoCodec'] as String?,
      audioCodec: map['audioCodec'] as String?,
      videoBitrate: (map['videoBitrate'] as num?)?.toDouble(),
      audioBitrate: (map['audioBitrate'] as num?)?.toDouble(),
      totalBitrate: (map['totalBitrate'] as num?)?.toDouble(),
      filesize: (map['filesize'] as num?)?.toInt(),
      filesizeApprox: (map['filesizeApprox'] as num?)?.toInt(),
      dynamicRange: map['dynamicRange'] as String?,
      language: map['language'] as String?,
      audioChannels: (map['audioChannels'] as num?)?.toInt(),
      protocol: map['protocol'] as String?,
      hasDrm: map['hasDrm'] as bool?,
    );
  }

  @override
  String toString() {
    return '[${formatId ?? '?'}] ${qualityLabel ?? height ?? '?'} · ${extension ?? '?'} (v: ${videoCodec ?? 'none'}, a: ${audioCodec ?? 'none'})';
  }
}

class MediaInfo {
  const MediaInfo({
    required this.sourceUrl,
    required this.title,
    this.id,
    this.thumbnailUrl,
    this.duration,
    this.uploader,
    this.webpageUrl,
    this.formats = const <MediaFormat>[],
    this.artist,
    this.album,
    this.track,
    this.genre,
    this.hasDrm,
    this.subtitles = const <MediaSubtitleTrack>[],
    this.automaticCaptions = const <MediaSubtitleTrack>[],
    this.playlistIndex,
  });

  final String sourceUrl;
  final String title;
  final String? id;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? uploader;
  final String? webpageUrl;
  final List<MediaFormat> formats;

  /// Music-style metadata (artist/album/track/genre), populated only when
  /// the source actually carries it — most non-music content leaves these
  /// null. Never fabricated as a fallback for [title]/[uploader].
  final String? artist;
  final String? album;
  final String? track;
  final String? genre;

  /// True only when yt-dlp explicitly reported this media as DRM-protected
  /// overall. Null means "not reported".
  final bool? hasDrm;

  /// Manually authored subtitles. Empty when the extractor/platform
  /// exposes none — this is a common, honest state, not a failure.
  final List<MediaSubtitleTrack> subtitles;

  /// Machine-generated captions — distinct from [subtitles] because
  /// accuracy differs and the two should never be presented as equivalent.
  final List<MediaSubtitleTrack> automaticCaptions;

  /// yt-dlp's 1-based index of this entry inside a multi-entry extraction,
  /// or null for an ordinary single-video URL.
  ///
  /// Null is meaningful: its absence is what marks the media as *not* part
  /// of a playlist, and the download must then be issued without any
  /// item selection at all, exactly as before.
  ///
  /// Scoped to one extraction. It describes a position in the result yt-dlp
  /// just returned, so it is carried only as far as the download that
  /// follows and is never persisted to history.
  final int? playlistIndex;

  static MediaInfo fromMap(Map<Object?, Object?> map) {
    final Object? rawFormats = map['formats'];
    final List<MediaFormat> formats = rawFormats is List
        ? rawFormats
              .whereType<Map<Object?, Object?>>()
              .map(MediaFormat.fromMap)
              .toList(growable: false)
        : const <MediaFormat>[];

    final int? durationSeconds = (map['durationSeconds'] as num?)?.toInt();

    return MediaInfo(
      sourceUrl: (map['sourceUrl'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Untitled',
      id: map['id'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      duration: durationSeconds == null
          ? null
          : Duration(seconds: durationSeconds),
      uploader: map['uploader'] as String?,
      webpageUrl: map['webpageUrl'] as String?,
      formats: formats,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      track: map['track'] as String?,
      genre: map['genre'] as String?,
      hasDrm: map['hasDrm'] as bool?,
      subtitles: _subtitleListFrom(map['subtitles']),
      automaticCaptions: _subtitleListFrom(map['automaticCaptions']),
      playlistIndex: (map['playlistIndex'] as num?)?.toInt(),
    );
  }

  static List<MediaSubtitleTrack> _subtitleListFrom(Object? raw) {
    if (raw is! List) return const <MediaSubtitleTrack>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(MediaSubtitleTrack.fromMap)
        .whereType<MediaSubtitleTrack>()
        .toList(growable: false);
  }
}

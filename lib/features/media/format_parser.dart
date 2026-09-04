import 'media_info.dart';

enum FormatKind { videoAndAudio, videoOnly, audioOnly, nonDownloadable }

class ParsedFormat {
  const ParsedFormat({required this.raw, required this.kind});

  final MediaFormat raw;
  final FormatKind kind;

  bool get isUsable => kind != FormatKind.nonDownloadable;
  bool get hasVideo =>
      kind == FormatKind.videoAndAudio || kind == FormatKind.videoOnly;
  bool get hasAudio =>
      kind == FormatKind.videoAndAudio || kind == FormatKind.audioOnly;

  String? get formatId => raw.formatId;
  String? get extension => raw.extension;
  int? get width => raw.width;
  int? get height => raw.height;
  double? get fps => raw.fps;
  String? get videoCodec => raw.videoCodec;
  String? get audioCodec => raw.audioCodec;
  double? get videoBitrate => raw.videoBitrate;
  double? get audioBitrate => raw.audioBitrate;
  double? get totalBitrate => raw.totalBitrate;
  int? get filesize => raw.filesize;
  int? get filesizeApprox => raw.filesizeApprox;

  /// yt-dlp's "dynamic_range" for this format (e.g. "SDR", "HDR10",
  /// "HLG"). Null means unreported, never "confirmed SDR" — see
  /// [MediaFormat.dynamicRange].
  String? get dynamicRange => raw.dynamicRange;
  String? get language => raw.language;
  int? get audioChannels => raw.audioChannels;
  String? get protocol => raw.protocol;
  bool? get hasDrm => raw.hasDrm;

  /// True when this format carries no video stream but does carry audio,
  /// judged purely from stream semantics — never from the container
  /// extension or the protocol. This is what makes HLS audio renditions
  /// (ext "mp4", protocol "m3u8_native") count as audio on X/Twitter.
  bool get isAudioOnly => kind == FormatKind.audioOnly;

  @override
  String toString() => '${kind.name}: ${raw.toString()}';
}

class ParsedFormatCollection {
  const ParsedFormatCollection({
    required this.videoAndAudio,
    required this.videoOnly,
    required this.audioOnly,
    required this.nonDownloadable,
  });

  final List<ParsedFormat> videoAndAudio;
  final List<ParsedFormat> videoOnly;
  final List<ParsedFormat> audioOnly;
  final List<ParsedFormat> nonDownloadable;

  List<ParsedFormat> get usable => <ParsedFormat>[
    ...videoAndAudio,
    ...videoOnly,
    ...audioOnly,
  ];

  bool get hasUsableFormats => usable.isNotEmpty;
}

/// Classifies a raw [MediaFormat] list from the extraction engine into
/// download-relevant categories. This layer is deliberately dumb: it does
/// not rank, sort, pick a default, or infer quality. That belongs to the
/// Normal/Advanced selectors that will consume this output later.
class FormatParser {
  const FormatParser._();

  static ParsedFormatCollection parse(List<MediaFormat> formats) {
    final List<ParsedFormat> videoAndAudio = <ParsedFormat>[];
    final List<ParsedFormat> videoOnly = <ParsedFormat>[];
    final List<ParsedFormat> audioOnly = <ParsedFormat>[];
    final List<ParsedFormat> nonDownloadable = <ParsedFormat>[];

    for (final MediaFormat format in formats) {
      final FormatKind kind = _classify(format);
      final ParsedFormat parsed = ParsedFormat(raw: format, kind: kind);

      switch (kind) {
        case FormatKind.videoAndAudio:
          videoAndAudio.add(parsed);
        case FormatKind.videoOnly:
          videoOnly.add(parsed);
        case FormatKind.audioOnly:
          audioOnly.add(parsed);
        case FormatKind.nonDownloadable:
          nonDownloadable.add(parsed);
      }
    }

    return ParsedFormatCollection(
      videoAndAudio: List<ParsedFormat>.unmodifiable(videoAndAudio),
      videoOnly: List<ParsedFormat>.unmodifiable(videoOnly),
      audioOnly: List<ParsedFormat>.unmodifiable(audioOnly),
      nonDownloadable: List<ParsedFormat>.unmodifiable(nonDownloadable),
    );
  }

  static FormatKind _classify(MediaFormat format) {
    final bool hasVideo = _hasCodec(format.videoCodec);
    final bool hasAudio = _hasCodec(format.audioCodec);

    if (hasVideo && hasAudio) return FormatKind.videoAndAudio;
    if (hasVideo) return FormatKind.videoOnly;
    if (hasAudio) return FormatKind.audioOnly;
    return FormatKind.nonDownloadable;
  }

  /// yt-dlp's own convention: the literal string "none" is the only signal
  /// that a stream is confirmed absent (e.g. a video-only DASH format
  /// reports acodec: "none"). A missing/null codec means the extractor
  /// simply didn't report one — not that the stream is absent — so it must
  /// be treated as present, the same way yt-dlp itself does.
  ///
  /// Evidence: X/Twitter's HLS audio renditions (format_id like
  /// "hls-audio-128000-Audio") report vcodec: "none" but leave acodec
  /// completely unset. Treating that null as "no audio" silently
  /// reclassified genuine audio-only formats as nonDownloadable, making
  /// the Audio option disappear even though the stream was real and
  /// downloadable.
  static bool _hasCodec(String? codec) {
    if (codec == null) return true;
    final String normalized = codec.trim().toLowerCase();
    return normalized.isEmpty || normalized != 'none';
  }
}

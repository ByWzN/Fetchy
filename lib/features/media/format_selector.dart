import 'format_parser.dart';

/// How a [FormatCandidate] was assembled from the raw format list.
enum FormatSourceKind {
  /// A single format that already contains both video and audio.
  combined,

  /// A video-only format paired with a separate audio-only format.
  /// Actually producing a playable file from this requires merging the
  /// two streams at download time — not implemented by this layer.
  merge,

  /// A video-only format with no usable audio-only format available to
  /// pair it with. Rare, but honestly represented rather than dropped.
  videoOnly,

  /// An audio-only format.
  audioOnly,
}

/// A single user-facing candidate produced by [FormatSelector].
///
/// This never fabricates data: every field traces back to a real
/// [MediaFormat] returned by the extraction engine.
class FormatCandidate {
  const FormatCandidate._({
    required this.kind,
    required this.primary,
    this.audio,
  });

  factory FormatCandidate.combined(ParsedFormat format) {
    return FormatCandidate._(kind: FormatSourceKind.combined, primary: format);
  }

  factory FormatCandidate.merge({
    required ParsedFormat video,
    required ParsedFormat audio,
  }) {
    return FormatCandidate._(
      kind: FormatSourceKind.merge,
      primary: video,
      audio: audio,
    );
  }

  factory FormatCandidate.videoOnly(ParsedFormat format) {
    return FormatCandidate._(kind: FormatSourceKind.videoOnly, primary: format);
  }

  factory FormatCandidate.audioOnly(ParsedFormat format) {
    return FormatCandidate._(kind: FormatSourceKind.audioOnly, primary: format);
  }

  /// For [FormatSourceKind.combined] and [FormatSourceKind.videoOnly] and
  /// [FormatSourceKind.merge], this is the video-carrying format.
  /// For [FormatSourceKind.audioOnly], this is the audio format itself.
  final ParsedFormat primary;

  /// Only set for [FormatSourceKind.merge]: the audio-only format that
  /// would need to be merged with [primary] at download time.
  final ParsedFormat? audio;

  final FormatSourceKind kind;

  bool get requiresMerge => kind == FormatSourceKind.merge;
  bool get hasAudio => kind != FormatSourceKind.videoOnly;
  bool get hasVideo => kind != FormatSourceKind.audioOnly;

  int? get height => primary.height;
  int? get width => primary.width;
  double? get fps => primary.fps;
  String? get videoCodec => primary.videoCodec;
  int? get filesize => primary.filesize;

  String? get audioCodec {
    if (kind == FormatSourceKind.merge) return audio?.audioCodec;
    return primary.audioCodec;
  }

  @override
  String toString() {
    switch (kind) {
      case FormatSourceKind.combined:
        return 'combined(${primary.formatId})';
      case FormatSourceKind.videoOnly:
        return 'videoOnly(${primary.formatId})';
      case FormatSourceKind.audioOnly:
        return 'audioOnly(${primary.formatId})';
      case FormatSourceKind.merge:
        return 'merge(video: ${primary.formatId}, audio: ${audio?.formatId})';
    }
  }
}

/// Normal-mode candidate set: a small, fixed shape the future Normal-mode
/// UI can render directly (Best, 1080p, 720p, 480p, Audio).
class NormalModeCandidates {
  const NormalModeCandidates({
    required this.best,
    required this.byHeight,
    required this.audio,
  });

  final FormatCandidate? best;

  /// Keyed by the requested target height (e.g. 1080, 720, 480). A null
  /// value means no usable video format exists near that height.
  final Map<int, FormatCandidate?> byHeight;

  final FormatCandidate? audio;
}

/// Consumes a [ParsedFormatCollection] and produces deterministic,
/// platform-agnostic selection candidates.
///
/// This layer never ranks by format ordering, never invents bitrate
/// values, and never reads [ParsedFormatCollection.nonDownloadable] —
/// non-downloadable formats can never surface as a candidate.
class FormatSelector {
  const FormatSelector._();

  static const List<int> defaultNormalModeHeights = <int>[1080, 720, 480];

  /// The single best available video option. Prefers a combined
  /// (video+audio) format, but switches to a video-only + audio-only pair
  /// when the video-only track is genuinely higher quality than anything
  /// combined offers — the common case where progressive formats cap out
  /// lower than adaptive/DASH formats.
  static FormatCandidate? selectBest(ParsedFormatCollection formats) {
    final ParsedFormat? bestCombined = _bestOf(
      formats.videoAndAudio,
      _compareVideoQuality,
    );
    final ParsedFormat? bestVideoOnly = _bestOf(
      formats.videoOnly,
      _compareVideoQuality,
    );
    final ParsedFormat? bestAudio = _bestOf(
      formats.audioOnly,
      _compareAudioQuality,
    );

    final bool videoOnlyIsBetter =
        bestVideoOnly != null &&
        (bestCombined == null ||
            _compareVideoQuality(bestVideoOnly, bestCombined) > 0);

    if (videoOnlyIsBetter && bestAudio != null) {
      return FormatCandidate.merge(video: bestVideoOnly, audio: bestAudio);
    }

    if (bestCombined != null) {
      return FormatCandidate.combined(bestCombined);
    }

    if (bestVideoOnly != null) {
      // Video exists but no audio-only track to pair it with. Represent
      // this honestly rather than silently dropping the best video option.
      return FormatCandidate.videoOnly(bestVideoOnly);
    }

    return null;
  }

  /// The video option closest to [targetHeight], considering both
  /// combined and video-only+audio candidates and picking whichever is
  /// nearer. Ties prefer the combined format, since it needs no merge.
  static FormatCandidate? selectAroundHeight(
    ParsedFormatCollection formats,
    int targetHeight,
  ) {
    final ParsedFormat? closestCombined = _closestByHeight(
      formats.videoAndAudio,
      targetHeight,
    );
    final ParsedFormat? closestVideoOnly = _closestByHeight(
      formats.videoOnly,
      targetHeight,
    );
    final ParsedFormat? bestAudio = _bestOf(
      formats.audioOnly,
      _compareAudioQuality,
    );

    final int? combinedDistance = closestCombined?.height == null
        ? null
        : (closestCombined!.height! - targetHeight).abs();
    final int? videoOnlyDistance = closestVideoOnly?.height == null
        ? null
        : (closestVideoOnly!.height! - targetHeight).abs();

    final bool preferVideoOnly =
        closestVideoOnly != null &&
        bestAudio != null &&
        (combinedDistance == null ||
            videoOnlyDistance! < combinedDistance ||
            (videoOnlyDistance == combinedDistance &&
                _compareVideoQuality(closestVideoOnly, closestCombined!) > 0));

    if (preferVideoOnly) {
      return FormatCandidate.merge(video: closestVideoOnly, audio: bestAudio);
    }

    if (closestCombined != null) {
      return FormatCandidate.combined(closestCombined);
    }

    if (closestVideoOnly != null) {
      return FormatCandidate.videoOnly(closestVideoOnly);
    }

    return null;
  }

  /// The best available audio-only option.
  static FormatCandidate? selectAudioOnly(ParsedFormatCollection formats) {
    final ParsedFormat? best = _bestOf(formats.audioOnly, _compareAudioQuality);
    if (best == null) return null;
    return FormatCandidate.audioOnly(best);
  }

  /// Convenience bundle for a Normal-mode selector UI: best, a fixed set
  /// of target heights, and audio — each independently computed.
  static NormalModeCandidates selectNormalModeCandidates(
    ParsedFormatCollection formats, {
    List<int> heights = defaultNormalModeHeights,
  }) {
    final Map<int, FormatCandidate?> byHeight = <int, FormatCandidate?>{
      for (final int height in heights)
        height: selectAroundHeight(formats, height),
    };

    return NormalModeCandidates(
      best: selectBest(formats),
      byHeight: byHeight,
      audio: selectAudioOnly(formats),
    );
  }

  static ParsedFormat? _closestByHeight(
    List<ParsedFormat> formats,
    int targetHeight,
  ) {
    ParsedFormat? closest;
    int? closestDistance;

    for (final ParsedFormat format in formats) {
      final int? height = format.height;
      if (height == null) continue;

      final int distance = (height - targetHeight).abs();
      final bool isCloser =
          closestDistance == null || distance < closestDistance;
      final bool isTieButBetter =
          distance == closestDistance &&
          closest != null &&
          _compareVideoQuality(format, closest) > 0;

      if (isCloser || isTieButBetter) {
        closest = format;
        closestDistance = distance;
      }
    }

    return closest;
  }

  static ParsedFormat? _bestOf(
    List<ParsedFormat> formats,
    int Function(ParsedFormat a, ParsedFormat b) compare,
  ) {
    ParsedFormat? best;
    for (final ParsedFormat format in formats) {
      if (best == null || compare(format, best) > 0) {
        best = format;
      }
    }
    return best;
  }

  /// Positive when [a] is the better video candidate than [b].
  /// Compares real signals only — never invents a bitrate.
  static int _compareVideoQuality(ParsedFormat a, ParsedFormat b) {
    final int heightCompare = (a.height ?? -1).compareTo(b.height ?? -1);
    if (heightCompare != 0) return heightCompare;

    final int widthCompare = (a.width ?? -1).compareTo(b.width ?? -1);
    if (widthCompare != 0) return widthCompare;

    final int fpsCompare = (a.fps ?? -1.0).compareTo(b.fps ?? -1.0);
    if (fpsCompare != 0) return fpsCompare;

    // videoBitrate is essentially always null with the current engine
    // (the library exposes no vbr field); totalBitrate is used only as a
    // ranking signal here, never surfaced to the caller as videoBitrate.
    final double aBitrate = a.videoBitrate ?? a.totalBitrate ?? -1.0;
    final double bBitrate = b.videoBitrate ?? b.totalBitrate ?? -1.0;
    final int bitrateCompare = aBitrate.compareTo(bBitrate);
    if (bitrateCompare != 0) return bitrateCompare;

    final int filesizeCompare = (a.filesize ?? -1).compareTo(b.filesize ?? -1);
    if (filesizeCompare != 0) return filesizeCompare;

    // Final deterministic tiebreaker so results never depend on the
    // engine's original ordering.
    return (a.formatId ?? '').compareTo(b.formatId ?? '');
  }

  /// Positive when [a] is the better audio candidate than [b].
  static int _compareAudioQuality(ParsedFormat a, ParsedFormat b) {
    final double aBitrate = a.audioBitrate ?? a.totalBitrate ?? -1.0;
    final double bBitrate = b.audioBitrate ?? b.totalBitrate ?? -1.0;
    final int bitrateCompare = aBitrate.compareTo(bBitrate);
    if (bitrateCompare != 0) return bitrateCompare;

    final int filesizeCompare = (a.filesize ?? -1).compareTo(b.filesize ?? -1);
    if (filesizeCompare != 0) return filesizeCompare;

    return (a.formatId ?? '').compareTo(b.formatId ?? '');
  }
}

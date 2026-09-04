import 'format_parser.dart';
import 'format_selector.dart';
import 'media_size.dart';
import 'quality_tier.dart';

export 'quality_tier.dart' show QualityTier;

/// One resolution that genuinely exists for this media item.
class ResolutionOption {
  const ResolutionOption({
    required this.height,
    required this.width,
    required this.standardLabel,
    required this.candidate,
  });

  /// The real height reported by the engine. Never a requested or
  /// rounded value.
  ///
  /// Null when the engine reported no usable dimensions for a format that
  /// is nonetheless downloadable — see
  /// [MediaSelectionCatalog._buildUnknownQualityFallback]. Height is
  /// metadata about a download, never a precondition for one.
  final int? height;

  final int? width;

  /// Derived technical label ("8K", "4K", "2K", "1080p"). This is a
  /// format descriptor, not localizable UI copy.
  ///
  /// Null alongside a null [height]: there is no honest technical label for
  /// a resolution nobody reported, and inventing one ("360p") would state a
  /// fact the engine never gave us. Callers render their own localized
  /// "quality unavailable" copy in that case.
  final String? standardLabel;

  final FormatCandidate candidate;

  bool get requiresMerge => candidate.requiresMerge;
  double? get fps => candidate.fps;
  String? get videoCodec => candidate.videoCodec;
  /// The download size for this resolution, with its accuracy.
  ///
  /// The video stream is the deciding component: [FormatSelector] pairs every
  /// merge resolution with the *same* best audio track, so falling back to the
  /// audio size when the video size was missing once made every resolution
  /// report one identical figure. That fallback must never return — an
  /// unresolvable video size yields [MediaSizeAccuracy.unknown] instead.
  MediaSize size(Duration? duration) {
    final MediaSize videoSize = MediaSize.forFormat(
      candidate.primary,
      duration: duration,
    );
    if (!videoSize.isKnown) return const MediaSize.unknown();

    if (!candidate.requiresMerge) return videoSize;

    final ParsedFormat? audio = candidate.audio;
    if (audio == null) return videoSize;

    final MediaSize audioSize = MediaSize.forFormat(audio, duration: duration);
    // A merge downloads both streams, so an unknown audio component makes the
    // total an estimate rather than a fact.
    if (!audioSize.isKnown) {
      return MediaSize.approximate(videoSize.bytes!);
    }

    return videoSize.combineWith(audioSize);
  }

  /// The fixed quality tier for [height]. `null` when [height] falls below
  /// the lowest defined tier (under 360p), and also when there is no
  /// reported height at all — an unknown resolution belongs to no tier, so
  /// the tier selector simply omits it.
  QualityTier? get qualityTier {
    final int? height = this.height;
    return height == null ? null : QualityTier.fromHeight(height);
  }

  /// True when the engine gave no usable dimensions for this option.
  bool get hasUnknownQuality => height == null;

  @override
  String toString() =>
      '${standardLabel ?? 'unknown quality'} (${height ?? '?'}p, $candidate)';
}

/// How an audio output would be produced.
enum AudioOutputKind {
  /// The source audio stream is written as-is. No processing required.
  nativePassthrough,

  /// The source audio must be transcoded to reach this output format.
  /// Requires processing capability that Fetchy does not yet have.
  conversion,
}

class AudioOutputOption {
  const AudioOutputOption({
    required this.label,
    required this.kind,
    required this.source,
  });

  /// Output container/codec descriptor ("M4A", "OPUS", "MP3").
  final String label;

  final AudioOutputKind kind;

  /// The audio-only candidate this output would be produced from.
  final FormatCandidate source;

  bool get requiresProcessing => kind == AudioOutputKind.conversion;

  String? get sourceExtension => source.primary.extension;
  double? get sourceBitrate =>
      source.primary.audioBitrate ?? source.primary.totalBitrate;
  MediaSize size(Duration? duration) =>
      MediaSize.forFormat(source.primary, duration: duration);

  @override
  String toString() => '$label (${kind.name}, from ${source.primary.formatId})';
}

/// What the download pipeline can currently produce beyond passthrough.
///
/// Defaults to [none] because FFmpeg is not integrated. Conversion
/// targets are therefore absent from the catalog entirely rather than
/// offered and then failing.
class AudioProcessingCapabilities {
  const AudioProcessingCapabilities({
    this.canTranscode = false,
    this.conversionTargets = const <String>{},
  });

  static const AudioProcessingCapabilities none = AudioProcessingCapabilities();

  final bool canTranscode;

  /// Uppercase output labels, e.g. {'MP3'}. Ignored when [canTranscode]
  /// is false.
  final Set<String> conversionTargets;
}

/// The complete set of real, offerable choices for one media item,
/// shaped for all three user levels.
///
/// Everything here traces back to a format the engine actually returned.
/// Non-downloadable formats never reach this layer.
class MediaSelectionCatalog {
  const MediaSelectionCatalog({
    required this.resolutions,
    required this.tiers,
    required this.audioOutputs,
    required this.advancedVideoFormats,
    required this.advancedAudioFormats,
    required this.advancedVideoEntries,
    required this.advancedVideoOnlyEntries,
  });

  /// Distinct available resolutions, highest first. Level 1 renders these
  /// directly — every entry is real.
  final List<ResolutionOption> resolutions;

  /// Level 1 tier shortcuts, keyed by a fixed height-based [QualityTier].
  /// Absent keys mean no available resolution falls into that tier.
  final Map<QualityTier, ResolutionOption> tiers;

  /// Level 2 audio-only outputs. Contains only outputs that can actually
  /// be produced given the supplied capabilities.
  final List<AudioOutputOption> audioOutputs;

  /// Level 3 raw formats, full engine metadata, unranked and unfiltered
  /// apart from excluding non-downloadable entries.
  final List<ParsedFormat> advancedVideoFormats;
  final List<ParsedFormat> advancedAudioFormats;

  /// Advanced format/quality browser entries — every real video format the
  /// engine returned, unranked and un-deduplicated by height (unlike
  /// [resolutions], which keeps only the single best candidate per
  /// height). Combined formats are used as-is; video-only formats are
  /// paired with the best available audio track so their [ResolutionOption
  /// .size] reflects an actual download, matching "Include audio: ON"
  /// (today's normal) behavior.
  final List<ResolutionOption> advancedVideoEntries;

  /// The subset usable when audio is explicitly excluded ("Include audio:
  /// OFF") — video-only formats alone, never paired with bestaudio, so
  /// each entry's size is exactly what that download would transfer. This
  /// is the ONLY list that may ever be downloaded without audio; combined
  /// formats never appear here because they cannot have their audio
  /// stripped without re-encoding, which this build does not do.
  final List<ResolutionOption> advancedVideoOnlyEntries;

  /// Looks up one [advancedVideoEntries]/[advancedVideoOnlyEntries] entry
  /// by its real yt-dlp format_id — used to reconstruct the exact
  /// [ResolutionOption] a user picked in the Advanced format browser after
  /// it round-trips through the serializable [DownloadOptions]. Returns
  /// null if the id is not found in the pool matching [includeAudio] (e.g.
  /// stale data after the media changed).
  ResolutionOption? advancedEntryForFormatId(
    String formatId, {
    required bool includeAudio,
  }) {
    final List<ResolutionOption> pool = includeAudio
        ? advancedVideoEntries
        : advancedVideoOnlyEntries;
    for (final ResolutionOption option in pool) {
      if (option.candidate.primary.formatId == formatId) return option;
    }
    return null;
  }

  /// Looks up one real audio format by its yt-dlp format_id from
  /// [advancedAudioFormats] and wraps it as an [AudioOutputOption] —
  /// mirrors [advancedEntryForFormatId] so both modes' Advanced format
  /// picker round-trip through [DownloadOptions] the same way. Always
  /// [AudioOutputKind.nativePassthrough]: the Advanced browser only ever
  /// surfaces real engine formats, never a synthetic conversion target.
  AudioOutputOption? advancedAudioEntryForFormatId(String formatId) {
    for (final ParsedFormat format in advancedAudioFormats) {
      if (format.formatId == formatId) {
        return AudioOutputOption(
          label: audioLabelFor(format),
          kind: AudioOutputKind.nativePassthrough,
          source: FormatCandidate.audioOnly(format),
        );
      }
    }
    return null;
  }

  bool get hasVideo => resolutions.isNotEmpty;
  bool get hasAudio => audioOutputs.isNotEmpty;
  bool get isEmpty => !hasVideo && !hasAudio;

  /// The highest available resolution, regardless of which fixed tier it
  /// falls into. Kept independent of [tiers] so the default selection is
  /// never affected by a video lacking a "Best Quality"-range format.
  ResolutionOption? get best => resolutions.isEmpty ? null : resolutions.first;

  ResolutionOption? resolutionForHeight(int height) {
    for (final ResolutionOption option in resolutions) {
      if (option.height == height) return option;
    }
    return null;
  }

  /// The single option produced when a real video format exists but no
  /// format reported a usable height — see
  /// [_buildUnknownQualityFallback].
  ///
  /// Always null whenever normal height-based resolutions exist, so it can
  /// never shadow or compete with them. It exists because a height-less
  /// option cannot be addressed by [resolutionForHeight], which is how
  /// every other selection is keyed.
  ResolutionOption? get unknownQualityResolution {
    if (resolutions.length != 1) return null;
    final ResolutionOption only = resolutions.first;
    return only.hasUnknownQuality ? only : null;
  }

  /// Tiers with duplicates removed, preserving Best → Low order. Useful
  /// when few resolutions exist and several tiers collapse onto one.
  List<MapEntry<QualityTier, ResolutionOption>> get distinctTiers {
    final List<MapEntry<QualityTier, ResolutionOption>> result =
        <MapEntry<QualityTier, ResolutionOption>>[];
    final Set<int> seenHeights = <int>{};

    for (final QualityTier tier in QualityTier.values) {
      final ResolutionOption? option = tiers[tier];
      if (option == null) continue;
      // A tier is only ever assigned from a real height (see _deriveTiers,
      // which skips options with no qualityTier), so this is never null.
      if (seenHeights.add(option.height!)) {
        result.add(MapEntry<QualityTier, ResolutionOption>(tier, option));
      }
    }

    return result;
  }

  static MediaSelectionCatalog from(
    ParsedFormatCollection formats, {
    AudioProcessingCapabilities capabilities = AudioProcessingCapabilities.none,
  }) {
    final List<ResolutionOption> heightedResolutions = _buildResolutions(formats);

    // Only when the ordinary, height-keyed path found nothing at all. Any
    // media that reports a single usable height keeps its existing
    // behaviour untouched.
    final ResolutionOption? fallback = heightedResolutions.isEmpty
        ? _buildUnknownQualityFallback(formats)
        : null;

    final List<ResolutionOption> resolutions = fallback == null
        ? heightedResolutions
        : <ResolutionOption>[fallback];

    return MediaSelectionCatalog(
      resolutions: List<ResolutionOption>.unmodifiable(resolutions),
      tiers: Map<QualityTier, ResolutionOption>.unmodifiable(
        _deriveTiers(resolutions),
      ),
      audioOutputs: List<AudioOutputOption>.unmodifiable(
        _buildAudioOutputs(formats, capabilities),
      ),
      advancedVideoFormats: List<ParsedFormat>.unmodifiable(<ParsedFormat>[
        ...formats.videoAndAudio,
        ...formats.videoOnly,
      ]),
      advancedAudioFormats: List<ParsedFormat>.unmodifiable(formats.audioOnly),
      advancedVideoEntries: List<ResolutionOption>.unmodifiable(
        _buildAdvancedVideoEntries(formats),
      ),
      advancedVideoOnlyEntries: List<ResolutionOption>.unmodifiable(
        _buildAdvancedVideoOnlyEntries(formats),
      ),
    );
  }

  /// Every real video format as a browsable [ResolutionOption]: combined
  /// formats used as-is, video-only formats paired with the single best
  /// available audio track (mirroring [FormatSelector.selectBest]'s own
  /// "video-only + bestaudio" pairing) so a user browsing with audio
  /// included never sees a size that omits the audio they will actually
  /// get. Deliberately keeps every distinct format_id at a given height —
  /// unlike [_buildResolutions], which keeps only one representative per
  /// height — because Advanced is specifically for choosing a REAL,
  /// specific engine format, not a curated "best at this height" pick.
  static List<ResolutionOption> _buildAdvancedVideoEntries(
    ParsedFormatCollection formats,
  ) {
    final ParsedFormat? bestAudio = FormatSelector.selectAudioOnly(
      formats,
    )?.primary;

    final List<ResolutionOption> options = <ResolutionOption>[];

    for (final ParsedFormat format in formats.videoAndAudio) {
      final int? height = format.height;
      if (height == null || height <= 0) continue;
      options.add(
        ResolutionOption(
          height: height,
          width: format.width,
          standardLabel: standardLabelForHeight(height),
          candidate: FormatCandidate.combined(format),
        ),
      );
    }

    for (final ParsedFormat format in formats.videoOnly) {
      final int? height = format.height;
      if (height == null || height <= 0) continue;
      final FormatCandidate candidate = bestAudio != null
          ? FormatCandidate.merge(video: format, audio: bestAudio)
          : FormatCandidate.videoOnly(format);
      options.add(
        ResolutionOption(
          height: height,
          width: format.width,
          standardLabel: standardLabelForHeight(height),
          candidate: candidate,
        ),
      );
    }

    return options;
  }

  /// The video-only subset, never paired with an audio track — the only
  /// pool an "Include audio: OFF" pick may ever come from.
  static List<ResolutionOption> _buildAdvancedVideoOnlyEntries(
    ParsedFormatCollection formats,
  ) {
    final List<ResolutionOption> options = <ResolutionOption>[];

    for (final ParsedFormat format in formats.videoOnly) {
      final int? height = format.height;
      if (height == null || height <= 0) continue;
      options.add(
        ResolutionOption(
          height: height,
          width: format.width,
          standardLabel: standardLabelForHeight(height),
          candidate: FormatCandidate.videoOnly(format),
        ),
      );
    }

    return options;
  }

  /// Enumerates the heights that actually exist, then asks
  /// [FormatSelector] for the best candidate at each. Because every
  /// height passed in is known to exist, the selector always returns an
  /// exact match while still applying its combined-vs-merge preference.
  /// One downloadable video option for media whose formats carry a real
  /// stream but no usable dimensions.
  ///
  /// Some extractors simply do not report width/height. yt-dlp's generic
  /// HTML5/direct-file paths never do, and even purpose-built extractors
  /// sometimes report zero. [_buildResolutions] keys everything on a
  /// positive height, so for that media it produced nothing at all, the
  /// catalog looked empty, and a perfectly downloadable video became
  /// unreachable. Height is metadata about a download, not a precondition
  /// for one.
  ///
  /// Nothing is fabricated: height, width, fps and filesize are all left
  /// exactly as the engine reported them (usually absent). The option
  /// carries a real [FormatCandidate] and downloads through the same
  /// format_id path as every other candidate.
  ///
  /// Deliberately narrow:
  ///
  ///  * It runs only when the ordinary path yielded nothing, so no working
  ///    platform can be affected by it.
  ///  * Only formats already classified as carrying video reach it. Audio
  ///    is excluded structurally rather than by a rule here — yt-dlp marks
  ///    confirmed-audio streams `vcodec: "none"`, which [FormatParser]
  ///    routes to `audioOnly` long before this point.
  ///  * Audio-only formats are withheld from the selector so it cannot
  ///    invent a merge pairing. With no dimensions to rank by, any
  ///    video-only/audio pairing would be arbitrary, so only a genuinely
  ///    single-format candidate is acceptable here.
  ///  * A candidate with no format_id is rejected: format_id is what the
  ///    download is actually issued with.
  static ResolutionOption? _buildUnknownQualityFallback(
    ParsedFormatCollection formats,
  ) {
    if (formats.videoAndAudio.isEmpty && formats.videoOnly.isEmpty) {
      return null;
    }

    // Reuses FormatSelector rather than ranking here. Handing it an empty
    // audio list is what makes a merge impossible: selectBest then prefers
    // a combined format and falls back to video-only, both single formats.
    final FormatCandidate? candidate = FormatSelector.selectBest(
      ParsedFormatCollection(
        videoAndAudio: formats.videoAndAudio,
        videoOnly: formats.videoOnly,
        audioOnly: const <ParsedFormat>[],
        nonDownloadable: const <ParsedFormat>[],
      ),
    );
    if (candidate == null || candidate.requiresMerge) return null;

    final String? formatId = candidate.primary.formatId?.trim();
    if (formatId == null || formatId.isEmpty) return null;

    return ResolutionOption(
      height: null,
      width: candidate.width,
      standardLabel: null,
      candidate: candidate,
    );
  }

  static List<ResolutionOption> _buildResolutions(
    ParsedFormatCollection formats,
  ) {
    final Set<int> heights = <int>{};

    for (final ParsedFormat format in <ParsedFormat>[
      ...formats.videoAndAudio,
      ...formats.videoOnly,
    ]) {
      final int? height = format.height;
      if (height != null && height > 0) heights.add(height);
    }

    final List<int> sorted = heights.toList()
      ..sort((int a, int b) => b.compareTo(a));

    final List<ResolutionOption> options = <ResolutionOption>[];

    for (final int height in sorted) {
      final FormatCandidate? candidate = FormatSelector.selectAroundHeight(
        formats,
        height,
      );

      // Defensive: skip if the selector somehow lands elsewhere, so a
      // mislabelled resolution can never be shown.
      if (candidate == null || candidate.height != height) continue;

      options.add(
        ResolutionOption(
          height: height,
          width: candidate.width,
          standardLabel: standardLabelForHeight(height),
          candidate: candidate,
        ),
      );
    }

    return options;
  }

  /// Groups the real resolutions by their fixed [QualityTier] (derived only
  /// from actual height — see [QualityTier.fromHeight]). A tier is present
  /// only when a resolution genuinely falls into its height range; when
  /// several resolutions share a tier, the highest of them represents it.
  /// This never fabricates a resolution and never re-labels one based on
  /// what else the video happens to offer.
  static Map<QualityTier, ResolutionOption> _deriveTiers(
    List<ResolutionOption> descending,
  ) {
    final Map<QualityTier, ResolutionOption> tiers =
        <QualityTier, ResolutionOption>{};

    for (final ResolutionOption option in descending) {
      final QualityTier? tier = option.qualityTier;
      if (tier == null) continue;
      // descending is sorted highest-first, so the first option seen for
      // a tier is already its highest representative.
      tiers.putIfAbsent(tier, () => option);
    }

    return tiers;
  }

  /// Groups the audio-only formats into offerable outputs.
  ///
  /// Grouping is by a *derived* label, not by the raw container extension.
  /// Keying on `ext` alone silently dropped every audio format whose
  /// extension was absent or blank — and when that applied to all of them,
  /// `audioOutputs` came back empty and the Audio option vanished from the UI
  /// even though usable audio-only streams existed. X/Twitter HLS audio
  /// renditions are the case that exposed this.
  static List<AudioOutputOption> _buildAudioOutputs(
    ParsedFormatCollection formats,
    AudioProcessingCapabilities capabilities,
  ) {
    if (formats.audioOnly.isEmpty) return const <AudioOutputOption>[];

    final List<AudioOutputOption> outputs = <AudioOutputOption>[];

    // Preserve a stable, deterministic order without depending on `ext`.
    final List<String> labels = <String>[];
    for (final ParsedFormat format in formats.audioOnly) {
      final String label = audioLabelFor(format);
      if (!labels.contains(label)) labels.add(label);
    }
    labels.sort();

    for (final String label in labels) {
      final FormatCandidate? best = _bestAudioForLabel(formats, label);
      if (best == null) continue;

      outputs.add(
        AudioOutputOption(
          label: label,
          kind: AudioOutputKind.nativePassthrough,
          source: best,
        ),
      );
    }

    if (!capabilities.canTranscode) return outputs;

    final FormatCandidate? bestOverall = FormatSelector.selectAudioOnly(
      formats,
    );
    if (bestOverall == null) return outputs;

    final Set<String> nativeLabels = outputs
        .map((AudioOutputOption o) => o.label)
        .toSet();

    final List<String> targets = capabilities.conversionTargets.toList()
      ..sort();

    for (final String target in targets) {
      final String upper = target.toUpperCase();
      if (nativeLabels.contains(upper)) continue;

      outputs.add(
        AudioOutputOption(
          label: upper,
          kind: AudioOutputKind.conversion,
          source: bestOverall,
        ),
      );
    }

    return outputs;
  }

  /// A user-facing label for an audio-only format.
  ///
  /// Named after the **audio codec**, falling back to the container
  /// extension only when the codec is unreported.
  ///
  /// The precedence used to be the other way round, and that was wrong for
  /// the common case. A container name describes the box, not the sound
  /// inside it: YouTube ships its AAC audio in an MP4 container and its
  /// Opus audio in a WebM one, so an extension-first label put "MP4" and
  /// "WEBM" in the Audio-only picker — offering what reads as a video
  /// format to someone who has explicitly asked for audio. Naming the codec
  /// gives "M4A" and "OPUS", which is both accurate and what every other
  /// audio tool calls them.
  ///
  /// A useful side effect: AAC streams that arrive as `m4a` and as `mp4`
  /// now collapse onto the same "M4A" label instead of appearing as two
  /// separate choices for the same thing.
  ///
  /// Never returns empty, so no audio format can be dropped for lack of a
  /// usable name.
  static String audioLabelFor(ParsedFormat format) {
    final String? codec = format.audioCodec?.trim().toLowerCase();
    if (codec != null && codec.isNotEmpty && codec != 'none') {
      // Codec strings carry profiles ("mp4a.40.2"), so match on the prefix.
      if (codec.startsWith('mp4a') || codec.startsWith('aac')) return 'M4A';
      if (codec.startsWith('opus')) return 'OPUS';
      if (codec.startsWith('vorbis')) return 'OGG';
      if (codec.startsWith('mp3')) return 'MP3';
      if (codec.startsWith('flac')) return 'FLAC';
      if (codec.startsWith('ac-3') || codec.startsWith('ec-3')) return 'AC3';
      if (codec.startsWith('alac')) return 'ALAC';
      return codec.toUpperCase();
    }

    // No codec reported. yt-dlp leaves acodec unset on some renditions
    // (X/Twitter's HLS audio, for one) and FormatParser deliberately treats
    // that as "audio present" rather than "absent", so this branch is
    // reachable for a real audio stream — and falling straight through to
    // the container would put "MP4" back in an audio picker.
    //
    // An audio stream inside an MP4-family container is an .m4a by every
    // practical convention, so it is named that way. Anything else keeps
    // its container name, which is the most honest thing left to say about
    // a stream whose codec nobody reported.
    final String extension = format.extension?.trim().toLowerCase() ?? '';
    switch (extension) {
      case 'mp4':
      case 'm4a':
      case 'm4b':
      case 'mov':
      case '3gp':
      case '3gpp':
        return 'M4A';
    }
    if (extension.isNotEmpty) return extension.toUpperCase();

    return 'AUDIO';
  }

  /// Reuses [FormatSelector]'s own audio ranking by handing it a
  /// collection narrowed to a single extension, rather than duplicating
  /// the comparison logic here.
  static FormatCandidate? _bestAudioForLabel(
    ParsedFormatCollection formats,
    String label,
  ) {
    final List<ParsedFormat> subset = formats.audioOnly
        .where((ParsedFormat f) => audioLabelFor(f) == label)
        .toList(growable: false);

    if (subset.isEmpty) return null;

    return FormatSelector.selectAudioOnly(
      ParsedFormatCollection(
        videoAndAudio: const <ParsedFormat>[],
        videoOnly: const <ParsedFormat>[],
        audioOnly: subset,
        nonDownloadable: const <ParsedFormat>[],
      ),
    );
  }

  static String standardLabelForHeight(int height) {
    if (height >= 4320) return '8K';
    if (height >= 2160) return '4K';
    if (height >= 1440) return '2K';
    return '${height}p';
  }
}

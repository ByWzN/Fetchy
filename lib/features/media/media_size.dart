import 'format_parser.dart';

/// How much confidence there is in a reported download size.
enum MediaSizeAccuracy {
  /// yt-dlp reported an exact "filesize".
  exact,

  /// Derived from yt-dlp's own "filesize_approx", or computed from a real
  /// bitrate and a real duration. The user-facing format card shows this
  /// as a plain number — this flag exists for logic/diagnostics, not to
  /// drive a visible marker.
  approximate,

  /// Nothing trustworthy was available. Rendered as "Size unavailable" —
  /// never substituted with another format's number.
  unknown,
}

/// A download size together with how reliable it is.
///
/// The three states exist because many YouTube adaptive/DASH and HLS formats
/// genuinely have no pre-download size, and presenting an estimate as fact
/// would be misleading.
class MediaSize {
  const MediaSize.exact(int this.bytes) : accuracy = MediaSizeAccuracy.exact;

  const MediaSize.approximate(int this.bytes)
    : accuracy = MediaSizeAccuracy.approximate;

  const MediaSize.unknown() : bytes = null, accuracy = MediaSizeAccuracy.unknown;

  final int? bytes;
  final MediaSizeAccuracy accuracy;

  bool get isKnown => bytes != null && bytes! > 0;
  bool get isApproximate => accuracy == MediaSizeAccuracy.approximate;

  /// Combines two components of a single download (a video stream plus its
  /// audio stream). The result is only as trustworthy as its weakest part:
  /// any approximate component makes the sum approximate, and a missing
  /// component makes the whole thing unknown.
  MediaSize combineWith(MediaSize other) {
    if (!isKnown || !other.isKnown) return const MediaSize.unknown();

    final int total = bytes! + other.bytes!;
    final bool bothExact =
        accuracy == MediaSizeAccuracy.exact &&
        other.accuracy == MediaSizeAccuracy.exact;

    return bothExact ? MediaSize.exact(total) : MediaSize.approximate(total);
  }

  /// Resolves the best available size for a single format.
  ///
  /// Priority, highest confidence first:
  ///   1. exact `filesize`
  ///   2. yt-dlp's own `filesize_approx`
  ///   3. bitrate x duration, when both are genuinely reported
  ///   4. unknown
  ///
  /// No network probe is ever performed to manufacture a size.
  static MediaSize forFormat(ParsedFormat format, {Duration? duration}) {
    final int? exact = format.filesize;
    if (exact != null && exact > 0) return MediaSize.exact(exact);

    final int? approx = format.filesizeApprox;
    if (approx != null && approx > 0) return MediaSize.approximate(approx);

    final int? estimated = _estimateFromBitrate(format, duration);
    if (estimated != null) return MediaSize.approximate(estimated);

    return const MediaSize.unknown();
  }

  /// bitrate x duration, in bytes. Returns null unless both inputs are real:
  /// a missing duration (live or dynamic manifests report none) means no
  /// estimate is attempted at all.
  static int? _estimateFromBitrate(ParsedFormat format, Duration? duration) {
    if (duration == null) return null;
    final int seconds = duration.inSeconds;
    if (seconds <= 0) return null;

    // Pick the bitrate that actually describes this stream:
    //  - audio-only  -> abr (falling back to tbr, which is the same thing here)
    //  - video-only  -> tbr, which for a single-stream format is that stream
    //  - muxed       -> tbr, covering both components
    final double? kbitsPerSecond = format.isAudioOnly
        ? (format.audioBitrate ?? format.totalBitrate)
        : format.totalBitrate;

    if (kbitsPerSecond == null || kbitsPerSecond <= 0) return null;

    // yt-dlp reports bitrates in kbit/s.
    final double bytes = kbitsPerSecond * 1000 / 8 * seconds;
    if (!bytes.isFinite || bytes <= 0) return null;

    return bytes.round();
  }
}

import '../../l10n/generated/app_localizations.dart';

/// Fixed resolution → quality-tier mapping for Normal mode.
///
/// A tier is determined ONLY by a format's actual height. It never depends
/// on which other resolutions a given media item happens to offer, so the
/// same height always produces the same label across every video.
enum QualityTier {
  bestQuality,
  veryHigh,
  high,
  medium,
  low,
  veryLow;

  /// Returns the tier for [height], or `null` when [height] is below the
  /// lowest defined tier (under 360p) and therefore has no label.
  static QualityTier? fromHeight(int height) {
    if (height >= 2160) return QualityTier.bestQuality;
    if (height >= 1440) return QualityTier.veryHigh;
    if (height >= 1080) return QualityTier.high;
    if (height >= 720) return QualityTier.medium;
    if (height >= 480) return QualityTier.low;
    if (height >= 360) return QualityTier.veryLow;
    return null;
  }

  /// The localized label for this tier.
  String label(AppLocalizations strings) {
    switch (this) {
      case QualityTier.bestQuality:
        return strings.qualityTierBestQuality;
      case QualityTier.veryHigh:
        return strings.qualityTierVeryHigh;
      case QualityTier.high:
        return strings.qualityTierHigh;
      case QualityTier.medium:
        return strings.qualityTierMedium;
      case QualityTier.low:
        return strings.qualityTierLow;
      case QualityTier.veryLow:
        return strings.qualityTierVeryLow;
    }
  }
}

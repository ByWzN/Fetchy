import 'package:flutter/material.dart';

/// Fetchy's type scale.
///
/// Three rules hold the hierarchy together:
///
/// * Size and colour carry the hierarchy, not weight. Nothing above `w700`
///   exists in the scale, and body copy stays at `w400` — the previous
///   design leaned on `w700`/`w800`/`w900` almost everywhere, which
///   flattened everything into looking equally important.
/// * Tracking tightens as size grows and opens slightly as it shrinks, so
///   headings feel set rather than stretched and 11px labels stay legible.
/// * Body line-height is generous (1.5) and label line-height is tight
///   (1.25–1.35), because one is read and the other is scanned.
///
/// Every size is specified in logical pixels with no hard-coded colour;
/// `AppTheme` applies the scheme's `onSurface` over the whole scale, and
/// secondary text is expressed by switching to `onSurfaceVariant` rather
/// than by shrinking or lightening the weight.
///
/// The scale is metric-only and carries no font family, so it applies
/// identically to the Latin and Arabic system faces — Arabic keeps its own
/// default typeface and its taller line boxes are accommodated by the same
/// generous `height` values.
class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
      height: 1.15,
    ),
    displayMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.18,
    ),
    displaySmall: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.22,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      height: 1.27,
    ),
    headlineSmall: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.32,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.33,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.05,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.35,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
      height: 1.25,
    ),
  );

  /// The style for a section caption ("APPEARANCE", "Recent downloads").
  /// Small, medium-weight, opened tracking, and always painted in
  /// `onSurfaceVariant` by [FetchySectionHeader] — a caption is a signpost,
  /// not a heading, so it never competes with the content under it.
  static TextStyle sectionCaption(TextTheme text) =>
      text.labelMedium!.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w600);

  /// Tabular-ish numerals for figures that change in place (percentages,
  /// byte counts) so the surrounding layout does not jitter as digits
  /// change width.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);

  /// The same scale with every negative tracking value removed.
  ///
  /// Tight tracking is a Latin typesetting device: it makes large Latin
  /// headings feel set rather than stretched. Arabic is a connected script,
  /// and `letterSpacing` is applied as an advance adjustment *after*
  /// shaping — so a negative value there pulls joined letterforms into one
  /// another and degrades the very thing the script depends on. Positive
  /// tracking on the small labels is harmless either way and is kept.
  ///
  /// Applied per-locale by `AppTheme.forLocale`, so the Latin scale keeps
  /// its intended tightness and Arabic gets a scale that suits it.
  static TextTheme withoutTightTracking(TextTheme base) {
    TextStyle? relax(TextStyle? style) {
      if (style == null) return null;
      final double spacing = style.letterSpacing ?? 0;
      return spacing < 0 ? style.copyWith(letterSpacing: 0) : style;
    }

    return TextTheme(
      displayLarge: relax(base.displayLarge),
      displayMedium: relax(base.displayMedium),
      displaySmall: relax(base.displaySmall),
      headlineLarge: relax(base.headlineLarge),
      headlineMedium: relax(base.headlineMedium),
      headlineSmall: relax(base.headlineSmall),
      titleLarge: relax(base.titleLarge),
      titleMedium: relax(base.titleMedium),
      titleSmall: relax(base.titleSmall),
      bodyLarge: relax(base.bodyLarge),
      bodyMedium: relax(base.bodyMedium),
      bodySmall: relax(base.bodySmall),
      labelLarge: relax(base.labelLarge),
      labelMedium: relax(base.labelMedium),
      labelSmall: relax(base.labelSmall),
    );
  }
}

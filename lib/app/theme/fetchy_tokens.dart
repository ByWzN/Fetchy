import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand colour roles that [ColorScheme] has no slot for.
///
/// Anything a Fetchy widget needs that Material does not define — the
/// progress gradient, the page background wash, the raised/sunken surface
/// pair, the success/warning pairs — lives here rather than being written
/// inline in a widget. Read it with `FetchyTokens.of(context)`.
///
/// Keeping these in a [ThemeExtension] rather than as global constants is
/// what makes light and dark a single switch: a widget never asks which
/// brightness it is in, it just asks the theme for the role it needs.
@immutable
class FetchyTokens extends ThemeExtension<FetchyTokens> {
  const FetchyTokens({
    required this.accentGradient,
    required this.progressGradient,
    required this.pageGradient,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceSelected,
    required this.onSurfaceSelected,
    required this.hairline,
    required this.progressTrack,
    required this.successFg,
    required this.successBg,
    required this.warningFg,
    required this.warningBg,
    required this.shadow,
  });

  /// The primary action's fill: cyan into blue, but a deeper, narrower ramp
  /// than the wordmark's. See [AppColors.buttonGradientLight] for why the
  /// two are not the same gradient.
  final List<Color> accentGradient;

  /// The download bar's fill.
  ///
  /// Kept separate from [accentGradient] for a contrast reason. The Fetch
  /// button is a large filled surface carrying its own white label, so the
  /// brightest cyan works there; a 10px bar sitting on a pale track is a
  /// different problem, and the light theme's cyan end is too light to
  /// clear the 3:1 non-text contrast ratio against it. The progress ramp
  /// therefore starts at a deeper cyan while reading as the same brand
  /// gradient. On dark the two are the same ramp, since a bright fill on a
  /// deep navy track has contrast to spare.
  final List<Color> progressGradient;

  /// The very restrained wash behind full pages: two nearly-identical
  /// surface tones with a whisper of brand tint in the top corner. Calm on
  /// purpose; it should register as depth, not as decoration.
  final List<Color> pageGradient;

  /// A surface that sits *above* the page: cards, sheets, list groups.
  final Color surfaceRaised;

  /// A surface that sits *below* it: inset wells, read-only summaries,
  /// segmented-control tracks.
  final Color surfaceSunken;

  /// The tonal fill behind anything currently chosen. This replaces the
  /// old outlined/bordered selected state throughout the app.
  final Color surfaceSelected;

  /// Content colour on [surfaceSelected].
  final Color onSurfaceSelected;

  /// The one-pixel separator used *between* rows of a single group. Never
  /// used to outline a container.
  final Color hairline;

  /// The unfilled remainder of a progress bar.
  final Color progressTrack;

  final Color successFg;
  final Color successBg;
  final Color warningFg;
  final Color warningBg;

  /// Ambient shadow colour, tuned per brightness — a navy-tinted shadow on
  /// light, a genuine black on dark.
  final Color shadow;

  static const FetchyTokens light = FetchyTokens(
    accentGradient: AppColors.buttonGradientLight,
    progressGradient: AppColors.progressGradientLight,
    pageGradient: <Color>[Color(0xFFF7FAFE), AppColors.lightBackground],
    surfaceRaised: AppColors.lightSurface,
    surfaceSunken: AppColors.lightContainerHigh,
    surfaceSelected: Color(0xFFDCEAFE),
    onSurfaceSelected: Color(0xFF08326F),
    hairline: AppColors.lightOutlineVariant,
    progressTrack: Color(0xFFDDE7F3),
    successFg: Color(0xFF07775A),
    successBg: Color(0xFFD6F5EA),
    warningFg: AppColors.warning,
    warningBg: Color(0xFFFDEEDC),
    shadow: Color(0xFF0B1520),
  );

  static const FetchyTokens dark = FetchyTokens(
    accentGradient: AppColors.buttonGradientDark,
    progressGradient: AppColors.brandGradientDark,
    pageGradient: <Color>[Color(0xFF0A1220), AppColors.darkSurface],
    surfaceRaised: AppColors.darkContainer,
    surfaceSunken: AppColors.darkContainerLow,
    // Muted rather than vivid. A saturated blue chip on a near-black card
    // reads as "lit up"; this is dark enough to sit *in* the surface while
    // the light label on top still carries the selection.
    surfaceSelected: Color(0xFF15334C),
    onSurfaceSelected: Color(0xFFB6DEFA),
    hairline: AppColors.darkOutlineVariant,
    progressTrack: Color(0xFF1B2A42),
    successFg: AppColors.successDark,
    successBg: Color(0xFF0A3A2E),
    warningFg: AppColors.warningDark,
    warningBg: Color(0xFF43310D),
    shadow: Color(0xFF000000),
  );

  /// The tokens for the current theme. Falls back to the light set if a
  /// widget is somehow built outside `AppTheme` (only reachable in tests).
  static FetchyTokens of(BuildContext context) =>
      Theme.of(context).extension<FetchyTokens>() ?? light;

  @override
  FetchyTokens copyWith({
    List<Color>? accentGradient,
    List<Color>? progressGradient,
    List<Color>? pageGradient,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? surfaceSelected,
    Color? onSurfaceSelected,
    Color? hairline,
    Color? progressTrack,
    Color? successFg,
    Color? successBg,
    Color? warningFg,
    Color? warningBg,
    Color? shadow,
  }) {
    return FetchyTokens(
      accentGradient: accentGradient ?? this.accentGradient,
      progressGradient: progressGradient ?? this.progressGradient,
      pageGradient: pageGradient ?? this.pageGradient,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      onSurfaceSelected: onSurfaceSelected ?? this.onSurfaceSelected,
      hairline: hairline ?? this.hairline,
      progressTrack: progressTrack ?? this.progressTrack,
      successFg: successFg ?? this.successFg,
      successBg: successBg ?? this.successBg,
      warningFg: warningFg ?? this.warningFg,
      warningBg: warningBg ?? this.warningBg,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  FetchyTokens lerp(covariant FetchyTokens? other, double t) {
    if (other == null) return this;
    return FetchyTokens(
      accentGradient: _lerpColors(accentGradient, other.accentGradient, t),
      progressGradient: _lerpColors(progressGradient, other.progressGradient, t),
      pageGradient: _lerpColors(pageGradient, other.pageGradient, t),
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      onSurfaceSelected: Color.lerp(onSurfaceSelected, other.onSurfaceSelected, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final int length = a.length < b.length ? a.length : b.length;
    return <Color>[
      for (int i = 0; i < length; i++) Color.lerp(a[i], b[i], t)!,
    ];
  }
}

import 'package:flutter/material.dart';

/// Fetchy's raw brand palette.
///
/// The identity is a cyan-to-blue ramp taken straight off the Fetchy hook
/// logo (`assets/fetchy_motion/fetchy_logo.svg`): a bright cyan at the top
/// of the mark falling through sky blue into a deep electric blue at the
/// arrow. Everything accent-coloured in the app is drawn from this ramp;
/// there is deliberately no purple/lavender anywhere in the system, since a
/// seeded Material palette produces one by default and it reads as somebody
/// else's brand.
///
/// These are raw values only. Anything that flips between light and dark
/// belongs in the [ColorScheme] built by `AppTheme`, or in the brand-role
/// tokens in `fetchy_tokens.dart` — widgets should reach for those, not for
/// the constants here, except where a colour is genuinely fixed (the brand
/// gradient, the semantic success/warning hues).
class AppColors {
  const AppColors._();

  // ------------------------------------------------------- Brand ramp
  // Sampled from the logo gradient, light end to dark end.

  /// The brightest point of the mark.
  static const Color brandCyan = Color(0xFF12D7F1);

  /// The midpoint of the logo gradient.
  static const Color brandSky = Color(0xFF12A9F5);

  /// The deep blue at the arrow.
  static const Color brandBlue = Color(0xFF0A5BF6);

  /// The darkest usable brand tone, for pressed/scrim work on light.
  static const Color brandNavy = Color(0xFF0A337F);

  // ------------------------------- Legacy names kept for existing imports
  // Same ramp, older names. New code should prefer the brand* names above
  // or the theme tokens.
  static const Color primaryNavy = brandNavy;
  static const Color primaryDeep = Color(0xFF0B4FD8);
  static const Color primary = Color(0xFF0B62E4);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primarySky = brandSky;
  static const Color primaryCyan = Color(0xFF38BDF8);
  static const Color primaryMint = Color(0xFF2DD4BF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// The brand gradient, cyan to blue, used for the primary action and the
  /// download progress fill. Reserved for those two roles plus the
  /// wordmark: it is never a card fill or a page wash.
  static const List<Color> brandGradient = <Color>[
    brandCyan,
    brandSky,
    brandBlue,
  ];

  static const List<double> brandGradientStops = <double>[0.0, 0.45, 1.0];

  /// The same ramp shifted lighter, for use on dark surfaces where the deep
  /// blue end would disappear into the background.
  static const List<Color> brandGradientDark = <Color>[
    Color(0xFF67E8F9),
    Color(0xFF38BDF8),
    Color(0xFF3B82F6),
  ];

  /// The primary button's fill.
  ///
  /// Deliberately *not* [brandGradient]. The brand ramp starts at
  /// [brandCyan], which is a near-white cyan — beautiful in the wordmark,
  /// but across a full-width button it lights up the whole leading half and
  /// reads as glare rather than as colour. These ramps keep the same
  /// cyan-into-blue reading over a narrower, deeper range, so the button
  /// looks solid instead of shiny.
  static const List<Color> buttonGradientLight = <Color>[
    Color(0xFF2091CE),
    Color(0xFF1770DF),
    Color(0xFF1152CE),
  ];

  static const List<Color> buttonGradientDark = <Color>[
    Color(0xFF2F9BCE),
    Color(0xFF2B78D6),
    Color(0xFF2F5FC8),
  ];

  /// The download bar's fill on light surfaces.
  ///
  /// The same cyan-to-blue reading as [brandGradient], but starting at a
  /// deeper cyan: [brandCyan] is a genuinely light colour and a thin bar
  /// filled with it cannot reach the 3:1 non-text contrast ratio against a
  /// pale track, however good it looks on a large button.
  static const List<Color> progressGradientLight = <Color>[
    Color(0xFF0B84B8),
    Color(0xFF0C71D4),
    Color(0xFF0B55DE),
  ];

  // --------------------------------------------------------- Semantics
  static const Color success = Color(0xFF0E9F6E);
  static const Color successDark = Color(0xFF34D399);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFD92D20);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFF87171);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFB54708);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFBBF24);

  // ------------------------------------------ Light surface neutrals
  // Cool, faintly blue-tinted neutrals rather than flat grey, so the
  // light theme reads as part of the same family as the accent.
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightContainerLow = Color(0xFFFAFCFF);
  static const Color lightContainer = Color(0xFFF1F5FA);
  static const Color lightContainerHigh = Color(0xFFE9EFF7);
  static const Color lightContainerHighest = Color(0xFFE1E9F4);
  static const Color lightOnSurface = Color(0xFF0B1520);
  static const Color lightOnSurfaceVariant = Color(0xFF556575);
  static const Color lightOutline = Color(0xFF8496A8);
  static const Color lightOutlineVariant = Color(0xFFDCE4EE);

  // ------------------------------------------- Dark surface neutrals
  // Genuinely deep navy, not a washed-out grey.
  static const Color darkSurface = Color(0xFF070C17);
  static const Color darkContainerLowest = Color(0xFF04070E);
  static const Color darkContainerLow = Color(0xFF0B1220);
  static const Color darkContainer = Color(0xFF101A2B);
  static const Color darkContainerHigh = Color(0xFF172338);
  static const Color darkContainerHighest = Color(0xFF1F2E47);
  static const Color darkOnSurface = Color(0xFFE8F0FA);
  static const Color darkOnSurfaceVariant = Color(0xFF9AAAC0);
  static const Color darkOutline = Color(0xFF5C7086);
  static const Color darkOutlineVariant = Color(0xFF22314A);

  // ------------------------------------------------------- Fallbacks
  // Referenced by non-themed code paths that predate the token system.
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color onSurface = lightOnSurface;
  static const Color textPrimary = lightOnSurface;
  static const Color textSecondary = lightOnSurfaceVariant;
  static const Color outline = lightOutlineVariant;
}

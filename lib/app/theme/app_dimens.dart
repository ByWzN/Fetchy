import 'package:flutter/widgets.dart';

/// The spacing scale. Every gap in the app should come from here rather
/// than a literal, so vertical rhythm stays consistent across screens.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 36;
  static const double hero = 48;

  /// The horizontal inset every scrollable page uses, so content on Home,
  /// History, and Settings all line up on the same two edges.
  static const double page = 20;
}

/// The raw corner-radius scale.
///
/// Prefer the intent-named tokens in [AppShape] — they say *what* is being
/// shaped, which is what keeps the shape language coherent. These raw
/// values exist so [AppShape] has something to be built from, and because
/// a handful of one-off decorations still reference them directly.
class AppRadius {
  const AppRadius._();

  static const double xxs = 6;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 34;
  static const double pill = 999;
}

/// Fetchy's shape language.
///
/// Deliberately *not* one radius applied everywhere. The rule is that
/// rounding scales with the size and the importance of the surface:
/// small interactive controls stay comparatively crisp so they read as
/// controls, containers get softer as they get larger, and only the two
/// genuinely expressive moments — the primary action and the brand mark —
/// go further than that. Pills are reserved for true labels (status tags,
/// counts), never for buttons or containers, which is what made the old
/// UI read as dated.
class AppShape {
  const AppShape._();

  /// Tags, badges, and the sheet drag handle — things that are labels
  /// rather than surfaces.
  static const BorderRadius tag = BorderRadius.all(Radius.circular(AppRadius.pill));

  /// Small square-ish affordances: leading icon tiles, thumbnails, inline
  /// swatches.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(AppRadius.sm));

  /// Standard interactive controls: buttons, text fields, selector
  /// segments. Crisper than the containers they sit inside.
  static const BorderRadius control = BorderRadius.all(Radius.circular(AppRadius.md));

  /// The container that wraps a group of controls (a segmented track, an
  /// inline banner).
  static const BorderRadius group = BorderRadius.all(Radius.circular(AppRadius.lg));

  /// Content cards and settings groups — the most common surface.
  static const BorderRadius card = BorderRadius.all(Radius.circular(AppRadius.xl));

  /// Dialogs and the top corners of bottom sheets.
  static const BorderRadius sheet = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.xxl),
    topRight: Radius.circular(AppRadius.xxl),
  );

  static const BorderRadius dialog = BorderRadius.all(Radius.circular(AppRadius.xxl));

  /// The one expressive shape in the system: the primary Fetch/Download
  /// action. Rounder than any other control so it is unmistakably the
  /// thing to press — but deliberately short of half its own height, so it
  /// stays a distinctly shaped button rather than collapsing into a pill.
  static const BorderRadius hero = BorderRadius.all(Radius.circular(20));

  /// The download progress bar. Softened but not fully rounded — a pill
  /// track reads as decorative, a slightly squared one reads as a
  /// measurement.
  static const BorderRadius progress = BorderRadius.all(Radius.circular(4));
}

/// Standard motion durations. Kept short: micro-interactions should be felt
/// rather than watched.
class AppMotion {
  const AppMotion._();

  /// Press/state-layer feedback.
  static const Duration fast = Duration(milliseconds: 120);

  /// Selected-state transitions, indicator slides.
  static const Duration medium = Duration(milliseconds: 220);

  /// Layout shifts, expand/collapse.
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeOut;
}

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/fetchy_tokens.dart';

/// Fetchy's download progress bar.
///
/// A chunky, continuous bar filled with the Fetchy cyan-to-blue gradient.
///
/// It deliberately does *not* follow the current Material pattern of
/// separating the fill from the track with a gap and capping the track with
/// a stop indicator: at this size those extra pieces read as two disconnected
/// lines with a dot after them rather than as one bar filling up.
///
/// Two details matter for how it feels:
///
/// * The bar is a single continuous rectangle. The filled part and the
///   remaining track meet with no gap and no end marker, so it reads as one
///   bar filling up rather than as two separate lines with a break in the
///   middle.
/// * The gradient is mapped across the bar's **full** width, not across
///   the filled portion. A given point on the track therefore keeps the
///   same colour as progress advances, so the bar looks like it is being
///   revealed rather than like it is being recoloured every frame.
///
/// This widget is presentational only. It renders whatever [value] it is
/// given and never derives, smooths, or estimates a figure of its own. The
/// only easing it applies is a short tween between two reported values so
/// the bar glides rather than steps; the target is always exactly the
/// figure it was handed.
class FetchyProgressBar extends StatefulWidget {
  const FetchyProgressBar({super.key, required this.value, this.height = 14});

  /// Progress in the range 0..1, or null for an indeterminate bar (used
  /// for phases the engine genuinely reports no percentage for, such as
  /// the merge step).
  final double? value;

  /// Deliberately chunky. A download's progress is the most important thing
  /// on its card, and a thin rule reads as a divider rather than as a
  /// measurement.
  final double height;

  @override
  State<FetchyProgressBar> createState() => _FetchyProgressBarState();
}

class _FetchyProgressBarState extends State<FetchyProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Slow enough to read as deliberate motion rather than a strobe.
    duration: const Duration(milliseconds: 2200),
  );

  /// The last value we were given, so the bar can animate between reported
  /// figures instead of stepping. Purely a rendering nicety — the target is
  /// always exactly what the caller passed.
  double? _displayedValue;

  @override
  void initState() {
    super.initState();
    _displayedValue = widget.value;
    _syncTicker();
  }

  @override
  void didUpdateWidget(FetchyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _displayedValue = oldWidget.value;
    _syncTicker();
  }

  /// The ticker only runs for an indeterminate bar. A determinate bar has
  /// nothing to animate on its own, and leaving a repeating controller
  /// running under it would repaint the card every frame for the entire
  /// download.
  void _syncTicker() {
    final bool needsTicker = widget.value == null;
    if (needsTicker && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!needsTicker && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FetchyTokens tokens = FetchyTokens.of(context);
    final TextDirection direction = Directionality.of(context);
    final double? target = widget.value;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        // Indeterminate bars pin this at 0; the painter ignores it then.
        tween: Tween<double>(
          begin: _displayedValue ?? 0,
          end: (target ?? 0).clamp(0.0, 1.0),
        ),
        duration: target == null ? Duration.zero : AppMotion.slow,
        curve: AppMotion.emphasized,
        builder: (BuildContext context, double animatedValue, _) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              return CustomPaint(
                painter: _FetchyProgressPainter(
                  value: target == null ? null : animatedValue,
                  phase: _controller.value,
                  gradient: tokens.progressGradient,
                  trackColor: tokens.progressTrack,
                  textDirection: direction,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FetchyProgressPainter extends CustomPainter {
  const _FetchyProgressPainter({
    required this.value,
    required this.phase,
    required this.gradient,
    required this.trackColor,
    required this.textDirection,
  });

  final double? value;

  /// 0..1, driving the indeterminate segment's travel. Ignored entirely by
  /// the determinate bar, which has nothing of its own to animate.
  final double phase;

  final List<Color> gradient;
  final Color trackColor;
  final TextDirection textDirection;

  /// How much of the track the indeterminate segment occupies. Small enough
  /// to read as a thing moving along a bar rather than as the bar filling
  /// and emptying.
  static const double _indeterminateExtent = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    // Right-to-left locales fill from the trailing edge. Mirroring the
    // whole canvas keeps a single set of left-to-right maths below.
    if (textDirection == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final Radius r = Radius.circular(AppShape.progress.topLeft.x);
    final Rect fullBar = Offset.zero & size;

    // The track runs the whole width and the fill is drawn on top of it, so
    // the two are always one continuous bar with no seam.
    canvas.drawRRect(
      RRect.fromRectAndRadius(fullBar, r),
      Paint()..color = trackColor,
    );

    final Paint fill = Paint()
      // Mapped across the full bar, not the filled part, so colours stay put
      // as the fill advances.
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(fullBar);

    if (value == null) {
      _paintIndeterminate(canvas, size, r, fill);
      canvas.restore();
      return;
    }

    final double filled = (size.width * value!).clamp(0.0, size.width);
    if (filled > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, filled, size.height),
          r,
        ),
        fill,
      );
    }
    canvas.restore();
  }

  /// A short segment sliding the length of the track and back out again.
  ///
  /// Deliberately a fixed, small width: the previous version derived its two
  /// ends from separate wrapping curves, which meant the segment stretched
  /// to most of the bar and jumped as the curves wrapped — it read as the
  /// bar filling completely in one fast sweep.
  void _paintIndeterminate(Canvas canvas, Size size, Radius r, Paint fill) {
    final double extent = size.width * _indeterminateExtent;
    // Travel from fully off the leading edge to fully off the trailing one,
    // eased so it slows at both ends instead of snapping round.
    final double travel = Curves.easeInOutCubic.transform(phase);
    final double start = -extent + travel * (size.width + extent);

    final Rect segment = Rect.fromLTWH(start, 0, extent, size.height);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, r));
    canvas.drawRRect(RRect.fromRectAndRadius(segment, r), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FetchyProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.phase != phase ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.textDirection != textDirection;
}

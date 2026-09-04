import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The Fetchy hook, drawn as a vector.
///
/// This is the app's mark: a hooked spiral that curls over from the stem,
/// crosses to make the "F", and finishes in a download arrow. Rendering it
/// as a [CustomPainter] rather than shipping the logo PNG means it stays
/// crisp at every size, picks up whatever colour or gradient the surface
/// needs, and costs nothing to tint per theme — which is what lets the
/// same mark serve as the Fetch button's icon, the empty-state glyph, and
/// the wordmark's lockup without three separate assets.
///
/// The geometry is authored against the logo's own 1024x1536 canvas (see
/// [_HookGeometry]) and scaled to whatever box it is given.
class FetchyHookIcon extends StatelessWidget {
  const FetchyHookIcon({super.key, this.size = 24, this.color, this.gradient});

  /// The mark's height. Its width follows from the logo's own proportions
  /// (roughly 0.59x the height).
  final double size;

  /// A flat fill. Ignored when [gradient] is supplied; defaults to the
  /// ambient [IconTheme] colour, then the scheme's primary.
  final Color? color;

  /// A gradient fill, mapped across the mark's bounding box. Using the
  /// brand gradient here is what visually ties the Fetch button to the logo.
  final Gradient? gradient;

  /// The mark's width for a given height.
  static double widthFor(double height) => height * _HookGeometry.aspectRatio;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widthFor(size),
      height: size,
      child: CustomPaint(
        painter: _FetchyHookPainter(color: effectiveColor, gradient: gradient),
      ),
    );
  }
}

/// The logo's measurements, in its own authoring canvas.
///
/// The hook is a 117-unit-wide stroke swept around a circle centred at
/// ([centerX], [centerY]): [outerRadius] and [innerRadius] are that
/// stroke's two edges, and the tail tapers to a point on the stroke's
/// midline. The stem, crossbar, and arrowhead all hang off that same
/// circle, which is why every value below is expressed relative to it
/// rather than as an isolated coordinate.
class _HookGeometry {
  const _HookGeometry._();

  static const double centerX = 604;
  static const double centerY = 451;
  static const double outerRadius = 351;
  static const double innerRadius = 234;
  static const double strokeWidth = outerRadius - innerRadius; // 117
  static const double midRadius = (outerRadius + innerRadius) / 2; // 292.5

  /// The stem's centre line, running down from the circle's leftmost point.
  static const double stemX = centerX - midRadius; // 311.5
  static const double stemBottom = 1240;

  /// The crossbar that turns the hook into an "F".
  static const double crossbarY = 750.5;
  static const double crossbarEndX = 596.5;

  /// The arrowhead is authored inset and then expanded by a round stroke,
  /// which rounds its three corners without hand-built arcs.
  static const double arrowTopY = 1226;
  static const double arrowHalfWidth = 138;
  static const double arrowTipY = 1420;
  static const double arrowCornerRadius = 26;

  /// Where the tail's outer edge stops, where its inner edge stops, and
  /// where the two converge — in degrees clockwise from "east", matching
  /// Flutter's canvas convention (y grows downwards).
  static const double tailOuterEndDeg = 40;
  static const double tailInnerEndDeg = 0;
  static const double tailTipDeg = 65;
  static const double tailTipRadius = 290;

  /// The painted bounds, derived from everything above. The arrowhead's
  /// wings are the widest point on the left, the circle on the right.
  static const double left = stemX - arrowHalfWidth - arrowCornerRadius;
  static const double right = centerX + outerRadius;
  static const double top = centerY - outerRadius;

  /// Where the arrow's point lands once the round stroke has expanded it
  /// along the apex bisector.
  static const double bottom = arrowTipY + 45;

  static const double width = right - left;
  static const double height = bottom - top;
  static const double aspectRatio = width / height;
}

class _FetchyHookPainter extends CustomPainter {
  const _FetchyHookPainter({required this.color, this.gradient});

  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Rect box = Offset.zero & size;
    final Shader? shader = gradient?.createShader(box);

    final Paint fill = Paint()
      ..isAntiAlias = true
      ..color = color
      ..shader = shader;

    // The stem and crossbar are one thick round-capped stroke; the arrow's
    // corners are rounded by expanding an inset triangle. Everything is
    // painted in the same colour, so the overlaps merge into a single
    // silhouette and every join is rounded for free.
    final Paint limb = Paint()
      ..isAntiAlias = true
      ..color = color
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = _HookGeometry.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint arrowRounding = Paint()
      ..isAntiAlias = true
      ..color = color
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = _HookGeometry.arrowCornerRadius * 2
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    // Fit the authoring canvas into whatever box we were given, uniformly
    // on both axes so the mark can never be stretched.
    final double scale = size.height / _HookGeometry.height;
    canvas.translate((size.width - _HookGeometry.width * scale) / 2, 0);
    canvas.scale(scale);
    canvas.translate(-_HookGeometry.left, -_HookGeometry.top);

    canvas.drawPath(_buildHookTail(), fill);
    canvas.drawPath(_buildStemAndCrossbar(), limb);

    final Path arrow = _buildArrowhead();
    canvas.drawPath(arrow, fill);
    canvas.drawPath(arrow, arrowRounding);

    canvas.restore();
  }

  /// The curl: a thick arc that tapers to a point where the tail ends.
  Path _buildHookTail() {
    const Offset centre = Offset(_HookGeometry.centerX, _HookGeometry.centerY);
    final Rect outer = Rect.fromCircle(
      center: centre,
      radius: _HookGeometry.outerRadius,
    );
    final Rect inner = Rect.fromCircle(
      center: centre,
      radius: _HookGeometry.innerRadius,
    );

    const double startDeg = 180;
    const double outerSweep = (360 + _HookGeometry.tailOuterEndDeg) - startDeg;
    final Offset tip = _polar(
      centre,
      _HookGeometry.tailTipRadius,
      _HookGeometry.tailTipDeg,
    );
    final Offset innerEnd = _polar(
      centre,
      _HookGeometry.innerRadius,
      _HookGeometry.tailInnerEndDeg,
    );

    return Path()
      ..moveTo(_HookGeometry.centerX - _HookGeometry.outerRadius, _HookGeometry.centerY)
      ..arcTo(outer, _rad(startDeg), _rad(outerSweep), false)
      // A shallow curve into the point rather than a hard corner, so the
      // tip reads as drawn rather than as clipped.
      ..quadraticBezierTo(
        (tip.dx + innerEnd.dx) / 2 + 18,
        tip.dy + 14,
        tip.dx,
        tip.dy,
      )
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(inner, _rad(_HookGeometry.tailInnerEndDeg), _rad(-180), false)
      ..close();
  }

  Path _buildStemAndCrossbar() {
    return Path()
      ..moveTo(_HookGeometry.stemX, _HookGeometry.centerY)
      ..lineTo(_HookGeometry.stemX, _HookGeometry.stemBottom)
      ..moveTo(_HookGeometry.stemX, _HookGeometry.crossbarY)
      ..lineTo(_HookGeometry.crossbarEndX, _HookGeometry.crossbarY);
  }

  Path _buildArrowhead() {
    const double cx = _HookGeometry.stemX;
    return Path()
      ..moveTo(cx + _HookGeometry.arrowHalfWidth, _HookGeometry.arrowTopY)
      ..lineTo(cx, _HookGeometry.arrowTipY)
      ..lineTo(cx - _HookGeometry.arrowHalfWidth, _HookGeometry.arrowTopY)
      ..close();
  }

  static Offset _polar(Offset origin, double radius, double degrees) {
    final double radians = _rad(degrees);
    return Offset(
      origin.dx + radius * math.cos(radians),
      origin.dy + radius * math.sin(radians),
    );
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(_FetchyHookPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gradient != gradient;
}

/// The supplied fishing-hook artwork, used on the Fetch button.
///
/// Two rasters the user provided, one per theme: `hook.png` is white and
/// `hook_light.png` is cyan. They are drawn in their own colours rather than
/// tinted, since the whole point of shipping two files is that each already
/// carries the colour it should be. [color] is therefore an override used
/// only for the disabled state, where the glyph has to grey out with the
/// rest of the button.
///
/// Both sources are 32x32, so they are scaled up on high-density screens and
/// will not be as crisp as a vector.
class FetchyHookAsset extends StatelessWidget {
  const FetchyHookAsset({super.key, this.size = 21, this.color});

  final double size;

  /// Forces a tint. Left null to draw the artwork as authored.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDark ? 'assets/icon/hook.png' : 'assets/icon/hook_light.png',
      width: size,
      height: size,
      color: color,
      // The artwork is small; smoothing beats nearest-neighbour blockiness
      // when it is scaled past its native size.
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
    );
  }
}

/// The Fetchy hook inside a rounded brand-gradient tile — the launcher-icon
/// lockup, used where the app needs to present "itself" (the About row).
class FetchyMarkTile extends StatelessWidget {
  const FetchyMarkTile({super.key, this.size = 40, this.radiusFactor = 0.3});

  final double size;

  /// Corner radius as a fraction of [size]. The default reads as a
  /// superellipse-ish squircle rather than a circle or a plain box.
  final double radiusFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * radiusFactor),
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          stops: AppColors.brandGradientStops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: FetchyHookIcon(size: size * 0.62, color: Colors.white),
    );
  }
}

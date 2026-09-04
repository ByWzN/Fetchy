import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'fetchy_hook_icon.dart';

/// Fetchy's wordmark: the hook mark followed by a gradient-filled
/// "Fetchy", used wherever the app names itself.
///
/// The mark and the word share one gradient definition, so the lockup
/// reads as a single object rather than as an icon placed next to some
/// text.
class FetchyWordmark extends StatelessWidget {
  const FetchyWordmark({super.key, this.fontSize = 24, this.includeMark = true});

  final double fontSize;
  final bool includeMark;

  static const LinearGradient _gradient = LinearGradient(
    colors: AppColors.brandGradient,
    stops: AppColors.brandGradientStops,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (includeMark) ...<Widget>[
          FetchyHookIcon(size: fontSize * 1.16, gradient: _gradient),
          SizedBox(width: fontSize * 0.34),
        ],
        ShaderMask(
          shaderCallback: _gradient.createShader,
          child: Text(
            // The product name is a proper noun and is never translated,
            // in any locale.
            'Fetchy',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// The launcher-icon lockup: the hook on a rounded brand-gradient tile.
///
/// Kept as an alias of [FetchyMarkTile] so the many call sites that grew up
/// around the old name keep working while there is only one implementation.
class FetchyMark extends StatelessWidget {
  const FetchyMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => FetchyMarkTile(size: size);
}

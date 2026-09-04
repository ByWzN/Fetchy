import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/fetchy_tokens.dart';

/// Adds a small scale-down on press to anything wrapped in it.
///
/// Material's ink ripple says "you touched something"; this says "the thing
/// you touched is a control". It is used on the primary action and on
/// tappable cards, and deliberately nowhere else — applied everywhere it
/// would just read as the whole screen wobbling.
class FetchyPressable extends StatefulWidget {
  const FetchyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<FetchyPressable> createState() => _FetchyPressableState();
}

class _FetchyPressableState extends State<FetchyPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// The app's primary action: Fetch on Home, Download on the media preview.
///
/// It is the only control in Fetchy filled with the brand gradient and the
/// only one carrying the hero corner radius, so there is never any question
/// which button on a screen is *the* button. The leading glyph is the
/// Fetchy hook itself rather than a generic download arrow, which is what
/// visually ties the action back to the logo.
///
/// Disabled and busy states both drop the gradient for a flat tonal fill —
/// a greyed-out gradient reads as a rendering bug rather than as "not yet".
class FetchyPrimaryButton extends StatelessWidget {
  const FetchyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.glyph,
    this.busy = false,
    this.busyLabel,
    this.height = 54,
    this.expand = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The leading icon. Defaults to a plain download arrow — the primary
  /// action is nearly always "get this file", and a conventional icon is
  /// read faster than a branded one.
  final IconData? icon;

  /// A custom leading glyph, taking precedence over [icon]. Home passes the
  /// Fetchy hook here; that is the one screen where the brand mark earns
  /// its place on a control.
  final Widget? glyph;

  /// Swaps the glyph for a spinner and blocks the tap without changing the
  /// button's size, so the layout never jumps when work starts.
  final bool busy;

  /// Shown instead of [label] while [busy].
  final String? busyLabel;

  final double height;

  /// Whether the button stretches to its parent's width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool enabled = onPressed != null && !busy;

    final Color foreground = enabled
        ? Colors.white
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    // The spinner runs a little larger than the resting glyph — it is the
    // only thing moving on the screen while work is in flight, and at the
    // glyph's size it read as an afterthought.
    final double slotSize = busy ? 26 : 22;

    final Widget slot = busy
        ? SizedBox(
            width: slotSize,
            height: slotSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: foreground,
            ),
          )
        : glyph ??
              Icon(
                icon ?? Icons.download_rounded,
                size: slotSize,
                color: foreground,
              );

    // A resting glyph sits *after* the label — "Fetch 🪝" in English, which
    // the Row mirrors to "🪝 جلب" in Arabic with no extra handling. A busy
    // spinner leads instead, which is the conventional reading order for
    // "working on it".
    //
    // Either way the opposite side is padded by exactly the slot's width
    // plus its gap, which is what keeps the word itself dead-centre in the
    // button rather than shunted off-centre by whatever sits beside it.
    final Widget label_ = Flexible(
      child: Text(
        busy ? (busyLabel ?? label) : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
    final Widget balance = SizedBox(width: slotSize + AppSpacing.md);
    final Widget gap = const SizedBox(width: AppSpacing.md);

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: busy
          ? <Widget>[slot, gap, label_, balance]
          : <Widget>[balance, label_, gap, slot],
    );

    // A plain Container, not an AnimatedContainer. Cross-fading the gradient
    // and its shadow bought nothing — enabled/disabled is an instant,
    // deliberate change — and an implicitly animated decoration under a big
    // blurred shadow is a needless source of shimmer on a surface that is
    // already repainting while a download runs.
    return FetchyPressable(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppShape.hero,
          color: enabled ? null : tokens.surfaceSunken,
          gradient: enabled
              ? LinearGradient(
                  colors: tokens.accentGradient,
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                )
              : null,
          // No coloured glow at all. It was asked for three times running and
          // the honest answer is that the gradient does not need help being
          // found — it is the only one on the screen. What is left is a
          // plain, almost-black drop shadow that lifts the button off the
          // page without tinting the air around it.
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: tokens.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: content,
      ),
    );
  }
}

/// The quiet partner to [FetchyPrimaryButton]: a flat tonal fill with no
/// outline, for secondary actions (Open, Share, Cancel, Change).
class FetchyTonalButton extends StatelessWidget {
  const FetchyTonalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expand = true,
    this.emphasis = false,
    this.destructive = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expand;

  /// Uses the brand tint instead of the neutral one — for the secondary
  /// action that still matters most on its screen.
  final bool emphasis;

  final bool destructive;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool enabled = onPressed != null && !busy;

    final (Color background, Color foreground) = destructive
        ? (colorScheme.errorContainer, colorScheme.onErrorContainer)
        : emphasis
        ? (tokens.surfaceSelected, tokens.onSurfaceSelected)
        : (tokens.surfaceSunken, colorScheme.onSurface);

    final Color effectiveForeground = enabled
        ? foreground
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return FetchyPressable(
      onTap: enabled ? onPressed : null,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? background
              : background.withValues(alpha: 0.5),
          borderRadius: AppShape.control,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveForeground,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: effectiveForeground),
            if (busy || icon != null) const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: effectiveForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact tonal icon button — the shape used for card-level affordances
/// (cancel a download, open filters) where a labelled button would be too
/// heavy.
class FetchyIconButton extends StatelessWidget {
  const FetchyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 19,
    this.emphasis = false,
    this.destructive = false,
    this.borderRadius = AppShape.chip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool emphasis;
  final bool destructive;

  /// Rounding scales with the button: the small ones keep the chip radius,
  /// while a large one sitting next to the primary action matches its
  /// shape instead.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final (Color background, Color foreground) = destructive
        ? (colorScheme.errorContainer, colorScheme.onErrorContainer)
        : emphasis
        ? (tokens.surfaceSelected, tokens.onSurfaceSelected)
        : (tokens.surfaceSunken, colorScheme.onSurfaceVariant);

    final Widget button = Material(
      color: background,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: foreground),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import '../theme/fetchy_tokens.dart';

/// Where a surface sits in Fetchy's depth order.
///
/// The app has exactly three planes and no more: the page itself, things
/// lifted off it, and wells recessed into it. Keeping the vocabulary this
/// small is what stops the UI drifting back into "a border around
/// everything" — depth is expressed by tone, not by outline.
enum FetchyTone {
  /// Lifted off the page: cards, settings groups, sheets.
  raised,

  /// Recessed into it: read-only summaries, input fills, selector tracks.
  sunken,

  /// Currently chosen. A brand-tinted fill, never a border.
  selected,

  /// No fill at all — for grouping without introducing another plane.
  flat,
}

/// The single container primitive every Fetchy surface is built from.
///
/// It owns the fill, the shape, the (very restrained) shadow, and the ink
/// response, so no page has to decide any of those for itself. Anything
/// that would previously have been a `Container` with a `BoxDecoration`
/// and a `Border.all` should be one of these instead.
class FetchySurface extends StatelessWidget {
  const FetchySurface({
    super.key,
    required this.child,
    this.tone = FetchyTone.raised,
    this.padding,
    this.borderRadius = AppShape.card,
    this.color,
    this.onTap,
    this.onLongPress,
    this.elevated = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final FetchyTone tone;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  /// Overrides the fill [tone] would otherwise supply — for the semantic
  /// surfaces (success/warning/error banners) that are not part of the
  /// neutral depth order.
  final Color? color;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Whether a raised surface also casts its ambient shadow. Turn it off
  /// for a raised surface nested inside another one, where a second shadow
  /// would just read as grime.
  final bool elevated;

  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color fill = color ?? switch (tone) {
      FetchyTone.raised => tokens.surfaceRaised,
      FetchyTone.sunken => tokens.surfaceSunken,
      FetchyTone.selected => tokens.surfaceSelected,
      FetchyTone.flat => Colors.transparent,
    };

    // A shadow only ever appears on light, and only on a raised surface.
    // On dark it would be invisible, so the raised tone carries the depth
    // by itself.
    final List<BoxShadow> shadows =
        (!elevated || isDark || tone != FetchyTone.raised)
        ? const <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: tokens.shadow.withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: tokens.shadow.withValues(alpha: 0.03),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ];

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: Material(
        color: fill,
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        type: fill == Colors.transparent ? MaterialType.transparency : MaterialType.canvas,
        child: content,
      ),
    );
  }
}

/// The standard content card: a raised surface with the app's usual inset.
class FetchyCard extends StatelessWidget {
  const FetchyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.tone = FetchyTone.raised,
    this.borderRadius = AppShape.card,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final FetchyTone tone;
  final BorderRadius borderRadius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return FetchySurface(
      tone: tone,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      elevated: elevated,
      child: child,
    );
  }
}

/// A caption above a group of content.
///
/// Small, tracked out, and always in `onSurfaceVariant` — a signpost, not
/// a heading. Every section label in the app routes through this so they
/// are all identical and none of them competes with the content below.
class FetchySectionHeader extends StatelessWidget {
  const FetchySectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.only(
      start: AppSpacing.xs,
      bottom: AppSpacing.sm,
      end: AppSpacing.xs,
    ),
  });

  final String title;
  final IconData? icon;

  /// An optional action aligned to the far end of the caption row (an
  /// "Edit" link, a count). Kept quiet so the caption stays a caption.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color labelColor = theme.colorScheme.onSurfaceVariant;
    final TextStyle style = AppTypography.sectionCaption(
      theme.textTheme,
    ).copyWith(color: labelColor);

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: labelColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(title, style: style)),
          ?trailing,
        ],
      ),
    );
  }
}

/// A group of rows rendered as one raised surface with hairlines between
/// them — the shape every settings-style list uses.
///
/// The hairlines are inset from the leading edge so they read as row
/// separators rather than as a table grid.
class FetchyGroup extends StatelessWidget {
  const FetchyGroup({
    super.key,
    required this.children,
    this.title,
    this.icon,
    this.trailing,
    this.dividerIndent = 60,
  });

  final List<Widget> children;
  final String? title;
  final IconData? icon;
  final Widget? trailing;

  /// How far the hairline is inset from the leading edge, so it starts
  /// past the rows' leading icons.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final FetchyTokens tokens = FetchyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          FetchySectionHeader(title: title!, icon: icon, trailing: trailing),
        FetchySurface(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: dividerIndent,
                    endIndent: 0,
                    color: tokens.hairline,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The page wash.
///
/// Two nearly-identical surface tones with a single soft brand glow in the
/// top trailing corner and a fainter cyan one at the bottom leading corner.
/// Deliberately almost subliminal: it exists so a full screen of cards does
/// not sit on a dead flat slab, and it must never read as a pattern or a
/// texture. Nothing here is interactive, and it never tints content.
class FetchyPageBackground extends StatelessWidget {
  const FetchyPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tokens.pageGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.95, -1.05),
                    radius: 1.1,
                    colors: <Color>[
                      colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.07),
                      colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.0, 1.1),
                    radius: 0.95,
                    colors: <Color>[
                      colorScheme.secondary.withValues(alpha: isDark ? 0.08 : 0.05),
                      colorScheme.secondary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// A page shell: transparent scaffold, brand app bar, and the page wash.
///
/// Every full screen in Fetchy uses this so the background treatment,
/// app-bar style, and safe-area handling are decided once. A page that
/// needs an unusual body (a full-bleed list, its own bottom bar) still
/// gets the same chrome.
class FetchyScaffold extends StatelessWidget {
  const FetchyScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.safeArea = true,
    this.centerTitle,
    this.toolbarHeight,
  });

  final Widget body;

  /// The app-bar title as plain text. Ignored when [titleWidget] is given.
  final String? title;
  final Widget? titleWidget;

  /// Overrides the theme's start-aligned app-bar title. Home centres its
  /// title, because there the title is the app's own name rather than a
  /// label for the screen you happen to be on.
  final bool? centerTitle;

  /// A taller bar, which lets Home sit its masthead lower down the screen
  /// instead of tight against the status bar.
  final double? toolbarHeight;

  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;

  /// Whether the body is wrapped in a [SafeArea]. Turned off by pages that
  /// manage their own insets.
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final bool hasAppBar =
        title != null || titleWidget != null || actions != null;

    // The app bar already clears the status bar when there is one. Without
    // one the body has to clear it itself, or a page that puts its own
    // heading at the top would tuck it under the clock.
    final Widget content = safeArea
        ? SafeArea(top: !hasAppBar, child: body)
        : body;

    // The wash sits *outside* the Scaffold so it runs continuously behind
    // the app bar as well as the body. Painting it inside the body instead
    // would either leave a seam at the app bar or push content underneath
    // it, and the whole point of the treatment is that the screen reads as
    // one surface.
    return FetchyPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: !hasAppBar
            ? null
            : AppBar(
                title: titleWidget ?? (title == null ? null : Text(title!)),
                actions: actions,
                leading: leading,
                centerTitle: centerTitle,
                toolbarHeight: toolbarHeight,
              ),
        bottomNavigationBar: bottomNavigationBar,
        body: content,
      ),
    );
  }
}

/// A small rounded tile holding a leading icon, used at the start of a
/// settings-style row. Tonal by default; [emphasis] switches it to the
/// brand tint for the one or two rows per screen that deserve it.
class FetchyLeadingIcon extends StatelessWidget {
  const FetchyLeadingIcon({
    super.key,
    required this.icon,
    this.emphasis = false,
    this.destructive = false,
    this.size = 38,
  });

  final IconData icon;
  final bool emphasis;
  final bool destructive;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final (Color background, Color foreground) = destructive
        ? (colorScheme.errorContainer, colorScheme.onErrorContainer)
        : emphasis
        ? (tokens.surfaceSelected, tokens.onSurfaceSelected)
        : (tokens.surfaceSunken, colorScheme.onSurfaceVariant);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppShape.chip,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

/// A small status/metadata label. The one place a full pill shape is used,
/// because a tag genuinely is a label rather than a surface.
class FetchyTag extends StatelessWidget {
  const FetchyTag({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FetchyTokens tokens = FetchyTokens.of(context);
    final Color fg = foreground ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? AppSpacing.sm : AppSpacing.sm - 1,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background ?? tokens.surfaceSunken,
        borderRadius: AppShape.tag,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

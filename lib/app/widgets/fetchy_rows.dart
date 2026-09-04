import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/fetchy_tokens.dart';
import 'fetchy_surface.dart';

/// One row inside a [FetchyGroup].
///
/// The settings-style row: an optional leading icon tile, a title, an
/// optional subtitle, and a trailing affordance (chevron, switch, button).
/// Every Settings, Download Location, Quick Fetch, Connected Accounts, and
/// Diagnostics row is one of these, which is what keeps their spacing and
/// type identical.
///
/// Subtitles are deliberately capped at two lines: a settings row is a
/// summary and a doorway, and anything that needs more than two lines to
/// explain belongs on the screen behind it.
class FetchyListRow extends StatelessWidget {
  const FetchyListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.destructive = false,
    this.enabled = true,
    this.subtitleMaxLines = 2,
    this.titleTextDirection,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Adds the drill-down chevron. Kept separate from [trailing] so a row
  /// can have both a value and a chevron.
  final bool showChevron;

  final bool destructive;
  final bool enabled;
  final int subtitleMaxLines;

  /// Forces the title's direction — used for rows whose title is a domain
  /// or a URL, which must stay left-to-right even in Arabic.
  final TextDirection? titleTextDirection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color titleColor = destructive
        ? colorScheme.error
        : enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textDirection: titleTextDirection,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: subtitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
          if (showChevron) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (onTap == null || !enabled) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// How a [FetchyBanner] is coloured.
enum FetchyBannerTone { neutral, info, success, warning, error }

/// The inline explanatory strip used throughout the app: the slow-fetch
/// notice, the sessions privacy note, the Download Location intro, the
/// Pull Info result, the Limitations text.
///
/// All of those used to be hand-built containers with slightly different
/// padding, radius, and icon size. Routing them through one widget is what
/// makes "informational" a recognisable thing in the UI rather than five
/// similar-looking boxes.
class FetchyBanner extends StatelessWidget {
  const FetchyBanner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = FetchyBannerTone.neutral,
    this.action,
    this.margin = EdgeInsets.zero,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final FetchyBannerTone tone;

  /// An action rendered below the message — the "Enable accessibility"
  /// style button on Quick Fetch's status rows.
  final Widget? action;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final (Color background, Color foreground, IconData defaultIcon) = switch (tone) {
      FetchyBannerTone.neutral => (
        tokens.surfaceSunken,
        colorScheme.onSurfaceVariant,
        Icons.info_outline_rounded,
      ),
      FetchyBannerTone.info => (
        tokens.surfaceSelected,
        tokens.onSurfaceSelected,
        Icons.info_outline_rounded,
      ),
      FetchyBannerTone.success => (
        tokens.successBg,
        tokens.successFg,
        Icons.check_circle_outline_rounded,
      ),
      FetchyBannerTone.warning => (
        tokens.warningBg,
        tokens.warningFg,
        Icons.warning_amber_rounded,
      ),
      FetchyBannerTone.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
    };

    return Padding(
      padding: margin,
      child: FetchySurface(
        color: background,
        borderRadius: AppShape.group,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon ?? defaultIcon, size: 18, color: foreground),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                        height: 1.45,
                      ),
                    ),
                  if (action != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: action,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value line inside a read-only summary well.
///
/// Used by the media preview's "what will actually be downloaded" summary
/// and by the History detail page. [emphasize] is reserved for the one
/// figure per summary that the user is really looking for (the file size).
class FetchyDetailRow extends StatelessWidget {
  const FetchyDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.icon,
    this.valueTextDirection,
  });

  final String label;
  final String value;
  final bool emphasize;
  final IconData? icon;

  /// Forces the value's direction, for paths and URLs.
  final TextDirection? valueTextDirection;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: valueTextDirection,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: emphasize ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An empty-state block: a soft glyph, a headline, a line of explanation,
/// and an optional action.
class FetchyEmptyState extends StatelessWidget {
  const FetchyEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.glyph,
    this.action,
  });

  final String title;
  final String message;
  final IconData? icon;

  /// A custom glyph in place of [icon] — used to put the Fetchy hook at the
  /// centre of the "no downloads yet" state.
  final Widget? glyph;

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: tokens.surfaceSunken,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: glyph ??
              Icon(
                icon ?? Icons.inbox_rounded,
                size: 30,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (action != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          action!,
        ],
      ],
    );
  }
}

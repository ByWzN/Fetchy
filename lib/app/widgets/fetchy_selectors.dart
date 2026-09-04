import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/fetchy_tokens.dart';
import 'fetchy_surface.dart';

/// One option in a [FetchySegmented].
class FetchySegment<T> {
  const FetchySegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Fetchy's inline choice control, replacing Material's [SegmentedButton].
///
/// The old control drew an outlined rounded rectangle divided by vertical
/// rules — the single most dated pattern in the app, and repeated on
/// Appearance, Language, media mode, artwork, and Quick Fetch. This is the
/// modern equivalent: a recessed track with a brand-tinted pill sliding
/// between positions, so the selection reads instantly from fill and
/// motion instead of from borders.
///
/// The indicator is positioned directionally, so it slides from the right
/// in Arabic exactly as it slides from the left in English.
class FetchySegmented<T> extends StatelessWidget {
  const FetchySegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.dense = false,
  });

  final List<FetchySegment<T>> segments;
  final T selected;

  /// Null disables the whole control.
  final ValueChanged<T>? onChanged;

  /// Drops the height and hides the icons — for a control sitting inside a
  /// card rather than owning a section.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool enabled = onChanged != null;

    const double trackPadding = 4;
    final double height = dense ? 40 : 48;

    int selectedIndex = segments.indexWhere(
      (FetchySegment<T> segment) => segment.value == selected,
    );
    if (selectedIndex < 0) selectedIndex = 0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double innerWidth = constraints.maxWidth - trackPadding * 2;
        final double segmentWidth = segments.isEmpty
            ? 0
            : innerWidth / segments.length;

        return Container(
          height: height,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: tokens.surfaceSunken,
            borderRadius: AppShape.group,
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositionedDirectional(
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                start: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: enabled
                        ? tokens.surfaceSelected
                        : tokens.surfaceSelected.withValues(alpha: 0.4),
                    borderRadius: AppShape.control,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < segments.length; i++)
                    Expanded(
                      child: _SegmentLabel<T>(
                        segment: segments[i],
                        isSelected: i == selectedIndex,
                        enabled: enabled,
                        dense: dense,
                        selectedColor: tokens.onSurfaceSelected,
                        unselectedColor: colorScheme.onSurfaceVariant,
                        disabledColor: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.45,
                        ),
                        onTap: enabled ? () => onChanged!(segments[i].value) : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentLabel<T> extends StatelessWidget {
  const _SegmentLabel({
    required this.segment,
    required this.isSelected,
    required this.enabled,
    required this.dense,
    required this.selectedColor,
    required this.unselectedColor,
    required this.disabledColor,
    required this.onTap,
  });

  final FetchySegment<T> segment;
  final bool isSelected;
  final bool enabled;
  final bool dense;
  final Color selectedColor;
  final Color unselectedColor;
  final Color disabledColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = !enabled
        ? disabledColor
        : (isSelected ? selectedColor : unselectedColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShape.control,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (segment.icon != null && !dense) ...<Widget>[
                  Icon(segment.icon, size: 17, color: foreground),
                  const SizedBox(width: AppSpacing.xs + 2),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.medium,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: foreground,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tonal choice chip for a wrapped set of options — quality tiers,
/// resolutions, audio formats, history filters.
///
/// Selection is a fill change plus a weight change, with no border in
/// either state. Where an option has a figure attached (a file size), it
/// sits on a second line in a quieter style rather than being crammed onto
/// the label with a separator, which is what made the old
/// "1080p | 24.3 MB" chips so dense.
class FetchyChoiceChip extends StatelessWidget {
  const FetchyChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.caption,
    this.icon,
  });

  final String label;
  final String? caption;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final Color background = isSelected
        ? tokens.surfaceSelected
        : tokens.surfaceSunken;
    final Color foreground = isSelected
        ? tokens.onSurfaceSelected
        : colorScheme.onSurface;
    final Color captionColor = isSelected
        ? tokens.onSurfaceSelected.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: AppShape.control,
      clipBehavior: Clip.antiAlias,
      animationDuration: AppMotion.medium,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: caption == null ? AppSpacing.md - 2 : AppSpacing.sm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 15, color: foreground),
                    const SizedBox(width: AppSpacing.xs + 1),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: captionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A drill-down row: a label on the leading edge, its current value on the
/// trailing edge, and a chevron.
///
/// This is the shape every "pick one of several things" control in Fetchy
/// collapses to — Format, Quality, FPS, Subtitles, Bitrate, Download
/// Location. The value carries the state: neutral when it is the default,
/// and a brand-tinted tonal chip when the user has actively chosen
/// something, so an overridden setting is visible without scanning.
///
/// A null [onTap] renders the row genuinely disabled rather than merely
/// inert, which is how "this media reports no FPS values at all" is
/// distinguished from "this control is broken".
class FetchySelectorRow extends StatelessWidget {
  const FetchySelectorRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.selected = false,
    this.description,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Whether [value] is an explicit user choice rather than the default.
  final bool selected;

  final String? description;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);
    final bool enabled = onTap != null;

    final Color labelColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppShape.control,
        child: Padding(
          padding: padding,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? AppSpacing.md : 0,
                  vertical: selected ? AppSpacing.xs + 1 : 0,
                ),
                decoration: BoxDecoration(
                  color: selected && enabled
                      ? tokens.surfaceSelected
                      : Colors.transparent,
                  borderRadius: AppShape.chip,
                ),
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: !enabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : (selected
                              ? tokens.onSurfaceSelected
                              : colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable row inside a picker sheet.
///
/// Selection is shown by a tonal fill plus a filled check on the trailing
/// edge — not by a radio button, which reads as a form control rather than
/// as a choice already made.
class FetchyOptionTile extends StatelessWidget {
  const FetchyOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.description,
    this.trailingText,
    this.leading,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? description;

  /// A secondary figure aligned before the check mark — a file size, a
  /// bitrate. Kept quiet so the label stays the thing being chosen.
  final String? trailingText;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? tokens.surfaceSelected : Colors.transparent,
        borderRadius: AppShape.control,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 1,
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
                    children: <Widget>[
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? tokens.onSurfaceSelected
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? tokens.onSurfaceSelected.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailingText != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? tokens.onSurfaceSelected.withValues(alpha: 0.85)
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                AnimatedOpacity(
                  duration: AppMotion.medium,
                  opacity: isSelected ? 1 : 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: tokens.onSurfaceSelected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable choice rendered as a card rather than a list row — used for
/// the "how do you want to do this?" forks (cookie source, session connect
/// method) where each option needs a sentence of explanation.
class FetchyActionTile extends StatelessWidget {
  const FetchyActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.emphasis = false,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool emphasis;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FetchyTokens tokens = FetchyTokens.of(context);

    final Color titleColor = destructive
        ? colorScheme.error
        : emphasis
        ? tokens.onSurfaceSelected
        : (enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant);
    final Color subtitleColor = emphasis
        ? tokens.onSurfaceSelected.withValues(alpha: 0.85)
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FetchySurface(
        tone: emphasis ? FetchyTone.selected : FetchyTone.sunken,
        borderRadius: AppShape.control,
        onTap: enabled ? onTap : null,
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: destructive ? colorScheme.error : titleColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

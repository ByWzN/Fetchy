import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/fetchy_tokens.dart';

/// The shared chrome for every Fetchy bottom sheet.
///
/// Previously each sheet hand-rolled its own drag handle, title, padding,
/// and keyboard handling, which is why they had drifted apart. This owns
/// all four, so Download Options, the Format/Quality/FPS pickers, the
/// subtitle picker, the History filters, and the session sheets are all
/// visibly the same surface.
///
/// The keyboard is handled once, here, for the whole sheet: opening it
/// shrinks how much of the single scrollable is visible rather than
/// shifting any individual field, which is what keeps a focused text field
/// reachable without leaving blank space next to a separately-anchored
/// button row.
class FetchySheet extends StatelessWidget {
  const FetchySheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.titleTrailing,
    this.footer,
    this.maxHeightFactor = 0.9,
    this.pinFooter = false,
  });

  final String title;
  final String? subtitle;

  /// An action aligned to the trailing edge of the title row (a "Use
  /// automatic" reset, for instance).
  final Widget? titleTrailing;

  final Widget child;

  /// A button row below the content.
  final Widget? footer;

  /// How much of the screen the sheet may occupy at most.
  final double maxHeightFactor;

  /// When true the footer stays visible while the body scrolls. Left false
  /// for form-style sheets, where scrolling the buttons with the fields is
  /// what keeps them reachable above an open keyboard.
  final bool pinFooter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?titleTrailing,
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: child,
    );

    final Widget footerRow = footer == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              0,
            ),
            child: footer,
          );

    return AnimatedPadding(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const FetchySheetHandle(),
              if (pinFooter) ...<Widget>[
                header,
                Flexible(child: SingleChildScrollView(child: body)),
                footerRow,
                const SizedBox(height: AppSpacing.xl),
              ] else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        header,
                        body,
                        footerRow,
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grab handle at the top of a sheet.
class FetchySheetHandle extends StatelessWidget {
  const FetchySheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
            alpha: 0.35,
          ),
          borderRadius: AppShape.tag,
        ),
      ),
    );
  }
}

/// Opens a modal sheet with Fetchy's shape and scrim.
///
/// Every sheet in the app goes through this so none of them can quietly
/// pick up a different corner radius or background.
Future<T?> showFetchySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final FetchyTokens tokens = FetchyTokens.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: tokens.surfaceRaised,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(borderRadius: AppShape.sheet),
    clipBehavior: Clip.antiAlias,
    builder: builder,
  );
}

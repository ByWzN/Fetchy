import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';
import 'fetchy_tokens.dart';

/// Fetchy's two themes.
///
/// Both schemes are written out explicitly rather than derived with
/// [ColorScheme.fromSeed]. A seeded blue palette generates lavender
/// secondary/tertiary containers, and those containers are exactly what
/// Material paints selected chips, navigation indicators, and tonal
/// buttons with — which is why the app used to show purple selection
/// states that had nothing to do with the brand. Writing the roles out by
/// hand keeps every accent on the cyan/blue/teal ramp.
///
/// The component themes below also carry most of the shape work. Removing
/// the card border, the chip border, and the text-field outline here fixes
/// the "outlined rounded rectangle everywhere" problem globally instead of
/// widget by widget.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDCEAFE),
      onPrimaryContainer: Color(0xFF08326F),
      // Secondary is the cyan half of the brand, used for supporting
      // accents (audio-mode tinting, informational chips).
      secondary: Color(0xFF0785B0),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFD3F1FA),
      onSecondaryContainer: Color(0xFF0B3F4E),
      // Tertiary is the mint tip of the logo gradient. Deliberately teal,
      // never the lavender a seeded scheme would produce.
      tertiary: Color(0xFF0F766E),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFCDF2EC),
      onTertiaryContainer: Color(0xFF0A3F3A),
      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFDE4E2),
      onErrorContainer: Color(0xFF7A1710),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      surfaceDim: Color(0xFFE6ECF4),
      surfaceBright: Color(0xFFFFFFFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: AppColors.lightContainerLow,
      surfaceContainer: AppColors.lightContainer,
      surfaceContainerHigh: AppColors.lightContainerHigh,
      surfaceContainerHighest: AppColors.lightContainerHighest,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      shadow: Color(0xFF0B1520),
      scrim: Color(0xFF0B1520),
      inverseSurface: Color(0xFF16202D),
      onInverseSurface: Color(0xFFF1F5FA),
      inversePrimary: AppColors.primaryCyan,
    );

    return _buildTheme(colorScheme, FetchyTokens.light);
  }

  static ThemeData get dark {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryCyan,
      onPrimary: Color(0xFF00243B),
      primaryContainer: Color(0xFF15334C),
      onPrimaryContainer: Color(0xFFB6DEFA),
      secondary: Color(0xFF67E8F9),
      onSecondary: Color(0xFF00323F),
      secondaryContainer: Color(0xFF0A4152),
      onSecondaryContainer: Color(0xFFB6F0FB),
      tertiary: Color(0xFF5EEAD4),
      onTertiary: Color(0xFF00332E),
      tertiaryContainer: Color(0xFF0B4B45),
      onTertiaryContainer: Color(0xFFB9F5EA),
      error: AppColors.errorDark,
      onError: Color(0xFF3F0906),
      errorContainer: Color(0xFF5A1512),
      onErrorContainer: Color(0xFFFFD9D6),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      surfaceDim: AppColors.darkContainerLowest,
      surfaceBright: Color(0xFF25344D),
      surfaceContainerLowest: AppColors.darkContainerLowest,
      surfaceContainerLow: AppColors.darkContainerLow,
      surfaceContainer: AppColors.darkContainer,
      surfaceContainerHigh: AppColors.darkContainerHigh,
      surfaceContainerHighest: AppColors.darkContainerHighest,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE8F0FA),
      onInverseSurface: Color(0xFF0B1220),
      inversePrimary: AppColors.primary,
    );

    return _buildTheme(colorScheme, FetchyTokens.dark);
  }

  /// Adapts a built theme to the locale it will actually be rendered in.
  ///
  /// Only typography changes, and only for scripts the Latin scale's tight
  /// tracking would harm — see [AppTypography.withoutTightTracking]. The
  /// colour system, shapes, and every component theme are identical in
  /// every locale.
  ///
  /// Called from `FetchyApp`'s `MaterialApp.builder`, which is the first
  /// point at which the resolved locale is known: it can come from the
  /// user's explicit pick *or* from the device, and the theme itself is
  /// constructed before either is available.
  static ThemeData forLocale(ThemeData base, Locale locale) {
    if (locale.languageCode != 'ar') return base;

    final TextTheme textTheme = AppTypography.withoutTightTracking(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(letterSpacing: 0),
      ),
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, FetchyTokens tokens) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final TextTheme textTheme = AppTypography.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      // Pages paint their own [FetchyPageBackground] wash on top of this,
      // so the scaffold colour only shows through where a page opts out.
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.page,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
      ),

      // Cards are soft surfaces, not outlined rectangles: a tonal fill plus
      // the faintest ambient shadow on light, and a lifted container tone
      // on dark where a shadow would be invisible anyway.
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        shadowColor: tokens.shadow.withValues(alpha: isDark ? 0 : 0.05),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppShape.card),
        color: tokens.surfaceRaised,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(0, 46),
        ),
      ),

      // Outlined buttons survive only as the quiet, secondary partner to a
      // filled one (Cancel next to Save). The outline is a hairline rather
      // than the heavy 1px scheme outline it used to be.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: tokens.hairline),
          shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize: const Size(0, 46),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          minimumSize: const Size(0, 40),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppShape.chip),
        ),
      ),

      // Filled, borderless fields. A resting outline on every input was one
      // of the biggest contributors to the old dated look; the fill alone
      // is enough to say "type here", and a focus ring only appears when it
      // has to.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide.none,
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShape.control,
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // Tonal chips with no border. Selected reads through fill and weight,
      // which is legible at a glance without drawing a box around it.
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceSunken,
        selectedColor: tokens.surfaceSelected,
        disabledColor: colorScheme.surfaceContainerHighest,
        checkmarkColor: tokens.onSurfaceSelected,
        showCheckmark: false,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: tokens.onSurfaceSelected,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll<BorderSide>(BorderSide.none),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.selected)
                ? tokens.surfaceSelected
                : tokens.surfaceSunken;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.selected)
                ? tokens.onSurfaceSelected
                : colorScheme.onSurfaceVariant;
          }),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppShape.control),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
        ),
      ),

      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        thumbColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
          }
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return isDark ? colorScheme.onSurfaceVariant : colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.surfaceContainerHighest;
          }
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xxs)),
        ),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline;
        }),
      ),

      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        minVerticalPadding: AppSpacing.md,
      ),

      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 3,
        shape: const RoundedRectangleBorder(borderRadius: AppShape.dialog),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surfaceRaised,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppShape.sheet),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(40, 4),
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),

      // Material's default snackbar inverts the theme — a white slab on a
      // dark app — which reads as a system toast rather than as part of
      // Fetchy. This one is simply a raised Fetchy surface with the same
      // fill, radius, and text colour as every card, so a message looks
      // like it came from the app it is sitting on, in either theme.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : tokens.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.primary,
        closeIconColor: colorScheme.onSurfaceVariant,
        elevation: isDark ? 0 : 4,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppShape.group),
      ),

      // The updated (non-2023) Material progress indicators: rounded caps,
      // a gap between the active bar and the track, and a stop indicator.
      // The download bar uses Fetchy's own gradient painter, but every
      // incidental spinner and bar in the app picks this up.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        // The flag is deprecated precisely because false will become the
        // default; until it does, this is the only way to opt every
        // incidental spinner and bar in the app into the current
        // appearance rather than the 2023 one.
        // ignore: deprecated_member_use
        year2023: false,
        color: colorScheme.primary,
        linearTrackColor: tokens.progressTrack,
        circularTrackColor: tokens.progressTrack,
        linearMinHeight: 6,
        borderRadius: AppShape.progress,
        stopIndicatorColor: colorScheme.primary.withValues(alpha: 0.35),
        trackGap: 4,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: AppShape.chip,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.primary,
        textColor: colorScheme.onPrimary,
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),

      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppShape.control),
        collapsedShape: const RoundedRectangleBorder(borderRadius: AppShape.control),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        // Brand-tinted, never the lavender secondaryContainer a seeded
        // scheme would have supplied here.
        indicatorColor: tokens.surfaceSelected,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppShape.group),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.onSurfaceSelected, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall!.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }
}

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'appearance.dart';
import 'wallpaper.dart';

const _subThemes = FlexSubThemesData(
  blendOnLevel: 10,
  blendOnColors: false,
  useM2StyleDividerInM3: true,
  alignedDropdown: true,
  useInputDecoratorThemeInDialogs: true,
  fabUseShape: true,
  interactionEffects: true,
  bottomNavigationBarElevation: 0,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorRadius: 14,
  inputDecoratorUnfocusedHasBorder: true,
  inputDecoratorUnfocusedBorderIsColored: false,
  chipRadius: 20,
  cardRadius: AppRadius.card,
  dialogRadius: 22,
  bottomSheetRadius: 28,
  filledButtonRadius: 40,
  elevatedButtonRadius: 40,
  outlinedButtonRadius: 40,
  textButtonRadius: 40,
  segmentedButtonRadius: 40,
  toggleButtonsRadius: 40,
  popupMenuRadius: 14,
  menuRadius: 14,
  tooltipRadius: 8,
  snackBarRadius: 14,
  navigationRailUseIndicator: true,
);

abstract final class AppTheme {
  static ThemeData light([Appearance appearance = const Appearance()]) => _finish(
    FlexThemeData.light(
      colors: appearance.scheme.data.light,
      keyColors: const FlexKeyColors(useKeyColors: true, useSecondary: true, useTertiary: true, keepPrimary: true, keepSecondary: true, keepTertiary: true),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 6,
      subThemesData: _subThemes,
      fontFamily: AppFonts.sans,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
    appearance.wallpaper,
  );

  static ThemeData dark([Appearance appearance = const Appearance()]) => _finish(
    FlexThemeData.dark(
      colors: appearance.scheme.data.dark,
      keyColors: const FlexKeyColors(useKeyColors: true, useSecondary: true, useTertiary: true, keepPrimary: true, keepSecondary: true, keepTertiary: true),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      subThemesData: _subThemes.copyWith(blendOnLevel: 20),
      fontFamily: AppFonts.sans,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
    appearance.wallpaper,
  );

  /// Every page route paints the wallpaper under its content (see [WallpaperPageTransitionsBuilder]).
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.fuchsia: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.iOS: WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.macOS: WallpaperPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.linux: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
      TargetPlatform.windows: WallpaperPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
    },
  );

  static ThemeData _finish(ThemeData base, WallpaperSpec wallpaper) {
    final scheme = base.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textTheme = _typography(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final sheetColor = isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest;
    final selectedTint = Color.alphaBlend(scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14), sheetColor);
    final fieldFill = isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.hairline),
    );

    return base.copyWith(
      colorScheme: scheme,
      // Pages are see-through: the wallpaper under every route shows behind them.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      pageTransitionsTheme: _pageTransitions,
      textTheme: textTheme,
      primaryTextTheme: _typography(base.primaryTextTheme),
      extensions: [colors, WallpaperTheme.of(wallpaper, scheme)],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: colors.hairline),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: fieldFill,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder.copyWith(borderSide: BorderSide(color: colors.hairline.withValues(alpha: 0.5))),
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        helperMaxLines: 3,
        errorMaxLines: 3,
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: sheetColor,
        modalBackgroundColor: sheetColor,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        showDragHandle: true,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceBright,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.hairline),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rowAll),
        selectedTileColor: scheme.primary.withValues(alpha: 0.12),
        selectedColor: scheme.primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: selectedTint,
        secondarySelectedColor: selectedTint,
        checkmarkColor: scheme.primary,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(color: states.contains(WidgetState.selected) ? scheme.primary.withValues(alpha: 0.6) : colors.hairline),
        ),
      ),
      // Tabs read as the floating tab bar's pill: a soft accent capsule, no underline.
      tabBarTheme: base.tabBarTheme.copyWith(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: ShapeDecoration(
          shape: const StadiumBorder(),
          color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        overlayColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.06)),
        splashBorderRadius: BorderRadius.circular(AppRadius.pill),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabAlignment: TabAlignment.start,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? scheme.surfaceContainerHighest : const Color(0xFF1C1E22),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: isDark ? scheme.onSurface : Colors.white),
        actionTextColor: isDark ? scheme.primary : scheme.primaryFixedDim,
        elevation: 0,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(waitDuration: const Duration(milliseconds: 400)),
      // Pill buttons read a touch bolder than body text.
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(color: states.contains(WidgetState.disabled) ? colors.hairline : scheme.outline.withValues(alpha: 0.6)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (base.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      expansionTileTheme: base.expansionTileTheme.copyWith(shape: const Border(), collapsedShape: const Border()),
    );
  }

  /// Fraunces for display, headline and large titles; Figtree (the theme's font) for the rest,
  /// with slightly tighter tracking on large sizes.
  static TextTheme _typography(TextTheme theme) {
    TextStyle? serif(TextStyle? style, double spacing) => style?.copyWith(fontFamily: AppFonts.serif, fontWeight: FontWeight.w600, letterSpacing: spacing);
    TextStyle? sans(TextStyle? style, double spacing, [FontWeight? weight]) =>
        style?.copyWith(fontFamily: AppFonts.sans, letterSpacing: spacing, fontWeight: weight ?? style.fontWeight);
    return theme.copyWith(
      displayLarge: serif(theme.displayLarge, -1.2),
      displayMedium: serif(theme.displayMedium, -0.9),
      displaySmall: serif(theme.displaySmall, -0.6),
      headlineLarge: serif(theme.headlineLarge, -0.6),
      headlineMedium: serif(theme.headlineMedium, -0.5),
      headlineSmall: serif(theme.headlineSmall, -0.4),
      titleLarge: serif(theme.titleLarge, -0.3),
      titleMedium: sans(theme.titleMedium, -0.1, FontWeight.w600),
      titleSmall: sans(theme.titleSmall, 0, FontWeight.w600),
      bodyLarge: sans(theme.bodyLarge, -0.1),
      bodyMedium: sans(theme.bodyMedium, 0),
      bodySmall: sans(theme.bodySmall, 0.1),
      labelLarge: sans(theme.labelLarge, 0, FontWeight.w600),
      labelMedium: sans(theme.labelMedium, 0.1, FontWeight.w500),
      labelSmall: sans(theme.labelSmall, 0.2, FontWeight.w500),
    );
  }
}

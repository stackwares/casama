import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Accent choices in Settings → Appearance. The accent colors controls and selection only; pages
/// and cards stay neutral whatever is picked.
enum AppAccent {
  kasama('Kasama', Color(0xFF0F766E)),
  indigo('Indigo', Color(0xFF4F46E5)),
  blue('Blue', Color(0xFF2563EB)),
  green('Green', Color(0xFF15803D)),
  orange('Orange', Color(0xFFEA580C)),
  rose('Rose', Color(0xFFE11D48)),
  purple('Purple', Color(0xFF7C3AED));

  const AppAccent(this.label, this.seed);
  final String label;
  final Color seed;
}

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
  static ThemeData light([AppAccent accent = AppAccent.kasama]) => _finish(
        FlexThemeData.light(
          colors: FlexSchemeColor.from(primary: accent.seed, brightness: Brightness.light),
          keyColors: const FlexKeyColors(useKeyColors: true, keepPrimary: true),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 7,
          subThemesData: _subThemes,
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
        ),
      );

  static ThemeData dark([AppAccent accent = AppAccent.kasama]) => _finish(
        FlexThemeData.dark(
          colors: FlexSchemeColor.from(primary: accent.seed, brightness: Brightness.dark),
          keyColors: const FlexKeyColors(useKeyColors: true),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 13,
          subThemesData: _subThemes.copyWith(blendOnLevel: 20),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          useMaterial3: true,
        ),
      );

  /// Neutral surfaces whatever the accent: it colors controls and selection, never the page.
  static ColorScheme _neutralSurfaces(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return scheme.copyWith(
        surface: const Color(0xFF0D0E10),
        surfaceDim: const Color(0xFF0D0E10),
        surfaceBright: const Color(0xFF2A2D33),
        surfaceContainerLowest: const Color(0xFF0A0B0C),
        surfaceContainerLow: const Color(0xFF16171A),
        surfaceContainer: const Color(0xFF1C1E22),
        surfaceContainerHigh: const Color(0xFF23252A),
        surfaceContainerHighest: const Color(0xFF2A2D33),
        onSurface: const Color(0xFFEEF0F3),
        onSurfaceVariant: const Color(0xFF9095A0),
        outline: const Color(0xFF4A4E57),
        outlineVariant: const Color(0xFF25272B),
        surfaceTint: Colors.transparent,
      );
    }
    return scheme.copyWith(
      surface: const Color(0xFFF4F5F7),
      surfaceDim: const Color(0xFFE6E8EB),
      surfaceBright: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFEEF0F3),
      surfaceContainerHigh: const Color(0xFFE8EAEE),
      surfaceContainerHighest: const Color(0xFFE1E4E8),
      onSurface: const Color(0xFF111317),
      onSurfaceVariant: const Color(0xFF5F6570),
      outline: const Color(0xFFA0A5AE),
      outlineVariant: const Color(0xFFE3E5E8),
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _finish(ThemeData base) {
    final scheme = _neutralSurfaces(base.colorScheme);
    final isDark = scheme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textTheme = _nunitoHeadlines(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final sheetColor = isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest;
    final selectedTint = Color.alphaBlend(scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14), sheetColor);
    final fieldFill = isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final fieldBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.hairline));

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: _nunitoHeadlines(base.primaryTextTheme),
      extensions: [colors],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll, side: BorderSide(color: colors.hairline)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: colors.hairline)),
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
        indicator: ShapeDecoration(shape: const StadiumBorder(), color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.12)),
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
      expansionTileTheme: base.expansionTileTheme.copyWith(
        shape: const Border(),
        collapsedShape: const Border(),
      ),
    );
  }

  /// Display, headline and title styles use Nunito; body and labels keep the platform font, with
  /// the tighter tracking San Francisco and Segoe want (Material's is tuned for Roboto).
  static TextTheme _nunitoHeadlines(TextTheme theme) {
    TextStyle? nunito(TextStyle? style) => style?.copyWith(fontFamily: 'Nunito');
    TextStyle? track(TextStyle? style, double spacing) => style?.copyWith(letterSpacing: spacing);
    return theme.copyWith(
      bodyLarge: track(theme.bodyLarge, -0.1),
      bodyMedium: track(theme.bodyMedium, 0),
      bodySmall: track(theme.bodySmall, 0.1),
      labelLarge: track(theme.labelLarge, 0),
      labelMedium: track(theme.labelMedium, 0.1),
      labelSmall: track(theme.labelSmall, 0.2),
      displayLarge: nunito(theme.displayLarge),
      displayMedium: nunito(theme.displayMedium),
      displaySmall: nunito(theme.displaySmall),
      headlineLarge: nunito(theme.headlineLarge),
      headlineMedium: nunito(theme.headlineMedium),
      headlineSmall: nunito(theme.headlineSmall),
      titleLarge: nunito(theme.titleLarge),
      titleMedium: nunito(theme.titleMedium),
    );
  }
}

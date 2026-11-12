import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'appearance.dart';
import 'fonts.dart';
import 'page_transitions.dart';
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
  // A theme takes milliseconds to build, and a rebuilt theme is a new object: handed to
  // MaterialApp it counts as a change, which animates the theme and rebuilds every widget that
  // reads it. The same appearance gives back the same theme.
  static final _built = <(Brightness, TargetPlatform, String, String, String, WallpaperSpec), ThemeData>{};

  static ThemeData _cached(Brightness brightness, Appearance a, ThemeData Function() build) {
    final key = (brightness, defaultTargetPlatform, a.schemeId, a.headingFont, a.bodyFont, a.wallpaper);
    final hit = _built[key];
    if (hit != null) return hit;
    if (_built.length >= 8) _built.clear();
    return _built[key] = build();
  }

  static ThemeData light([Appearance appearance = const Appearance()]) => _cached(Brightness.light, appearance, () => _light(appearance));

  static ThemeData dark([Appearance appearance = const Appearance()]) => _cached(Brightness.dark, appearance, () => _dark(appearance));

  static ThemeData _light(Appearance appearance) => _finish(
    FlexThemeData.light(
      colors: appearance.scheme.data.light,
      keyColors: const FlexKeyColors(useKeyColors: true, useSecondary: true, useTertiary: true, keepPrimary: true, keepSecondary: true, keepTertiary: true),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 6,
      subThemesData: _subThemes,
      fontFamily: bundledFonts.contains(appearance.bodyFont) ? appearance.bodyFont : null,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
    appearance,
  );

  static ThemeData _dark(Appearance appearance) => _finish(
    FlexThemeData.dark(
      colors: appearance.scheme.data.dark,
      keyColors: const FlexKeyColors(useKeyColors: true, useSecondary: true, useTertiary: true, keepPrimary: true, keepSecondary: true, keepTertiary: true),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      subThemesData: _subThemes.copyWith(blendOnLevel: 20),
      fontFamily: bundledFonts.contains(appearance.bodyFont) ? appearance.bodyFont : null,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
    appearance,
  );

  /// Pages are see-through over the one wallpaper the app paints behind every navigator. Android
  /// pages fade through each other along a shared axis, so two pages never show at once; iOS keeps
  /// its slide and swipe back, with each page painting the wallpaper so it covers the one under it.
  /// The web and desktop are click and open, so pages there switch with no transition, as do phones
  /// in a browser.
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: kIsWeb ? InstantPageTransitionsBuilder() : SharedAxisPageTransitionsBuilder(),
      TargetPlatform.iOS: kIsWeb ? InstantPageTransitionsBuilder() : OpaquePageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      TargetPlatform.macOS: InstantPageTransitionsBuilder(),
      TargetPlatform.windows: InstantPageTransitionsBuilder(),
      TargetPlatform.linux: InstantPageTransitionsBuilder(),
      TargetPlatform.fuchsia: InstantPageTransitionsBuilder(),
    },
  );

  static ThemeData _finish(ThemeData base, Appearance appearance) {
    final wallpaper = appearance.wallpaper;
    TextTheme typography(TextTheme t) => _typography(t, heading: appearance.headingFont, body: appearance.bodyFont);
    final scheme = base.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textTheme = typography(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final sheetColor = isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest;
    final selectedTint = Color.alphaBlend(scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14), sheetColor);
    // Text fields read as places to type on any surface: a fill a step lighter than sheets and
    // dialogs in dark mode, and a visible outline (the page hairline vanishes on dark sheets).
    final fieldFill = isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLowest;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      colorScheme: scheme,
      // Pages are see-through: the wallpaper under every route shows behind them.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      pageTransitionsTheme: _pageTransitions,
      textTheme: textTheme,
      primaryTextTheme: typography(base.primaryTextTheme),
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
      // Text selection in the accent: a 30% highlight behind selected text (text over it stays
      // readable in light and dark, whatever the scheme), the full accent for the cursor and handles.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: scheme.primary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: fieldFill,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
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
      // Dialogs lift off the page: a real shadow (Material's default barely shows over a dark
      // wallpaper), a hairline edge, and a firmer dim behind them.
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.7 : 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: colors.hairline)),
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.32),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
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

  /// The heading font (Noto Serif by default) for display, headline and large titles; the body
  /// font (Google Sans by default) for the rest, with slightly tighter tracking on large sizes.
  /// Even leading keeps text optically centered in fields and buttons whatever the font's metrics.
  static TextTheme _typography(TextTheme theme, {required String heading, required String body}) {
    TextStyle? serif(TextStyle? style, double spacing) => style == null
        ? null
        : fontStyle(heading, style.copyWith(fontWeight: FontWeight.w600, letterSpacing: spacing, leadingDistribution: TextLeadingDistribution.even));
    TextStyle? sans(TextStyle? style, double spacing, [FontWeight? weight]) => style == null
        ? null
        : fontStyle(
            body,
            style.copyWith(letterSpacing: spacing, fontWeight: weight ?? style.fontWeight, leadingDistribution: TextLeadingDistribution.even),
          );
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

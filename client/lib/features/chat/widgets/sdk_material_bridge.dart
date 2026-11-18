// The basic A2UI catalog is still built on Flutter's own material library, which looks up its own
// Material and Theme. The app runs on material_ui (D-212), so those lookups find nothing: the
// radio and checkbox lists, text fields, sliders and tabs crash with "Null check operator used on
// a null value" in Material.of. This gives them an SDK Material and an SDK Theme with Casama's
// colours and type.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as sdk;
import 'package:material_ui/material_ui.dart';

class SdkMaterialBridge extends StatelessWidget {
  const SdkMaterialBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return sdk.Theme(
      data: sdk.ThemeData(
        colorScheme: _scheme(theme.colorScheme),
        textTheme: _text(theme.textTheme),
        materialTapTargetSize: sdk.MaterialTapTargetSize.shrinkWrap,
        splashFactory: sdk.InkSparkle.splashFactory,
        // Fields in a bot's form: filled, rounded, no outline (D-256), like the app's own cards.
        inputDecorationTheme: sdk.InputDecorationTheme(
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: sdk.OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: sdk.OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: sdk.OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          ),
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      child: sdk.Material(type: sdk.MaterialType.transparency, child: child),
    );
  }

  static sdk.ColorScheme _scheme(ColorScheme s) => sdk.ColorScheme(
    brightness: s.brightness,
    primary: s.primary,
    onPrimary: s.onPrimary,
    primaryContainer: s.primaryContainer,
    onPrimaryContainer: s.onPrimaryContainer,
    secondary: s.secondary,
    onSecondary: s.onSecondary,
    secondaryContainer: s.secondaryContainer,
    onSecondaryContainer: s.onSecondaryContainer,
    tertiary: s.tertiary,
    onTertiary: s.onTertiary,
    tertiaryContainer: s.tertiaryContainer,
    onTertiaryContainer: s.onTertiaryContainer,
    error: s.error,
    onError: s.onError,
    errorContainer: s.errorContainer,
    onErrorContainer: s.onErrorContainer,
    surface: s.surface,
    onSurface: s.onSurface,
    onSurfaceVariant: s.onSurfaceVariant,
    surfaceDim: s.surfaceDim,
    surfaceBright: s.surfaceBright,
    surfaceContainerLowest: s.surfaceContainerLowest,
    surfaceContainerLow: s.surfaceContainerLow,
    surfaceContainer: s.surfaceContainer,
    surfaceContainerHigh: s.surfaceContainerHigh,
    surfaceContainerHighest: s.surfaceContainerHighest,
    outline: s.outline,
    outlineVariant: s.outlineVariant,
    shadow: s.shadow,
    scrim: s.scrim,
    inverseSurface: s.inverseSurface,
    onInverseSurface: s.onInverseSurface,
    inversePrimary: s.inversePrimary,
    surfaceTint: s.surfaceTint,
  );

  static sdk.TextTheme _text(TextTheme t) => sdk.TextTheme(
    displayLarge: t.displayLarge,
    displayMedium: t.displayMedium,
    displaySmall: t.displaySmall,
    headlineLarge: t.headlineLarge,
    headlineMedium: t.headlineMedium,
    headlineSmall: t.headlineSmall,
    titleLarge: t.titleLarge,
    titleMedium: t.titleMedium,
    titleSmall: t.titleSmall,
    bodyLarge: t.bodyLarge,
    bodyMedium: t.bodyMedium,
    bodySmall: t.bodySmall,
    labelLarge: t.labelLarge,
    labelMedium: t.labelMedium,
    labelSmall: t.labelSmall,
  );
}

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'looks.g.dart';

/// Casama's brand scheme is data: `client/looks/schemes/casama.json`, generated into `looks.g.dart`.
export 'looks.g.dart' show casamaScheme;

/// Color families for filtering the theme picker, worked out from each scheme's primary color.
enum SchemeFamily { brand, purple, blue, teal, green, warm, red, neutral }

/// One color scheme the person can pick: Casama's own, or one of FlexColorScheme's built-ins.
class ThemeChoice {
  const ThemeChoice({
    required this.id,
    required this.data,
    required this.family,
  });

  /// Stored in preferences: `casama` or a [FlexScheme] name.
  final String id;
  final FlexSchemeData data;
  final SchemeFamily family;

  String get name => data.name;
  String get description => data.description;
  FlexSchemeColor colors(Brightness b) =>
      b == Brightness.dark ? data.dark : data.light;
}

SchemeFamily _familyOf(Color c) {
  final hsl = HSLColor.fromColor(c);
  if (hsl.saturation < 0.2) return SchemeFamily.neutral;
  final h = hsl.hue;
  if (h < 18 || h >= 340) return SchemeFamily.red;
  if (h < 70) return SchemeFamily.warm;
  if (h < 160) return SchemeFamily.green;
  if (h < 200) return SchemeFamily.teal;
  if (h < 255) return SchemeFamily.blue;
  return SchemeFamily.purple;
}

/// Gallery schemes saved on this device, keyed by `gallery:<id>`.
final gallerySchemeChoices = <String, ThemeChoice>{};

Color colorFromHex(String hex) {
  final n = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | n);
}

String hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// A scheme built from the gallery's light and dark seeds.
ThemeChoice galleryChoiceFromSeeds({
  required String id,
  required String name,
  required String light,
  required String dark,
}) {
  final lightColor = colorFromHex(light);
  return ThemeChoice(
    id: id,
    family: _familyOf(lightColor),
    data: FlexSchemeData(
      name: name,
      description: 'From the gallery',
      light: FlexSchemeColor.from(
        primary: lightColor,
        brightness: Brightness.light,
      ),
      dark: FlexSchemeColor.from(
        primary: colorFromHex(dark),
        brightness: Brightness.dark,
      ),
    ),
  );
}

/// The six colors a full scheme gives for each of light and dark (gallery README, "Full color
/// schemes"), plus an optional `appBar`.
const schemeColorKeys = [
  'primary',
  'primaryContainer',
  'secondary',
  'secondaryContainer',
  'tertiary',
  'tertiaryContainer',
];

final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// One mode's exact colors, or null unless all six (and `appBar`, when given) are #RRGGBB.
FlexSchemeColor? schemeColorsFromJson(Object? raw, Brightness brightness) {
  if (raw is! Map) return null;
  Color? read(String key) {
    final v = raw[key];
    return v is String && _hex.hasMatch(v) ? colorFromHex(v) : null;
  }

  final c = [for (final k in schemeColorKeys) read(k)];
  if (c.any((x) => x == null)) return null;
  final appBar = read('appBar');
  if (raw['appBar'] != null && appBar == null) return null;
  return FlexSchemeColor(
    primary: c[0]!,
    primaryContainer: c[1]!,
    secondary: c[2]!,
    secondaryContainer: c[3]!,
    tertiary: c[4]!,
    tertiaryContainer: c[5]!,
    appBarColor: appBar ?? c[1],
    error: brightness == Brightness.light
        ? const Color(0xFFBA1A1A)
        : const Color(0xFFFFB4AB),
  );
}

/// [colors] in the format [schemeColorsFromJson] reads.
Map<String, String> schemeColorsToJson(FlexSchemeColor colors) => {
  'primary': hexFromColor(colors.primary),
  'primaryContainer': hexFromColor(colors.primaryContainer),
  'secondary': hexFromColor(colors.secondary),
  'secondaryContainer': hexFromColor(colors.secondaryContainer),
  'tertiary': hexFromColor(colors.tertiary),
  'tertiaryContainer': hexFromColor(colors.tertiaryContainer),
  'appBar': hexFromColor(colors.appBarColor ?? colors.primaryContainer),
};

/// A scheme with the exact colors a gallery item gives, or null when they're incomplete.
ThemeChoice? galleryChoiceFromColors({
  required String id,
  required String name,
  required Object? light,
  required Object? dark,
}) {
  final l = schemeColorsFromJson(light, Brightness.light);
  final d = schemeColorsFromJson(dark, Brightness.dark);
  if (l == null || d == null) return null;
  return ThemeChoice(
    id: id,
    family: _familyOf(l.primary),
    data: FlexSchemeData(
      name: name,
      description: 'From the gallery',
      light: l,
      dark: d,
    ),
  );
}

/// Every scheme in the picker, Casama first.
final List<ThemeChoice> themeChoices = [
  const ThemeChoice(
    id: 'casama',
    data: casamaScheme,
    family: SchemeFamily.brand,
  ),
  for (final s in FlexScheme.values)
    if (s != FlexScheme.custom && FlexColor.schemes[s] != null)
      ThemeChoice(
        id: s.name,
        data: FlexColor.schemes[s]!,
        family: _familyOf(FlexColor.schemes[s]!.light.primary),
      ),
];

ThemeChoice themeChoiceById(String id) =>
    gallerySchemeChoices[id] ??
    themeChoices.firstWhere(
      (c) => c.id == id,
      orElse: () => themeChoices.first,
    );

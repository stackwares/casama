import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Color families for filtering the theme picker, worked out from each scheme's primary color.
enum SchemeFamily { brand, purple, blue, teal, green, warm, red, neutral }

/// One color scheme the person can pick: Kasama's own, or one of FlexColorScheme's built-ins.
class ThemeChoice {
  const ThemeChoice({required this.id, required this.data, required this.family});

  /// Stored in preferences: `kasama` or a [FlexScheme] name.
  final String id;
  final FlexSchemeData data;
  final SchemeFamily family;

  String get name => data.name;
  String get description => data.description;
  FlexSchemeColor colors(Brightness b) => b == Brightness.dark ? data.dark : data.light;
}

/// Kasama's brand scheme, from the app icon: plum and lilac for the cloud, the orb's sky blue and
/// cyan as secondary and tertiary.
const kasamaScheme = FlexSchemeData(
  name: 'Kasama',
  description: 'Plum, lilac and sky, from the Kasama cloud.',
  light: FlexSchemeColor(
    primary: Color(0xFF7A3FA8),
    primaryContainer: Color(0xFFF1E2FC),
    secondary: Color(0xFF3B78DB),
    secondaryContainer: Color(0xFFDCE8FF),
    tertiary: Color(0xFF0E8F9A),
    tertiaryContainer: Color(0xFFCCF6F4),
    appBarColor: Color(0xFFF1E2FC),
    error: Color(0xFFBA1A1A),
  ),
  dark: FlexSchemeColor(
    primary: Color(0xFFD9B6F7),
    primaryContainer: Color(0xFF5A1F6E),
    secondary: Color(0xFF9DC3FF),
    secondaryContainer: Color(0xFF1F3F73),
    tertiary: Color(0xFF7FEAE4),
    tertiaryContainer: Color(0xFF0B4B50),
    appBarColor: Color(0xFF2A1035),
    error: Color(0xFFFFB4AB),
  ),
);

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

/// Every scheme in the picker, Kasama first.
final List<ThemeChoice> themeChoices = [
  const ThemeChoice(id: 'kasama', data: kasamaScheme, family: SchemeFamily.brand),
  for (final s in FlexScheme.values)
    if (s != FlexScheme.custom && FlexColor.schemes[s] != null)
      ThemeChoice(id: s.name, data: FlexColor.schemes[s]!, family: _familyOf(FlexColor.schemes[s]!.light.primary)),
];

ThemeChoice themeChoiceById(String id) => themeChoices.firstWhere((c) => c.id == id, orElse: () => themeChoices.first);

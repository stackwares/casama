import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casama/theme/appearance.dart';
import 'package:casama/theme/presets.dart';
import 'package:casama/theme/schemes.dart';
import 'package:casama/theme/wallpaper.dart';
import 'package:casama/ui/effects.dart';

ThemePreset preset(String id) => builtInPresets.firstWhere((p) => p.id == id);

const _ocean = ThemePreset(
  id: 'ocean',
  name: 'Ocean',
  schemeId: 'blueWhale',
  wallpaper: WallpaperSpec(pattern: WallpaperPattern.sea, palette: WallpaperPalette.ocean),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Plain comes first: flat, no pattern, fewer effects', () {
    final p = builtInPresets.first;
    expect(p.id, 'plain');
    expect(p.wallpaper.pattern, WallpaperPattern.none);
    expect(p.wallpaper.palette, WallpaperPalette.flat);
    expect(p.fewerEffects, isTrue);
    expect(builtInPresets.where((p) => p.fewerEffects), hasLength(1));
  });

  test('Plain is the only built-in theme, in casama.ai\'s colors on plain surfaces (D-380)', () {
    expect(builtInPresets, hasLength(1));
    final plain = themeChoiceById(builtInPresets.single.schemeId);
    expect(plain.id, 'plain');
    expect(plain.neutralSurfaces, isTrue);
    expect(plain.data.light.primary, const Color(0xFF7A3FA8));
    expect(plain.data.dark.primary, const Color(0xFFD9B6F7));
    // Unknown schemes fall back to Plain.
    expect(themeChoiceById('nope').id, 'plain');
    final light = withNeutralSurfaces(ColorScheme.fromSeed(seedColor: const Color(0xFF7A3FA8)));
    expect(light.surface, const Color(0xFFFFFFFF));
    expect(light.surfaceContainerLow, const Color(0xFFF7F7F9));
    final dark = withNeutralSurfaces(
      ColorScheme.fromSeed(seedColor: const Color(0xFF7A3FA8), brightness: Brightness.dark),
    );
    expect(dark.surface, const Color(0xFF1C1C1E));
    expect(dark.surfaceContainerLow, const Color(0xFF242427));
  });

  test('a look saved as the old Plain reads as Plain; Shad Neutral picked on purpose stays', () async {
    final oldPlain = {
      'appearance.scheme': 'shadNeutral',
      'appearance.font.heading': 'Google Sans',
      'appearance.font.body': 'Google Sans',
      'appearance.wallpaper': jsonEncode(defaultWallpaper.toJson()),
    };
    SharedPreferences.setMockInitialValues(oldPlain);
    final a = (await AppearanceNotifier.readSaved())!;
    expect(a.schemeId, 'plain');
    expect(preset('plain').matches(a), isTrue);

    SharedPreferences.setMockInitialValues({...oldPlain, 'appearance.font.heading': 'Fraunces'});
    expect((await AppearanceNotifier.readSaved())!.schemeId, 'shadNeutral');
  });

  test('Plain keeps light or dark as it is, turns on fewer effects, survives a restart, and a colorful theme brings effects back', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    // Let the saved look finish loading first, as it does before the app's first frame.
    c.read(appearanceProvider);
    await pumpEventQueue();
    final notifier = c.read(appearanceProvider.notifier);
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      await notifier.setMode(mode);
      await notifier.applyPreset(preset('plain'));
      final a = c.read(appearanceProvider);
      expect(a.mode, mode);
      expect(a.fewerEffects, isTrue);
      expect(preset('plain').matches(a), isTrue);
    }

    final saved = await AppearanceNotifier.readSaved();
    expect(saved!.fewerEffects, isTrue);
    expect(saved.wallpaper.palette, WallpaperPalette.flat);

    await notifier.applyPreset(_ocean);
    expect(c.read(appearanceProvider).fewerEffects, isFalse);
  });

  test('a shared Plain theme carries fewer effects', () {
    final back = ThemePreset.fromCode(preset('plain').toCode())!;
    expect(back.fewerEffects, isTrue);
    expect(back.wallpaper.palette, WallpaperPalette.flat);
    // Codes without it still read.
    expect(
      ThemePreset.fromCode(_ocean.toCode())!.fewerEffects,
      isFalse,
    );
  });

  testWidgets('decorative motion is off with fewer effects or reduced motion', (
    tester,
  ) async {
    late bool fewer, reduced, normal;
    Widget probe(void Function(bool) out) => Builder(
      builder: (c) {
        out(Effects.decorative(c));
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      Effects(fewer: true, child: probe((v) => fewer = v)),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Effects(fewer: false, child: probe((v) => reduced = v)),
      ),
    );
    await tester.pumpWidget(
      Effects(fewer: false, child: probe((v) => normal = v)),
    );
    expect((fewer, reduced, normal), (false, false, true));
  });
}

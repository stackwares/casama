import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/presets.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:casama_app/ui/effects.dart';

ThemePreset preset(String id) => builtInPresets.firstWhere((p) => p.id == id);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the Plain themes come first: flat, no pattern, fewer effects, each with its own light or dark', () {
    expect(builtInPresets.take(3).map((p) => p.id), [
      'plain',
      'plainLight',
      'plainDark',
    ]);
    for (final p in builtInPresets.take(3)) {
      expect(p.wallpaper.pattern, WallpaperPattern.none);
      expect(p.wallpaper.palette, WallpaperPalette.flat);
      expect(p.fewerEffects, isTrue);
    }
    expect(preset('plain').mode, ThemeMode.system);
    expect(preset('plainLight').mode, ThemeMode.light);
    expect(preset('plainDark').mode, ThemeMode.dark);
  });

  test('Plain Dark switches to dark with fewer effects, survives a restart, and a colorful theme brings effects back', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    // Let the saved look finish loading first, as it does before the app's first frame.
    c.read(appearanceProvider);
    await pumpEventQueue();
    await c.read(appearanceProvider.notifier).applyPreset(preset('plainDark'));
    var a = c.read(appearanceProvider);
    expect(a.mode, ThemeMode.dark);
    expect(a.fewerEffects, isTrue);
    expect(preset('plainDark').matches(a), isTrue);
    expect(preset('plainLight').matches(a), isFalse);
    expect(preset('plain').matches(a), isFalse);

    final saved = await AppearanceNotifier.readSaved();
    expect(saved!.mode, ThemeMode.dark);
    expect(saved.fewerEffects, isTrue);
    expect(saved.wallpaper.palette, WallpaperPalette.flat);

    // Colorful themes keep the current light/dark and turn the effects back on.
    await c.read(appearanceProvider.notifier).applyPreset(preset('ocean'));
    a = c.read(appearanceProvider);
    expect(a.mode, ThemeMode.dark);
    expect(a.fewerEffects, isFalse);
  });

  test('a shared Plain theme carries its light/dark and fewer effects', () {
    final back = ThemePreset.fromCode(preset('plainLight').toCode())!;
    expect(back.mode, ThemeMode.light);
    expect(back.fewerEffects, isTrue);
    expect(back.wallpaper.palette, WallpaperPalette.flat);
    // Older codes without them still read.
    final old = ThemePreset.fromCode(preset('ocean').toCode())!;
    expect(old.mode, isNull);
    expect(old.fewerEffects, isFalse);
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

import 'package:casama/theme/appearance.dart';
import 'package:casama/theme/suggested_look.dart';
import 'package:casama/theme/wallpaper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> start() async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(appearanceProvider);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  test('applies a suggested gallery theme, mode and fonts, and Undo puts the old look back', () async {
    final c = await start();
    final n = c.read(appearanceProvider.notifier);
    final before = c.read(appearanceProvider);
    // Themes other than Plain come from the gallery (D-380); the app looks them up by id.
    final asked = <String>[];
    final saved = await applySuggestedLook(
      before,
      n,
      {'preset': 'ocean', 'mode': 'dark', 'body_font': 'Figtree'},
      galleryTheme: (id) async {
        asked.add(id);
        await n.apply(schemeId: 'blueWhale', headingFont: 'Lato', bodyFont: 'Lato', wallpaper: const WallpaperSpec(), fewerEffects: false);
        return true;
      },
    );
    expect(asked, ['ocean']);
    expect(saved, same(before));
    final now = c.read(appearanceProvider);
    expect(now.schemeId, 'blueWhale');
    expect(now.mode, ThemeMode.dark);
    expect(now.bodyFont, 'Figtree');
    await restoreLook(n, saved!);
    expect(c.read(appearanceProvider).schemeId, before.schemeId);
    expect(c.read(appearanceProvider).mode, before.mode);
    expect(c.read(appearanceProvider).bodyFont, before.bodyFont);
  });

  test("drops what the app doesn't have", () async {
    final c = await start();
    final n = c.read(appearanceProvider.notifier);
    final before = c.read(appearanceProvider);
    expect(
      await applySuggestedLook(
        before,
        n,
        {'preset': 'neon', 'scheme': 'nope', 'heading_font': 'Comic Sans'},
        galleryTheme: (_) async => false,
      ),
      isNull,
    );
    expect(c.read(appearanceProvider).schemeId, before.schemeId);
    expect(c.read(appearanceProvider).headingFont, before.headingFont);
  });
}

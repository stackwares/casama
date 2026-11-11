import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/settings/appearance_screen.dart';
import 'package:casama_app/features/settings/customize_screen.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/presets.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _seeds = {
  'light': {
    'seed': '#0E6E78',
    'background': '#F4FBFC',
    'onBackground': '#102226',
  },
  'dark': {
    'seed': '#8FE8E2',
    'background': '#0C2428',
    'onBackground': '#E7F6F5',
  },
};

// Bundled fonts, so previews don't try to download a Google Font in tests.
const _lagoon = GalleryItem(
  id: 'lagoon',
  type: 'theme',
  name: 'Lagoon',
  authorName: 'Ana Reyes',
  license: 'CC0-1.0',
  featured: true,
  document: {
    'v': 2,
    'scheme': _seeds,
    'headingFont': 'Fraunces',
    'bodyFont': 'Figtree',
    'wallpaper': {'pattern': 'sea', 'palette': 'ocean', 'intensity': 0.5},
  },
);

const _reef = GalleryItem(
  id: 'reef',
  type: 'scheme',
  name: 'Reef',
  authorName: 'Casama',
  license: 'CC0-1.0',
  document: _seeds,
);

const _tide = GalleryItem(
  id: 'tide',
  type: 'wallpaper',
  name: 'Tide',
  authorName: 'Casama',
  license: 'CC0-1.0',
  document: {
    'kind': 'pattern',
    'pattern': 'sea',
    'palette': 'ocean',
    'intensity': 0.6,
  },
);

FakeBackend _backend() => FakeBackend()..galleryItems = [_lagoon, _reef, _tide];

ProviderContainer _container(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'gallery themes sit with the others; one tap uses one, and using it again keeps one copy',
    (tester) async {
      await setSize(tester, const Size(430, 2200));
      await tester.pumpWidget(harness(_backend(), const AppearanceScreen()));
      await tester.pumpAndSettle();
      final c = _container(tester, AppearanceScreen);

      expect(find.textContaining('From the gallery'), findsOneWidget);
      // Only themes here: colors and wallpapers belong to Customize.
      expect(find.byKey(const Key('gallery-theme-lagoon')), findsOneWidget);
      expect(find.text('Reef'), findsNothing);
      expect(find.text('By Ana Reyes'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('gallery-theme-lagoon')));
      await tester.tap(find.byKey(const Key('gallery-theme-lagoon')));
      await tester.pumpAndSettle();
      final a = c.read(appearanceProvider);
      expect(a.headingFont, 'Fraunces');
      expect(a.schemeId, 'gallery:theme-lagoon');
      expect(a.wallpaper.pattern, WallpaperPattern.sea);
      expect(find.byKey(const Key('currentLookName')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('currentLookName'))).data,
        'Lagoon',
      );

      // Kept for offline use, but shown once: its gallery card, not a second copy under Themes.
      await tester.tap(find.byKey(const Key('gallery-theme-lagoon')));
      await tester.pumpAndSettle();
      expect(
        c.read(savedThemesProvider).where((p) => p.id == 'gallery-lagoon'),
        hasLength(1),
      );
      expect(find.byKey(const Key('preset-gallery-lagoon')), findsNothing);
    },
  );

  testWidgets(
    'trying a theme after changing the look offers Undo, which brings it back',
    (tester) async {
      await setSize(tester, const Size(430, 2200));
      await tester.pumpWidget(harness(FakeBackend(), const AppearanceScreen()));
      await tester.pumpAndSettle();
      final c = _container(tester, AppearanceScreen);
      final notifier = c.read(appearanceProvider.notifier);

      // From a theme to a theme: nothing to lose, so no Undo.
      await tester.ensureVisible(find.byKey(const Key('preset-ocean')));
      await tester.tap(find.byKey(const Key('preset-ocean')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('undoTheme')), findsNothing);

      // A look of one's own: Custom look, with Save.
      await notifier.setFonts(heading: 'Lora');
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('currentLookName'))).data,
        'Custom look',
      );
      expect(find.byKey(const Key('saveTheme')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('preset-forest')));
      await tester.tap(find.byKey(const Key('preset-forest')));
      await tester.pumpAndSettle();
      expect(c.read(appearanceProvider).schemeId, 'jungle');
      expect(find.text('Switched to Forest'), findsOneWidget);
      await tester.tap(find.byKey(const Key('undoTheme')));
      await tester.pumpAndSettle();
      final back = c.read(appearanceProvider);
      expect(back.headingFont, 'Lora');
      expect(back.schemeId, 'blueWhale');
    },
  );

  test('a theme stays in use when "Show in the whole app" changes, and themes keep that switch', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(appearanceProvider);
    await pumpEventQueue();
    final notifier = c.read(appearanceProvider.notifier);
    final ocean = builtInPresets.firstWhere((p) => p.id == 'ocean');
    await notifier.applyPreset(ocean);
    await notifier.setWallpaper(
      c.read(appearanceProvider).wallpaper.copyWith(everywhere: false),
    );
    expect(ocean.matches(c.read(appearanceProvider)), isTrue);
    expect(currentTheme(c.read(appearanceProvider), const [])?.id, 'ocean');
    // Another theme doesn't turn it back on.
    await notifier.applyPreset(
      builtInPresets.firstWhere((p) => p.id == 'forest'),
    );
    expect(c.read(appearanceProvider).wallpaper.everywhere, isFalse);
  });

  testWidgets(
    'Customize: colors, background and fonts under one preview, with the gallery mixed in',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      await tester.pumpWidget(harness(_backend(), const CustomizeScreen()));
      await tester.pumpAndSettle();
      final c = _container(tester, CustomizeScreen);
      expect(find.byKey(const Key('customizePreview')), findsOneWidget);
      // The look is a theme, so there's nothing to save yet.
      expect(find.byKey(const Key('saveTheme')), findsNothing);

      // The gallery's schemes have a chip of their own and apply like any other.
      await tester.tap(find.byKey(const Key('family-gallery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scheme-gallery:reef')));
      await tester.pumpAndSettle();
      expect(c.read(appearanceProvider).schemeId, 'gallery:reef');
      // Changed from the theme: Save shows in the header.
      expect(find.byKey(const Key('saveTheme')), findsOneWidget);

      // Background: ready-made wallpapers from the gallery come first.
      await tester.tap(find.text('Background'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pattern-doodles')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gallery-wallpaper-tide')));
      await tester.pumpAndSettle();
      expect(
        c.read(appearanceProvider).wallpaper.pattern,
        WallpaperPattern.sea,
      );
      expect(c.read(appearanceProvider).wallpaper.intensity, 0.6);

      await tester.tap(find.text('Fonts'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fontSearch')), findsOneWidget);
      // The preview stays while the tabs change.
      expect(find.byKey(const Key('customizePreview')), findsOneWidget);
    },
  );

  testWidgets(
    'Customize can preview the other brightness without changing the app',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      await tester.pumpWidget(harness(FakeBackend(), const CustomizeScreen()));
      await tester.pumpAndSettle();
      final c = _container(tester, CustomizeScreen);
      Brightness preview() =>
          Theme.of(tester.element(find.byKey(const Key('customizePreview'))))
              .brightness;
      expect(preview(), Brightness.light);
      await tester.tap(find.byKey(const Key('customizePeek')));
      await tester.pumpAndSettle();
      expect(preview(), Brightness.dark);
      expect(c.read(appearanceProvider).mode, ThemeMode.system);
    },
  );

  testWidgets('Customize lays the preview beside the choices on wide windows', (
    tester,
  ) async {
    await setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        const CustomizeScreen(initial: LookPart.background),
      ),
    );
    await tester.pumpAndSettle();
    final preview = tester.getRect(find.byKey(const Key('customizePreview')));
    final tabs = tester.getRect(find.byKey(const Key('customizeTabs')));
    expect(preview.left, greaterThan(tabs.right));
    expect(find.byKey(const Key('pattern-doodles')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a new install is the Casama theme, not a custom look', () {
    expect(currentTheme(const Appearance(), const [])?.id, 'casama');
  });

  test('older links still name a part, and unknown ones open Colors', () {
    expect(LookPart.named('fonts'), LookPart.fonts);
    expect(LookPart.named('background'), LookPart.background);
    expect(LookPart.named(null), LookPart.colors);
    expect(LookPart.named('nope'), LookPart.colors);
  });
}

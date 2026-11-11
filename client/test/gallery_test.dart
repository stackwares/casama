import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/settings/gallery_previews.dart';
import 'package:casama_app/features/settings/gallery_screen.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

const _author = 'Casama';

GalleryItem _scheme(String id, String name, {bool featured = false}) => GalleryItem(
  id: id,
  type: 'scheme',
  name: name,
  authorName: _author,
  license: 'CC0-1.0',
  featured: featured,
  tags: const ['teal'],
  document: const {
    'light': {'seed': '#0E6E78', 'background': '#F4FBFC', 'onBackground': '#102226'},
    'dark': {'seed': '#8FE8E2', 'background': '#0C2428', 'onBackground': '#E7F6F5'},
  },
);

// Bundled fonts, so previews don't try to download a Google Font in tests.
const _theme = GalleryItem(
  id: 'lagoon',
  type: 'theme',
  name: 'Lagoon',
  authorName: _author,
  license: 'CC0-1.0',
  featured: true,
  document: {
    'v': 2,
    'scheme': {
      'light': {'seed': '#0E6E78', 'background': '#F4FBFC', 'onBackground': '#102226'},
      'dark': {'seed': '#8FE8E2', 'background': '#0C2428', 'onBackground': '#E7F6F5'},
    },
    'headingFont': 'Fraunces',
    'bodyFont': 'Figtree',
    'wallpaper': {'pattern': 'sea', 'palette': 'ocean', 'intensity': 0.5},
  },
);

const _wallpaper = GalleryItem(
  id: 'tide',
  type: 'wallpaper',
  name: 'Tide',
  authorName: 'Ana Reyes',
  license: 'CC-BY-4.0',
  featured: true,
  document: {'kind': 'pattern', 'pattern': 'sea', 'palette': 'ocean', 'intensity': 0.6},
);

const _skill = GalleryItem(
  id: 'meeting-notes',
  type: 'skill',
  name: 'Meeting notes',
  authorName: _author,
  license: 'Apache-2.0',
  category: 'work',
  icon: 'notebook-pen',
  description: 'Turn a meeting transcript into decisions and action items.',
  skillMd: '---\nname: meeting-notes\ndescription: Notes\n---\n\n# Meeting notes\n\n1. Read everything once.\n',
);

FakeBackend _backend() => FakeBackend()..galleryItems = [_scheme('lagoon', 'Lagoon'), _theme, _wallpaper, _skill];

Future<void> _pumpScreen(WidgetTester tester, FakeBackend backend, Widget screen, {List<dynamic> overrides = const []}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(harness(backend, screen, overrides: overrides));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a gallery color scheme is drawn in its colors and can be used', (tester) async {
    await _pumpScreen(tester, _backend(), const GalleryScreen(initialType: 'scheme'));
    expect(find.text('Lagoon'), findsOneWidget);
    expect(find.text('Light and dark'), findsOneWidget);
    expect(find.byType(GallerySchemeSwatch), findsOneWidget);
    await tester.tap(find.byKey(const Key('gallery-scheme-lagoon')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('galleryPreview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('galleryUse-lagoon')));
    await tester.pumpAndSettle();
    expect(find.text('Using Lagoon'), findsOneWidget);
  });

  testWidgets('everything shows featured looks first, then a row of each kind', (tester) async {
    await _pumpScreen(tester, _backend(), const GalleryScreen());
    // One featured theme and one featured wallpaper, each drawn as a chat.
    expect(find.byKey(const Key('galleryFeatured-theme-lagoon')), findsOneWidget);
    expect(find.byKey(const Key('galleryFeatured-wallpaper-tide')), findsOneWidget);
    expect(find.textContaining('Themes', findRichText: true), findsWidgets);
    expect(find.text('Meeting notes'), findsOneWidget);
    // A contributor is credited on the card; Casama's own items say what they are.
    expect(find.text('By Ana Reyes'), findsWidgets);
    expect(find.text('Fraunces · Figtree'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gallerySeeAll-wallpaper')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-wallpaper-tide')), findsOneWidget);
    expect(find.byKey(const Key('gallery-theme-lagoon')), findsNothing);
  });

  testWidgets('search narrows every kind and says when nothing matches', (tester) async {
    await _pumpScreen(tester, _backend(), const GalleryScreen());
    await tester.enterText(find.byKey(const Key('gallerySearch')), 'meeting');
    await tester.pumpAndSettle();
    expect(find.text('Meeting notes'), findsOneWidget);
    expect(find.byKey(const Key('gallery-theme-lagoon')), findsNothing);
    await tester.enterText(find.byKey(const Key('gallerySearch')), 'zebra');
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches “zebra”'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-theme-lagoon')), findsOneWidget);
  });

  testWidgets('a theme marks itself in use once applied', (tester) async {
    await _pumpScreen(tester, _backend(), const GalleryScreen(initialType: 'theme'));
    expect(find.text('In use'), findsNothing);
    await tester.tap(find.byKey(const Key('gallery-theme-lagoon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('galleryUse-lagoon')));
    await tester.pumpAndSettle();
    expect(find.text('Using Lagoon'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(GalleryScreen)));
    final look = container.read(appearanceProvider);
    expect(look.schemeId, 'gallery:theme-lagoon');
    expect(look.headingFont, 'Fraunces');
  });

  testWidgets('a tag in the detail searches the gallery for it', (tester) async {
    await _pumpScreen(tester, _backend(), const GalleryScreen(openType: 'scheme', openId: 'lagoon'));
    await tester.tap(find.byKey(const Key('galleryTag-teal')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byKey(const Key('gallerySearch')));
    expect(field.controller!.text, 'teal');
  });

  testWidgets('a skill shows its instructions and installs to the workspace', (tester) async {
    final backend = _backend();
    final org = (await backend.organizations()).first;
    await _pumpScreen(
      tester,
      backend,
      const GalleryScreen(openType: 'skill', openId: 'meeting-notes'),
      overrides: [currentOrgProvider.overrideWithValue(org)],
    );
    expect(find.byKey(const Key('gallerySkillInstructions')), findsOneWidget);
    expect(find.textContaining('Read everything once.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('galleryUse-meeting-notes')));
    await tester.pumpAndSettle();
    expect(backend.galleryInstalls, [('meeting-notes', null)]);
    expect(find.text('Installed Meeting notes'), findsOneWidget);
  });

  testWidgets('the gallery says when it cannot be reached, and tries again', (tester) async {
    final backend = FakeBackend()..galleryAvailable = false;
    await _pumpScreen(tester, backend, const GalleryScreen());
    expect(find.text('The gallery is offline'), findsOneWidget);
    backend
      ..galleryAvailable = true
      ..galleryItems = [_theme];
    await tester.tap(find.byKey(const Key('galleryRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-theme-lagoon')), findsOneWidget);
  });
}

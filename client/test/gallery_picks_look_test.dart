// Pictures of "Picks for you" with the gallery's real starter sets, on a phone, a phone held
// sideways, a tablet and a desktop window, in light and dark mode, for looking at. It runs only
// when told where to put them:
//
//   PICKS_SHOTS=/some/folder flutter test test/gallery_picks_look_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/welcome/gallery_picks_step.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'support/shots.dart';

List<GalleryItem> _load(String file) => [
  for (final j
      in (jsonDecode(File('../gallery/$file').readAsStringSync())
              as Map)['items']
          as List)
    GalleryItem.fromJson((j as Map).cast<String, dynamic>()),
];

void main() {
  final dir = Platform.environment['PICKS_SHOTS'];
  const sizes = <(String, Size, FakeViewPadding)>[
    ('phone', Size(393, 852), FakeViewPadding(top: 59, bottom: 34)),
    ('phone-small', Size(375, 667), FakeViewPadding(top: 20)),
    (
      'phone-sideways',
      Size(852, 393),
      FakeViewPadding(left: 59, right: 59, bottom: 21),
    ),
    ('tablet', Size(820, 1180), FakeViewPadding(top: 24, bottom: 20)),
    ('desktop', Size(1280, 820), FakeViewPadding.zero),
    ('desktop-wide', Size(1680, 1050), FakeViewPadding.zero),
    ('desktop-tall', Size(1830, 1400), FakeViewPadding.zero),
  ];

  for (final (name, size, padding) in sizes) {
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('pictures: $name ${mode.name}', (tester) async {
        await loadAppFonts();
        // Real, blurred shadows: tests draw them as solid blocks unless told otherwise.
        debugDisableShadows = false;
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = FakeViewPadding(
          left: padding.left * 2,
          top: padding.top * 2,
          right: padding.right * 2,
          bottom: padding.bottom * 2,
        );
        addTearDown(tester.view.reset);
        final backend = FakeBackend()
          ..about = const AboutYouView(
            about: 'I run a small startup and talk to investors.',
          )
          ..gallerySetItems = _load('sets.json')
          ..galleryItems = [
            ..._load('index.json'),
            ..._load('bots.json'),
            ..._load('routines.json'),
            ..._load('apps.json'),
          ];
        await tester.pumpWidget(
          ShotFrame(
            child: ProviderScope(
              overrides: [backendProvider.overrideWithValue(backend)],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: mode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const GalleryPicksStep(),
              ),
            ),
          ),
        );
        Future<void> settle() async {
          for (var i = 0; i < 20; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle();
        await shot(tester, dir!, '${name}_${mode.name}');
        final student = find.byKey(const Key('galleryPicksSet-student-kit'));
        await tester.scrollUntilVisible(
          student,
          200,
          scrollable: find.descendant(
            of: find.byKey(const Key('galleryPicksList')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.ensureVisible(student);
        await tester.pump();
        await tester.tap(student);
        await settle();
        await shot(tester, dir, '${name}_${mode.name}_student');
        debugDisableShadows = true;
      }, skip: dir == null);
    }
  }
}

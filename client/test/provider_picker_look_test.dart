// Pictures of the add-key provider picker in light and dark, for looking at. It runs only when
// told where to put them:
//
//   PICKER_SHOTS=/some/folder flutter test test/provider_picker_look_test.dart
import 'dart:io';

import 'package:casama/app.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/home/home_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';
import 'support/shots.dart';

void main() {
  final dir = Platform.environment['PICKER_SHOTS'];
  for (final dark in [false, true]) {
    testWidgets('pictures: provider picker ${dark ? 'dark' : 'light'}', (tester) async {
      await loadAppFonts();
      SharedPreferences.setMockInitialValues({'theme_mode': dark ? 'dark' : 'light'});
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.view.physicalSize = const Size(390 * 3, 1700 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ShotFrame(
          child: ProviderScope(
            overrides: [backendProvider.overrideWithValue(FakeBackend())],
            child: const CasamaApp(),
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        tester.takeException();
      }

      await settle();
      GoRouter.of(tester.element(find.byType(HomeShell))).go('/settings/keys');
      await settle();
      await tester.ensureVisible(find.byKey(const Key('provider-openrouter')));
      await settle();
      await shot(tester, dir!, 'picker_${dark ? 'dark' : 'light'}');
      await tester.tap(find.byKey(const Key('moreProviders')));
      await settle();
      await tester.ensureVisible(find.byKey(const Key('moreProviders')));
      await settle();
      await shot(tester, dir, 'picker_more_${dark ? 'dark' : 'light'}');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
      tester.takeException();
    }, skip: dir == null);
  }
}

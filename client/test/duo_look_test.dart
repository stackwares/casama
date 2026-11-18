// Pictures of the app in every iPhone Duo pose (D-411), for looking at. It runs only when told
// where to put them:
//
//   DUO_SHOTS=/some/folder flutter test test/duo_look_test.dart
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
import 'support/poses.dart';
import 'support/shots.dart';

void main() {
  final dir = Platform.environment['DUO_SHOTS'];
  const pages = {
    'chats': '/bots',
    'chat': '/bots/$botId/chat',
    'library': '/library',
    'tasks': '/tasks',
    'settings': '/settings',
    'settings-appearance': '/settings/appearance',
    'computer': '/computer?bot=$botId',
    'search': '/search',
    'bot-profile': '/bots/$botId/settings',
  };

  // A window that is not a folding phone but gets the same two panes: a 13-inch iPad held
  // upright. (A mid-width desktop window lays out the same way beside its rail.)
  const others = <(DuoPose, TargetPlatform?)>[
    (DuoPose('ipad 13 upright', Size(1032, 1376), padding: FakeViewPadding(top: 24, bottom: 20)), TargetPlatform.iOS),
  ];

  for (final (pose, platform) in <(DuoPose, TargetPlatform?)>[for (final p in DuoPose.all) (p, TargetPlatform.iOS), ...others]) {
    testWidgets(
      'pictures: ${pose.name}',
      (tester) async {
        await loadAppFonts();
        SharedPreferences.setMockInitialValues({});
        setPose(tester, pose);
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
        final router = GoRouter.of(tester.element(find.byType(HomeShell)));
        for (final MapEntry(key: name, value: path) in pages.entries) {
          router.go(path);
          await settle();
          await shot(tester, dir!, '${pose.name}_$name');
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 1));
        tester.takeException();
      },
      skip: dir == null,
      variant: platform == null
          ? const DefaultTestVariant()
          : TargetPlatformVariant.only(platform),
    );
  }
}

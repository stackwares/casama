// A tour of the app on a folding phone, with sample data and no server (D-411): for looking at
// every pose on a simulator or a device.
//
//   flutter test integration_test/duo_tour_test.dart -d <device>
//
// It prints `TOUR pose <name>` and waits for the device to be in that pose (closed, openWide,
// book, openTall, laptop, tent), then walks through the main screens, printing
// `TOUR shot <pose> <screen>` when each one is ready and holding it for a few seconds. Put the
// device in each pose by hand (Xcode's Device Hub has the buttons for a simulator), or let a
// script read the lines, click the buttons and take the pictures. A pose that doesn't come
// within a minute and a half is skipped. `--dart-define=TOUR_POSES=closed,openWide` tours only
// those.
import 'package:casama/app.dart';
import 'package:casama/core/fold/fold.dart';
import 'package:casama/core/live.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/voice.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/home/home_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/fake_backend.dart';
import '../test/fake_live.dart';
import '../test/fake_unlockers.dart';
import '../test/fake_voice.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a tour of every pose', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(FakeBackend()),
          unlockersProvider.overrideWithValue(FakeUnlockers()),
          liveConnectorProvider.overrideWithValue(FakeLiveConnector()),
          voiceCallConnectorProvider.overrideWithValue(FakeCallConnector()),
        ],
        child: const CasamaApp(),
      ),
    );

    Future<void> hold(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        tester.takeException();
      }
    }

    Future<void> tapIfThere(String key) async {
      final target = find.byKey(Key(key)).hitTestable();
      if (target.evaluate().isEmpty) return;
      await tester.tap(target.first, warnIfMissed: false);
      await hold(800);
    }

    await hold(3000);
    // The first-run steps that cover the app on a fresh install.
    await tapIfThere('notificationsNotNow');

    FoldInfo fold() => FoldInfo.of(tester.element(find.byType(HomeShell)));
    final router = GoRouter.of(tester.element(find.byType(HomeShell)));
    final screens = <String, String>{
      'chats': '/bots',
      'chat': '/bots/$botId/chat',
      'library': '/library',
      'tasks': '/tasks',
      'settings': '/settings/appearance',
      'fold': '/settings/fold',
      'computer': '/computer/live?c=$computerId',
      'call': '/bots/$botId/call',
    };

    const only = String.fromEnvironment('TOUR_POSES');
    final poses = only.isEmpty
        ? ['closed', 'openWide', 'book', 'openTall', 'laptop', 'tent']
        : only.split(',');
    for (final pose in poses) {
      // ignore: avoid_print
      print('TOUR pose $pose');
      final giveUp = DateTime.now().add(const Duration(seconds: 90));
      while (fold().pose.name != pose && DateTime.now().isBefore(giveUp)) {
        await hold(500);
      }
      if (fold().pose.name != pose) {
        // ignore: avoid_print
        print('TOUR skipped $pose (the device is in ${fold().pose.name})');
        continue;
      }
      await hold(1500);
      for (final MapEntry(key: name, value: path) in screens.entries) {
        router.go(path);
        await hold(1800);
        // In control of the bot's computer, so the trackpad shows where there is one.
        if (name == 'computer') await tapIfThere('takeControl');
        // ignore: avoid_print
        print('TOUR shot $pose $name');
        await hold(3500);
        if (name == 'computer') await tapIfThere('handBack');
        if (name == 'computer') await tapIfThere('confirmHandBack');
        if (name == 'call') await tapIfThere('hangUpButton');
      }
      router.go('/bots');
      await hold(800);
    }
    // ignore: avoid_print
    print('TOUR done');
  }, timeout: const Timeout(Duration(minutes: 25)));
}

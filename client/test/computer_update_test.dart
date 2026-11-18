// Computer updates on the person's terms, and live view that survives a deploy (D-360).
import 'package:casama/core/live.dart';
import 'package:casama/features/computer/computer_screen.dart';
import 'package:casama/features/computer/live_view_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'fake_live.dart';
import 'live_test.dart' show liveHarness;

Future<void> _openComputer(WidgetTester tester, FakeBackend backend) async {
  await setSize(tester, const Size(500, 1400));
  await tester.pumpWidget(
    harness(
      backend,
      const Scaffold(body: ComputerScreen(embedded: true, initialTab: 'manage')),
    ),
  );
  await tester.pumpAndSettle();
}

FakeBackend _waiting() => FakeBackend()
  ..teamComputerState = ComputerState.running
  ..computerUpdateSince = DateTime.now().subtract(const Duration(hours: 3));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('live view after a cut', () {
    Future<FakeLiveConnector> open(WidgetTester tester, FakeBackend backend) async {
      await setSize(tester, const Size(900, 900));
      final live = FakeLiveConnector();
      await tester.pumpWidget(liveHarness(backend, live, const LiveViewScreen(computerId: computerId)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(live.connects, 1);
      return live;
    }

    testWidgets('a cut stream says Reconnecting, redials and plays again', (tester) async {
      final backend = FakeBackend();
      final live = await open(tester, backend);
      live.connection.drop();
      await tester.pump();
      expect(find.text('Reconnecting…'), findsWidgets);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(live.connects, 2);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Reconnecting…'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('keeps trying while the server is down, then offers Try again', (tester) async {
      final backend = FakeBackend();
      final live = await open(tester, backend);
      live.failNext = 100;
      live.connection.drop();
      await tester.pump();
      // About 45 seconds of tries (1, 2, 4, 8, 15, 15 s).
      for (final s in [1, 2, 4, 8, 15, 15]) {
        await tester.pump(Duration(seconds: s));
        await tester.pump();
      }
      expect(live.connects, 7);
      expect(find.text('Screenshots'), findsOneWidget);
      expect(find.byKey(const Key('liveRetry')), findsOneWidget);
      // No more tries on its own.
      await tester.pump(const Duration(seconds: 30));
      expect(live.connects, 7);

      live.failNext = 0;
      await tester.tap(find.byKey(const Key('liveRetry')));
      await tester.pump();
      await tester.pump();
      expect(live.connects, 8);
      expect(find.text('Live'), findsOneWidget);
      expect(find.byKey(const Key('liveRetry')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a network that blocks video still falls back at once, with no redials', (tester) async {
      final backend = FakeBackend();
      final live = await open(tester, backend);
      live.connection.goFallback(); // never cut: blocked
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(live.connects, 1);
      expect(find.text('Screenshots'), findsOneWidget);
      expect(find.byKey(const Key('liveRetry')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    test('the API restart close code is 1012', () => expect(liveRestartCloseCode, 1012));
  });

  group('update available', () {
    testWidgets('an up-to-date computer shows no card', (tester) async {
      await _openComputer(tester, FakeBackend()..teamComputerState = ComputerState.running);
      expect(find.byKey(const Key('computerUpdateCard')), findsNothing);
    });

    testWidgets('a sleeping computer shows no card: it updates when it wakes', (tester) async {
      final backend = _waiting()..teamComputerState = ComputerState.sleeping;
      await _openComputer(tester, backend);
      expect(find.byKey(const Key('computerUpdateCard')), findsNothing);
    });

    testWidgets('Update now asks, then restarts it on the new system', (tester) async {
      final backend = _waiting();
      await _openComputer(tester, backend);
      expect(find.byKey(const Key('computerUpdateCard')), findsOneWidget);
      expect(find.textContaining('Updating restarts this computer'), findsOneWidget);

      await tester.tap(find.byKey(const Key('computerUpdateNow')));
      await tester.pumpAndSettle();
      expect(find.text('Update this computer?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmComputerUpdate')));
      await tester.pumpAndSettle();
      expect(backend.computerActions, ['update']);
      expect(find.text('Updated. Your files are all there.'), findsOneWidget);
      expect(find.byKey(const Key('computerUpdateCard')), findsNothing);
    });

    testWidgets('a running command asks once more before it is stopped', (tester) async {
      final backend = _waiting()..computerBusy = true;
      await _openComputer(tester, backend);
      await tester.tap(find.byKey(const Key('computerUpdateNow')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmComputerUpdate')));
      await tester.pumpAndSettle();
      expect(find.text('A command is still running'), findsOneWidget);
      expect(backend.computerActions, isEmpty);
      await tester.tap(find.byKey(const Key('confirmComputerUpdateAnyway')));
      await tester.pumpAndSettle();
      expect(backend.computerActions, ['update+force']);
    });

    testWidgets('the live view offers it in its menu', (tester) async {
      await setSize(tester, const Size(900, 900));
      final backend = _waiting();
      final live = FakeLiveConnector();
      await tester.pumpWidget(
        liveHarness(backend, live, const LiveViewScreen(computerId: computerId)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('liveMore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('liveUpdateComputer')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    // Last: Later is remembered for the rest of the day.
    testWidgets('Later hides the card for a day', (tester) async {
      final backend = _waiting();
      await _openComputer(tester, backend);
      await tester.tap(find.byKey(const Key('computerUpdateLater')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('computerUpdateCard')), findsNothing);
      expect(backend.computerActions, isEmpty);
      final p = await SharedPreferences.getInstance();
      expect(p.getStringList('computer_update_later')?.single, startsWith('$computerId@'));
    });
  });
}

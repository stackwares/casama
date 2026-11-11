import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/user_activity.dart';
import 'package:casama_app/features/computer/live_view_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/material.dart';
import 'package:casama_app/core/live.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_live.dart';

/// Activity-based keep-awake (D-195): presence only while the person is here, "Still watching?"
/// after a long quiet spell, and no stream while nobody can see it.
void main() {
  Future<(FakeBackend, FakeLiveConnector)> open(WidgetTester tester, {OrganizationWithRole? org, FakeBackend? backend}) async {
    await setSize(tester, const Size(900, 900));
    final b = backend ?? FakeBackend();
    final live = FakeLiveConnector();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(b), liveConnectorProvider.overrideWithValue(live), if (org != null) currentOrgProvider.overrideWithValue(org)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LiveViewScreen(computerId: computerId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(live.connects, 1);
    return (b, live);
  }

  Future<void> lifecycle(WidgetTester tester, List<AppLifecycleState> states) async {
    for (final s in states) {
      tester.binding.handleAppLifecycleStateChanged(s);
      await tester.pump();
    }
  }

  testWidgets('presence goes out every minute only while the person touched the app recently', (tester) async {
    final (_, live) = await open(tester);
    final conn = live.connection;
    await tester.pump(KeepAwake.presenceInterval);
    expect(conn.presences, 1);

    // No input for longer than the recent-input window: the beats stop.
    await tester.pump(KeepAwake.recentInput);
    final quiet = conn.presences;
    // Still quiet, and short of the "Still watching?" question.
    await tester.pump(KeepAwake.stillWatchingAfter - KeepAwake.presenceInterval - KeepAwake.recentInput - const Duration(seconds: 10));
    expect(conn.presences, quiet);

    // A touch anywhere brings them back.
    await tester.tap(find.byKey(const Key('liveStatus')));
    await tester.pump(KeepAwake.presenceInterval);
    expect(conn.presences, quiet + 1);
  });

  testWidgets('hidden closes the stream with no presence; resumed reconnects', (tester) async {
    final (_, live) = await open(tester);
    final conn = live.connection;
    await lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden]);
    expect(conn.closed, isTrue);
    final before = conn.presences;
    await tester.pump(KeepAwake.presenceInterval * 2);
    expect(conn.presences, before);

    await lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await tester.pump(const Duration(milliseconds: 100));
    expect(live.connects, 2);
    expect(conn.closed, isFalse);
  });

  testWidgets('a visible but unfocused window sends no presence', (tester) async {
    final (_, live) = await open(tester);
    await lifecycle(tester, [AppLifecycleState.inactive]);
    await tester.pump(KeepAwake.presenceInterval * 2);
    expect(live.connection.presences, 0);
    expect(live.connection.closed, isFalse);
    await lifecycle(tester, [AppLifecycleState.resumed]);
  });

  testWidgets('"Still watching?" after the quiet spell; unanswered, it pauses to save power and Resume reconnects', (tester) async {
    final (_, live) = await open(tester);
    await tester.pump(KeepAwake.stillWatchingAfter - const Duration(seconds: 5));
    expect(find.byKey(const Key('stillWatching')), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Still watching?'), findsOneWidget);

    await tester.pump(KeepAwake.answerWindow);
    expect(find.byKey(const Key('stillWatching')), findsNothing);
    expect(find.text('Paused to save power'), findsOneWidget);
    expect(live.connection.closed, isTrue);
    // Coming back to the app doesn't reconnect by itself.
    await lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(live.connects, 1);

    await tester.tap(find.byKey(const Key('liveResume')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(live.connects, 2);
    expect(live.connection.closed, isFalse);
    expect(find.text('Paused to save power'), findsNothing);
  });

  testWidgets('Keep watching keeps the stream', (tester) async {
    final (_, live) = await open(tester);
    await tester.pump(KeepAwake.stillWatchingAfter + const Duration(seconds: 1));
    expect(find.byKey(const Key('stillWatching')), findsOneWidget);
    await tester.tap(find.byKey(const Key('keepWatching')));
    await tester.pump();
    expect(find.byKey(const Key('stillWatching')), findsNothing);
    await tester.pump(KeepAwake.answerWindow * 2);
    expect(live.connection.closed, isFalse);
    expect(find.text('Paused to save power'), findsNothing);
  });

  testWidgets('no "Still watching?" while a bot is working on this computer', (tester) async {
    final backend = FakeBackend()..defaultComputer = computerId;
    backend.extraBots.add(backend.bot(id: 'bot-working', name: 'Bo', status: BotStatusEnum.working));
    final org = (await backend.organizations()).first;
    final (_, live) = await open(tester, backend: backend, org: org);
    await tester.pump(KeepAwake.stillWatchingAfter + const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('stillWatching')), findsNothing);
    await tester.pump(KeepAwake.answerWindow * 2);
    expect(live.connection.closed, isFalse);
  });
}

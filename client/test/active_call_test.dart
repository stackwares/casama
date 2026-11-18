import 'dart:async';

import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/core/voice.dart';
import 'package:casama/features/island/island_call.dart';
import 'package:casama/features/voice/active_call.dart';
import 'package:casama/features/voice/call_bubble.dart';
import 'package:casama/features/voice/call_screen.dart';
import 'package:casama/features/voice/wake_word.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';
import 'wake_word_test.dart' show FakeWakeEngine;

/// A new [FakeCall] for every connection, so two calls in a row are two calls.
class CallsConnector implements VoiceCallConnector {
  final calls = <FakeCall>[];
  final sessions = <VoiceSession>[];
  FakeCall get last => calls.last;
  @override
  Future<VoiceCall> connect(VoiceSession s) async {
    sessions.add(s);
    final c = FakeCall();
    calls.add(c);
    return c;
  }
}

const otherBotId = 'bot-max';

/// The app's shape for calls: a home page, the call screen at /bots/:id/call, a chat page, and the
/// bubble over the router.
({Widget app, GoRouter router}) callApp(
  FakeBackend backend,
  VoiceCallConnector calls, {
  List<Override> extra = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: Text('home'))),
      ),
      GoRoute(
        path: '/bots/:id/call',
        builder: (_, s) => CallScreen(
          botId: s.pathParameters['id']!,
          conversationId: s.uri.queryParameters['c'],
          callId: s.uri.queryParameters['call'],
        ),
      ),
      GoRoute(
        path: '/bots/:id/chat',
        builder: (_, s) => Scaffold(
          body: Column(
            children: [
              CallReturnBar(
                botId: s.pathParameters['id']!,
                conversationId: s.uri.queryParameters['c'],
              ),
              Text(
                'chat ${s.pathParameters['id']} ${s.uri.queryParameters['c']}',
              ),
            ],
          ),
        ),
      ),
    ],
  );
  final app = ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      voiceCallConnectorProvider.overrideWithValue(calls),
      routerProvider.overrideWithValue(router),
      ...extra,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => CallBubbleOverlay(child: child!),
    ),
  );
  return (app: app, router: router);
}

Future<void> settle(WidgetTester tester) async {
  // Page transitions finish, the screen that left is disposed, and the bubble comes in.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

FakeBackend backendWithBots() {
  final b = FakeBackend();
  b.extraBots.add(
    Bot.fromJson({...b.bot().toJson(), 'id': otherBotId, 'name': 'Max'}),
  );
  return b;
}

void main() {
  CallScreen.motion = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'leaving the call screen minimises the call to a bubble; tapping it returns to the same call',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = FakeBackend();
      final calls = CallsConnector();
      final (:app, :router) = callApp(backend, calls);
      await tester.pumpWidget(app);
      unawaited(router.push('/bots/$botId/call?c=$convId'));
      await settle(tester);
      expect(find.text('Live'), findsOneWidget);
      expect(find.byKey(const Key('callBubble')), findsNothing);

      // Back: the call keeps going, as a bubble over the home page.
      router.pop();
      await settle(tester);
      expect(find.text('home'), findsOneWidget);
      expect(calls.last.hungUp, isFalse);
      expect(find.byKey(const Key('callBubble')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('callBubble'))).label,
        contains('Call with'),
      );

      // Turns keep saving while it's minimised.
      calls.last.say('user', 'Still there?');
      await settle(tester);
      expect(backend.liveTurns, [('user', 'Still there?')]);

      await tester.tap(find.byKey(const Key('callBubble')));
      await settle(tester);
      expect(find.text('Live'), findsOneWidget);
      expect(calls.sessions.length, 1, reason: 'the same call, not a new one');
      expect(find.byKey(const Key('callBubble')), findsNothing);

      // The minimise button does what Back does.
      await tester.tap(find.byKey(const Key('minimiseCall')));
      await settle(tester);
      expect(find.byKey(const Key('callBubble')), findsOneWidget);
      expect(calls.last.hungUp, isFalse);
    },
  );

  testWidgets(
    'the bubble\'s long press mutes and ends the call; it snaps to the nearest side',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = FakeBackend();
      final calls = CallsConnector();
      final (:app, :router) = callApp(backend, calls);
      await tester.pumpWidget(app);
      unawaited(router.push('/bots/$botId/call?c=$convId'));
      await settle(tester);
      router.pop();
      await settle(tester);

      // Dragged to the left half, it rests on the left edge.
      final bubble = find.byKey(const Key('callBubble'));
      await tester.drag(bubble, const Offset(-300, -100));
      await settle(tester);
      expect(tester.getTopLeft(bubble).dx, lessThan(100));
      expect(
        (await SharedPreferences.getInstance()).getBool('call.bubble.side'),
        isFalse,
      );

      await tester.longPress(bubble);
      await settle(tester);
      await tester.tap(find.byKey(const Key('callBubbleMute')));
      await settle(tester);
      expect(calls.last.muted, isTrue);
      expect(find.byKey(const Key('callBubbleMuted')), findsOneWidget);

      await tester.longPress(bubble);
      await settle(tester);
      await tester.tap(find.byKey(const Key('callBubbleEnd')));
      await settle(tester);
      expect(calls.last.hungUp, isTrue);
      expect(find.byKey(const Key('callBubble')), findsNothing);
      expect(backend.endedLiveCalls, ['live-1']);
    },
  );

  testWidgets(
    'calling a second bot asks first: End and Call saves the first call, Cancel keeps it',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = backendWithBots();
      final calls = CallsConnector();
      final (:app, :router) = callApp(backend, calls);
      await tester.pumpWidget(app);
      unawaited(router.push('/bots/$botId/call?c=$convId'));
      await settle(tester);
      calls.last.say('user', 'Hello');
      router.pop();
      await settle(tester);

      // Cancel: back, with the first call still on.
      unawaited(router.push('/bots/$otherBotId/call'));
      await settle(tester);
      expect(find.textContaining('and call Max?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(calls.calls.length, 1);
      expect(calls.last.hungUp, isFalse);
      expect(find.byKey(const Key('callBubble')), findsOneWidget);

      // End and Call: the first call ends (saved), the second starts.
      unawaited(router.push('/bots/$otherBotId/call'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('callSwitchConfirm')));
      await settle(tester);
      expect(calls.calls.first.hungUp, isTrue);
      expect(backend.endedLiveCalls, ['live-1']);
      expect(calls.calls.length, 2);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Call with Max'), findsWidgets);

      // Calling the same bot again only shows its call.
      unawaited(router.push('/bots/$otherBotId/call'));
      await settle(tester);
      expect(calls.calls.length, 2);
    },
  );

  testWidgets(
    'hanging up from the call screen saves the call and opens its chat',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = FakeBackend();
      final calls = CallsConnector();
      final (:app, :router) = callApp(backend, calls);
      await tester.pumpWidget(app);
      unawaited(router.push('/bots/$botId/call?c=$convId'));
      await settle(tester);
      calls.last.say('user', 'Bye');
      await tester.tap(find.byKey(const Key('hangUpButton')));
      await settle(tester);
      expect(calls.last.hungUp, isTrue);
      expect(find.text('chat $botId $convId'), findsOneWidget);
      expect(backend.liveTurns, [('user', 'Bye')]);
      expect(find.byKey(const Key('callBubble')), findsNothing);
    },
  );

  testWidgets('the call\'s chat shows a bar back to it while minimised', (
    tester,
  ) async {
    await setSize(tester, const Size(420, 860));
    final backend = FakeBackend();
    final calls = CallsConnector();
    final (:app, :router) = callApp(backend, calls);
    await tester.pumpWidget(app);
    unawaited(router.push('/bots/$botId/call?c=$convId'));
    await settle(tester);
    router.go('/bots/$botId/chat?c=$convId');
    await settle(tester);
    expect(
      calls.last.hungUp,
      isFalse,
      reason: 'switching screens never hangs up',
    );
    expect(find.byKey(const Key('callReturnBar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('callReturnBar')));
    await settle(tester);
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets(
    'wide windows dock the call in the sidebar card instead of a bubble',
    (tester) async {
      await setSize(tester, const Size(1300, 900));
      final backend = FakeBackend();
      final calls = CallsConnector();
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            voiceCallConnectorProvider.overrideWithValue(calls),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => CallBubbleOverlay(child: child!),
                home: const Scaffold(
                  body: Align(
                    alignment: Alignment.bottomLeft,
                    child: SizedBox(width: 280, child: CallSidebarCard()),
                  ),
                ),
              );
            },
          ),
        ),
      );
      container.read(activeCallProvider).begin(botId, conversationId: convId);
      await settle(tester);
      expect(find.byKey(const Key('callSidebarCard')), findsOneWidget);
      expect(find.byKey(const Key('callBubble')), findsNothing);
      await tester.tap(find.byKey(const Key('callCardMute')));
      await settle(tester);
      expect(calls.last.muted, isTrue);
      await tester.tap(find.byKey(const Key('callCardEnd')));
      await settle(tester);
      expect(calls.last.hungUp, isTrue);
      expect(find.byKey(const Key('callSidebarCard')), findsNothing);
    },
  );

  group('the call itself (CallController)', () {
    Future<(ActiveCall, CallsConnector, FakeBackend)> start(
      WidgetTester tester, {
      Duration idle = const Duration(minutes: 2),
    }) async {
      final backend = FakeBackend();
      final calls = CallsConnector();
      final active = ActiveCall(() => backend, () => calls);
      addTearDown(active.dispose);
      active.begin(botId, conversationId: convId, idleLimit: idle);
      await tester.pump();
      await tester.pump();
      return (active, calls, backend);
    }

    testWidgets("the Mac's notch follows the call: live, Mute and Hang up from it (D-324)", (
      tester,
    ) async {
      final (active, calls, _) = await start(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final island = container.read(islandCallProvider.notifier);
      final stop = followActiveCall(active, island);
      addTearDown(stop);
      await tester.pump();
      expect(container.read(islandCallProvider)?.botId, botId);
      expect(container.read(islandCallProvider)?.muted, isFalse);
      final controls = island.controls!;
      expect(controls.level, inInclusiveRange(0, 1));
      controls.toggleMute();
      await tester.pump();
      expect(active.live?.muted, isTrue, reason: "the call's own mute, as from the bubble");
      expect(container.read(islandCallProvider)?.muted, isTrue);
      // A call reported some other way is left alone; this one goes when it ends.
      controls.hangUp();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(active.live, isNull);
      expect(container.read(islandCallProvider), isNull);
      expect(calls.last.hungUp, isTrue);
    });

    testWidgets('turns are posted once each, and a failed post is retried', (
      tester,
    ) async {
      final (active, calls, backend) = await start(tester);
      backend.failTurnPosts = 1;
      calls.last.say('user', 'One');
      await tester.pump();
      expect(backend.liveTurns, isEmpty);
      calls.last.say('assistant', 'Two');
      await tester.pump(const Duration(seconds: 3));
      expect(backend.liveTurns, [('user', 'One'), ('assistant', 'Two')]);
      calls.last.say('user', 'Three');
      await tester.pump();
      expect(backend.liveTurns.length, 3);
      await active.end();
      expect(
        backend.liveTurns.length,
        3,
        reason: 'hanging up doesn\'t send saved turns again',
      );
    });

    testWidgets('a turn that never got through goes with the hang-up', (
      tester,
    ) async {
      final (active, calls, backend) = await start(tester);
      backend.failTurnPosts = 99;
      calls.last.say('user', 'Offline words');
      await tester.pump();
      backend.failTurnPosts = 0;
      // The hang-up's own try gets it through, or the transcript carries it (by id, once).
      await active.end();
      expect(backend.liveTurns, [('user', 'Offline words')]);
      expect(backend.endedLiveCalls, ['live-1']);
    });

    testWidgets(
      'a heartbeat every 30 seconds; the server ending the call hangs it up',
      (tester) async {
        final (active, calls, backend) = await start(tester);
        await tester.pump(const Duration(seconds: 31));
        expect(backend.heartbeats, ['live-1']);
        backend.heartbeatEnded = true;
        await tester.pump(const Duration(seconds: 30));
        await tester.pump();
        expect(calls.last.hungUp, isTrue);
        expect(active.lastEnded?.endedBy, CallEnd.server);
      },
    );

    testWidgets(
      'a dropped connection that can\'t resume ends the call and saves it',
      (tester) async {
        final (active, calls, backend) = await start(tester);
        calls.last.say('user', 'Hello?');
        await tester.pump();
        calls.last.drop();
        await tester.pump();
        await tester.pump();
        expect(active.live, isNull);
        expect(active.lastEnded?.endedBy, CallEnd.failed);
        expect(backend.endedLiveCalls, ['live-1']);
      },
    );

    testWidgets(
      'a call that can\'t connect ends its server record and shows why',
      (tester) async {
        final backend = FakeBackend()..voiceSessionError = StateError('no key');
        final calls = CallsConnector();
        final active = ActiveCall(() => backend, () => calls);
        addTearDown(active.dispose);
        final c = active.begin(botId, conversationId: convId)!;
        await tester.pump();
        expect(c.error, isNotNull);
        expect(c.state, CallState.failed);
        expect(
          backend.endedLiveCalls,
          isEmpty,
          reason: 'no session, nothing to end',
        );
      },
    );
  });

  testWidgets(
    'the wake word stops listening during a call and starts again after',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wake.enabled': true,
        'wake.phrase': 'hey casama',
        'wake.bot': botId,
      });
      WakeWordController.testing = true;
      final engine = FakeWakeEngine();
      final backend = FakeBackend();
      final calls = CallsConnector();
      final container = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          voiceCallConnectorProvider.overrideWithValue(calls),
          wakeWordEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);
      container.listen(wakeWordProvider, (_, _) {});
      await tester.pump();
      await tester.pump();
      expect(engine.phrase, 'hey casama');
      final stoppedBefore = engine.stopped;
      engine.phrase = null;
      container.read(activeCallProvider).begin(botId, conversationId: convId);
      await tester.pump();
      // Cancelling the listener's subscription finishes on the real event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(engine.stopped, greaterThan(stoppedBefore));
      await container.read(activeCallProvider).end();
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(engine.phrase, 'hey casama', reason: 'listening again');
    },
  );
}

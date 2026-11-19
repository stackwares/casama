// The bot's work on a call (D-327 Phase 2): jobs started on the call are followed, the bot speaks
// up when one ends (after a pause), the call doesn't hang up for quiet while one runs, the
// live-view tile and its swap, show_screen, stop_task, the job strip and the recap card.
import 'dart:async';

import 'package:casama/core/backend.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:casama/core/voice.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/voice/active_call.dart';
import 'package:casama/features/voice/call_bubble.dart';
import 'package:casama/features/voice/call_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'active_call_test.dart' show CallsConnector, settle;
import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_voice.dart';

const jobRun = '66666666-6666-4666-8666-666666666666';

/// The call screen, the live view and a chat page, with the bubble over the router.
({Widget app, GoRouter router}) jobsApp(
  FakeBackend backend,
  VoiceCallConnector calls,
) {
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
        ),
      ),
      GoRoute(
        path: '/bots/:id/chat',
        builder: (_, s) =>
            Scaffold(body: Text('chat ${s.uri.queryParameters['c']}')),
      ),
      GoRoute(
        path: '/computer/live',
        builder: (_, s) => Scaffold(
          body: Center(child: Text('live view ${s.uri.queryParameters['c']}')),
        ),
      ),
    ],
  );
  final app = ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      voiceCallConnectorProvider.overrideWithValue(calls),
      routerProvider.overrideWithValue(router),
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

/// A backend whose start_task starts [jobRun].
FakeBackend jobsBackend() =>
    FakeBackend()
      ..voiceToolResults['start_task'] = VoiceToolResult(
        status: VoiceToolResultStatusEnum.completed,
        runId: jobRun,
        output: 'Started in the background.',
        approvalId: null,
      );

RunEventItem jobEvent(int seq, String type, Map<String, dynamic> payload) =>
    RunEventItem.fromJson({...eventJson(seq, type, payload), 'run_id': jobRun});

Future<CallController> openCall(
  WidgetTester tester,
  FakeBackend backend,
  CallsConnector calls,
  GoRouter router,
) async {
  unawaited(router.push('/bots/$botId/call?c=$convId'));
  await settle(tester);
  final c = ProviderScope.containerOf(tester.element(find.byType(CallScreen)))
      .read(activeCallProvider)
      .live!;
  return c;
}

Future<void> startJob(WidgetTester tester, FakeCall call) async {
  call.askTool('c-job', 'start_task', const {
    'task': 'Book the flight to Cebu',
  });
  await settle(tester);
}

void main() {
  CallScreen.motion = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'a job started on the call is followed: Working card and strip, no hang-up for quiet, the bot hears it finished after a pause',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = jobsBackend();
      final calls = CallsConnector();
      final (:app, :router) = jobsApp(backend, calls);
      await tester.pumpWidget(app);
      final c = await openCall(tester, backend, calls, router);
      final call = calls.last;
      await startJob(tester, call);

      expect(call.results['c-job'], contains('Started'));
      expect(find.text('Working on it'), findsOneWidget);
      expect(find.byKey(const Key('callJobStrip')), findsOneWidget);
      expect(find.text('Working on: Book the flight to Cebu'), findsOneWidget);
      expect(c.jobsBusy, isTrue);

      // Three quiet minutes: a call with a job running stays up.
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(seconds: 10));
      }
      expect(c.over, isFalse);
      expect(call.hungUp, isFalse);

      // The job replies and finishes while the bot is talking: the note waits for a pause.
      call.speakingNow.value = true;
      backend.runEventsController
        ..add(
          jobEvent(5, 'message.completed', {
            'message_id': 'm-1',
            'content': [
              {'type': 'text', 'text': 'Booked: PR 1845 on Friday at 9.'},
            ],
          }),
        )
        ..add(jobEvent(6, 'run.completed', {'final_message_id': 'm-1'}));
      await tester.pump(const Duration(seconds: 2));
      expect(call.notes, isEmpty);
      call.speakingNow.value = false;
      await tester.pump(const Duration(seconds: 2));
      expect(call.notes, hasLength(1));
      expect(call.notes.single, contains('is done'));
      expect(call.notes.single, contains('PR 1845'));
      expect(c.jobsBusy, isFalse);
      expect(find.byKey(const Key('callJobStrip')), findsNothing);

      // With the job over, two quiet minutes end the call as before.
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(seconds: 10));
      }
      await settle(tester);
      expect(call.hungUp, isTrue);
    },
  );

  testWidgets(
    'a job on the computer shows the tile; a takeover turns it amber; tapping swaps to the live view and the bubble swaps back',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = jobsBackend();
      final calls = CallsConnector();
      final (:app, :router) = jobsApp(backend, calls);
      await tester.pumpWidget(app);
      final c = await openCall(tester, backend, calls, router);
      final call = calls.last;
      await startJob(tester, call);
      expect(find.byKey(const Key('callLiveTile')), findsNothing);

      backend.runEventsController.add(
        jobEvent(3, 'tool.started', {
          'call_id': 'b1',
          'tool': 'browser.open',
          'args_redacted': <String, Object?>{},
        }),
      );
      await settle(tester);
      expect(find.byKey(const Key('callLiveTile')), findsOneWidget);
      expect(find.text('Live view'), findsOneWidget);

      backend.runEventsController.add(
        jobEvent(4, 'takeover.requested', {
          'computer_id': computerId,
          'reason': 'Sign in to the airline',
        }),
      );
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(find.text('Needs you'), findsOneWidget);
      expect(c.tileNeedsYou, isTrue);
      expect(call.notes.single, contains('needs the user on the computer'));
      expect(call.notes.single, contains('Sign in to the airline'));
      expect(find.text('Needs you: Book the flight to Cebu'), findsOneWidget);

      // Tap: the desktop full size in place of the call screen; the call goes on in the bubble.
      await tester.tap(find.byKey(const Key('callLiveTile')));
      await settle(tester);
      expect(find.text('live view $computerId'), findsOneWidget);
      expect(find.byType(CallScreen), findsNothing);
      expect(find.byKey(const Key('callBubble')), findsOneWidget);
      expect(call.hungUp, isFalse);

      // The bubble swaps back.
      await tester.tap(find.byKey(const Key('callBubble')));
      await settle(tester);
      expect(find.byType(CallScreen), findsOneWidget);
      expect(find.byKey(const Key('callBubble')), findsNothing);

      // The close button hides the tile.
      await tester.tap(find.byKey(const Key('callLiveTileClose')));
      await settle(tester);
      expect(find.byKey(const Key('callLiveTile')), findsNothing);

      await c.end(CallEnd.hungUp);
      await settle(tester);
    },
  );

  testWidgets(
    'show_screen opens the tile, then the full live view; stop_task stops quietly; job approvals are answered on the card',
    (tester) async {
      await setSize(tester, const Size(420, 860));
      final backend = jobsBackend();
      final calls = CallsConnector();
      final (:app, :router) = jobsApp(backend, calls);
      await tester.pumpWidget(app);
      final c = await openCall(tester, backend, calls, router);
      final call = calls.last;

      // show_screen is answered by the app, not the server: the bot's (team) computer in a tile.
      call.askTool('s1', 'show_screen', const {});
      await settle(tester);
      expect(backend.voiceTools, isNot(contains('show_screen')));
      expect(call.results['s1'], contains('small tile'));
      expect(find.byKey(const Key('callLiveTile')), findsOneWidget);

      // A job asks for approval: Allow on its card, and it carries on.
      await startJob(tester, call);
      backend.runEventsController.add(
        jobEvent(3, 'approval.requested', {
          'approval_id': 'appr1',
          'tool': 'browser.submit',
          'args_redacted': <String, Object?>{},
          'risk': 'medium',
          'expires_at': '2026-11-20T09:00:00.000Z',
        }),
      );
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(call.notes.single, contains("needs the user's OK"));
      expect(c.needsPerson, isTrue);
      await tester.tap(find.byKey(const Key('toolAllow-c-job')));
      await settle(tester);
      expect(c.jobsBusy, isTrue);
      expect(c.needsPerson, isFalse);
      expect(c.jobs.single.state, CallJobState.running);
      expect(backend.decisions['appr1'], 'approved');

      // "Stop that": the server stops it, and the bot isn't told twice.
      call.askTool('st', 'stop_task', const {});
      await settle(tester);
      expect(backend.voiceTools, contains('stop_task'));
      backend.runEventsController.add(jobEvent(7, 'run.cancelled', {'cancelled_by': null}));
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(c.jobs.single.state, CallJobState.cancelled);
      expect(call.notes.where((n) => n.contains('stopped')), isEmpty);

      // show_screen again while the tile shows: the full live view.
      call.askTool('s2', 'show_screen', const {});
      await settle(tester);
      expect(call.results['s2'], contains('full size'));
      expect(find.text('live view $computerId'), findsOneWidget);

      await c.end(CallEnd.hungUp);
      await settle(tester);
    },
  );

  testWidgets(
    'the chat shows a call recap card instead of its text, with links to the runs',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..storedMessages = [
          ChatMessageView(
            id: 'm-recap',
            role: 'assistant',
            text: 'Call ended · 3:12',
            createdAt: DateTime(2026, 11, 16, 9),
            call: MessageCall.fromContent([
              {'type': 'text', 'text': 'Call ended · 3:12'},
              {
                'type': 'call',
                'seconds': 192,
                'tasks': [
                  {
                    'run_id': 'run-a',
                    'task': 'Book the flight to Cebu',
                    'status': 'completed',
                  },
                  {
                    'run_id': 'run-b',
                    'task': 'Email Ana the plan',
                    'status': 'cancelled',
                  },
                ],
              },
            ]),
          ),
        ];
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/bots/$botId/chat?c=$convId',
        routes: [
          GoRoute(
            path: '/bots/:botId/chat',
            builder: (_, s) => ChatScreen(
              botId: s.pathParameters['botId']!,
              conversationId: s.uri.queryParameters['c'],
            ),
          ),
          GoRoute(
            path: '/bots/:botId/runs/:runId',
            builder: (_, s) =>
                Scaffold(body: Text('run ${s.pathParameters['runId']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            localCacheProvider.overrideWithValue(const NoCache()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('callCard-m-recap')), findsOneWidget);
      expect(find.text('Voice call · 3:12'), findsOneWidget);
      expect(find.text('Call ended · 3:12'), findsNothing);
      expect(find.text('Book the flight to Cebu'), findsOneWidget);
      expect(find.text('Stopped · See what it did'), findsOneWidget);

      await tester.tap(find.byKey(const Key('callRecapRun-run-a')));
      await tester.pumpAndSettle();
      expect(find.text('run run-a'), findsOneWidget);
    },
  );
}

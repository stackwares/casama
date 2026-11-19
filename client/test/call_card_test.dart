import 'package:casama/core/backend.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

const liveCall = '77777777-7777-4777-8777-777777777777';

/// A spoken turn of [call], as the server saves it (its text part carries the call).
ChatMessageView turn(
  String id,
  String role,
  String text,
  DateTime at, {
  String call = liveCall,
}) => ChatMessageView(
  id: id,
  role: role,
  text: text,
  createdAt: at,
  callId: call,
);

/// A call's card message.
ChatMessageView card(
  Map<String, Object?> part,
  DateTime at, {
  String id = 'm-card',
}) => ChatMessageView(
  id: id,
  role: 'assistant',
  text: 'Voice call · 4:12',
  createdAt: at,
  call: MessageCall.fromContent([
    {'type': 'call', ...part},
  ]),
);

Map<String, Object?> fullPart({String summary = 'ready'}) => {
  'live_call_id': liveCall,
  'seconds': 252,
  'kind': 'app',
  'ended': 'bot_hung_up',
  'ended_at': DateTime(2026, 11, 19, 14, 41).toUtc().toIso8601String(),
  'turns': 3,
  'tasks': [
    {'run_id': 'run-a', 'task': 'Book dinner at Abaca', 'status': 'running'},
  ],
  'actions': [
    {
      'run_id': 'run-m',
      'tool': 'memory.write',
      'label': 'Remembered: you like aisle seats',
      'ok': true,
      'target': {'kind': 'memory', 'id': null},
    },
  ],
  'summary': summary == 'ready'
      ? {
          'status': 'ready',
          'text': "Planned Friday's Cebu trip: the 7 AM flight and dinner for four.",
        }
      : {'status': summary},
  'next_steps': summary == 'ready'
      ? [
          {
            'id': 's1',
            'label': 'Text Ana the hotel address',
            'task': 'Text Ana the hotel address',
            'doable': true,
            'state': 'open',
            'run_id': null,
          },
          {
            'id': 's2',
            'label': 'Pack for Cebu',
            'task': 'Pack for Cebu',
            'doable': false,
            'state': 'open',
            'run_id': null,
          },
        ]
      : [],
};

/// [settle]: false where something animates on (the summary shimmer, a live call's pulse).
Future<GoRouter> pumpChat(
  WidgetTester tester,
  FakeBackend backend, {
  bool settle = true,
}) async {
  await setSize(tester, const Size(430, 1400));
  final router = GoRouter(
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
      GoRoute(
        path: '/bots/:botId/memory',
        builder: (_, _) => const Scaffold(body: Text('memory screen')),
      ),
      GoRoute(
        path: '/bots/:botId/call',
        builder: (_, s) =>
            Scaffold(body: Text('calling ${s.uri.queryParameters['c']}')),
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return router;
}

void main() {
  final t0 = DateTime(2026, 11, 19, 14, 37);

  testWidgets(
    'a call is one card: summary, next steps, what was done, and its transcript folded in',
    (tester) async {
      final backend = FakeBackend()
        ..storedMessages = [
          // A call from before the card (no call on its turns): stays as bubbles.
          ChatMessageView(
            id: 'old',
            role: 'assistant',
            text: 'An older spoken turn',
            createdAt: t0.subtract(const Duration(days: 1)),
          ),
          turn('t0', 'assistant', "Hi, it's Ada.", t0),
          turn(
            't1',
            'user',
            "Plan Friday's Cebu trip with me",
            t0.add(const Duration(seconds: 5)),
          ),
          turn(
            't2',
            'assistant',
            'The 7 AM flight works, and dinner at Abaca.',
            t0.add(const Duration(minutes: 2)),
          ),
          card(fullPart(), t0.add(const Duration(minutes: 4))),
        ];
      await pumpChat(tester, backend);

      expect(find.byKey(const Key('callCard-$liveCall')), findsOneWidget);
      expect(find.text('Voice call · 4:12'), findsOneWidget);
      expect(find.textContaining('Ada hung up'), findsOneWidget);
      expect(
        find.text(
          "Planned Friday's Cebu trip: the 7 AM flight and dinner for four.",
        ),
        findsOneWidget,
      );
      // The call's turns aren't bubbles; an older call's are.
      expect(find.text("Plan Friday's Cebu trip with me"), findsNothing);
      expect(find.text('An older spoken turn'), findsOneWidget);
      // Next steps: Do it only where the bot can do it.
      expect(find.text('Text Ana the hotel address'), findsOneWidget);
      expect(find.byKey(const Key('callStepDo-s1')), findsOneWidget);
      expect(find.byKey(const Key('callStepDo-s2')), findsNothing);
      // Done on the call: the job and the quick tool.
      expect(find.text('Book dinner at Abaca'), findsOneWidget);
      expect(find.text('Remembered: you like aisle seats'), findsOneWidget);

      // The transcript unfolds inside the card.
      expect(find.text('Transcript · 3 turns'), findsOneWidget);
      await tester.tap(find.byKey(const Key('callCardTranscript')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          "Plan Friday's Cebu trip with me",
          findRichText: true,
        ),
        findsOneWidget,
      );

      // Do it starts the step; dismissing the other puts it away.
      await tester.tap(find.byKey(const Key('callStepDo-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('callStepDismiss-s2')));
      await tester.pumpAndSettle();
      expect(backend.callSteps, [
        (liveCall, 's1', false),
        (liveCall, 's2', true),
      ]);

      // A remembered fact opens the bot's memory.
      await tester.tap(find.text('Remembered: you like aisle seats'));
      await tester.pumpAndSettle();
      expect(find.text('memory screen'), findsOneWidget);
    },
  );

  testWidgets(
    'the summary is written after the call: a placeholder, then it arrives in place',
    (tester) async {
      final backend = FakeBackend()
        ..storedMessages = [
          turn('t0', 'assistant', 'Hi', t0),
          turn(
            't1',
            'user',
            "Let's plan the week",
            t0.add(const Duration(seconds: 3)),
          ),
          card({
            ...fullPart(summary: 'pending'),
            'ended_at': DateTime.now().toUtc().toIso8601String(),
          }, DateTime.now()),
        ];
      await pumpChat(tester, backend, settle: false);
      expect(find.byKey(const Key('callCardSummaryWaiting')), findsOneWidget);
      expect(find.byKey(const Key('callStepDo-s1')), findsNothing);

      backend.storedMessages = [
        ...backend.storedMessages.take(2),
        card({
          ...fullPart(),
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        }, DateTime.now()),
      ];
      backend.activity.add(const ConversationActivity.changed('m-card'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('callCardSummaryWaiting')), findsNothing);
      expect(
        find.text(
          "Planned Friday's Cebu trip: the 7 AM flight and dinner for four.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('callStepDo-s1')), findsOneWidget);
      // Still one card: the finished one replaced the pending one.
      expect(find.byKey(const Key('callCard-$liveCall')), findsOneWidget);
    },
  );

  testWidgets('a missed call says why and puts Call back first', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..storedMessages = [
        card(
          {
            'live_call_id': null,
            'seconds': 0,
            'kind': 'phone',
            'ended': 'missed',
            'reason': 'Your flight moved to 6 AM',
            'summary': {'status': 'skipped'},
          },
          t0,
          id: 'm-missed',
        ),
      ];
    await pumpChat(tester, backend);
    expect(find.text('Missed call from Ada'), findsOneWidget);
    expect(find.text('Your flight moved to 6 AM'), findsOneWidget);
    expect(find.byKey(const Key('callCardTranscript')), findsNothing);
    final callBack = find.byKey(const Key('callCardCallBack'));
    expect(tester.widget(callBack), isA<FilledButton>());
    await tester.tap(callBack);
    await tester.pumpAndSettle();
    expect(find.text('calling $convId'), findsOneWidget);
  });

  testWidgets(
    'turns with no card yet show as a call going on elsewhere, not as bubbles',
    (tester) async {
      final now = DateTime.now();
      final backend = FakeBackend()
        ..storedMessages = [
          turn(
            't0',
            'assistant',
            'Hi there',
            now.subtract(const Duration(seconds: 30)),
          ),
          turn(
            't1',
            'user',
            'Book the dentist',
            now.subtract(const Duration(seconds: 10)),
          ),
        ];
      await pumpChat(tester, backend, settle: false);
      expect(find.byKey(const Key('callCard-$liveCall')), findsOneWidget);
      expect(find.text('On a call on another device'), findsOneWidget);
      expect(find.text('“Book the dentist”'), findsOneWidget);
      expect(find.byKey(const Key('callCardCallBack')), findsNothing);
    },
  );

  testWidgets(
    'Copy puts the whole call on the clipboard; Delete asks, then removes the card',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final backend = FakeBackend()
        ..storedMessages = [
          turn('t0', 'assistant', 'Hi', t0),
          turn(
            't1',
            'user',
            'Plan the trip',
            t0.add(const Duration(seconds: 4)),
          ),
          card(fullPart(), t0.add(const Duration(minutes: 4))),
        ];
      await pumpChat(tester, backend);
      await tester.tap(find.byKey(const Key('callCardCopy')));
      await tester.pumpAndSettle();
      expect(copied, contains('Voice call · 4:12'));
      expect(copied, contains("Planned Friday's Cebu trip"));
      expect(copied, contains('- Text Ana the hotel address'));
      expect(copied, contains('You: Plan the trip'));

      await tester.tap(find.byKey(const Key('callCardMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('callCardDelete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete call').last);
      await tester.pumpAndSettle();
      expect(backend.deletedCalls, [liveCall]);
      expect(find.byKey(const Key('callCard-$liveCall')), findsNothing);
    },
  );

  test('an older page puts its turns into the card on screen instead of a second card', () {
    final at = DateTime(2026, 11, 19, 14);
    CallTurnView t(String id, int s) => CallTurnView(
      messageId: id,
      role: 'user',
      text: id,
      at: at.add(Duration(seconds: s)),
    );
    final onScreen = CallRecapEntry(
      messageId: 'm-card',
      call: null,
      liveCallId: liveCall,
      turns: [t('t3', 3), t('t4', 4)],
    );
    final fromOlder = CallRecapEntry(
      messageId: null,
      call: null,
      liveCallId: liveCall,
      turns: [t('t1', 1), t('t2', 2)],
    );
    final other = NoticeEntry(
      kind: NoticeKind.routine,
      text: 'Morning news',
      at: at,
    );
    final merged = mergeEarlierCalls([other, fromOlder], [onScreen]);
    expect(merged.whereType<CallRecapEntry>(), hasLength(1));
    expect(merged.first, same(other));
    expect((merged.last as CallRecapEntry).turns.map((x) => x.messageId), [
      't1',
      't2',
      't3',
      't4',
    ]);
  });
}

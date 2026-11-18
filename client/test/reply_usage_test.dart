// Usage on replies (D-307): off by default; when on, each run's last reply gets a small line with
// what it cost, counting up while the bot works, and tapping it shows the breakdown.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_detail.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/reply_usage.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _runA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _runB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

Future<FakeBackend> _openWithHistory(
  WidgetTester tester, {
  required bool on,
}) async {
  SharedPreferences.setMockInitialValues({'chat.showUsage': on});
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend()
    ..storedMessages = [
      ChatMessageView(
        id: 'u1',
        role: 'user',
        text: 'Plan my trip',
        createdAt: DateTime(2026, 1, 1, 0, 0),
        runId: _runA,
      ),
      ChatMessageView(
        id: 'a1',
        role: 'assistant',
        text: 'Looking at flights first.',
        createdAt: DateTime(2026, 1, 1, 0, 1),
        runId: _runA,
      ),
      ChatMessageView(
        id: 'a2',
        role: 'assistant',
        text: 'Here is your plan.',
        createdAt: DateTime(2026, 1, 1, 0, 2),
        runId: _runA,
      ),
      ChatMessageView(
        id: 'u2',
        role: 'user',
        text: 'Thanks',
        createdAt: DateTime(2026, 1, 1, 0, 3),
        runId: _runB,
      ),
      ChatMessageView(
        id: 'a3',
        role: 'assistant',
        text: 'Anytime.',
        createdAt: DateTime(2026, 1, 1, 0, 4),
        runId: _runB,
      ),
    ];
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the switch is off by default and remembered on this device', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(showReplyUsageProvider, (_, _) {});
    expect(container.read(showReplyUsageProvider), isFalse);
    await container.read(showReplyUsageProvider.notifier).set(true);
    expect(container.read(showReplyUsageProvider), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('chat.showUsage'),
      isTrue,
    );
  });

  testWidgets('off: no usage lines and nothing is asked of the server', (
    tester,
  ) async {
    final backend = await _openWithHistory(tester, on: false);
    expect(find.byKey(const Key('replyUsage-$_runA')), findsNothing);
    expect(backend.usageAsked, isEmpty);
  });

  testWidgets(
    'on: one line under each run\'s last reply, with cost, tokens and time',
    (tester) async {
      final backend = await _openWithHistory(tester, on: true);
      expect(find.byKey(const Key('replyUsage-$_runA')), findsOneWidget);
      expect(find.byKey(const Key('replyUsage-$_runB')), findsOneWidget);
      expect(backend.usageAsked.toSet(), {_runA, _runB});
      expect(find.text(r'$0.0420 · 18.2K tokens · 32s'), findsNWidgets(2));

      // The line sits under the run's last reply, not its first.
      final line = tester
          .getTopLeft(find.byKey(const Key('replyUsage-$_runA')))
          .dy;
      expect(
        line,
        greaterThan(
          tester
              .getTopLeft(
                find.textContaining('Here is your plan.', findRichText: true),
              )
              .dy,
        ),
      );
      expect(
        line,
        lessThan(
          tester
              .getTopLeft(find.textContaining('Thanks', findRichText: true))
              .dy,
        ),
      );

      await tester.tap(find.byKey(const Key('replyUsage-$_runA')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('replyUsageSheet')), findsOneWidget);
      expect(find.text('What this reply cost'), findsWidgets);
      expect(find.text('Model input'), findsOneWidget);
      expect(find.text('Model output'), findsOneWidget);
      expect(find.byKey(const Key('replyUsageOpenRun')), findsOneWidget);
    },
  );

  testWidgets('on: own keys and helper runs show as such', (tester) async {
    SharedPreferences.setMockInitialValues({'chat.showUsage': true});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'a1',
          role: 'assistant',
          text: 'Done.',
          createdAt: DateTime(2026),
          runId: _runA,
        ),
      ]
      ..usageOfRun = RunUsage(
        runId: _runA,
        status: RunStatus.completed,
        costUsd: 0.5,
        chargedUsd: 0,
        tokensIn: 0,
        tokensOut: 0,
        durationMs: null,
        toolCalls: 0,
        subruns: 2,
        items: [
          RunUsageItemsInner(
            kind: 'computer_seconds',
            model: null,
            source_: RunUsageItemsInnerSource_Enum.key,
            billable: false,
            quantity: 90,
            costUsd: 0.5,
          ),
        ],
      );
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    expect(find.text(r'$0.5000 on your keys'), findsOneWidget);
    await tester.tap(find.byKey(const Key('replyUsage-$_runA')));
    await tester.pumpAndSettle();
    expect(find.text('Includes 2 helper runs'), findsOneWidget);
    expect(find.text('Cloud computer time'), findsOneWidget);
    expect(find.textContaining('1m 30s'), findsOneWidget);
  });

  for (final owner in [false, true]) {
  testWidgets('our cost and margin: ${owner ? 'shown to the instance owner' : 'hidden from everyone else'} (D-395)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'chat.showUsage': true});
    await setSize(tester, const Size(500, 900));
    RunUsage usage({num? upstream}) => RunUsage(
      runId: _runA,
      status: RunStatus.completed,
      costUsd: 0.042,
      chargedUsd: 0.042,
      upstreamCostUsd: upstream,
      tokensIn: 1000,
      tokensOut: 200,
      durationMs: null,
      toolCalls: 0,
      subruns: 0,
      items: [
        RunUsageItemsInner(
          kind: 'tokens_in',
          model: 'm',
          source_: RunUsageItemsInnerSource_Enum.key,
          billable: true,
          quantity: 1000,
          costUsd: 0.042,
          upstreamCostUsd: upstream,
        ),
      ],
    );
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'a1',
          role: 'assistant',
          text: 'Done.',
          createdAt: DateTime(2026),
          runId: _runA,
        ),
      ]
      ..usageOfRun = usage(upstream: owner ? 0.03 : null);
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('replyUsage-$_runA')));
    await tester.pumpAndSettle();
    if (!owner) {
      expect(find.byKey(const Key('replyUsageAdmin')), findsNothing);
      expect(find.textContaining('Our cost'), findsNothing);
      return;
    }
    // The instance owner's copy carries the server's cost.
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('replyUsageOurCost'))).data,
      r'$0.0300',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('replyUsageMargin'))).data,
      r'$0.0120',
    );
    expect(find.textContaining(r'Our cost $0.0300'), findsOneWidget);
  });
  }

  testWidgets('on: the line counts up while the bot works', (tester) async {
    SharedPreferences.setMockInitialValues({'chat.showUsage': true});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'Hi');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController
      ..add(
        ev(1, 'run.started', {
          'trigger': 'chat',
          'model': 'm',
          'computer_id': null,
        }),
      )
      ..add(
        ev(2, 'message.delta', {'message_id': 'live1', 'text': 'Hello there'}),
      )
      ..add(
        ev(3, 'usage', {
          'tokens_in': 1000,
          'tokens_out': 50,
          'cost_usd': 0.0021,
        }),
      );
    await tester.pump();
    expect(find.text(r'$0.0021 so far · 1.05K tokens'), findsOneWidget);
    // Live numbers come from the chat's events; the server isn't asked until the run ends.
    expect(backend.usageAsked, isEmpty);
  });

  test('durations read short', () {
    expect(formatRunDuration(const Duration(milliseconds: 900)), '0.9s');
    expect(formatRunDuration(const Duration(seconds: 32)), '32s');
    expect(formatRunDuration(const Duration(minutes: 2, seconds: 5)), '2m 5s');
    expect(formatRunDuration(const Duration(minutes: 3)), '3m');
    expect(formatRunDuration(const Duration(hours: 1, minutes: 4)), '1h 4m');
  });
}

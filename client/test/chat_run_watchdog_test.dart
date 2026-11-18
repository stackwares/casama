// A chat that stops hearing its run catches up on its own: a stalled stream or a reload that failed
// half-way never leaves "Thinking…" on screen while the run waits on an approval nobody can see.
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

RunEventItem ev(int seq, String type, Map<String, dynamic> payload) =>
    RunEventItem.fromJson({
      'v': 1,
      'run_id': runId,
      'seq': seq,
      'ts': '2026-11-18T08:41:00.000Z',
      'bot_id': botId,
      'type': type,
      'payload': payload,
    });

RunEventItem delta(int seq, String text) => ev(seq, 'message.delta', {
  'message_id': '66666666-6666-4666-8666-666666666666',
  'text': text,
});

RunEventItem approval(int seq) => ev(seq, 'approval.requested', {
  'approval_id': '77777777-7777-4777-8777-777777777777',
  'tool': 'shell.exec',
  'args_redacted': {'command': 'ls'},
  'risk': 'high',
  'expires_at': '2026-11-19T08:41:00.000Z',
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  FakeBackend running() => FakeBackend()
    ..runStatus = RunStatus.waitingApproval
    ..activeRunId = runId
    ..storedMessages = [
      ChatMessageView(
        id: 'm-ask',
        role: 'user',
        text: 'Edit the dates',
        createdAt: DateTime(2026, 11, 18),
      ),
    ];

  Future<(ProviderContainer, ChatController)> openChat(
    WidgetTester tester,
    FakeBackend fake,
  ) async {
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(fake)],
    );
    final c = container.read(chatControllerProvider(botId).notifier);
    await c.open(convId);
    expect(fake.watchRunCalls.single.afterSeq, 0);
    for (var i = 1; i <= 3; i++) {
      fake.runEventsController.add(delta(i, 'word$i '));
    }
    await tester.pump();
    return (container, c);
  }

  testWidgets(
    'a stream that fell behind the server follows the run again from the last event shown',
    (tester) async {
      final fake = running()..runLastSeq = 5;
      final (container, _) = await openChat(tester, fake);
      await tester.pump(const Duration(seconds: 25));
      await tester.pump();
      expect(fake.watchRunCalls, hasLength(2));
      expect(fake.watchRunCalls.last.afterSeq, 3);
      // The approval the run is waiting on now reaches the chat.
      fake.runEventsController.add(approval(4));
      await tester.pump();
      final state = container.read(chatControllerProvider(botId));
      expect(state.entries.last, isA<ApprovalEntry>());
      expect(state.running, isTrue);
      container.dispose();
    },
  );

  testWidgets('a run that is only quiet is left alone', (tester) async {
    final fake = running()..runLastSeq = 3;
    final (container, _) = await openChat(tester, fake);
    await tester.pump(const Duration(minutes: 3));
    expect(fake.watchRunCalls, hasLength(1));
    container.dispose();
  });

  testWidgets('a reload that fails mid-run does not leave the run unfollowed', (
    tester,
  ) async {
    final fake = running()..runLastSeq = 3;
    final (container, c) = await openChat(tester, fake);
    fake.offline = true;
    await c.open(convId);
    expect(container.read(chatControllerProvider(botId)).running, isTrue);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(fake.watchRunCalls, hasLength(2));
    expect(fake.watchRunCalls.last.afterSeq, 3);
    container.dispose();
  });

  testWidgets(
    'a reply taken back for a second look says the bot is checking its work',
    (tester) async {
      final fake = running()..runLastSeq = 3;
      final (container, _) = await openChat(tester, fake);
      fake.runEventsController.add(
        ev(4, 'message.completed', {
          'message_id': '66666666-6666-4666-8666-666666666666',
          'content': <Object>[],
        }),
      );
      await tester.pump();
      var state = container.read(chatControllerProvider(botId));
      expect(
        state.entries.whereType<MessageEntry>().where(
          (m) => m.role == 'assistant',
        ),
        isEmpty,
      );
      expect(state.rechecking, isTrue);
      fake.runEventsController.add(
        ev(5, 'tool.started', {
          'call_id': 'c1',
          'tool': 'shell.exec',
          'args_redacted': {'command': 'ls'},
        }),
      );
      await tester.pump();
      state = container.read(chatControllerProvider(botId));
      expect(state.rechecking, isFalse);
      container.dispose();
    },
  );
}

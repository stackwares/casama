// One bot, several chats, several devices (D-413): what a chat does while another one is opened,
// while it is still loading, and while the person's other device sends into it.
import 'dart:async';

import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

const _a = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _b = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

ChatMessageView _msg(String id, String role, String text, [String? runId]) =>
    ChatMessageView(
      id: id,
      role: role,
      text: text,
      runId: runId,
      createdAt: DateTime(2026, 11, 1),
    );

/// A backend with a thread, a working run and a run stream per conversation, and gates to hold a
/// load or a send while something else happens.
class _Backend extends FakeBackend {
  final threads = <String, List<ChatMessageView>>{};
  final working = <String, String?>{};
  final loadGates = <String, Completer<void>>{};
  Completer<void>? sendGate;
  final sentTo = <String>[];
  final created = <String>[];
  final watched = <String>[];
  final loads = <String>[];
  final streams = <String, StreamController<RunEventItem>>{};

  StreamController<RunEventItem> streamOf(String run) =>
      streams[run] ??= StreamController<RunEventItem>.broadcast();

  @override
  Future<List<ChatMessageView>> messages(
    String conversationId, {
    int? limit,
    String? before,
    String? around,
  }) async {
    loads.add(conversationId);
    await loadGates[conversationId]?.future;
    return threads[conversationId] ?? const [];
  }

  @override
  Future<String?> activeRun(String conversationId) async =>
      working[conversationId];

  @override
  Future<Conversation> createConversation(String botId) async {
    created.add(botId);
    return super.createConversation(botId);
  }

  @override
  Future<SendMessageResponse> send(
    String conversationId,
    String text, {
    List<AttachmentRef> attachments = const [],
    Map<String, Object?>? uiAction,
    List<String> skills = const [],
    String? idempotencyKey,
  }) async {
    sentTo.add(conversationId);
    await sendGate?.future;
    return SendMessageResponse(
      messageId: 'sent-${sentTo.length}',
      runId: 'run-of-$conversationId',
      conversationId: conversationId,
    );
  }

  @override
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0}) {
    watched.add(runId);
    return streamOf(runId).stream;
  }
}

void main() {
  (ProviderContainer, _Backend, ChatController) chat() {
    final backend = _Backend()
      ..threads[_a] = [_msg('a1', 'assistant', 'Topic A so far')]
      ..threads[_b] = [_msg('b1', 'assistant', 'Topic B so far')];
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);
    container.listen(chatControllerProvider(botId), (_, _) {});
    return (
      container,
      backend,
      container.read(chatControllerProvider(botId).notifier),
    );
  }

  ChatState stateOf(ProviderContainer c) =>
      c.read(chatControllerProvider(botId));
  List<String> texts(ProviderContainer c) => [
    for (final e in stateOf(c).entries)
      if (e is MessageEntry) e.text,
  ];
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('a send that comes back after another topic was opened is not followed in that topic', () async {
    final (c, backend, controller) = chat();
    await controller.open(_a);
    backend.sendGate = Completer<void>();
    final sending = controller.send('Research hotels');
    await settle();
    expect(texts(c), ['Topic A so far', 'Research hotels']);

    // The person taps the other topic before the server has answered the send.
    await controller.open(_b);
    expect(texts(c), ['Topic B so far']);
    backend.sendGate!.complete();
    await sending;
    await settle();

    // Topic B shows nothing of topic A's run: no working state, no Stop button for it.
    expect(stateOf(c).conversationId, _b);
    expect(stateOf(c).running, isFalse);
    expect(backend.watched, isEmpty);
    expect(texts(c), ['Topic B so far']);

    // Back in topic A the message is there and its run is followed.
    backend.threads[_a] = [
      ...backend.threads[_a]!,
      _msg('sent-1', 'user', 'Research hotels', 'run-of-$_a'),
    ];
    backend.working[_a] = 'run-of-$_a';
    await controller.open(_a);
    expect(texts(c), ['Topic A so far', 'Research hotels']);
    expect(stateOf(c).activeRunId, 'run-of-$_a');
  });

  test('a send that fails after another topic was opened waits in its own topic with Try Again', () async {
    final (c, backend, controller) = chat();
    await controller.open(_a);
    backend.sendGate = Completer<void>();
    final sending = controller.send('Research hotels');
    await settle();
    await controller.open(_b);
    backend.sendGate!.completeError(StateError('refused'));
    await expectLater(sending, throwsStateError);
    expect(texts(c), ['Topic B so far']);

    await controller.open(_a);
    final mine = stateOf(c).entries.whereType<MessageEntry>().last;
    expect(mine.text, 'Research hotels');
    expect(mine.failed, isTrue);
  });

  test('opening one topic and then another shows the second, whichever loads first', () async {
    final (c, backend, controller) = chat();
    backend.working[_a] = 'run-of-$_a';
    backend.loadGates[_a] = Completer<void>();
    final first = controller.open(_a);
    await settle();
    await controller.open(_b);
    // Topic A's slow load finishes now, with its working run.
    backend.loadGates[_a]!.complete();
    await first;
    await settle();
    expect(stateOf(c).conversationId, _b);
    expect(texts(c), ['Topic B so far']);
    expect(stateOf(c).running, isFalse);
    expect(backend.watched, isEmpty);
  });

  test(
    'a message sent while its chat is still loading goes to that chat',
    () async {
      final (c, backend, controller) = chat();
      backend.loadGates[_a] = Completer<void>();
      final opening = controller.open(_a);
      await settle();
      expect(stateOf(c).loading, isTrue);
      final sending = controller.send('Are you there?');
      await settle();
      expect(backend.sentTo, isEmpty);
      backend.loadGates[_a]!.complete();
      await opening;
      await sending;
      // It did not start a new conversation because no id was known yet.
      expect(backend.created, isEmpty);
      expect(backend.sentTo, [_a]);
      expect(texts(c), ['Topic A so far', 'Are you there?']);
    },
  );

  test(
    'a new chat started while another was loading stays the new chat',
    () async {
      final (c, backend, controller) = chat();
      backend.loadGates[_a] = Completer<void>();
      final opening = controller.open(_a);
      await settle();
      await controller.newChat();
      backend.loadGates[_a]!.complete();
      await opening;
      await settle();
      expect(stateOf(c).conversationId, isNull);
      expect(stateOf(c).entries, isEmpty);
    },
  );

  test("a message from the person's other device shows while the bot works, and the steps stay", () async {
    final (c, backend, controller) = chat();
    backend.threads[_a] = [_msg('a1', 'user', 'Plan the trip', 'run-1')];
    backend.working[_a] = 'run-1';
    await controller.open(_a);
    expect(stateOf(c).activeRunId, 'run-1');
    backend
        .streamOf('run-1')
        .add(
          ev(1, 'tool.started', {
            'call_id': 'c1',
            'tool': 'web.search',
            'args_redacted': <String, dynamic>{},
          }),
        );
    await settle();
    expect(stateOf(c).entries.whereType<ToolEntry>(), hasLength(1));

    // The desktop sends into the same chat. The message joins the run that is working, so no
    // run starts; only the message itself is announced.
    backend.threads[_a] = [
      ...backend.threads[_a]!,
      _msg('a2', 'user', 'Make it four nights', 'run-1'),
    ];
    backend.activity.add(const ConversationActivity.message('a2'));
    await settle();
    expect(texts(c), ['Plan the trip', 'Make it four nights']);
    expect(stateOf(c).entries.whereType<ToolEntry>(), hasLength(1));
    expect(stateOf(c).activeRunId, 'run-1');

    // Announced twice (a reconnect): it is on screen once.
    backend.activity.add(const ConversationActivity.message('a2'));
    await settle();
    expect(texts(c), ['Plan the trip', 'Make it four nights']);
  });

  test(
    'what was added while a run was on screen is there when it ends',
    () async {
      final (c, backend, controller) = chat();
      backend.threads[_a] = [_msg('a1', 'user', 'Plan the trip', 'run-1')];
      backend.working[_a] = 'run-1';
      await controller.open(_a);
      // A message this device never heard about (a server from before the announcement).
      backend.threads[_a] = [
        ...backend.threads[_a]!,
        _msg('a2', 'user', 'Make it four nights', 'run-1'),
        _msg('r1', 'assistant', 'Four nights, booked.', 'run-1'),
      ];
      backend.working[_a] = null;
      backend.streamOf('run-1')
        ..add(
          ev(1, 'message.delta', {
            'message_id': 'r1',
            'text': 'Four nights, booked.',
          }),
        )
        ..add(
          ev(2, 'message.completed', {
            'message_id': 'r1',
            'content': [
              {'type': 'text', 'text': 'Four nights, booked.'},
            ],
          }),
        )
        ..add(ev(3, 'run.completed', {'final_message_id': 'r1'}));
      await settle();
      await backend.streamOf('run-1').close();
      await settle();
      expect(stateOf(c).running, isFalse);
      expect(texts(c), [
        'Plan the trip',
        'Make it four nights',
        'Four nights, booked.',
      ]);
    },
  );

  test(
    'a run whose stream ends without saying how leaves nothing thinking',
    () async {
      final (c, backend, controller) = chat();
      backend.threads[_a] = [_msg('a1', 'user', 'Plan the trip', 'run-1')];
      backend.working[_a] = 'run-1';
      await controller.open(_a);
      backend
          .streamOf('run-1')
          .add(ev(1, 'message.delta', {'message_id': 'r1', 'text': 'Looking'}));
      await settle();
      expect(
        stateOf(c).entries.whereType<MessageEntry>().last.streaming,
        isTrue,
      );

      // The server ended the run and closed the stream; no run.completed or run.failed came.
      backend.working[_a] = null;
      final before = backend.loads.length;
      await backend.streamOf('run-1').close();
      await settle();
      expect(stateOf(c).running, isFalse);
      expect(
        stateOf(c).entries.whereType<MessageEntry>().where((m) => m.streaming),
        isEmpty,
      );
      // The saved thread is read again, to show how it ended.
      expect(backend.loads.length, greaterThan(before));
    },
  );
}

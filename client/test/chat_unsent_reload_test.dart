// A message that didn't reach the server stays in the chat when the thread reloads (Fix 11).
import 'dart:async';

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  (ProviderContainer, FakeBackend, ChatController) setUpChat() {
    final backend = FakeBackend()
      ..storedMessages = [ChatMessageView(id: 'm-1', role: 'assistant', text: 'Hello', createdAt: DateTime(2026))];
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    container.listen(chatControllerProvider(botId), (_, _) {});
    return (container, backend, container.read(chatControllerProvider(botId).notifier));
  }

  List<MessageEntry> messages(ProviderContainer c) => c.read(chatControllerProvider(botId)).entries.whereType<MessageEntry>().toList();

  test('a failed message is still there, with Try Again, after the thread reloads', () async {
    final (container, backend, c) = setUpChat();
    await c.open(convId);
    backend.failNextSend = Exception('connection refused');
    await expectLater(c.send('Book the hotel', skills: ['travel']), throwsException);
    expect(messages(container).last.failed, isTrue);

    // Another device sent something, a routine posted: the chat reloads.
    await c.open(convId);
    final kept = messages(container).last;
    expect(kept.text, 'Book the hotel');
    expect(kept.failed, isTrue);

    await c.resend(kept.id);
    expect(backend.sent, ['Book the hotel']);
    expect(backend.sentSkills.last, ['travel']);
  });

  test('it is still there after looking at another chat and coming back', () async {
    final (container, backend, c) = setUpChat();
    await c.open(convId);
    backend.failNextSend = Exception('connection refused');
    await expectLater(c.send('Book the hotel'), throwsException);
    await c.open('other-chat');
    expect(messages(container).where((m) => m.failed), isEmpty);
    await c.open(convId);
    expect(messages(container).last.text, 'Book the hotel');
    expect(messages(container).last.failed, isTrue);
  });

  test('a message still waiting for its files stays through a reload', () async {
    final (container, _, c) = setUpChat();
    await c.open(convId);
    final uploads = Completer<bool>();
    const file = AttachmentRef(path: 'uploads/a.png', name: 'a.png', mimeType: 'image/png', size: 3);
    final sending = c.send('Look at this', attachments: [file], uploads: uploads.future);
    await Future<void>.delayed(Duration.zero);
    await c.open(convId);
    expect(messages(container).last.text, 'Look at this');
    expect(messages(container).last.uploading, isTrue);
    uploads.complete(true);
    await sending;
  });
}

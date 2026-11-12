import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';

import 'fake_backend.dart';

const photo = AttachmentRef(
  path: 'workspace/uploads/20261112-a.jpg',
  name: 'a.jpg',
  mimeType: 'image/jpeg',
  size: 10,
);

void main() {
  test('a message sent while its photo uploads shows at once and goes out when the photo is up', () async {
    final backend = FakeBackend();
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);
    final c = container.read(chatControllerProvider(botId).notifier);
    await c.open(convId);

    final upload = Completer<bool>();
    final first = c.send(
      'What is in this photo?',
      attachments: [photo],
      uploads: upload.future,
    );
    await pumpEventQueue();
    MessageEntry last() => container
        .read(chatControllerProvider(botId))
        .entries
        .whereType<MessageEntry>()
        .last;
    expect(last().text, 'What is in this photo?');
    expect(last().uploading, isTrue);
    expect(backend.sent, isEmpty);

    // A message typed meanwhile waits its turn instead of overtaking the photo.
    final second = c.send('And make it brighter');
    await pumpEventQueue();
    expect(backend.sent, isEmpty);

    upload.complete(true);
    await first;
    await second;
    expect(backend.sent, ['What is in this photo?', 'And make it brighter']);
    expect(backend.sentAttachments.first.single.path, photo.path);
    expect(
      container
          .read(chatControllerProvider(botId))
          .entries
          .whereType<MessageEntry>()
          .where((m) => m.uploading),
      isEmpty,
    );
  });

  test(
    'if the photo fails to upload, the message is taken back and not sent',
    () async {
      final backend = FakeBackend();
      final container = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(backend)],
      );
      addTearDown(container.dispose);
      final c = container.read(chatControllerProvider(botId).notifier);
      await c.open(convId);

      await expectLater(
        c.send('Look', attachments: [photo], uploads: Future.value(false)),
        throwsA(isA<UploadsFailed>()),
      );
      expect(backend.sent, isEmpty);
      expect(
        container
            .read(chatControllerProvider(botId))
            .entries
            .whereType<MessageEntry>()
            .where((m) => m.text == 'Look'),
        isEmpty,
      );
    },
  );
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/plain_text.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_sdk/casama_sdk.dart' hide GalleryItem;

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test('the preview gets fewer lines as the chats list fills up', () {
    expect(
      [
        for (final n in [0, 1, 2, 3, 4, 9]) chatPreviewLines(n),
      ],
      [3, 3, 2, 2, 1, 1],
    );
  });

  test('a preview is plain words on one run of text', () {
    expect(
      plainPreview(
        '## Plan\n\n**Water** the [fern](https://x.y) and `prune`.\n\n- Monday',
      ),
      'Plan Water the fern and prune. Monday',
    );
    expect(plainPreview('Hi!\n\n\nHow are you?'), 'Hi! How are you?');
    // Nothing but code still shows something.
    expect(plainPreview('```sh\nls -la\n```'), 'ls -la');
  });

  Future<int?> previewLines(WidgetTester tester, FakeBackend backend) async {
    await setSize(tester, const Size(500, 1000));
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotsList())));
    await tester.pumpAndSettle();
    return tester
        .widget<Text>(find.byKey(const Key('bot-preview-$botId')))
        .maxLines;
  }

  FakeBackend withBots(int extra) {
    final backend = FakeBackend()
      ..lastMessage = BotLastMessage(
        text: '**Hi!**\n\nI can plan your week.',
        from: BotLastMessageFromEnum.bot,
        fileName: null,
        fileMime: null,
        conversationId: 'c1',
        at: DateTime(2026),
      );
    for (var i = 0; i < extra; i++) {
      backend.extraBots.add(backend.bot(id: 'bot-$i', name: 'Bot $i'));
    }
    return backend;
  }

  testWidgets('one bot gets a three-line preview, in plain words', (
    tester,
  ) async {
    final backend = withBots(0);
    expect(await previewLines(tester, backend), 3);
    expect(find.text('Hi! I can plan your week.'), findsOneWidget);
  });

  testWidgets('a few bots get two lines', (tester) async {
    expect(await previewLines(tester, withBots(2)), 2);
  });

  testWidgets('four bots get one line', (tester) async {
    expect(await previewLines(tester, withBots(3)), 1);
  });

  testWidgets('group chats count towards how full the list is', (tester) async {
    final backend = withBots(1);
    await backend.createGroupChat(botId, ['bot-0']);
    await backend.createGroupChat(botId, ['bot-0']);
    expect(await previewLines(tester, backend), 1);
  });
}

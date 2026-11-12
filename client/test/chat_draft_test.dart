import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

String inputText(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(const Key('messageInput')))
    .controller!
    .text;

void main() {
  testWidgets('a half-written message is still there after leaving the chat', (
    tester,
  ) async {
    await setSize(tester, const Size(700, 900));
    final cache = MemoryCache();
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        const ChatScreen(botId: botId, conversationId: convId),
        cache: cache,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('messageInput')),
      'Remind me to call the bank',
    );
    await tester.pumpAndSettle();

    // Closing the chat before the save timer runs still keeps it.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      harness(
        backend,
        const ChatScreen(botId: botId, conversationId: convId),
        cache: cache,
      ),
    );
    await tester.pumpAndSettle();
    expect(inputText(tester), 'Remind me to call the bank');

    // Sending clears it, so the next visit starts empty.
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump(const Duration(seconds: 1));
    expect(inputText(tester), isEmpty);
    expect(cache.data['draft:$botId:$convId'], anyOf(isNull, 'null'));
  });
}

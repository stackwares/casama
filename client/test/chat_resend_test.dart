// A message that didn't reach the server stays in the chat, marked, with Try Again and Remove.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<FakeBackend> _sendFailing(WidgetTester tester, String text) async {
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend()..failNextSend = Exception('connection refused');
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('messageInput')), text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendButton')));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Try Again sends the same message without typing it again', (
    tester,
  ) async {
    final backend = await _sendFailing(tester, 'Book the Sapporo hotel');
    expect(backend.sent, isEmpty);
    expect(find.byKey(const Key('notSentNote')), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resendMessage')));
    // The bot starts working, so the screen keeps animating: pump instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.sent, ['Book the Sapporo hotel']);
    expect(find.byKey(const Key('notSentNote')), findsNothing);
    expect(find.text('Book the Sapporo hotel'), findsOneWidget);
  });

  testWidgets('Remove drops a message that was not sent', (tester) async {
    final backend = await _sendFailing(tester, 'Never mind this one');
    await tester.tap(find.byKey(const Key('discardMessage')));
    await tester.pumpAndSettle();
    expect(find.text('Never mind this one'), findsNothing);
    expect(backend.sent, isEmpty);
  });
}

// A chat that can't load says so and offers Try Again, instead of placeholder bubbles forever.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a chat that fails to load shows an error, and Try Again loads it', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..offline = true
      ..storedMessages = [ChatMessageView(id: 'm-1', role: 'assistant', text: 'Here is the plan', createdAt: DateTime(2026))];
    // Nothing saved on the device (always the case on the web).
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();

    expect(find.byType(ChatThreadSkeleton), findsNothing);
    expect(find.byKey(const Key('chatLoadError')), findsOneWidget);

    backend.offline = false;
    await tester.tap(find.byKey(const Key('chatLoadRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatLoadError')), findsNothing);
    expect(find.text('Here is the plan'), findsOneWidget);
  });

  testWidgets('the most recent chat failing to load shows the error too', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..offline = true;
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byType(ChatThreadSkeleton), findsNothing);
    expect(find.byKey(const Key('chatLoadError')), findsOneWidget);
  });
}

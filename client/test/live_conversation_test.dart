// An open chat follows runs that start in it from another device (D-224).
import 'package:casama_app/core/backend.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'a message sent from another phone shows up, and its reply streams in',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend()
        ..storedMessages = [
          ChatMessageView(
            id: 'm1',
            role: 'user',
            text: 'Morning',
            createdAt: DateTime(2026, 11, 1),
          ),
        ];
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();
      expect(backend.watchedConversations, contains(convId));

      // The iPhone sends: the server stores the message and starts a run.
      backend
        ..storedMessages = [
          ...backend.storedMessages,
          ChatMessageView(
            id: 'm2',
            role: 'user',
            text: 'Book the Sapporo hotel',
            createdAt: DateTime(2026, 11, 1, 0, 5),
          ),
        ]
        ..activeRunId = 'run-from-iphone';
      backend.conversationActivity.add('run-from-iphone');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('Book the Sapporo hotel'), findsOneWidget);

      backend.runEventsController.add(
        ev(1, 'message.delta', {
          'message_id': 'a1',
          'text': 'Booked: 3 nights from Friday.',
        }),
      );
      await tester.pump();
      expect(
        find.textContaining('Booked: 3 nights', findRichText: true),
        findsOneWidget,
      );
    },
  );
}

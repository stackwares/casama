import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('opening the keyboard keeps the latest message in view', (
    tester,
  ) async {
    await setSize(tester, const Size(390, 844));
    final b = FakeBackend()
      ..storedMessages = [
        for (var i = 0; i < 30; i++)
          ChatMessageView(
            id: 'm$i',
            role: i.isEven ? 'user' : 'assistant',
            text: 'Message number $i',
            createdAt: DateTime(2026, 11, 1, 0, i),
          ),
      ];
    await tester.pumpWidget(
      harness(b, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();

    final list = find.byType(ListView).first;
    bool latestVisible() {
      final latest = find.text('Message number 29', findRichText: true);
      if (latest.evaluate().isEmpty) return false;
      return tester.getRect(latest).bottom <= tester.getRect(list).bottom;
    }

    expect(latestVisible(), isTrue);

    // The keyboard opens in steps, like the real animation.
    for (final inset in [100.0, 200.0, 320.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump();
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(latestVisible(), isTrue);
  });
}

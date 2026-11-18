import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Starter requests in an empty chat (D-338).
void main() {
  ChatStarters starters({bool refreshing = false}) => ChatStarters(
        items: [
          ChatStarter(emoji: '🌱', text: 'Plan a calm Sunday for me'),
          ChatStarter(emoji: '📬', text: 'Sum up my unread emails'),
          ChatStarter(emoji: '🧁', text: 'Find a quick cupcake recipe'),
          ChatStarter(emoji: '🎁', text: 'Help me pick a birthday gift'),
        ],
        source_: ChatStartersSource_Enum.ai,
        refreshing: refreshing,
      );

  testWidgets('shows the starters written for the person, and a tap sends one', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend()..starters = starters();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(backend.startersAsked, [botId]);
    expect(find.text('Plan a calm Sunday for me'), findsOneWidget);
    expect(find.text('Help me pick a birthday gift'), findsOneWidget);
    // The app's own everyday ones aren't shown beside them.
    expect(find.text('Help me plan my day'), findsNothing);
    await tester.tap(find.byKey(const Key('suggestion-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.sent.last, contains('Find a quick cupcake recipe'));
  });

  testWidgets('without the server it shows everyday starters, not computer ones', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Help me plan my day'), findsOneWidget);
    expect(find.text('What can you help me with?'), findsOneWidget);
    expect(find.textContaining('computer'), findsNothing);
    expect(find.textContaining('workspace'), findsNothing);
  });

  testWidgets('while a new list is written it asks again and the new list replaces the old', (tester) async {
    await setSize(tester, const Size(600, 900));
    final backend = FakeBackend()
      ..starters = ChatStarters(
        items: [
          ChatStarter(emoji: '☀️', text: 'Help me plan my day'),
          ChatStarter(emoji: '✍️', text: 'Help me write a message'),
          ChatStarter(emoji: '🔎', text: 'Look something up and explain it simply'),
          ChatStarter(emoji: '⏰', text: 'Remind me about something later'),
        ],
        source_: ChatStartersSource_Enum.rules,
        refreshing: true,
      );
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Remind me about something later'), findsOneWidget);
    backend.starters = starters();
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(backend.startersAsked.length, 2);
    expect(find.text('Plan a calm Sunday for me'), findsOneWidget);
    expect(find.text('Remind me about something later'), findsNothing);
  });
}

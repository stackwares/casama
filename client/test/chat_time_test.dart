// When messages were sent (D-387): a label where the day changes or after a pause of an hour or
// more, and the exact time in a message's menu, never a time under every bubble.
import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/chat_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// intl puts a narrow no-break space before AM/PM.
String _plain(String s) => s.replaceAll('\u202f', ' ');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('chatTimeBreak', () {
    final at = DateTime(2026, 11, 18, 15, 42);
    test('the first message shown starts with its day', () => expect(chatTimeBreak(null, at), ChatTimeBreak.day));
    test('a new day gets a day label, even minutes later', () {
      expect(chatTimeBreak(DateTime(2026, 11, 17, 23, 58), DateTime(2026, 11, 18, 0, 3)), ChatTimeBreak.day);
    });
    test('a pause of an hour or more gets the time', () {
      expect(chatTimeBreak(at.subtract(const Duration(hours: 1)), at), ChatTimeBreak.gap);
      expect(chatTimeBreak(at.subtract(const Duration(minutes: 59)), at), isNull);
    });
  });

  testWidgets('labels: today, yesterday, a weekday date, and the year for another year', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(harness(FakeBackend(), Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    await tester.pumpAndSettle();
    final now = DateTime(2026, 11, 18, 18);
    expect(chatDayLabel(ctx, DateTime(2026, 11, 18, 9), now: now), 'Today');
    expect(chatDayLabel(ctx, DateTime(2026, 11, 17, 9), now: now), 'Yesterday');
    expect(chatDayLabel(ctx, DateTime(2026, 11, 16, 9), now: now), 'Mon, Nov 16');
    expect(chatDayLabel(ctx, DateTime(2025, 11, 16, 9), now: now), 'Sun, Nov 16, 2025');
    expect(_plain(chatTimeLabel(ctx, ChatTimeBreak.day, DateTime(2026, 11, 18, 15, 42), now: now)), 'Today · 3:42 PM');
    expect(_plain(chatTimeLabel(ctx, ChatTimeBreak.gap, DateTime(2026, 11, 18, 15, 42), now: now)), '3:42 PM');
    expect(_plain(messageSentLabel(ctx, DateTime(2026, 11, 17, 9, 5), now: now)), 'Yesterday at 9:05 AM');
  });

  testWidgets('the chat shows a label per day and after a long pause, not per message', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(id: 'm-1', role: 'user', text: 'Monday question', createdAt: DateTime(2024, 11, 18, 9, 0)),
        ChatMessageView(id: 'm-2', role: 'assistant', text: 'Monday answer', createdAt: DateTime(2024, 11, 18, 9, 1)),
        // Same day, a few minutes on: no label.
        ChatMessageView(id: 'm-3', role: 'user', text: 'Follow-up', createdAt: DateTime(2024, 11, 18, 9, 10)),
        // Same day, hours on: the time.
        ChatMessageView(id: 'm-4', role: 'user', text: 'Afternoon', createdAt: DateTime(2024, 11, 18, 14, 30)),
        // Another day.
        ChatMessageView(id: 'm-5', role: 'user', text: 'Next day', createdAt: DateTime(2024, 11, 19, 8, 15)),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatTimeDivider')), findsNWidgets(3));
    final labels = [for (final t in tester.widgetList<Text>(find.byKey(const Key('chatTimeDivider')))) _plain(t.data!)];
    // The list may be laid out newest first; a past year's days carry the year.
    expect(labels, unorderedEquals(['Mon, Nov 18, 2024 · 9:00 AM', '2:30 PM', 'Tue, Nov 19, 2024 · 8:15 AM']));

    // The exact time sits at the top of a message's menu.
    await tester.longPress(find.text('Afternoon'));
    await tester.pumpAndSettle();
    final sent = tester.widget<Text>(find.descendant(of: find.byKey(const Key('msgSentAt')), matching: find.byType(Text)));
    expect(_plain(sent.data!), 'Mon, Nov 18, 2024 at 2:30 PM');
  });
}

// Deleting chats: from the chat's menu, from the history list, and every chat from bot settings.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/bot_profile_screen.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<FakeBackend> _openChat(
  WidgetTester tester, {
  bool canDelete = true,
}) async {
  await setSize(tester, const Size(900, 1000));
  final backend = FakeBackend()..canDeleteChats = canDelete;
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the chat menu deletes this chat after saying what stays', (
    tester,
  ) async {
    final backend = await _openChat(tester);
    await tester.tap(find.byKey(const Key('chatMoreMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteChat')));
    await tester.pumpAndSettle();
    expect(find.textContaining('stays in its memory'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDeleteChat')));
    await tester.pumpAndSettle();
    expect(backend.deletedConversations, [convId]);
    expect(find.text('Chat deleted'), findsOneWidget);
  });

  testWidgets(
    'no Delete for a chat someone else started in a bot you do not manage',
    (tester) async {
      await _openChat(tester, canDelete: false);
      await tester.tap(find.byKey(const Key('chatMoreMenu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deleteChat')), findsNothing);
    },
  );

  testWidgets('the history list deletes a chat from its row', (tester) async {
    final backend = await _openChat(tester);
    await tester.tap(find.byKey(const Key('chatMoreMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openConversations')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteConversation-$convId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteChat')));
    await tester.pumpAndSettle();
    expect(backend.deletedConversations, [convId]);
    expect(find.byKey(const Key('deleteConversation-$convId')), findsNothing);
  });

  testWidgets('bot settings deletes every chat with the bot', (tester) async {
    await setSize(tester, const Size(700, 2400));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const BotProfileScreen(botId: botId)),
    );
    await tester.pumpAndSettle();
    // The profile is a lazy list; scroll until the row at its end is built.
    await tester.scrollUntilVisible(
      find.byKey(const Key('deleteAllChats')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteAllChats')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteAllChats')));
    await tester.pumpAndSettle();
    expect(backend.clearedBots, [botId]);
    expect(find.text('1 chat deleted.'), findsOneWidget);
  });
}

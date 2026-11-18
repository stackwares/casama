// A group chat's working line: no stand-in "Assistant" while the app learns which bot took the
// turn, then one header for that bot and a Thinking line without a second face under it (D-118).
import 'dart:async';

import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:casama/features/groups/group_chats.dart';
import 'package:casama/ui/bot_avatar.dart';
import 'package:casama/core/backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the working line waits for the bot, then shows it once', (
    tester,
  ) async {
    await setSize(tester, const Size(1400, 900));
    final gate = Completer<void>();
    final backend = FakeBackend()
      ..extraBots.add(FakeBackend().bot(id: 'bot-b', name: 'Bea'))
      ..runGate = gate
      ..runBotId = 'bot-b'
      ..activeRunId = 'r-live'
      ..storedMessages = [
        ChatMessageView(
          id: 'm-ask',
          role: 'user',
          text: 'Hi there',
          createdAt: DateTime(2026, 11, 16),
        ),
      ];
    final g = await backend.createGroupChat(botId, ['bot-b']);
    await tester.pumpWidget(
      harness(backend, GroupChatScreen(conversationId: g.id)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Not known yet: nothing that would then change name and face.
    expect(find.byType(WorkingIndicator), findsNothing);
    expect(find.byType(BotTurnHeader), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.descendant(
        of: find.byType(BotTurnHeader),
        matching: find.text('Bea'),
      ),
      findsOneWidget,
    );
    final line = find.byType(WorkingIndicator);
    expect(line, findsOneWidget);
    expect(
      find.descendant(of: line, matching: find.byType(BotAvatar)),
      findsNothing,
    );
  });
}

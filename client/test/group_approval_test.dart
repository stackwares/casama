// A group chat's approvals and steps belong to the bot whose run it is, not the bot that leads the
// chat (D-118).
import 'dart:async';

import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:casama/features/groups/group_chats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('an approval in a group chat names the bot that is asking', (
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
          text: '@Bea share the page',
          createdAt: DateTime(2026, 11, 16),
        ),
      ];
    final g = await backend.createGroupChat(botId, ['bot-b']);
    await tester.pumpWidget(
      harness(backend, GroupChatScreen(conversationId: g.id)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    // The request arrives before the app has learned whose run it is.
    backend.runEventsController
      ..add(
        ev(1, 'tool.started', {
          'call_id': 'c1',
          'tool': 'pages.share',
          'args_redacted': {'visibility': 'public'},
        }),
      )
      ..add(
        ev(2, 'approval.requested', {
          'approval_id': 'appr1',
          'tool': 'pages.share',
          'args_redacted': {'visibility': 'public'},
          'risk': 'high',
          'expires_at': '2026-11-16T09:00:00.000Z',
        }),
      );
    await tester.pump(const Duration(milliseconds: 100));
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bea is asking first'), findsOneWidget);
    expect(find.text('Ada is asking first'), findsNothing);
    // One header, Bea's: the lead's name never heads Bea's step or request.
    final headers = find.byType(BotTurnHeader);
    expect(
      find.descendant(of: headers, matching: find.text('Bea')),
      findsWidgets,
    );
    expect(
      find.descendant(of: headers, matching: find.text('Ada')),
      findsNothing,
    );
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/groups/group_chats.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('creating a group chat picks bots, first one leads', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(onPressed: () => showNewGroupChat(context, ref), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-$botId')));
    await tester.pumpAndSettle();
    expect(find.text('Leads the group'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-bot-b')));
    await tester.enterText(find.byKey(const Key('groupTitle')), 'Launch crew');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createGroup')));
    await tester.pumpAndSettle();
    expect(backend.groups.single.botIds, [botId, 'bot-b']);
    expect(backend.groups.single.title, 'Launch crew');
  });

  testWidgets('an empty group chat says who is in it and how to reach them', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    final g = await backend.createGroupChat(botId, ['bot-b'], title: 'Launch crew');
    await tester.pumpWidget(harness(backend, GroupChatScreen(conversationId: g.id)));
    await tester.pumpAndSettle();
    expect(find.text('Launch crew'), findsWidgets);
    expect(find.byKey(const Key('groupHowItWorks')), findsOneWidget);
    expect(find.text('2 bots are in this chat. Each keeps its own memory and settings.'), findsOneWidget);
    // No one-bot starter requests in a group.
    expect(find.byKey(const Key('suggestion-0')), findsNothing);
    // A member's chip starts the message to them.
    await tester.tap(find.byKey(const Key('groupMention-bot-b')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('messageInput')), matching: find.text('@Bea '), matchRoot: true), findsOneWidget);
  });

  testWidgets('typing @ suggests the group bots and everyone', (tester) async {
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    final input = TextEditingController();
    addTearDown(input.dispose);
    final mentions = MentionController(input);
    addTearDown(mentions.dispose);
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: Column(
            children: [
              MentionPicker(botIds: const [botId, 'bot-b'], controller: mentions),
              Focus(onKeyEvent: (_, e) => mentions.handleKey(e), child: TextField(controller: input)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mentionPicker')), findsNothing);
    input.text = 'hi @B';
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mention-Bea')), findsOneWidget);
    expect(find.byKey(const Key('mention-Ada')), findsNothing);
    await tester.tap(find.byKey(const Key('mention-Bea')));
    await tester.pumpAndSettle();
    expect(input.text, 'hi @Bea ');
    input.text = '@';
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mention-everyone')), findsOneWidget);
    expect(find.byKey(const Key('mention-Ada')), findsOneWidget);
  });

  testWidgets('Tab completes the highlighted bot, arrows move, and the line says who will answer', (tester) async {
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    final input = TextEditingController();
    addTearDown(input.dispose);
    final mentions = MentionController(input);
    addTearDown(mentions.dispose);
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: Column(
            children: [
              MentionPicker(botIds: const [botId, 'bot-b'], controller: mentions),
              Focus(onKeyEvent: (_, e) => mentions.handleKey(e), child: TextField(key: const Key('in'), controller: input)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // No mention: the lead (first bot) answers.
    expect(find.textContaining('Ada will answer', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const Key('in')));
    await tester.enterText(find.byKey(const Key('in')), 'hey @');
    await tester.pumpAndSettle();
    // everyone, Ada, Bea: the arrow moves the highlight to Ada, Tab picks it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(input.text, 'hey @Ada ');
    await tester.enterText(find.byKey(const Key('in')), 'hey @Be');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(input.text, 'hey @Bea ');
    expect(find.textContaining('Bea will answer', findRichText: true), findsOneWidget);
  });
}

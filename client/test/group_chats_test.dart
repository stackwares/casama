import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/groups/group_chats.dart';
import 'package:casama/ui/shell_header.dart';

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

  testWidgets('the new group sheet lets you change the lead and take a bot out', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    backend.extraBots
      ..add(backend.bot(id: 'bot-b', name: 'Bea'))
      ..add(backend.bot(id: 'bot-c', name: 'Cy'));
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
    expect(find.text('Pick 2 more bots'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('createGroup'))).onPressed, isNull);
    for (final id in [botId, 'bot-b', 'bot-c']) {
      await tester.tap(find.byKey(Key('pick-$id')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('crew-bot-c')), findsOneWidget);
    // Cy becomes the lead; Bea leaves from the strip at the top.
    await tester.tap(find.byKey(const Key('crewLead-bot-c')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crewRemove-bot-b')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crew-bot-b')), findsNothing);
    await tester.tap(find.byKey(const Key('createGroup')));
    await tester.pumpAndSettle();
    expect(backend.groups.single.botIds, ['bot-c', botId]);
    expect(backend.groups.single.title, isNull);
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

  testWidgets('a group chat is headed by the group, with no topic controls', (tester) async {
    await setSize(tester, const Size(1400, 900));
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    final g = await backend.createGroupChat(botId, ['bot-b']);
    await tester.pumpWidget(harness(backend, GroupChatScreen(conversationId: g.id)));
    await tester.pumpAndSettle();
    // Unnamed, it goes by its bots' names, in the header as well as the empty thread.
    final header = find.byType(ShellHeader);
    expect(find.descendant(of: header, matching: find.byType(GroupAvatar)), findsOneWidget);
    expect(find.descendant(of: header, matching: find.text('Ada, Bea')), findsOneWidget);
    // The composer names the group too; the line above it says which bot answers.
    expect(find.text('Message Ada, Bea'), findsOneWidget);
    // A new topic or the topic list would belong to the lead bot alone and leave the group.
    expect(find.byKey(const Key('newChatButton')), findsNothing);
    // No computer panel beside a group chat, so no button to open one.
    expect(find.byKey(const Key('computerPanelToggle')), findsNothing);
    // Calls are with one bot: none in a group.
    expect(find.byKey(const Key('callButton')), findsNothing);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openConversations')), findsNothing);
    // One bot's profile would stand for the whole group: the menu lists the bots instead.
    expect(find.byKey(const Key('openBotProfile')), findsNothing);
    await tester.tap(find.byKey(const Key('openGroupMembers')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('groupMember-$botId')), findsOneWidget);
    expect(find.byKey(const Key('groupMember-bot-b')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('groupMember-$botId')), matching: find.text('Leads the group')), findsOneWidget);
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
    // Bots and apps share one list: the bots sit under their own heading, above apps to connect.
    expect(find.byType(ActionChip), findsNothing);
    final list = find.byKey(const Key('mentionPicker'));
    expect(find.descendant(of: list, matching: find.text('Bots')), findsOneWidget);
    expect(find.descendant(of: list, matching: find.byKey(const Key('mention-connect-stripe'))), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('mention-Bea'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('mention-connect-stripe'))).dy),
    );
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

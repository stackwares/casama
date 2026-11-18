import 'package:casama/app.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/home/last_chat.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

const _bo = '66666666-6666-4666-8666-666666666666';

Future<void> _open(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: const CasamaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

String _chatBot(WidgetTester tester) =>
    tester.widget<ChatScreen>(find.byType(ChatScreen)).botId;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the saved chat wins while it exists; else the most recent bot, else the first', () {
    final backend = FakeBackend();
    final ada = backend.bot();
    final bo = backend.bot(id: _bo, name: 'Bo');
    final group = Conversation(
      id: 'g1',
      botId: botId,
      title: 'All',
      lastMessageAt: null,
      createdAt: DateTime(2026),
      kind: ConversationKindEnum.group,
      botIds: [botId],
    );
    expect(
      chatToOpen(saved: '/bots/$_bo/chat', bots: [ada, bo], groups: const []),
      '/bots/$_bo/chat',
    );
    expect(
      chatToOpen(saved: '/groups/g1', bots: [ada, bo], groups: [group]),
      '/groups/g1',
    );
    // The bot or group is gone, or the saved text isn't a chat: the first bot (none has spoken).
    expect(
      chatToOpen(saved: '/bots/gone/chat', bots: [ada, bo], groups: const []),
      '/bots/$botId/chat',
    );
    expect(
      chatToOpen(saved: '/groups/g1', bots: [ada, bo], groups: const []),
      '/bots/$botId/chat',
    );
    expect(
      chatToOpen(saved: '/settings', bots: [ada, bo], groups: const []),
      '/bots/$botId/chat',
    );
    expect(chatToOpen(saved: null, bots: const [], groups: const []), isNull);
    // Whoever spoke last.
    backend.lastMessage = BotLastMessage(
      text: 'Hi',
      from: BotLastMessageFromEnum.bot,
      fileName: null,
      fileMime: null,
      conversationId: 'c1',
      at: DateTime(2026, 11, 18),
    );
    expect(
      chatToOpen(saved: null, bots: [bo, backend.bot()], groups: const []),
      '/bots/$botId/chat',
    );
  });

  testWidgets(
    'a wide window opens the chat last open on this device, and remembers the next one',
    (tester) async {
      await setSize(tester, const Size(1600, 1000));
      SharedPreferences.setMockInitialValues({
        'lastChat:$orgId': '/bots/$_bo/chat',
      });
      final backend = FakeBackend();
      backend.extraBots.add(backend.bot(id: _bo, name: 'Bo'));
      await _open(tester, backend);
      expect(_chatBot(tester), _bo);

      await tester.tap(find.byKey(const Key('sidebar-bot-$botId')));
      await tester.pumpAndSettle();
      expect(_chatBot(tester), botId);
      expect(
        (await SharedPreferences.getInstance()).getString('lastChat:$orgId'),
        '/bots/$botId/chat',
      );
    },
  );

  testWidgets(
    'with nothing saved, a wide window opens the bot that spoke last',
    (tester) async {
      await setSize(tester, const Size(1600, 1000));
      final backend = FakeBackend();
      backend.extraBots.add(
        Bot.fromJson({
          ...backend.bot(id: _bo, name: 'Bo').toJson(),
          'last_message': BotLastMessage(
            text: 'Done',
            from: BotLastMessageFromEnum.bot,
            fileName: null,
            fileMime: null,
            conversationId: 'c9',
            at: DateTime(2026, 11, 18),
          ).toJson(),
        }),
      );
      await _open(tester, backend);
      expect(_chatBot(tester), _bo);
    },
  );

  testWidgets(
    'a workspace without bots keeps the page, with the way to make the first one',
    (tester) async {
      await setSize(tester, const Size(1600, 1000));
      final backend = FakeBackend()..archived.add(botId);
      await _open(tester, backend);
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.text('No bots yet'), findsOneWidget);
      expect(
        find.text(
          'A bot is a teammate with its own computer. Create one to start chatting.',
        ),
        findsOneWidget,
      );
      expect(find.text('New bot'), findsOneWidget);
    },
  );

  testWidgets('phones keep the list of bots', (tester) async {
    await setSize(tester, const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'lastChat:$orgId': '/bots/$botId/chat',
    });
    await _open(tester, FakeBackend());
    expect(find.byType(ChatScreen), findsNothing);
  });

  testWidgets(
    'on a computer the chat opens with the cursor in the message box',
    (tester) async {
      await setSize(tester, const Size(1600, 1000));
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await _open(tester, FakeBackend());
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(focused.findAncestorWidgetOfExactType<ChatScreen>(), isNotNull);
      expect(
        focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null,
        isTrue,
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'what the chat shows is read once the window is in front, not while it is behind',
    (tester) async {
      await setSize(tester, const Size(1600, 1000));
      final backend = FakeBackend()
        ..storedNotifications = [
          NotificationView(
            id: 'r',
            kind: 'routine_result',
            title: '',
            body: '',
            link: '/bots/$botId/chat?c=c1',
            createdAt: DateTime.now(),
            botId: botId,
          ),
        ];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _open(tester, backend);
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(backend.readNotifications, isEmpty);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(backend.readNotifications, ['r']);
    },
  );
}

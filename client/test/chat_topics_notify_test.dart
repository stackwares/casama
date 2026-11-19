// A bot's chats share one screen and one path (D-253). What happens in another topic of the bot
// on screen, or in the bot that was on screen before, is somewhere else (D-413).
import 'package:casama/core/backend.dart';
import 'package:casama/core/chat_focus.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/inbox/in_app_alert.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _otherBot = '99999999-9999-4999-8999-999999999999';
const _otherConv = '88888888-8888-4888-8888-888888888888';

NotificationView _reply(String id, String conversation, {String bot = botId}) =>
    NotificationView(
      id: id,
      kind: 'reply',
      title: 'Ada',
      body: 'Done: the report is ready.',
      link: '/bots/$bot/chat?c=$conversation',
      createdAt: DateTime.now(),
      botId: bot,
      conversationId: conversation,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a reply in another topic of the bot on screen gets its banner', (
    tester,
  ) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend();
    late ProviderContainer container;
    final router = GoRouter(
      initialLocation: '/bots/$botId/chat?c=$convId',
      routes: [
        ShellRoute(
          builder: (_, s, child) =>
              InAppAlertBanner(location: s.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/bots/:id/chat',
              builder: (_, s) =>
                  Scaffold(body: Text('chat ${s.uri.queryParameters['c']}')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The chat screen reports which conversation is showing.
    container.read(chatFocusProvider).open(convId);

    // A reply in the conversation on screen: no banner over what the person is reading.
    backend.notificationsController.add(_reply('here', convId));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);

    // A reply in another topic of the same bot: same path, another place.
    backend.notificationsController.add(_reply('elsewhere', _otherConv));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inAppAlertOpen')));
    await tester.pumpAndSettle();
    expect(find.text('chat $_otherConv'), findsOneWidget);
  });

  test('opening one topic leaves the notifications of the bot\'s other topics unread', () async {
    final backend = FakeBackend()
      ..storedNotifications = [
        _reply('here', convId),
        _reply('elsewhere', _otherConv),
        // From before links carried the conversation: read with whichever chat of the bot opens.
        NotificationView(
          id: 'old',
          kind: 'routine_result',
          title: '',
          body: '',
          link: '/bots/$botId/chat',
          createdAt: DateTime.now(),
          botId: botId,
        ),
        // A reply in a group chat links to the group, whichever bot spoke.
        NotificationView(
          id: 'group',
          kind: 'reply',
          title: '',
          body: '',
          link: '/groups/$convId',
          createdAt: DateTime.now(),
          botId: _otherBot,
        ),
      ];
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(notificationsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(notificationsProvider.future);
    await container
        .read(notificationsProvider.notifier)
        .markBotChatRead(botId, conversationId: convId);
    final unread = [
      for (final n in container.read(notificationsProvider).value!)
        if (n.readAt == null) n.id,
    ];
    expect(unread, ['elsewhere']);
  });

  testWidgets(
    'going from one bot to another reports the second bot\'s chat as the one on screen',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      late ProviderContainer container;
      Widget screen(String bot, String conversation) => harness(
        backend,
        Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            // The router keeps the screen and hands it the next bot.
            return ChatScreen(botId: bot, conversationId: conversation);
          },
        ),
      );
      await tester.pumpWidget(screen(botId, convId));
      await tester.pumpAndSettle();
      expect(container.read(chatFocusProvider).conversation, convId);

      await tester.pumpWidget(screen(_otherBot, _otherConv));
      await tester.pumpAndSettle();
      // Before, the first bot's chat stayed "on screen": its replies stopped notifying anywhere.
      expect(container.read(chatFocusProvider).conversation, _otherConv);
    },
  );
}

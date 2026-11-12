import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_sdk/casama_sdk.dart' show BotLastMessage, BotLastMessageFromEnum;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/board/board_screen.dart' show TicketSheet;
import 'package:casama_app/features/home/home_shell.dart';
import 'package:casama_app/features/memory/memory_screen.dart';
import 'package:casama_app/features/search/search_view.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('search groups results and opens the exact message', (tester) async {
    await setSize(tester, const Size(700, 1000));
    final backend = FakeBackend();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.uri.queryParameters['c']} ${s.uri.queryParameters['m']}')),
        GoRoute(path: '/tasks', builder: (_, _) => const Text('board')),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'invoice');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(backend.searches, ['invoice']);
    expect(find.text('MESSAGES'), findsOneWidget);
    expect(find.text('TICKETS'), findsOneWidget);
    expect(find.text('FILES'), findsOneWidget);
    expect(find.text('invoice.md'), findsOneWidget);
    // The scope chips count what each kind found.
    expect(find.text('Tickets  1'), findsOneWidget);
    expect(find.text('Files  1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-message-msg-1')));
    await tester.pumpAndSettle();
    expect(find.text('chat $convId msg-1'), findsOneWidget);
  });

  testWidgets('the chat scrolls to and highlights the searched message', (tester) async {
    await setSize(tester, const Size(500, 700));
    final backend = FakeBackend()
      ..storedMessages = [
        for (var i = 0; i < 40; i++)
          ChatMessageView(id: 'm$i', role: i.isEven ? 'user' : 'assistant', text: 'Message number $i', createdAt: DateTime(2026, 11, 1, 0, i)),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId, focusMessageId: 'm5')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focusedMessage')), findsOneWidget);
    expect(find.text('Message number 5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('focusedMessage')), findsNothing);
  });

  testWidgets('Ctrl+K opens search on larger windows', (tester) async {
    await setSize(tester, const Size(1400, 900));
    await tester.pumpWidget(harness(FakeBackend(), const HomeShell(location: '/settings/privacy', child: Text('screen'))));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchField')), findsOneWidget);
  });


  Widget searchApp(FakeBackend backend) => ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend)],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.uri.queryParameters['c']} ${s.uri.queryParameters['m']}')),
          GoRoute(path: '/bots/:id/memory', builder: (_, s) => Text('memory ${s.uri.queryParameters['focus']}')),
          GoRoute(path: '/tasks', builder: (_, _) => const Text('board')),
          GoRoute(path: '/quick-ask', builder: (_, s) => Text('ask ${s.uri.queryParameters['bot']} ${s.uri.queryParameters['text']}')),
          GoRoute(path: '/settings/skills', builder: (_, _) => const Text('skills')),
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('searchField')), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('before typing, search offers recent chats, what is waiting and places (D-235)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..lastMessage = BotLastMessage(
        text: 'Here is the summary.',
        from: BotLastMessageFromEnum.bot,
        fileName: null,
        fileMime: null,
        conversationId: 'conv-9',
        at: DateTime.now().subtract(const Duration(hours: 2)),
      );
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    expect(find.text('JUMP BACK IN'), findsOneWidget);
    expect(find.text('Here is the summary.'), findsOneWidget);
    expect(find.text('GO TO'), findsOneWidget);
    expect(find.byKey(const Key('place-tasks')), findsOneWidget);
    // No history yet, so no Recent section, and nothing was sent to the server.
    expect(find.text('RECENT'), findsNothing);
    expect(backend.searches, isEmpty);
    await tester.tap(find.byKey(Key('recentChat-$botId')));
    await tester.pumpAndSettle();
    expect(find.text('chat conv-9 null'), findsOneWidget);
  });

  testWidgets('one letter matches bots and places at once, without the server', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    await type(tester, 'a');
    expect(find.text('TOP HITS'), findsOneWidget);
    expect(find.byKey(Key('botHit-$botId')), findsOneWidget);
    expect(find.text('Keep typing to search messages, memories and files.'), findsOneWidget);
    expect(backend.searches, isEmpty);
    await type(tester, 'tas');
    expect(find.byKey(const Key('place-tasks')), findsOneWidget);
    await tester.tap(find.byKey(const Key('place-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('board'), findsOneWidget);
  });

  testWidgets('a scope chip searches one kind only', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    await type(tester, 'invoice');
    expect(backend.searchKinds.last, isNull);
    await tester.ensureVisible(find.byKey(const Key('searchScope-tickets')));
    await tester.tap(find.byKey(const Key('searchScope-tickets')));
    await tester.pumpAndSettle();
    expect(backend.searchKinds.last, ['ticket']);
    expect(find.byKey(const Key('result-ticket-t1')), findsOneWidget);
    expect(find.byKey(const Key('result-message-msg-1')), findsNothing);
    expect(find.text('FILES'), findsNothing);
  });

  testWidgets('a search that opened something is remembered, and can be run again', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    await type(tester, 'invoice');
    await tester.tap(find.byKey(const Key('result-message-msg-1')));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getStringList('search.recent.me.$orgId'), ['invoice']);

    // A fresh search panel shows it; tapping it searches again.
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    expect(find.text('RECENT'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recentSearch-invoice')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(backend.searches, ['invoice', 'invoice']);
    await tester.tap(find.byKey(const Key('clearSearch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearRecent')));
    await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getStringList('search.recent.me.$orgId'), isNull);
  });

  testWidgets('nothing found offers to ask a bot instead', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..searchFindsNothing = true;
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    await type(tester, 'quarterly churn');
    expect(find.text('Nothing found for “quarterly churn”.'), findsOneWidget);
    expect(find.text('Ask Ada about “quarterly churn”'), findsOneWidget);
    await tester.tap(find.byKey(const Key('askBot')));
    await tester.pumpAndSettle();
    expect(find.text('ask $botId quarterly churn'), findsOneWidget);
  });

  testWidgets('arrow keys and Enter open a result on larger windows', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(1200, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(searchApp(backend));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchKeysHint')), findsOneWidget);
    await type(tester, 'invoice');
    // Rows: the message, the ticket, the file, ask a bot. Down once selects the ticket.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('board'), findsOneWidget);
    expect(find.byType(TicketSheet), findsOneWidget);
  });

  testWidgets('Escape clears the query first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(1200, 900));
    await tester.pumpWidget(searchApp(FakeBackend()));
    await tester.pumpAndSettle();
    await type(tester, 'invoice');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('GO TO'), findsOneWidget);
  });

  testWidgets('a memory search result opens that memory', (tester) async {
    await setSize(tester, const Size(500, 900));
    final router = GoRouter(
      initialLocation: '/bots/$botId/memory?focus=mem1',
      routes: [GoRoute(path: '/bots/:id/memory', builder: (_, s) => MemoryScreen(botId: s.pathParameters['id']!))],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(FakeBackend())],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    // The edit sheet is open with the memory's text.
    expect(find.widgetWithText(TextField, 'Likes teal'), findsOneWidget);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/home/home_shell.dart';
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
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('docs/invoice.md'), findsOneWidget);
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
}

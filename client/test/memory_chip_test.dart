// "Remembered something" in a chat opens the bot's memory at what it saved, to check, fix or
// delete it; a run of several opens the whole list.
import 'package:casama/core/providers.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Future<(FakeBackend, GoRouter)> _open(WidgetTester tester) async {
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend();
  final router = GoRouter(
    initialLocation: '/chat',
    routes: [
      GoRoute(
        path: '/chat',
        builder: (_, _) =>
            const ChatScreen(botId: botId, conversationId: convId),
      ),
      GoRoute(
        path: '/bots/:botId/memory',
        builder: (_, s) =>
            Text('memory ${s.pathParameters['botId']} ${s.uri.query}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('messageInput')),
    'I prefer metric units',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendButton')));
  await tester.pump();
  backend.runEventsController.add(
    ev(1, 'run.started', {
      'trigger': 'chat',
      'model': 'm',
      'computer_id': null,
    }),
  );
  return (backend, router);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('one memory opens at that memory', (tester) async {
    final (backend, _) = await _open(tester);
    backend.runEventsController
      ..add(ev(2, 'memory.written', {'memory_id': 'm1', 'kind': 'preference'}))
      ..add(ev(3, 'message.delta', {'message_id': 'a1', 'text': 'Got it.'}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('openMemory')));
    await tester.pumpAndSettle();
    expect(find.text('memory $botId focus=m1'), findsOneWidget);
  });

  testWidgets('several in a row open the whole list', (tester) async {
    final (backend, _) = await _open(tester);
    backend.runEventsController
      ..add(ev(2, 'memory.written', {'memory_id': 'm1', 'kind': 'preference'}))
      ..add(ev(3, 'memory.written', {'memory_id': 'm2', 'kind': 'fact'}))
      ..add(ev(4, 'message.delta', {'message_id': 'a1', 'text': 'Got it.'}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('openMemory')), findsOneWidget);
    await tester.tap(find.byKey(const Key('openMemory')));
    await tester.pumpAndSettle();
    expect(find.text('memory $botId '), findsOneWidget);
  });
}

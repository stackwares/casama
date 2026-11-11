// Simple chats (D-162): by default the chat shows what the bot is doing in a few words and its
// answer, not each step, command or technical error.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/chat/chat_detail.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<FakeBackend> _openAndSend(WidgetTester tester) async {
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend();
  await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('messageInput')), 'Find photos of Sapporo snow');
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendButton')));
  await tester.pump();
  backend.runEventsController.add(ev(1, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}));
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('steps stay out of the chat; the working line says what is happening in plain words', (tester) async {
    final backend = await _openAndSend(tester);
    backend.runEventsController
      ..add(ev(2, 'tool.started', {'call_id': 'c1', 'tool': 'tools.load', 'args_redacted': <String, Object?>{}}))
      ..add(ev(3, 'tool.completed', {'call_id': 'c1', 'result_preview': 'ok', 'artifact_path': null, 'duration_ms': 0}))
      ..add(
        ev(4, 'tool.started', {
          'call_id': 'c2',
          'tool': 'web.search',
          'args_redacted': {'query': 'Sapporo snow winter photos'},
        }),
      );
    await tester.pump();
    expect(find.text('Searching the web…'), findsOneWidget);
    // No step cards, tool names or queries.
    expect(find.textContaining('tools.load'), findsNothing);
    expect(find.text('Searched the web'), findsNothing);
    expect(find.textContaining('Sapporo snow winter photos'), findsNothing);

    backend.runEventsController
      ..add(ev(5, 'tool.completed', {'call_id': 'c2', 'result_preview': '3 results', 'artifact_path': null, 'duration_ms': 812}))
      ..add(ev(6, 'skill.loaded', {'skill_id': 's1', 'name': 'photo-finder'}))
      ..add(ev(7, 'memory.written', {'memory_id': 'm1', 'kind': 'preference'}))
      ..add(ev(8, 'message.delta', {'message_id': 'a1', 'text': 'Here are three photos of Sapporo in the snow.'}));
    await tester.pump();
    expect(find.textContaining('Here are three photos', findRichText: true), findsOneWidget);
    // How it works stays out; what it learned about you stays in.
    expect(find.textContaining('photo-finder'), findsNothing);
    expect(find.text('Remembered something'), findsOneWidget);
  });

  testWidgets('a failure without a plain explanation reads as one sentence, the rest in Details', (tester) async {
    final backend = await _openAndSend(tester);
    backend.runEventsController.add(ev(2, 'run.failed', {'error_code': 'model_error', 'message': 'Something went wrong while the bot was working. provider returned 400'}));
    await tester.pump();
    expect(find.text('Something went wrong. Try again, or open Details to see why.'), findsOneWidget);
    expect(find.textContaining('provider returned 400'), findsNothing);
    expect(find.byKey(const Key('errorDetails')), findsOneWidget);
  });

  testWidgets('failures that already explain themselves read as they are', (tester) async {
    final backend = await _openAndSend(tester);
    backend.runEventsController.add(ev(2, 'run.failed', {'error_code': 'budget_exceeded', 'message': r'This run reached its budget of $1.'}));
    await tester.pump();
    expect(find.text(r'This run reached its budget of $1.'), findsOneWidget);
  });

  test('showing the steps is off by default and remembered on this device', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(showBotStepsProvider, (_, _) {});
    expect(container.read(showBotStepsProvider), isFalse);
    await container.read(showBotStepsProvider.notifier).set(true);
    expect(container.read(showBotStepsProvider), isTrue);
    expect((await SharedPreferences.getInstance()).getBool('chat.showSteps'), isTrue);
  });
}

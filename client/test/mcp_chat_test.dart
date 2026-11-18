import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// A connected MCP server's question and a local server's sign-in, as chat cards (D-363).
void main() {
  // The run is still going while it waits, so its working indicator never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<FakeBackend> startRun(WidgetTester tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'deploy it');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    return backend;
  }

  testWidgets(
    'a question from a connection: fill the form and send, and the card folds',
    (tester) async {
      final backend = await startRun(tester);
      backend.runEventsController.add(
        ev(1, 'mcp.question', {
          'question_id': 'q1',
          'connection': 'Deploys',
          'message': 'Where to deploy?',
          'schema': {
            'type': 'object',
            'properties': {
              'env': {
                'type': 'string',
                'enum': ['staging', 'production'],
                'title': 'Environment',
              },
              'notes': {'type': 'string'},
              'confirm': {'type': 'boolean', 'title': 'Run checks'},
            },
            'required': ['env'],
          },
          'expires_at': DateTime.now()
              .add(const Duration(minutes: 10))
              .toUtc()
              .toIso8601String(),
        }),
      );
      await settle(tester);
      expect(find.byKey(const Key('chatMcpQuestion')), findsOneWidget);
      expect(find.text('Deploys asks'), findsOneWidget);
      expect(find.text('Where to deploy?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mcpField-env')));
      await settle(tester);
      await tester.tap(find.text('production').last);
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('mcpField-notes')),
        'after 5pm',
      );
      await tester.tap(find.byKey(const Key('mcpField-confirm')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('mcpQuestionSend')));
      await settle(tester);
      expect(
        (backend.mcpAnswers.single.$1, backend.mcpAnswers.single.$2),
        ('q1', 'accept'),
      );
      expect(backend.mcpAnswers.single.$3, {
        'env': 'production',
        'notes': 'after 5pm',
        'confirm': true,
      });
      expect(find.text('Answered Deploys'), findsOneWidget);
    },
  );

  testWidgets('a declined or closed question folds to say so', (tester) async {
    final backend = await startRun(tester);
    backend.runEventsController.add(
      ev(1, 'mcp.question', {
        'question_id': 'q2',
        'connection': 'Deploys',
        'message': 'Sure?',
        'schema': {'type': 'object', 'properties': <String, Object?>{}},
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 10))
            .toUtc()
            .toIso8601String(),
      }),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('mcpQuestionDecline')));
    await settle(tester);
    expect(backend.mcpAnswers.single.$2, 'decline');

    backend.runEventsController.add(
      ev(2, 'mcp.question', {
        'question_id': 'q3',
        'connection': 'Billing',
        'message': 'Which invoice?',
        'schema': {'type': 'object', 'properties': <String, Object?>{}},
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 10))
            .toUtc()
            .toIso8601String(),
      }),
    );
    backend.runEventsController.add(
      ev(3, 'mcp.question_resolved', {
        'question_id': 'q3',
        'outcome': 'expired',
      }),
    );
    await settle(tester);
    expect(find.text("Billing's question closed"), findsOneWidget);
    expect(find.byKey(const Key('mcpQuestionSend')), findsNothing);
  });

  testWidgets('a local server that needs a sign-in says where to sign in', (
    tester,
  ) async {
    final backend = await startRun(tester);
    backend.runEventsController.add(
      ev(1, 'local_mcp.sign_in_needed', {
        'integration_id': 'i1',
        'device_id': 'some-other-mac',
        'server': 't3_code',
        'label': 'T3 Code',
        'bot_id': botId,
      }),
    );
    backend.runEventsController.add(
      ev(2, 'run.completed', {'final_message_id': null}),
    );
    await settle(tester);
    expect(find.byKey(const Key('chatMcpSignIn')), findsOneWidget);
    expect(find.text('T3 Code needs you to sign in'), findsOneWidget);
    // Not this device, so no button: sign in on that computer.
    expect(find.byKey(const Key('mcpSignIn')), findsNothing);
    expect(find.textContaining('and sign in there'), findsOneWidget);
  });
}

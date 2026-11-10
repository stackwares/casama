import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  Future<FakeBackend> openChat(WidgetTester tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('messageInput')),
      'charge the customer',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController.add(
      ev(1, 'secret.requested', {
        'request_id': 'sr1',
        'name': 'STRIPE_API_KEY',
        'service': 'Stripe',
        'allowed_hosts': ['api.stripe.com'],
        'reason': 'To create the charge.',
        'expires_at': '2026-11-11T00:00:00Z',
      }),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return backend;
  }

  testWidgets('the protected card saves the value straight to the backend', (
    tester,
  ) async {
    final backend = await openChat(tester);
    expect(find.byKey(const Key('chatSecret')), findsOneWidget);
    expect(find.text('Ada needs a Stripe key'), findsOneWidget);
    expect(find.text('Only for api.stripe.com'), findsOneWidget);
    final field = tester.widget<TextField>(
      find
          .descendant(
            of: find.byKey(const Key('secretValue')),
            matching: find.byType(TextField),
            matchRoot: true,
          )
          .first,
    );
    expect(field.obscureText, isTrue);
    expect(field.enableSuggestions, isFalse);
    await tester.enterText(find.byKey(const Key('secretValue')), 'sk_live_123');
    await tester.tap(find.byKey(const Key('secretSave')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.secretAnswers, [('sr1', 'sk_live_123')]);
    expect(find.text('sk_live_123'), findsNothing);
    expect(find.text('Saved STRIPE_API_KEY'), findsOneWidget);
    // The composer never held it.
    expect(
      tester
          .widget<TextField>(
            find
                .descendant(
                  of: find.byKey(const Key('messageInput')),
                  matching: find.byType(TextField),
                  matchRoot: true,
                )
                .first,
          )
          .controller
          ?.text,
      isNot(contains('sk_live')),
    );
  });

  testWidgets('declining tells the backend and shows the outcome', (
    tester,
  ) async {
    final backend = await openChat(tester);
    await tester.tap(find.byKey(const Key('secretDecline')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.secretAnswers, [('sr1', null)]);
    backend.runEventsController.add(
      ev(2, 'secret.resolved', {'request_id': 'sr1', 'outcome': 'declined'}),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Declined'), findsOneWidget);
  });
}

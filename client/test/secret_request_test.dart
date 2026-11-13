import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  Future<FakeBackend> openChat(
    WidgetTester tester, {
    Map<String, String> statuses = const {},
  }) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..secretStatuses.addAll(statuses);
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
      'kind': 'value',
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
    // The secret's own name as the title, the bot's reason under it, where it may be used (D-256).
    expect(find.text('STRIPE_API_KEY'), findsWidgets);
    expect(find.text('To create the charge.'), findsOneWidget);
    expect(find.textContaining('Only for api.stripe.com'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('secretSave'))).onPressed, isNull, reason: 'Save waits for a value');
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
    await tester.pump();
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
    // Answered: the card folds into one line; the reason and the field are gone.
    expect(find.text('Declined: Stripe key'), findsOneWidget);
    expect(find.text('Only for api.stripe.com'), findsNothing);
  });

  testWidgets('a request already answered on the server shows how it ended, not an open card', (
    tester,
  ) async {
    // Declined earlier, but its run had ended, so no secret.resolved event ever came.
    final backend = await openChat(tester, statuses: {'sr1': 'declined'});
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Declined: Stripe key'), findsOneWidget);
    expect(find.byKey(const Key('secretValue')), findsNothing);
    expect(find.byKey(const Key('secretDecline')), findsNothing);
    expect(backend.secretAnswers, isEmpty);
  });
}

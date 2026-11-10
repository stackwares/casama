import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/bots/action_rules_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a rule is added with limits and shown in plain language, grouped by category', (tester) async {
    await setSize(tester, const Size(900, 1300));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ActionRulesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addRule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ruleKind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go ahead within limits').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ruleDomains')), 'acme.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveRule')));
    await tester.pumpAndSettle();
    expect(backend.rules.single.botId, botId);
    expect(find.text('Sending messages'), findsOneWidget);
    expect(find.text('Sends messages to anyone at acme.com without asking'), findsOneWidget);
  });
}

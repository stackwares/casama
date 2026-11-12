import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Payments (D-142).
void main() {
  testWidgets('owners connect card issuing with caps, then see recent cards', (tester) async {
    await setSize(tester, const Size(900, 2000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: SingleChildScrollView(child: PaymentsSection(orgId: orgId)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payments')));
    await tester.pumpAndSettle();
    for (final (k, v) in [
      ('stripeKey', 'sk_live_issuing'),
      ('stripeWebhookSecret', 'whsec_123'),
      ('cardholderName', 'Ana Test'),
      ('cardholderEmail', 'ana@example.com'),
      ('cardholderLine1', '1 Main St'),
      ('cardholderCity', 'Austin'),
      ('cardholderZip', '78701'),
      ('paymentsCap', '300'),
    ]) {
      await tester.enterText(find.byKey(Key(k)), v);
    }
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('savePayments')));
    await tester.tap(find.byKey(const Key('savePayments')));
    await tester.pumpAndSettle();
    expect(backend.setPay!.cardholder.country, 'US');
    expect(backend.setPay!.monthlyCapUsd, 300);
    expect(find.textContaining(r'$0.00 spent this month of $300'), findsOneWidget);
    expect(find.textContaining(r'$92.00 · Amtrak'), findsOneWidget);
  });
}

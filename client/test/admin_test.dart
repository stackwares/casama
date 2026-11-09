import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/admin/admin_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the owner sees totals, an update notice, and can set quotas', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateNotice')), findsOneWidget);
    expect(find.text('Kasama 0.9.1 is available (you run 0.6.0)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Workspaces'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit quotas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('maxBots')), '3');
    await tester.enterText(find.byKey(const Key('monthlyUsd')), '25');
    await tester.tap(find.byKey(const Key('saveQuota')));
    await tester.pumpAndSettle();
    expect(backend.setLimits, {'max_bots': 3, 'monthly_usd': 25});

    await tester.tap(find.widgetWithText(Tab, 'Services'));
    await tester.pumpAndSettle();
    expect(find.text('Postgres (Supabase)'), findsOneWidget);
  });

  testWidgets('everyone else sees that the console is owner-only', (tester) async {
    final backend = FakeBackend()..isOwner = false;
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Only the instance owner can open the admin console.'), findsOneWidget);
  });
}

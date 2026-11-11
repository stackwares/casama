import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/admin/admin_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the owner sees totals, an update notice, and can set quotas', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateNotice')), findsOneWidget);
    expect(find.text('Casama 0.9.1 is available (you run 0.6.0)'), findsOneWidget);
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

  testWidgets('the owner chooses how apps without their own sign-in connect', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Services'));
    await tester.pumpAndSettle();
    expect(find.text('App connections'), findsOneWidget);
    expect(find.text("Casama's Composio account"), findsOneWidget);
    await tester.tap(find.byKey(const Key('connectionsOwn')));
    await tester.pumpAndSettle();
    expect(backend.connectionSettings.composio.value, 'own');
    await tester.tap(find.byKey(const Key('connectionsServer')));
    await tester.pumpAndSettle();
    expect(backend.connectionSettings.composio.value, 'server');
    // Google's apps: Composio by default, Google's own servers on request (D-166).
    expect(backend.connectionSettings.google.value, 'composio');
    await tester.ensureVisible(find.byKey(const Key('connectionsGoogleDirect')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('connectionsGoogleDirect')));
    await tester.pumpAndSettle();
    expect(backend.connectionSettings.google.value, 'direct');
    expect(backend.connectionSettings.composio.value, 'server');
    await tester.tap(find.byKey(const Key('connectionsGoogleComposio')));
    await tester.pumpAndSettle();
    expect(backend.connectionSettings.google.value, 'composio');
  });

  testWidgets('the owner suspends a workspace, lifts it, and reviews abuse', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Workspaces'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('suspend-$orgId')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('suspendReason')), 'Spam reports');
    await tester.tap(find.byKey(const Key('confirmSuspend')));
    await tester.pumpAndSettle();
    expect(backend.suspendedReason, 'Spam reports');
    expect(find.textContaining('Suspended: Spam reports'), findsOneWidget);
    await tester.tap(find.byKey(Key('suspend-$orgId')));
    await tester.pumpAndSettle();
    expect(backend.suspendedReason, isNull);

    await tester.tap(find.widgetWithText(Tab, 'Abuse'));
    await tester.pumpAndSettle();
    expect(find.text('Crypto mining blocked'), findsOneWidget);
    expect(find.textContaining('xmr.nanopool.org:443'), findsOneWidget);
  });

  testWidgets('everyone else sees that the console is owner-only', (tester) async {
    final backend = FakeBackend()..isOwner = false;
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Only the instance owner can open the admin console.'), findsOneWidget);
  });
}

// Phase 7 gate on a device: a Dodo purchase made on the web unlocks the plan in this app (iOS,
// Android, desktop). Needs a billing-enabled API with the local billing mock:
//   node --env-file=.env apps/server/test/fake-billing-server.ts http://127.0.0.1:8788 /tmp/billing.env
//   MODE=api node --env-file=.env --env-file=/tmp/billing.env apps/server/src/main.ts
// and KASAMA_API_URL=http://localhost:8788 (see scripts/e2e-app.sh, E2E_BILLING=1).
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kasama_app/core/config.dart';
import 'package:kasama_app/main.dart';

import 'app_flow_test.dart' show tap, waitFor;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a web purchase unlocks the plan in this app', (tester) async {
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    if (backend.isSignedIn) await backend.signOut();
    await tester.pumpWidget(app);
    await waitFor(tester, find.byKey(const Key('openSignIn')));
    await tap(tester, find.byKey(const Key('openSignIn')));
    await waitFor(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('usePassword')));
    await waitFor(tester, find.byKey(const Key('email')));
    await tap(tester, find.byKey(const Key('toggleMode')));
    await tester.enterText(find.byKey(const Key('email')), 'billing-${Random().nextInt(1 << 30)}@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw-123456');
    await tap(tester, find.byKey(const Key('submit')));
    await waitFor(tester, find.byKey(const Key('workspaceName')).hitTestable());
    await tester.enterText(find.byKey(const Key('workspaceName')), 'Billing Test');
    await tap(tester, find.byKey(const Key('createWorkspace')));
    await waitFor(tester, find.byKey(const Key('apiKey')).hitTestable());

    // A new Kasama Cloud workspace starts on the free plan.
    final router = GoRouter.of(tester.element(find.byKey(const Key('apiKey'))));
    router.go('/settings/billing');
    final plan = find.byKey(const Key('currentPlan'));
    await waitFor(tester, find.descendant(of: plan, matching: find.text('Free')));
    expect(find.text(r'Credits: $1.00'), findsOneWidget);

    // Someone pays on the web (another device): open the hosted checkout and complete it.
    final org = (await backend.organizations()).first;
    final url = await backend.checkoutUrl(org.id, planCode: 'pro');
    final client = HttpClient();
    final res = await (await client.getUrl(Uri.parse(url))).close();
    expect(res.statusCode, 200, reason: await res.transform(const SystemEncoding().decoder).join());
    client.close();

    // This app reads the workspace's entitlement: Pro, billed on the web.
    await tap(tester, find.byTooltip('Refresh'));
    await waitFor(tester, find.descendant(of: plan, matching: find.text('Pro')));
    expect(find.text('Billed on the web'), findsOneWidget);
    expect(find.text(r'Credits: $21.00'), findsOneWidget);
    if (const bool.fromEnvironment('E2E_HOLD')) await tester.pump(const Duration(seconds: 25));
  });
}

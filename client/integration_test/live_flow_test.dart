// Live view end to end against a running local stack with a sandbox (supervisor, TURN relay) and
// the desktop computer image. See scripts/e2e-app.sh (E2E_LIVE=1).
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';

import 'app_flow_test.dart' show tap, waitFor;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('watch a desktop live over WebRTC, take control and hand back', (tester) async {
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    if (backend.isSignedIn) await backend.signOut();
    await tester.pumpWidget(app);
    await waitFor(tester, find.byKey(const Key('openSignIn')));
    await tap(tester, find.byKey(const Key('openSignIn')));
    await waitFor(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('usePassword')));
    await waitFor(tester, find.byKey(const Key('email')));
    final email = 'live-${Random().nextInt(1 << 30)}@example.com';
    await tap(tester, find.byKey(const Key('toggleMode')));
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), 'pw-123456');
    await tap(tester, find.byKey(const Key('submit')));
    await waitFor(tester, find.byKey(const Key('workspaceName')).hitTestable());
    await tester.enterText(find.byKey(const Key('workspaceName')), 'Live Test');
    await tap(tester, find.byKey(const Key('createWorkspace')));
    await waitFor(tester, find.byKey(const Key('apiKey')).hitTestable());
    await tester.enterText(find.byKey(const Key('apiKey')), 'sk-or-v1-live-test');
    await tap(tester, find.byKey(const Key('addKey')));
    await waitFor(tester, find.byKey(const Key('botName')).hitTestable());
    await tester.enterText(find.byKey(const Key('model')), 'fixture-main');
    await tap(tester, find.byKey(const Key('createBot')));
    await waitFor(tester, find.byKey(const Key('messageInput')).hitTestable());

    // Switch the team computer to the desktop profile from Settings > Computers.
    final router = GoRouter.of(tester.element(find.byKey(const Key('messageInput'))));
    router.go('/settings/computers');
    await waitFor(tester, find.byKey(const Key('newComputer')));
    final orgs = await backend.organizations();
    final computer = (await backend.computers(orgs.first.id)).first;
    await tap(tester, find.byKey(Key('computerMenu-${computer.id}')));
    await waitFor(tester, find.text('Switch to desktop').hitTestable());
    await tap(tester, find.text('Switch to desktop'));
    await waitFor(tester, find.textContaining('Desktop'));

    // Live view: video arrives through the TURN relay; latency is measured on the data channel.
    router.push('/computer/live?c=${computer.id}');
    await waitFor(tester, find.textContaining('Live ·'), timeout: const Duration(seconds: 120));
    await waitFor(tester, find.byKey(const Key('latency')), timeout: const Duration(seconds: 30));
    final latency = tester.widget<Text>(find.byKey(const Key('latency'))).data!;
    final ms = int.parse(latency.split(' ').first);
    expect(ms, lessThan(500), reason: 'data-channel RTT $latency');

    await tap(tester, find.byKey(const Key('takeControl')));
    await waitFor(tester, find.textContaining("You're in control"));
    await tester.tap(find.byKey(const Key('liveSurface')));
    await tester.pump(const Duration(milliseconds: 300));
    await tap(tester, find.byKey(const Key('handBack')));
    await waitFor(tester, find.byKey(const Key('handBackNote')).hitTestable());
    await tester.enterText(find.byKey(const Key('handBackNote')), 'All yours');
    await tap(tester, find.byKey(const Key('confirmHandBack')));
    await waitFor(tester, find.textContaining('Bot in control'));
    debugPrint('LIVE E2E: latency $latency');
  });
}

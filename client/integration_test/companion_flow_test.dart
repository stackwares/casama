// Phase 6 gate: this Mac's desktop app acts as a bot's computer and completes a browser task with
// agent-browser (its own browser, in a separate "casama" namespace). Needs the local stack and
// agent-browser on PATH (Homebrew). See scripts/e2e-app.sh (E2E_COMPANION=1).
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_flow_test.dart' show tap, typeMessage, waitFor;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the companion completes a browser task on this computer', (tester) async {
    // The page the bot reads, served on this machine.
    final page = await HttpServer.bind(InternetAddress.loopbackIPv4, 47123);
    page.listen((r) {
      r.response.headers.contentType = ContentType.html;
      r.response.write('<html><body><h1>Casama companion check</h1><p>The secret word is marigold-4242.</p></body></html>');
      r.response.close();
    });
    addTearDown(() => page.close(force: true));

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
    await tester.enterText(find.byKey(const Key('email')), 'companion-${Random().nextInt(1 << 30)}@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw-123456');
    await tap(tester, find.byKey(const Key('submit')));
    await waitFor(tester, find.byKey(const Key('workspaceName')).hitTestable());
    await tester.enterText(find.byKey(const Key('workspaceName')), 'Companion Test');
    await tap(tester, find.byKey(const Key('createWorkspace')));
    await waitFor(tester, find.byKey(const Key('apiKey')).hitTestable());
    await tester.enterText(find.byKey(const Key('apiKey')), 'sk-or-v1-companion-test');
    await tap(tester, find.byKey(const Key('addKey')));
    await waitFor(tester, find.byKey(const Key('botName')).hitTestable());
    await tester.enterText(find.byKey(const Key('model')), 'fixture-main');
    await tap(tester, find.byKey(const Key('createBot')));
    await waitFor(tester, find.byKey(const Key('messageInput')).hitTestable());
    final router = GoRouter.of(tester.element(find.byKey(const Key('messageInput'))));
    final chatPath = router.routeInformationProvider.value.uri.path;
    final botId = RegExp(r'^/bots/([^/]+)').firstMatch(chatPath)!.group(1)!;

    // Settings > Use this computer for bots: pair, allow the browser, allow the bot.
    router.go('/settings/companion');
    await waitFor(tester, find.byKey(const Key('pairComputer')).hitTestable());
    await tap(tester, find.byKey(const Key('pairComputer')));
    await waitFor(tester, find.byKey(const Key('cap-browser')).hitTestable());
    await tap(tester, find.byKey(const Key('cap-browser')));
    await tester.scrollUntilVisible(find.byKey(const Key('companionEnabled')), -200, scrollable: find.byType(Scrollable).first);
    try {
      await waitFor(tester, find.text('On: bots you allow can use this computer'), timeout: const Duration(seconds: 30));
    } catch (_) {
      final status = tester.widgetList<Text>(find.byKey(const Key('companionStatus'))).map((t) => t.data).join();
      fail('companion status: $status');
    }
    await tester.scrollUntilVisible(find.byKey(Key('allowBot-$botId')), 200, scrollable: find.byType(Scrollable).first);
    await tap(tester, find.byKey(Key('allowBot-$botId')));
    await tester.pump(const Duration(seconds: 1));

    // The bot browses on this Mac.
    router.go('/bots/$botId/chat');
    await waitFor(tester, find.byKey(const Key('messageInput')).hitTestable());
    await typeMessage(tester, 'Please open the companion test page and read it.');
    await tap(tester, find.byKey(const Key('sendButton')));
    var sawOverlay = false;
    final end = DateTime.now().add(const Duration(seconds: 120));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('companionOverlay')).evaluate().isNotEmpty) sawOverlay = true;
      if (find.textContaining('the secret word is marigold-4242').evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('the secret word is marigold-4242'), findsOneWidget);
    expect(sawOverlay, isTrue, reason: 'the overlay shows while the bot acts');

    // The reply above only matches when the tool result (read on this Mac) held the secret word.
    final runs = await backend.runs(botId);
    final events = await backend.runEvents(runs.first.id);
    final tools = events.whereType<ToolCompletedItem>().map((e) => e.event.payload.callId).toList();
    expect(tools, ['b1', 'b2'], reason: 'browser.open and browser.read both ran on this computer');
    debugPrint('COMPANION E2E: browser task completed on this computer');

    // Clean up the agent-browser session the bot opened (only Casama's namespace).
    await Process.run('/opt/homebrew/bin/agent-browser', ['close'], environment: {
      'AGENT_BROWSER_NAMESPACE': 'casama',
      'AGENT_BROWSER_SESSION': 'casama-companion',
    });
  });
}

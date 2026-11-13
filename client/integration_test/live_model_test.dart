// Live chat against a real model (D-064). Run only through scripts/live-check.sh, which passes the
// key with a temporary --dart-define-from-file and points the worker at the real provider.
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';

import 'app_flow_test.dart' show tap, typeMessage, waitFor;

const _key = String.fromEnvironment('CASAMA_LIVE_OPENROUTER_KEY');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live: onboard with an OpenRouter key and chat with Muse Ember', (tester) async {
    expect(_key, isNotEmpty, reason: 'run through scripts/live-check.sh');
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
    await tester.enterText(find.byKey(const Key('email')), 'live-chat-${Random().nextInt(1 << 30)}@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw-123456');
    await tap(tester, find.byKey(const Key('submit')));
    await waitFor(tester, find.byKey(const Key('workspaceName')).hitTestable());
    await tester.enterText(find.byKey(const Key('workspaceName')), 'Live Chat');
    await tap(tester, find.byKey(const Key('createWorkspace')));
    await waitFor(tester, find.byKey(const Key('apiKey')).hitTestable());
    await tester.enterText(find.byKey(const Key('apiKey')), _key);
    await tap(tester, find.byKey(const Key('addKey')));
    await waitFor(tester, find.byKey(const Key('botName')).hitTestable());

    // The model is preselected: Muse Ember for an OpenRouter key.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<TextField>(find.byKey(const Key('model'))).controller!.text, 'deepseek/deepseek-v4.1-flash-1017');
    await tap(tester, find.byKey(const Key('createBot')));

    await waitFor(tester, find.byKey(const Key('messageInput')).hitTestable());
    await typeMessage(tester, 'What is 6 times 7? Reply with only the digits followed by the word casama, for example: 12 casama');
    await tap(tester, find.byKey(const Key('sendButton')));
    await waitFor(tester, find.textContaining('42 casama', findRichText: true), timeout: const Duration(seconds: 120));
    await waitFor(tester, find.byKey(const Key('sendButton')), timeout: const Duration(seconds: 60));
  });
}

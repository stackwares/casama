import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/settings/model_keys_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('desktop: Continue with ChatGPT connects a plan', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()..canConnectChatGpt = true;
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Continue with ChatGPT'), findsOneWidget);
    expect(find.text('Or add an API key'), findsOneWidget);
    await tester.tap(find.byKey(const Key('continueWithChatGpt')));
    await tester.pumpAndSettle();
    expect(backend.connectedChatGpt, [orgId]);
    expect(find.text('Connected your ChatGPT plan (me@example.com).'), findsOneWidget);
  });

  testWidgets('phones and the web point to the desktop app or the CLI', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()..canConnectChatGpt = false;
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continueWithChatGpt')), findsNothing);
    expect(find.textContaining('casama credential chatgpt'), findsOneWidget);
  });

  testWidgets('servers with ChatGPT sign-in off show only API keys', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..chatGptSignIn = false
      ..canConnectChatGpt = true;
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continueWithChatGpt')), findsNothing);
    expect(find.text('Or add an API key'), findsNothing);
  });

  testWidgets('my plan: status, owner-only fallback setting and remove', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    backend.extraCredentials = [chatGptCredential(orgId, status: CredentialStatus.planUsageOff)];
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only you can use it'), findsOneWidget);
    expect(find.text('Plan usage off'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keyMenu-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Manage usage'), findsOneWidget);
    await tester.tap(find.byKey(const Key('fallbackOnLimit')));
    await tester.pumpAndSettle();
    expect(backend.credentialUpdates, {'plan': true});

    await tester.tap(find.byKey(const Key('keyMenu-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Your ChatGPT sign-in is revoked too.'), findsOneWidget);
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(backend.deletedCredentials, ['plan']);
  });

  testWidgets("a teammate's plan shows whose it is and no plan settings", (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    backend.extraCredentials = [chatGptCredential(orgId, owner: 'someone-else')];
    await tester.pumpWidget(harness(backend, const ModelKeysScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining("Another member's plan"), findsOneWidget);
    await tester.tap(find.byKey(const Key('keyMenu-plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fallbackOnLimit')), findsNothing);
    expect(find.text('Test key'), findsNothing);
  });

  test('ChatGPT is never offered as a paste-a-key provider', () {
    expect(keyProviders, isNot(contains(ProviderId.chatgpt)));
    expect(providerLabel(ProviderId.chatgpt), 'ChatGPT');
  });
}

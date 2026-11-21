import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/core/billing.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/model_picker.dart';
import 'package:casama/features/settings/model_keys_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';

import 'package:casama_sdk/casama_sdk.dart' show Credential, CredentialStatus, ProviderId;

import 'app_test.dart' show harness;
import 'fake_backend.dart';

Credential _key(String id, ProviderId provider) => Credential(
  id: id,
  orgId: 'org',
  provider: provider,
  label: id == casamaCloudCredentialId ? 'Casama Cloud' : 'Mine',
  baseUrl: null,
  keyHint: null,
  lastTestedAt: null,
  lastTestOk: null,
  ownerUserId: null,
  status: CredentialStatus.ok,
  account: null,
  fallbackOnLimit: false,
  embeddingModel: null,
  createdAt: DateTime(2026),
);

/// A server offering exactly [keys].
class _KeysBackend extends FakeBackend {
  _KeysBackend(this.keys);
  final List<Credential> keys;
  @override
  Future<List<Credential>> credentials(String orgId) async => keys;
}

Widget _fixed(FakeBackend backend) => harness(
  backend,
  Scaffold(body: Consumer(builder: (_, ref, _) => Text('fixed: ${casamaModelFixed(ref)}'))),
);

Widget _picker(FakeBackend backend, String credentialId) {
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      billingProvider.overrideWith((ref) async => backend.billing('org')),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ModelPickerField(
          credentialId: credentialId,
          value: 'anthropic/claude-sonnet-5.5',
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Casama Cloud shows its model and does not open the list', (
    tester,
  ) async {
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(_picker(backend, casamaCloudCredentialId));
    await tester.pumpAndSettle();
    expect(find.text('DeepSeek: DeepSeek V4.1 Flash 1017'), findsOneWidget);
    expect(find.text('Casama chooses this model.'), findsOneWidget);
    expect(find.text('anthropic/claude-sonnet-5.5'), findsNothing);
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSearch')), findsNothing);
  });

  testWidgets('Casama Cloud locks a workspace key too', (tester) async {
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(_picker(backend, 'cred'));
    await tester.pumpAndSettle();
    expect(find.text('DeepSeek: DeepSeek V4.1 Flash 1017'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSearch')), findsNothing);
  });

  testWidgets('a self-hosted server opens the model list', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(_picker(backend, 'cred'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSearch')), findsOneWidget);
  });

  testWidgets('Casama Cloud\'s keys page offers only search, maps and data keys', (tester) async {
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          billingProvider.overrideWith((ref) async => backend.billing('org')),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ModelKeysScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Service keys'), findsWidgets);
    expect(find.text('Model keys'), findsNothing);
    // The workspace's OpenRouter key does nothing on Cloud, so it isn't listed; no ChatGPT sign-in.
    expect(find.text('No service keys yet.'), findsOneWidget);
    expect(find.text('OpenRouter'), findsNothing);
    expect(find.text('Brave Search'), findsOneWidget);
  });

  testWidgets('without billing, Casama\'s key alone fixes the model too', (tester) async {
    final backend = _KeysBackend([
      _key(casamaCloudCredentialId, ProviderId.openrouter),
      _key('brave', ProviderId.braveSearch),
    ]);
    await tester.pumpWidget(_fixed(backend));
    await tester.pumpAndSettle();
    expect(find.text('fixed: true'), findsOneWidget);
  });

  testWidgets('a chat key of your own next to Casama\'s keeps the choice', (tester) async {
    final backend = FakeBackend()..extraCredentials = [_key(casamaCloudCredentialId, ProviderId.openrouter)];
    await tester.pumpWidget(_fixed(backend));
    await tester.pumpAndSettle();
    expect(find.text('fixed: false'), findsOneWidget);
  });

  testWidgets('without billing, Casama\'s key still shows its model, locked', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(_picker(backend, casamaCloudCredentialId));
    await tester.pumpAndSettle();
    expect(find.text('DeepSeek: DeepSeek V4.1 Flash 1017'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSearch')), findsNothing);
  });

  testWidgets('with ownProviders enabled on Cloud, own keys open the model list', (tester) async {
    final backend = FakeBackend()
      ..billingEnabled = true
      ..ownProvidersValue = true;
    await tester.pumpWidget(_picker(backend, 'cred'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modelPicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('modelSearch')), findsOneWidget);
  });

  testWidgets('with ownProviders enabled on Cloud, Models screen shows Who runs your bots', (tester) async {
    final backend = FakeBackend()
      ..billingEnabled = true
      ..ownProvidersValue = true
      ..extraCredentials = [_key(casamaCloudCredentialId, ProviderId.openrouter)];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          billingProvider.overrideWith((ref) async => backend.billing('org')),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ModelKeysScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Models'), findsWidgets);
    expect(find.text('Who runs your bots'), findsOneWidget);
    expect(find.byKey(const Key('workspaceDefaultCasama')), findsOneWidget);
    expect(find.byKey(const Key('workspaceDefaultOwn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('workspaceDefaultOwn')));
    await tester.pumpAndSettle();
    expect(backend.orgModelDefault?.source_.value, 'own');
    expect(backend.orgModelDefault?.credentialId, 'cred');
  });

  testWidgets('Your own provider without a key says to add one instead of doing nothing', (tester) async {
    final backend = FakeBackend()
      ..billingEnabled = true
      ..ownProvidersValue = true
      ..noKeys = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          billingProvider.overrideWith((ref) async => backend.billing('org')),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ModelKeysScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const hint = 'To use your own provider, add a chat key from it under Add a key below first.';
    expect(find.text(hint), findsOneWidget);
    await tester.tap(find.byKey(const Key('workspaceDefaultOwn')));
    await tester.pump();
    expect(find.text(hint), findsNWidgets(2));
    expect(backend.orgModelDefault, isNull);
  });
}

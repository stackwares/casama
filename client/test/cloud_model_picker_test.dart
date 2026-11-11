import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/billing.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/bots/model_picker.dart';
import 'package:casama_app/features/settings/model_keys_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

import 'fake_backend.dart';

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
    expect(find.text('Meta: Muse Ember'), findsOneWidget);
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
    expect(find.text('Meta: Muse Ember'), findsOneWidget);
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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Secret store (D-145).
void main() {
  testWidgets('admins move secrets to Infisical and back', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: SecretStoreSection(orgId: orgId))));
    await tester.pumpAndSettle();
    expect(find.textContaining("This server's vault"), findsOneWidget);
    await tester.tap(find.byKey(const Key('secretStore')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('infisicalProject')), 'proj-1');
    await tester.enterText(find.byKey(const Key('infisicalClientId')), 'cid');
    await tester.enterText(find.byKey(const Key('infisicalClientSecret')), 'secret');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveSecretStore')));
    await tester.pumpAndSettle();
    expect(backend.setStore!.moveExisting, isTrue);
    expect(find.textContaining('Infisical · proj-1 · prod'), findsOneWidget);
    await tester.tap(find.byKey(const Key('secretStore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('secretStoreVault')));
    await tester.pumpAndSettle();
    expect(find.textContaining("This server's vault"), findsOneWidget);
  });
}

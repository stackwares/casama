import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Encryption at rest (D-136).
void main() {
  testWidgets('owners turn on encryption after confirming, rotate the key, and turn it off', (tester) async {
    await setSize(tester, const Size(800, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: SingleChildScrollView(child: EncryptionSection(orgId: orgId)))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Off'), findsOneWidget);
    expect(find.byKey(const Key('rotateKey')), findsNothing);

    await tester.tap(find.byKey(const Key('encryption')));
    await tester.pumpAndSettle();
    expect(find.textContaining("can't be recovered"), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmEncryption')));
    await tester.pumpAndSettle();
    expect(backend.encryptionActions, ['set:true']);
    expect(find.textContaining('Turning on'), findsOneWidget);

    // Rotating asks first; cancelling changes nothing.
    await tester.tap(find.byKey(const Key('rotateKey')));
    await tester.pumpAndSettle();
    expect(find.text('Rotate the key?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backend.encryptionActions.last, 'set:true');
    await tester.tap(find.byKey(const Key('rotateKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmRotateKey')));
    await tester.pumpAndSettle();
    expect(backend.encryptionActions.last, 'rotate');
    expect(find.textContaining('Last rotated'), findsOneWidget);

    await tester.tap(find.byKey(const Key('encryption')));
    await tester.pumpAndSettle();
    expect(backend.encryptionActions.last, 'set:false');
    expect(find.textContaining('Turning off'), findsOneWidget);
  });
}

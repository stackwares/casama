import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/spaces.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Memory backends (D-137).
void main() {
  testWidgets('admins move memory to Honcho, copying what bots remember, and back', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: MemoryBackendSection(orgId: orgId))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Built in'), findsOneWidget);

    await tester.tap(find.byKey(const Key('memoryBackend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Honcho'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('memoryApiKey')), 'hch-secret-key');
    await tester.enterText(find.byKey(const Key('memoryWorkspace')), 'acme');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveMemoryBackend')));
    await tester.pumpAndSettle();
    expect(backend.setBackend!.provider, SetMemoryBackendRequestProviderEnum.honcho);
    expect(backend.setBackend!.apiKey, 'hch-secret-key');
    expect(backend.setBackend!.workspace, 'acme');
    expect(backend.setBackend!.copyExisting, isTrue);
    expect(find.textContaining('Honcho'), findsOneWidget);

    await tester.tap(find.byKey(const Key('memoryBackend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memoryBuiltIn')));
    await tester.pumpAndSettle();
    expect(backend.backend.provider, MemoryBackendProviderEnum.postgres);
    expect(find.textContaining('Built in'), findsOneWidget);
  });
}

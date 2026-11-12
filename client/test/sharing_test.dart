import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/sharing_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('share a private bot: add a person, change access, save', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SharingScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('ana@acme.test'), findsOneWidget);
    expect(find.byKey(const Key('add-me')), findsNothing); // the creator isn't listed
    await tester.tap(find.byKey(const Key('add-u-ben')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('access-u-ana')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Can edit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveSharing')));
    await tester.pumpAndSettle();
    final r = backend.savedAccess!;
    expect(r.visibility.value, 'private');
    expect(r.entries.map((e) => '${e.userId}:${e.access.value}'), ['u-ana:edit', 'u-ben:chat']);
  });
}

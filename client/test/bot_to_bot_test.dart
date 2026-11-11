import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('admins turn off bots talking to each other', (tester) async {
    await setSize(tester, const Size(800, 600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotToBotSwitch(orgId: orgId))));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('botToBot'))).value, isTrue);
    await tester.tap(find.byKey(const Key('botToBot')));
    await tester.pumpAndSettle();
    expect(backend.botToBot, isFalse);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('botToBot'))).value, isFalse);
  });
}

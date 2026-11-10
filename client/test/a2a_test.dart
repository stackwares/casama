import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/bots/a2a_sheet.dart';
import 'package:kasama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Agent-to-agent (D-140).
void main() {
  testWidgets('publishing needs the workspace switch; then the agent card is shown', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const Scaffold(body: BotA2aSheet(botId: botId))));
    await tester.pumpAndSettle();
    expect(find.text('Turn on agent-to-agent in workspace settings first.'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('a2aPublish'))).onChanged, isNull);

    await tester.pumpWidget(harness(backend, const Scaffold(body: A2aSwitch(orgId: orgId))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('a2aSwitch')));
    await tester.pumpAndSettle();
    expect(backend.a2aOn, isTrue);

    await tester.pumpWidget(harness(backend, const Scaffold(body: BotA2aSheet(botId: botId, key: Key('again')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('a2aPublish')));
    await tester.pumpAndSettle();
    expect(backend.a2aPublished, isTrue);
    expect(find.text('https://api.example.com/a2a/$botId/.well-known/agent-card.json'), findsOneWidget);
  });
}

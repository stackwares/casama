import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/inbox/inbox_screen.dart';
import 'package:kasama_app/features/settings/settings_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('For you shows the brief and suggestions; accepting hands it to the bot', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Today: 10:00 Standup.'), findsOneWidget);
    expect(find.text('Reply to Ana'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept-s1')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['accept:s1']);
  });

  testWidgets('dismissing can ask the bot not to suggest it again', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismiss-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismissNever')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['never:s1']);
  });

  testWidgets('check-ins turn on from bot settings', (tester) async {
    await setSize(tester, const Size(1000, 2400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BotSettingsScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('botCheckins')));
    await tester.tap(find.byKey(const Key('botCheckins')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkinsEnabled')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveCheckins')));
    await tester.pumpAndSettle();
    expect(backend.checkins.enabled, isTrue);
  });
}

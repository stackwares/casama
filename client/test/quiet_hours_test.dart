import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/settings/settings_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('quiet hours turn on from settings', (tester) async {
    await setSize(tester, const Size(800, 2400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('settingsQuietHours')));
    await tester.tap(find.byKey(const Key('settingsQuietHours')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quietEnabled')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveQuiet')));
    await tester.pumpAndSettle();
    expect(backend.quiet.enabled, isTrue);
    expect(find.text('22:00 to 07:00'), findsOneWidget);
  });

  testWidgets('a bot can be let through quiet hours', (tester) async {
    await setSize(tester, const Size(1000, 3000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BotSettingsScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('botQuiet')));
    await tester.tap(find.byKey(const Key('botQuiet')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Always notify me'));
    await tester.pumpAndSettle();
    expect(backend.botQuiets[botId]?.mode, 'always');
  });
}

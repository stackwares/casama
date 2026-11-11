import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/bot_template.dart';
import 'package:casama_app/features/settings/settings_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a bot is shared as a link, with memories only when ticked', (tester) async {
    await setSize(tester, const Size(1000, 3200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BotSettingsScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('shareBot')));
    await tester.tap(find.byKey(const Key('shareBot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('makeShareLink')));
    await tester.pumpAndSettle();
    expect(backend.shares, [false]);
    expect(find.text('https://app.example/import/t0k3n'), findsOneWidget);
  });

  testWidgets('importing a shared link previews everything before creating the bot', (tester) async {
    await setSize(tester, const Size(900, 2000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ImportBotScreen(token: 't0k3n')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importPreview')), findsOneWidget);
    expect(find.text('dunning'), findsOneWidget);
    expect(find.text('Weekly chase'), findsOneWidget);
    expect(find.text('Gmail'), findsOneWidget);
    await tester.tap(find.byKey(const Key('importMemories')));
    await tester.pumpAndSettle();
    final importButton = find.byKey(const Key('importBot'));
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    expect(backend.imported?.memories, isFalse);
    expect(backend.imported?.routines, isTrue);
  });
}

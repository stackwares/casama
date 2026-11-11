import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the list is only chats; "+" opens everything that adds to it, with imports under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(400, 900));
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    await tester.pumpWidget(harness(backend, const BotsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Import a bot'), findsNothing);
    expect(find.text('New group chat'), findsNothing);
    await tester.tap(find.byKey(const Key('createMenu')));
    await tester.pumpAndSettle();
    for (final id in ['bot', 'group']) {
      expect(find.byKey(Key('create-$id')), findsOneWidget);
    }
    for (final id in ['importBot', 'importAgent']) {
      expect(find.byKey(Key('create-$id')), findsNothing);
    }
    await tester.tap(find.byKey(const Key('advanced-chats.create')));
    await tester.pumpAndSettle();
    for (final id in ['importBot', 'importAgent']) {
      expect(find.byKey(Key('create-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('create-bot')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateBotSheet), findsOneWidget);
  });

  testWidgets('empty Chats tab hides Import a bot and Import an agent under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(400, 900));
    final backend = FakeBackend()..archived.add(botId);
    await tester.pumpWidget(harness(backend, const BotsScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('archivedBots')), findsOneWidget);
    expect(find.byKey(const Key('importBotFile')), findsNothing);
    expect(find.byKey(const Key('importAgent')), findsNothing);

    final advancedText = tester.widget<Text>(find.descendant(of: find.byKey(const Key('advanced-chats.empty')), matching: find.text('Advanced')));
    expect(advancedText.style?.decoration, TextDecoration.underline);

    await tester.tap(find.byKey(const Key('advanced-chats.empty')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('importBotFile')), findsOneWidget);
    expect(find.byKey(const Key('importAgent')), findsOneWidget);
  });
}

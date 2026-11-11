import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/bots_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the list is only chats; "+" opens everything that adds to it', (tester) async {
    await setSize(tester, const Size(400, 900));
    final backend = FakeBackend();
    backend.extraBots.add(backend.bot(id: 'bot-b', name: 'Bea'));
    await tester.pumpWidget(harness(backend, const BotsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Import a bot'), findsNothing);
    expect(find.text('New group chat'), findsNothing);
    await tester.tap(find.byKey(const Key('createMenu')));
    await tester.pumpAndSettle();
    for (final id in ['bot', 'group', 'importBot', 'importAgent']) {
      expect(find.byKey(Key('create-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('create-bot')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateBotSheet), findsOneWidget);
  });
}

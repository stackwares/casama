import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test('the drift cache keeps JSON snapshots by key', () async {
    final cache = DriftCache(NativeDatabase.memory());
    expect(await cache.read('bots:o1'), isNull);
    await cache.write('bots:o1', [
      {'id': 'b1', 'name': 'Ada'},
    ]);
    await cache.write('bots:o1', [
      {'id': 'b2', 'name': 'Bo'},
    ]);
    expect(await cache.read('bots:o1'), [
      {'id': 'b2', 'name': 'Bo'},
    ]);
    await cache.clear();
    expect(await cache.read('bots:o1'), isNull);
    await cache.close();
  });

  testWidgets('a chat opened once stays readable offline', (tester) async {
    await setSize(tester, const Size(700, 900));
    final cache = MemoryCache();
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(id: 'm1', role: 'user', text: 'What is due today?', createdAt: DateTime(2026, 11, 1)),
        ChatMessageView(id: 'm2', role: 'assistant', text: 'Two invoices are due.', createdAt: DateTime(2026, 11, 1, 0, 1)),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId), cache: cache));
    await tester.pumpAndSettle();
    expect(find.text('Two invoices are due.'), findsOneWidget);
    expect(cache.data.keys, containsAll(['msgs:$convId', 'bots:$orgId']));

    backend.offline = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId), cache: cache));
    await tester.pumpAndSettle();
    expect(find.text('Two invoices are due.'), findsOneWidget);
    expect(find.byKey(const Key('offlineNote')), findsOneWidget);
  });
}

// A message just sent can be edited without reopening the chat (Fix 13): its bubble takes the
// id the server gave it.
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the sent bubble takes the server id', () async {
    final backend = FakeBackend();
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    container.listen(chatControllerProvider(botId), (_, _) {});
    final c = container.read(chatControllerProvider(botId).notifier);
    await c.open(convId);
    await c.send('First');
    c.apply(ev(1, 'run.completed', {'final_message_id': 'a1'}));
    await c.send('Second');
    final mine = container.read(chatControllerProvider(botId)).entries.whereType<MessageEntry>().where((m) => m.role == 'user').toList();
    expect([for (final m in mine) m.text], ['First', 'Second']);
    expect(mine.every((m) => !m.id.startsWith('local-')), isTrue);
    expect(mine.map((m) => m.id).toSet(), hasLength(2));
  });

  testWidgets('a message just sent can be edited once the bot has answered', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'Plan a trip to Cebu');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    backend.runEventsController.add(ev(1, 'run.completed', {'final_message_id': 'a1'}));
    await tester.pumpAndSettle();

    final bubble = tester.widget<UserBubble>(find.byType(UserBubble));
    expect(bubble.onEdit, isNotNull);
    bubble.onEdit!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editField')), 'Plan a trip to Bohol');
    await tester.tap(find.byKey(const Key('sendEdit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.edits.single.$1, isNot(startsWith('local-')));
    expect(backend.edits.single.$2, 'Plan a trip to Bohol');
    backend.runEventsController.add(ev(2, 'run.completed', {'final_message_id': 'a2'}));
    await tester.pumpAndSettle();
  });
}

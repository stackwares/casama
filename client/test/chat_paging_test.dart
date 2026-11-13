// The thread loads a page at a time (Fix 10): the newest messages first, earlier ones on the way
// up, and a search hit older than the first page comes with the messages around it.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

List<ChatMessageView> _thread(int n) => [
  for (var i = 1; i <= n; i++)
    ChatMessageView(id: 'm-$i', role: i.isOdd ? 'user' : 'assistant', text: 'Message number $i', createdAt: DateTime(2026, 1, 1, 0, i)),
];

List<String> _ids(ChatState s) => [for (final e in s.entries.whereType<MessageEntry>()) e.id];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  (ProviderContainer, FakeBackend, ChatController) setUpChat(int n) {
    final backend = FakeBackend()..storedMessages = _thread(n);
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    container.listen(chatControllerProvider(botId), (_, _) {});
    return (container, backend, container.read(chatControllerProvider(botId).notifier));
  }

  test('opening a long chat asks for one page, not the whole thread', () async {
    final (container, backend, c) = setUpChat(200);
    await c.open(convId);
    final s = container.read(chatControllerProvider(botId));
    expect(backend.messageRequests.single.limit, ChatController.pageSize);
    expect(_ids(s).length, ChatController.pageSize);
    expect(_ids(s).last, 'm-200');
    expect(s.hasEarlier, isTrue);
  });

  test('a short chat has nothing earlier to load', () async {
    final (container, _, c) = setUpChat(12);
    await c.open(convId);
    expect(container.read(chatControllerProvider(botId)).hasEarlier, isFalse);
  });

  test('loading earlier adds the page before, up to the start of the thread', () async {
    final (container, backend, c) = setUpChat(150);
    await c.open(convId);
    await c.loadEarlier();
    var s = container.read(chatControllerProvider(botId));
    expect(backend.messageRequests.last, (limit: ChatController.pageSize, before: 'm-91', around: null));
    expect(_ids(s).first, 'm-31');
    expect(_ids(s).length, 120);
    expect(s.hasEarlier, isTrue);

    await c.loadEarlier();
    s = container.read(chatControllerProvider(botId));
    expect(_ids(s), [for (var i = 1; i <= 150; i++) 'm-$i']);
    expect(s.hasEarlier, isFalse);

    // A reload (a routine posted, another device sent) keeps what was scrolled back through.
    backend.storedMessages = _thread(151);
    await c.open(convId);
    s = container.read(chatControllerProvider(botId));
    expect(_ids(s).last, 'm-151');
    expect(_ids(s).length, 150);
  });

  test('a search hit older than the first page loads with what is around it', () async {
    final (container, backend, c) = setUpChat(300);
    await c.open(convId, around: 'm-100');
    final s = container.read(chatControllerProvider(botId));
    expect(backend.messageRequests.single.around, 'm-100');
    expect(_ids(s), contains('m-100'));
    expect(_ids(s).first, 'm-70');
    expect(_ids(s).last, 'm-300');
  });

  testWidgets('scrolling to the top of the thread loads earlier messages', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..storedMessages = _thread(150);
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.text('Message number 150'), findsOneWidget);
    expect(backend.messageRequests.where((r) => r.before != null), isEmpty);

    final list = find.byType(ListView).first;
    for (var i = 0; i < 40 && backend.messageRequests.every((r) => r.before == null); i++) {
      await tester.drag(list, const Offset(0, 800));
      await tester.pumpAndSettle();
    }
    expect(backend.messageRequests.last.before, 'm-91');
    // The page before is in the thread now.
    final container = ProviderScope.containerOf(tester.element(find.byType(ChatScreen)));
    expect(_ids(container.read(chatControllerProvider(botId))).first, 'm-31');
  });

  testWidgets('opening a search hit from far back shows that message', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..storedMessages = _thread(300);
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId, focusMessageId: 'm-100')));
    await tester.pumpAndSettle();
    expect(backend.messageRequests.first.around, 'm-100');
    expect(find.byKey(const Key('focusedMessage')), findsOneWidget);
    expect(find.text('Message number 100'), findsOneWidget);
    // The highlight fades after a moment.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}

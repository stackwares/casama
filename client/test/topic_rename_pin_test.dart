// Improve (app) 2: topics can be renamed and pinned from All topics; a pinned topic stays near the
// top and never moves to Older.
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Conversation _topic(
  String id,
  String? title, {
  DateTime? at,
  bool pinned = false,
}) => Conversation(
  id: id,
  botId: botId,
  title: title,
  lastMessageAt: at ?? DateTime.now().subtract(const Duration(hours: 1)),
  createdAt: DateTime(2026),
  kind: ConversationKindEnum.direct,
  botIds: const [botId],
  isMain: false,
  parentConversationId: convId,
  canDelete: true,
  pinned: pinned,
);

Future<FakeBackend> _openTopics(
  WidgetTester tester,
  List<Conversation> topics,
) async {
  await setSize(tester, const Size(900, 1000));
  final backend = FakeBackend()
    ..fakeChatIsGeneral = true
    ..topics = topics;
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('chatMoreMenu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('openConversations')));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('rename a topic from its row', (tester) async {
    final backend = await _openTopics(tester, [_topic('t1', 'Untitled thing')]);
    await tester.tap(find.byKey(const Key('topicMenu-t1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('renameConversation-t1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('topicNameField')),
      'Japan trip',
    );
    await tester.tap(find.byKey(const Key('saveTopicName')));
    await tester.pumpAndSettle();
    expect(backend.conversationUpdates.single, ('t1', 'Japan trip', null));
    expect(find.text('Japan trip'), findsWidgets);
  });

  testWidgets('pin a topic: it moves above newer ones and out of Older', (
    tester,
  ) async {
    final backend = await _openTopics(tester, [
      _topic('t-new', 'Newest', at: DateTime.now()),
      _topic(
        't-old',
        'Month old',
        at: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ]);
    // A month-old topic waits under Older until pinned.
    expect(find.byKey(const Key('olderTopics')), findsOneWidget);
    await tester.tap(find.byKey(const Key('topicMenu-t-old')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pinConversation-t-old')));
    await tester.pumpAndSettle();
    expect(backend.conversationUpdates.single, ('t-old', null, true));
    expect(find.byKey(const Key('olderTopics')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('topicRow-t-old'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('topicRow-t-new'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('topicRow-$convId'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('topicRow-t-old'))).dy),
    );
    // Unpin from the same menu.
    await tester.tap(find.byKey(const Key('topicMenu-t-old')));
    await tester.pumpAndSettle();
    expect(find.text('Unpin'), findsOneWidget);
  });

  testWidgets('General has no pin or rename, only delete', (tester) async {
    await _openTopics(tester, [_topic('t1', 'One')]);
    await tester.tap(find.byKey(const Key('topicMenu-$convId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('renameConversation-$convId')), findsNothing);
    expect(find.byKey(const Key('pinConversation-$convId')), findsNothing);
    expect(find.byKey(const Key('deleteConversation-$convId')), findsOneWidget);
  });

  test('splitTopics keeps a pinned topic live, after needs-you and before the rest', () {
    final now = DateTime(2026, 11, 14);
    final all = [
      _topic('a', 'A', at: now.subtract(const Duration(hours: 1))),
      _topic(
        'p',
        'P',
        at: now.subtract(const Duration(days: 40)),
        pinned: true,
      ),
    ];
    final split = splitTopics(all, now: now);
    expect(split.active.map((c) => c.id), ['p', 'a']);
    expect(split.older, isEmpty);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/groups/group_chats.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the sidebar counts what each bot waits on, and a group chat opens from its own section', (tester) async {
    await setSize(tester, const Size(1600, 1000));
    final backend = FakeBackend()
      ..groups.add(
        Conversation(id: 'g1', botId: botId, title: 'Every Bot', lastMessageAt: null, createdAt: DateTime(2026), kind: ConversationKindEnum.group, botIds: [botId]),
      );
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(backend)], child: const CasamaApp()));
    await tester.pumpAndSettle();
    // One pending approval for Ada; its approval notification isn't counted a second time.
    expect(find.descendant(of: find.byKey(const Key('sidebar-bot-$botId')), matching: find.text('1')), findsOneWidget);
    expect(find.text('Group chats'), findsOneWidget);
    expect(find.byType(GroupAvatar), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-group-g1')));
    await tester.pumpAndSettle();
    expect(find.text('Select a bot to chat'), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  test('answered requests and read notifications drop out of the badges', () async {
    final backend = FakeBackend()
      ..storedNotifications = [
        NotificationView(id: 'a', kind: 'approval_request', title: '', body: '', createdAt: DateTime.now(), botId: botId),
        NotificationView(id: 'r', kind: 'routine_result', title: '', body: '', link: '/bots/$botId/chat?c=c1', createdAt: DateTime.now(), botId: botId),
        NotificationView(id: 'o', kind: 'routine_result', title: '', body: '', createdAt: DateTime.now(), botId: 'other'),
      ];
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    final subs = [
      container.listen(approvalsProvider, (_, _) {}),
      container.listen(takeoversProvider, (_, _) {}),
      container.listen(notificationsProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final s in subs) {
        s.close();
      }
    });
    await container.read(notificationsProvider.future);
    await container.read(approvalsProvider.future);
    await container.read(takeoversProvider.future);
    // Ada: the pending approval and the routine result (the approval notification isn't extra).
    expect(container.read(botBadgeProvider(botId)), 2);
    await container.read(notificationsProvider.notifier).markBotChatRead(botId);
    expect(container.read(botBadgeProvider(botId)), 1);
    expect(container.read(botBadgeProvider('other')), 1);
  });
}

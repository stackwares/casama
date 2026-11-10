import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/backend.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/chat/widgets/chat_widgets.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  FakeBackend backend() => FakeBackend()
    ..storedMessages = [
      ChatMessageView(id: 'u2', role: 'user', text: 'Edited question', createdAt: DateTime(2026, 11, 1), siblingIndex: 2, siblingCount: 2),
      ChatMessageView(id: 'a2', role: 'assistant', text: 'Answer to the edit', createdAt: DateTime(2026, 11, 1, 0, 1)),
    ]
    ..siblings = ['u1', 'u2'];

  testWidgets('arrows switch between edited versions', (tester) async {
    await setSize(tester, const Size(1200, 900));
    final b = backend();
    await tester.pumpWidget(harness(b, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('branchPrev')));
    await tester.pumpAndSettle();
    expect(b.branchSwitches, ['u1']);
  });

  testWidgets('editing a sent message sends the new text for a rerun', (tester) async {
    await setSize(tester, const Size(1200, 900));
    final b = backend();
    await tester.pumpWidget(harness(b, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    tester.widget<UserBubble>(find.byType(UserBubble)).onEdit!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editField')), 'Better question');
    await tester.tap(find.byKey(const Key('sendEdit')));
    await tester.pumpAndSettle();
    expect(b.edits, [('u2', 'Better question')]);
  });
}

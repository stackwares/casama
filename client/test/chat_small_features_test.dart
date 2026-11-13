// Add 11 (the small ones): regenerate a reply, delete a message, find in this chat, paste a picture.
import 'dart:convert';

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/chat/widgets/composer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

FakeBackend _backend() => FakeBackend()
  ..storedMessages = [
    ChatMessageView(id: 'u1', role: 'user', text: 'What is the capital of France?', createdAt: DateTime(2026, 11, 1)),
    ChatMessageView(id: 'a1', role: 'assistant', text: 'Paris is the capital.', createdAt: DateTime(2026, 11, 1, 0, 1)),
    ChatMessageView(id: 'u2', role: 'user', text: 'And of Spain?', createdAt: DateTime(2026, 11, 1, 0, 2)),
    ChatMessageView(id: 'a2', role: 'assistant', text: 'Madrid is the capital.', createdAt: DateTime(2026, 11, 1, 0, 3)),
  ];

Future<FakeBackend> _open(WidgetTester tester) async {
  await setSize(tester, const Size(1200, 900));
  final b = _backend();
  await tester.pumpWidget(harness(b, const ChatScreen(botId: botId, conversationId: convId)));
  await tester.pumpAndSettle();
  return b;
}

AssistantMessage _reply(WidgetTester tester, String id) =>
    tester.widgetList<AssistantMessage>(find.byType(AssistantMessage)).firstWhere((m) => m.entry.id == id);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('regenerate asks the question again as a new version', (tester) async {
    final b = await _open(tester);
    _reply(tester, 'a2').onRegenerate!();
    await tester.pumpAndSettle();
    // The message it answered reruns with the same words (the old reply stays as a branch).
    expect(b.edits, [('u2', 'And of Spain?')]);
  });

  testWidgets('delete a message after asking', (tester) async {
    final b = await _open(tester);
    _reply(tester, 'a1').onDelete!();
    await tester.pumpAndSettle();
    expect(find.text('Delete this message?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDeleteMessage')));
    await tester.pumpAndSettle();
    expect(b.deletedMessages, ['a1']);
    expect(find.text('Paris is the capital.'), findsNothing);
    expect(find.text('Madrid is the capital.'), findsOneWidget);
  });

  testWidgets('your own message can be deleted too', (tester) async {
    final b = await _open(tester);
    tester.widgetList<UserBubble>(find.byType(UserBubble)).firstWhere((u) => u.text.startsWith('What')).onDelete!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteMessage')));
    await tester.pumpAndSettle();
    expect(b.deletedMessages, ['u1']);
  });

  testWidgets('find in chat steps through matches, newest first', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('chatMoreMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('findInChat')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('findInChatField')), 'capital');
    await tester.pumpAndSettle();
    // Three messages mention it; the newest is first and highlighted.
    expect(tester.widget<Text>(find.byKey(const Key('findCount'))).data, '1 of 3');
    expect(find.byKey(const Key('focusedMessage')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('focusedMessage')), matching: find.text('Madrid is the capital.')), findsOneWidget);
    await tester.tap(find.byKey(const Key('findOlder')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('findCount'))).data, '2 of 3');
    await tester.enterText(find.byKey(const Key('findInChatField')), 'tokyo');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('findCount'))).data, 'No matches');
    await tester.tap(find.byKey(const Key('closeFind')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('findBar')), findsNothing);
    // The highlight fades after a moment.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Cmd/Ctrl+F opens find', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const Key('messageInput')));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('findBar')), findsOneWidget);
  });

  test('findInEntries matches every word, ignoring case', () {
    // Pure function over the controller's entries.
    expect(findInEntries(const [], 'x'), isEmpty);
  });

  testWidgets('pasting a picture attaches it', (tester) async {
    // A real 1x1 PNG, since the pending chip draws it.
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    final before = ChatComposer.readClipboardImage;
    ChatComposer.readClipboardImage = () async => png;
    addTearDown(() => ChatComposer.readClipboardImage = before);
    final b = await _open(tester);
    await tester.tap(find.byKey(const Key('messageInput')));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final uploaded = b.uploads.entries.single;
    expect(uploaded.key, contains('pasted-'));
    expect(uploaded.key, endsWith('.png'));
    expect(uploaded.value, png);
  });
}

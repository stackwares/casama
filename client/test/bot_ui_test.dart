import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/backend.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _surface = 'ui_plan';
final _messages = <Object?>[
  {
    'version': '1.0',
    'createSurface': {'surfaceId': _surface, 'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json'},
  },
  {
    'version': '1.0',
    'updateComponents': {
      'surfaceId': _surface,
      'components': [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['title', 'choices'],
        },
        {'id': 'title', 'component': 'Text', 'text': 'Which plan?'},
        {
          'id': 'choices',
          'component': 'Row',
          'children': ['basic', 'pro'],
        },
        {
          'id': 'basic',
          'component': 'Button',
          'child': 'basicLabel',
          'action': {
            'event': {
              'name': 'choose',
              'context': {'plan': 'basic'},
            },
          },
        },
        {'id': 'basicLabel', 'component': 'Text', 'text': 'Basic'},
        {
          'id': 'pro',
          'component': 'Button',
          'variant': 'primary',
          'child': 'proLabel',
          'action': {
            'event': {
              'name': 'choose',
              'context': {'plan': 'pro'},
            },
          },
        },
        {'id': 'proLabel', 'component': 'Text', 'text': 'Pro'},
      ],
    },
  },
];

void main() {
  testWidgets('a bot UI renders in the chat, and tapping a choice sends it back to the bot', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: 'Pick a plan:',
          createdAt: DateTime(2026),
          ui: [UiPart(surfaceId: _surface, messages: _messages)],
        ),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('botUi-$_surface')), findsOneWidget);
    expect(find.text('Which plan?'), findsOneWidget);
    await tester.tap(find.text('Pro'));
    // The bot starts replying (a looping shimmer), so pump a few frames instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(backend.sentUiActions.single, {
      'surface_id': _surface,
      'name': 'choose',
      'context': {'plan': 'pro'},
      'source_component_id': 'pro',
    });
    expect(backend.sent.last, 'pro');
    // Answered: still visible, marked as sent.
    expect(find.text('Sent'), findsOneWidget);
  });
}

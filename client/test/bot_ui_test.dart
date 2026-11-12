import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/widgets/bot_ui.dart';

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

  test('the message for an action reads like the screen: picked labels, or the button tapped', () {
    const picks = BotUiAction(
      surfaceId: 's',
      name: 'welcome.focus',
      context: {'focus': ['research', 'email_calendar'], 'other': ''},
      sourceComponentId: 'go',
      label: 'Continue',
      optionLabels: {'research': 'Research', 'email_calendar': 'Email and calendar'},
    );
    expect(uiActionSummary(picks), 'Research, Email and calendar');
    const next = BotUiAction(surfaceId: 's', name: 'welcome.next', context: {}, sourceComponentId: 'next', label: 'Done, next');
    expect(uiActionSummary(next), 'Done, next');
    const empty = BotUiAction(surfaceId: 's', name: 'welcome.task', context: {'text': ''}, sourceComponentId: 'go', label: 'Go');
    expect(uiActionSummary(empty), 'Go');
    const skip = BotUiAction(surfaceId: 's', name: 'welcome.task', context: {'skip': true}, sourceComponentId: 'skip', label: 'Skip');
    expect(uiActionSummary(skip), 'Skip');
  });
}

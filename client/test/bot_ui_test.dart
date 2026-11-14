import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_api/casama_api.dart' show Integration, IntegrationKind, IntegrationStatusEnum;
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

  testWidgets('a Connect card closes once its app is connected', (tester) async {
    await setSize(tester, const Size(500, 900));
    const id = 'ui_connect';
    final backend = FakeBackend()
      ..integrationList.add(
        Integration(
          id: 'i1',
          orgId: 'org',
          kind: IntegrationKind.mcp,
          name: 'Google Calendar',
          appId: 'googlecalendar',
          status: IntegrationStatusEnum.ok,
          error: null,
          tools: const [],
          toolsCachedAt: null,
          createdAt: DateTime(2026),
        ),
      )
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: 'One thing first:',
          createdAt: DateTime(2026),
          ui: [
            UiPart(
              surfaceId: id,
              messages: [
                {
                  'version': '1.0',
                  'createSurface': {'surfaceId': id, 'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json'},
                },
                {
                  'version': '1.0',
                  'updateComponents': {
                    'surfaceId': id,
                    'components': [
                      {'id': 'root', 'component': 'Button', 'child': 'label', 'variant': 'primary', 'action': {
                        'event': {'name': 'app:connect', 'context': {'app': 'googlecalendar'}},
                      }},
                      {'id': 'label', 'component': 'Text', 'text': 'Connect Google Calendar'},
                    ],
                  },
                },
              ],
            ),
          ],
        ),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();

    expect(find.text('Connect Google Calendar'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('radio and checkbox pickers from the basic catalog render (they need an SDK Material)', (tester) async {
    await setSize(tester, const Size(500, 900));
    List<Object?> picker(String id, String variant) => [
      {
        'version': '1.0',
        'createSurface': {'surfaceId': id, 'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json'},
      },
      {
        'version': '1.0',
        'updateComponents': {
          'surfaceId': id,
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['pick', 'other'],
            },
            {'id': 'other', 'component': 'TextField', 'label': 'Other $variant', 'value': {'@path': '/other'}, 'variant': 'shortText'},
            {
              'id': 'pick',
              'component': 'ChoicePicker',
              'label': 'Pick $variant',
              'variant': variant,
              'value': {'@path': '/picked'},
              'options': [
                {'value': 'a', 'label': 'Apple $variant'},
                {'value': 'b', 'label': 'Banana $variant'},
              ],
            },
          ],
        },
      },
    ];
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: 'Pick:',
          createdAt: DateTime(2026),
          ui: [
            UiPart(surfaceId: 'radio', messages: picker('radio', 'mutuallyExclusive')),
            UiPart(surfaceId: 'checks', messages: picker('checks', 'multipleSelection')),
          ],
        ),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Lists are lettered (D-256), and two questions show one at a time with Skip and Next.
    expect(find.text('Apple mutuallyExclusive'), findsOneWidget);
    expect(find.text('Banana multipleSelection'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('botUi-radio')), matching: find.text('A')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('botUi-checks')), matching: find.text('B')), findsOneWidget);
    expect(find.text('Other mutuallyExclusive'), findsNothing);
    await tester.tap(find.text('Banana multipleSelection'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The text field (a basic SDK-Material component) is the next step.
    final next = find.descendant(of: find.byKey(const Key('botUi-radio')), matching: find.byKey(const Key('formNext')));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Other mutuallyExclusive'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

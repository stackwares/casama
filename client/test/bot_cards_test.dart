// Casama's cards in bots' replies (D-337): each renders what it was given, and the ones with their
// own buttons send their event with the values on screen.
import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/bot_ui_previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeBackend> show(
    WidgetTester tester,
    Map<String, Object?> card,
  ) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: 'Here you go.',
          createdAt: DateTime(2026),
          ui: [
            UiPart(
              surfaceId: 'ui_c',
              messages: [
                {
                  'version': '1.0',
                  'createSurface': {
                    'surfaceId': 'ui_c',
                    'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
                  },
                },
                {
                  'version': '1.0',
                  'updateComponents': {
                    'surfaceId': 'ui_c',
                    'components': [
                      {'id': 'root', ...card},
                    ],
                  },
                },
              ],
            ),
          ],
        ),
      ];
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  // After a tap the bot starts replying (a looping shimmer), so pump frames instead of settling.
  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Map<Object?, Object?> lastContext(FakeBackend b) =>
      b.sentUiActions.last['context']! as Map<Object?, Object?>;

  testWidgets('Event: Add to calendar sends the event as shown', (
    tester,
  ) async {
    final backend = await show(tester, {
      'component': 'Event',
      'title': 'Design review',
      'start': '2026-11-20T14:00',
      'end': '2026-11-20T15:00',
      'location': 'Room 4',
      'attendees': ['sarah@acme.com'],
    });
    expect(find.text('New event'), findsOneWidget);
    expect(find.text('Design review'), findsOneWidget);
    expect(find.text('Room 4'), findsOneWidget);
    expect(find.text('sarah@acme.com'), findsOneWidget);
    await tap(tester, find.byKey(const Key('eventAdd')));
    expect(backend.sentUiActions.last['name'], 'event.add');
    expect(lastContext(backend), {
      'title': 'Design review',
      'start': '2026-11-20T14:00',
      'end': '2026-11-20T15:00',
      'location': 'Room 4',
      'attendees': ['sarah@acme.com'],
    });
    expect(backend.sent.last, 'Add to calendar');
  });

  testWidgets('Event with actions false has no buttons', (tester) async {
    await show(tester, {
      'component': 'Event',
      'title': 'Lunch',
      'start': '2026-11-20',
      'actions': false,
    });
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.textContaining('All day'), findsOneWidget);
    expect(find.byKey(const Key('eventAdd')), findsNothing);
  });

  testWidgets('Agenda lists the day in time order', (tester) async {
    await show(tester, {
      'component': 'Agenda',
      'events': [
        {
          'title': 'Lunch with Ana',
          'start': '2026-11-20T12:30',
          'location': 'Cafe',
        },
        {
          'title': 'Standup',
          'start': '2026-11-20T09:00',
          'end': '2026-11-20T09:15',
        },
      ],
    });
    final standup = tester.getTopLeft(find.text('Standup')).dy;
    final lunch = tester.getTopLeft(find.text('Lunch with Ana')).dy;
    expect(standup < lunch, isTrue);
  });

  testWidgets('MessageList: rows show, and Reply sends the message it is on', (
    tester,
  ) async {
    final backend = await show(tester, {
      'component': 'MessageList',
      'messages': [
        {
          'id': 'm1',
          'from': 'Sarah Lee',
          'subject': 'Design review',
          'preview': 'Can we move it?',
          'unread': true,
        },
        {'id': 'm2', 'from': 'Bank', 'subject': 'Statement'},
      ],
    });
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.text('Can we move it?'), findsOneWidget);
    await tap(tester, find.byKey(const Key('messageReply-0')));
    expect(backend.sentUiActions.last['name'], 'message.reply');
    expect(lastContext(backend), {
      'id': 'm1',
      'from': 'Sarah Lee',
      'subject': 'Design review',
    });
    expect(backend.sent.last, 'Reply to Sarah Lee');
  });

  testWidgets('Checklist: Save shows after a change and sends what changed', (
    tester,
  ) async {
    final backend = await show(tester, {
      'component': 'Checklist',
      'items': [
        {'id': 't1', 'text': 'Book flights'},
        {'id': 't2', 'text': 'Pack', 'done': true},
      ],
    });
    expect(find.text('1 of 2 done'), findsOneWidget);
    expect(find.byKey(const Key('checklistSave')), findsNothing);
    await tester.tap(find.byKey(const Key('checkRow-0')));
    await tester.tap(find.byKey(const Key('checkRow-1')));
    await tester.pump();
    await tap(tester, find.byKey(const Key('checklistSave')));
    expect(backend.sentUiActions.last['name'], 'checklist.save');
    expect(lastContext(backend), {
      'done': ['t1'],
      'undone': ['t2'],
    });
  });

  testWidgets('Results: Choose sends the pick', (tester) async {
    final backend = await show(tester, {
      'component': 'Results',
      'layout': 'list',
      'choose': true,
      'items': [
        {
          'id': 'r1',
          'title': 'Blue Bottle',
          'subtitle': 'Coffee · 0.4 km',
          'rating': 4.6,
          'reviews': 1203,
          'price': r'$$',
        },
        {'id': 'r2', 'title': 'Sightglass'},
      ],
    });
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text(' (1203)'), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('result-1')),
        matching: find.text('Choose'),
      ),
    );
    expect(backend.sentUiActions.last['name'], 'result.choose');
    expect(lastContext(backend), {'id': 'r2', 'title': 'Sightglass'});
  });

  testWidgets('PersonPicker: Choose is off until someone is picked', (
    tester,
  ) async {
    final backend = await show(tester, {
      'component': 'PersonPicker',
      'people': [
        {'id': 'c1', 'name': 'Sarah Lee', 'detail': 'sarah@acme.com'},
        {'id': 'c2', 'name': 'Sarah Kim', 'detail': 'sk@gmail.com'},
      ],
    });
    expect(find.text('Who do you mean?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('personChoose')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('person-1')));
    await tester.pump();
    await tap(tester, find.byKey(const Key('personChoose')));
    expect(backend.sentUiActions.last['name'], 'person.pick');
    expect(lastContext(backend), {
      'people': [
        {'id': 'c2', 'name': 'Sarah Kim', 'detail': 'sk@gmail.com'},
      ],
    });
    expect(backend.sent.last, 'Sarah Kim');
  });

  testWidgets('Schedule: Cancel it sends its id', (tester) async {
    final backend = await show(tester, {
      'component': 'Schedule',
      'kind': 'routine',
      'title': 'Morning brief',
      'when': 'Weekdays at 8:00',
      'ref': 'rt_1',
    });
    expect(find.text('Routine'), findsOneWidget);
    expect(find.text('Weekdays at 8:00'), findsOneWidget);
    await tap(tester, find.byKey(const Key('scheduleCancel')));
    expect(backend.sentUiActions.last['name'], 'schedule.cancel');
    expect(lastContext(backend), {'ref': 'rt_1', 'title': 'Morning brief'});
  });

  testWidgets('Details and Stats show what they were given', (tester) async {
    await show(tester, {
      'component': 'Details',
      'title': 'Order',
      'rows': [
        {'label': 'Total', 'value': r'$42.00'},
      ],
      'footer': 'Arrives Friday',
    });
    expect(find.text('Total'), findsOneWidget);
    expect(find.text(r'$42.00'), findsOneWidget);
    expect(find.text('Arrives Friday'), findsOneWidget);
  });

  testWidgets('Stats show tiles and a chart', (tester) async {
    await show(tester, {
      'component': 'Stats',
      'title': 'Sleep this week',
      'stats': [
        {'label': 'Average', 'value': '7h 12m', 'change': '+8%', 'good': 'up'},
      ],
      'chart': {
        'type': 'bar',
        'labels': ['Mon', 'Tue', 'Wed'],
        'series': [
          {
            'values': [6.5, 7.2, 7.9],
          },
        ],
      },
    });
    expect(find.text('Sleep this week'), findsOneWidget);
    expect(find.text('+8%'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
  });

  group('approval previews (D-337)', () {
    test('a Gmail send shows as an email', () {
      final d = approvalDraft('composio.apps.gmail_send_email', {
        'recipient_email': 'sarah@acme.com',
        'subject': 'Hi',
        'body': 'Line one<br>Line two',
        'is_html': true,
      })!;
      expect(d.kind, 'email');
      expect(d.to, ['sarah@acme.com']);
      expect(d.body, 'Line one\nLine two');
      expect(d.app, 'gmail');
    });

    test('a Slack post shows as a message to its channel', () {
      final d = approvalDraft('composio.apps.slack_send_message', {
        'channel': '#design',
        'text': 'Shipping today',
      })!;
      expect(d.kind, 'message');
      expect(d.to, ['#design']);
    });

    test('a calendar create shows as an event', () {
      final e = approvalEvent('composio.apps.googlecalendar_create_event', {
        'summary': 'Design review',
        'start_datetime': '2026-11-20T14:00:00',
        'attendees': [
          {'email': 'sarah@acme.com'},
        ],
      })!;
      expect(e.title, 'Design review');
      expect(e.attendees, ['sarah@acme.com']);
      expect(e.actions, isFalse);
    });

    test('other tools keep the usual summary', () {
      expect(approvalDraft('shell.exec', {'command': 'ls'}), isNull);
      expect(
        approvalEvent('composio.apps.gmail_fetch_emails', {'query': 'x'}),
        isNull,
      );
      expect(
        approvalDraft('composio.apps.gmail_send_email', {
          'recipient_email': 'a@b.com',
        }),
        isNull,
      );
    });
  });
}

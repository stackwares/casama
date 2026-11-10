import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/devices/device_collector.dart';
import 'package:kasama_app/features/devices/device_connections_screen.dart';
import 'package:kasama_app/features/devices/device_sync.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class FakeCollector implements DeviceCollector {
  FakeCollector({this.allow = true});
  bool allow;
  final asked = <DeviceKind>[];
  final writes = <(String, Map<String, Object?>)>[];
  final ranges = <(DeviceKind, DateTime, DateTime)>[];

  @override
  Set<DeviceKind> get supported => {DeviceKind.calendar, DeviceKind.contacts};

  @override
  Future<bool> requestPermission(DeviceKind kind) async {
    asked.add(kind);
    return allow;
  }

  @override
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to) async {
    ranges.add((kind, from, to));
    return [
      DeviceReadingInput(kind: kind, periodStart: from, periodEnd: to, externalId: '${kind.value}-1', summary: {'n': 1}),
    ];
  }

  @override
  Future<Map<String, Object?>> write(String action, Map<String, Object?> params) async {
    writes.add((action, params));
    return {'event_id': 'E1'};
  }
}

DeviceRequest req(String id, String kind, String action, [Map<String, Object?> params = const {}]) =>
    DeviceRequest(id: id, sourceId: 's', kind: kind, action: DeviceRequestActionEnum.values.firstWhere((a) => a.value == action), params: params, createdAt: DateTime(2027));

/// Device connections (D-149).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('calendar events become one summary per day; contacts go in chunks', () {
    final from = DateTime(2027, 1, 7);
    final to = DateTime(2027, 1, 8, 23);
    final days = calendarDays(
      [
        (title: 'Lunch', start: DateTime(2027, 1, 7, 12), end: DateTime(2027, 1, 7, 13), allDay: false, location: 'Cafe', calendar: 'Home'),
        (title: 'Standup', start: DateTime(2027, 1, 7, 9), end: DateTime(2027, 1, 7, 9, 15), allDay: false, location: null, calendar: 'Work'),
        (title: 'Out of range', start: DateTime(2027, 1, 20, 9), end: DateTime(2027, 1, 20, 10), allDay: false, location: null, calendar: 'Work'),
      ],
      from,
      to,
    );
    expect(days.map((d) => d.externalId), ['cal-2027-01-07', 'cal-2027-01-08']);
    final events = days.first.summary['events'] as List;
    expect(events.map((e) => (e as Map)['title']), ['Standup', 'Lunch']);
    expect((events[1] as Map)['location'], 'Cafe');
    expect(days.last.summary['events'], isEmpty);

    final people = [
      for (var i = 0; i < 450; i++) (name: 'P$i', phones: ['+1555$i'], emails: <String>[]),
    ];
    final chunks = contactChunks(people, DateTime(2027));
    expect(chunks.map((c) => c.externalId), ['contacts-0', 'contacts-1', 'contacts-2']);
    expect((chunks.last.summary['contacts'] as List).length, 50);
  });

  test('turning a kind on asks the system first, then registers and uploads; off removes it', () async {
    final backend = FakeBackend();
    final collector = FakeCollector(allow: false);
    final sync = DeviceSync(backend, collector);
    expect(await sync.setKind(DeviceKind.calendar, true), isFalse);
    expect(backend.deviceSourcesSaved, isEmpty);
    collector.allow = true;
    expect(await sync.setKind(DeviceKind.calendar, true), isTrue);
    final key = await sync.deviceKey();
    expect(backend.deviceSourcesSaved[key]!.kinds.keys, ['calendar']);
    expect(backend.uploadedReadings.single.$2.externalId, 'calendar-1');
    // The calendar window looks a month ahead.
    expect(collector.ranges.single.$3.difference(collector.ranges.single.$2).inDays, 31);
    await sync.setKind(DeviceKind.calendar, false);
    expect(backend.deviceSourcesSaved[key]!.kinds, isEmpty);
    expect(await sync.deviceKey(), key);
  });

  test('answers fresh reads and writes, and refuses kinds it does not share', () async {
    final backend = FakeBackend();
    final collector = FakeCollector();
    final sync = DeviceSync(backend, collector);
    await sync.setKind(DeviceKind.calendar, true);
    backend.uploadedReadings.clear();
    backend.pendingDeviceRequests.addAll([
      req('r1', 'calendar', 'read', {'from': '2027-01-07T00:00:00Z', 'to': '2027-01-09T00:00:00Z'}),
      req('w1', 'calendar', 'calendar.create', {'title': 'Lunch'}),
      req('h1', 'health', 'read'),
    ]);
    await sync.answerPending();
    expect(backend.uploadedReadings.single.$3, 'r1');
    expect(collector.ranges.last.$2, DateTime.utc(2027, 1, 7));
    expect(collector.writes.single.$1, 'calendar.create');
    expect(collector.writes.single.$2, {'title': 'Lunch'});
    expect(backend.deviceAnswers.map((a) => (a.$1, a.$2)), [('w1', true), ('h1', false)]);
    expect(backend.pendingDeviceRequests, isEmpty);
  });

  testWidgets('settings: turn a kind on, keep it shorter, and stop a bot reading it', (tester) async {
    await setSize(tester, const Size(500, 1200));
    final backend = FakeBackend();
    final collector = FakeCollector();
    backend.grants.add(DeviceGrant(botId: botId, botName: 'Pal', kind: DeviceKind.calendar, createdAt: DateTime(2026)));
    await tester.pumpWidget(harness(backend, const DeviceConnectionsScreen(), overrides: [deviceCollectorProvider.overrideWithValue(collector)]));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deviceSwitch-calendar')));
    await tester.pumpAndSettle();
    expect(collector.asked, [DeviceKind.calendar]);
    expect(backend.deviceSourcesSaved.values.single.kinds.keys, ['calendar']);
    expect(find.byKey(const Key('grant-$botId-calendar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('deviceKeep-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 days').last);
    await tester.pumpAndSettle();
    expect(backend.deviceSourcesSaved.values.single.kinds['calendar']!.retentionDays, 30);

    await tester.tap(find.descendant(of: find.byKey(const Key('grant-$botId-calendar')), matching: find.byType(Icon)).last);
    await tester.pumpAndSettle();
    expect(backend.grants, isEmpty);
  });

  testWidgets('a bot asking for the calendar gets a one-tap card in chat', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), "what's on tomorrow?");
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController.add(ev(1, 'device.access_requested', {'kind': 'calendar', 'reason': 'To see your day.', 'bot_id': botId}));
    // The bot doesn't wait for the card; its run goes on and ends.
    backend.runEventsController.add(ev(2, 'run.completed', {'final_message_id': null}));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatDeviceAccess')), findsOneWidget);
    expect(find.textContaining('would like to use your calendar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deviceAccessAllow')));
    await tester.pumpAndSettle();
    expect(backend.grants.single.kind, DeviceKind.calendar);
    expect(find.text('Allowed to use your calendar'), findsOneWidget);
  });
}

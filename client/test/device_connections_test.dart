import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/devices/device_collector.dart';
import 'package:kasama_app/features/devices/device_connections_screen.dart';
import 'package:kasama_app/features/devices/device_events.dart';
import 'package:kasama_app/features/devices/device_sync.dart';
import 'package:kasama_app/features/devices/health_summary.dart';
import 'dart:async';

import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:native_geofence/native_geofence.dart' show GeofenceEvent;
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
  Future<bool> requestPermission(DeviceKind kind, {DeviceKindSettings? settings}) async {
    asked.add(kind);
    return allow;
  }

  @override
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to, {DeviceKindSettings? settings}) async {
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

class FakeTriggers implements DeviceTriggerPlatform {
  final watched = <List<String>>[];
  final notes = StreamController<({String app, String title, String text})>.broadcast();
  var stopped = 0;
  @override
  bool get supportsPlaces => true;
  @override
  bool get supportsNotifications => true;
  @override
  Future<bool> requestPlaces() async => true;
  @override
  Future<({double lat, double lng})?> currentLocation() async => (lat: 40.7, lng: -74.0);
  @override
  Future<void> watchPlaces(List<DevicePlace> places) async => watched.add([for (final p in places) p.name]);
  @override
  Future<void> stopPlaces() async => stopped++;
  @override
  Future<bool> requestNotifications() async => true;
  @override
  Stream<({String app, String title, String text})> notifications() => notes.stream;
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

  test('health: one summary per day (sleep counts for the morning it ends) and one per workout, no raw samples', () {
    HealthPoint p(String type, DateTime from, DateTime to, [num value = 0]) => (type: type, from: from, to: to, value: value, activity: null, energy: null, distance: null);
    final night = DateTime(2027, 1, 9, 23, 30);
    final points = <HealthPoint>[
      p('sleep_deep', night, night.add(const Duration(minutes: 90))),
      p('sleep_rem', night.add(const Duration(minutes: 90)), night.add(const Duration(minutes: 180))),
      p('sleep_light', night.add(const Duration(minutes: 180)), night.add(const Duration(minutes: 420))),
      p('sleep_awake', night.add(const Duration(minutes: 420)), night.add(const Duration(minutes: 430))),
      p('steps', DateTime(2027, 1, 10, 9), DateTime(2027, 1, 10, 10), 3000),
      p('steps', DateTime(2027, 1, 10, 17), DateTime(2027, 1, 10, 18), 4200),
      p('resting_hr', DateTime(2027, 1, 10, 8), DateTime(2027, 1, 10, 8), 58),
      p('resting_hr', DateTime(2027, 1, 10, 20), DateTime(2027, 1, 10, 20), 62),
      p('glucose', DateTime(2027, 1, 10, 8), DateTime(2027, 1, 10, 8), 99),
      (type: 'workout', from: DateTime(2027, 1, 10, 7), to: DateTime(2027, 1, 10, 7, 45), value: 0, activity: 'RUNNING', energy: 420.4, distance: 7012.6),
    ];
    final out = healthSummaries(points, DateTime(2027, 1, 10), DateTime(2027, 1, 10, 23, 59));
    final day = out.firstWhere((r) => r.externalId == 'health-2027-01-10').summary;
    expect(day['sleep'], {'start': '23:30', 'end': '06:40', 'minutes': 420, 'stages': {'deep': 90, 'rem': 90, 'light': 240, 'awake': 10}});
    expect(day['steps'], 7200);
    expect(day['resting_hr'], 60);
    expect(day['workouts'], 1);
    expect(day.containsKey('glucose'), isFalse);
    final w = out.firstWhere((r) => r.externalId.startsWith('workout-')).summary;
    expect(w, containsPair('activity', 'running'));
    expect(w['minutes'], 45);
    expect(w['distance_m'], 7013);
    // Extras only when turned on.
    final withExtras = healthSummaries(points, DateTime(2027, 1, 10), DateTime(2027, 1, 10, 23, 59), extras: {'glucose'});
    expect(withExtras.firstWhere((r) => r.externalId == 'health-2027-01-10').summary['glucose'], {'avg_mg_dl': 99, 'min_mg_dl': 99, 'max_mg_dl': 99});
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

  test('geofence events become arrive and leave with the place name only; codes are masked', () {
    final at = DateTime.utc(2027, 1, 10, 18, 2);
    expect(geofenceEvent('place:Home', GeofenceEvent.enter, at), {'id': 'geo-Home-arrive-${at.millisecondsSinceEpoch ~/ 60000}', 'type': 'arrive', 'at': '2027-01-10T18:02:00.000Z', 'place': 'Home'});
    expect(geofenceEvent('place:Work', GeofenceEvent.exit, at)!['type'], 'leave');
    expect(geofenceEvent('place:Gym', GeofenceEvent.dwell, at), isNull);
    expect(geofenceEvent('other', GeofenceEvent.enter, at), isNull);
    expect(maskCodes('Your code is 482913, ref AB12-CD34.'), 'Your code is ••••, ref ••••.');
    expect(maskCodes('Lunch at 12?'), 'Lunch at 12?');
  });

  test('places watch the named places; picked apps only, masked; "where am I" answered once', () async {
    final backend = FakeBackend();
    final triggers = FakeTriggers();
    final sync = DeviceSync(backend, FakeCollector(), triggers: triggers);
    await backend.saveDevicePlace(name: 'Home', latitude: 1, longitude: 2);
    expect(sync.supported, containsAll([DeviceKind.places, DeviceKind.notifications]));
    await sync.setKind(DeviceKind.places, true);
    expect(triggers.watched.single, ['Home']);
    await sync.setKind(DeviceKind.notifications, true, settings: DeviceKindSettings(apps: ['bank']));
    triggers.notes.add((app: 'com.mybank.app', title: 'Code', text: 'Your code is 482913'));
    triggers.notes.add((app: 'com.games.app', title: 'Play', text: 'now'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(backend.reportedEvents.map((e) => e.$2.app), ['com.mybank.app']);
    expect(backend.reportedEvents.single.$2.text, 'Your code is ••••');
    expect(await DeviceEventQueue.pending(), isEmpty);

    backend.pendingDeviceRequests.add(req('loc1', 'places', 'locate'));
    await sync.answerPending();
    expect((backend.deviceAnswers.single.$1, backend.deviceAnswers.single.$2), ('loc1', true));
    expect(backend.deviceAnswers.single.$3, {'lat': 40.7, 'lng': -74.0});
    await sync.setKind(DeviceKind.places, false);
    expect(triggers.stopped, 1);
    sync.dispose();
  });

  testWidgets('settings: turn a kind on, keep it shorter, and stop a bot reading it', (tester) async {
    await setSize(tester, const Size(500, 1200));
    final backend = FakeBackend();
    final collector = FakeCollector();
    backend.grants.add(DeviceGrant(botId: botId, botName: 'Pal', kind: DeviceKind.calendar, createdAt: DateTime(2026)));
    await tester.pumpWidget(harness(backend, const DeviceConnectionsScreen(), overrides: [deviceCollectorProvider.overrideWithValue(collector), deviceTriggerPlatformProvider.overrideWithValue(FakeTriggers())]));
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

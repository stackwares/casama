import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

/// Reads (and for calendar, writes) the data a person shares from this device (D-149).
abstract class DeviceCollector {
  /// Kinds this platform can share.
  Set<DeviceKind> get supported;

  /// Shows the system permission prompt (only when the person turns a kind on).
  Future<bool> requestPermission(DeviceKind kind);

  /// Summaries for [from]..[to] (or the whole set, for contacts).
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to);

  /// Does a write a run asked for (`calendar.create`, `reminders.create`); returns the result.
  Future<Map<String, Object?>> write(String action, Map<String, Object?> params);
}

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Groups calendar events into one summary per local day (re-uploading a day replaces it).
@visibleForTesting
List<DeviceReadingInput> calendarDays(List<({String title, DateTime start, DateTime end, bool allDay, String? location, String calendar})> events, DateTime from, DateTime to) {
  final byDay = <String, List<Map<String, Object?>>>{};
  for (var d = DateTime(from.year, from.month, from.day); !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
    byDay[_day(d)] = [];
  }
  for (final e in events) {
    final local = e.start.toLocal();
    final list = byDay[_day(local)];
    if (list == null || list.length >= 100) continue;
    list.add({
      'title': e.title,
      'start': e.start.toUtc().toIso8601String(),
      'end': e.end.toUtc().toIso8601String(),
      if (e.allDay) 'all_day': true,
      if (e.location != null && e.location!.isNotEmpty) 'location': e.location,
      'calendar': e.calendar,
    });
  }
  return [
    for (final entry in byDay.entries)
      () {
        final p = entry.key.split('-').map(int.parse).toList();
        final start = DateTime(p[0], p[1], p[2]);
        final list = entry.value..sort((a, b) => '${a['start']}'.compareTo('${b['start']}'));
        return DeviceReadingInput(
          kind: DeviceKind.calendar,
          periodStart: start.toUtc(),
          periodEnd: DateTime(p[0], p[1], p[2] + 1).subtract(const Duration(seconds: 1)).toUtc(),
          externalId: 'cal-${entry.key}',
          summary: {'date': entry.key, 'events': list},
        );
      }(),
  ];
}

/// Contacts in chunks of 200 (names, phone numbers and emails only).
@visibleForTesting
List<DeviceReadingInput> contactChunks(List<({String name, List<String> phones, List<String> emails})> contacts, DateTime now) => [
  for (var i = 0; i < contacts.length; i += 200)
    DeviceReadingInput(
      kind: DeviceKind.contacts,
      periodStart: now.toUtc(),
      periodEnd: now.toUtc(),
      externalId: 'contacts-${i ~/ 200}',
      summary: {
        'contacts': [
          for (final c in contacts.skip(i).take(200)) {'name': c.name, if (c.phones.isNotEmpty) 'phones': c.phones, if (c.emails.isNotEmpty) 'emails': c.emails},
        ],
      },
    ),
];

/// The phone's own calendar and contacts through their plugins (iOS and Android; contacts on macOS too).
class PluginDeviceCollector implements DeviceCollector {
  final _calendar = dc.DeviceCalendarPlugin();

  bool get _mobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  @override
  Set<DeviceKind> get supported => {if (_mobile) DeviceKind.calendar, if (_mobile || (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS)) DeviceKind.contacts};

  @override
  Future<bool> requestPermission(DeviceKind kind) async {
    switch (kind) {
      case DeviceKind.calendar:
        final has = await _calendar.hasPermissions();
        if (has.data == true) return true;
        return (await _calendar.requestPermissions()).data == true;
      case DeviceKind.contacts:
        final s = await FlutterContacts.permissions.request(PermissionType.read);
        return s == PermissionStatus.granted || s == PermissionStatus.limited;
      default:
        return false;
    }
  }

  @override
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to) async {
    switch (kind) {
      case DeviceKind.calendar:
        final cals = (await _calendar.retrieveCalendars()).data ?? const <dc.Calendar>[];
        final events = <({String title, DateTime start, DateTime end, bool allDay, String? location, String calendar})>[];
        for (final c in cals) {
          if (c.id == null) continue;
          final r = await _calendar.retrieveEvents(c.id, dc.RetrieveEventsParams(startDate: from, endDate: to));
          for (final e in r.data ?? const <dc.Event>[]) {
            if (e.start == null || e.end == null) continue;
            events.add((title: e.title ?? '(no title)', start: e.start!, end: e.end!, allDay: e.allDay ?? false, location: e.location, calendar: c.name ?? 'Calendar'));
          }
        }
        return calendarDays(events, from, to);
      case DeviceKind.contacts:
        final all = await FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone, ContactProperty.email});
        return contactChunks([
          for (final c in all) (name: c.displayName ?? '', phones: [for (final p in c.phones) p.number], emails: [for (final e in c.emails) e.address]),
        ], DateTime.now());
      default:
        return const [];
    }
  }

  @override
  Future<Map<String, Object?>> write(String action, Map<String, Object?> params) async {
    if (action != 'calendar.create') throw UnsupportedError('This device can\'t do $action yet.');
    final cals = ((await _calendar.retrieveCalendars()).data ?? const <dc.Calendar>[]).where((c) => c.isReadOnly != true).toList();
    if (cals.isEmpty) throw StateError('No calendar on this device can be written to.');
    final cal = cals.firstWhere((c) => c.isDefault == true, orElse: () => cals.first);
    final r = await _calendar.createOrUpdateEvent(
      dc.Event(
        cal.id,
        title: '${params['title']}',
        start: dc.TZDateTime.from(DateTime.parse('${params['start']}'), dc.UTC),
        end: dc.TZDateTime.from(DateTime.parse('${params['end']}'), dc.UTC),
        location: params['location'] as String?,
        description: params['notes'] as String?,
      ),
    );
    if (r == null || !r.isSuccess) throw StateError(r?.errors.map((e) => e.errorMessage).join('; ') ?? 'The calendar refused the event.');
    return {'event_id': r.data, 'calendar': cal.name};
  }
}

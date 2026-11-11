import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:health/health.dart' as hc;
import 'package:kasama_sdk/kasama_sdk.dart';

import 'health_summary.dart';

/// Reads (and for calendar, writes) the data a person shares from this device (D-149).
abstract class DeviceCollector {
  /// Kinds this platform can share.
  Set<DeviceKind> get supported;

  /// Shows the system permission prompt (only when the person turns a kind on, or an extra).
  Future<bool> requestPermission(DeviceKind kind, {DeviceKindSettings? settings});

  /// Summaries for [from]..[to] (or the whole set, for contacts).
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to, {DeviceKindSettings? settings});

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

  final _health = hc.Health();
  var _healthReady = false;

  // Read-only types for the daily summary; the extras only when turned on (D-150).
  static List<hc.HealthDataType> _healthTypes(DeviceKindSettings? s) => [
    hc.HealthDataType.SLEEP_SESSION,
    hc.HealthDataType.SLEEP_ASLEEP,
    hc.HealthDataType.SLEEP_DEEP,
    hc.HealthDataType.SLEEP_REM,
    hc.HealthDataType.SLEEP_LIGHT,
    hc.HealthDataType.SLEEP_AWAKE,
    hc.HealthDataType.STEPS,
    hc.HealthDataType.ACTIVE_ENERGY_BURNED,
    hc.HealthDataType.WORKOUT,
    hc.HealthDataType.RESTING_HEART_RATE,
    if (defaultTargetPlatform == TargetPlatform.iOS) hc.HealthDataType.HEART_RATE_VARIABILITY_SDNN else hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    hc.HealthDataType.WEIGHT,
    if (s?.extras?.any((e) => e.value == 'glucose') ?? false) hc.HealthDataType.BLOOD_GLUCOSE,
    if (s?.extras?.any((e) => e.value == 'blood_pressure') ?? false) ...[hc.HealthDataType.BLOOD_PRESSURE_SYSTOLIC, hc.HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
    if (s?.extras?.any((e) => e.value == 'cycle') ?? false) hc.HealthDataType.MENSTRUATION_FLOW,
  ];

  /// [_healthTypes] this phone's health store has: some exist only on Android (Health Connect's
  /// sleep sessions) or only on iOS, and asking for one the platform lacks fails the whole request.
  List<hc.HealthDataType> _availableHealthTypes(DeviceKindSettings? s) => _healthTypes(s).where(_health.isDataTypeAvailable).toList();

  Future<void> _healthInit() async {
    if (_healthReady) return;
    await _health.configure();
    _healthReady = true;
  }

  static String? _pointType(hc.HealthDataType t) => switch (t) {
    hc.HealthDataType.SLEEP_SESSION => 'sleep_session',
    hc.HealthDataType.SLEEP_ASLEEP => 'sleep_asleep',
    hc.HealthDataType.SLEEP_DEEP => 'sleep_deep',
    hc.HealthDataType.SLEEP_REM => 'sleep_rem',
    hc.HealthDataType.SLEEP_LIGHT => 'sleep_light',
    hc.HealthDataType.SLEEP_AWAKE => 'sleep_awake',
    hc.HealthDataType.STEPS => 'steps',
    hc.HealthDataType.ACTIVE_ENERGY_BURNED => 'active_energy',
    hc.HealthDataType.WORKOUT => 'workout',
    hc.HealthDataType.RESTING_HEART_RATE => 'resting_hr',
    hc.HealthDataType.HEART_RATE_VARIABILITY_SDNN || hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD => 'hrv',
    hc.HealthDataType.WEIGHT => 'weight',
    hc.HealthDataType.BLOOD_GLUCOSE => 'glucose',
    hc.HealthDataType.BLOOD_PRESSURE_SYSTOLIC => 'bp_sys',
    hc.HealthDataType.BLOOD_PRESSURE_DIASTOLIC => 'bp_dia',
    hc.HealthDataType.MENSTRUATION_FLOW => 'menstruation',
    _ => null,
  };

  @override
  Set<DeviceKind> get supported => {
    if (_mobile) DeviceKind.calendar,
    if (_mobile) DeviceKind.health,
    if (_mobile || (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS)) DeviceKind.contacts,
  };

  @override
  Future<bool> requestPermission(DeviceKind kind, {DeviceKindSettings? settings}) async {
    switch (kind) {
      case DeviceKind.health:
        await _healthInit();
        final types = _availableHealthTypes(settings);
        return _health.requestAuthorization(types, permissions: [for (final _ in types) hc.HealthDataAccess.READ]);
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
  Future<List<DeviceReadingInput>> collect(DeviceKind kind, DateTime from, DateTime to, {DeviceKindSettings? settings}) async {
    switch (kind) {
      case DeviceKind.health:
        await _healthInit();
        final raw = await _health.getHealthDataFromTypes(types: _availableHealthTypes(settings), startTime: from.subtract(const Duration(hours: 18)), endTime: to);
        final points = <HealthPoint>[];
        for (final p in raw) {
          final t = _pointType(p.type);
          if (t == null) continue;
          final v = p.value;
          if (v is hc.WorkoutHealthValue) {
            points.add((type: t, from: p.dateFrom, to: p.dateTo, value: 0, activity: v.workoutActivityType.name, energy: v.totalEnergyBurned, distance: v.totalDistance));
          } else if (v is hc.NumericHealthValue) {
            points.add((type: t, from: p.dateFrom, to: p.dateTo, value: v.numericValue, activity: null, energy: null, distance: null));
          } else if (t.startsWith('sleep') || t == 'menstruation') {
            points.add((type: t, from: p.dateFrom, to: p.dateTo, value: 0, activity: null, energy: null, distance: null));
          }
        }
        return healthSummaries(points, from, to, extras: {for (final e in settings?.extras ?? const <DeviceKindSettingsExtrasEnum>[]) e.value});
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

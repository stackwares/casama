import 'package:casama_sdk/casama_sdk.dart';

/// One reading from Apple Health or Health Connect, reduced to what a summary needs (D-150).
typedef HealthPoint = ({String type, DateTime from, DateTime to, num value, String? activity, num? energy, num? distance});

String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
num _round(num v, [int places = 1]) => num.parse(v.toStringAsFixed(places));

/// Daily summaries and one summary per workout; raw samples never leave the device.
/// Sleep that ends on a day counts for that day ("last night").
List<DeviceReadingInput> healthSummaries(List<HealthPoint> points, DateTime from, DateTime to, {Set<String> extras = const {}}) {
  final days = <String, List<HealthPoint>>{};
  final workouts = <HealthPoint>[];
  for (final p in points) {
    if (p.type == 'workout') {
      workouts.add(p);
      continue;
    }
    final at = p.type.startsWith('sleep') ? p.to.toLocal() : p.from.toLocal();
    if (at.isBefore(from) || at.isAfter(to)) continue;
    days.putIfAbsent(_day(at), () => []).add(p);
  }
  final out = <DeviceReadingInput>[];
  for (final entry in days.entries) {
    final ps = entry.value;
    num sum(String t) => ps.where((p) => p.type == t).fold<num>(0, (a, p) => a + p.value);
    num minutes(String t) => ps.where((p) => p.type == t).fold<num>(0, (a, p) => a + p.to.difference(p.from).inSeconds / 60);
    num? avg(String t) {
      final v = ps.where((p) => p.type == t).map((p) => p.value).toList();
      return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
    }

    num? last(String t) {
      final v = ps.where((p) => p.type == t).toList()..sort((a, b) => a.from.compareTo(b.from));
      return v.isEmpty ? null : v.last.value;
    }

    final summary = <String, Object?>{'type': 'day', 'date': entry.key};
    final sleepPoints = ps.where((p) => p.type.startsWith('sleep')).toList();
    if (sleepPoints.isNotEmpty) {
      final deep = minutes('sleep_deep'), rem = minutes('sleep_rem'), light = minutes('sleep_light'), awake = minutes('sleep_awake');
      final staged = deep + rem + light;
      final asleep = staged > 0 ? staged : (minutes('sleep_asleep') > 0 ? minutes('sleep_asleep') : (minutes('sleep_session') - awake).clamp(0, 1440));
      sleepPoints.sort((a, b) => a.from.compareTo(b.from));
      final end = sleepPoints.map((p) => p.to).reduce((a, b) => a.isAfter(b) ? a : b);
      summary['sleep'] = {
        'start': _hm(sleepPoints.first.from.toLocal()),
        'end': _hm(end.toLocal()),
        'minutes': asleep.round(),
        if (staged > 0) 'stages': {'deep': deep.round(), 'rem': rem.round(), 'light': light.round(), 'awake': awake.round()},
      };
    }
    if (ps.any((p) => p.type == 'steps')) summary['steps'] = sum('steps').round();
    if (ps.any((p) => p.type == 'active_energy')) summary['active_energy_kcal'] = sum('active_energy').round();
    final wk = workouts.where((w) => _day(w.from.toLocal()) == entry.key).length;
    if (wk > 0) summary['workouts'] = wk;
    final rhr = avg('resting_hr');
    if (rhr != null) summary['resting_hr'] = _round(rhr);
    final hrv = avg('hrv');
    if (hrv != null) summary['hrv_ms'] = _round(hrv);
    final weight = last('weight');
    if (weight != null) summary['weight_kg'] = _round(weight);
    if (extras.contains('glucose') && ps.any((p) => p.type == 'glucose')) {
      final g = ps.where((p) => p.type == 'glucose').map((p) => p.value).toList();
      summary['glucose'] = {'avg_mg_dl': _round(g.reduce((a, b) => a + b) / g.length), 'min_mg_dl': _round(g.reduce((a, b) => a < b ? a : b)), 'max_mg_dl': _round(g.reduce((a, b) => a > b ? a : b))};
    }
    if (extras.contains('blood_pressure') && ps.any((p) => p.type == 'bp_sys')) {
      summary['blood_pressure'] = {'systolic': _round(avg('bp_sys')!), 'diastolic': _round(avg('bp_dia') ?? 0)};
    }
    if (extras.contains('cycle') && ps.any((p) => p.type == 'menstruation')) summary['cycle'] = {'flow': 'logged'};
    final p = entry.key.split('-').map(int.parse).toList();
    out.add(
      DeviceReadingInput(
        kind: DeviceKind.health,
        periodStart: DateTime(p[0], p[1], p[2]).toUtc(),
        periodEnd: DateTime(p[0], p[1], p[2] + 1).subtract(const Duration(seconds: 1)).toUtc(),
        externalId: 'health-${entry.key}',
        summary: summary,
      ),
    );
  }
  for (final w in workouts) {
    if (w.from.isBefore(from) || w.from.isAfter(to)) continue;
    out.add(
      DeviceReadingInput(
        kind: DeviceKind.health,
        periodStart: w.from.toUtc(),
        periodEnd: w.to.toUtc(),
        externalId: 'workout-${w.from.toUtc().millisecondsSinceEpoch}',
        summary: {
          'type': 'workout',
          'activity': (w.activity ?? 'workout').toLowerCase().replaceAll('_', ' '),
          'start': w.from.toUtc().toIso8601String(),
          'end': w.to.toUtc().toIso8601String(),
          'minutes': w.to.difference(w.from).inMinutes,
          if (w.energy != null) 'energy_kcal': w.energy!.round(),
          if (w.distance != null) 'distance_m': w.distance!.round(),
        },
      ),
    );
  }
  out.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return out;
}

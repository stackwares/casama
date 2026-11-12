import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

/// Schedules in words (D-182): the common shapes of a five-field cron expression
/// (`minute hour day month weekday`), so people read "Weekdays at 9:00 AM" instead of `0 9 * * 1-5`.
/// Anything else keeps its raw expression.
sealed class CronShape {
  const CronShape();
}

/// `*/n * * * *` (and `* * * * *` for every minute).
final class CronEveryMinutes extends CronShape {
  const CronEveryMinutes(this.n);
  final int n;
}

/// `0 */n * * *`.
final class CronEveryHours extends CronShape {
  const CronEveryHours(this.n);
  final int n;
}

/// `m * * * *`.
final class CronHourly extends CronShape {
  const CronHourly(this.minute);
  final int minute;
}

/// `m h * * *` (or every weekday listed).
final class CronDaily extends CronShape {
  const CronDaily(this.hour, this.minute);
  final int hour;
  final int minute;
}

/// `m h * * d,d`: [days] are 0 (Sunday) to 6 (Saturday), sorted, never all seven.
final class CronWeekly extends CronShape {
  const CronWeekly(this.days, this.hour, this.minute);
  final List<int> days;
  final int hour;
  final int minute;

  bool get weekdays => days.length == 5 && const [1, 2, 3, 4, 5].every(days.contains);
  bool get weekends => days.length == 2 && days.contains(0) && days.contains(6);
}

/// `m h d * *`.
final class CronMonthly extends CronShape {
  const CronMonthly(this.day, this.hour, this.minute);
  final int day;
  final int hour;
  final int minute;
}

const _macros = {'@hourly': '0 * * * *', '@daily': '0 0 * * *', '@midnight': '0 0 * * *', '@weekly': '0 0 * * 0', '@monthly': '0 0 1 * *'};
const _dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
final _number = RegExp(r'^\d{1,2}$');

int? _num(String s, int min, int max) {
  if (!_number.hasMatch(s)) return null;
  final n = int.parse(s);
  return n < min || n > max ? null : n;
}

/// `*/n` or `0/n`, where [period] divides evenly by n (so the gaps stay equal).
int? _step(String s, int period) {
  final m = RegExp(r'^(?:\*|0)/(\d{1,2})$').firstMatch(s);
  if (m == null) return null;
  final n = int.parse(m.group(1)!);
  return n < 1 || n >= period || period % n != 0 ? null : n;
}

int? _day(String s) {
  final named = _dayNames.indexOf(s.toLowerCase());
  if (named >= 0) return named;
  final n = _num(s, 0, 7);
  return n == null ? null : n % 7;
}

/// The weekday field as a set of days, or null for anything we don't describe (steps, `?`, `L`).
Set<int>? _days(String field) {
  final days = <int>{};
  for (final part in field.split(',')) {
    final range = part.split('-');
    if (range.length == 1) {
      final d = _day(part);
      if (d == null) return null;
      days.add(d);
    } else if (range.length == 2) {
      final from = _day(range[0]);
      // A range may end on Sunday (`5-7`, `fri-sun`), so Sunday counts as 7 at the end.
      final end = _day(range[1]);
      final to = end == 0 && range[1] != '0' ? 7 : end;
      if (from == null || to == null || from > to) return null;
      for (var d = from; d <= to; d++) {
        days.add(d % 7);
      }
    } else {
      return null;
    }
  }
  return days;
}

/// What [cron] means, when it is one of the common shapes; null otherwise.
CronShape? parseCron(String cron) {
  var text = cron.trim().replaceAll(RegExp(r'\s+'), ' ');
  text = _macros[text.toLowerCase()] ?? text;
  final f = text.split(' ');
  if (f.length != 5) return null;
  final [min, hour, dom, month, dow] = f;
  if (month != '*') return null;
  final everyDay = dom == '*' && dow == '*';

  if (everyDay && hour == '*') {
    if (min == '*') return const CronEveryMinutes(1);
    final n = _step(min, 60);
    if (n != null) return CronEveryMinutes(n);
    final m = _num(min, 0, 59);
    return m == null ? null : CronHourly(m);
  }
  final m = _num(min, 0, 59);
  if (m == null) return null;
  if (everyDay) {
    final hours = _step(hour, 24);
    if (hours != null) return m == 0 ? CronEveryHours(hours) : null;
  }
  final h = _num(hour, 0, 23);
  if (h == null) return null;
  if (everyDay) return CronDaily(h, m);
  if (dom == '*') {
    final days = _days(dow);
    if (days == null || days.isEmpty) return null;
    if (days.length == 7) return CronDaily(h, m);
    return CronWeekly(days.toList()..sort(), h, m);
  }
  if (dow != '*') return null;
  final d = _num(dom, 1, 31);
  return d == null ? null : CronMonthly(d, h, m);
}

/// [cron] in words, or the expression itself when it isn't a common shape. [formatTime] renders
/// an hour and minute in the reader's locale (see [scheduleWords]).
String cronToWords(String cron, AppLocalizations l10n, {required String Function(int hour, int minute) formatTime}) {
  final shape = parseCron(cron);
  return switch (shape) {
    null => cron.trim(),
    CronEveryMinutes(:final n) => l10n.cronEveryMinutes(n),
    CronEveryHours(:final n) => l10n.cronEveryHours(n),
    CronHourly(minute: 0) => l10n.everyHour,
    CronHourly(:final minute) => l10n.cronHourlyAt(minute.toString().padLeft(2, '0')),
    CronDaily(:final hour, :final minute) => l10n.cronDailyAt(formatTime(hour, minute)),
    CronWeekly(weekdays: true, :final hour, :final minute) => l10n.cronWeekdaysAt(formatTime(hour, minute)),
    CronWeekly(weekends: true, :final hour, :final minute) => l10n.cronWeekendsAt(formatTime(hour, minute)),
    CronWeekly(:final days, :final hour, :final minute) => l10n.cronDaysAt(_dayList(days, l10n), formatTime(hour, minute)),
    CronMonthly(:final day, :final hour, :final minute) => l10n.cronMonthlyAt(day, formatTime(hour, minute)),
  };
}

/// "Mondays", "Mondays and Thursdays", "Mondays, Wednesdays and Fridays"; the week starts on Monday.
String _dayList(List<int> days, AppLocalizations l10n) {
  final names = [
    for (final d in [...days.where((d) => d != 0), if (days.contains(0)) 0]) l10n.cronDays(cronDayKey(d)),
  ];
  if (names.length == 1) return names.single;
  return l10n.cronAnd(names.sublist(0, names.length - 1).join(', '), names.last);
}

/// The `select` key the day-name strings use for 0 (Sunday) to 6 (Saturday).
String cronDayKey(int day) => _dayNames[day % 7];

/// [cron] in words with the time in the reader's locale and 12/24-hour setting.
String scheduleWords(BuildContext context, String cron) => cronToWords(
  cron,
  AppLocalizations.of(context),
  formatTime: (h, m) => TimeOfDay(hour: h, minute: m).format(context),
);

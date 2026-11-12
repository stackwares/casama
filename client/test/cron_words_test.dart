import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/routines/cron_words.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  // The app formats times with MaterialLocalizations; the default English one is enough here.
  String time(int h, int m) => const DefaultMaterialLocalizations().formatTimeOfDay(TimeOfDay(hour: h, minute: m));
  String words(String cron) => cronToWords(cron, l10n, formatTime: time);

  test('every N minutes and hours', () {
    expect(words('* * * * *'), 'Every minute');
    expect(words('*/1 * * * *'), 'Every minute');
    expect(words('*/15 * * * *'), 'Every 15 minutes');
    expect(words('0/5 * * * *'), 'Every 5 minutes');
    expect(words('0 */2 * * *'), 'Every 2 hours');
    expect(words('0 */1 * * *'), 'Every hour');
  });

  test('hourly at a minute', () {
    expect(words('0 * * * *'), 'Every hour');
    expect(words('5 * * * *'), 'Every hour at :05');
    expect(words('45 * * * *'), 'Every hour at :45');
    expect(words('@hourly'), 'Every hour');
  });

  test('daily, weekdays and weekends at a time', () {
    expect(words('0 9 * * *'), 'Every day at 9:00 AM');
    expect(words('30 18 * * *'), 'Every day at 6:30 PM');
    expect(words('@daily'), 'Every day at 12:00 AM');
    expect(words('0 9 * * 1-5'), 'Weekdays at 9:00 AM');
    expect(words('0 9 * * mon-fri'), 'Weekdays at 9:00 AM');
    expect(words('0 9 * * 1,2,3,4,5'), 'Weekdays at 9:00 AM');
    expect(words('0 10 * * 0,6'), 'Weekends at 10:00 AM');
    expect(words('0 10 * * 6-7'), 'Weekends at 10:00 AM');
    // Every day of the week reads as every day.
    expect(words('0 8 * * 0-6'), 'Every day at 8:00 AM');
    expect(words('0 8 * * *'), 'Every day at 8:00 AM');
  });

  test('one weekday or a list of them, Monday first', () {
    expect(words('0 9 * * 1'), 'Mondays at 9:00 AM');
    expect(words('0 9 * * MON'), 'Mondays at 9:00 AM');
    expect(words('0 9 * * 7'), 'Sundays at 9:00 AM');
    expect(words('0 9 * * 0'), 'Sundays at 9:00 AM');
    expect(words('0 9 * * 1,4'), 'Mondays and Thursdays at 9:00 AM');
    expect(words('15 7 * * 5,3,1'), 'Mondays, Wednesdays and Fridays at 7:15 AM');
    expect(words('0 9 * * 0,1'), 'Mondays and Sundays at 9:00 AM');
    expect(words('0 9 * * fri-sun'), 'Fridays, Saturdays and Sundays at 9:00 AM');
    expect(words('@weekly'), 'Sundays at 12:00 AM');
  });

  test('monthly on a day', () {
    expect(words('0 9 1 * *'), 'Day 1 of every month at 9:00 AM');
    expect(words('30 14 15 * *'), 'Day 15 of every month at 2:30 PM');
    expect(words('@monthly'), 'Day 1 of every month at 12:00 AM');
  });

  test('anything else keeps its expression', () {
    for (final raw in [
      '0 9 * 1 *', // a month
      '0 9 1 * 1', // a day of the month and a weekday
      '*/7 * * * *', // uneven gaps across the hour
      '30 */2 * * *',
      '0 9-17 * * *',
      '0 9 * * 1/2',
      '0 9 L * *',
      '0 0 9 * * *', // six fields
      '0 24 * * *',
      '60 9 * * *',
      '0 9 * * 8',
      '0 9 * * 5-1',
      '@yearly',
      'every day',
      '',
    ]) {
      expect(words(raw), raw.trim(), reason: raw);
      expect(parseCron(raw), isNull, reason: raw);
    }
    expect(words('  0 9 * 1 *  '), '0 9 * 1 *');
  });

  test('extra spaces are fine, and the shape is there for the editor', () {
    expect(words(' 0   9 * *  1-5 '), 'Weekdays at 9:00 AM');
    expect(parseCron('30 7 * * 3'), isA<CronWeekly>().having((w) => w.days, 'days', [3]).having((w) => w.hour, 'hour', 7).having((w) => w.minute, 'minute', 30));
    expect(parseCron('0 9 * * 1-5'), isA<CronWeekly>().having((w) => w.weekdays, 'weekdays', isTrue));
    expect(parseCron('0 9 * * *'), isA<CronDaily>());
    expect(parseCron('0 * * * *'), isA<CronHourly>().having((h) => h.minute, 'minute', 0));
  });

  test('day keys match the day-name strings', () {
    expect([for (var d = 0; d < 7; d++) l10n.cronDay(cronDayKey(d))], ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']);
  });
}

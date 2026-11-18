import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

/// Every date and time the app shows, in the person's language and clock. Pass server times
/// already converted with toLocal(); calendar days kept in UTC (the Usage chart) are formatted
/// as they are.
extension HumanDates on DateTime {
  // Jul 24, 2016 — rows, lists and past dates.
  String formattedDate(BuildContext context) => DateFormat.yMMMd(_locale(context)).format(this);

  // Sun, Jul 24 — dates people plan around (renewals, the next run).
  String formattedWeekdayDate(BuildContext context) => DateFormat.MMMEd(_locale(context)).format(this);

  // 2:44 PM, or 14:44 when the device uses 24-hour time.
  String formattedTime(BuildContext context) => (_use24h(context) ? DateFormat.Hm(_locale(context)) : DateFormat.jm(_locale(context))).format(this);

  // 2:44:05 PM, or 14:44:05 — event logs where seconds matter.
  String formattedTimeWithSeconds(BuildContext context) => (_use24h(context) ? DateFormat.Hms(_locale(context)) : DateFormat.jms(_locale(context))).format(this);

  // 24 — day labels under a chart.
  String formattedDayOfMonth(BuildContext context) => DateFormat.d(_locale(context)).format(this);

  // J — month labels under a chart (the language's own narrow month name).
  String formattedMonthInitial(BuildContext context) => DateFormat('LLLLL', _locale(context)).format(this);

  // Sun, Jul 24, 2016 · 2:44 PM — the exact moment, behind a relative time ("3 hours ago").
  String formattedExact(BuildContext context) => '${DateFormat.yMMMEd(_locale(context)).format(this)} · ${formattedTime(context)}';

  // Jul 2016 — a whole month.
  String formattedMonthYear(BuildContext context) => DateFormat.yMMM(_locale(context)).format(this);
}

/// A time of day saved as "HH:mm" (quiet hours, the morning brief), shown the way the person
/// reads times: "22:00" → "10:00 PM", or "22:00" on a 24-hour device. Other text comes back as it is.
String formatClockTime(BuildContext context, String hhmm) {
  final List<String> parts = hhmm.split(':');
  final int? hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
  final int? minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
  if (hour == null || minute == null) return hhmm;

  return DateTime(2000, 1, 1, hour, minute).formattedTime(context);
}

String _locale(BuildContext context) => Localizations.localeOf(context).toString();

bool _use24h(BuildContext context) => MediaQuery.alwaysUse24HourFormatOf(context);

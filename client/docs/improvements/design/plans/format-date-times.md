# Fix: Dates and times are built by hand instead of in the person's format

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-date-times
- **Needs new dependency**: none (`intl: ^0.20.3` is already in `pubspec.yaml`)

## Why

Some dates and times in Casama are glued together by hand, so they ignore the person's language
and clock: the Usage chart labels months with a hard-coded English `J F M A …` list and days
with bare numbers, its tooltip says only "J" or "14" (which J? which month?), the run timeline
prints `14:44:05` even on a 12-hour phone, and quiet hours and the morning brief show the stored
`22:00` instead of `10:00 PM`. The rest of the app's dates go through scattered
`MaterialLocalizations` calls. Collecting every date format in one `DateTime` extension built on
intl's `DateFormat` makes each date read naturally in the person's language and clock, and keeps
new screens from inventing their own.

## Where

Every date or time the app shows (a search for `DateFormat` finds nothing; there's no shared
date helper).

```dart
// lib/core/widgets.dart:205 — current (relativeTime: dates older than a week)
  return MaterialLocalizations.of(context).formatShortDate(t.toLocal());
```

```dart
// lib/features/usage/usage_screen.dart:114 — current (Usage → Spend by day chart)
            AppCard(child: SizedBox(height: 200, child: _DailyChart(days: _filled(days, period, DateTime.parse(report.since.toIso8601String()))))),
```

```dart
// lib/features/usage/usage_screen.dart:218 — current (chart data: labels built by hand, lines 218, 229, 233, 236)
List<(String, double)> _filled(List<UsageReportByDayInner> days, UsagePeriod period, DateTime since) {
        (const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][m - 1], byMonth['${now.year}-${m.toString().padLeft(2, '0')}'] ?? 0),
  final out = <(String, double)>[];
    out.add(('${d.day}', byDay[key] ?? 0));
```

```dart
// lib/features/usage/usage_screen.dart:241 — current
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days});
  final List<(String, double)> days;
```

```dart
// lib/features/usage/usage_screen.dart:282 — current (axis label under each bar)
                  child: Text(days[i].$1, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// lib/features/usage/usage_screen.dart:292 — current (tooltip: "J" or "14", then the amount)
              '${days[group.x].$1}\n${formatUsd(rod.toY)}',
```

```dart
// lib/features/timeline/timeline_screen.dart:234 — current (run timeline: always 24-hour hh:mm:ss)
    final hh = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
```

```dart
// lib/features/notifications/quiet_hours.dart:20 — current (Settings row: "22:00 to 07:00")
    q.enabled ? context.l10n.quietHoursRange(q.start, q.end) : context.l10n.off;
```

```dart
// lib/features/notifications/quiet_hours.dart:104 — current (sheet buttons: "From 22:00", "Until 07:00"; lines 104 and 107)
              child: OutlinedButton.icon(key: const Key('quietStart'), onPressed: _enabled ? () => _pick(true) : null, icon: const Icon(LucideIcons.moon, size: 18), label: Text('${l10n.from} $_start')),
              child: OutlinedButton.icon(key: const Key('quietEnd'), onPressed: _enabled ? () => _pick(false) : null, icon: const Icon(LucideIcons.sun, size: 18), label: Text('${l10n.until} $_end')),
```

```dart
// lib/features/notifications/checkins_sheet.dart:68 — current ("Morning brief at 08:00")
          label: Text('${l10n.briefTime} $_time'),
```

```dart
// lib/features/workspaces/workspace_files.dart:77 — current
                      if (sync.lastSyncedAt != null) l10n.gitSyncLast(MaterialLocalizations.of(context).formatShortDate(sync.lastSyncedAt!.toLocal())),
```

```dart
// lib/features/workspaces/spaces.dart:504 — current ("Last rotated Fri, Jan 5": a past date with no year)
            subtitle: s.rotatedAt != null ? l10n.encryptionRotated(MaterialLocalizations.of(context).formatMediumDate(s.rotatedAt!.toLocal())) : l10n.encryptionRotateHelp,
```

```dart
// lib/features/privacy/privacy_screen.dart:78 — current
          subtitle: l10n.accountDeletedBody(MaterialLocalizations.of(context).formatMediumDate(r.purgeAfter.toLocal())),
```

```dart
// lib/features/auth/passkeys_screen.dart:94 — current
                            ? l10n.passkeyAddedOn(MaterialLocalizations.of(context).formatShortDate(p.createdAt.toLocal()))
```

```dart
// lib/features/routines/routines_screen.dart:115 — current (a routine's next and last run)
  return '${MaterialLocalizations.of(context).formatMediumDate(local)} · ${TimeOfDay.fromDateTime(local).format(context)}';
```

```dart
// lib/features/skills/skill_proposals.dart:162 — current (lines 162 and 169)
              if (s.lastFailureAt != null) Text(l10n.skillLastFailure(MaterialLocalizations.of(context).formatShortDate(s.lastFailureAt!.toLocal()))),
                  title: Text(MaterialLocalizations.of(context).formatShortDate(r.createdAt.toLocal())),
```

```dart
// lib/features/pages/pages_screen.dart:126 — current
                            l10n.pageUpdated(MaterialLocalizations.of(context).formatShortDate(p.updatedAt.toLocal())),
```

```dart
// lib/features/billing/billing_screen.dart:318 — current (lines 318 and 319)
                            ? l10n.planEndsOn(MaterialLocalizations.of(context).formatMediumDate(until.toLocal()))
                            : l10n.planRenewsOn(MaterialLocalizations.of(context).formatMediumDate(until.toLocal())),
```

```dart
// test/quiet_hours_test.dart:23 — current (expects the stored 24-hour text)
    expect(find.text('22:00 to 07:00'), findsOneWidget);
```

## The fix

The article's fix: format with `DateFormat` from `intl` in the person's locale, and collect
every case in one `DateTime` extension so showing a date stays one call. Two adaptations for
this app: the locale comes from `Localizations.localeOf(context)` (never hard-coded), and the
patterns are intl's locale-aware skeletons (`yMMMd`, `MMMEd`, `jm`…) instead of fixed patterns
like `'d MMM yyyy'`, so each language also gets its own order (English "Jul 24, 2016", British
"24 Jul 2016"). Times follow the device's 24-hour setting the way the app's `TimeOfDay.format`
already does. No `initializeDateFormatting()` call is needed: `flutter_localizations` loads
intl's date data for every locale when the app starts.

New file `lib/core/date_format.dart` (target, complete):

```dart
import 'package:flutter/material.dart';
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
```

Which method where: `formattedDate` replaces every `formatShortDate` (same text today) and the
past-date `formatMediumDate` on the encryption row (gains the year it was missing);
`formattedWeekdayDate` replaces the `formatMediumDate` calls for upcoming dates (same text
today); `formattedTime` replaces `TimeOfDay.fromDateTime(...).format(context)` (same text
today).

Targets (each line keeps everything else as it is):

```dart
// lib/core/widgets.dart:205 — target
  return t.toLocal().formattedDate(context);
```

```dart
// lib/features/usage/usage_screen.dart:114 — target
            AppCard(child: SizedBox(height: 200, child: _DailyChart(days: _filled(days, period, DateTime.parse(report.since.toIso8601String())), byMonth: period == UsagePeriod.year))),
```

```dart
// lib/features/usage/usage_screen.dart:216 — target (the whole function; the chart now carries real dates)
/// Every day of the period up to today, zero where nothing was used, so the chart has no gaps.
/// A year is shown by month (each month as its first day). The dates are UTC calendar days.
List<(DateTime, double)> _filled(List<UsageReportByDayInner> days, UsagePeriod period, DateTime since) {
  final byDay = {for (final d in days) d.day: d.costUsd.toDouble()};
  final now = DateTime.now().toUtc();
  if (period == UsagePeriod.year) {
    final byMonth = <String, double>{};
    for (final d in days) {
      final m = d.day.substring(0, 7);
      byMonth[m] = (byMonth[m] ?? 0) + d.costUsd.toDouble();
    }
    return [
      for (var m = 1; m <= now.month; m++)
        (DateTime.utc(now.year, m), byMonth['${now.year}-${m.toString().padLeft(2, '0')}'] ?? 0),
    ];
  }
  final start = DateTime.utc(since.toUtc().year, since.toUtc().month, since.toUtc().day);
  final out = <(DateTime, double)>[];
  for (var d = start; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
    final key = d.toIso8601String().substring(0, 10);
    out.add((d, byDay[key] ?? 0));
  }
  return out;
}
```

```dart
// lib/features/usage/usage_screen.dart:241 — target
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days, required this.byMonth});
  final List<(DateTime, double)> days;

  /// The year view: one bar per month instead of one per day.
  final bool byMonth;
```

```dart
// lib/features/usage/usage_screen.dart:282 — target
                  child: Text(byMonth ? days[i].$1.formattedMonthInitial(context) : days[i].$1.formattedDayOfMonth(context), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
```

```dart
// lib/features/usage/usage_screen.dart:292 — target (tooltip: "Jul 2026" or "Sun, Jul 24", then the amount)
              '${byMonth ? days[group.x].$1.formattedMonthYear(context) : days[group.x].$1.formattedWeekdayDate(context)}\n${formatUsd(rod.toY)}',
```

```dart
// lib/features/timeline/timeline_screen.dart:234 — target
    final hh = time.formattedTimeWithSeconds(context);
```

```dart
// lib/features/notifications/quiet_hours.dart:20 — target
    q.enabled ? context.l10n.quietHoursRange(formatClockTime(context, q.start), formatClockTime(context, q.end)) : context.l10n.off;
```

```dart
// lib/features/notifications/quiet_hours.dart:104 and 107 — target (only the label: part changes)
              child: OutlinedButton.icon(key: const Key('quietStart'), onPressed: _enabled ? () => _pick(true) : null, icon: const Icon(LucideIcons.moon, size: 18), label: Text('${l10n.from} ${formatClockTime(context, _start)}')),
              child: OutlinedButton.icon(key: const Key('quietEnd'), onPressed: _enabled ? () => _pick(false) : null, icon: const Icon(LucideIcons.sun, size: 18), label: Text('${l10n.until} ${formatClockTime(context, _end)}')),
```

```dart
// lib/features/notifications/checkins_sheet.dart:68 — target
          label: Text('${l10n.briefTime} ${formatClockTime(context, _time)}'),
```

```dart
// lib/features/workspaces/workspace_files.dart:77 — target
                      if (sync.lastSyncedAt != null) l10n.gitSyncLast(sync.lastSyncedAt!.toLocal().formattedDate(context)),
```

```dart
// lib/features/workspaces/spaces.dart:504 — target
            subtitle: s.rotatedAt != null ? l10n.encryptionRotated(s.rotatedAt!.toLocal().formattedDate(context)) : l10n.encryptionRotateHelp,
```

```dart
// lib/features/privacy/privacy_screen.dart:78 — target
          subtitle: l10n.accountDeletedBody(r.purgeAfter.toLocal().formattedWeekdayDate(context)),
```

```dart
// lib/features/auth/passkeys_screen.dart:94 — target
                            ? l10n.passkeyAddedOn(p.createdAt.toLocal().formattedDate(context))
```

```dart
// lib/features/routines/routines_screen.dart:115 — target
  return '${local.formattedWeekdayDate(context)} · ${local.formattedTime(context)}';
```

```dart
// lib/features/skills/skill_proposals.dart:162 and 169 — target
              if (s.lastFailureAt != null) Text(l10n.skillLastFailure(s.lastFailureAt!.toLocal().formattedDate(context))),
                  title: Text(r.createdAt.toLocal().formattedDate(context)),
```

```dart
// lib/features/pages/pages_screen.dart:126 — target
                            l10n.pageUpdated(p.updatedAt.toLocal().formattedDate(context)),
```

```dart
// lib/features/billing/billing_screen.dart:318 and 319 — target
                            ? l10n.planEndsOn(until.toLocal().formattedWeekdayDate(context))
                            : l10n.planRenewsOn(until.toLocal().formattedWeekdayDate(context)),
```

```dart
// test/quiet_hours_test.dart:23 — target (tests run on a 12-hour clock)
    expect(find.text('10:00 PM to 7:00 AM'), findsOneWidget);
```

## Steps

Line numbers are from when this plan was written. If a file has shifted since (for example
new imports were added at the top), find each line by its quoted text; only a change in the
quoted text itself is a reason to stop.

Edit by hand. Never run `dart format` on existing files.

1. Create `lib/core/date_format.dart` with exactly the content in "The fix", then run
   `dart format -l 200 lib/core/date_format.dart` (the only source file you may format).
2. `lib/core/widgets.dart`: add `import 'date_format.dart';` directly below the line
   `import '../l10n/generated/app_localizations.dart';`, then replace line 205 with its target.
3. `lib/features/usage/usage_screen.dart`:
   a. Add `import '../../core/date_format.dart';` directly above
      `import '../../core/providers.dart';`.
   b. Line 114: add `, byMonth: period == UsagePeriod.year` right after the closing `)` of
      `_filled(…)` so the line equals its target.
   c. Replace the whole `_filled` function, from its doc comment
      `/// Every day of the period up to today, …` (line 216) to its closing `}` (line 239), with
      the target.
   d. Replace the three `_DailyChart` lines (241–243) with the six target lines; the blank line
      that already follows them stays.
   e. Line 282: replace `child: Text(days[i].$1, style:` with
      `child: Text(byMonth ? days[i].$1.formattedMonthInitial(context) : days[i].$1.formattedDayOfMonth(context), style:`.
   f. Line 292: replace `'${days[group.x].$1}\n` with
      `'${byMonth ? days[group.x].$1.formattedMonthYear(context) : days[group.x].$1.formattedWeekdayDate(context)}\n`.
      Leave the `${formatUsd(…)}` part of the line exactly as it is now.
4. `lib/features/timeline/timeline_screen.dart`: add `import '../../core/date_format.dart';`
   directly above `import '../../core/providers.dart';`, then replace line 234 with its target
   (line 233 `final time = item.envelope.ts.toLocal();` and line 307 `'#${item.seq}  $hh'` stay).
5. `lib/features/notifications/quiet_hours.dart`: add `import '../../core/date_format.dart';`
   directly above `import '../../core/providers.dart';`, then change line 20 and the `label:`
   parts of lines 104 and 107 to their targets. Lines 75–79 (`_pick`, which stores "HH:mm")
   stay as they are: that's the saved value, not display.
6. `lib/features/notifications/checkins_sheet.dart`: add
   `import '../../core/date_format.dart';` directly above `import '../../core/providers.dart';`,
   then replace line 68 with its target. Line 65 (stores "HH:mm") stays.
7. For each of these files, add `import '../../core/date_format.dart';` directly above
   `import '../../core/providers.dart';`, then replace the quoted lines with their targets:
   `lib/features/workspaces/workspace_files.dart` (77), `lib/features/workspaces/spaces.dart`
   (504), `lib/features/privacy/privacy_screen.dart` (78),
   `lib/features/auth/passkeys_screen.dart` (94), `lib/features/routines/routines_screen.dart`
   (115; line 114 `final local = t.toLocal();` stays), `lib/features/skills/skill_proposals.dart`
   (162 and 169), `lib/features/pages/pages_screen.dart` (126),
   `lib/features/billing/billing_screen.dart` (318 and 319).
8. `test/quiet_hours_test.dart` line 23: replace `'22:00 to 07:00'` with `'10:00 PM to 7:00 AM'`.
9. Create `test/date_format_test.dart` with this content, then run
   `dart format -l 200 test/date_format_test.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:casama_app/core/date_format.dart';
   import 'package:casama_app/l10n/generated/app_localizations.dart';

   void main() {
     final moment = DateTime(2016, 7, 24, 14, 44, 5); // a Sunday

     Future<BuildContext> pumpContext(WidgetTester tester, {bool use24h = false}) async {
       tester.platformDispatcher.alwaysUse24HourFormatTestValue = use24h;
       addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
       late BuildContext captured;
       await tester.pumpWidget(
         MaterialApp(
           localizationsDelegates: AppLocalizations.localizationsDelegates,
           supportedLocales: AppLocalizations.supportedLocales,
           home: Builder(
             builder: (context) {
               captured = context;
               return const SizedBox();
             },
           ),
         ),
       );
       return captured;
     }

     testWidgets('dates read the way English writes them', (tester) async {
       final context = await pumpContext(tester);
       expect(moment.formattedDate(context), 'Jul 24, 2016');
       expect(moment.formattedWeekdayDate(context), 'Sun, Jul 24');
       expect(moment.formattedDayOfMonth(context), '24');
       expect(moment.formattedMonthInitial(context), 'J');
       expect(moment.formattedMonthYear(context), 'Jul 2016');
     });

     testWidgets('times follow the 12-hour clock', (tester) async {
       final context = await pumpContext(tester);
       expect(moment.formattedTime(context), '2:44 PM');
       expect(moment.formattedTimeWithSeconds(context), '2:44:05 PM');
       expect(formatClockTime(context, '22:00'), '10:00 PM');
       expect(formatClockTime(context, '07:00'), '7:00 AM');
     });

     testWidgets('times follow the device when it uses 24-hour time', (tester) async {
       final context = await pumpContext(tester, use24h: true);
       expect(moment.formattedTime(context), '14:44');
       expect(moment.formattedTimeWithSeconds(context), '14:44:05');
       expect(formatClockTime(context, '07:00'), '07:00');
     });

     testWidgets('a saved time that is not HH:mm is shown as it is', (tester) async {
       final context = await pumpContext(tester);
       expect(formatClockTime(context, 'soon'), 'soon');
     });
   }
   ```
10. From `client/`, run
    `flutter test test/date_format_test.dart test/quiet_hours_test.dart test/checkins_test.dart test/design_test.dart test/encryption_test.dart test/passkeys_test.dart test/pages_test.dart test/skill_proposals_test.dart test/billing_test.dart test/privacy_test.dart test/routine_editor_test.dart test/app_test.dart test/phone_layout_test.dart`.
    All must pass.

## Check it

- `dart analyze lib/core/date_format.dart lib/core/widgets.dart lib/features/usage/usage_screen.dart lib/features/timeline/timeline_screen.dart lib/features/notifications/quiet_hours.dart lib/features/notifications/checkins_sheet.dart lib/features/workspaces/workspace_files.dart lib/features/workspaces/spaces.dart lib/features/privacy/privacy_screen.dart lib/features/auth/passkeys_screen.dart lib/features/routines/routines_screen.dart lib/features/skills/skill_proposals.dart lib/features/pages/pages_screen.dart lib/features/billing/billing_screen.dart test/date_format_test.dart test/quiet_hours_test.dart` reports no issues.
- `grep -c "MaterialLocalizations.of(context).format" <file>` → 0 for each of:
  `lib/core/widgets.dart`, `lib/features/workspaces/workspace_files.dart`,
  `lib/features/workspaces/spaces.dart`, `lib/features/privacy/privacy_screen.dart`,
  `lib/features/auth/passkeys_screen.dart`, `lib/features/routines/routines_screen.dart`,
  `lib/features/skills/skill_proposals.dart`, `lib/features/pages/pages_screen.dart`,
  `lib/features/billing/billing_screen.dart`.
- `grep -c "'J', 'F', 'M'" lib/features/usage/usage_screen.dart` → 0
- `grep -c "formattedMonthInitial(context)" lib/features/usage/usage_screen.dart` → 1
- `grep -c "formattedWeekdayDate(context)" lib/features/usage/usage_screen.dart` → 1
- `grep -c "byMonth: period == UsagePeriod.year" lib/features/usage/usage_screen.dart` → 1
- `grep -c "padLeft" lib/features/timeline/timeline_screen.dart` → 0
- `grep -c "formattedTimeWithSeconds(context)" lib/features/timeline/timeline_screen.dart` → 1
- `grep -c "formatClockTime(context" lib/features/notifications/quiet_hours.dart` → 3
- `grep -c "formatClockTime(context, _time)" lib/features/notifications/checkins_sheet.dart` → 1
- `grep -c "TimeOfDay.fromDateTime" lib/features/routines/routines_screen.dart` → 1 (only the time picker's `initialTime` at line 326 remains)
- `grep -c "10:00 PM to 7:00 AM" test/quiet_hours_test.dart` → 1
- The `flutter test` run in step 10 passes.

## Don't touch

- `lib/features/chat/widgets/error_details.dart` (`'When: ${e.at!.toUtc().toIso8601String()}'`):
  a support report that is English and UTC on purpose (its own comment says so).
- `usageSummary`, `usageCsv` and the export file name in `usage_screen.dart`: text and files for
  a bot or a spreadsheet, where ISO dates are the clearest form.
- The stored `"HH:mm"` values (`_pick` in `quiet_hours.dart`, line 65 of `checkins_sheet.dart`)
  and every date sent to the server (`device_collector.dart`, `health_summary.dart`,
  `desktop_watch.dart`, `device_events.dart`, `device_sync.dart`).
- `relativeTime`'s "just now / 5 minutes ago / yesterday" parts (already translated), the
  `TimeOfDay.format(context)` calls in `cron_words.dart` and the routine editor's time button
  (already localized), and the date pickers.
- Money formatting on the same lines (`formatUsd(…)`): out of scope; keep it as it is.
- Never run `dart format` on existing files or directories (only on the two new files).
- No git commands (others commit in this shared tree).
- No new dependencies. No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on
  since this plan was written). One exception: on `usage_screen.dart` line 292, the
  `formatUsd(rod.toY)` call may already carry a second argument (for example
  `formatUsd(rod.toY, context.l10n.localeName)`); keep it exactly as it is and change only the
  label part.
- A date test in step 9 expects a different text than the app produces (for example a different
  space before PM): report the actual output instead of changing the expectation.
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to
open to see it. Not a list of files, the steps already have those. For example: every date and
time now comes from one formatter in the person's language and clock, so quiet hours read
"10:00 PM to 7:00 AM" on a 12-hour phone and the Usage chart labels and tooltips name real
months and days; open Settings → Usage, pick Year and tap a bar.

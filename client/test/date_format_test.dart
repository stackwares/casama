import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/date_format.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

void main() {
  final moment = DateTime(2016, 7, 24, 14, 44, 5); // a Sunday

  Future<BuildContext> pumpContext(WidgetTester tester, {bool use24h = false}) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The device's 24-hour setting, as the app reads it.
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24h), child: child!),
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
    expect(moment.formattedTime(context), '2:44\u202fPM');
    expect(moment.formattedTimeWithSeconds(context), '2:44:05\u202fPM');
    expect(formatClockTime(context, '22:00'), '10:00\u202fPM');
    expect(formatClockTime(context, '07:00'), '7:00\u202fAM');
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

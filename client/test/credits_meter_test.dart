import 'package:casama/features/usage/usage_screen.dart';
import 'package:casama/core/backend.dart' show UsageFilter;
import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// $1.00 left, $0.10 billed this month; ten runs at $0.05 each.
class _MeterBackend extends FakeBackend {
  _MeterBackend({this.runCount = 10, this.credits, this.daily, this.hours}) {
    billingEnabled = true;
  }

  final int runCount;
  final double? credits;
  final BillingSummaryDaily? daily;
  final BillingSummaryComputerHours? hours;

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day', UsageFilter filter = UsageFilter.none}) async =>
      (await super.usage(
        orgId,
        period: period,
      )).copyWith(totalCostUsd: 0.5, runs: runCount);

  @override
  Future<BillingSummary> billing(String orgId) async {
    var b = await super.billing(orgId);
    if (credits != null) b = b.copyWith(creditsUsd: credits!);
    if (daily != null) b = b.copyWith(daily: daily);
    if (hours != null) b = b.copyWith(computerHours: hours);
    return b;
  }
}

BillingSummaryDaily _daily(double used, double cap) => BillingSummaryDaily(
  usedUsd: used,
  capUsd: cap,
  resetsAt: DateTime.now().add(const Duration(hours: 1, minutes: 45)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'usage opens on credits in dollars: share used, runs left, what a credit is (D-245)',
    (tester) async {
      await setSize(tester, const Size(430, 2400));
      await tester.pumpWidget(harness(_MeterBackend(), const UsageScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('creditsMeter')), findsOneWidget);
      expect(find.text(r'Credits: $1.00'), findsOneWidget);
      // $0.10 of $1.10 this month.
      expect(find.text('9% used'), findsOneWidget);
      expect(
        find.text('About 20 more runs at your usual cost'),
        findsOneWidget,
      );
      expect(
        find.text(r'1 credit = $1. Packs from the App Store or Google Play never expire; web packs last 12 months.'),
        findsOneWidget,
      );
      // Token counts are not on the main view.
      expect(find.textContaining('tokens'), findsNothing);
    },
  );

  testWidgets('too few runs for a guess: no estimate; no credits: says so', (
    tester,
  ) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(
      harness(_MeterBackend(runCount: 2, credits: 0), const UsageScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creditsRunsLeft')), findsNothing);
    expect(find.byKey(const Key('creditsOut')), findsOneWidget);
    expect(find.text('100% used'), findsOneWidget);
  });

  testWidgets(
    "the daily cap shows under the credits, and says when it's reached (D-311)",
    (tester) async {
      await setSize(tester, const Size(430, 2400));
      await tester.pumpWidget(
        harness(_MeterBackend(daily: _daily(0.1, 0.25)), const UsageScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text("Today's limit"), findsOneWidget);
      expect(find.text(r'$0.10 of $0.25'), findsOneWidget);
      expect(find.byKey(const Key('dailyLimitReached')), findsNothing);
      expect(find.textContaining('Resets in about 2 hours.'), findsOneWidget);

      // Credits left, but today's cap spent: the meter says why bots stopped.
      await tester.pumpWidget(
        harness(_MeterBackend(daily: _daily(0.53, 0.25)), const UsageScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$0.53 of $0.25'), findsOneWidget);
      expect(find.byKey(const Key('dailyLimitReached')), findsOneWidget);
      expect(find.byKey(const Key('creditsOut')), findsNothing);
    },
  );

  testWidgets(
    'computer hours show under the credits; used up, they say chat still works (D-442)',
    (tester) async {
      BillingSummaryComputerHours hours(double used) => BillingSummaryComputerHours(
        usedHours: used,
        limitHours: 5,
        resetsAt: DateTime.utc(2026, 12, 1),
      );
      await setSize(tester, const Size(430, 2400));
      await tester.pumpWidget(
        harness(_MeterBackend(hours: hours(1.5)), const UsageScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Computer hours'), findsOneWidget);
      expect(find.text('1.5 of 5 h'), findsOneWidget);
      expect(find.byKey(const Key('computerHoursReached')), findsNothing);
      expect(find.textContaining('Resets on December 1.'), findsOneWidget);

      await tester.pumpWidget(
        harness(_MeterBackend(hours: hours(17)), const UsageScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('17 of 5 h'), findsOneWidget);
      expect(find.byKey(const Key('computerHoursReached')), findsOneWidget);
      expect(find.textContaining('Chat still works.'), findsOneWidget);
    },
  );

  testWidgets('no daily cap from the server: no daily row', (tester) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(_MeterBackend(), const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dailyLimit')), findsNothing);
  });

  testWidgets('a self-hosted server has no credits meter', (tester) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(FakeBackend(), const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creditsMeter')), findsNothing);
  });

  testWidgets('the header button fetches the numbers again', (tester) async {
    await setSize(tester, const Size(430, 2400));
    final backend = _MeterBackend();
    await tester.pumpWidget(harness(backend, const UsageScreen()));
    await tester.pumpAndSettle();
    final before = backend.usageCalls;
    await tester.tap(find.byKey(const Key('usageRefresh')));
    await tester.pumpAndSettle();
    expect(backend.usageCalls, greaterThan(before));
  });
}

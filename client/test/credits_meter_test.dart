import 'package:casama_app/features/usage/usage_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// $1.00 left, $0.10 billed this month; ten runs at $0.05 each.
class _MeterBackend extends FakeBackend {
  _MeterBackend({this.runCount = 10, this.credits}) {
    billingEnabled = true;
  }

  final int runCount;
  final double? credits;

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day'}) async =>
      (await super.usage(
        orgId,
        period: period,
      )).copyWith(totalCostUsd: 0.5, runs: runCount);

  @override
  Future<BillingSummary> billing(String orgId) async {
    final b = await super.billing(orgId);
    return credits == null ? b : b.copyWith(creditsUsd: credits!);
  }
}

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
        find.text(r'1 credit = $1. Credits from packs last 12 months.'),
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

  testWidgets('a self-hosted server has no credits meter', (tester) async {
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(FakeBackend(), const UsageScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creditsMeter')), findsNothing);
  });
}

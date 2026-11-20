import 'package:casama/features/billing/saved_resets.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

class _ResetBackend extends FakeBackend {
  _ResetBackend(this.resets) {
    billingEnabled = true;
  }
  final List<SavedLimitReset> resets;
  @override
  Future<BillingSummary> billing(String org) async =>
      (await super.billing(org)).copyWith(resets: resets);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('hides when no resets are saved', (tester) async {
    await tester.pumpWidget(
      harness(_ResetBackend([]), const Scaffold(body: SavedResets())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Use Reset'), findsNothing);
  });
  testWidgets('owner sees exact expiry and confirmation amount', (
    tester,
  ) async {
    final reset = SavedLimitReset(
      id: '11111111-1111-4111-8111-111111111111',
      campaignId: null,
      message: 'Sorry about the outage',
      expiresAt: DateTime(2027, 1, 5, 18, 30),
      refillUsd: 4.2,
      resetDaily: true,
      resetComputer: false,
      canUse: true,
      unavailableReason: null,
    );
    await tester.pumpWidget(
      harness(_ResetBackend([reset]), const Scaffold(body: SavedResets())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sorry about the outage'), findsOneWidget);
    await tester.tap(find.text('Use Reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining(r'Refills $4.20'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
  testWidgets('member sees saved reset without redemption button', (
    tester,
  ) async {
    final reset = SavedLimitReset(
      id: '11111111-1111-4111-8111-111111111111',
      campaignId: null,
      message: 'Saved',
      expiresAt: DateTime(2027),
      refillUsd: 1,
      resetDaily: true,
      resetComputer: false,
      canUse: false,
      unavailableReason: 'owner_required',
    );
    await tester.pumpWidget(
      harness(_ResetBackend([reset]), const Scaffold(body: SavedResets())),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 reset saved'), findsOneWidget);
    expect(find.text('Use Reset'), findsNothing);
  });
}

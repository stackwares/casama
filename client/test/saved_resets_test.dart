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
    expect(
      find.textContaining(r'Refills $4.20 of this period'),
      findsOneWidget,
    );
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
    expect(
      find.textContaining('Only a workspace owner can use it.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'says why a reset is unavailable, even for a reason it does not know',
    (tester) async {
      SavedLimitReset withReason(String reason) => SavedLimitReset(
        id: '22222222-2222-4222-8222-222222222222',
        campaignId: null,
        message: 'Saved',
        expiresAt: DateTime(2027),
        refillUsd: 0,
        resetDaily: true,
        resetComputer: false,
        canUse: false,
        unavailableReason: reason,
      );
      await tester.pumpWidget(
        harness(
          _ResetBackend([withReason('nothing_to_refill')]),
          const Scaffold(body: SavedResets()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing to refill yet'), findsOneWidget);
      await tester.pumpWidget(
        harness(
          _ResetBackend([withReason('something_new')]),
          const Scaffold(body: SavedResets()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Not available right now.'), findsOneWidget);
    },
  );
  testWidgets(
    'a reset with no credits to refill says it clears today\'s limit',
    (tester) async {
      final reset = SavedLimitReset(
        id: '33333333-3333-4333-8333-333333333333',
        campaignId: null,
        message: 'Saved',
        expiresAt: DateTime(2027),
        refillUsd: 0,
        resetDaily: true,
        resetComputer: false,
        canUse: true,
        unavailableReason: null,
      );
      await tester.pumpWidget(
        harness(_ResetBackend([reset]), const Scaffold(body: SavedResets())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Reset'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Clears today’s limit so your bots'),
        findsOneWidget,
      );
      expect(find.textContaining(r'$0.00'), findsNothing);
    },
  );

  group('layout on every screen size', () {
    SavedLimitReset soon() => SavedLimitReset(
      id: '44444444-4444-4444-8444-444444444444',
      campaignId: null,
      message: 'A test reset from Casama. Use it any time before it expires.',
      expiresAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
      refillUsd: 1,
      resetDaily: true,
      resetComputer: true,
      canUse: true,
      unavailableReason: null,
    );

    Future<void> pump(
      WidgetTester tester,
      double width, {
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          _ResetBackend([soon()]),
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: SavedResets(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a phone: the button spans the card under the details', (
      tester,
    ) async {
      await pump(tester, 390);
      final card = tester.getRect(find.byKey(const Key('savedResetCard')));
      final button = tester.getRect(find.byKey(const Key('useSavedReset')));
      final title = tester.getRect(find.text('1 reset saved'));
      expect(button.top, greaterThan(title.bottom));
      expect(button.width, greaterThan(card.width * 0.8));
      // What it does and when it ends, in plain words; the end is close, so the time shows.
      expect(find.text(r'Refills $1.00 of credits'), findsOneWidget);
      expect(find.text('Clears today’s limit'), findsOneWidget);
      expect(find.text('Gives back computer hours'), findsOneWidget);
      expect(find.text('2 days left'), findsOneWidget);
      expect(find.textContaining('·'), findsOneWidget);
    });

    testWidgets('a wide window: the button sits beside the title', (
      tester,
    ) async {
      await pump(tester, 1000);
      final button = tester.getRect(find.byKey(const Key('useSavedReset')));
      final title = tester.getRect(find.text('1 reset saved'));
      expect(button.left, greaterThan(title.right));
      expect((button.center.dy - title.center.dy).abs(), lessThan(24));
    });

    testWidgets('a small phone with large text still fits', (tester) async {
      await pump(tester, 320, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('useSavedReset')), findsOneWidget);
    });
  });
}

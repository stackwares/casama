import 'package:casama/core/billing.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/billing/billing_screen.dart';
import 'package:casama/features/billing/redeem_code_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'billing_test.dart' show app, pricingPlans, revealInPaywall, settle;
import 'fake_backend.dart';
import 'fake_unlockers.dart';

/// Free plans for friends (docs/COMP-PLANS-PLAN.md).
FakeBackend comped({required Duration left}) {
  final ends = DateTime.now().toUtc().add(left);
  return FakeBackend()
    ..billingEnabled = true
    ..planCode = 'pro'
    ..catalogPlans = pricingPlans()
    ..comp = BillingSummaryComp(
      planCode: 'pro',
      endsAt: ends,
      from: BillingSummaryCompFromEnum.grant,
      keepFrom: ends.subtract(const Duration(days: 7)),
    );
}

Widget redeemApp(
  FakeBackend backend, {
  TargetPlatform platform = TargetPlatform.macOS,
  String? code,
}) {
  final router = GoRouter(
    initialLocation: redeemCodePath(code),
    routes: [
      GoRoute(
        path: '/settings/billing',
        builder: (_, _) => const Text('billing page'),
      ),
      GoRoute(
        path: '/settings/billing/redeem',
        builder: (_, s) =>
            RedeemCodeScreen(code: s.uri.queryParameters['code']),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      unlockersProvider.overrideWithValue(FakeUnlockers()),
      platformProvider.overrideWithValue(platform),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('gift codes only where a store has no say: the web and direct desktop builds', () {
    expect(giftCodesAllowed(platform: TargetPlatform.iOS, isWeb: true), isTrue);
    expect(
      giftCodesAllowed(platform: TargetPlatform.macOS, isWeb: false),
      isTrue,
    );
    expect(
      giftCodesAllowed(platform: TargetPlatform.windows, isWeb: false),
      isTrue,
    );
    expect(
      giftCodesAllowed(platform: TargetPlatform.linux, isWeb: false),
      isTrue,
    );
    expect(
      giftCodesAllowed(platform: TargetPlatform.iOS, isWeb: false),
      isFalse,
    );
    expect(
      giftCodesAllowed(platform: TargetPlatform.android, isWeb: false),
      isFalse,
    );
  });

  testWidgets(
    'a free plan says it is free from Casama, until when, with nothing to manage',
    (tester) async {
      await setSize(tester, const Size(430, 1800));
      await tester.pumpWidget(app(comped(left: const Duration(days: 60))));
      await tester.pumpAndSettle();
      expect(find.text('Free from Casama'), findsOneWidget);
      expect(find.byKey(const Key('compFreeUntil')), findsOneWidget);
      expect(find.byKey(const Key('manageSubscription')), findsNothing);
      expect(find.byKey(const Key('keepCompPlan')), findsNothing);
      expect(find.byKey(const Key('haveGiftCode')), findsNothing);

      // In the paywall the comped plan is the current one, and can't be bought yet.
      await tester.ensureVisible(find.byKey(const Key('changePlan')));
      await tester.tap(find.byKey(const Key('changePlan')));
      await settle(tester);
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
      await tester.tap(find.byKey(const Key('paywallTier-pro')));
      await settle(tester);
      expect(find.textContaining('Free until'), findsWidgets);
      await tester.tap(
        find.byKey(const Key('paywallBuy')),
        warnIfMissed: false,
      );
      await settle(tester);
    },
  );

  testWidgets('in its last week the plan can be kept by choosing it', (
    tester,
  ) async {
    await setSize(tester, const Size(430, 1800));
    final backend = comped(left: const Duration(days: 3));
    await tester.pumpWidget(app(backend));
    await tester.pumpAndSettle();
    expect(find.text('Keep Pro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('keepCompPlan')));
    await settle(tester);
    await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
    await tester.tap(find.byKey(const Key('paywallTier-pro')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('paywallBuy')));
    await settle(tester);
    expect(backend.checkouts, ['pro']);
  });

  testWidgets(
    'the gift code button shows on desktop and never in the store apps',
    (tester) async {
      await setSize(tester, const Size(430, 1800));
      for (final (platform, shown) in [
        (TargetPlatform.macOS, true),
        (TargetPlatform.iOS, false),
        (TargetPlatform.android, false),
      ]) {
        final backend = FakeBackend()..billingEnabled = true;
        await tester.pumpWidget(app(backend, platform: platform));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('haveGiftCode')),
          shown ? findsOneWidget : findsNothing,
          reason: '$platform',
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('redeeming a code shows what it gives, then the plan', (
    tester,
  ) async {
    await setSize(tester, const Size(430, 1200));
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(redeemApp(backend));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('redeemCodeSubmit')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('redeemCodeField')),
      'G-ZZZZZ-ZZZZZ',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('redeemCodeInvalid')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('redeemCodeField')),
      'g-abcde-12345',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('3 months of Pro, free'), findsOneWidget);
    await tester.tap(find.byKey(const Key('redeemCodeSubmit')));
    await tester.pumpAndSettle();
    expect(backend.redeemedCompCodes, ['g-abcde-12345']);
    expect(find.text('Pro is yours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('redeemCodeOpenBilling')));
    await tester.pumpAndSettle();
    expect(find.text('billing page'), findsOneWidget);
  });

  testWidgets('a code in the link is checked at once', (tester) async {
    await setSize(tester, const Size(430, 1200));
    await tester.pumpWidget(
      redeemApp(FakeBackend()..billingEnabled = true, code: 'G-ABCDE-12345'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('redeemCodePreview')), findsOneWidget);
  });

  testWidgets('the store apps say it is not available here, with no field', (
    tester,
  ) async {
    await setSize(tester, const Size(430, 1200));
    await tester.pumpWidget(
      redeemApp(
        FakeBackend()..billingEnabled = true,
        platform: TargetPlatform.iOS,
        code: 'G-ABCDE-12345',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('redeemCodeField')), findsNothing);
    expect(
      find.text("This isn't available in this version of the app."),
      findsOneWidget,
    );
  });
}

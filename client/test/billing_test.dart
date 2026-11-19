import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/core/billing.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/widgets.dart';
import 'package:casama/features/billing/billing_screen.dart';
import 'package:casama/features/billing/out_of_credits.dart';
import 'package:casama/features/billing/paywall.dart';
import 'package:casama/ui/adaptive_modal.dart';
import 'package:casama/ui/highlight_target.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';
import 'fake_unlockers.dart';

class FakeStore implements StorePurchases {
  FakeStore(this.source, {this.country, this.priced = false, this.trials = const {}});
  @override
  final String? source;
  final String? country;

  /// Products carry real numbers ($49.99 a month, $489.99 a year), as the stores give them.
  final bool priced;

  /// Free-trial days the store confirms, by product id; empty when unknown or not eligible.
  final Map<String, int> trials;
  final _purchases = StreamController<StorePurchase>.broadcast();
  final bought = <String>[];
  final completed = <String>[];
  var restoredWith = '';

  /// The next purchase fails in the store.
  var fail = false;

  @override
  Future<String?> storefront() async => country;
  @override
  Future<Map<String, int>> freeTrialDays(Set<String> ids) async => {for (final id in ids) if (trials[id] != null) id: trials[id]!};
  @override
  Future<List<StoreProduct>> products(Set<String> ids) async =>
      [for (final id in ids) priced ? _priced(id) : StoreProduct(id: id, price: source == 'app_store' ? r'$9.99' : r'$9.49')];

  StoreProduct _priced(String id) {
    final yearly = id.contains('yearly');
    final price = yearly ? r'$489.99' : r'$49.99';
    return StoreProduct(
      id: id,
      price: price,
      amount: yearly ? 489.99 : 49.99,
      currencyCode: 'USD',
    );
  }
  @override
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false}) async {
    bought.add('${product.id}@$orgId${consumable ? ' (consumable)' : ''}');
    _purchases.add(StorePurchase(
      source: source!,
      productId: product.id,
      status: fail ? PurchaseStatus.error : PurchaseStatus.purchased,
      transactionId: source == 'app_store' ? '2000000123' : null,
      purchaseToken: source == 'google_play' ? 'play-token' : null,
    ));
  }

  @override
  Future<void> restore({required String orgId}) async {
    restoredWith = orgId;
    _purchases.add(StorePurchase(source: source!, productId: 'casama_pro', purchaseToken: 'restored-token', restored: true));
  }

  @override
  Stream<StorePurchase> get purchases => _purchases.stream;
  @override
  Future<void> complete(StorePurchase purchase) async => completed.add(purchase.productId);
}

Widget app(FakeBackend backend, {StorePurchases store = const NoStore(), TargetPlatform platform = TargetPlatform.macOS, List<String>? opened}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const BillingScreen()),
    GoRoute(path: '/settings/billing', builder: (_, _) => const BillingScreen()),
    GoRoute(path: '/settings/usage', builder: (_, _) => const Text('usage page')),
  ]);
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
      storeProvider.overrideWithValue(store),
      platformProvider.overrideWithValue(platform),
      openUrlProvider.overrideWithValue((url) async => opened?.add(url)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// The D-244 catalog: Free, then Plus, Pro and Max, each monthly and yearly.
List<Plan> pricingPlans() {
  Plan plan(String code, String name, String interval, Map<String, num> limits, String price) => Plan(
        code: code,
        name: name,
        interval: PlanIntervalEnum.values.firstWhere((i) => i.value == interval),
        limits: limits,
        priceLabel: price,
        web: true,
        storeProductIds: {'app_store': 'ai.casama.$code', 'google_play': 'casama_$code'},
      );
  const plus = {'max_bots': 5, 'computer_hours': 30, 'monthly_credits_usd': 5, 'seats': 2};
  const pro = {'max_bots': 20, 'computer_hours': 100, 'monthly_credits_usd': 10, 'seats': 5};
  const max = {'max_bots': 50, 'computer_hours': 400, 'monthly_credits_usd': 50, 'seats': 10};
  return [
    Plan(code: 'free', name: 'Free', interval: PlanIntervalEnum.none, limits: const {'max_bots': 2, 'seats': 1}, priceLabel: null, web: false, storeProductIds: const {}),
    plan('plus', 'Plus', 'month', plus, r'$15 / month'),
    plan('plus_yearly', 'Plus (yearly)', 'year', plus, r'$150 / year'),
    plan('pro', 'Pro', 'month', pro, r'$39 / month'),
    plan('pro_yearly', 'Pro (yearly)', 'year', pro, r'$390 / year'),
    plan('max', 'Max', 'month', max, r'$149 / month'),
    plan('max_yearly', 'Max (yearly)', 'year', max, r'$1,490 / year'),
  ];
}

/// Opens the paywall from a button, the way a 402 or the Billing banner does.
Future<void> pumpPaywall(WidgetTester tester, FakeBackend backend,
    {StorePurchases store = const NoStore(), TargetPlatform platform = TargetPlatform.macOS, List<String>? opened}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
      storeProvider.overrideWithValue(store),
      platformProvider.overrideWithValue(platform),
      openUrlProvider.overrideWithValue((url) async => opened?.add(url)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) => TextButton(onPressed: () => openPaywall(context), child: const Text('Open'))),
    ),
  ));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('Open'));
  await settle(tester);
}

/// The paywall's mascots never stop moving, so step time instead of waiting for it to settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Scrolls the paywall (either way) until [finder] is built and on screen; small phones show the
/// pickers below the mascots.
Future<void> revealInPaywall(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: find.byType(PaywallScreen), matching: find.byType(Scrollable)).first;
  for (final delta in [100.0, -100.0]) {
    if (finder.evaluate().isNotEmpty) break;
    try {
      await tester.scrollUntilVisible(finder, delta, scrollable: list, maxScrolls: 30);
    } on StateError {
      // Not that way; try the other.
    }
  }
  if (finder.evaluate().isNotEmpty) await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('store rules', () {
    test('iOS shows in-app purchase only outside the US storefront', () {
      expect(purchaseChannels(platform: TargetPlatform.iOS, isWeb: false, storefront: 'GBR'), [PurchaseChannel.appStore]);
      expect(purchaseChannels(platform: TargetPlatform.iOS, isWeb: false, storefront: 'PHL'), [PurchaseChannel.appStore]);
      expect(purchaseChannels(platform: TargetPlatform.iOS, isWeb: false), [PurchaseChannel.appStore]);
      expect(purchaseChannels(platform: TargetPlatform.iOS, isWeb: false, storefront: 'USA'),
          [PurchaseChannel.appStore, PurchaseChannel.web]);
    });
    test('Android uses Google Play; web and desktop use web checkout', () {
      expect(purchaseChannels(platform: TargetPlatform.android, isWeb: false, storefront: 'USA'), [PurchaseChannel.googlePlay]);
      expect(purchaseChannels(platform: TargetPlatform.macOS, isWeb: false), [PurchaseChannel.web]);
      expect(purchaseChannels(platform: TargetPlatform.windows, isWeb: false), [PurchaseChannel.web]);
      expect(purchaseChannels(platform: TargetPlatform.iOS, isWeb: true), [PurchaseChannel.web]);
    });
  });

  testWidgets('self-hosted servers show no paywall', (tester) async {
    await tester.pumpWidget(app(FakeBackend()));
    await tester.pumpAndSettle();
    expect(find.text('Billing is off on this server. Self-hosted Casama has no limits.'), findsOneWidget);
    expect(find.byKey(const Key('plan-pro')), findsNothing);
  });

  testWidgets('desktop and web: web checkout, credit packs, usage and Casama Link servers and keys', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    final opened = <String>[];
    await tester.pumpWidget(app(backend, opened: opened));
    await tester.pumpAndSettle();
    expect(find.text('Free'), findsOneWidget);
    expect(find.text(r'Credits: $1.00'), findsOneWidget);
    expect(find.byKey(const Key('restorePurchases')), findsNothing);
    // Free upgrades through the banner's paywall; there is no plan list to buy from here.
    expect(find.byKey(const Key('changePlan')), findsNothing);
    await tester.tap(find.byKey(const Key('openPaywall')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('paywallBuy')));
    await settle(tester);
    expect(backend.checkouts, ['pro']);
    expect(opened, ['https://checkout.example.com/pro']);
    await tester.tap(find.byKey(const Key('paywallClose')));
    await settle(tester);
    // Credit packs come with a paid plan; Free is offered the upgrade instead (D-246).
    expect(find.byKey(const Key('pack-credits_10')), findsNothing);
    // One row to Usage with the month's total; the full list lives there (D-182).
    expect(find.text(r'This month so far: $0.10'), findsOneWidget);
    expect(find.text('Cloud computers: 2.00 h · home-server'), findsNothing);

    // Casama Link servers and keys are under Advanced.
    expect(find.byKey(const Key('createLinkKey')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('createLinkKey')));
    await tester.tap(find.byKey(const Key('createLinkKey')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('instanceName')), 'home-server');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('CASAMA_CLOUD_KEY=kcc_secret_shown_once'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('kcc_abcd…wxyz'), findsOneWidget);
  });

  testWidgets('Casama Link lists the workspace\'s linked servers and removes one (D-296)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()
      ..billingEnabled = true
      ..linkServerLimit = 3;
    await tester.pumpWidget(app(backend));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    expect(find.text('Linked Servers · Your plan connects 3 servers.'), findsOneWidget);
    // None yet: say where linking starts (on the person's own server).
    expect(find.byKey(const Key('linkServersNone')), findsOneWidget);
  });

  testWidgets('a linked server shows its address and can be removed (D-296)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()
      ..billingEnabled = true
      ..linkedServers.addAll(['Home Mac', 'Attic server']);
    await tester.pumpWidget(app(backend));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    expect(find.text('Linked Servers · Your plan connects 1 server.'), findsOneWidget);
    expect(find.text('Home Mac'), findsOneWidget);
    expect(find.text('k7qm2xfd9ab0.link.test · Has an address'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('removeLinkServer-s1')));
    await tester.tap(find.byKey(const Key('removeLinkServer-s1')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Attic server? Its address stops working. The server can be linked again later.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('removeLinkServerConfirm')));
    await tester.pumpAndSettle();
    expect(backend.linkedServers, ['Home Mac']);
    expect(find.text('Attic server'), findsNothing);
  });

  testWidgets('the plan stays up top, the usage row opens Usage, Casama Link folds under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(430, 1800));
    await tester.pumpWidget(app(FakeBackend()..billingEnabled = true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currentPlan')), findsOneWidget);
    expect(find.byKey(const Key('openPaywall')), findsOneWidget);
    expect(find.text('Charges by server, Casama Link servers and keys'), findsOneWidget);
    expect(find.byKey(const Key('createLinkKey')), findsNothing);
    expect(find.byKey(const Key('billedItems')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('createLinkKey')), findsOneWidget);
    // Each charge with the server it came from stays reachable here.
    expect(find.byKey(const Key('billedItems')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('billingUsage')));
    await tester.tap(find.byKey(const Key('billingUsage')));
    await tester.pumpAndSettle();
    expect(find.text('usage page'), findsOneWidget);
  });

  testWidgets('iOS outside the US: App Store purchase only, verified by the server, plus Restore Purchases', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    final store = FakeStore('app_store', country: 'GBR');
    await tester.pumpWidget(app(backend, store: store, platform: TargetPlatform.iOS));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-credits_10')), findsNothing);
    expect(find.byKey(const Key('restorePurchases')), findsOneWidget);
    await tester.tap(find.byKey(const Key('openPaywall')));
    await settle(tester);
    // App Store only: the store's price on the button, no web checkout.
    expect(find.byKey(const Key('paywallWeb')), findsNothing);
    expect(find.text(r'Subscribe for $9.99'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paywallBuy')));
    await settle(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(store.bought, ['dev.casama.pro.monthly@$orgId']);
    expect(backend.verified, ['app_store:dev.casama.pro.monthly:2000000123']);
    expect(store.completed, ['dev.casama.pro.monthly']);
    expect(find.text('Billed through the App Store'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('currentPlan')), matching: find.text('Pro')), findsOneWidget);
  });

  testWidgets('a paying workspace changes plans in the paywall, not from a list of every plan', (tester) async {
    await setSize(tester, const Size(430, 1800));
    final backend = FakeBackend()
      ..billingEnabled = true
      ..planCode = 'pro'
      ..billingSource = BillingSummarySource_Enum.dodo;
    await tester.pumpWidget(app(backend));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('openPaywall')), findsNothing);
    expect(find.byKey(const Key('plan-pro')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('changePlan')));
    await tester.tap(find.byKey(const Key('changePlan')));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
  });

  testWidgets('iOS on the US storefront also offers web checkout', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(app(backend, store: FakeStore('app_store', country: 'USA'), platform: TargetPlatform.iOS));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openPaywall')));
    await settle(tester);
    expect(find.text(r'Subscribe for $9.99'), findsOneWidget);
    expect(find.byKey(const Key('paywallWeb')), findsOneWidget);
  });

  testWidgets('Android: Restore Purchases sends the purchase token to the server', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    final store = FakeStore('google_play', country: 'USA');
    await tester.pumpWidget(app(backend, store: store, platform: TargetPlatform.android));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restorePurchases')));
    await tester.pumpAndSettle();
    expect(store.restoredWith, orgId);
    expect(backend.verified, ['google_play:casama_pro:restored-token']);
    expect(find.text('Billed through Google Play'), findsOneWidget);
  });

  testWidgets('a 402 inside a sheet opens the paywall on top of it, and closing it goes back to the sheet', (tester) async {
    await setSize(tester, const Size(400, 900));
    final backend = FakeBackend()..billingEnabled = true;
    final opened = <String>[];
    onPaymentRequired = showPaywall;
    addTearDown(() => onPaymentRequired = null);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdaptiveSheet<void>(
                context: context,
                builder: (sheet) => TextButton(
                  onPressed: () => runGuarded(sheet, () async {
                    final req = RequestOptions(path: '/v1/bots');
                    throw DioException(
                      requestOptions: req,
                      response: Response(
                        requestOptions: req,
                        statusCode: 402,
                        data: {'type': 'about:blank', 'title': 'Payment Required', 'status': 402, 'code': 'plan_limit', 'detail': 'Your plan allows 2 bots. Upgrade to add more.'},
                      ),
                    );
                  }),
                  child: const Text('Create'),
                ),
              ),
              child: const Text('New bot'),
            ),
          ),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
        platformProvider.overrideWithValue(TargetPlatform.macOS),
        openUrlProvider.overrideWithValue((url) async => opened.add(url)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('New bot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The paywall is in front: its button takes the tap, not the sheet behind it.
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('Your plan allows 2 bots. Upgrade to add more.'), findsOneWidget);
    expect(find.text('Grow your crew with Pro'), findsOneWidget);
    expect(find.text('Create').hitTestable(), findsNothing);
    await tester.tap(find.byKey(const Key('paywallBuy')).hitTestable());
    await tester.pump(const Duration(seconds: 1));
    expect(backend.checkouts, ['pro']);
    expect(opened, ['https://checkout.example.com/pro']);
    // Closing it leaves the sheet as it was.
    await tester.tap(find.byKey(const Key('paywallClose')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('Create').hitTestable(), findsOneWidget);
  });

  testWidgets('the paywall closes and celebrates once the plan turns paid', (tester) async {
    await setSize(tester, const Size(400, 900));
    final backend = FakeBackend()..billingEnabled = true;
    final store = FakeStore('google_play', country: 'USA');
    bool? upgraded;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
        storeProvider.overrideWithValue(store),
        platformProvider.overrideWithValue(TargetPlatform.android),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(billingProvider);
            return TextButton(onPressed: () async => upgraded = await openPaywall(context), child: const Text('Open'));
          },
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Open'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text(r'Subscribe for $9.49'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paywallBuy')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(backend.verified, ['google_play:casama_pro:monthly:play-token']);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(upgraded, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  group('paywall tiers (D-244)', () {
    test('plans group into tiers by base code; the default is the tier above the current plan', () {
      final tiers = paywallTiers(pricingPlans());
      expect([for (final t in tiers) t.code], ['plus', 'pro', 'max']);
      expect(tiers[1].monthly?.code, 'pro');
      expect(tiers[1].yearly?.code, 'pro_yearly');
      expect(tiers[1].name, 'Pro');
      expect(defaultPaywallTier(tiers, 'free'), 'plus');
      expect(defaultPaywallTier(tiers, null), 'plus');
      expect(defaultPaywallTier(tiers, 'plus'), 'pro');
      expect(defaultPaywallTier(tiers, 'plus_yearly'), 'pro');
      expect(defaultPaywallTier(tiers, 'pro'), 'max');
      expect(defaultPaywallTier(tiers, 'max_yearly'), 'max');
    });

    for (final width in [320.0, 1280.0]) {
      testWidgets('at $width px: Plus monthly by default, then pick a tier and a period', (tester) async {
        await setSize(tester, Size(width, width < 600 ? 640 : 900));
        final backend = FakeBackend()
          ..billingEnabled = true
          ..catalogPlans = pricingPlans();
        final opened = <String>[];
        await pumpPaywall(tester, backend, opened: opened);
        expect(find.byType(PaywallScreen), findsOneWidget);
        // On a small phone the period toggle and the tier cards sit under the headline.
        await tester.scrollUntilVisible(find.byKey(const Key('paywallInterval-year')), 100,
            scrollable: find.descendant(of: find.byType(PaywallScreen), matching: find.byType(Scrollable)).first);
        await settle(tester);
        // Yearly saves 16% on every tier here.
        expect(find.text('Save up to 16%'), findsOneWidget);
        for (final t in ['plus', 'pro', 'max']) {
          await revealInPaywall(tester, find.byKey(Key('paywallTier-$t')));
          expect(find.byKey(Key('paywallTier-$t')), findsOneWidget);
        }
        // From Free: Plus, monthly, the smallest price first.
        Finder inPrice(String code, Finder f) => find.descendant(of: find.byKey(Key('paywallPrice-$code')), matching: f);
        expect(find.byKey(const Key('paywallPrice-pro_yearly')), findsNothing);
        expect(inPrice('plus', find.text(r'$15/mo', findRichText: true)), findsOneWidget);
        expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Plus')), findsOneWidget);

        // Yearly: every tier shows its price a month, how it is billed and the monthly price it
        // beats (no store on desktop, so the web price labels).
        await revealInPaywall(tester, find.byKey(const Key('paywallInterval-year')));
        await tester.tap(find.byKey(const Key('paywallInterval-year')));
        await settle(tester);
        await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
        await tester.tap(find.byKey(const Key('paywallTier-pro')));
        await settle(tester);
        expect(inPrice('pro_yearly', find.text(r'$39 $32.50/mo', findRichText: true)), findsOneWidget);
        expect(inPrice('pro_yearly', find.text(r'$390 billed yearly')), findsOneWidget);
        expect(inPrice('pro_yearly', find.text('2 months free')), findsOneWidget);
        // No trial open here, so the button names the plan.
        expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Pro')), findsOneWidget);

        await revealInPaywall(tester, find.byKey(const Key('paywallTier-max')));
        await tester.tap(find.byKey(const Key('paywallTier-max')));
        await settle(tester);
        expect(inPrice('max_yearly', find.text(r'$1,490 billed yearly')), findsOneWidget);
        expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Max')), findsOneWidget);

        await revealInPaywall(tester, find.byKey(const Key('paywallInterval-month')));
        await tester.tap(find.byKey(const Key('paywallInterval-month')));
        await settle(tester);
        await revealInPaywall(tester, find.byKey(const Key('paywallPrice-max')));
        expect(inPrice('max', find.text(r'$149/mo', findRichText: true)), findsOneWidget);
        expect(find.byKey(const Key('paywallPrice-max_yearly')), findsNothing);
        if (width < 600) {
          // Phones compare Max with Free under the cards: 50 bots where Free has 2.
          await revealInPaywall(tester, find.text('50'));
          expect(find.text('50'), findsWidgets);
        }

        await tester.tap(find.byKey(const Key('paywallBuy')));
        await settle(tester);
        expect(backend.checkouts, ['max']);
        expect(opened, ['https://checkout.example.com/max']);
      });
    }

    group('weekly plans (D-432)', () {
      List<Plan> withWeekly() {
        Plan week(String code, String name, Map<String, num> limits, String price) => Plan(
              code: code,
              name: name,
              interval: PlanIntervalEnum.week,
              limits: limits,
              priceLabel: price,
              web: true,
              storeProductIds: {'app_store': 'ai.casama.$code', 'google_play': 'casama_$code'},
            );
        final base = pricingPlans();
        Map<String, num> limitsOf(String code) => base.firstWhere((p) => p.code == code).limits;
        return [
          base.first,
          week('plus_weekly', 'Plus', limitsOf('plus'), r'$7.99 / week'),
          ...base.where((p) => p.code.startsWith('plus')),
          week('pro_weekly', 'Pro', limitsOf('pro'), r'$19.99 / week'),
          // Monthly and yearly Pro carry the trial; weekly never does.
          for (final p in base.where((p) => p.code.startsWith('pro')))
            p.copyWith(limits: {...p.limits, 'trial_days': 7}),
          week('max_weekly', 'Max', limitsOf('max'), r'$39.99 / week'),
          ...base.where((p) => p.code.startsWith('max')),
        ];
      }

      test('a weekly plan joins its tier, and the paywall still opens on monthly', () {
        final tiers = paywallTiers(withWeekly());
        expect([for (final t in tiers) t.code], ['plus', 'pro', 'max']);
        expect(tiers[1].weekly?.code, 'pro_weekly');
        expect(tiers[1].planFor(PaywallPeriod.week)?.code, 'pro_weekly');
        expect(tiers[1].planFor(PaywallPeriod.month)?.code, 'pro');
        expect(paywallTierOf('pro_weekly'), 'pro');
        expect(defaultPaywallTier(tiers, 'plus_weekly'), 'pro');
        expect(paywallPeriods(tiers), PaywallPeriod.values);
        expect(paywallPeriods(paywallTiers(pricingPlans())), [PaywallPeriod.month, PaywallPeriod.year]);
        expect(defaultPaywallPeriod(tiers), PaywallPeriod.month);
      });

      testWidgets('weekly is a third period: billed every week, no trial, and monthly shows what a week costs',
          (tester) async {
        await setSize(tester, const Size(400, 900));
        final backend = FakeBackend()
          ..billingEnabled = true
          ..trialAvailable = true
          ..catalogPlans = withWeekly();
        final opened = <String>[];
        await pumpPaywall(tester, backend, opened: opened);
        Finder inPrice(String code, Finder f) => find.descendant(of: find.byKey(Key('paywallPrice-$code')), matching: f);
        // Opens on monthly, with each monthly price worked out per week beside the weekly option.
        await revealInPaywall(tester, find.byKey(const Key('paywallInterval-week')));
        expect(find.byKey(const Key('paywallInterval-month')), findsOneWidget);
        expect(find.byKey(const Key('paywallInterval-year')), findsOneWidget);
        await revealInPaywall(tester, find.byKey(const Key('paywallPrice-plus')));
        expect(inPrice('plus', find.text(r"That's $3.46 a week")), findsOneWidget);

        await revealInPaywall(tester, find.byKey(const Key('paywallInterval-week')));
        await tester.tap(find.byKey(const Key('paywallInterval-week')));
        await settle(tester);
        await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
        await tester.tap(find.byKey(const Key('paywallTier-pro')));
        await settle(tester);
        expect(inPrice('pro_weekly', find.text(r'$19.99/wk', findRichText: true)), findsOneWidget);
        expect(inPrice('pro_weekly', find.text('Billed weekly')), findsOneWidget);
        expect(find.byKey(const Key('paywallPerWeek-pro_weekly')), findsNothing);
        // The Pro trial belongs to monthly and yearly.
        expect(find.descendant(of: find.byKey(const Key('paywallTier-pro')), matching: find.text('7 days free')), findsNothing);
        expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Pro')), findsOneWidget);
        final disclosure = tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data!;
        expect(disclosure, startsWith(r'$19.99 / week, renewing automatically'));
        await tester.tap(find.byKey(const Key('paywallBuy')));
        await settle(tester);
        expect(backend.checkouts, ['pro_weekly']);

        // Back on yearly the trial is offered again, and yearly works out per week too.
        await revealInPaywall(tester, find.byKey(const Key('paywallInterval-year')));
        await tester.tap(find.byKey(const Key('paywallInterval-year')));
        await settle(tester);
        await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
        expect(find.descendant(of: find.byKey(const Key('paywallTier-pro')), matching: find.text('7 days free')), findsOneWidget);
        expect(inPrice('pro_yearly', find.text(r"That's $7.50 a week")), findsOneWidget);
      });
    });

    test('the server picks the plan the paywall opens on and the popular tier (D-332)', () {
      Plan flag(Plan p, {bool def = false, bool popular = false}) => p.copyWith(paywallDefault: def, paywallPopular: popular);
      final tiers = paywallTiers([
        for (final p in pricingPlans())
          flag(p, def: p.code == 'pro_yearly', popular: p.code.startsWith('max')),
      ]);
      expect(defaultPaywallTier(tiers, 'free'), 'pro');
      expect(defaultPaywallTier(tiers, 'pro'), 'max');
      expect(defaultPaywallYearly(tiers), isTrue);
      expect(popularPaywallTiers(tiers), {'max'});
      // Nothing marked: Plus, monthly, no badge.
      final none = paywallTiers([for (final p in pricingPlans()) flag(p)]);
      expect(defaultPaywallTier(none, 'free'), 'plus');
      expect(defaultPaywallYearly(none), isFalse);
      expect(popularPaywallTiers(none), isEmpty);
      // A server from before the marks: Plus monthly, Pro badged.
      final old = paywallTiers(pricingPlans());
      expect(defaultPaywallYearly(old), isFalse);
      expect(popularPaywallTiers(old), {'pro'});
    });

    testWidgets('opens on the plan the server marks, with its period and its badge', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = [
          for (final p in pricingPlans())
            p.copyWith(paywallDefault: p.code == 'max_yearly', paywallPopular: p.code.startsWith('plus')),
        ];
      await pumpPaywall(tester, backend);
      expect(find.byKey(const Key('paywallPrice-max_yearly')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Max')), findsOneWidget);
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-plus')));
      expect(find.descendant(of: find.byKey(const Key('paywallTier-plus')), matching: find.text('Most popular')), findsOneWidget);
      expect(find.text('Most popular'), findsOneWidget);
    });

    testWidgets('on Plus it opens on Pro and compares Pro with Plus', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..planCode = 'plus'
        ..catalogPlans = pricingPlans();
      await pumpPaywall(tester, backend);
      expect(find.byKey(const Key('paywallPrice-pro')), findsOneWidget);
      await revealInPaywall(tester, find.text('100 h'));
      expect(find.text('100 h'), findsOneWidget);
      expect(find.text('30 h'), findsOneWidget);
      // Plus is marked as theirs; switching up is not a trial.
      expect(find.descendant(of: find.byKey(const Key('paywallTier-plus')), matching: find.text('Current plan')), findsOneWidget);
    });

    testWidgets('a first-time Pro subscriber on the web is offered the trial, on the card and the button', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..trialAvailable = true
        ..catalogPlans = [
          for (final p in pricingPlans())
            p.code.startsWith('pro')
                ? Plan(code: p.code, name: p.name, interval: p.interval, limits: {...p.limits, 'trial_days': 7},
                    priceLabel: p.priceLabel, web: p.web, storeProductIds: p.storeProductIds)
                : p,
        ];
      final opened = <String>[];
      await pumpPaywall(tester, backend, opened: opened);
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
      await tester.tap(find.byKey(const Key('paywallTier-pro')));
      await settle(tester);
      expect(find.descendant(of: find.byKey(const Key('paywallTier-pro')), matching: find.text('7 days free')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('paywallTier-pro')), matching: find.text('Most popular')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Start 7-day free trial')), findsOneWidget);
      // The fine print says when charging starts and how not to be charged.
      final disclosure = tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data!;
      expect(disclosure, startsWith('Free for 7 days, then '));
      expect(disclosure, contains("before the trial ends and you won't be charged"));
      // Max has no trial: its button names the plan.
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-max')));
      await tester.tap(find.byKey(const Key('paywallTier-max')));
      await settle(tester);
      expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Get Max')), findsOneWidget);
    });

    testWidgets('in a store the paywall never promises a free trial: the store decides who gets one', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..trialAvailable = true
        ..catalogPlans = [
          for (final p in pricingPlans())
            p.code.startsWith('pro')
                ? Plan(code: p.code, name: p.name, interval: p.interval, limits: {...p.limits, 'trial_days': 7},
                    priceLabel: p.priceLabel, web: p.web, storeProductIds: p.storeProductIds)
                : p,
        ];
      await pumpPaywall(tester, backend, store: FakeStore('app_store', country: 'GBR'), platform: TargetPlatform.iOS);
      expect(find.text('7 days free'), findsNothing);
      expect(find.textContaining('free trial'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data, isNot(contains('Free for')));
    });

    testWidgets('a store trial the store confirms is stated: days free then price, a trial button, charging after it', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      final store = FakeStore('app_store', country: 'GBR', priced: true, trials: const {'ai.casama.pro': 7, 'ai.casama.pro_yearly': 7});
      await pumpPaywall(tester, backend, store: store, platform: TargetPlatform.iOS);
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
      await tester.tap(find.byKey(const Key('paywallTier-pro')));
      await settle(tester);
      expect(find.text(r'7 days free, then $49.99/mo'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Start free trial')), findsOneWidget);
      final disclosure = tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data!;
      expect(disclosure, contains('Free for 7 days, then'));
      expect(disclosure, contains('when the trial ends'));
    });

    testWidgets('no confirmed store trial (not eligible or unknown): no trial wording at all', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      await pumpPaywall(tester, backend, store: FakeStore('app_store', country: 'GBR', priced: true), platform: TargetPlatform.iOS);
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-pro')));
      await tester.tap(find.byKey(const Key('paywallTier-pro')));
      await settle(tester);
      expect(find.textContaining('days free'), findsNothing);
      expect(find.text('Start free trial'), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data, isNot(contains('Free for')));
    });

    testWidgets('a store yearly plan leads with the yearly price it charges, the monthly figure after it', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      await pumpPaywall(tester, backend, store: FakeStore('app_store', country: 'GBR', priced: true), platform: TargetPlatform.iOS);
      for (final key in ['paywallInterval-year', 'paywallTier-pro']) {
        await revealInPaywall(tester, find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await settle(tester);
      }
      Finder inPrice(Finder f) => find.descendant(of: find.byKey(const Key('paywallPrice-pro_yearly')), matching: f);
      expect(inPrice(find.text(r'$489.99/yr', findRichText: true)), findsOneWidget);
      expect(inPrice(find.text(r'Works out to $40.83/mo')), findsOneWidget);
      // No struck-through monthly price beside a store's yearly price.
      expect(inPrice(find.textContaining(r'$49.99', findRichText: true)), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data, contains(r'$489.99 per year'));
    });

    testWidgets('on Pro yearly it opens on Max; picking the plan they have turns the button off', (tester) async {
      await setSize(tester, const Size(400, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..planCode = 'pro_yearly'
        ..catalogPlans = pricingPlans();
      await pumpPaywall(tester, backend);
      expect(find.byKey(const Key('paywallPrice-max')), findsOneWidget);
      // Their plan is the yearly one.
      for (final key in ['paywallInterval-year', 'paywallTier-pro']) {
        await revealInPaywall(tester, find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await settle(tester);
      }
      expect(find.descendant(of: find.byKey(const Key('paywallBuy')), matching: find.text('Current plan')), findsOneWidget);
      await tester.tap(find.byKey(const Key('paywallBuy')));
      await settle(tester);
      expect(backend.checkouts, isEmpty);
    });

    testWidgets('Android: the cards show the store price, and the button buys that plan', (tester) async {
      await setSize(tester, const Size(360, 740));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      final store = FakeStore('google_play', country: 'USA');
      await pumpPaywall(tester, backend, store: store, platform: TargetPlatform.android);
      // The store's button promises only its price: the store decides who gets its intro offer.
      expect(find.text(r'Subscribe for $9.49'), findsOneWidget);
      // No web checkout link on Android, even on the US storefront.
      expect(find.byKey(const Key('paywallWeb')), findsNothing);
      Finder inPrice(String code, Finder f) => find.descendant(of: find.byKey(Key('paywallPrice-$code')), matching: f);
      for (final key in ['paywallInterval-year', 'paywallTier-pro']) {
        await revealInPaywall(tester, find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await settle(tester);
      }
      // The fake store gives no number to divide, so the yearly price stands as it is, never the
      // web's dollars beside the store's price.
      expect(inPrice('pro_yearly', find.text(r'$9.49/yr', findRichText: true)), findsOneWidget);
      expect(inPrice('pro_yearly', find.text('Billed yearly')), findsOneWidget);
      await revealInPaywall(tester, find.byKey(const Key('paywallInterval-month')));
      await tester.tap(find.byKey(const Key('paywallInterval-month')));
      await settle(tester);
      expect(inPrice('pro', find.text(r'$9.49/mo', findRichText: true)), findsOneWidget);
      await tester.tap(find.byKey(const Key('paywallBuy')));
      await settle(tester);
      expect(store.bought, ['casama_pro@$orgId']);
      expect(backend.verified, ['google_play:casama_pro:play-token']);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('Android: credit packs with a Google Play product are bought in the store as consumables', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()
      ..billingEnabled = true
      ..planCode = 'pro'
      ..catalogPacks = [
        CreditPack(code: 'credits_10', name: r'$10 of credits', creditsUsd: 10, web: true, priceLabel: r'$10',
            storeProductIds: const {'app_store': 'ai.casama.credits.10', 'google_play': 'casama_credits_10'}),
        // No Google product and no web checkout on Android: not offered.
        CreditPack(code: 'credits_web', name: r'$5 of credits', creditsUsd: 5, web: true, priceLabel: r'$5'),
      ];
    final store = FakeStore('google_play', country: 'USA');
    await tester.pumpWidget(app(backend, store: store, platform: TargetPlatform.android));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-credits_web')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('packStore-credits_10')), matching: find.text(r'$9.49')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('packStore-credits_10')));
    await tester.tap(find.byKey(const Key('packStore-credits_10')));
    await tester.pumpAndSettle();
    expect(store.bought, ['casama_credits_10@$orgId (consumable)']);
    expect(backend.verified, ['google_play:casama_credits_10:play-token']);
    expect(store.completed, ['casama_credits_10']);
    // Still on Pro, with the credits added.
    expect(find.text(r'Credits: $11.00'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('currentPlan')), matching: find.text('Pro')), findsOneWidget);
  });

  testWidgets('desktop: web packs keep web checkout and show their price label', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()
      ..billingEnabled = true
      ..planCode = 'pro'
      ..catalogPacks = [
        CreditPack(code: 'credits_25', name: r'$25 of credits', creditsUsd: 25, web: true, priceLabel: r'$25',
            storeProductIds: const {'app_store': 'ai.casama.credits.25', 'google_play': 'casama_credits_25'}),
      ];
    final opened = <String>[];
    await tester.pumpWidget(app(backend, opened: opened));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('packStore-credits_25')), findsNothing);
    expect(find.descendant(of: find.byKey(const Key('pack-credits_25')), matching: find.text(r'$25')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-credits_25')));
    await tester.pumpAndSettle();
    expect(opened, ['https://checkout.example.com/credits_25']);
  });

  group('D-248: terms, one subscription, out of credits, purchase outcomes', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    testWidgets('the paywall states price, renewal and cancellation, with Terms of Use and Privacy (iOS)', (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      final opened = <String>[];
      await pumpPaywall(tester, backend, store: FakeStore('app_store', country: 'GBR'), platform: TargetPlatform.iOS, opened: opened);
      final disclosure = tester.widget<Text>(find.byKey(const Key('purchaseDisclosure'))).data!;
      expect(disclosure, contains(r'$9.99 per month'));
      expect(disclosure, contains('Apple Account'));
      expect(disclosure, isNot(contains('Account account')), reason: 'the store name already says account');
      expect(disclosure, contains('24 hours before it renews'));
      expect(find.byKey(const Key('termsOfUse')), findsOneWidget);
      await tester.tap(find.byKey(const Key('privacyPolicy')));
      await settle(tester);
      expect(opened, ['https://casama.ai/privacy']);
      // The plan's name is in the headline, not always "Pro".
      await revealInPaywall(tester, find.byKey(const Key('paywallTier-max')));
      await tester.tap(find.byKey(const Key('paywallTier-max')));
      await settle(tester);
      await revealInPaywall(tester, find.text('Grow your crew with Max'));
      expect(find.text('Grow your crew with Max'), findsOneWidget);
    });

    testWidgets('a web subscriber changing plans is moved in place: no second checkout page, a welcome to the new plan', (tester) async {
      await setSize(tester, const Size(1280, 900));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans()
        ..planCode = 'pro'
        ..billingSource = BillingSummarySource_Enum.dodo;
      final opened = <String>[];
      await pumpPaywall(tester, backend, opened: opened);
      await tester.tap(find.byKey(const Key('paywallTier-max')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('paywallBuy')));
      await settle(tester);
      expect(backend.checkouts.single, startsWith('max'));
      expect(opened, isEmpty);
      expect(backend.planCode, startsWith('max'));
      expect(find.textContaining('Welcome to Max'), findsOneWidget);
    });

    group('a web subscriber in a store app', () {
      FakeBackend webSubscriber() => FakeBackend()
        ..billingEnabled = true
        ..planCode = 'pro'
        ..billingSource = BillingSummarySource_Enum.dodo
        ..catalogPlans = [
          for (final p in pricingPlans())
            p.code == 'pro'
                ? Plan(code: p.code, name: p.name, interval: p.interval, limits: {...p.limits, 'extra_seat_usd': 12},
                    priceLabel: p.priceLabel, web: p.web, storeProductIds: p.storeProductIds)
                : p,
        ];

      testWidgets('outside the US gets no link to the web portal, no extra people to buy, and no pointer to web checkout', (tester) async {
        await setSize(tester, const Size(430, 1400));
        final backend = webSubscriber();
        await tester.pumpWidget(app(backend, store: FakeStore('app_store', country: 'GBR'), platform: TargetPlatform.iOS));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('manageSubscription')), findsNothing);
        expect(find.byKey(const Key('extraPeople')), findsNothing);
        await pumpPaywall(tester, backend, store: FakeStore('app_store', country: 'GBR'), platform: TargetPlatform.iOS);
        await revealInPaywall(tester, find.byKey(const Key('paywallChannelNote')));
        expect(find.textContaining('billed outside this app'), findsOneWidget);
        expect(find.textContaining('web checkout'), findsNothing);
        await tester.pump(const Duration(seconds: 5));
      });

      testWidgets('on the US storefront keeps the portal and extra people', (tester) async {
        await setSize(tester, const Size(430, 1400));
        await tester.pumpWidget(app(webSubscriber(), store: FakeStore('app_store', country: 'USA'), platform: TargetPlatform.iOS));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('manageSubscription')), findsOneWidget);
        expect(find.byKey(const Key('extraPeople')), findsOneWidget);
      });
    });

    testWidgets('an App Store subscriber on Android is told to change plans in the App Store, with nothing to buy here', (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans()
        ..planCode = 'plus'
        ..billingSource = BillingSummarySource_Enum.appStore;
      await pumpPaywall(tester, backend, store: FakeStore('google_play', country: 'USA'), platform: TargetPlatform.android);
      await revealInPaywall(tester, find.byKey(const Key('paywallChannelNote')));
      expect(find.byKey(const Key('paywallChannelNote')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('paywallBuy'))).onPressed, isNull);
    });

    testWidgets('a store purchase that fails says so instead of nothing happening', (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..billingEnabled = true
        ..catalogPlans = pricingPlans();
      final store = FakeStore('app_store', country: 'GBR')..fail = true;
      await pumpPaywall(tester, backend, store: store, platform: TargetPlatform.iOS);
      await tester.tap(find.byKey(const Key('paywallBuy')));
      await settle(tester);
      expect(find.textContaining("didn't go through"), findsOneWidget);
      // A failed transaction is finished so it doesn't sit in the store's queue.
      expect(store.completed, hasLength(1));
      expect(backend.verified, isEmpty);
    });

    Future<void> pumpOutOfCredits(WidgetTester tester, FakeBackend backend, List<String> opened) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
          storeProvider.overrideWithValue(const NoStore()),
          platformProvider.overrideWithValue(TargetPlatform.macOS),
          openUrlProvider.overrideWithValue((url) async => opened.add(url)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) => TextButton(onPressed: () => openOutOfCredits(context), child: const Text('Out'))),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Out'));
      await settle(tester);
    }

    testWidgets('out of credits: a paying workspace is offered packs; a free one sees the plans', (tester) async {
      await setSize(tester, const Size(900, 1200));
      final opened = <String>[];
      final paid = FakeBackend()
        ..billingEnabled = true
        ..planCode = 'pro'
        ..catalogPacks = [CreditPack(code: 'credits_10', name: r'$10 of credits', creditsUsd: 10, web: true, priceLabel: r'$10')];
      await pumpOutOfCredits(tester, paid, opened);
      expect(find.byKey(const Key('outOfCreditsSheet')), findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);
      await tester.tap(find.byKey(const Key('creditsPack-credits_10')));
      await settle(tester);
      expect(opened, ['https://checkout.example.com/credits_10']);

      final free = FakeBackend()..billingEnabled = true;
      await pumpOutOfCredits(tester, free, opened);
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text("You're out of credits"), findsOneWidget);
    });
  });

  group('BillingScreen ?highlight= targets', () {
    testWidgets('highlight=credits activates the credits HighlightTarget without triggering purchases', (tester) async {
      await setSize(tester, const Size(900, 1400));
      final backend = FakeBackend()..billingEnabled = true;
      final store = FakeStore('app_store', country: 'USA');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            unlockersProvider.overrideWithValue(FakeUnlockers()),
            storeProvider.overrideWithValue(store),
            platformProvider.overrideWithValue(TargetPlatform.iOS),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BillingScreen(highlight: 'credits'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final activeTargets = tester
          .widgetList<HighlightTarget>(find.byType(HighlightTarget))
          .where((w) => w.active)
          .toList();
      expect(activeTargets, hasLength(1));
      expect(
        find.descendant(
          of: find.byWidget(activeTargets.single),
          matching: find.byKey(const Key('creditsBalance')),
        ),
        findsOneWidget,
      );
      expect(backend.verified, isEmpty);
      expect(store.restoredWith, isEmpty);
    });

    testWidgets('highlight=link_cloud expands AdvancedSection and respects reduced motion', (tester) async {
      await setSize(tester, const Size(900, 1400));
      final backend = FakeBackend()..billingEnabled = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            unlockersProvider.overrideWithValue(FakeUnlockers()),
            storeProvider.overrideWithValue(const NoStore()),
            platformProvider.overrideWithValue(TargetPlatform.macOS),
          ],
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: BillingScreen(highlight: 'link_cloud'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final activeTargets = tester
          .widgetList<HighlightTarget>(find.byType(HighlightTarget))
          .where((w) => w.active)
          .toList();
      expect(activeTargets, hasLength(1));
      expect(find.byWidget(activeTargets.single), findsOneWidget);
    });
  });
}

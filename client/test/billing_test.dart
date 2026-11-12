import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/billing.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/features/billing/billing_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

class FakeStore implements StorePurchases {
  FakeStore(this.source, {this.country});
  @override
  final String? source;
  final String? country;
  final _purchases = StreamController<StorePurchase>.broadcast();
  final bought = <String>[];
  final completed = <String>[];
  var restoredWith = '';

  @override
  Future<String?> storefront() async => country;
  @override
  Future<List<StoreProduct>> products(Set<String> ids) async =>
      [for (final id in ids) StoreProduct(id: id, price: source == 'app_store' ? r'$9.99' : r'$9.49')];
  @override
  Future<void> buy(StoreProduct product, {required String orgId}) async {
    bought.add('${product.id}@$orgId');
    _purchases.add(StorePurchase(
      source: source!,
      productId: product.id,
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
      backendProvider.overrideWithValue(backend),
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

  testWidgets('desktop and web: web checkout, credit packs, usage and Cloud Connect keys', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    final opened = <String>[];
    await tester.pumpWidget(app(backend, opened: opened));
    await tester.pumpAndSettle();
    expect(find.text('Free'), findsOneWidget);
    expect(find.text(r'Credits: $1.00'), findsOneWidget);
    expect(find.byKey(const Key('buyStore-pro')), findsNothing);
    expect(find.byKey(const Key('restorePurchases')), findsNothing);
    await tester.tap(find.byKey(const Key('buyWeb-pro')));
    await tester.pumpAndSettle();
    expect(backend.checkouts, ['pro']);
    expect(opened, ['https://checkout.example.com/pro']);
    await tester.tap(find.byKey(const Key('pack-credits_10')));
    await tester.pumpAndSettle();
    expect(opened.last, 'https://checkout.example.com/credits_10');
    // One row to Usage with the month's total; the full list lives there (D-182).
    expect(find.text(r'This month so far: $0.10'), findsOneWidget);
    expect(find.text('Cloud computers: 2.00 h · home-server'), findsNothing);

    // Cloud Connect keys are under Advanced.
    expect(find.byKey(const Key('createConnectKey')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('createConnectKey')));
    await tester.tap(find.byKey(const Key('createConnectKey')));
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

  testWidgets('the plan stays up top, the usage row opens Usage, Cloud Connect keys fold under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(430, 1800));
    await tester.pumpWidget(app(FakeBackend()..billingEnabled = true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currentPlan')), findsOneWidget);
    expect(find.byKey(const Key('buyWeb-pro')), findsOneWidget);
    expect(find.text('Charges by server, Cloud Connect keys'), findsOneWidget);
    expect(find.byKey(const Key('createConnectKey')), findsNothing);
    expect(find.byKey(const Key('billedItems')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('advanced-billing')));
    await tester.tap(find.byKey(const Key('advanced-billing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('createConnectKey')), findsOneWidget);
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
    expect(find.byKey(const Key('buyWeb-pro')), findsNothing);
    expect(find.byKey(const Key('pack-credits_10')), findsNothing);
    expect(find.byKey(const Key('restorePurchases')), findsOneWidget);
    expect(find.text(r'Subscribe for $9.99'), findsOneWidget);
    await tester.tap(find.byKey(const Key('buyStore-pro')));
    await tester.pumpAndSettle();
    expect(store.bought, ['dev.casama.pro.monthly@$orgId']);
    expect(backend.verified, ['app_store:dev.casama.pro.monthly:2000000123']);
    expect(store.completed, ['dev.casama.pro.monthly']);
    expect(find.text('Billed through the App Store'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('currentPlan')), matching: find.text('Pro')), findsOneWidget);
  });

  testWidgets('iOS on the US storefront also offers web checkout', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    await tester.pumpWidget(app(backend, store: FakeStore('app_store', country: 'USA'), platform: TargetPlatform.iOS));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buyStore-pro')), findsOneWidget);
    expect(find.byKey(const Key('buyWeb-pro')), findsOneWidget);
  });

  testWidgets('Android: Restore Purchases sends the purchase token to the server', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    final store = FakeStore('google_play', country: 'USA');
    await tester.pumpWidget(app(backend, store: store, platform: TargetPlatform.android));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buyWeb-pro')), findsNothing);
    expect(find.text(r'Subscribe for $9.49'), findsOneWidget);
    await tester.tap(find.byKey(const Key('restorePurchases')));
    await tester.pumpAndSettle();
    expect(store.restoredWith, orgId);
    expect(backend.verified, ['google_play:casama_pro:restored-token']);
    expect(find.text('Billed through Google Play'), findsOneWidget);
  });

  testWidgets('a 402 from the server opens the paywall, which leads to the plans', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend()..billingEnabled = true;
    onPaymentRequired = showPaywall;
    addTearDown(() => onPaymentRequired = null);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runGuarded(context, () async {
                final req = RequestOptions(path: '/v1/bots');
                throw DioException(
                  requestOptions: req,
                  response: Response(
                    requestOptions: req,
                    statusCode: 402,
                    data: {'type': 'about:blank', 'title': 'Payment Required', 'status': 402, 'code': 'plan_limit', 'detail': 'Your plan allows 2 bots. Upgrade in Billing to add more.'},
                  ),
                );
              }),
              child: const Text('Add bot'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/settings/billing', builder: (_, _) => const BillingScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend), platformProvider.overrideWithValue(TargetPlatform.macOS)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.tap(find.text('Add bot'));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade your plan'), findsOneWidget);
    expect(find.text('Your plan allows 2 bots. Upgrade in Billing to add more.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paywallSeePlans')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plan-pro')), findsOneWidget);
  });
}

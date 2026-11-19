import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:casama_sdk/casama_sdk.dart';

import 'providers.dart';
import 'distribution.dart';
import 'haptics.dart';
import 'telemetry.dart';
import 'analytics.dart';
import 'review_prompt.dart';
import '../l10n/generated/app_localizations.dart';

/// Where a purchase can happen (D-070).
enum PurchaseChannel { web, appStore, googlePlay }

/// Store rules (SPEC "Monetization"): digital subscriptions bought in the iOS app use Apple in-app
/// purchase, and a link to web checkout is shown only on the US storefront. Android uses Google Play
/// billing. Web and desktop use Dodo checkout. Re-check store rules every quarter.
List<PurchaseChannel> purchaseChannels({
  required TargetPlatform platform,
  required bool isWeb,
  String? storefront,
}) {
  if (isWeb) return const [PurchaseChannel.web];
  switch (platform) {
    case TargetPlatform.iOS:
      final us = storefront == 'USA' || storefront == 'US';
      return us ? const [PurchaseChannel.appStore, PurchaseChannel.web] : const [PurchaseChannel.appStore];
    // No web checkout link on Android, not even in the US: that needs Google's external content
    // links program (its fee, reporting and API), which we decided against on 2026-11-14.
    case TargetPlatform.android:
      return const [PurchaseChannel.googlePlay];
    // The Mac App Store build buys through StoreKit, with the same storefront rule as iOS.
    case TargetPlatform.macOS when isMacAppStoreBuild:
      final us = storefront == 'USA' || storefront == 'US';
      return us ? const [PurchaseChannel.appStore, PurchaseChannel.web] : const [PurchaseChannel.appStore];
    default:
      return const [PurchaseChannel.web];
  }
}

/// RevenueCat's public SDK keys (D-297). They are meant to ship inside the apps; a build can point
/// at another RevenueCat project with these defines.
const kRevenueCatAppleKey = String.fromEnvironment('CASAMA_REVENUECAT_APPLE_KEY', defaultValue: 'appl_latZWsuTtiUgUXjNfDEIIXcRpwm');
const kRevenueCatGoogleKey = String.fromEnvironment('CASAMA_REVENUECAT_GOOGLE_KEY', defaultValue: 'goog_wnpnuPIbuxupCqOPgzEAQhWbUBa');

/// Where a store purchase stands.
enum PurchaseStatus { pending, purchased, restored, error, canceled }

/// A product as the store shows it (localized price).
class StoreProduct {
  const StoreProduct({required this.id, required this.price, this.amount, this.currencyCode, this.raw});

  /// The id the server knows: App Store product id, or Google `product:basePlan`.
  final String id;
  final String price;

  /// The price as a number, in [currencyCode]; null when the store didn't give one.
  final double? amount;
  final String? currencyCode;
  final Object? raw;
}

/// A purchase or restored purchase the server must verify before it counts.
class StorePurchase {
  const StorePurchase({
    required this.source,
    required this.productId,
    this.transactionId,
    this.purchaseToken,
    this.restored = false,
    this.status = PurchaseStatus.purchased,
    this.error,
    this.raw,
  });
  final String source; // app_store | google_play
  final String productId;
  final String? transactionId;
  final String? purchaseToken;
  final bool restored;
  final PurchaseStatus status;
  final Object? error;
  final Object? raw;
}

/// App Store and Google Play through RevenueCat (D-297); a fake in tests.
abstract class StorePurchases {
  /// app_store, google_play, or null where there is no store (web, desktop).
  String? get source;
  Future<String?> storefront();
  Future<List<StoreProduct>> products(Set<String> ids);

  /// Free-trial days the store has confirmed this person gets on each of [ids] (product id to
  /// days). A product with no trial, an unknown or ineligible answer is left out, so the paywall
  /// never promises a trial it can't confirm (App Store 3.1.2).
  Future<Map<String, int>> freeTrialDays(Set<String> ids);

  /// [consumable] is for credit packs, which can be bought again and again (D-244).
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false});
  Future<void> restore({required String orgId});
  Stream<StorePurchase> get purchases;
  Future<void> complete(StorePurchase purchase);
}

class NoStore implements StorePurchases {
  const NoStore();
  @override
  String? get source => null;
  @override
  Future<String?> storefront() async => null;
  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => const [];
  @override
  Future<Map<String, int>> freeTrialDays(Set<String> ids) async => const {};
  @override
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false}) async {}
  @override
  Future<void> restore({required String orgId}) async {}
  @override
  Stream<StorePurchase> get purchases => const Stream.empty();
  @override
  Future<void> complete(StorePurchase purchase) async {}
}

/// The App Store (iOS and the Mac App Store build) and Google Play through RevenueCat (D-297).
/// The workspace is the RevenueCat customer (its id is the app user id), so a purchase belongs to
/// the workspace it was made in and the server finds it there. RevenueCat finishes transactions
/// and consumes credit packs; the server reads what was bought from RevenueCat.
class RevenueCatStore implements StorePurchases {
  RevenueCatStore(this.source, this._apiKey, this._currentOrg);
  @override
  final String source;
  final String _apiKey;

  /// The workspace open now, so RevenueCat starts out as that customer rather than an anonymous one.
  final String? Function() _currentOrg;
  final _purchases = StreamController<StorePurchase>.broadcast();
  Future<void>? _configured;
  String? _user;

  bool get _android => source == 'google_play';

  /// Sets RevenueCat up once, then switches it to [orgId] when given.
  Future<void> _ready([String? orgId]) async {
    _configured ??= () async {
      _user = orgId ?? _currentOrg();
      await rc.Purchases.configure(rc.PurchasesConfiguration(_apiKey)..appUserID = _user);
    }();
    await _configured;
    if (orgId != null && orgId != _user) {
      await rc.Purchases.logIn(orgId);
      _user = orgId;
    }
  }

  @override
  Future<String?> storefront() async {
    try {
      await _ready();
      return (await rc.Purchases.storefront)?.countryCode;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    try {
      await _ready();
      // Google asks for subscriptions and one-time products separately; Apple answers both at once.
      final found = <rc.StoreProduct>[
        ...await rc.Purchases.getProducts(ids.toList()),
        if (_android) ...await rc.Purchases.getProducts(ids.toList(), productCategory: rc.ProductCategory.nonSubscription),
      ];
      final out = <String, StoreProduct>{};
      for (final p in found) {
        if (!ids.contains(p.identifier)) continue;
        out[p.identifier] = StoreProduct(id: p.identifier, price: p.priceString, amount: p.price, currencyCode: p.currencyCode, raw: p);
      }
      return out.values.toList();
    } catch (e) {
      debugPrint('store products unavailable: $e');
      return const [];
    }
  }

  /// A free trial in whole days (7 days, or 1 week), or null for anything else.
  static int? _trialDays(rc.PeriodUnit unit, int count) => switch (unit) {
    rc.PeriodUnit.day => count > 0 ? count : null,
    rc.PeriodUnit.week => count > 0 ? count * 7 : null,
    _ => null,
  };

  /// Apple: the product has a free introductory offer and the person is eligible for it.
  /// Google Play never reports eligibility, so the subscription option the store would start
  /// (its default one, which already accounts for who qualifies) must open with a free phase.
  @override
  Future<Map<String, int>> freeTrialDays(Set<String> ids) async {
    try {
      await _ready();
      final found = (await rc.Purchases.getProducts(ids.toList())).where((p) => ids.contains(p.identifier)).toList();
      final out = <String, int>{};
      if (_android) {
        for (final p in found) {
          final phase = p.defaultOption?.freePhase;
          final period = phase?.billingPeriod;
          final days = period == null ? null : _trialDays(period.unit, period.value);
          if (days != null) out[p.identifier] = days;
        }
        return out;
      }
      final intro = found.where((p) => (p.introductoryPrice?.price ?? 1) == 0).toList();
      if (intro.isEmpty) return out;
      final eligibility = await rc.Purchases.checkTrialOrIntroductoryPriceEligibility([for (final p in intro) p.identifier]);
      for (final p in intro) {
        if (eligibility[p.identifier]?.status != rc.IntroEligibilityStatus.introEligibilityStatusEligible) continue;
        final i = p.introductoryPrice!;
        final days = _trialDays(i.periodUnit, i.periodNumberOfUnits * (i.cycles > 0 ? i.cycles : 1));
        if (days != null) out[p.identifier] = days;
      }
      return out;
    } catch (e) {
      debugPrint('store trials unavailable: $e');
      return const {};
    }
  }

  @override
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false}) async {
    try {
      await _ready(orgId);
      // Google Play: a subscriber choosing another plan (or the other period) replaces the
      // subscription they have instead of starting a second one (D-248). Apple does this by itself,
      // because every plan is in one subscription group. Credit packs never replace anything.
      rc.StoreProductChangeInfo? change;
      if (_android && !consumable) {
        final info = await rc.Purchases.getCustomerInfo();
        final old = info.activeSubscriptions.where((id) => id != product.id).firstOrNull;
        if (old != null) change = rc.StoreProductChangeInfo(old, replacementMode: rc.StoreReplacementMode.withTimeProration);
      }
      final r = await rc.Purchases.purchase(
        rc.PurchaseParams.storeProduct(product.raw! as rc.StoreProduct, productChangeInfo: change),
      );
      _purchases.add(StorePurchase(
        source: source,
        productId: product.id,
        transactionId: r.storeTransaction.transactionIdentifier,
      ));
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      _purchases.add(StorePurchase(
        source: source,
        productId: product.id,
        status: switch (code) {
          rc.PurchasesErrorCode.purchaseCancelledError => PurchaseStatus.canceled,
          rc.PurchasesErrorCode.paymentPendingError => PurchaseStatus.pending,
          _ => PurchaseStatus.error,
        },
        error: e,
      ));
    }
  }

  /// Restores into [orgId]: each active subscription is checked with the server, which finds it
  /// under the workspace it was bought for (a purchase never moves to another workspace).
  @override
  Future<void> restore({required String orgId}) async {
    await _ready(orgId);
    final info = await rc.Purchases.restorePurchases();
    for (final id in info.activeSubscriptions) {
      _purchases.add(StorePurchase(source: source, productId: id, restored: true, status: PurchaseStatus.restored));
    }
  }

  @override
  Stream<StorePurchase> get purchases => _purchases.stream;

  /// RevenueCat finishes transactions itself.
  @override
  Future<void> complete(StorePurchase purchase) async {}
}

StorePurchases defaultStore(String? Function() currentOrg) {
  if (kIsWeb) return const NoStore();
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => RevenueCatStore('app_store', kRevenueCatAppleKey, currentOrg),
    TargetPlatform.android => RevenueCatStore('google_play', kRevenueCatGoogleKey, currentOrg),
    TargetPlatform.macOS when isMacAppStoreBuild => RevenueCatStore('app_store', kRevenueCatAppleKey, currentOrg),
    _ => const NoStore(),
  };
}

final storeProvider = Provider<StorePurchases>((ref) => defaultStore(() => ref.read(currentOrgProvider)?.id));

/// The current workspace's billing; `enabled` is false on self-hosted servers.
final billingProvider = FutureProvider<BillingSummary?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).billing(org.id);
});

/// This month's billed usage and the latest credit changes for the current workspace.
final billingUsageProvider = FutureProvider<BillingUsage?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? null : ref.watch(backendProvider).billingUsage(org.id);
});

/// Verifies store purchases with the server as they arrive (purchases and Restore Purchases).
class PurchaseVerifier {
  PurchaseVerifier(this.ref);
  final Ref ref;
  StreamSubscription<StorePurchase>? _sub;
  final _outcomes = StreamController<PurchaseOutcome>.broadcast();

  /// What happened to each purchase, for the screen that started it to say so (D-248).
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  void _tell(PurchaseOutcome o) {
    if (!_outcomes.isClosed) _outcomes.add(o);
  }

  /// Purchase analytics carry what was bought (D-248).
  static String _kind(StorePurchase p) => p.productId.contains('credits') ? 'credit_pack' : 'subscription';

  void start() {
    _sub ??= ref.read(storeProvider).purchases.listen(_verify);
  }

  Future<void> _verify(StorePurchase p) async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;

    if (p.status == PurchaseStatus.canceled) {
      // Finished so a cancelled transaction never stays in the store's queue.
      await ref.read(storeProvider).complete(p).catchError((_) {});
      await Analytics.capture('purchase_completed', properties: {
        'outcome': 'cancelled',
        'store': p.source,
        'product_id': p.productId,
        'kind': _kind(p),
      });
      return;
    }

    if (p.status == PurchaseStatus.error) {
      await ref.read(storeProvider).complete(p).catchError((_) {});
      _tell(PurchaseOutcome.failed);
      await Analytics.capture('purchase_completed', properties: {
        'outcome': 'failed',
        'reason': 'store_error',
        'store': p.source,
        'product_id': p.productId,
        'kind': _kind(p),
      });
      return;
    }

    if (p.status == PurchaseStatus.pending) {
      _tell(PurchaseOutcome.pending);
      await Analytics.capture('purchase_completed', properties: {
        'outcome': 'pending',
        'store': p.source,
        'product_id': p.productId,
        'kind': _kind(p),
      });
      return;
    }

    if (p.status != PurchaseStatus.purchased && p.status != PurchaseStatus.restored) {
      return;
    }

    try {
      await ref.read(backendProvider).verifyPurchase(org.id,
          source: p.source, productId: p.productId, transactionId: p.transactionId, purchaseToken: p.purchaseToken);
      await ref.read(storeProvider).complete(p);
      ref.invalidate(billingProvider);
      // A new purchase went through (Restore Purchases replays old ones, quietly).
      if (!p.restored) {
        HapticsHelper.success();
        _tell(PurchaseOutcome.purchased);
        // A good moment for the store's rating prompt (D-305); the store shows it over the celebration.
        unawaited(ref.read(reviewPromptProvider).moment(ReviewMoment.purchase));
        await Analytics.capture('purchase_completed', properties: {
          'outcome': 'purchased',
          'store': p.source,
          'product_id': p.productId,
          'kind': _kind(p),
        });
      } else {
        _tell(PurchaseOutcome.restored);
        Analytics.log('restore_purchases', {'outcome': 'restored', 'store': p.source});
      }
    } catch (e, st) {
      // Left uncompleted: the store redelivers it, and Restore Purchases retries.
      debugPrint('purchase verification failed: $e');
      Telemetry.captureException(e, st, context: {
        'source': p.source,
        'product_id': p.productId,
        'restored': p.restored,
      }, warning: true);
      _tell(PurchaseOutcome.verifyFailed);
      await Analytics.capture('purchase_completed', properties: {
        'outcome': 'failed',
        'reason': 'verification_failed',
        'store': p.source,
        'product_id': p.productId,
        'kind': _kind(p),
      });
    }
  }

  void dispose() {
    _sub?.cancel();
    _outcomes.close();
  }
}

/// What became of a store purchase or restore (D-248).
enum PurchaseOutcome { purchased, restored, pending, failed, verifyFailed }

/// Each purchase outcome as it happens; screens that sell listen and say what happened.
final purchaseOutcomeProvider = StreamProvider<PurchaseOutcome>(
  (ref) => ref.watch(purchaseVerifierProvider).outcomes,
);

/// The words for a purchase outcome, or null when there's nothing to add (a purchase that went
/// through celebrates on its own).
String? purchaseOutcomeText(AppLocalizations l10n, PurchaseOutcome o) => switch (o) {
  PurchaseOutcome.purchased => null,
  PurchaseOutcome.restored => l10n.purchasesRestored,
  PurchaseOutcome.pending => l10n.purchasePending,
  PurchaseOutcome.failed => l10n.purchaseFailed,
  PurchaseOutcome.verifyFailed => l10n.purchaseVerifyFailed,
};

final purchaseVerifierProvider = Provider<PurchaseVerifier>((ref) {
  final v = PurchaseVerifier(ref)..start();
  ref.onDispose(v.dispose);
  return v;
});

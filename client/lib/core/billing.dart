import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show ReplacementMode;
import 'package:casama_sdk/casama_sdk.dart';

import 'providers.dart';
import 'distribution.dart';
import 'haptics.dart';
import 'telemetry.dart';
import 'analytics.dart';
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

/// A product as the store shows it (localized price).
class StoreProduct {
  const StoreProduct({required this.id, required this.price, this.raw});

  /// The id the server knows: App Store product id, or Google `product:basePlan`.
  final String id;
  final String price;
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

/// App Store and Google Play through `in_app_purchase`; a fake in tests.
abstract class StorePurchases {
  /// app_store, google_play, or null where there is no store (web, desktop).
  String? get source;
  Future<String?> storefront();
  Future<List<StoreProduct>> products(Set<String> ids);

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
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false}) async {}
  @override
  Future<void> restore({required String orgId}) async {}
  @override
  Stream<StorePurchase> get purchases => const Stream.empty();
  @override
  Future<void> complete(StorePurchase purchase) async {}
}

class InAppPurchaseStore implements StorePurchases {
  InAppPurchaseStore(this.source);
  @override
  final String source;
  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Future<String?> storefront() async {
    try {
      return await _iap.countryCode();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async {
    if (!await _iap.isAvailable()) return const [];
    // Google ids are `product:basePlan`; the store is queried by product.
    final query = ids.map((i) => i.split(':').first).toSet();
    final res = await _iap.queryProductDetails(query);
    final out = <StoreProduct>[];
    for (final p in res.productDetails) {
      var id = p.id;
      if (p is GooglePlayProductDetails && p.subscriptionIndex != null) {
        final offer = p.productDetails.subscriptionOfferDetails?[p.subscriptionIndex!];
        if (offer?.offerId != null) continue; // base plans only; offers come later
        id = '${p.id}:${offer?.basePlanId}';
      }
      if (ids.contains(id)) out.add(StoreProduct(id: id, price: p.price, raw: p));
    }
    return out;
  }

  @override
  Future<void> buy(StoreProduct product, {required String orgId, bool consumable = false}) async {
    // The workspace id travels with the purchase (appAccountToken / obfuscatedAccountId), so the
    // server can refuse to link it to another workspace.
    final param = PurchaseParam(productDetails: product.raw! as ProductDetails, applicationUserName: orgId);
    if (consumable) {
      // The server consumes a Google purchase once it has added the credits, so a purchase that
      // fails verification is redelivered rather than lost. iOS finishes it in [complete].
      await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
      return;
    }
    // Google Play: a subscriber choosing another plan (or the other period) replaces the
    // subscription they have instead of starting a second one (D-248). iOS does this by itself,
    // because every plan is in one subscription group.
    final change = source == 'google_play' ? await _playSubscriptionToReplace() : null;
    await _iap.buyNonConsumable(
      purchaseParam: change == null
          ? param
          : GooglePlayPurchaseParam(
              productDetails: product.raw! as ProductDetails,
              applicationUserName: orgId,
              changeSubscriptionParam: ChangeSubscriptionParam(
                oldPurchaseDetails: change,
                replacementMode: ReplacementMode.withTimeProration,
              ),
            ),
    );
  }

  /// The Play subscription this person owns now, if any (credit packs are consumed, so they never
  /// show here; their ids name credits anyway).
  Future<GooglePlayPurchaseDetails?> _playSubscriptionToReplace() async {
    try {
      final past = await _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      return past.pastPurchases
          .whereType<GooglePlayPurchaseDetails>()
          .where((p) => !p.productID.contains('credits'))
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> restore({required String orgId}) => _iap.restorePurchases(applicationUserName: orgId);

  @override
  Stream<StorePurchase> get purchases => _iap.purchaseStream.expand((list) => list.map((p) => StorePurchase(
        source: source,
        productId: p.productID,
        transactionId: source == 'app_store' ? p.purchaseID : null,
        purchaseToken: source == 'google_play' ? p.verificationData.serverVerificationData : null,
        restored: p.status == PurchaseStatus.restored,
        status: p.status,
        error: p.error,
        raw: p,
      )));

  @override
  Future<void> complete(StorePurchase purchase) async {
    final p = purchase.raw;
    if (p is PurchaseDetails && p.pendingCompletePurchase) await _iap.completePurchase(p);
  }
}

StorePurchases defaultStore() {
  if (kIsWeb) return const NoStore();
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => InAppPurchaseStore('app_store'),
    TargetPlatform.android => InAppPurchaseStore('google_play'),
    TargetPlatform.macOS when isMacAppStoreBuild => InAppPurchaseStore('app_store'),
    _ => const NoStore(),
  };
}

final storeProvider = Provider<StorePurchases>((ref) => defaultStore());

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

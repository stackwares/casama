import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show ProductDetails;
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics.dart';
import '../../core/billing.dart';
import '../../core/haptics.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/celebration.dart';
import '../../ui/effects.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/mascot.dart';
import 'billing_screen.dart';
import 'purchase_terms.dart';

/// Opens the paywall over everything on screen, sheets and dialogs included, so it is never hidden
/// under the sheet that hit the limit. Closing it goes back to exactly where the person was (the
/// half-filled New bot sheet, say), ready to try again after upgrading. Returns true when the
/// workspace moved to a paid plan while it was open.
Future<bool> openPaywall(
  BuildContext context, {
  String? reason,
  String source = 'limit',
}) async {
  unawaited(
    Analytics.capture(
      'paywall_view',
      properties: {'source': source, 'paywall_kind': 'regular'},
    ),
  );
  final upgraded = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(reason: reason, source: source),
    ),
  );
  if (upgraded != true) {
    unawaited(Analytics.capture('paywall_dismiss', properties: {'source': source}));
  }
  return upgraded == true;
}

/// One paid tier: its monthly and yearly plans (`pro` and `pro_yearly`), either may be missing.
class PaywallTier {
  const PaywallTier(this.code, {this.monthly, this.yearly});
  final String code;
  final Plan? monthly;
  final Plan? yearly;

  String get name => (monthly ?? yearly)!.name;
}

/// The paid plans grouped into tiers by base code (`x` and `x_yearly` share one), in catalog order.
List<PaywallTier> paywallTiers(Iterable<Plan> plans) {
  final order = <String>[];
  final monthly = <String, Plan>{};
  final yearly = <String, Plan>{};
  for (final p in plans) {
    if (p.interval.value == 'none') continue;
    final code = paywallTierOf(p.code);
    if (!order.contains(code)) order.add(code);
    (p.interval.value == 'year' ? yearly : monthly)[code] = p;
  }
  return [for (final c in order) PaywallTier(c, monthly: monthly[c], yearly: yearly[c])];
}

String paywallTierOf(String planCode) =>
    planCode.endsWith('_yearly') ? planCode.substring(0, planCode.length - '_yearly'.length) : planCode;

/// The tier the paywall opens on: the one just above the current plan, Pro from Free.
String? defaultPaywallTier(List<PaywallTier> tiers, String? currentPlan) {
  if (tiers.isEmpty) return null;
  final i = currentPlan == null ? -1 : tiers.indexWhere((t) => t.code == paywallTierOf(currentPlan));
  if (i < 0) return (tiers.where((t) => t.code == 'pro').firstOrNull ?? tiers.first).code;
  return tiers[math.min(i + 1, tiers.length - 1)].code;
}

/// Casama's paid plans, sold with the mascots: who you get, what they can do, a tier and a billing
/// period to pick, and one button (D-236, D-244).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason, this.source = 'limit'});

  /// Why it opened, in the server's words ("Your plan allows 2 bots."). Shown as a small pill.
  final String? reason;
  final String source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with WidgetsBindingObserver {
  String? _tier;
  // Yearly first: the better deal.
  var _yearly = true;
  var _busy = false;
  String? _startPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Store purchases and restores are verified by the server as they arrive.
    ref.read(purchaseVerifierProvider);
    _startPlan = ref.read(billingProvider).value?.planCode;
    // A store that failed to list its products last time gets another try (D-248). Only where
    // there is a store (the web has none, so its list is always empty), and after this frame:
    // invalidating while the route builds throws in debug.
    final listed = ref.read(storeProductsProvider);
    if (ref.read(storeProvider).source != null &&
        (listed.hasError || (listed.value?.isEmpty ?? false))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(storeProductsProvider);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from web checkout in the browser: look again, so a finished checkout shows right away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(billingProvider);
  }

  String get _orgId => ref.read(currentOrgProvider)!.id;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  void _close() => Navigator.of(context).pop(false);

  Future<void> _web(Plan p) => _run(() async {
    unawaited(
      Analytics.capture(
        'purchase_started',
        properties: {
          'store': 'dodo',
          'kind': 'subscription',
          'product_id': p.code,
        },
      ),
    );
    final url = await ref
        .read(backendProvider)
        .checkoutUrl(_orgId, planCode: p.code);
    if (url == null) {
      // Moved to the new plan in place (D-248); the billing listener celebrates it.
      ref.invalidate(billingProvider);
      return;
    }
    await ref.read(openUrlProvider)(url);
  });

  Future<void> _store(StoreProduct product) => _run(() {
    unawaited(
      Analytics.capture(
        'purchase_started',
        properties: {
          'store': ref.read(storeProvider).source ?? 'store',
          'kind': 'subscription',
          'product_id': product.id,
        },
      ),
    );
    return ref.read(storeProvider).buy(product, orgId: _orgId);
  });

  Future<void> _restore() => _run(() async {
    await ref.read(storeProvider).restore(orgId: _orgId);
    if (mounted) showSuccess(context, context.l10n.restoreStarted);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;

    // The plan changed to a paid one while the paywall was open: celebrate and go back.
    ref.listen(billingProvider, (_, next) {
      final code = next.value?.planCode;
      if (code == null) return;
      // Opened before billing loaded: the first answer is where they start, not an upgrade.
      if (_startPlan == null) {
        _startPlan = code;
        return;
      }
      if (code == _startPlan || code == 'free') return;
      _startPlan = code;
      showCelebration(context, l10n.paywallWelcomePlan(next.value!.planName), mascot: Mascot.starry);
      Navigator.of(context).pop(true);
    });
    // Say what happened to a store purchase that didn't simply go through (D-248).
    ref.listen(purchaseOutcomeProvider, (_, next) {
      final o = next.value;
      final text = o == null ? null : purchaseOutcomeText(l10n, o);
      if (text == null || !mounted) return;
      showToast(context, text, kind: o == PurchaseOutcome.restored ? ToastKind.success : ToastKind.info);
    });

    final billing = ref.watch(billingProvider).value;
    final catalog = ref.watch(planCatalogProvider).value;
    final products =
        ref.watch(storeProductsProvider).value ??
        const <String, StoreProduct>{};
    final source = ref.watch(storeProvider).source;
    final channels = purchaseChannels(
      platform: ref.watch(platformProvider),
      isWeb: kIsWeb,
      storefront: ref.watch(storefrontProvider).value,
    );
    final org = ref.watch(currentOrgProvider);
    final isAdmin = org != null && org.role != OrgRole.member;
    final storeChannel = channels.any((c) => c != PurchaseChannel.web);

    // In a store with no web checkout, only plans the store sells are offered, so no tier or
    // period leads to a button that does nothing (D-248). Until the store answers, all show.
    final storeOnly = storeChannel && !channels.contains(PurchaseChannel.web) && source != null;
    final sellable = (catalog?.plans ?? const <Plan>[]).where(
      (p) => !storeOnly || products.isEmpty || products[p.storeProductIds[source]] != null,
    );
    final tiers = paywallTiers(sellable);
    final tier =
        tiers.where((t) => t.code == _tier).firstOrNull ??
        tiers.where((t) => t.code == defaultPaywallTier(tiers, billing?.planCode)).firstOrNull;
    final selected = tier == null
        ? null
        : (_yearly ? tier.yearly ?? tier.monthly : tier.monthly ?? tier.yearly);
    final yearly = selected?.interval.value == 'year';
    final isCurrent = selected != null && selected.code == billing?.planCode;
    final free = catalog?.plans
        .where((p) => p.interval.value == 'none')
        .firstOrNull;
    final current = billing?.limits ?? free?.limits ?? const <String, num>{};

    StoreProduct? productFor(Plan p) {
      if (!storeChannel || source == null) return null;
      return products[p.storeProductIds[source]];
    }

    String? priceFor(Plan p) => productFor(p)?.price ?? p.priceLabel;

    /// What a plan costs as a number: the store's own price, else the web price label. A store
    /// product without a number gives null, never the web's dollars beside the store's price.
    double? amountOf(Plan? p) {
      if (p == null) return null;
      final product = productFor(p);
      if (product != null) return product.raw is ProductDetails ? (product.raw as ProductDetails).rawPrice : null;
      final m = RegExp(r'[0-9][0-9,]*(\.[0-9]+)?').firstMatch(p.priceLabel ?? '');
      return m == null ? null : double.tryParse(m.group(0)!.replaceAll(',', ''));
    }

    // The currency prices are in: the store's own, else the web's dollars.
    String currencyOf(Plan? p) {
      final raw = p == null ? null : productFor(p)?.raw;
      return raw is ProductDetails ? raw.currencyCode : 'USD';
    }

    String money(double v, String code) =>
        v.humanizedCurrency(l10n.localeName, code, decimalDigits: v == v.roundToDouble() ? 0 : 2);

    // Months free and percent saved on yearly, worked out from the prices shown (store prices
    // differ by country).
    int monthsFreeOf(PaywallTier t) {
      final m = amountOf(t.monthly), y = amountOf(t.yearly);
      return m == null || y == null || m <= 0 ? 0 : (12 - y / m).round();
    }

    int savePercentOf(PaywallTier t) {
      final m = amountOf(t.monthly), y = amountOf(t.yearly);
      return m == null || y == null || m <= 0 ? 0 : ((1 - y / (12 * m)) * 100).floor();
    }

    final bestSave = tiers.fold(0, (best, t) => math.max(best, savePercentOf(t)));
    final hasBothPeriods = tiers.any((t) => t.monthly != null && t.yearly != null);
    // The free trial comes with web checkout only. In a store the store alone decides who gets its
    // introductory offer, so the paywall never promises one there (App Store 3.1.2, Play's
    // subscription policy); the store's own payment sheet states the offer to whoever gets it.
    final trialOpen = billing?.trialAvailable == true && !storeChannel;
    int? trialDaysOf(PaywallTier t) => trialOpen ? (t.monthly ?? t.yearly)?.limits['trial_days']?.toInt() : null;

    /// What one tier's card shows for the period picked: its price, how it is billed, and on a
    /// web yearly plan the monthly price it beats.
    _CardPrice? cardPrice(PaywallTier t) {
      final plan = _yearly ? t.yearly ?? t.monthly : t.monthly ?? t.yearly;
      if (plan == null) return null;
      final code = currencyOf(plan);
      final amount = amountOf(plan);
      final product = productFor(plan);
      // A store plan billed yearly leads with what is actually charged, the yearly price; the
      // per-month figure only follows it (App Store 3.1.2: the billed amount is the most prominent
      // price). No struck-through monthly price beside it either.
      if (plan.interval.value == 'year' && product != null) {
        return _CardPrice(
          plan: plan,
          big: product.price,
          suffix: l10n.paywallPerYearShort,
          billed: amount == null ? l10n.paywallBilledYearlyPlain : l10n.paywallWorksOutTo(money(amount / 12, code)),
          monthsFree: monthsFreeOf(t),
        );
      }
      // Web checkout: the yearly price per month, with the yearly total right under it.
      if (plan.interval.value == 'year') {
        final monthly = amountOf(t.monthly);
        return _CardPrice(
          plan: plan,
          // Without a number to divide, the price label stands as it is.
          big: amount == null ? (priceFor(plan) ?? '') : money(amount / 12, code),
          suffix: amount == null ? '' : l10n.paywallPerMonthShort,
          billed: amount == null ? l10n.paywallBilledYearlyPlain : l10n.paywallBilledYearly(money(amount, code)),
          was: monthly == null || amount == null || monthly * 12 <= amount ? null : money(monthly, code),
          monthsFree: monthsFreeOf(t),
        );
      }
      return _CardPrice(
        plan: plan,
        big: productFor(plan)?.price ?? (amount == null ? (priceFor(plan) ?? '') : money(amount, code)),
        suffix: productFor(plan) != null || amount != null ? l10n.paywallPerMonthShort : '',
        billed: l10n.paywallBilledMonthly,
      );
    }

    // One subscription per workspace (D-248): someone who already pays changes plans where they
    // subscribed. A web subscriber is moved in place by web checkout; a store subscriber only in
    // that store (another store, or the web, would start a second subscription).
    final paidVia = billing != null && billing.planCode != 'free' ? billing.source_.value : null;
    final storeSub = paidVia == 'app_store' || paidVia == 'google_play';
    final elsewhere = storeSub && paidVia != source;
    final webSub = paidVia == 'dodo';

    // A paying workspace picking its own tier's other period, or a smaller tier, is switching, not
    // upgrading: the button says so (D-248).
    final currentTier = billing == null ? null : paywallTierOf(billing.planCode);
    final tierRank = {for (final (i, t) in tiers.indexed) t.code: i};
    String? switchLabel;
    if (paidVia != null && selected != null && !isCurrent && currentTier != null) {
      final selectedTier = paywallTierOf(selected.code);
      if (selectedTier == currentTier) {
        switchLabel = l10n.paywallSwitchTo(yearly ? l10n.paywallYearly : l10n.paywallMonthly);
      } else if ((tierRank[selectedTier] ?? 0) < (tierRank[currentTier] ?? 0)) {
        switchLabel = l10n.paywallSwitchTo(tier!.name);
      }
    }

    // A first-time subscriber to a tier with a trial starts the trial; anyone else gets the plan.
    final selectedTrial = tier == null || paidVia != null ? null : trialDaysOf(tier);
    final startLabel = selectedTrial != null
        ? l10n.paywallStartTrial(selectedTrial)
        : l10n.paywallGetPlan(tier?.name ?? 'Pro');

    // What the main button does with the chosen plan: the store first, else web checkout.
    VoidCallback? buy;
    String buyLabel = l10n.paywallContinue;
    String? note;
    String? termsStore;
    if (isCurrent) {
      buyLabel = l10n.currentPlan;
    } else if (selected != null && isAdmin) {
      final product = webSub ? null : productFor(selected);
      if (elsewhere) {
        note = l10n.subscribedInStoreNote(paidVia == 'app_store' ? 'the App Store' : 'Google Play');
      } else if (product != null) {
        buy = () => _store(product);
        // The store decides who gets its intro offer, so its button promises only the price.
        buyLabel = switchLabel ?? l10n.subscribeFor(product.price);
        termsStore = source;
      } else if (channels.contains(PurchaseChannel.web) && selected.web) {
        buy = () => _web(selected);
        buyLabel = switchLabel ?? startLabel;
      } else if (webSub) {
        note = l10n.subscribedOnWebNote;
      }
    }
    final webToo =
        selected != null &&
        !isCurrent &&
        isAdmin &&
        !storeSub &&
        !webSub &&
        productFor(selected) != null &&
        channels.contains(PurchaseChannel.web) &&
        selected.web;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    onClose: _close,
                    // Anyone can restore: it only re-links purchases the store already has.
                    onRestore: storeChannel ? _restore : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        // Wide windows lay the tiers side by side; everything else stays narrow.
                        final wide = box.maxWidth >= 760 && tiers.length > 1;
                        // Short screens (a phone in landscape, a small window) skip the parade.
                        final parade = box.maxHeight >= 560;
                        Widget narrow(Widget child) => Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: child,
                          ),
                        );
                        final cards = [
                          for (final t in tiers)
                            if (cardPrice(t) case final price?)
                              _TierCard(
                                key: Key('paywallTier-${t.code}'),
                                name: t.name,
                                tagline: switch (t.code) {
                                  'plus' => l10n.paywallTaglinePlus,
                                  'pro' => l10n.paywallTaglinePro,
                                  'max' => l10n.paywallTaglineMax,
                                  _ => null,
                                },
                                facts: _facts(l10n, price.plan.limits),
                                price: price,
                                selected: t.code == tier?.code,
                                current: currentTier == t.code && paidVia != null,
                                popular: t.code == 'pro' && tiers.length > 1,
                                trial: trialDaysOf(t)?.let(l10n.trialDaysFree),
                                vertical: wide,
                                onTap: () {
                                  HapticsHelper.selection();
                                  setState(() => _tier = t.code);
                                },
                              ),
                        ];
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            0,
                            AppSpace.lg,
                            AppSpace.lg,
                          ),
                          children: [
                            if (parade) ...[
                              const _MascotParade(),
                              const SizedBox(height: AppSpace.xs),
                            ],
                            if (widget.reason case final reason?
                                when reason.isNotEmpty) ...[
                              Center(child: _ReasonPill(reason)),
                              const SizedBox(height: AppSpace.sm),
                            ],
                            narrow(
                              Text(
                                l10n.paywallTitleFor(tier?.name ?? 'Pro'),
                                textAlign: TextAlign.center,
                                style: context.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            narrow(
                              Text(
                                l10n.paywallSubtitle,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.lg),
                            if (hasBothPeriods) ...[
                              Center(
                                child: _PeriodToggle(
                                  yearly: _yearly,
                                  saveBadge: bestSave >= 1 ? l10n.paywallSaveUpTo(bestSave) : null,
                                  onChanged: (v) {
                                    HapticsHelper.selection();
                                    setState(() => _yearly = v);
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                            ],
                            if (wide)
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 980),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        for (final (i, c) in cards.indexed) ...[
                                          if (i > 0) const SizedBox(width: AppSpace.sm),
                                          Expanded(child: c),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              narrow(
                                Semantics(
                                  container: true,
                                  label: l10n.plans,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final (i, c) in cards.indexed) ...[
                                        if (i > 0) const SizedBox(height: AppSpace.sm),
                                        c,
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            // Side-by-side cards already list every number, so only phones get the
                            // what-changes list.
                            if (selected != null && !wide) ...[
                              const SizedBox(height: AppSpace.lg),
                              narrow(
                                Padding(
                                  padding: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.xs),
                                  child: Text(
                                    l10n.paywallWhatYouGet(tier!.name),
                                    style: context.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              narrow(_Perks(pro: selected.limits, current: current)),
                            ],
                            if (!isAdmin) ...[
                              const SizedBox(height: AppSpace.md),
                              narrow(
                                FormNote(
                                  l10n.paywallAskAdmin,
                                  icon: LucideIcons.shieldCheck,
                                ),
                              ),
                            ],
                            if (note != null) ...[
                              const SizedBox(height: AppSpace.md),
                              narrow(
                                FormNote(
                                  note,
                                  key: const Key('paywallChannelNote'),
                                  icon: LucideIcons.info,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  _BuyBar(
                    label: isAdmin || isCurrent ? buyLabel : l10n.close,
                    onBuy: isCurrent ? null : (isAdmin ? buy : _close),
                    busy: _busy,
                    onWeb: webToo ? () => _web(selected) : null,
                    terms: PurchaseTerms(
                      price: selected == null || isCurrent ? null : priceFor(selected),
                      yearly: yearly,
                      store: termsStore,
                      priceHasPeriod: termsStore == null,
                      trialDays: termsStore == null ? selectedTrial : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft colour behind the mascots: two glows from the brand's colours fading into the surface.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final a = context.isDark ? 0.30 : 0.20;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Glow(color: scheme.primary.withValues(alpha: a), size: 460),
          ),
          Positioned(
            top: -100,
            right: -140,
            child: _Glow(
              color: scheme.tertiary.withValues(alpha: a),
              size: 420,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, this.onRestore});
  final VoidCallback onClose;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.xxs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('paywallClose'),
            tooltip: l10n.close,
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: context.colorScheme.surfaceContainerHigh
                  .withValues(alpha: 0.7),
            ),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
          const Spacer(),
          if (onRestore != null)
            TextButton(
              key: const Key('paywallRestore'),
              onPressed: onRestore,
              child: Text(l10n.paywallRestore),
            ),
        ],
      ),
    );
  }
}

/// Five of the bots bobbing in an arc, Starry in the middle on a glowing halo.
class _MascotParade extends StatefulWidget {
  const _MascotParade();

  @override
  State<_MascotParade> createState() => _MascotParadeState();
}

class _MascotParadeState extends State<_MascotParade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  // Left to right: who stands where, how big, and how far below the middle one.
  static const _cast = [
    (Mascot.shy, 54.0, 34.0),
    (Mascot.lovey, 74.0, 14.0),
    (Mascot.starry, 118.0, 0.0),
    (Mascot.giggly, 74.0, 14.0),
    (Mascot.cool, 54.0, 34.0),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Effects.decorative(context)) {
      if (!_float.isAnimating) _float.repeat();
    } else {
      _float.stop();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final moving = Effects.decorative(context);
    return SizedBox(
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The halo behind the star of the show.
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(
                    scheme.primary,
                    scheme.tertiary,
                    0.4,
                  )!.withValues(alpha: context.isDark ? 0.45 : 0.28),
                  scheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _float,
            // Narrow phones shrink the parade rather than cutting off the outer bots.
            builder: (context, _) => FittedBox(
              fit: BoxFit.scaleDown,
              // The bottom pad makes room for the outer bots, drawn up to 38 px below the row, so
              // the scaled parade never reaches the title under it.
              child: Padding(
                padding: const EdgeInsets.only(bottom: 38),
                child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, (mascot, size, drop)) in _cast.indexed)
                    Padding(
                      padding: EdgeInsets.only(bottom: 18 - drop * 0.5),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          drop +
                              math.sin(_float.value * 2 * math.pi + i * 1.3) *
                                  (size > 100 ? 5 : 4),
                        ),
                        child: Transform.rotate(
                          angle: (i - 2) * 0.06,
                          child: MascotImage(
                            mascot,
                            size: size,
                            animate: moving,
                            semanticLabel: i == 2 ? mascot.label : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why the paywall opened, in a small warning-tinted pill.
class _ReasonPill extends StatelessWidget {
  const _ReasonPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final warn = context.appColors.warning;
    return Container(
      key: const Key('paywallReason'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warn.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: warn.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lock, size: 14, color: warn),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What Pro brings, one bot per perk, with the Pro amount next to what you have now.
class _Perks extends StatelessWidget {
  const _Perks({required this.pro, required this.current});
  final Map<String, num> pro;
  final Map<String, num> current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    String money(num v) => v.humanizedCurrency(locale, 'USD', decimalDigits: 0);
    String count(num v) => v.humanizedCount(locale, decimalDigits: 0);
    final rows = [
      // No bot limit on a plan means unlimited (D-249).
      (
        Mascot.thinker,
        l10n.paywallPerkBots,
        l10n.paywallPerkBotsBody,
        pro['max_bots']?.let(count) ?? l10n.unlimitedValue,
        current.isEmpty ? null : (current['max_bots']?.let(count) ?? l10n.unlimitedValue),
      ),
      if (pro['computer_hours'] case final v?)
        (
          Mascot.focused,
          l10n.paywallPerkComputers,
          l10n.paywallPerkComputersBody,
          l10n.paywallHours(count(v)),
          current['computer_hours']?.let((c) => l10n.paywallHours(count(c))),
        ),
      if (pro['monthly_credits_usd'] case final v?)
        (
          Mascot.wow,
          l10n.paywallPerkCredits,
          l10n.paywallPerkCreditsBody,
          money(v),
          current['monthly_credits_usd']?.let(money),
        ),
      if (pro['seats'] case final v?)
        (
          Mascot.lovey,
          l10n.paywallPerkSeats,
          l10n.paywallPerkSeatsBody,
          count(v),
          current['seats']?.let(count),
        ),
    ];
    final scheme = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color:
            (context.isDark
                    ? scheme.surfaceContainer
                    : scheme.surfaceContainerLowest)
                .withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        border: Border.all(color: context.appColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (final (i, (mascot, title, body, value, was))
              in rows.indexed) ...[
            if (i > 0)
              Divider(height: 1, indent: 76, color: context.appColors.hairline),
            _PerkRow(
              mascot: mascot,
              title: title,
              body: body,
              value: value,
              was: was == value ? null : was,
            ),
          ],
        ],
      ),
    );
  }
}

extension<T extends Object> on T {
  R let<R>(R Function(T) f) => f(this);
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.mascot,
    required this.title,
    required this.body,
    required this.value,
    this.was,
  });
  final Mascot mascot;
  final String title;
  final String body;
  final String value;
  final String? was;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerHigh,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: MascotImage(mascot, size: 42, animate: false),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                  fontFeatures: AppText.tabular,
                ),
              ),
              if (was != null)
                Text(
                  was!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    fontFeatures: AppText.tabular,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tier's price as its card shows it.
class _CardPrice {
  const _CardPrice({
    required this.plan,
    required this.big,
    required this.suffix,
    required this.billed,
    this.was,
    this.monthsFree = 0,
  });

  /// The plan this card buys for the period picked.
  final Plan plan;

  /// The headline price: per month (a yearly price divided by 12), or the raw label.
  final String big;

  /// What follows [big]: "/mo", "/yr", or nothing when the label carries its own period.
  final String suffix;

  /// How it is charged: "$490 billed yearly", "Billed monthly".
  final String billed;

  /// The monthly price yearly beats, struck through.
  final String? was;
  final int monthsFree;
}

/// The plan's headline numbers on one line each: bots, computer time, credits, people.
List<String> _facts(AppLocalizations l10n, Map<String, num> limits) => [
  // No bot limit on a plan means unlimited (D-249).
  if (limits['max_bots'] case final v?) l10n.limitBots(v.toInt()) else l10n.limitBotsUnlimited,
  if (limits['computer_hours'] case final v?) l10n.paywallFactHours(v.toInt()),
  if (limits['monthly_credits_usd'] case final v?)
    l10n.limitCredits(v.humanizedCurrency(l10n.localeName, 'USD', decimalDigits: 0)),
  if (limits['seats'] case final v?) l10n.paywallPeople(v.toInt()),
];

/// Monthly | Yearly as one pill, with what yearly saves riding on its half.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.yearly, required this.onChanged, this.saveBadge});
  final bool yearly;
  final ValueChanged<bool> onChanged;
  final String? saveBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    Widget half(bool isYearly, String label, Key key) {
      final on = yearly == isYearly;
      return Semantics(
        button: true,
        selected: on,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(isYearly),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: on ? scheme.onSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: on ? scheme.surface : scheme.onSurfaceVariant,
                  ),
                ),
                if (isYearly && saveBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.appColors.positive.withValues(alpha: on ? 0.9 : 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      saveBadge!,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: on ? Colors.white : context.appColors.positive,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Very narrow screens (or large text) shrink the pill rather than overflow it.
    return Semantics(
      container: true,
      label: l10n.paywallBillingPeriod,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerHigh).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: context.appColors.hairline),
        ),
        // Both halves as tall as the taller one, each as wide as its label.
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              half(false, l10n.paywallMonthly, const Key('paywallInterval-month')),
              half(true, l10n.paywallYearly, const Key('paywallInterval-year')),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// One tier to pick: name, who it suits, its price for the period picked and its headline numbers.
/// Stacked rows on phones; [vertical] columns side by side on wide windows.
class _TierCard extends StatelessWidget {
  const _TierCard({
    super.key,
    required this.name,
    required this.facts,
    required this.price,
    required this.selected,
    required this.onTap,
    this.tagline,
    this.current = false,
    this.popular = false,
    this.trial,
    this.vertical = false,
  });
  final String name;
  final String? tagline;
  final List<String> facts;
  final _CardPrice price;
  final bool selected;
  final bool current;
  final bool popular;

  /// "7 days free" when this tier's trial is still open.
  final String? trial;
  final bool vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final base = context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final muted = scheme.onSurfaceVariant;

    Widget pill(String text, {required Color color, bool filled = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: filled ? scheme.onPrimary : color,
        ),
      ),
    );

    final radio = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : Colors.transparent,
        border: Border.all(color: selected ? scheme.primary : scheme.outline, width: 2),
      ),
      child: selected ? Icon(LucideIcons.check, size: 14, color: scheme.onPrimary) : null,
    );

    final heading = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        if (current) pill(l10n.currentPlan, color: muted),
        if (popular && !current) pill(l10n.paywallMostPopular, color: scheme.primary, filled: true),
        if (trial != null && !current) pill(trial!, color: context.appColors.positive),
      ],
    );

    final priceBlock = Column(
      key: Key('paywallPrice-${price.plan.code}'),
      crossAxisAlignment: vertical ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              if (price.was case final was?)
                TextSpan(
                  text: '$was ',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: muted,
                    decoration: TextDecoration.lineThrough,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              TextSpan(
                text: price.big,
                style: (vertical ? context.textTheme.headlineSmall : context.textTheme.titleLarge)?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  fontFeatures: AppText.tabular,
                ),
              ),
              if (price.suffix.isNotEmpty)
                TextSpan(
                  text: price.suffix,
                  style: context.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
          textAlign: vertical ? TextAlign.start : TextAlign.end,
        ),
        Text(
          price.billed,
          textAlign: vertical ? TextAlign.start : TextAlign.end,
          style: context.textTheme.labelSmall?.copyWith(color: muted),
        ),
        if (price.monthsFree >= 1)
          Text(
            l10n.paywallMonthsFree(price.monthsFree),
            textAlign: vertical ? TextAlign.start : TextAlign.end,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.appColors.positive,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );

    final taglineText = tagline == null
        ? null
        : Text(tagline!, style: context.textTheme.bodySmall?.copyWith(color: muted, height: 1.3));
    final factsText = Text(
      facts.join(' · '),
      style: context.textTheme.labelSmall?.copyWith(color: muted, height: 1.4),
    );

    final body = vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [radio, const SizedBox(width: AppSpace.sm), Expanded(child: heading)]),
              if (taglineText != null) ...[const SizedBox(height: AppSpace.xs), taglineText],
              const SizedBox(height: AppSpace.md),
              priceBlock,
              const SizedBox(height: AppSpace.md),
              Divider(height: 1, color: context.appColors.hairline),
              const SizedBox(height: AppSpace.sm),
              for (final f in facts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(LucideIcons.check, size: 14, color: scheme.primary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(f, style: context.textTheme.bodySmall)),
                    ],
                  ),
                ),
            ],
          )
        // Phones: name and price share the top line; the numbers run the full width under them.
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: radio),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final name = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        if (taglineText != null) ...[const SizedBox(height: 2), taglineText],
                      ],
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Narrow cards (small phones, large text) put the price under the name.
                        if (box.maxWidth < 280) ...[
                          name,
                          const SizedBox(height: AppSpace.xs),
                          Align(alignment: AlignmentDirectional.centerStart, child: priceBlock),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: name),
                              const SizedBox(width: AppSpace.sm),
                              Flexible(child: priceBlock),
                            ],
                          ),
                        const SizedBox(height: AppSpace.xs),
                        factsText,
                      ],
                    );
                  },
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.curve,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(scheme.primary.withValues(alpha: context.isDark ? 0.16 : 0.07), base)
                : base.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.card + 4),
            border: Border.all(
              color: selected ? scheme.primary : context.appColors.hairline,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: body,
        ),
      ),
    );
  }
}

/// The one button, pinned to the bottom, with the fine print under it.
class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.label,
    required this.onBuy,
    required this.busy,
    required this.terms,
    this.onWeb,
  });
  final String label;
  final VoidCallback? onBuy;
  final bool busy;

  /// Price, renewal and cancellation terms, with the Terms and Privacy links.
  final Widget terms;
  final VoidCallback? onWeb;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface.withValues(alpha: 0),
            scheme.surface,
            scheme.surface,
          ],
          stops: const [0, 0.25, 1],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              math.max(bottom, AppSpace.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlowButton(
                  key: const Key('paywallBuy'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: busy ? null : onBuy,
                  child: busy
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Text(label),
                ),
                if (onWeb != null)
                  TextButton(
                    key: const Key('paywallWeb'),
                    onPressed: onWeb,
                    child: Text(context.l10n.subscribeOnWeb),
                  ),
                const SizedBox(height: AppSpace.xs),
                terms,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

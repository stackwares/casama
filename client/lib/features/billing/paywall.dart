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
    // A store that failed to list its products last time gets another try (D-248).
    final listed = ref.read(storeProductsProvider);
    if (listed.hasError || (listed.value?.isEmpty ?? false)) ref.invalidate(storeProductsProvider);
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

    /// What a plan costs as a number: the store's own price, else the web price label.
    double? amountOf(Plan? p) {
      if (p == null) return null;
      final raw = productFor(p)?.raw;
      if (raw is ProductDetails) return raw.rawPrice;
      final m = RegExp(r'[0-9][0-9,]*(\.[0-9]+)?').firstMatch(p.priceLabel ?? '');
      return m == null ? null : double.tryParse(m.group(0)!.replaceAll(',', ''));
    }

    // Months free on yearly, worked out from the prices shown (store prices differ by country).
    final monthlyAmount = amountOf(tier?.monthly);
    final yearlyAmount = amountOf(tier?.yearly);
    final monthsFree = monthlyAmount == null || yearlyAmount == null || monthlyAmount <= 0
        ? 0
        : (12 - yearlyAmount / monthlyAmount).round();
    final freeBadge = monthsFree >= 1 ? l10n.paywallMonthsFree(monthsFree) : null;

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
        buyLabel = l10n.subscribeFor(product.price);
        termsStore = source;
        if (switchLabel != null) buyLabel = switchLabel;
      } else if (channels.contains(PurchaseChannel.web) && selected.web) {
        buy = () => _web(selected);
        buyLabel = switchLabel ?? l10n.paywallContinueCheckout;
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            0,
                            AppSpace.lg,
                            AppSpace.lg,
                          ),
                          children: [
                            const _MascotParade(),
                            const SizedBox(height: AppSpace.md),
                            if (widget.reason case final reason?
                                when reason.isNotEmpty)
                              Center(child: _ReasonPill(reason)),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              l10n.paywallTitleFor(tier?.name ?? 'Pro'),
                              textAlign: TextAlign.center,
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              l10n.paywallSubtitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            if (tiers.length > 1) ...[
                              _Segmented(
                                semanticLabel: l10n.plans,
                                selected: tier?.code,
                                options: [
                                  for (final t in tiers)
                                    _Segment(
                                      t.code,
                                      t.name,
                                      // A first-time Pro subscriber tries it free (D-249).
                                      badge: billing?.trialAvailable == true &&
                                              (t.monthly ?? t.yearly)?.limits['trial_days'] != null
                                          ? l10n.trialDaysFree((t.monthly ?? t.yearly)!.limits['trial_days']!.toInt())
                                          : null,
                                      key: Key('paywallTier-${t.code}'),
                                    ),
                                ],
                                onSelect: (code) {
                                  HapticsHelper.selection();
                                  setState(() => _tier = code);
                                },
                              ),
                              const SizedBox(height: AppSpace.sm),
                            ],
                            if (tier?.monthly != null &&
                                tier?.yearly != null) ...[
                              _Segmented(
                                semanticLabel: l10n.paywallBillingPeriod,
                                selected: yearly ? 'year' : 'month',
                                options: [
                                  _Segment(
                                    'month',
                                    l10n.paywallMonthly,
                                    key: const Key('paywallInterval-month'),
                                  ),
                                  _Segment(
                                    'year',
                                    l10n.paywallYearly,
                                    badge: freeBadge,
                                    key: const Key('paywallInterval-year'),
                                  ),
                                ],
                                onSelect: (v) {
                                  HapticsHelper.selection();
                                  setState(() => _yearly = v == 'year');
                                },
                              ),
                              const SizedBox(height: AppSpace.md),
                            ],
                            if (selected != null)
                              _Perks(pro: selected.limits, current: current),
                            if (!isAdmin) ...[
                              const SizedBox(height: AppSpace.md),
                              FormNote(
                                l10n.paywallAskAdmin,
                                icon: LucideIcons.shieldCheck,
                              ),
                            ],
                            if (note != null) ...[
                              const SizedBox(height: AppSpace.md),
                              FormNote(
                                note,
                                key: const Key('paywallChannelNote'),
                                icon: LucideIcons.info,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _BuyBar(
                    // The chosen plan's price sits with the button, so it is always in sight.
                    price: selected == null
                        ? null
                        : _PriceCard(
                            plan: selected,
                            name: tier!.name,
                            yearly: yearly,
                            price: priceFor(selected),
                            // Price labels carry their own period ("$39 / month").
                            withPeriod: productFor(selected) != null,
                            freeBadge: freeBadge,
                          ),
                    label: isAdmin || isCurrent ? buyLabel : l10n.close,
                    onBuy: isCurrent ? null : (isAdmin ? buy : _close),
                    busy: _busy,
                    onWeb: webToo ? () => _web(selected) : null,
                    terms: PurchaseTerms(
                      price: selected == null || isCurrent ? null : priceFor(selected),
                      yearly: yearly,
                      store: termsStore,
                      priceHasPeriod: termsStore == null,
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
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The halo behind the star of the show.
          Container(
            width: 150,
            height: 150,
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

class _Segment {
  const _Segment(this.value, this.label, {required this.key, this.badge});
  final String value;
  final String label;
  final String? badge;
  final Key key;
}

/// A row of equal segments (the tiers, or Monthly / Yearly) that wraps its labels rather than
/// overflowing at 320 px.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.semanticLabel,
  });
  final List<_Segment> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (context.isDark
                  ? scheme.surfaceContainer
                  : scheme.surfaceContainerHigh)
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.appColors.hairline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final o in options)
                Expanded(
                  child: _SegmentButton(
                    segment: o,
                    selected: o.value == selected,
                    onTap: () => onSelect(o.value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });
  final _Segment segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = context.isDark
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerLowest;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        key: segment.key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.curve,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? base : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card - 4),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                segment.label,
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              if (segment.badge case final badge?)
                Text(
                  badge,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chosen plan and its price: the store's when there is one, else the plan's price label.
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.plan,
    required this.name,
    required this.yearly,
    required this.price,
    required this.withPeriod,
    this.freeBadge,
  });
  final Plan plan;
  final String name;
  final bool yearly;
  final String? price;
  final bool withPeriod;

  /// "2 months free", worked out from the prices; null when yearly saves less than a month.
  final String? freeBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final base = context.isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
    return Container(
      key: Key('paywallPrice-${plan.code}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: context.isDark ? 0.18 : 0.08),
          base,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  yearly
                      ? (freeBadge == null ? l10n.paywallYearly : '${l10n.paywallYearly} · $freeBadge')
                      : l10n.paywallMonthly,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: yearly ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: yearly ? FontWeight.w800 : null,
                  ),
                ),
              ],
            ),
          ),
          if (price case final price?) ...[
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    if (withPeriod)
                      TextSpan(
                        text:
                            ' ${yearly ? l10n.paywallPerYear : l10n.paywallPerMonth}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ],
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
    this.price,
  });
  final Widget? price;
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
                if (price != null) ...[
                  price!,
                  const SizedBox(height: AppSpace.md),
                ],
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

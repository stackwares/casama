import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../ui/pressable_scale.dart';
import 'billing_screen.dart';

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

/// Casama Pro, sold with the mascots: who you get, what they can do, one plan to pick and one button.
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
  String? _selected;
  var _busy = false;
  String? _startPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Store purchases and restores are verified by the server as they arrive.
    ref.read(purchaseVerifierProvider);
    _startPlan = ref.read(billingProvider).value?.planCode;
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
      if (code == null || code == _startPlan || code == 'free') return;
      _startPlan = code;
      showCelebration(context, l10n.paywallWelcomePro, mascot: Mascot.starry);
      Navigator.of(context).pop(true);
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

    final paid = [
      for (final p in catalog?.plans ?? const <Plan>[])
        if (p.interval.value != 'none' && p.code != billing?.planCode) p,
    ];
    // Yearly first chosen: the better deal.
    final selected =
        paid.where((p) => p.code == _selected).firstOrNull ??
        paid.where((p) => p.interval.value == 'year').firstOrNull ??
        paid.firstOrNull;
    final free = catalog?.plans
        .where((p) => p.interval.value == 'none')
        .firstOrNull;
    final current = billing?.limits ?? free?.limits ?? const <String, num>{};

    StoreProduct? productFor(Plan p) {
      if (!storeChannel || source == null) return null;
      return products[p.storeProductIds[source]];
    }

    String? priceFor(Plan p) => productFor(p)?.price ?? p.priceLabel;

    // What the main button does with the chosen plan: the store first, else web checkout.
    VoidCallback? buy;
    String buyLabel = l10n.paywallContinue;
    if (selected != null && isAdmin) {
      final product = productFor(selected);
      if (product != null) {
        buy = () => _store(product);
        buyLabel = l10n.subscribeFor(product.price);
      } else if (channels.contains(PurchaseChannel.web) && selected.web) {
        buy = () => _web(selected);
        buyLabel = l10n.paywallContinueCheckout;
      }
    }
    final webToo =
        selected != null &&
        isAdmin &&
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
                    onRestore: isAdmin && storeChannel ? _restore : null,
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
                              l10n.paywallTitle,
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
                            if (selected != null)
                              _Perks(pro: selected.limits, current: current),
                            if (!isAdmin) ...[
                              const SizedBox(height: AppSpace.md),
                              FormNote(
                                l10n.paywallAskAdmin,
                                icon: LucideIcons.shieldCheck,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _BuyBar(
                    // The plans sit with the button, so the price is always in sight.
                    picker: paid.isEmpty
                        ? null
                        : _PlanPicker(
                            plans: paid,
                            selected: selected?.code,
                            priceFor: priceFor,
                            onSelect: (p) {
                              HapticsHelper.selection();
                              setState(() => _selected = p.code);
                            },
                          ),
                    label: isAdmin ? buyLabel : l10n.close,
                    onBuy: isAdmin ? buy : _close,
                    busy: _busy,
                    onWeb: webToo ? () => _web(selected) : null,
                    fine: storeChannel
                        ? l10n.paywallFineStore
                        : l10n.paywallFineWeb,
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
      if (pro['max_bots'] case final v?)
        (
          Mascot.thinker,
          l10n.paywallPerkBots,
          l10n.paywallPerkBotsBody,
          count(v),
          current['max_bots']?.let(count),
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

/// The paid plans side by side; yearly wears the Best value ribbon.
class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.plans,
    required this.selected,
    required this.priceFor,
    required this.onSelect,
  });
  final List<Plan> plans;
  final String? selected;
  final String? Function(Plan) priceFor;
  final ValueChanged<Plan> onSelect;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in plans.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _PlanCard(
                plan: p,
                selected: p.code == selected,
                price: priceFor(p),
                onTap: () => onSelect(p),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.price,
    required this.onTap,
  });
  final Plan plan;
  final bool selected;
  final String? price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final yearly = plan.interval.value == 'year';
    final base = context.isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
    return Semantics(
      selected: selected,
      button: true,
      child: PressableScale(
        child: GestureDetector(
          key: Key('paywallPlan-${plan.code}'),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                curve: AppMotion.curve,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.md + 2,
                  AppSpace.md,
                  AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: context.isDark ? 0.18 : 0.08,
                          ),
                          base,
                        )
                      : base,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : context.appColors.hairline,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            yearly ? l10n.paywallYearly : l10n.paywallMonthly,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: AppMotion.of(context, AppMotion.fast),
                          child: Icon(
                            selected
                                ? LucideIcons.circleCheck
                                : LucideIcons.circle,
                            key: ValueKey(selected),
                            size: 20,
                            color: selected ? scheme.primary : scheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (price != null) ...[
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: price!,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' ${yearly ? l10n.paywallPerYear : l10n.paywallPerMonth}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      Text(
                        plan.name,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              if (yearly)
                PositionedDirectional(
                  top: -10,
                  start: AppSpace.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, 0.6)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      l10n.paywallBestValue,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    required this.fine,
    this.onWeb,
    this.picker,
  });
  final Widget? picker;
  final String label;
  final VoidCallback? onBuy;
  final bool busy;
  final String fine;
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
                if (picker != null) ...[
                  picker!,
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
                Text(
                  fine,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

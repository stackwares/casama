import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics.dart';
import '../../core/billing.dart';
import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../../ui/mascot.dart';
import 'paywall.dart';

final planCatalogProvider = FutureProvider<PlanCatalog>((ref) => ref.watch(backendProvider).plans());
final _usageProvider = FutureProvider<BillingUsage?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? null : ref.watch(backendProvider).billingUsage(org.id);
});
final _connectKeysProvider = FutureProvider<List<ConnectKey>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? const [] : ref.watch(backendProvider).connectKeys(org.id);
});
final storefrontProvider = FutureProvider<String?>((ref) => ref.watch(storeProvider).storefront());
final storeProductsProvider = FutureProvider<Map<String, StoreProduct>>((ref) async {
  final store = ref.watch(storeProvider);
  final source = store.source;
  if (source == null) return const {};
  final catalog = await ref.watch(planCatalogProvider.future);
  final ids = {for (final p in catalog.plans) ?p.storeProductIds[source]};
  return {for (final p in await store.products(ids)) p.id: p};
});

/// Overridable in tests (which platform the paywall rules apply to).
final platformProvider = Provider<TargetPlatform>((ref) => defaultTargetPlatform);

/// Opens a URL outside the app (checkout, portal, store subscription settings). Overridable in tests.
final openUrlProvider = Provider<Future<void> Function(String url)>(
  (ref) =>
      (url) async => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
);

/// Shown when the server answers 402 (plan limit or out of credits): the full-screen paywall, over
/// any sheet or dialog that was open (D-236).
Future<void> showPaywall(BuildContext context, String message) => openPaywall(context, reason: message);

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Store purchases and restores are verified by the server as they arrive.
    ref.read(purchaseVerifierProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  String get _orgId => ref.read(currentOrgProvider)!.id;

  Future<void> _webCheckout({String? plan, String? pack}) => _run(() async {
    unawaited(
      Analytics.capture(
        'purchase_started',
        properties: {'store': 'dodo', 'kind': pack != null ? 'credit_pack' : 'subscription', 'product_id': plan ?? pack},
      ),
    );
    final url = await ref.read(backendProvider).checkoutUrl(_orgId, planCode: plan, packCode: pack);
    await ref.read(openUrlProvider)(url);
  });

  Future<void> _storeBuy(StoreProduct p) => _run(() {
    unawaited(
      Analytics.capture(
        'purchase_started',
        properties: {'store': ref.read(storeProvider).source ?? 'store', 'kind': 'subscription', 'product_id': p.id},
      ),
    );
    return ref.read(storeProvider).buy(p, orgId: _orgId);
  });

  Future<void> _restore() => _run(() async {
    try {
      await ref.read(storeProvider).restore(orgId: _orgId);
    } catch (_) {
      Analytics.log('restore_purchases', {'outcome': 'failed', 'store': ref.read(storeProvider).source ?? 'store'});
      rethrow;
    }
    if (mounted) showSuccess(context, context.l10n.restoreStarted);
  });

  Future<void> _manage(BillingSummary b) => _run(() async {
    final source = b.source_.value;
    final url = switch (source) {
      'dodo' => await ref.read(backendProvider).billingPortalUrl(_orgId),
      'app_store' => 'https://apps.apple.com/account/subscriptions',
      _ => 'https://play.google.com/store/account/subscriptions?package=ai.casama.app',
    };
    await ref.read(openUrlProvider)(url);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(billingProvider);
    return SubPage(
      title: l10n.billing,
      actions: [
        HeaderIconButton(
          icon: LucideIcons.rotateCw,
          tooltip: l10n.refresh,
          onPressed: () {
            ref.invalidate(billingProvider);
            ref.invalidate(_usageProvider);
          },
        ),
      ],
      body: AsyncView(
        value: billing,
        onRetry: () => ref.invalidate(billingProvider),
        loading: const _BillingSkeleton(),
        data: (b) {
          if (b == null || !b.enabled) {
            return EmptyState(icon: LucideIcons.infinity, title: l10n.billingOffTitle, message: l10n.billingOffSelfHosted);
          }
          final org = ref.watch(currentOrgProvider);
          final isAdmin = org != null && org.role != OrgRole.member;
          final channels = purchaseChannels(platform: ref.watch(platformProvider), isWeb: kIsWeb, storefront: ref.watch(storefrontProvider).value);
          return AbsorbPointer(
            absorbing: _busy,
            child: PageColumn(
              children: [
                _CurrentPlan(summary: b, onManage: isAdmin && b.source_.value != 'default' ? () => _manage(b) : null).appCardEntrance(),
                if (isAdmin && b.planCode == 'free') const _UpgradeBanner().appCardEntrance(),
                if (isAdmin) ..._plans(context, b, channels),
                if (isAdmin && channels.contains(PurchaseChannel.web)) ..._packs(context),
                if (isAdmin && (channels.contains(PurchaseChannel.appStore) || channels.contains(PurchaseChannel.googlePlay)))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Center(
                      child: TextButton.icon(
                        key: const Key('restorePurchases'),
                        onPressed: _restore,
                        icon: const Icon(LucideIcons.rotateCcw, size: 18),
                        label: Text(l10n.restorePurchases),
                      ),
                    ),
                  ),
                const _UsageRow(),
                // Each charge with the server it came from, and the keys for your own server
                // reaching Casama Cloud, fold away (D-182).
                AdvancedSection(
                  id: 'billing',
                  summary: isAdmin ? l10n.billingAdvancedSummary : l10n.billingChargesSummary,
                  children: [const _BilledItems(), if (isAdmin) const _CloudConnectSection()],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _plans(BuildContext context, BillingSummary b, List<PurchaseChannel> channels) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final catalog = ref.watch(planCatalogProvider).value;
    final products = ref.watch(storeProductsProvider).value ?? const {};
    final source = ref.watch(storeProvider).source;
    if (catalog == null) return const [];
    return [
      SectionHeader(title: l10n.plans),
      for (final p in catalog.plans.where((p) => p.interval.value != 'none'))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: AppCard(
            key: Key('plan-${p.code}'),
            borderColor: p.code == b.planCode ? scheme.primary.withValues(alpha: 0.5) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(p.code == b.planCode ? LucideIcons.circleCheck : LucideIcons.gem, size: 20, color: scheme.primary),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(p.name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    if (p.code == b.planCode) StatusLabel(text: l10n.currentPlan, color: scheme.primary, pill: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_limitsText(context, p.limits), style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                if (p.code != b.planCode) ...[
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      if (source != null && products[p.storeProductIds[source]] != null && channels.any((c) => c != PurchaseChannel.web))
                        GlowButton.icon(
                          key: Key('buyStore-${p.code}'),
                          onPressed: () => _storeBuy(products[p.storeProductIds[source]]!),
                          icon: const Icon(LucideIcons.shoppingBag, size: 18),
                          label: Text(l10n.subscribeFor(products[p.storeProductIds[source]]!.price)),
                        ),
                      if (channels.contains(PurchaseChannel.web) && p.web)
                        OutlinedButton.icon(
                          key: Key('buyWeb-${p.code}'),
                          onPressed: () => _webCheckout(plan: p.code),
                          icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 18),
                          label: Text(l10n.subscribeOnWeb),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _packs(BuildContext context) {
    final l10n = context.l10n;
    final packs = ref.watch(planCatalogProvider).value?.packs.where((p) => p.web).toList() ?? const [];
    if (packs.isEmpty) return const [];
    return [
      SectionHeader(title: l10n.credits),
      GroupedCard(
        children: [
          for (final p in packs)
            GroupedTile(
              key: Key('pack-${p.code}'),
              icon: LucideIcons.creditCard,
              iconColor: context.appColors.positive,
              title: p.name,
              trailing: Icon(LucideIcons.squareArrowOutUpRight, size: 18, color: context.colorScheme.onSurfaceVariant),
              onTap: () => _webCheckout(pack: p.code),
            ),
        ],
      ),
    ];
  }
}

String _limitsText(BuildContext context, Map<String, num> limits) {
  final l10n = context.l10n;
  return [
    if (limits['max_bots'] != null) l10n.limitBots(limits['max_bots']!.toInt()),
    if (limits['computer_hours'] != null) l10n.limitComputerHours(limits['computer_hours']!.toInt()),
    if (limits['monthly_credits_usd'] != null) l10n.limitCredits(limits['monthly_credits_usd']!.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 0)),
  ].join(' · ');
}

/// On the free plan, the way to the paywall: the bots asking to come along.
class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Material(
        key: const Key('openPaywall'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, 0.6)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () => openPaywall(context, source: 'settings'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(left: 0, top: 10, child: MascotImage(Mascot.giggly, size: 40, animate: false)),
                        const Positioned(left: 50, top: 10, child: MascotImage(Mascot.lovey, size: 40, animate: false)),
                        const Positioned(left: 20, top: -2, child: MascotImage(Mascot.starry, size: 54)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.upgradeToPro, style: context.textTheme.titleMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w900)),
                        Text(l10n.upgradeToProBody, style: context.textTheme.bodySmall?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: scheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The billing page before it loads: the current plan card, two plan cards and the usage row.
class _BillingSkeleton extends StatelessWidget {
  const _BillingSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final muted = text.bodySmall?.copyWith(height: 1.4);
    Widget plan(double name, double limits) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: SkeletonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SkeletonBone(width: 20, height: 20, radius: 6),
                const SizedBox(width: AppSpace.xs),
                Expanded(child: SkeletonText(style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800), widthFactor: name)),
              ],
            ),
            const SizedBox(height: 6),
            SkeletonText(style: muted, widthFactor: limits),
            const SizedBox(height: AppSpace.sm),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SkeletonBone(width: 150, height: 44, radius: AppRadius.pill),
            ),
          ],
        ),
      ),
    );
    return SkeletonPage(
      children: [
        SkeletonCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBone(width: 48, height: 48, radius: 14),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkeletonText(style: text.labelMedium, widthFactor: 0.3),
                        SkeletonText(style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800), widthFactor: 0.45),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: context.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.row)),
                child: Row(
                  children: [
                    const SkeletonBone(width: 20, height: 20, radius: 6),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SkeletonText(style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), widthFactor: 0.4),
                          SkeletonText(style: muted, widthFactor: 0.75),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SkeletonSectionHeader(width: 60),
        plan(0.3, 0.7),
        plan(0.36, 0.8),
        const Padding(
          padding: EdgeInsets.only(top: AppSpace.lg),
          child: SkeletonGroupedCard(count: 1),
        ),
      ],
    );
  }
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.summary, this.onManage});
  final BillingSummary summary;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final b = summary;
    final until = b.validUntil;
    final via = switch (b.source_.value) {
      'dodo' => l10n.viaWeb,
      'app_store' => l10n.viaAppStore,
      'google_play' => l10n.viaGooglePlay,
      _ => null,
    };
    final muted = context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4);
    return AppCard(
      key: const Key('currentPlan'),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, Color.lerp(scheme.primary, scheme.tertiary, 0.5)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.gem, color: scheme.onPrimary, size: 26),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.yourPlan, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(b.planName, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    if (via != null) Text(via, style: muted),
                    if (until != null)
                      Text(
                        b.cancelAtPeriodEnd
                            ? l10n.planEndsOn(until.toLocal().formattedWeekdayDate(context))
                            : l10n.planRenewsOn(until.toLocal().formattedWeekdayDate(context)),
                        style: muted,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.row)),
            child: Row(
              children: [
                Icon(LucideIcons.wallet, size: 20, color: context.appColors.positive),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.creditsBalance(b.creditsUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2)),
                        key: const Key('creditsBalance'),
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                      ),
                      if (b.limits.isNotEmpty) Text(_limitsText(context, b.limits), style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onManage != null) ...[
            const SizedBox(height: AppSpace.md),
            OutlinedButton.icon(
              key: const Key('manageSubscription'),
              onPressed: onManage,
              icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
              label: Text(l10n.manageSubscription),
            ),
          ],
        ],
      ),
    );
  }
}

/// This month's billed charges one by one, with the server each came from (under Advanced).
class _BilledItems extends ConsumerWidget {
  const _BilledItems();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final usage = ref.watch(_usageProvider).value;
    if (usage == null) return const SizedBox.shrink();
    (String, IconData) describe(BillingUsageItem i) {
      final (what, icon) = switch (i.kind) {
        'computer_seconds' => (l10n.usageComputerHours((i.quantity / 3600).humanizedCount(context.l10n.localeName, decimalDigits: 2)), LucideIcons.monitor),
        'stream_seconds' => (l10n.usageLiveViewMinutes((i.quantity / 60).humanizedCount(context.l10n.localeName, decimalDigits: 0)), LucideIcons.monitorPlay),
        'tokens_in' || 'tokens_out' => (l10n.usageTokens(i.quantity.toInt()), LucideIcons.sparkles),
        _ => (i.kind, LucideIcons.receiptText),
      };
      return (i.instance.isUsable ? '$what · ${i.instance}' : what, icon);
    }

    return Column(
      key: const Key('billedItems'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.thisMonth, padding: const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.xs, AppSpace.xxs, AppSpace.xs)),
        if (usage.items.isEmpty)
          AppCard(child: FormNote(l10n.noBillableUsage, icon: LucideIcons.receiptText))
        else
          GroupedCard(
            children: [
              for (final i in usage.items)
                GroupedTile(
                  icon: describe(i).$2,
                  title: describe(i).$1,
                  trailing: Text(
                    i.costUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2),
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular, color: scheme.onSurface),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// One row to Settings → Usage, which has the full breakdown, with this month's billed total.
class _UsageRow extends ConsumerWidget {
  const _UsageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final usage = ref.watch(_usageProvider).value;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: GroupedCard(
        children: [
          GroupedTile(
            key: const Key('billingUsage'),
            icon: LucideIcons.chartColumn,
            title: l10n.usage,
            subtitle: usage == null ? l10n.billingUsageRow : l10n.billingUsageSoFar(usage.totalUsd.humanizedCurrency(context.l10n.localeName, 'USD', decimalDigits: 2)),
            showChevron: true,
            onTap: () => context.push('/settings/usage'),
          ),
        ],
      ),
    );
  }
}

class _CloudConnectSection extends ConsumerWidget {
  const _CloudConnectSection();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showTextPrompt(
      context,
      title: l10n.cloudConnectNewKey,
      subtitle: l10n.cloudConnectHelp,
      label: l10n.instanceName,
      hint: 'home-server',
      submitLabel: l10n.create,
      icon: LucideIcons.cloud,
      fieldIcon: LucideIcons.server,
      fieldKey: const Key('instanceName'),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    final created = await runGuarded(context, () => ref.read(backendProvider).createConnectKey(org.id, name));
    ref.invalidate(_connectKeysProvider);
    if (created == null || !context.mounted) return;
    await showAdaptiveSheet<void>(
      context: context,
      builder: (_) => _KeyCreatedSheet(secret: created.key),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keys = ref.watch(_connectKeysProvider).value ?? const <ConnectKey>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.cloudConnect,
          trailing: TextButton.icon(
            key: const Key('createConnectKey'),
            onPressed: () => _create(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.cloudConnectNewKey),
          ),
        ),
        FormNote(l10n.cloudConnectHelp),
        if (keys.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          GroupedCard(
            children: [
              for (final k in keys)
                GroupedTile(
                  icon: LucideIcons.server,
                  title: k.instanceName,
                  subtitle: k.keyHint,
                  trailing: IconButton(
                    tooltip: l10n.revoke,
                    icon: Icon(LucideIcons.trash2, color: context.colorScheme.onSurfaceVariant),
                    onPressed: () async {
                      final ok = await showConfirm(
                        context: context,
                        title: l10n.revokeKeyTitle(k.instanceName),
                        message: l10n.revokeKeyBody,
                        confirmLabel: l10n.revoke,
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      await runGuarded(context, () => ref.read(backendProvider).revokeConnectKey(ref.read(currentOrgProvider)!.id, k.id));
                      ref.invalidate(_connectKeysProvider);
                    },
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Shows a new connect key once, with a copy button.
class _KeyCreatedSheet extends StatelessWidget {
  const _KeyCreatedSheet({required this.secret});
  final String secret;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = 'CASAMA_CLOUD_KEY=$secret';
    return FormSheet(
      icon: LucideIcons.keyRound,
      iconColor: context.appColors.warning,
      title: l10n.cloudConnectKeyCreated,
      subtitle: l10n.cloudConnectKeyOnce,
      submitLabel: l10n.copy,
      submitIcon: LucideIcons.copy,
      cancelLabel: l10n.close,
      onSubmit: () {
        Clipboard.setData(ClipboardData(text: secret));
        showMessage(context, l10n.copied);
      },
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appColors.codeBackground,
            borderRadius: BorderRadius.circular(AppRadius.row),
            border: Border.all(color: context.appColors.hairline),
          ),
          child: SelectableText(line, key: const Key('connectKeyValue'), style: AppText.mono.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

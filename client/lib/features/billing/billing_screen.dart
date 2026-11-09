import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/billing.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

final _plansProvider = FutureProvider<PlanCatalog>((ref) => ref.watch(backendProvider).plans());
final _usageProvider = FutureProvider<BillingUsage?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? null : ref.watch(backendProvider).billingUsage(org.id);
});
final _connectKeysProvider = FutureProvider<List<ConnectKey>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? const [] : ref.watch(backendProvider).connectKeys(org.id);
});
final _storefrontProvider = FutureProvider<String?>((ref) => ref.watch(storeProvider).storefront());
final _storeProductsProvider = FutureProvider<Map<String, StoreProduct>>((ref) async {
  final store = ref.watch(storeProvider);
  final source = store.source;
  if (source == null) return const {};
  final catalog = await ref.watch(_plansProvider.future);
  final ids = {for (final p in catalog.plans) ?p.storeProductIds[source]};
  return {for (final p in await store.products(ids)) p.id: p};
});

/// Overridable in tests (which platform the paywall rules apply to).
final platformProvider = Provider<TargetPlatform>((ref) => defaultTargetPlatform);

/// Opens a URL outside the app (checkout, portal, store subscription settings). Overridable in tests.
final openUrlProvider = Provider<Future<void> Function(String url)>(
  (ref) => (url) async => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
);

/// Shown when the server answers 402 (plan limit or out of credits).
Future<void> showPaywall(BuildContext context, String message) async {
  final l10n = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.workspace_premium_outlined),
      title: Text(l10n.upgradeTitle),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.notNow)),
        FilledButton(key: const Key('paywallSeePlans'), onPressed: () => Navigator.pop(c, true), child: Text(l10n.seePlans)),
      ],
    ),
  );
  if (go == true && context.mounted) await context.push('/settings/billing');
}

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
        final url = await ref.read(backendProvider).checkoutUrl(_orgId, planCode: plan, packCode: pack);
        await ref.read(openUrlProvider)(url);
      });

  Future<void> _storeBuy(StoreProduct p) => _run(() => ref.read(storeProvider).buy(p, orgId: _orgId));

  Future<void> _restore() => _run(() async {
        await ref.read(storeProvider).restore(orgId: _orgId);
        if (mounted) showMessage(context, context.l10n.restoreStarted);
      });

  Future<void> _manage(BillingSummary b) => _run(() async {
        final source = b.source_.value;
        final url = switch (source) {
          'dodo' => await ref.read(backendProvider).billingPortalUrl(_orgId),
          'app_store' => 'https://apps.apple.com/account/subscriptions',
          _ => 'https://play.google.com/store/account/subscriptions?package=dev.kasama.app',
        };
        await ref.read(openUrlProvider)(url);
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(billingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billing), actions: [
        IconButton(
          tooltip: l10n.refresh,
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(billingProvider);
            ref.invalidate(_usageProvider);
          },
        ),
      ]),
      body: AsyncView(
        value: billing,
        onRetry: () => ref.invalidate(billingProvider),
        data: (b) {
          if (b == null || !b.enabled) {
            return EmptyState(icon: Icons.all_inclusive, message: l10n.billingOffSelfHosted);
          }
          final org = ref.watch(currentOrgProvider);
          final isAdmin = org != null && org.role != OrgRole.member;
          final channels = purchaseChannels(
            platform: ref.watch(platformProvider),
            isWeb: kIsWeb,
            storefront: ref.watch(_storefrontProvider).value,
          );
          return AbsorbPointer(
            absorbing: _busy,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              _CurrentPlan(summary: b, onManage: isAdmin && b.source_.value != 'default' ? () => _manage(b) : null),
              const SizedBox(height: 16),
              if (isAdmin) ..._plans(context, b, channels),
              if (isAdmin && channels.contains(PurchaseChannel.web)) ..._packs(context),
              if (isAdmin && (channels.contains(PurchaseChannel.appStore) || channels.contains(PurchaseChannel.googlePlay)))
                Center(
                  child: TextButton.icon(
                    key: const Key('restorePurchases'),
                    onPressed: _restore,
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.restorePurchases),
                  ),
                ),
              const SizedBox(height: 8),
              const _UsageSection(),
              if (isAdmin) const _CloudConnectSection(),
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _plans(BuildContext context, BillingSummary b, List<PurchaseChannel> channels) {
    final l10n = context.l10n;
    final catalog = ref.watch(_plansProvider).value;
    final products = ref.watch(_storeProductsProvider).value ?? const {};
    final source = ref.watch(storeProvider).source;
    if (catalog == null) return const [];
    return [
      Text(l10n.plans, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final p in catalog.plans.where((p) => p.interval.value != 'none'))
        Card(
          key: Key('plan-${p.code}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleSmall)),
                if (p.code == b.planCode) Chip(label: Text(l10n.currentPlan)),
              ]),
              const SizedBox(height: 4),
              Text(_limitsText(context, p.limits), style: Theme.of(context).textTheme.bodySmall),
              if (p.code != b.planCode) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (source != null && products[p.storeProductIds[source]] != null && channels.any((c) => c != PurchaseChannel.web))
                    FilledButton(
                      key: Key('buyStore-${p.code}'),
                      onPressed: () => _storeBuy(products[p.storeProductIds[source]]!),
                      child: Text(l10n.subscribeFor(products[p.storeProductIds[source]]!.price)),
                    ),
                  if (channels.contains(PurchaseChannel.web) && p.web)
                    OutlinedButton(
                      key: Key('buyWeb-${p.code}'),
                      onPressed: () => _webCheckout(plan: p.code),
                      child: Text(l10n.subscribeOnWeb),
                    ),
                ]),
              ],
            ]),
          ),
        ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _packs(BuildContext context) {
    final l10n = context.l10n;
    final packs = ref.watch(_plansProvider).value?.packs.where((p) => p.web).toList() ?? const [];
    if (packs.isEmpty) return const [];
    return [
      Text(l10n.credits, style: Theme.of(context).textTheme.titleMedium),
      for (final p in packs)
        ListTile(
          key: Key('pack-${p.code}'),
          leading: const Icon(Icons.add_card),
          title: Text(p.name),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _webCheckout(pack: p.code),
        ),
      const SizedBox(height: 8),
    ];
  }
}

String _limitsText(BuildContext context, Map<String, num> limits) {
  final l10n = context.l10n;
  return [
    if (limits['max_bots'] != null) l10n.limitBots(limits['max_bots']!.toInt()),
    if (limits['computer_hours'] != null) l10n.limitComputerHours(limits['computer_hours']!.toInt()),
    if (limits['monthly_credits_usd'] != null) l10n.limitCredits(limits['monthly_credits_usd']!.toStringAsFixed(0)),
  ].join(' · ');
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.summary, this.onManage});
  final BillingSummary summary;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = summary;
    final until = b.validUntil;
    final via = switch (b.source_.value) {
      'dodo' => l10n.viaWeb,
      'app_store' => l10n.viaAppStore,
      'google_play' => l10n.viaGooglePlay,
      _ => null,
    };
    return Card(
      key: const Key('currentPlan'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.yourPlan, style: Theme.of(context).textTheme.labelMedium),
          Text(b.planName, style: Theme.of(context).textTheme.headlineSmall),
          if (via != null) Text(via),
          if (until != null)
            Text(b.cancelAtPeriodEnd
                ? l10n.planEndsOn(MaterialLocalizations.of(context).formatMediumDate(until.toLocal()))
                : l10n.planRenewsOn(MaterialLocalizations.of(context).formatMediumDate(until.toLocal()))),
          const SizedBox(height: 8),
          Text(l10n.creditsBalance(b.creditsUsd.toStringAsFixed(2)), key: const Key('creditsBalance')),
          if (b.limits.isNotEmpty) Text(_limitsText(context, b.limits), style: Theme.of(context).textTheme.bodySmall),
          if (onManage != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(key: const Key('manageSubscription'), onPressed: onManage, child: Text(l10n.manageSubscription)),
          ],
        ]),
      ),
    );
  }
}

class _UsageSection extends ConsumerWidget {
  const _UsageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final usage = ref.watch(_usageProvider).value;
    if (usage == null) return const SizedBox.shrink();
    String label(BillingUsageItem i) {
      final what = switch (i.kind) {
        'computer_seconds' => l10n.usageComputerHours((i.quantity / 3600).toStringAsFixed(2)),
        'stream_seconds' => l10n.usageLiveViewMinutes((i.quantity / 60).toStringAsFixed(0)),
        'tokens_in' || 'tokens_out' => l10n.usageTokens(i.quantity.toInt()),
        _ => i.kind,
      };
      return i.instance == null ? what : '$what · ${i.instance}';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.thisMonth, style: Theme.of(context).textTheme.titleMedium),
      if (usage.items.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(l10n.noBillableUsage)),
      for (final i in usage.items)
        ListTile(dense: true, title: Text(label(i)), trailing: Text('\$${i.costUsd.toStringAsFixed(2)}')),
      const SizedBox(height: 8),
    ]);
  }
}

class _CloudConnectSection extends ConsumerWidget {
  const _CloudConnectSection();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showDialog<String>(context: context, builder: (_) => const _InstanceNameDialog());
    if (name == null || name.isEmpty || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    final created = await runGuarded(context, () => ref.read(backendProvider).createConnectKey(org.id, name));
    ref.invalidate(_connectKeysProvider);
    if (created == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.cloudConnectKeyCreated),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.cloudConnectKeyOnce),
          const SizedBox(height: 8),
          SelectableText('KASAMA_CLOUD_KEY=${created.key}', key: const Key('connectKeyValue')),
        ]),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: created.key)),
            child: Text(l10n.copy),
          ),
          FilledButton(onPressed: () => Navigator.pop(c), child: Text(l10n.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keys = ref.watch(_connectKeysProvider).value ?? const <ConnectKey>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.cloudConnect, style: Theme.of(context).textTheme.titleMedium),
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(l10n.cloudConnectHelp)),
      for (final k in keys)
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(k.instanceName),
          subtitle: Text(k.keyHint),
          trailing: IconButton(
            tooltip: l10n.revoke,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await runGuarded(context, () => ref.read(backendProvider).revokeConnectKey(ref.read(currentOrgProvider)!.id, k.id));
              ref.invalidate(_connectKeysProvider);
            },
          ),
        ),
      TextButton.icon(
        key: const Key('createConnectKey'),
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.cloudConnectNewKey),
      ),
    ]);
  }
}

class _InstanceNameDialog extends StatefulWidget {
  const _InstanceNameDialog();
  @override
  State<_InstanceNameDialog> createState() => _InstanceNameDialogState();
}

class _InstanceNameDialogState extends State<_InstanceNameDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.cloudConnectNewKey),
      content: TextField(
        key: const Key('instanceName'),
        controller: _c,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.instanceName),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: Text(l10n.create)),
      ],
    );
  }
}

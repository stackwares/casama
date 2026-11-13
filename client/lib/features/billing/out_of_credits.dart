import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics.dart';
import '../../core/billing.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/mascot.dart';
import 'billing_screen.dart';
import 'paywall.dart';
import 'purchase_terms.dart';

/// When a workspace runs out of credits (D-248): a paying workspace is offered credit packs first,
/// since its plan is fine and only this month ran dry; a free one goes to the paywall, with the
/// reason on top. Members who can't buy see who can.
Future<void> openOutOfCredits(BuildContext context, {String source = 'credits_depleted'}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  // The workspace first: billing is per workspace, and right after launch it may still be loading.
  // Listened to while waiting: a provider nobody listens to may be paused and never finish.
  final orgs = container.listen(organizationsProvider.future, (_, _) {});
  final summary = container.listen(billingProvider.future, (_, _) {});
  BillingSummary? billing;
  try {
    await orgs.read().timeout(const Duration(seconds: 3)).catchError((_) => const <OrganizationWithRole>[]);
    billing = await container.read(billingProvider.future).timeout(const Duration(seconds: 3)).catchError((_) => null);
  } finally {
    orgs.close();
    summary.close();
  }
  if (!context.mounted) return;
  if (billing == null || !billing.enabled || billing.planCode == 'free') {
    await openPaywall(context, reason: context.l10n.outOfCreditsTitle, source: source);
    return;
  }
  unawaited(Analytics.capture('paywall_view', properties: {'source': source, 'paywall_kind': 'credits'}));
  await showAdaptiveSheet<void>(context: context, builder: (_) => OutOfCreditsSheet(source: source));
}

class OutOfCreditsSheet extends ConsumerStatefulWidget {
  const OutOfCreditsSheet({super.key, this.source = 'credits_depleted'});
  final String source;

  @override
  ConsumerState<OutOfCreditsSheet> createState() => _OutOfCreditsSheetState();
}

class _OutOfCreditsSheetState extends ConsumerState<OutOfCreditsSheet> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Store purchases are verified by the server as they arrive.
    ref.read(purchaseVerifierProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  void _buyStore(StoreProduct p, String orgId) => _run(() async {
    unawaited(
      Analytics.capture(
        'purchase_started',
        properties: {'store': ref.read(storeProvider).source ?? 'store', 'kind': 'credit_pack', 'product_id': p.id, 'source': widget.source},
      ),
    );
    // Stays open: it closes once the server has added the credits, and says so if the store
    // didn't go through.
    await ref.read(storeProvider).buy(p, orgId: orgId, consumable: true);
  });

  void _buyWeb(String code, String orgId) => _run(() async {
    unawaited(
      Analytics.capture('purchase_started', properties: {'store': 'dodo', 'kind': 'credit_pack', 'product_id': code, 'source': widget.source}),
    );
    final url = await ref.read(backendProvider).checkoutUrl(orgId, packCode: code);
    if (url != null) await ref.read(openUrlProvider)(url);
    if (mounted) Navigator.of(context).pop();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final org = ref.watch(currentOrgProvider);
    final isAdmin = org != null && org.role != OrgRole.member;
    final store = ref.watch(storeProvider);
    final source = store.source;
    final products = ref.watch(storeProductsProvider).value ?? const {};
    final packs = ref.watch(planCatalogProvider).value?.packs ?? const <CreditPack>[];
    final channels = purchaseChannels(platform: ref.watch(platformProvider), isWeb: kIsWeb, storefront: ref.watch(storefrontProvider).value);
    final storeChannel = source != null && channels.any((c) => c != PurchaseChannel.web);
    // Credits arrived (a pack verified by the server): done.
    ref.listen(billingProvider, (prev, next) {
      final before = prev?.value?.creditsUsd ?? 0;
      final now = next.value?.creditsUsd ?? 0;
      if (now > before && mounted) {
        showSuccess(context, l10n.creditsAdded);
        Navigator.of(context).pop();
      }
    });
    // Say what happened to a store purchase or restore that didn't simply go through (D-248).
    ref.listen(purchaseOutcomeProvider, (_, next) {
      final o = next.value;
      final text = o == null ? null : purchaseOutcomeText(l10n, o);
      if (text == null || !mounted) return;
      showToast(context, text, kind: o == PurchaseOutcome.restored ? ToastKind.success : ToastKind.info);
    });

    final tiles = <Widget>[
      for (final p in packs)
        if (storeChannel && products[p.storeProductIds?[source]] != null)
          _PackTile(
            key: Key('creditsPackStore-${p.code}'),
            name: p.name,
            price: products[p.storeProductIds![source]]!.price,
            onTap: isAdmin && !_busy ? () => _buyStore(products[p.storeProductIds![source]]!, org.id) : null,
          )
        else if (channels.contains(PurchaseChannel.web) && p.web)
          _PackTile(
            key: Key('creditsPack-${p.code}'),
            name: p.name,
            price: p.priceLabel.isUsable ? p.priceLabel! : null,
            external: true,
            onTap: isAdmin && !_busy ? () => _buyWeb(p.code, org.id) : null,
          ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
      child: Column(
        key: const Key('outOfCreditsSheet'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: MascotImage(Mascot.sleepy, size: 88)),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.outOfCreditsTitle,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.outOfCreditsPaidBody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.md),
          if (!isAdmin)
            FormNote(l10n.paywallAskAdmin, icon: LucideIcons.shieldCheck)
          else if (tiles.isNotEmpty) ...[
            ...tiles,
            const SizedBox(height: AppSpace.sm),
          ],
          OutlinedButton.icon(
            key: const Key('outOfCreditsPlans'),
            onPressed: _busy
                ? null
                : () {
                    final nav = Navigator.of(context);
                    final root = nav.context;
                    nav.pop();
                    openPaywall(root, reason: l10n.outOfCreditsTitle, source: widget.source);
                  },
            icon: const Icon(LucideIcons.gem, size: 18),
            label: Text(l10n.seePlansButton),
          ),
          const SizedBox(height: AppSpace.xs),
          const PurchaseTerms(price: null, yearly: false, store: null),
        ],
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({super.key, required this.name, required this.price, required this.onTap, this.external = false});
  final String name;
  final String? price;
  final VoidCallback? onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 14),
        child: Row(
          children: [
            Icon(LucideIcons.creditCard, color: context.appColors.positive, size: 22),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
            if (price != null)
              Text(price!, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
            if (external) ...[
              const SizedBox(width: AppSpace.xs),
              Icon(LucideIcons.squareArrowOutUpRight, size: 16, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../billing/billing_screen.dart' show openUrlProvider;
import 'connect_domain_screen.dart' show showDomainSitePicker;
import 'domain_buying.dart';
import 'domains_providers.dart';
import 'sites_providers.dart';
import '../../core/remote_content.dart';

/// Find a Domain (`/settings/domains/find?q=`, SITES-AND-DOMAINS-PLAN §7.7, §7.16): search names
/// with their price and renewal price, then **Buy**: the registrant form the first time, the
/// terms, **Renew Automatically** and the site to show, then checkout in the browser (or a charge
/// on the saved payment method) and the order's progress. Bots link here with the name filled in.
class FindDomainScreen extends ConsumerStatefulWidget {
  const FindDomainScreen({super.key, this.query});

  /// The name to start with (a bot's link passes it).
  final String? query;

  /// How long typing pauses before a search.
  static const debounce = Duration(milliseconds: 400);

  @override
  ConsumerState<FindDomainScreen> createState() => _FindDomainScreenState();
}

class _FindDomainScreenState extends ConsumerState<FindDomainScreen> {
  late final _q = TextEditingController(text: widget.query?.trim() ?? '');
  Timer? _debounce;
  AsyncValue<DomainSearchList>? _results;
  int _seq = 0;
  String? _buying;

  /// A name passed in is searched once the workspace is known.
  late bool _searchFirst = _q.text.isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _typed(String _) {
    _debounce?.cancel();
    _debounce = Timer(FindDomainScreen.debounce, _search);
  }

  Future<void> _search() async {
    final orgId = ref.read(currentOrgIdProvider);
    final q = _q.text.trim();
    if (orgId == null || !mounted) return;
    if (q.isEmpty) {
      setState(() => _results = null);
      return;
    }
    final seq = ++_seq;
    setState(() => _results = const AsyncLoading());
    try {
      final r = await ref.read(backendProvider).searchDomains(orgId, q);
      if (mounted && seq == _seq) setState(() => _results = AsyncData(r));
    } catch (e, st) {
      if (mounted && seq == _seq) setState(() => _results = AsyncError(e, st));
    }
  }

  Future<void> _buy(DomainSearchResult item) async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null || _buying != null) return;
    setState(() => _buying = item.name);
    try {
      await _buyFlow(orgId, item);
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  Future<bool> _ensureContact(String orgId) async {
    final state = await runGuarded(
      context,
      () => ref.read(backendProvider).domainContact(orgId),
    );
    if (state == null || !mounted) return false;
    if (state.contact != null) return true;
    final saved = await showDomainContactSheet(
      context,
      orgId: orgId,
      state: state,
    );
    return saved != null;
  }

  Future<void> _buyFlow(String orgId, DomainSearchResult item) async {
    if (!await _ensureContact(orgId) || !mounted) return;
    final sites =
        ref.read(orgSitesProvider(orgId)).value ??
        await ref
            .read(backendProvider)
            .sites(orgId)
            .catchError((_) => const <Site>[]);
    if (!mounted) return;
    final choice = await showAdaptiveSheet<_BuyChoice>(
      context: context,
      builder: (_) => _BuySheet(item: item, sites: sites),
    );
    if (choice == null || !mounted) return;
    Future<DomainCheckoutResult> checkout() => ref
        .read(backendProvider)
        .domainCheckout(
          orgId,
          item.name,
          pageId: choice.pageId,
          autoRenew: choice.autoRenew,
        );
    final result = await runGuarded(context, () async {
      try {
        return await checkout();
      } catch (e) {
        // The contact went missing since: ask for it, then try once more.
        if (problemCode(e) != 'contact_required' || !mounted) rethrow;
        final state = await ref.read(backendProvider).domainContact(orgId);
        if (!mounted) rethrow;
        final saved = await showDomainContactSheet(
          context,
          orgId: orgId,
          state: state,
        );
        if (saved == null) rethrow;
        return checkout();
      }
    });
    if (result == null || !mounted) return;
    ref.invalidate(orgDomainsProvider(orgId));
    final url = result.checkoutUrl;
    if (url != null) {
      await ref.read(openUrlProvider)(url);
    }
    if (!mounted) return;
    unawaited(
      context.pushOnce(
        '/settings/domains/orders/${result.order.id}'
        '${url != null ? '?paying=1' : ''}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canBuy = ref.watch(canBuyDomainsProvider);
    if (ref.watch(currentOrgIdProvider) != null && _searchFirst && canBuy) {
      _searchFirst = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
    if (!canBuy) {
      return SubPage(
        title: l10n.domainsFind,
        children: [
          EmptyState(
            key: const Key('findDomainNotOffered'),
            icon: LucideIcons.globe,
            message: l10n.domainFindNotOffered,
          ),
        ],
      );
    }
    final results = _results;
    return SubPage(
      title: l10n.domainsFind,
      children: [
        TextField(
          key: const Key('findDomainField'),
          controller: _q,
          autofocus: widget.query == null,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: l10n.domainFindField,
            hintText: l10n.domainFindHint,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
          ),
          onChanged: _typed,
          onSubmitted: (_) {
            _debounce?.cancel();
            _search();
          },
        ),
        const SizedBox(height: AppSpace.xs),
        FormNote(l10n.domainFindHelp),
        const SizedBox(height: AppSpace.md),
        if (results != null)
          results.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpace.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              errorText(context, e),
              key: const Key('findDomainError'),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
            data: (r) => r.items.isEmpty
                ? Text(
                    l10n.domainFindNone,
                    key: const Key('findDomainNone'),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  )
                : GroupedCard(
                    children: [
                      for (final item in r.items)
                        _ResultRow(
                          item: item,
                          onBuy: _buying == null ? () => _buy(item) : null,
                        ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item, this.onBuy});
  final DomainSearchResult item;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = item.priceUsd;
    final renew = item.renewPriceUsd;
    final available = item.available && price != null;
    final subtitle = available
        ? [
            l10n.domainPricePerYear(domainUsd(context, price)),
            if (renew != null) l10n.domainRenewsAt(domainUsd(context, renew)),
          ].join(' · ')
        : domainReasonLabel(l10n, item.reason);
    final tile = GroupedTile(
      key: Key('domainResult-${item.name}'),
      icon: available ? LucideIcons.globe : LucideIcons.circleSlash,
      title: item.name,
      subtitle: subtitle,
      showChevron: false,
      trailing: available
          ? FilledButton(
              key: Key('domainBuy-${item.name}'),
              onPressed: onBuy,
              child: Text(l10n.domainBuy),
            )
          : null,
    );
    return available ? tile : Opacity(opacity: 0.5, child: tile);
  }
}

/// What the buyer chose in the buy sheet.
typedef _BuyChoice = ({bool autoRenew, String? pageId});

class _BuySheet extends ConsumerStatefulWidget {
  const _BuySheet({required this.item, required this.sites});
  final DomainSearchResult item;
  final List<Site> sites;

  @override
  ConsumerState<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends ConsumerState<_BuySheet> {
  bool _terms = false;
  bool _autoRenew = true;
  String? _pageId;

  Future<void> _pickSite() async {
    final picked = await showDomainSitePicker(
      context,
      sites: widget.sites,
      current: _pageId,
    );
    if (picked != null && mounted) setState(() => _pageId = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final price = item.priceUsd ?? 0;
    final renew = item.renewPriceUsd ?? price;
    var siteTitle = l10n.domainSiteNone;
    for (final s in widget.sites) {
      if (s.pageId == _pageId) siteTitle = s.title;
    }
    return FormSheet(
      icon: LucideIcons.shoppingCart,
      title: l10n.domainBuyTitle(item.name),
      subtitle: l10n.domainBuyPrice(
        domainUsd(context, price),
        domainUsd(context, renew),
      ),
      submitLabel: l10n.domainBuy,
      submitKey: const Key('domainBuySubmit'),
      onSubmit: _terms
          ? () =>
                Navigator.of(context)
                    .pop<_BuyChoice>((autoRenew: _autoRenew, pageId: _pageId))
          : null,
      children: [
        FormNote(l10n.domainBuyFinal),
        CheckboxListTile(
          key: const Key('domainBuyTerms'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          title: Text(l10n.domainBuyTerms),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('domainBuyReadTerms'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => ref.read(openUrlProvider)(remoteLink('domain_terms', domainTermsUrl)),
              child: Text(l10n.domainBuyReadTerms),
            ),
          ),
        ),
        SwitchListTile(
          key: const Key('domainBuyAutoRenew'),
          contentPadding: EdgeInsets.zero,
          value: _autoRenew,
          onChanged: (v) => setState(() => _autoRenew = v),
          title: Text(l10n.domainRenewAuto),
          subtitle: Text(l10n.domainRenewAutoHelp),
        ),
        if (widget.sites.isNotEmpty)
          ListTile(
            key: const Key('domainBuySite'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.layoutTemplate),
            title: Text(l10n.domainBuySite),
            subtitle: Text(siteTitle),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: _pickSite,
          ),
      ],
    );
  }
}

/// A domain order's progress (`/settings/domains/orders/:id`): it looks every few seconds until
/// the order ends, then opens the new domain's screen, or says it was refunded or failed.
class DomainOrderScreen extends ConsumerStatefulWidget {
  const DomainOrderScreen({
    super.key,
    required this.orderId,
    this.paying = false,
  });
  final String orderId;

  /// The checkout opened in the browser.
  final bool paying;

  /// How often the open screen looks again.
  static const pollEvery = Duration(seconds: 3);

  @override
  ConsumerState<DomainOrderScreen> createState() => _DomainOrderScreenState();
}

const _orderEnded = {'done', 'abandoned', 'refunded', 'needs_attention'};

class _DomainOrderScreenState extends ConsumerState<DomainOrderScreen> {
  AsyncValue<DomainOrder> _order = const AsyncLoading();
  Timer? _poll;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(DomainOrderScreen.pollEvery, (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await ref.read(backendProvider).domainOrder(widget.orderId);
      if (!mounted) return;
      setState(() => _order = AsyncData(o));
      if (_orderEnded.contains(o.status)) {
        _poll?.cancel();
        final orgId = ref.read(currentOrgIdProvider);
        if (orgId != null) ref.invalidate(orgDomainsProvider(orgId));
        final domainId = o.domainId;
        if (o.status == 'done' && domainId != null && !_left) {
          _left = true;
          context.pushReplacement('/settings/domains/$domainId');
        }
      }
    } catch (e, st) {
      // A failed look keeps what's on screen; the next one may work.
      if (mounted && !_order.hasValue) {
        setState(() => _order = AsyncError(e, st));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(currentOrgIdProvider);
    return SubPage(
      title: l10n.domainOrderTitle,
      body: AsyncView(
        value: _order,
        onRetry: _load,
        data: (o) => PageColumn(children: [_status(context, o)]),
      ),
    );
  }

  Widget _status(BuildContext context, DomainOrder o) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final (
      IconData? icon,
      Color? tone,
      String text,
      bool working,
    ) = switch (o.status) {
      'quote' ||
      'checkout' => (null, null, l10n.domainOrderWaitingPayment, true),
      'paid' ||
      'registering' => (null, null, l10n.domainOrderRegistering(o.name), true),
      'registered' => (null, null, l10n.domainOrderSettingUp(o.name), true),
      'refunding' => (null, null, l10n.domainOrderRefunding(o.name), true),
      'refunded' => (
        LucideIcons.undo2,
        colors.warning,
        l10n.domainOrderRefunded(o.name),
        false,
      ),
      'abandoned' => (
        LucideIcons.circleSlash,
        colors.warning,
        l10n.domainOrderAbandoned,
        false,
      ),
      'done' => (
        LucideIcons.circleCheck,
        colors.positive,
        l10n.domainOrderDone(o.name),
        false,
      ),
      _ => (
        LucideIcons.triangleAlert,
        colors.negative,
        l10n.domainOrderNeedsAttention,
        false,
      ),
    };
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    return AppCard(
      key: Key('domainOrder-${o.status}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (working)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Icon(icon, color: tone),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  text,
                  key: const Key('domainOrderText'),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (o.status == 'checkout' && widget.paying) ...[
            const SizedBox(height: AppSpace.xs),
            Text(l10n.domainBuyPayInBrowser, style: muted),
          ],
          if (o.failure != null && !working) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              o.failure!,
              key: const Key('domainOrderFailure'),
              style: muted,
            ),
          ],
          if (working) ...[
            const SizedBox(height: AppSpace.xs),
            Text(l10n.domainOrderLeave, style: muted),
          ] else if (o.status != 'done') ...[
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              key: const Key('domainOrderBack'),
              onPressed: () => context.go('/settings/domains'),
              child: Text(l10n.domainOrderBack),
            ),
          ],
        ],
      ),
    );
  }
}

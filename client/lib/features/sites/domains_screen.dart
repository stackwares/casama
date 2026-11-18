import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import 'domain_buying.dart';
import 'domains_providers.dart';

/// Settings → Domains (SITES-AND-DOMAINS-PLAN §7.16): the workspace's domains with the site each
/// shows and a state chip, **Find a Domain** where buying is offered (or a line saying a domain
/// can be bought on the web) and **Connect a Domain You Own**.
class DomainsScreen extends ConsumerWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orgId = ref.watch(currentOrgIdProvider);
    final canBuy = ref.watch(canBuyDomainsProvider);
    void connect() => unawaited(context.pushOnce('/settings/domains/connect'));
    void find() => unawaited(context.pushOnce('/settings/domains/find'));
    final connectButton = canBuy
        ? OutlinedButton.icon(
            key: const Key('domainsConnect'),
            onPressed: connect,
            icon: const Icon(LucideIcons.link, size: 18),
            label: Text(l10n.domainsConnectOwn),
          )
        : GlowButton.icon(
            key: const Key('domainsConnect'),
            onPressed: connect,
            icon: const Icon(LucideIcons.link, size: 18),
            label: Text(l10n.domainsConnectOwn),
          );
    final buttons = Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        if (canBuy)
          GlowButton.icon(
            key: const Key('domainsFind'),
            onPressed: find,
            icon: const Icon(LucideIcons.search, size: 18),
            label: Text(l10n.domainsFind),
          ),
        connectButton,
      ],
    );
    if (orgId == null) {
      return SubPage(title: l10n.settingsDomains, children: const []);
    }
    return SubPage(
      title: l10n.settingsDomains,
      actions: [
        if (canBuy)
          HeaderIconButton(
            icon: LucideIcons.search,
            tooltip: l10n.domainsFind,
            onPressed: find,
          ),
        HeaderIconButton(
          icon: LucideIcons.plus,
          tooltip: l10n.domainsConnectOwn,
          onPressed: connect,
        ),
      ],
      body: AsyncView(
        value: ref.watch(orgDomainsProvider(orgId)),
        onRetry: () => ref.invalidate(orgDomainsProvider(orgId)),
        data: (items) => items.isEmpty
            ? EmptyState(
                key: const Key('domainsEmpty'),
                icon: LucideIcons.globe,
                message: canBuy ? l10n.domainsEmptyBuy : l10n.domainsEmpty,
                action: buttons,
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(orgDomainsProvider(orgId).future),
                child: PageColumn(
                  children: [
                    GroupedCard(
                      children: [for (final d in items) _DomainRow(domain: d)],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Align(alignment: Alignment.centerLeft, child: buttons),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.domain});
  final Domain domain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GroupedTile(
      key: Key('domain-${domain.id}'),
      icon: LucideIcons.globe,
      iconColor: domain.live ? context.appColors.positive : null,
      title: domain.name,
      subtitle: domain.pageTitle ?? l10n.domainNoSite,
      onTap: () =>
          unawaited(context.pushOnce('/settings/domains/${domain.id}')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DomainStateChip.forState(
            context,
            domain.state,
            key: Key('domainState-${domain.id}'),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

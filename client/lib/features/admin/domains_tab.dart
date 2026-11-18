import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';

final adminDomainsProvider = FutureProvider.autoDispose<AdminDomains>(
  (r) => r.watch(backendProvider).adminDomains(),
);

/// Admin console > Domains (SITES-AND-DOMAINS-PLAN §7.16): counts, the registrar balance, orders
/// that need a person (**Approve** a new workspace's first purchase, **Retry** a failed refund or
/// registration) and every domain with **Suspend** / **Unsuspend**.
class AdminDomainsTab extends ConsumerWidget {
  const AdminDomainsTab({super.key});

  Future<void> _order(
    BuildContext context,
    WidgetRef ref,
    AdminDomainOrder o, {
    required bool approve,
  }) async {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final done = await runGuarded(
      context,
      () => approve
          ? backend.adminApproveDomainOrder(o.id)
          : backend.adminRetryDomainOrder(o.id),
    );
    if (done == null || !context.mounted) return;
    showSuccess(
      context,
      approve ? l10n.adminDomainsApproved : l10n.adminDomainsRetried,
    );
    ref.invalidate(adminDomainsProvider);
  }

  Future<void> _suspend(
    BuildContext context,
    WidgetRef ref,
    AdminDomain d,
  ) async {
    final l10n = context.l10n;
    final suspend = !d.suspended;
    final ok = await showConfirm(
      context: context,
      title: suspend
          ? l10n.adminDomainsSuspendTitle(d.name)
          : l10n.adminDomainsUnsuspendTitle(d.name),
      message: suspend
          ? l10n.adminDomainsSuspendBody
          : l10n.adminDomainsUnsuspendBody,
      confirmLabel: suspend
          ? l10n.adminDomainsSuspend
          : l10n.adminDomainsUnsuspend,
      destructive: suspend,
      confirmKey: const Key('confirmDomainSuspend'),
    );
    if (!ok || !context.mounted) return;
    final backend = ref.read(backendProvider);
    final done = await runGuarded(context, () async {
      suspend
          ? await backend.adminSuspendDomain(d.id)
          : await backend.adminUnsuspendDomain(d.id);
      return true;
    });
    if (done == true) ref.invalidate(adminDomainsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncView<AdminDomains>(
      value: ref.watch(adminDomainsProvider),
      onRetry: () => ref.invalidate(adminDomainsProvider),
      data: (a) {
        final muted = context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        );
        String usd(num v) => formatUsd(v, l10n.localeName);
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminDomainsProvider.future),
          child: PageColumn(
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _Count(
                    key: const Key('adminDomainsRegistered'),
                    label: l10n.adminDomainsRegistered,
                    value: '${a.counts.registered}',
                  ),
                  _Count(
                    label: l10n.adminDomainsConnected,
                    value: '${a.counts.connected}',
                  ),
                  _Count(
                    label: l10n.adminDomainsLiveHosts,
                    value: '${a.counts.liveHosts}',
                  ),
                  _Count(
                    label: l10n.adminDomainsSuspended,
                    value: '${a.counts.suspended}',
                  ),
                  _Count(
                    key: const Key('adminDomainsBalance'),
                    label: l10n.adminDomainsBalance,
                    value: a.balanceUsd == null
                        ? l10n.adminDomainsBalanceUnknown
                        : usd(a.balanceUsd!),
                  ),
                ],
              ),
              SectionHeader(title: l10n.adminDomainsOrders),
              if (a.orders.isEmpty)
                Text(l10n.adminDomainsNoOrders, style: muted)
              else
                GroupedCard(
                  children: [
                    for (final o in a.orders)
                      GroupedTile(
                        key: Key('adminDomainOrder-${o.id}'),
                        icon: o.needsApproval
                            ? LucideIcons.userCheck
                            : LucideIcons.triangleAlert,
                        iconColor: o.needsApproval
                            ? null
                            : context.appColors.negative,
                        title: '${o.name} · ${usd(o.priceUsd)}',
                        subtitle: [
                          o.orgName ?? l10n.adminDomainsNoWorkspace,
                          o.status,
                          if (o.attempts > 0)
                            l10n.adminDomainsAttempts(o.attempts),
                          ?o.failure,
                        ].join(' · '),
                        showChevron: false,
                        trailing: o.needsApproval
                            ? FilledButton(
                                key: Key('adminDomainApprove-${o.id}'),
                                onPressed: () =>
                                    _order(context, ref, o, approve: true),
                                child: Text(l10n.adminDomainsApprove),
                              )
                            : OutlinedButton(
                                key: Key('adminDomainRetry-${o.id}'),
                                onPressed: () =>
                                    _order(context, ref, o, approve: false),
                                child: Text(l10n.adminDomainsRetry),
                              ),
                      ),
                  ],
                ),
              SectionHeader(title: l10n.adminDomainsList),
              if (a.domains.isEmpty)
                Text(l10n.adminDomainsNone, style: muted)
              else
                GroupedCard(
                  children: [
                    for (final d in a.domains)
                      GroupedTile(
                        key: Key('adminDomain-${d.id}'),
                        icon: d.suspended ? LucideIcons.ban : LucideIcons.globe,
                        iconColor: d.suspended
                            ? context.appColors.negative
                            : null,
                        title: d.name,
                        subtitle: [
                          d.orgName ?? l10n.adminDomainsNoWorkspace,
                          d.kind == 'registered'
                              ? l10n.adminDomainsRegistered
                              : l10n.adminDomainsConnected,
                          ?d.registrarStatus,
                          if (d.expiresAt != null)
                            l10n.domainExpiresOn(
                              d.expiresAt!.toLocal().formattedDate(context),
                            ),
                          if (d.suspended) l10n.adminDomainsSuspended,
                        ].join(' · '),
                        showChevron: false,
                        trailing: TextButton(
                          key: Key('adminDomainSuspend-${d.id}'),
                          onPressed: () => _suspend(context, ref, d),
                          child: Text(
                            d.suspended
                                ? l10n.adminDomainsUnsuspend
                                : l10n.adminDomainsSuspend,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        );
      },
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

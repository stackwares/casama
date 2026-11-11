import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Null when the signed-in user is not this instance's owner.
final adminOverviewProvider = FutureProvider<AdminOverview?>((ref) async {
  final signedIn = ref.watch(signedInProvider).value ?? false;
  if (!signedIn) return null;
  return ref.watch(backendProvider).adminOverview();
});

final _adminUpdatesProvider = FutureProvider<UpdateNotice>((r) => r.watch(backendProvider).adminUpdates());
final _adminUsersProvider = FutureProvider<List<AdminUser>>((r) => r.watch(backendProvider).adminUsers());
final _adminServicesProvider = FutureProvider<List<AdminService>>((r) => r.watch(backendProvider).adminServices());
final _adminOrgsProvider = FutureProvider.autoDispose<List<AdminOrg>>((r) => r.watch(backendProvider).adminOrgs());
final _adminAbuseProvider = FutureProvider.autoDispose<List<AbuseEvent>>((r) => r.watch(backendProvider).adminAbuseEvents());

/// Owner admin console: overview and update notice, users, workspace quotas, services.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 5,
      child: SubPage(
        title: l10n.adminConsole,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                tabs: [
                  Tab(height: 40, text: l10n.adminOverview),
                  Tab(height: 40, text: l10n.adminUsers),
                  Tab(height: 40, text: l10n.adminWorkspaces),
                  Tab(height: 40, text: l10n.adminServices),
                  Tab(height: 40, text: l10n.adminAbuse),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [_Overview(), _Users(), _Orgs(), _Services(), _Abuse()]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colorScheme.primary;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontFeatures: AppText.tabular, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final updates = ref.watch(_adminUpdatesProvider);
    return AsyncView(
      value: ref.watch(adminOverviewProvider),
      onRetry: () => ref.invalidate(adminOverviewProvider),
      data: (o) {
        if (o == null) return EmptyState(icon: LucideIcons.lock, message: l10n.notInstanceOwner);
        final u = updates.value;
        final stats = [
          _Stat(icon: LucideIcons.user, label: l10n.adminUsers, value: '${o.users}'),
          _Stat(icon: LucideIcons.boxes, label: l10n.adminWorkspaces, value: '${o.orgs}'),
          _Stat(icon: LucideIcons.bot, label: l10n.bots, value: '${o.bots}'),
          _Stat(icon: LucideIcons.circlePlay, label: l10n.runs24h, value: '${o.runs24h}', color: colors.info),
          _Stat(
            icon: LucideIcons.circleAlert,
            label: l10n.failedRuns24h,
            value: '${o.failedRuns24h}',
            color: o.failedRuns24h > 0 ? colors.negative : colors.positive,
          ),
          _Stat(icon: LucideIcons.banknote, label: l10n.cost24h, value: formatUsd(o.cost24hUsd), color: colors.positive),
          _Stat(icon: LucideIcons.monitor, label: l10n.computersRunning, value: '${o.computersRunning}', color: colors.working),
          _Stat(icon: LucideIcons.monitorSmartphone, label: l10n.devicesOnline, value: '${o.devicesOnline}'),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: kPageMaxWidth);
            final columns = constraints.maxWidth - side * 2 >= 440 ? 3 : 2;
            return ListView(
              padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
              children: [
                if (u != null && u.updateAvailable) ...[
                  AppCard(
                    key: const Key('updateNotice'),
                    borderColor: context.colorScheme.primary.withValues(alpha: 0.45),
                    child: Row(
                      children: [
                        Icon(LucideIcons.arrowDownToLine, color: context.colorScheme.primary),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.updateAvailable(u.latest ?? '', u.current), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              if (u.url != null) SelectableText(u.url!, style: context.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                // Rows of tiles at their natural height (equal within a row), rather than a fixed
                // ratio that cuts them off on narrow phones, with other fonts or larger text.
                Column(
                  spacing: AppSpace.sm,
                  children: [
                    for (var r = 0; r < stats.length; r += columns)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpace.sm,
                          children: [
                            for (var c = r; c < r + columns; c++) Expanded(child: c < stats.length ? stats[c] : const SizedBox()),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                FormNote(l10n.kasamaVersion(o.version), icon: LucideIcons.badgeCheck),
              ],
            );
          },
        );
      },
    );
  }
}

class _Users extends ConsumerWidget {
  const _Users();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(_adminUsersProvider);
    return AsyncView(
      value: users,
      data: (items) => PageColumn(
        children: [
          GroupedCard(
            children: [
              for (final u in items)
                GroupedTile(
                  icon: LucideIcons.user,
                  title: u.email ?? u.id,
                  subtitle: [
                    context.l10n.workspacesCount(u.orgs),
                    if (u.lastSignInAt != null) context.l10n.lastSignIn(relativeTime(u.lastSignInAt!, context)),
                  ].join(' · '),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Orgs extends ConsumerStatefulWidget {
  const _Orgs();

  @override
  ConsumerState<_Orgs> createState() => _OrgsState();
}

class _OrgsState extends ConsumerState<_Orgs> {
  Future<void> _edit(AdminOrg o) async {
    final limits = await showAdaptiveSheet<Map<String, num>>(
      context: context,
      builder: (_) => _QuotaForm(org: o),
    );
    if (limits == null || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).setOrgLimits(o.id, limits));
    if (!mounted) return;
    ref.invalidate(_adminOrgsProvider);
  }

  Future<void> _toggleSuspend(AdminOrg o) async {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    if (o.suspendedAt != null) {
      await runGuarded(context, () => backend.unsuspendOrg(o.id));
    } else {
      final reason = TextEditingController();
      final ok = await showAdaptiveSheet<bool>(
        context: context,
        builder: (c) => FormSheet(
          icon: LucideIcons.ban,
          title: '${l10n.suspendWorkspace}: ${o.name}',
          subtitle: l10n.suspendWorkspaceHelp,
          submitLabel: l10n.suspendWorkspace,
          submitKey: const Key('confirmSuspend'),
          destructive: true,
          onSubmit: () => Navigator.pop(c, true),
          children: [
            TextField(key: const Key('suspendReason'), controller: reason, decoration: InputDecoration(labelText: l10n.suspendReason)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final text = reason.text.trim().isEmpty ? l10n.suspendedByInstanceOwner : reason.text.trim();
      await runGuarded(context, () => backend.suspendOrg(o.id, text));
    }
    if (!mounted) return;
    ref.invalidate(_adminOrgsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AsyncView<List<AdminOrg>>(
      value: ref.watch(_adminOrgsProvider),
      onRetry: () => ref.invalidate(_adminOrgsProvider),
      data: (orgs) {
        if (orgs.isEmpty) return EmptyState(icon: LucideIcons.boxes, message: l10n.adminNoWorkspaces);
        return PageColumn(
          children: [
            GroupedCard(
              children: [
                for (final o in orgs)
                  GroupedTile(
                    key: Key('adminOrg-${o.id}'),
                    icon: LucideIcons.boxes,
                    title: o.name,
                    subtitle: [
                      l10n.membersCount(o.members),
                      l10n.botsCount(o.bots),
                      l10n.cost30d(formatUsd(o.cost30dUsd)),
                      if (o.limits.isNotEmpty) o.limits.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                      if (o.suspendedAt != null) l10n.workspaceSuspended(o.suspendedReason ?? ''),
                    ].join(' · '),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(tooltip: l10n.editQuotas, icon: const Icon(LucideIcons.slidersHorizontal), onPressed: () => _edit(o)),
                        IconButton(
                          key: Key('suspend-${o.id}'),
                          tooltip: o.suspendedAt != null ? l10n.unsuspendWorkspace : l10n.suspendWorkspace,
                          icon: Icon(o.suspendedAt != null ? LucideIcons.circlePlay : LucideIcons.ban),
                          onPressed: () => _toggleSuspend(o),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuotaForm extends StatefulWidget {
  const _QuotaForm({required this.org});
  final AdminOrg org;

  @override
  State<_QuotaForm> createState() => _QuotaFormState();
}

class _QuotaFormState extends State<_QuotaForm> {
  late final _bots = TextEditingController(text: '${widget.org.limits['max_bots'] ?? ''}');
  late final _usd = TextEditingController(text: '${widget.org.limits['monthly_usd'] ?? ''}');

  @override
  void dispose() {
    _bots.dispose();
    _usd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.slidersHorizontal,
      title: l10n.quotasFor(widget.org.name),
      subtitle: l10n.quotasHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveQuota'),
      onSubmit: () => Navigator.pop(context, <String, num>{
        if (num.tryParse(_bots.text) != null) 'max_bots': num.parse(_bots.text),
        if (num.tryParse(_usd.text) != null) 'monthly_usd': num.parse(_usd.text),
      }),
      children: [
        TextField(
          key: const Key('maxBots'),
          controller: _bots,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.maxBots, prefixIcon: const Icon(LucideIcons.bot, size: 20)),
        ),
        TextField(
          key: const Key('monthlyUsd'),
          controller: _usd,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.monthlyUsd, prefixIcon: const Icon(LucideIcons.circleDollarSign, size: 20)),
        ),
      ],
    );
  }
}

class _Services extends ConsumerWidget {
  const _Services();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final services = ref.watch(_adminServicesProvider);
    return AsyncView(
      value: services,
      data: (items) => PageColumn(
        children: [
          GroupedCard(
            children: [
              for (final s in items)
                GroupedTile(
                  icon: !s.configured ? LucideIcons.circleMinus : (s.healthy == false ? LucideIcons.circleAlert : LucideIcons.circleCheck),
                  iconColor: !s.configured ? context.colorScheme.onSurfaceVariant : (s.healthy == false ? colors.negative : colors.positive),
                  title: s.name,
                  subtitle: s.detail,
                  trailing: StatusLabel(
                    text: !s.configured ? l10n.serviceOff : (s.healthy == false ? l10n.serviceDown : l10n.serviceOk),
                    color: !s.configured ? context.colorScheme.onSurfaceVariant : (s.healthy == false ? colors.negative : colors.positive),
                    pill: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Recent abuse signals and actions (D-094).
class _Abuse extends ConsumerWidget {
  const _Abuse();

  String _label(BuildContext context, String kind) {
    final l10n = context.l10n;
    return switch (kind) {
      'mining_pool' => l10n.abuseKind_mining_pool,
      'blocked_port' => l10n.abuseKind_blocked_port,
      'egress_flood' => l10n.abuseKind_egress_flood,
      'signup_blocked' => l10n.abuseKind_signup_blocked,
      'suspended' => l10n.abuseKind_suspended,
      'unsuspended' => l10n.abuseKind_unsuspended,
      _ => kind,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<List<AbuseEvent>>(
      value: ref.watch(_adminAbuseProvider),
      onRetry: () => ref.invalidate(_adminAbuseProvider),
      data: (items) {
        return PageColumn(
          children: [
            if (items.isEmpty)
              AppCard(child: FormNote(context.l10n.adminNoAbuse, icon: LucideIcons.shieldCheck))
            else
              GroupedCard(
                children: [
                  for (final e in items)
                    GroupedTile(
                      icon: e.kind == 'unsuspended' ? LucideIcons.circlePlay : LucideIcons.shieldAlert,
                      title: _label(context, e.kind),
                      subtitle: [
                        ?e.orgName,
                        if (e.detail['target'] case final String t) t,
                        if (e.detail['reason'] case final String r) r,
                        e.createdAt.replaceFirst('T', ' ').substring(0, 16),
                      ].join(' · '),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

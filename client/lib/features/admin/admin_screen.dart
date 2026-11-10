import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

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

/// Owner admin console: overview and update notice, users, workspace quotas, services.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 4,
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
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [_Overview(), _Users(), _Orgs(), _Services()]),
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
        if (o == null) return EmptyState(icon: Icons.lock_outline_rounded, message: l10n.notInstanceOwner);
        final u = updates.value;
        final stats = [
          _Stat(icon: Icons.person_outline_rounded, label: l10n.adminUsers, value: '${o.users}'),
          _Stat(icon: Icons.workspaces_outline, label: l10n.adminWorkspaces, value: '${o.orgs}'),
          _Stat(icon: Icons.smart_toy_outlined, label: l10n.bots, value: '${o.bots}'),
          _Stat(icon: Icons.play_circle_outline_rounded, label: l10n.runs24h, value: '${o.runs24h}', color: colors.info),
          _Stat(
            icon: Icons.error_outline_rounded,
            label: l10n.failedRuns24h,
            value: '${o.failedRuns24h}',
            color: o.failedRuns24h > 0 ? colors.negative : colors.positive,
          ),
          _Stat(icon: Icons.payments_outlined, label: l10n.cost24h, value: formatUsd(o.cost24hUsd), color: colors.positive),
          _Stat(icon: Icons.desktop_windows_outlined, label: l10n.computersRunning, value: '${o.computersRunning}', color: colors.working),
          _Stat(icon: Icons.devices_outlined, label: l10n.devicesOnline, value: '${o.devicesOnline}'),
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
                        Icon(Icons.system_update_alt_rounded, color: context.colorScheme.primary),
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
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpace.sm,
                  crossAxisSpacing: AppSpace.sm,
                  childAspectRatio: 1.35,
                  children: stats,
                ),
                const SizedBox(height: AppSpace.md),
                FormNote(l10n.kasamaVersion(o.version), icon: Icons.verified_outlined),
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
                  icon: Icons.person_outline_rounded,
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
  late Future<List<AdminOrg>> _orgs = ref.read(backendProvider).adminOrgs();

  Future<void> _edit(AdminOrg o) async {
    final limits = await showAdaptiveSheet<Map<String, num>>(
      context: context,
      builder: (_) => _QuotaForm(org: o),
    );
    if (limits == null || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).setOrgLimits(o.id, limits));
    final next = ref.read(backendProvider).adminOrgs();
    setState(() {
      _orgs = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<AdminOrg>>(
      future: _orgs,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return PageColumn(
          children: [
            GroupedCard(
              children: [
                for (final o in snap.data!)
                  GroupedTile(
                    key: Key('adminOrg-${o.id}'),
                    icon: Icons.workspaces_outline,
                    title: o.name,
                    subtitle: [
                      l10n.membersCount(o.members),
                      l10n.botsCount(o.bots),
                      l10n.cost30d(formatUsd(o.cost30dUsd)),
                      if (o.limits.isNotEmpty) o.limits.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                    ].join(' · '),
                    trailing: IconButton(tooltip: l10n.editQuotas, icon: const Icon(Icons.tune_rounded), onPressed: () => _edit(o)),
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
      icon: Icons.tune_rounded,
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
          decoration: InputDecoration(labelText: l10n.maxBots, prefixIcon: const Icon(Icons.smart_toy_outlined, size: 20)),
        ),
        TextField(
          key: const Key('monthlyUsd'),
          controller: _usd,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.monthlyUsd, prefixIcon: const Icon(Icons.attach_money_rounded, size: 20)),
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
                  icon: !s.configured
                      ? Icons.remove_circle_outline_rounded
                      : (s.healthy == false ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

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
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminConsole),
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l10n.adminOverview),
            Tab(text: l10n.adminUsers),
            Tab(text: l10n.adminWorkspaces),
            Tab(text: l10n.adminServices),
          ]),
        ),
        body: const TabBarView(children: [_Overview(), _Users(), _Orgs(), _Services()]),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final updates = ref.watch(_adminUpdatesProvider);
    return AsyncView(
      value: ref.watch(adminOverviewProvider),
      onRetry: () => ref.invalidate(adminOverviewProvider),
      data: (o) {
        if (o == null) return EmptyState(icon: Icons.lock_outline, message: l10n.notInstanceOwner);
        final u = updates.value;
        Widget stat(String label, String value) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            );
        return ListView(padding: const EdgeInsets.all(12), children: [
          if (u != null && u.updateAvailable)
            Card(
              key: const Key('updateNotice'),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: Text(l10n.updateAvailable(u.latest ?? '', u.current)),
                subtitle: u.url == null ? null : SelectableText(u.url!),
              ),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            stat(l10n.adminUsers, '${o.users}'),
            stat(l10n.adminWorkspaces, '${o.orgs}'),
            stat(l10n.bots, '${o.bots}'),
            stat(l10n.runs24h, '${o.runs24h}'),
            stat(l10n.failedRuns24h, '${o.failedRuns24h}'),
            stat(l10n.cost24h, formatUsd(o.cost24hUsd)),
            stat(l10n.computersRunning, '${o.computersRunning}'),
            stat(l10n.devicesOnline, '${o.devicesOnline}'),
          ]),
          const SizedBox(height: 8),
          Text(l10n.kasamaVersion(o.version), style: Theme.of(context).textTheme.bodySmall),
        ]);
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
      data: (items) => ListView(children: [
        for (final u in items)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(u.email ?? u.id),
            subtitle: Text([
              context.l10n.workspacesCount(u.orgs),
              if (u.lastSignInAt != null) context.l10n.lastSignIn(relativeTime(u.lastSignInAt!, context)),
            ].join(' · ')),
          ),
      ]),
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
    final l10n = context.l10n;
    final bots = TextEditingController(text: '${o.limits['max_bots'] ?? ''}');
    final usd = TextEditingController(text: '${o.limits['monthly_usd'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.quotasFor(o.name)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(key: const Key('maxBots'), controller: bots, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.maxBots)),
          TextField(key: const Key('monthlyUsd'), controller: usd, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.monthlyUsd)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          FilledButton(key: const Key('saveQuota'), onPressed: () => Navigator.pop(c, true), child: Text(l10n.save)),
        ],
      ),
    );
    final limits = <String, num>{
      if (num.tryParse(bots.text) != null) 'max_bots': num.parse(bots.text),
      if (num.tryParse(usd.text) != null) 'monthly_usd': num.parse(usd.text),
    };
    if (ok != true || !mounted) return;
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
        return ListView(children: [
          for (final o in snap.data!)
            ListTile(
              key: Key('adminOrg-${o.id}'),
              leading: const Icon(Icons.workspaces_outline),
              title: Text(o.name),
              subtitle: Text([
                l10n.membersCount(o.members),
                l10n.botsCount(o.bots),
                l10n.cost30d(formatUsd(o.cost30dUsd)),
                if (o.limits.isNotEmpty) o.limits.entries.map((e) => '${e.key}: ${e.value}').join(', '),
              ].join(' · ')),
              trailing: IconButton(tooltip: l10n.editQuotas, icon: const Icon(Icons.tune), onPressed: () => _edit(o)),
            ),
        ]);
      },
    );
  }
}

class _Services extends ConsumerWidget {
  const _Services();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(_adminServicesProvider);
    return AsyncView(
      value: services,
      data: (items) => ListView(children: [
        for (final s in items)
          ListTile(
            leading: Icon(
              !s.configured ? Icons.remove_circle_outline : (s.healthy == false ? Icons.error_outline : Icons.check_circle_outline),
              color: s.healthy == false ? Theme.of(context).colorScheme.error : null,
            ),
            title: Text(s.name),
            subtitle: Text(s.detail),
          ),
      ]),
    );
  }
}

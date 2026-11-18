import 'package:casama_sdk/casama_sdk.dart' show OrgRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/glow_button.dart';
import '../../ui/lucide_names.dart';
import '../../ui/page.dart';
import '../chat/widgets/gallery_cards.dart' show galleryKindIcon;

final _policyProvider = FutureProvider.autoDispose
    .family<WorkspaceGalleryPolicy, String>(
      (ref, orgId) => ref.watch(backendProvider).galleryPolicy(orgId),
    );

/// Adds waiting on an admin's yes; empty when the server has none (or no such route).
final _approvalsProvider = FutureProvider.autoDispose
    .family<List<WorkspaceGalleryApproval>, String>((ref, orgId) async {
      try {
        return await ref
            .watch(backendProvider)
            .galleryApprovals(orgId, status: 'pending');
      } catch (_) {
        return const [];
      }
    });

/// Every gallery item by `<type>/<id>`, to name the allow and block lists and to pick from.
final _galleryItemsProvider =
    FutureProvider.autoDispose<Map<String, GalleryItem>>((ref) async {
      final backend = ref.watch(backendProvider);
      final items = <String, GalleryItem>{};
      try {
        for (final i in (await backend.galleryEverything()).items) {
          items[i.key] = i;
        }
      } catch (_) {
        // No gallery here: the lists show the raw keys.
      }
      try {
        for (final s in await backend.gallerySets()) {
          items[s.key] = s;
        }
      } catch (_) {}
      return items;
    });

/// Settings → Workspace → Gallery (D-315), for admins and owners: whether members add freely, ask
/// first or pick only from an allowed list, what asks first, and the allowed and blocked items.
class GalleryPolicyScreen extends ConsumerStatefulWidget {
  const GalleryPolicyScreen({super.key});

  @override
  ConsumerState<GalleryPolicyScreen> createState() =>
      _GalleryPolicyScreenState();
}

class _GalleryPolicyScreenState extends ConsumerState<GalleryPolicyScreen> {
  /// The edited rules; null until loaded (and after a save, until changed again).
  WorkspaceGalleryPolicy? _draft;
  var _busy = false;

  Future<void> _save(String orgId) async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final saved = await runGuarded(
      context,
      () => ref.read(backendProvider).setGalleryPolicy(orgId, draft),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (saved != null) _draft = null;
    });
    if (saved == null) return;
    ref.invalidate(_policyProvider(orgId));
    showSuccess(context, l10n.galleryPolicySaved);
  }

  Future<void> _decide(
    String orgId,
    WorkspaceGalleryApproval approval, {
    required bool approve,
  }) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final done = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .decideGalleryApproval(approval.id, approve: approve),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(_approvalsProvider(orgId));
    if (done == null) return;
    if (done.status == 'failed') {
      showMessage(
        context,
        l10n.galleryPolicyApproveFailed(approval.name, done.error ?? ''),
      );
    } else {
      showSuccess(
        context,
        approve
            ? l10n.galleryPolicyApproved(approval.name)
            : l10n.galleryPolicyDeclined(approval.name),
      );
    }
  }

  void _edit(WorkspaceGalleryPolicy next) {
    HapticsHelper.selection();
    setState(() => _draft = next);
  }

  Future<void> _pick(
    WorkspaceGalleryPolicy current, {
    required bool allow,
  }) async {
    final taken = {...current.allow, ...current.block};
    final key = await showAdaptiveSheet<String>(
      context: context,
      heightFactor: 0.85,
      builder: (_) => _GalleryPickSheet(exclude: taken),
    );
    if (key == null || !mounted) return;
    _edit(
      allow
          ? current.copyWith(allow: [...current.allow, key])
          : current.copyWith(block: [...current.block, key]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    if (org == null) return const SizedBox.shrink();
    final admin = org.role != OrgRole.member;
    final loaded = ref.watch(_policyProvider(org.id));
    final policy = _draft ?? loaded.value;
    if (policy == null) {
      return SubPage(
        title: l10n.galleryPolicyTitle,
        body: loaded.hasError
            ? Center(child: Text(errorText(context, loaded.error!)))
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final items = ref.watch(_galleryItemsProvider).value ?? const {};
    final waiting = admin
        ? ref.watch(_approvalsProvider(org.id)).value ??
              const <WorkspaceGalleryApproval>[]
        : const <WorkspaceGalleryApproval>[];
    final dirty = _draft != null;
    void Function()? when(void Function() f) => admin && !_busy ? f : null;

    Widget modeTile(
      GalleryPolicyMode mode,
      IconData icon,
      String title,
      String help,
    ) => GroupedTile(
      key: Key('galleryPolicyMode-${mode.value}'),
      icon: icon,
      title: title,
      subtitle: help,
      onTap: when(() => _edit(policy.copyWith(mode: mode))),
      trailing: Icon(
        policy.mode == mode ? LucideIcons.circleCheck : LucideIcons.circle,
        color: policy.mode == mode
            ? context.colorScheme.primary
            : context.colorScheme.outline,
      ),
    );

    Widget ruleTile(String rule, IconData icon, String title) {
      final on = policy.approvalFor.contains(rule);
      return GroupedTile(
        key: Key('galleryPolicyRule-$rule'),
        icon: icon,
        title: title,
        onTap: when(
          () => _edit(
            policy.copyWith(approvalFor: _toggleRule(policy.approvalFor, rule)),
          ),
        ),
        trailing: Switch(
          key: Key('galleryPolicyRuleBox-$rule'),
          value: on,
          onChanged: admin && !_busy
              ? (_) => _edit(
                  policy.copyWith(
                    approvalFor: _toggleRule(policy.approvalFor, rule),
                  ),
                )
              : null,
        ),
      );
    }

    Widget listSection({required bool allow}) {
      final keys = allow ? policy.allow : policy.block;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: allow
                ? l10n.galleryPolicyAllowed
                : l10n.galleryPolicyBlocked,
            count: keys.isEmpty ? null : '${keys.length}',
            trailing: admin
                ? TextButton.icon(
                    key: Key(
                      allow
                          ? 'galleryPolicyAddAllowed'
                          : 'galleryPolicyAddBlocked',
                    ),
                    onPressed: _busy ? null : () => _pick(policy, allow: allow),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(l10n.galleryPolicyAddItem),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpace.xxs,
              bottom: AppSpace.xs,
            ),
            child: Text(
              [
                allow
                    ? l10n.galleryPolicyAllowedHelp
                    : l10n.galleryPolicyBlockedHelp,
                if (admin) l10n.galleryPolicyKeyHelp,
              ].join(' '),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          GroupedCard(
            children: [
              if (keys.isEmpty)
                GroupedTile(
                  icon: allow ? LucideIcons.circleCheck : LucideIcons.ban,
                  iconColor: context.colorScheme.onSurfaceVariant,
                  title: l10n.galleryPolicyNone,
                ),
              for (final k in keys)
                GroupedTile(
                  key: Key('galleryPolicyItem-$k'),
                  icon: _iconFor(k, items[k]),
                  title: items[k]?.name ?? k,
                  subtitle: items[k] == null ? null : k.split('/').first,
                  trailing: admin
                      ? IconButton(
                          key: Key('galleryPolicyRemove-$k'),
                          tooltip: l10n.galleryPolicyRemove(
                            items[k]?.name ?? k,
                          ),
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: _busy
                              ? null
                              : () => _edit(
                                  allow
                                      ? policy.copyWith(
                                          allow: [...policy.allow]..remove(k),
                                        )
                                      : policy.copyWith(
                                          block: [...policy.block]..remove(k),
                                        ),
                                ),
                        )
                      : null,
                ),
            ],
          ),
        ],
      );
    }

    return SubPage(
      title: l10n.galleryPolicyTitle,
      children: [
        if (!admin)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Text(
              l10n.galleryPolicyAdminsOnly,
              style: context.textTheme.bodyMedium,
            ),
          ),
        if (waiting.isNotEmpty) ...[
          SectionHeader(
            title: l10n.galleryPolicyWaiting,
            count: '${waiting.length}',
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxs,
              0,
              AppSpace.xxs,
              AppSpace.xs,
            ),
          ),
          GroupedCard(
            key: const Key('galleryPolicyWaiting'),
            children: [
              for (final a in waiting)
                GroupedTile(
                  key: Key('galleryPolicyApproval-${a.id}'),
                  icon: _iconFor(a.key, items[a.key]),
                  title: a.pack
                      ? l10n.galleryApprovalPack(a.name)
                      : items[a.key]?.name ?? a.name,
                  subtitle: switch ([
                    if (a.requestedByName case final n? when n.isNotEmpty)
                      l10n.galleryPolicyRequestedBy(n),
                    if (a.reason.isNotEmpty) a.reason,
                  ]) {
                    [] => null,
                    final parts => parts.join(' · '),
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('galleryPolicyDecline-${a.id}'),
                        tooltip: l10n.galleryPolicyDecline,
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: _busy
                            ? null
                            : () => _decide(org.id, a, approve: false),
                      ),
                      IconButton(
                        key: Key('galleryPolicyApprove-${a.id}'),
                        tooltip: l10n.galleryPolicyApprove,
                        icon: Icon(
                          LucideIcons.check,
                          size: 18,
                          color: context.colorScheme.primary,
                        ),
                        onPressed: _busy
                            ? null
                            : () => _decide(org.id, a, approve: true),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
        ],
        SectionHeader(
          title: l10n.galleryPolicyMode,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxs,
            0,
            AppSpace.xxs,
            AppSpace.xs,
          ),
        ),
        GroupedCard(
          children: [
            modeTile(
              GalleryPolicyMode.open,
              LucideIcons.globe,
              l10n.galleryPolicyOpen,
              l10n.galleryPolicyOpenHelp,
            ),
            modeTile(
              GalleryPolicyMode.approval,
              LucideIcons.userCheck,
              l10n.galleryPolicyApproval,
              l10n.galleryPolicyApprovalHelp,
            ),
            modeTile(
              GalleryPolicyMode.allowlist,
              LucideIcons.listChecks,
              l10n.galleryPolicyAllowlist,
              l10n.galleryPolicyAllowlistHelp,
            ),
          ],
        ),
        if (policy.mode == GalleryPolicyMode.approval) ...[
          SectionHeader(title: l10n.galleryPolicyApprovalFor),
          GroupedCard(
            children: [
              ruleTile(
                'runs_code',
                LucideIcons.terminal,
                l10n.galleryPolicyRunsCode,
              ),
              ruleTile('apps', LucideIcons.plug, l10n.galleryPolicyApps),
              ruleTile('all', LucideIcons.layers, l10n.galleryPolicyAll),
            ],
          ),
        ],
        listSection(allow: true),
        listSection(allow: false),
        if (admin) ...[
          const SizedBox(height: AppSpace.lg),
          GlowButton(
            key: const Key('galleryPolicySave'),
            onPressed: dirty && !_busy ? () => _save(org.id) : null,
            child: Text(l10n.save),
          ),
        ],
      ],
    );
  }
}

/// "Everything" stands alone: picking it clears the narrower rules, and picking one of those
/// clears it. Never empty (nothing ticked would mean asking for nothing): falls back to everything.
List<String> _toggleRule(List<String> current, String rule) {
  final next = {...current};
  if (next.contains(rule)) {
    next.remove(rule);
  } else if (rule == 'all') {
    next
      ..clear()
      ..add('all');
  } else {
    next
      ..remove('all')
      ..add(rule);
  }
  return next.isEmpty ? const ['all'] : next.toList();
}

/// A repository (`repo/<owner>:<repo>`) or pack (`pack/<name>`) key typed into the search, in
/// the server's form (lowercase letters, digits and dashes), or null when the text isn't one.
String? galleryPolicyTypedKey(String text) {
  final t = text.trim().toLowerCase();
  if (RegExp(r'^repo/[a-z0-9-]+:[a-z0-9._-]+$').hasMatch(t)) {
    return t.replaceAll(RegExp(r'[._]'), '-');
  }
  if (RegExp(r'^pack/[a-z0-9-]+$').hasMatch(t)) return t;
  return null;
}

IconData _iconFor(String key, GalleryItem? item) =>
    lucideByName(item?.icon) ??
    switch (key.split('/').first) {
      'repo' when item == null => LucideIcons.folderGit2,
      'pack' when item == null => LucideIcons.package,
      final type => galleryKindIcon(item?.type ?? type),
    };

/// Picks one gallery item by searching every kind; returns its `<type>/<id>`.
class _GalleryPickSheet extends ConsumerStatefulWidget {
  const _GalleryPickSheet({required this.exclude});
  final Set<String> exclude;

  @override
  ConsumerState<_GalleryPickSheet> createState() => _GalleryPickSheetState();
}

class _GalleryPickSheetState extends ConsumerState<_GalleryPickSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = ref.watch(_galleryItemsProvider);
    final q = _query.text.trim().toLowerCase();
    final matches = [
      for (final i in (all.value ?? const <String, GalleryItem>{}).values)
        if (!widget.exclude.contains(i.key) &&
            (q.isEmpty ||
                i.name.toLowerCase().contains(q) ||
                i.id.contains(q) ||
                i.type.contains(q) ||
                (i.description?.toLowerCase().contains(q) ?? false) ||
                i.tags.any((t) => t.toLowerCase().contains(q))))
          i,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // A repository or pack typed by hand (docs/PLUGINS-AND-PACKS-PLAN.md C.19).
    final typed = galleryPolicyTypedKey(_query.text);
    final useTyped = typed != null && !widget.exclude.contains(typed);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.galleryPolicyAddItem,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('galleryPolicySearch'),
            controller: _query,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.galleryPolicySearch,
              prefixIcon: const Icon(LucideIcons.search, size: 18),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              l10n.galleryPolicyKeyHelp,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (useTyped)
            ListTile(
              key: const Key('galleryPolicyUseKey'),
              leading: Icon(_iconFor(typed, null), size: 20),
              title: Text(l10n.galleryPolicyUseKey(typed)),
              onTap: () => Navigator.of(context).pop(typed),
            ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: all.isLoading
                ? const Center(child: CircularProgressIndicator())
                : matches.isEmpty
                ? Center(
                    child: Text(
                      l10n.galleryPolicyNoResults,
                      style: context.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, n) {
                      final i = matches[n];
                      return ListTile(
                        key: Key('galleryPolicyPick-${i.key}'),
                        leading: Icon(_iconFor(i.key, i), size: 20),
                        title: Text(i.name),
                        subtitle: Text(
                          [
                            i.type,
                            if (i.description case final d? when d.isNotEmpty)
                              d,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(i.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

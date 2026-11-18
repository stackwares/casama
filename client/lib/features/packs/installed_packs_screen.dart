import 'package:casama_sdk/casama_sdk.dart'
    show Pack, PackItem, PackItemKind, PackItemRef, PackKindDiff, PackUpdatePreview;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';
import '../skills/skill_visuals.dart';
import 'pack_logic.dart';
import 'pack_preview_screen.dart';

/// One installed pack and what it made.
final installedPackProvider = FutureProvider.autoDispose.family<Pack, String>(
  (ref, id) => ref.watch(backendProvider).pack(id),
);

/// Gallery → Installed packs (docs/PLUGINS-AND-PACKS-PLAN.md D.22): the workspace's packs.
class InstalledPacksScreen extends ConsumerWidget {
  const InstalledPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.packsInstalledTitle,
      body: AsyncView<List<Pack>>(
        value: ref.watch(installedPacksProvider),
        onRetry: () => ref.invalidate(installedPacksProvider),
        data: (packs) => packs.isEmpty
            ? EmptyState(
                icon: LucideIcons.package,
                message: l10n.packsInstalledEmpty,
                action: FilledButton(
                  key: const Key('packsEmptyAdd'),
                  onPressed: () => showAddPackFromLink(context, ref),
                  child: Text(l10n.packAddFromLink),
                ),
              )
            : PageColumn(
                children: [
                  GroupedCard(
                    key: const Key('installedPacks'),
                    children: [
                      for (final p in packs)
                        GroupedTile(
                          key: Key('installedPack-${p.id}'),
                          icon: packIcon(p.icon),
                          title: p.title,
                          subtitle: [
                            if (p.summary.isNotEmpty) p.summary,
                            l10n.packCountItems(p.items.length),
                          ].join(' · '),
                          showChevron: true,
                          onTap: () => context.push('/settings/gallery/packs/${p.id}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const PackAddTiles(),
                ],
              ),
      ),
    );
  }
}

/// An installed pack: its items (with "Edited by you"), Check for update and Remove.
class InstalledPackScreen extends ConsumerWidget {
  const InstalledPackScreen({super.key, required this.id});
  final String id;

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref, Pack pack) async {
    final l10n = context.l10n;
    final u = await runGuarded(context, () => ref.read(backendProvider).packUpdate(pack.id));
    if (u == null || !context.mounted) return;
    if (!u.canCheck) return showMessage(context, l10n.packCantCheck);
    if (u.upToDate) return showMessage(context, l10n.packUpToDate);
    final done = await showAdaptiveSheet<bool>(
      context: context,
      dialogMaxWidth: 600,
      builder: (_) => PackUpdateSheet(pack: pack, update: u),
    );
    if (done == true && context.mounted) {
      showSuccess(context, l10n.packUpdated(pack.title));
      ref.invalidate(installedPackProvider(pack.id));
      ref.invalidate(installedPacksProvider);
      ref.invalidate(botsProvider);
      ref.invalidate(skillsProvider);
      ref.invalidate(routinesProvider);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Pack pack) async {
    final l10n = context.l10n;
    final deleteBots = await showAdaptiveSheet<bool>(
      context: context,
      dialogMaxWidth: 480,
      builder: (_) => _RemovePackSheet(pack: pack),
    );
    if (deleteBots == null || !context.mounted) return;
    final kept = await runGuarded(context, () => ref.read(backendProvider).removePack(pack.id, deleteBots: deleteBots));
    if (kept == null || !context.mounted) return;
    showSuccess(context, l10n.packRemoved(kept));
    ref.invalidate(installedPacksProvider);
    ref.invalidate(botsProvider);
    ref.invalidate(skillsProvider);
    ref.invalidate(routinesProvider);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(installedPackProvider(id));
    return SubPage(
      title: value.value?.name ?? l10n.packsInstalledTitle,
      body: AsyncView<Pack>(
        value: value,
        onRetry: () => ref.invalidate(installedPackProvider(id)),
        data: (p) {
          final byKind = <PackItemKind, List<PackItem>>{};
          for (final i in p.items) {
            (byKind[i.kind] ??= []).add(i);
          }
          return PageColumn(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillIconTile(icon: packIcon(p.icon), color: context.colorScheme.primary, size: 52),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(p.title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        if (p.summary.isNotEmpty) Text(p.summary),
                        Text(
                          [
                            packSourceLine(l10n, p.source_, p.commit),
                            if (p.version case final v? when v.isNotEmpty) v,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('packCheckUpdate'),
                    onPressed: () => _checkUpdate(context, ref, p),
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: Text(l10n.checkForUpdate),
                  ),
                  OutlinedButton.icon(
                    key: const Key('packRemove'),
                    onPressed: () => _remove(context, ref, p),
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: Text(l10n.packRemove),
                  ),
                ],
              ),
              for (final MapEntry(key: kind, value: items) in byKind.entries) ...[
                SectionHeader(title: packKindTitle(l10n, kind), count: '${items.length}'),
                GroupedCard(
                  children: [
                    for (final i in items)
                      GroupedTile(
                        key: Key('packItem-${i.kind.value}:${i.id}'),
                        icon: packKindIcon(i.kind),
                        title: i.name,
                        trailing: i.edited ? _EditedBadge(key: Key('packEdited-${i.kind.value}:${i.id}')) : null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.xl),
            ],
          );
        },
      ),
    );
  }
}

class _EditedBadge extends StatelessWidget {
  const _EditedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          context.l10n.packEditedBadge,
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Asks whether to also delete the bots the pack made. Pops true or false to remove, null to keep.
class _RemovePackSheet extends StatefulWidget {
  const _RemovePackSheet({required this.pack});
  final Pack pack;

  @override
  State<_RemovePackSheet> createState() => _RemovePackSheetState();
}

class _RemovePackSheetState extends State<_RemovePackSheet> {
  var _deleteBots = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasBots = widget.pack.items.any((i) => i.kind == PackItemKind.bot);
    return FormSheet(
      key: const Key('packRemoveSheet'),
      icon: LucideIcons.trash2,
      title: l10n.packRemoveTitle(widget.pack.title),
      subtitle: l10n.packRemoveBody,
      submitLabel: l10n.packRemove,
      submitKey: const Key('packRemoveConfirm'),
      destructive: true,
      onSubmit: () => Navigator.of(context).pop(_deleteBots),
      children: [
        if (hasBots)
          CheckboxListTile(
            key: const Key('packRemoveBots'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _deleteBots,
            onChanged: (v) => setState(() => _deleteBots = v ?? false),
            title: Text(l10n.packRemoveBots),
          ),
      ],
    );
  }
}

/// A pack update's diff (docs/PLUGINS-AND-PACKS-PLAN.md D.23–24): what each kind gains, loses and
/// changes, new sites, keys and schedules, scheduled runs a week, and the items the person edited
/// with "Use the pack's version". An update that reaches further asks for a yes first.
class PackUpdateSheet extends ConsumerStatefulWidget {
  const PackUpdateSheet({super.key, required this.pack, required this.update});
  final Pack pack;
  final PackUpdatePreview update;

  @override
  ConsumerState<PackUpdateSheet> createState() => _PackUpdateSheetState();
}

class _PackUpdateSheetState extends ConsumerState<PackUpdateSheet> {
  final _theirs = <String>{};
  final _secrets = <String, TextEditingController>{};
  late var _reachGrew = widget.update.reachGrew;
  var _confirmed = false;
  var _busy = false;

  PackUpdatePreview get _u => widget.update;

  @override
  void initState() {
    super.initState();
    for (final n in _u.secretsAdded) {
      _secrets[n] = TextEditingController()..addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _secrets.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _name(PackItemRef r) =>
      widget.pack.items.where((i) => i.kind == r.kind && i.id == r.id).firstOrNull?.name ?? r.id;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(backendProvider)
          .updatePack(
            widget.pack.id,
            _u.toCommit ?? '',
            takeTheirs: [
              for (final r in _u.edited)
                if (_theirs.contains('${r.kind.value}:${r.id}')) r,
            ],
            confirmReach: _reachGrew && _confirmed,
            secrets: {for (final e in _secrets.entries) e.key: e.value.text.trim()},
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PackError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'pack_reach_grew') {
        // The list was out of date: ask now.
        setState(() => _reachGrew = true);
      } else {
        showError(context, e);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = _u;
    String short(String? v, String? commit) => v ?? (commit == null || commit.length < 7 ? '' : commit.substring(0, 7));
    final kinds = <(PackItemKind, PackKindDiff)>[
      (PackItemKind.bot, u.bots),
      (PackItemKind.skill, u.skills),
      (PackItemKind.routine, u.routines),
      (PackItemKind.app, u.apps),
      (PackItemKind.look, u.looks),
      (PackItemKind.tools, u.servers),
    ];
    final runsChanged = u.runsPerWeek.from.round() != u.runsPerWeek.to.round();
    final extra = [
      if (u.hostsAdded.isNotEmpty) (LucideIcons.globe, l10n.packDiffHosts(u.hostsAdded.join(', '))),
      if (u.secretsAdded.isNotEmpty) (LucideIcons.keyRound, l10n.packDiffSecrets(u.secretsAdded.join(', '))),
      if (u.schedulesChanged.isNotEmpty)
        (LucideIcons.calendarClock, l10n.packDiffSchedules(u.schedulesChanged.join(', '))),
      if (runsChanged)
        (LucideIcons.repeat, l10n.packDiffRuns('${u.runsPerWeek.from.round()}', '${u.runsPerWeek.to.round()}')),
    ];
    final anyKind = kinds.any((k) => !_empty(k.$2));
    final ready = !_busy && (!_reachGrew || _confirmed) && _secrets.values.every((c) => c.text.trim().isNotEmpty);
    return FormSheet(
      key: const Key('packUpdateSheet'),
      icon: LucideIcons.refreshCw,
      title: l10n.packUpdateTitle(widget.pack.title),
      subtitle: '${short(u.fromVersion, u.fromCommit)} → ${short(u.toVersion, u.toCommit)}',
      submitLabel: l10n.update,
      submitKey: const Key('packUpdateConfirm'),
      busy: _busy,
      onSubmit: ready ? _submit : null,
      children: [
        if (!anyKind && extra.isEmpty) Text(l10n.packDiffNone),
        for (final (kind, d) in kinds)
          if (!_empty(d)) _KindDiff(kind: kind, diff: d),
        if (extra.isNotEmpty)
          GroupedCard(
            key: const Key('packUpdateReach'),
            children: [for (final (icon, text) in extra) GroupedTile(icon: icon, title: text)],
          ),
        if (u.edited.isNotEmpty) ...[
          SectionHeader(title: l10n.packEditedTitle),
          Text(l10n.packEditedHelp, style: context.textTheme.bodySmall),
          GroupedCard(
            children: [
              for (final r in u.edited)
                SwitchListTile(
                  key: Key('packTheirs-${r.kind.value}:${r.id}'),
                  value: _theirs.contains('${r.kind.value}:${r.id}'),
                  onChanged: (v) => setState(() {
                    final k = '${r.kind.value}:${r.id}';
                    v ? _theirs.add(k) : _theirs.remove(k);
                  }),
                  secondary: Icon(packKindIcon(r.kind), size: 20),
                  title: Text(_name(r)),
                  subtitle: Text(l10n.packTakeTheirs),
                ),
            ],
          ),
        ],
        for (final e in _secrets.entries)
          Revealable(
            builder: (context, hidden, toggle) => TextField(
              key: Key('packSecret-${e.key}'),
              controller: e.value,
              obscureText: hidden,
              decoration: InputDecoration(labelText: e.key, suffixIcon: toggle),
            ),
          ),
        if (_reachGrew) ...[
          FormNote(
            l10n.packReachGrewHelp,
            key: const Key('packReachGrew'),
            icon: LucideIcons.shieldAlert,
            color: context.colorScheme.error,
          ),
          CheckboxListTile(
            key: const Key('packConfirmReach'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            title: Text(l10n.packReachConfirm),
          ),
        ],
      ],
    );
  }

  static bool _empty(PackKindDiff d) => d.added.isEmpty && d.removed.isEmpty && d.changed.isEmpty;
}

class _KindDiff extends StatelessWidget {
  const _KindDiff({required this.kind, required this.diff});
  final PackItemKind kind;
  final PackKindDiff diff;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      key: Key('packDiff-${kind.value}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        Text(packKindTitle(l10n, kind), style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        if (diff.added.isNotEmpty) Text(l10n.packDiffAdded(diff.added.join(', '))),
        if (diff.removed.isNotEmpty) Text(l10n.packDiffRemoved(diff.removed.join(', '))),
        for (final c in diff.changed) ...[
          Text(l10n.packDiffChanged(c.id)),
          if (c.diff.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in c.diff)
                    Text(
                      line,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: line.startsWith('+')
                            ? context.appColors.positive
                            : line.startsWith('-')
                            ? scheme.error
                            : null,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../settings/gallery_looks.dart';
import 'gallery_cards.dart';
import 'gallery_data.dart';
import 'gallery_detail_parts.dart';

/// The workspace's gallery items, with updates (D-315). Looks are tracked on the device.
final galleryInstalledProvider =
    FutureProvider.autoDispose<List<GalleryInstalledItem>>((ref) async {
      final org = ref.watch(currentOrgIdProvider);
      if (org == null) return const [];
      return ref.watch(backendProvider).galleryInstalled(org);
    });

/// Asks before an update that grows what an item can touch or is breaking: what it adds and
/// what changed. Returns true to update.
Future<bool> showGalleryUpdateDialog(
  BuildContext context, {
  required String name,
  required GalleryAccessDiff added,
  bool breaking = false,
  List<GalleryChange> changes = const [],
}) async {
  final l10n = context.l10n;
  final rows = galleryAccessDiffRows(l10n, added);
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 480,
    builder: (c) => FormSheet(
      key: const Key('galleryUpdateDialog'),
      icon: LucideIcons.shieldAlert,
      title: l10n.galleryUpdateAskTitle(name),
      subtitle: breaking && rows.isEmpty
          ? l10n.galleryUpdateBreakingHelp
          : l10n.galleryUpdateAccessHelp,
      submitLabel: l10n.galleryUpdate,
      submitKey: const Key('galleryUpdateConfirm'),
      onSubmit: () => Navigator.of(c).pop(true),
      children: [
        if (rows.isNotEmpty)
          GroupedCard(
            children: [
              for (final r in rows) GroupedTile(icon: r.icon, title: r.text),
            ],
          ),
        if (breaking && rows.isNotEmpty)
          Text(
            l10n.galleryUpdateBreakingHelp,
            style: c.textTheme.bodyMedium?.copyWith(color: c.colorScheme.error),
          ),
        if (changes.isNotEmpty) GalleryChangeList(changes: changes),
      ],
    ),
  );
  return ok ?? false;
}

/// What an update adds, one line each.
List<({IconData icon, String text})> galleryAccessDiffRows(
  AppLocalizations l10n,
  GalleryAccessDiff added,
) => [
  if (added.reads.isNotEmpty)
    (
      icon: LucideIcons.eye,
      text: l10n.galleryUpdateNowReads(added.reads.join(', ')),
    ),
  for (final w in added.writes)
    (icon: LucideIcons.pencil, text: l10n.galleryUpdateNowWrites(w)),
  if (added.runsCode)
    (icon: LucideIcons.code, text: l10n.galleryUpdateNowRunsCode),
  if (added.computer)
    (icon: LucideIcons.monitor, text: l10n.galleryUpdateNowComputer),
];

/// Updates an installed item, asking first when the server says access grew. True when updated.
Future<bool> galleryUpdateInstalled(
  BuildContext context,
  WidgetRef ref,
  GalleryInstalledItem item,
) async {
  final l10n = context.l10n;
  final backend = ref.read(backendProvider);
  final org = ref.read(currentOrgIdProvider);
  if (org == null) return false;
  var accept = false;
  if (item.asksFirst) {
    accept = await showGalleryUpdateDialog(
      context,
      name: item.name,
      added: item.accessAdded,
      breaking: item.breaking,
      changes: item.newChanges,
    );
    if (!accept || !context.mounted) return false;
  }
  try {
    await backend.updateGalleryInstalled(
      org,
      item.type,
      item.id,
      acceptAccess: accept,
    );
  } on GalleryAccessChanged catch (e) {
    // The list was out of date: ask with what the server says now.
    if (!context.mounted) return false;
    final ok = await showGalleryUpdateDialog(
      context,
      name: item.name,
      added: e.added,
      breaking: e.breaking,
      changes: item.newChanges,
    );
    if (!ok || !context.mounted) return false;
    final done = await runGuarded<bool>(context, () async {
      await backend.updateGalleryInstalled(
        org,
        item.type,
        item.id,
        acceptAccess: true,
      );
      return true;
    });
    if (done != true) return false;
  } catch (e, st) {
    if (context.mounted) showError(context, e, st);
    return false;
  }
  if (context.mounted) showSuccess(context, l10n.galleryUpdated(item.name));
  ref.invalidate(galleryInstalledProvider);
  return true;
}

/// The Installed tab's list.
class GalleryInstalledView extends ConsumerWidget {
  const GalleryInstalledView({super.key, this.onOpenItem, this.side = 0});

  /// Opens a gallery item (a retired item's replacement).
  final void Function(String type, String id)? onOpenItem;
  final double side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final installed = ref.watch(galleryInstalledProvider);
    final looks = ref.watch(galleryLocalLooksProvider);
    final catalog = ref.watch(galleryCatalogProvider).value;
    final items = installed.value ?? const <GalleryInstalledItem>[];
    final updates = items.where((i) => i.update && !i.retired).length;

    // Device looks: an update shows when the gallery has a newer version than the one used.
    final lookRows = [
      for (final l in looks) (look: l, latest: catalog?.find(l.type, l.id)),
    ];

    final children = <Widget>[];
    if (installed.isLoading && items.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (installed.hasError && items.isEmpty) {
      children.add(
        EmptyState(
          icon: LucideIcons.cloudOff,
          message: l10n.galleryInstalledError,
          action: OutlinedButton.icon(
            key: const Key('galleryInstalledRetry'),
            onPressed: () => ref.invalidate(galleryInstalledProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.retry),
          ),
        ),
      );
    }
    if (!installed.isLoading &&
        items.isEmpty &&
        looks.isEmpty &&
        !installed.hasError) {
      children.add(
        EmptyState(
          icon: LucideIcons.packageOpen,
          title: l10n.galleryInstalledEmptyTitle,
          message: l10n.galleryInstalledEmpty,
        ),
      );
    }
    if (items.isNotEmpty) {
      children.add(
        SectionHeader(
          title: l10n.galleryInstalledWorkspace,
          trailing: updates > 0
              ? Text(
                  l10n.galleryUpdatesAvailable(updates),
                  key: const Key('galleryUpdatesCount'),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      );
      children.add(
        GroupedCard(
          children: [
            for (final i in items)
              _InstalledRow(item: i, onOpenItem: onOpenItem),
          ],
        ),
      );
    }
    if (lookRows.isNotEmpty) {
      children.add(SectionHeader(title: l10n.galleryInstalledDevice));
      children.add(
        GroupedCard(
          children: [
            for (final r in lookRows) _LookRow(look: r.look, latest: r.latest),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Column(
        key: const Key('galleryInstalled'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InstalledRow extends ConsumerStatefulWidget {
  const _InstalledRow({required this.item, this.onOpenItem});
  final GalleryInstalledItem item;
  final void Function(String type, String id)? onOpenItem;

  @override
  ConsumerState<_InstalledRow> createState() => _InstalledRowState();
}

class _InstalledRowState extends ConsumerState<_InstalledRow> {
  var _busy = false;

  Future<void> _update() async {
    setState(() {
      _busy = true;
    });
    await galleryUpdateInstalled(context, ref, widget.item);
    if (mounted) {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _remove() async {
    final l10n = context.l10n;
    final item = widget.item;
    final ok = await showConfirm(
      context: context,
      title: l10n.galleryRemoveTitle(item.name),
      message: l10n.galleryRemoveHelp,
      confirmLabel: l10n.galleryRemove,
      confirmKey: const Key('galleryRemoveConfirm'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final org = ref.read(currentOrgIdProvider);
    if (org == null) return;
    final done = await runGuarded<bool>(context, () async {
      await ref
          .read(backendProvider)
          .removeGalleryInstalled(org, item.type, item.id);
      return true;
    });
    if (done == true && mounted) {
      showSuccess(context, l10n.galleryRemoved(item.name));
      ref.invalidate(galleryInstalledProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final replacement = item.replacement;
    final subtitle = item.retired
        ? (replacement != null
              ? l10n.galleryRetiredReplaced
              : l10n.galleryRetired)
        : item.update
        ? l10n.galleryUpdateFromTo(
            item.installedVersion,
            item.latestVersion ?? item.installedVersion,
          )
        : l10n.galleryVersion(item.installedVersion);
    return GroupedTile(
      key: Key('galleryInstalled-${item.type}-${item.id}'),
      icon: galleryKindIcon(item.type),
      title: item.name,
      subtitle: '${galleryKindName(l10n, item.type)} · $subtitle',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.retired && replacement != null && widget.onOpenItem != null)
            TextButton(
              key: Key('galleryReplacement-${item.id}'),
              onPressed: () =>
                  widget.onOpenItem!(replacement.type, replacement.id),
              child: Text(l10n.gallerySeeReplacement),
            )
          else if (item.update && !item.retired)
            FilledButton.tonal(
              key: Key('galleryUpdate-${item.id}'),
              onPressed: _busy ? null : _update,
              child: Text(l10n.galleryUpdate),
            ),
          IconButton(
            key: Key('galleryRemove-${item.id}'),
            tooltip: l10n.galleryRemove,
            onPressed: _busy ? null : _remove,
            icon: const Icon(LucideIcons.trash2, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LookRow extends ConsumerWidget {
  const _LookRow({required this.look, this.latest});
  final GalleryLocalLook look;
  final GalleryItem? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final latest = this.latest;
    final newer = latest != null && latest.version > look.version;
    return GroupedTile(
      key: Key('galleryLook-${look.type}-${look.id}'),
      icon: galleryKindIcon(look.type),
      title: look.name,
      subtitle:
          '${galleryKindName(l10n, look.type)} · ${newer ? l10n.galleryUpdateFromTo(look.version, latest.version) : l10n.galleryVersion(look.version)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (newer)
            FilledButton.tonal(
              key: Key('galleryLookUpdate-${look.id}'),
              onPressed: () async {
                final done = await runGuarded<bool>(context, () async {
                  await useGalleryLook(ref, latest);
                  return true;
                });
                if (done == true && context.mounted) {
                  showSuccess(context, l10n.galleryUpdated(look.name));
                }
              },
              child: Text(l10n.galleryUpdate),
            ),
          IconButton(
            key: Key('galleryLookForget-${look.id}'),
            tooltip: l10n.galleryForgetLook,
            onPressed: () =>
                ref.read(galleryLocalLooksProvider.notifier).remove(look.key),
            icon: const Icon(LucideIcons.x, size: 18),
          ),
        ],
      ),
    );
  }
}

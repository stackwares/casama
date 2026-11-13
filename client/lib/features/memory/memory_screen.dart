import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/app_menu.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/route_focus.dart';
import '../../ui/segmented.dart';
import '../bots/agent_import.dart';

/// What a bot remembers: search, add, view, edit, pin and delete (deleted memories are gone, not
/// hidden).
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

/// Whether [m] matches what was typed in the search box: every word, in any order.
bool memoryMatches(Memory m, String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final text = m.content.toLowerCase();
  return words.every(text.contains);
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  String get botId => widget.botId;
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Adds a fact or preference by hand (Improve app 3).
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showAdaptiveSheet<(String, String)>(context: context, builder: (_) => const _AddMemoryForm());
    if (added == null || !context.mounted) return;
    final (kind, text) = added;
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).addMemory(botId, text, kind: kind);
      return true;
    });
    ref.invalidate(memoriesProvider(botId));
    if (ok == true && context.mounted) showSuccess(context, context.l10n.memoryAdded);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Memory m) async {
    final text = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => _EditMemoryForm(initial: m.content),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).updateMemory(botId, m.id, content: text));
    ref.invalidate(memoriesProvider(botId));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Memory m) async {
    final l10n = context.l10n;
    final ok = await showConfirm(context: context, title: l10n.deleteMemoryTitle, message: l10n.deleteMemoryConfirm, confirmLabel: l10n.delete, destructive: true);
    if (!ok || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteMemory(botId, m.id));
    ref.invalidate(memoriesProvider(botId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(botId));
    final memories = ref.watch(memoriesProvider(botId));
    Future<void> importMemories() async {
      final n = await showAdaptiveSheet<int>(
        context: context,
        builder: (_) => MemoryImportSheet(botId: botId),
      );
      ref.invalidate(memoriesProvider(botId));
      if (n != null && context.mounted) showSuccess(context, l10n.memoriesImported(n));
    }

    // A search result links here with `?focus=<memory>` (D-235): open that memory.
    final focus = routeFocus(context);
    final focused = memories.value?.where((m) => m.id == focus).firstOrNull;
    return OpenOnce(
      id: focused?.id,
      ready: focused != null,
      open: (_) => _edit(context, ref, focused!),
      child: SubPage(
      title: l10n.memory,
      subtitle: bot?.name,
      actions: [
        IconButton(key: const Key('addMemory'), tooltip: l10n.addMemory, icon: const Icon(LucideIcons.plus), onPressed: () => _add(context, ref)),
        IconButton(key: const Key('importMemories'), tooltip: l10n.importMemoryTitle, icon: const Icon(LucideIcons.download), onPressed: importMemories),
      ],
      body: AsyncView(
        value: memories,
        onRetry: () => ref.invalidate(memoriesProvider(botId)),
        loading: const _MemoryListSkeleton(),
        data: (all) {
          if (all.isEmpty) return EmptyState(icon: LucideIcons.brain, title: l10n.noMemories, message: l10n.noMemoriesHelp);
          final items = _query.trim().isEmpty ? all : all.where((m) => memoryMatches(m, _query)).toList();
          return PageListView(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormNote(l10n.memoryHelp),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  key: const Key('memorySearch'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchMemories,
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('clearMemorySearch'),
                            tooltip: l10n.clearSearch,
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.lg),
                    child: Text(l10n.noMemoriesMatch, key: const Key('noMemoriesMatch'), textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _MemoryCard(
              memory: items[i],
              onEdit: () => _edit(context, ref, items[i]),
              onDelete: () => _delete(context, ref, items[i]),
              onPin: () async {
                await runGuarded(context, () => ref.read(backendProvider).updateMemory(botId, items[i].id, pinned: !items[i].pinned));
                ref.invalidate(memoriesProvider(botId));
              },
            ).appListItemEntrance(i),
          );
        },
      ),
      ),
    );
  }
}

/// The memory list still loading: the help note, then memory cards.
class _MemoryListSkeleton extends StatelessWidget {
  const _MemoryListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 1), child: SkeletonBone(width: 16, height: 16, radius: 8)),
            const SizedBox(width: 6),
            Expanded(child: SkeletonText(style: context.textTheme.bodySmall?.copyWith(height: 1.35), lines: 2, widthFactor: 0.8)),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        for (var i = 0; i < 5; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs), child: _MemoryCardSkeleton(lines: 1 + i % 3)),
      ],
    );
  }
}

/// A [_MemoryCard] still loading: the kind pill and time, a few lines of memory, the menu button.
class _MemoryCardSkeleton extends StatelessWidget {
  const _MemoryCardSkeleton({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xxs, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SkeletonBone(width: 78, height: 22, radius: AppRadius.pill),
                    const Spacer(),
                    SizedBox(width: 40, child: SkeletonText(style: text.labelSmall, widthFactor: 1)),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                SkeletonText(style: text.bodyMedium?.copyWith(height: 1.45), lines: lines, widthFactor: 0.7),
              ],
            ),
          ),
          const SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 4, height: 16, radius: 2))),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.onEdit, required this.onDelete, required this.onPin});
  final Memory memory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final m = memory;
    final (label, color, icon) = switch (m.kind.value) {
      'fact' => (l10n.memoryFact, colors.info, LucideIcons.lightbulb),
      'preference' => (l10n.memoryPreference, colors.positive, LucideIcons.heart),
      'summary' => (l10n.memorySummary, colors.warning, LucideIcons.notebookText),
      _ => (l10n.memoryEpisode, scheme.primary, LucideIcons.history),
    };
    return AppCard(
      key: Key('memory-${m.id}'),
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xxs, 12),
      borderColor: m.pinned ? scheme.primary.withValues(alpha: 0.45) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The labels wrap on narrow phones; the time stays on the right.
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StatusLabel(text: label, color: color, pill: true, icon: icon),
                          if (m.pinned) StatusLabel(text: l10n.pinned, color: scheme.primary, pill: true, icon: LucideIcons.pin),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    TimeAgo(m.updatedAt, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(m.content, style: context.textTheme.bodyMedium?.copyWith(height: 1.45)),
              ],
            ),
          ),
          AppMenuButton(
            tooltip: l10n.moreActions,
            entries: [
              AppMenuItem(icon: LucideIcons.pencil, label: l10n.edit, onTap: onEdit),
              AppMenuItem(
                icon: m.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                label: m.pinned ? l10n.unpin : l10n.pin,
                onTap: onPin,
              ),
              const AppMenuDivider(),
              AppMenuItem(icon: LucideIcons.trash2, label: l10n.delete, destructive: true, onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

/// A memory written by hand: a fact or a preference (Improve app 3).
class _AddMemoryForm extends StatefulWidget {
  const _AddMemoryForm();

  @override
  State<_AddMemoryForm> createState() => _AddMemoryFormState();
}

class _AddMemoryFormState extends State<_AddMemoryForm> {
  final _text = TextEditingController();
  var _kind = 'fact';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _text.text.trim();
    return FormSheet(
      icon: LucideIcons.brain,
      title: l10n.addMemory,
      subtitle: l10n.addMemoryHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveNewMemory'),
      onSubmit: text.isEmpty ? null : () => Navigator.pop(context, (_kind, text)),
      children: [
        AppSegmentedControl<String>(
          key: const Key('newMemoryKind'),
          values: const ['fact', 'preference'],
          labels: {'fact': l10n.memoryFact, 'preference': l10n.memoryPreference},
          groupValue: _kind,
          onValueChanged: (v) => setState(() => _kind = v),
        ),
        TextField(
          key: const Key('newMemoryText'),
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: _kind == 'fact' ? l10n.addMemoryFactHint : l10n.addMemoryPreferenceHint),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _EditMemoryForm extends StatefulWidget {
  const _EditMemoryForm({required this.initial});
  final String initial;

  @override
  State<_EditMemoryForm> createState() => _EditMemoryFormState();
}

class _EditMemoryFormState extends State<_EditMemoryForm> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.brain,
      title: l10n.editMemory,
      subtitle: l10n.editMemoryHelp,
      submitLabel: l10n.save,
      onSubmit: _text.text.trim().isEmpty ? null : () => Navigator.pop(context, _text.text.trim()),
      children: [TextField(controller: _text, autofocus: true, minLines: 3, maxLines: 8, onChanged: (_) => setState(() {}))],
    );
  }
}

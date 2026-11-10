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
import '../bots/agent_import.dart';

/// What a bot remembers: view, edit, pin and delete (deleted memories are gone, not hidden).
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key, required this.botId});
  final String botId;

  Future<void> _edit(BuildContext context, WidgetRef ref, Memory m) async {
    final text = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => _EditMemoryForm(initial: m.content),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).updateMemory(m.id, content: text));
    ref.invalidate(memoriesProvider(botId));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Memory m) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.deleteMemoryTitle,
      message: l10n.deleteMemoryConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteMemory(m.id));
    ref.invalidate(memoriesProvider(botId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(botId));
    final memories = ref.watch(memoriesProvider(botId));
    Future<void> importMemories() async {
      final n = await showAdaptiveSheet<int>(context: context, builder: (_) => MemoryImportSheet(botId: botId));
      ref.invalidate(memoriesProvider(botId));
      if (n != null && context.mounted) showMessage(context, l10n.memoriesImported(n));
    }

    return SubPage(
      title: l10n.memory,
      subtitle: bot?.name,
      actions: [IconButton(key: const Key('importMemories'), tooltip: l10n.importMemoryTitle, icon: const Icon(LucideIcons.download), onPressed: importMemories)],
      body: AsyncView(
        value: memories,
        onRetry: () => ref.invalidate(memoriesProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.brain, title: l10n.noMemories, message: l10n.noMemoriesHelp)
            : PageListView(
                header: FormNote(l10n.memoryHelp),
                itemCount: items.length,
                itemBuilder: (context, i) => _MemoryCard(
                  memory: items[i],
                  onEdit: () => _edit(context, ref, items[i]),
                  onDelete: () => _delete(context, ref, items[i]),
                  onPin: () async {
                    await runGuarded(context, () => ref.read(backendProvider).updateMemory(items[i].id, pinned: !items[i].pinned));
                    ref.invalidate(memoriesProvider(botId));
                  },
                ).appListItemEntrance(i),
              ),
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
                  children: [
                    StatusLabel(text: label, color: color, pill: true, icon: icon),
                    if (m.pinned) ...[const SizedBox(width: 6), StatusLabel(text: l10n.pinned, color: scheme.primary, pill: true, icon: LucideIcons.pin)],
                    const Spacer(),
                    Text(relativeTime(m.updatedAt, context), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(m.content, style: context.textTheme.bodyMedium?.copyWith(height: 1.45)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.moreActions,
            icon: Icon(LucideIcons.ellipsisVertical, color: scheme.onSurfaceVariant),
            onSelected: (v) => switch (v) {
              'edit' => onEdit(),
              'pin' => onPin(),
              _ => onDelete(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(leading: const Icon(LucideIcons.pencil), title: Text(l10n.edit), dense: true),
              ),
              PopupMenuItem(
                value: 'pin',
                child: ListTile(leading: Icon(m.pinned ? LucideIcons.pinOff : LucideIcons.pin), title: Text(m.pinned ? l10n.unpin : l10n.pin), dense: true),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(LucideIcons.trash2, color: scheme.error),
                  title: Text(l10n.delete, style: TextStyle(color: scheme.error)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
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

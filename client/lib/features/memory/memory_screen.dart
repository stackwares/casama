import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// What a bot remembers: view, edit, pin and delete (deleted memories are gone, not hidden).
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key, required this.botId});
  final String botId;

  Future<void> _edit(BuildContext context, WidgetRef ref, Memory m) async {
    final controller = TextEditingController(text: m.content);
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.edit),
        content: TextField(controller: controller, maxLines: 5, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(context.l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).updateMemory(m.id, content: text));
    ref.invalidate(memoriesProvider(botId));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Memory m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(context.l10n.deleteMemoryConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteMemory(m.id));
    ref.invalidate(memoriesProvider(botId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final memories = ref.watch(memoriesProvider(botId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.memory)),
      body: AsyncView(
        value: memories,
        onRetry: () => ref.invalidate(memoriesProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.psychology_outlined, message: l10n.noMemories)
            : ListView(children: [
                for (final m in items)
                  ListTile(
                    key: Key('memory-${m.id}'),
                    leading: Icon(m.pinned ? Icons.push_pin : Icons.notes_outlined),
                    title: Text(m.content),
                    subtitle: Text('${m.kind.value} · ${relativeTime(m.updatedAt, context)}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') await _edit(context, ref, m);
                        if (v == 'pin' && context.mounted) {
                          await runGuarded(context, () => ref.read(backendProvider).updateMemory(m.id, pinned: !m.pinned));
                          ref.invalidate(memoriesProvider(botId));
                        }
                        if (v == 'delete' && context.mounted) await _delete(context, ref, m);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'pin', child: Text(m.pinned ? l10n.unpin : l10n.pin)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ),
              ]),
      ),
    );
  }
}

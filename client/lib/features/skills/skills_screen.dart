import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';

/// Skills: Markdown instruction packs that bots load on demand.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [SkillView? skill]) async {
    await showAdaptiveSheet<void>(context: context, heightFactor: 0.85, builder: (_) => _SkillEditor(skill: skill));
    ref.invalidate(skillsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final skills = ref.watch(skillsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.skills)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSkill),
      ),
      body: AsyncView(
        value: skills,
        onRetry: () => ref.invalidate(skillsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.menu_book_outlined, message: l10n.noSkills)
            : ListView(children: [
                for (final s in items)
                  SwitchListTile(
                    title: Text(s.name),
                    subtitle: Text(s.description),
                    value: s.enabled,
                    onChanged: (v) async {
                      final org = ref.read(currentOrgProvider)!;
                      await runGuarded(
                        context,
                        () => ref.read(backendProvider).saveSkill(
                              org.id,
                              id: s.id,
                              botId: s.botId,
                              name: s.name,
                              description: s.description,
                              bodyMd: s.bodyMd,
                              enabled: v,
                            ),
                      );
                      ref.invalidate(skillsProvider);
                    },
                    secondary: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, ref, s)),
                  ),
              ]),
      ),
    );
  }
}

class _SkillEditor extends ConsumerStatefulWidget {
  const _SkillEditor({this.skill});
  final SkillView? skill;

  @override
  ConsumerState<_SkillEditor> createState() => _SkillEditorState();
}

class _SkillEditorState extends ConsumerState<_SkillEditor> {
  late final _name = TextEditingController(text: widget.skill?.name ?? '');
  late final _description = TextEditingController(text: widget.skill?.description ?? '');
  late final _body = TextEditingController(text: widget.skill?.bodyMd ?? '');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _name, decoration: InputDecoration(labelText: l10n.skillName)),
        const SizedBox(height: 8),
        TextField(controller: _description, decoration: InputDecoration(labelText: l10n.skillDescription)),
        const SizedBox(height: 8),
        TextField(controller: _body, decoration: InputDecoration(labelText: l10n.skillBody), maxLines: 10, minLines: 5),
        const SizedBox(height: 12),
        Row(children: [
          if (widget.skill != null)
            TextButton(
              onPressed: () async {
                await runGuarded(context, () => ref.read(backendProvider).deleteSkill(widget.skill!.id));
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.delete),
            ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              final org = ref.read(currentOrgProvider)!;
              final ok = await runGuarded(context, () async {
                await ref.read(backendProvider).saveSkill(
                      org.id,
                      id: widget.skill?.id,
                      botId: widget.skill?.botId,
                      name: _name.text.trim(),
                      description: _description.text.trim(),
                      bodyMd: _body.text,
                      enabled: widget.skill?.enabled ?? true,
                    );
                return true;
              });
              if (ok == true && context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ]),
      ]),
    );
  }
}

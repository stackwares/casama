import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';

/// Skills: Markdown instruction packs that bots load on demand.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [SkillView? skill]) async {
    await showAdaptiveSheet<void>(
      context: context,
      dialogMaxWidth: 680,
      builder: (_) => _SkillEditor(skill: skill),
    );
    ref.invalidate(skillsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final skills = ref.watch(skillsProvider);
    return SubPage(
      title: l10n.skills,
      actions: [HeaderIconButton(icon: LucideIcons.plus, tooltip: l10n.newSkill, onPressed: () => _edit(context, ref))],
      body: AsyncView(
        value: skills,
        onRetry: () => ref.invalidate(skillsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.bookOpen,
                title: l10n.noSkills,
                message: l10n.skillsHelp,
                action: FilledButton.icon(onPressed: () => _edit(context, ref), icon: const Icon(LucideIcons.plus, size: 18), label: Text(l10n.newSkill)),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.skillsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final s in items)
                        GroupedTile(
                          key: Key('skill-${s.id}'),
                          icon: LucideIcons.bookOpen,
                          iconColor: s.enabled ? null : context.colorScheme.onSurfaceVariant,
                          title: s.name,
                          subtitle: s.description,
                          onTap: () => _edit(context, ref, s),
                          trailing: Switch(
                            value: s.enabled,
                            onChanged: (v) async {
                              final org = ref.read(currentOrgProvider)!;
                              await runGuarded(
                                context,
                                () => ref
                                    .read(backendProvider)
                                    .saveSkill(org.id, id: s.id, botId: s.botId, name: s.name, description: s.description, bodyMd: s.bodyMd, enabled: v),
                              );
                              ref.invalidate(skillsProvider);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final org = ref.read(currentOrgProvider)!;
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .saveSkill(
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
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showConfirm(context: context, title: l10n.deleteSkillTitle(widget.skill!.name), confirmLabel: l10n.delete, destructive: true);
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteSkill(widget.skill!.id));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _name.text.trim().isNotEmpty && _description.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;
    return FormSheet(
      icon: LucideIcons.bookOpen,
      title: widget.skill == null ? l10n.newSkill : l10n.editSkill,
      subtitle: l10n.skillsHelp,
      submitLabel: l10n.save,
      busy: _busy,
      onSubmit: valid ? _save : null,
      footer: widget.skill == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: context.colorScheme.error),
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: Text(l10n.deleteSkill),
              ),
            ),
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l10n.skillName, hintText: 'weekly-report', prefixIcon: const Icon(LucideIcons.hash, size: 20)),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _description,
          decoration: InputDecoration(
            labelText: l10n.skillDescription,
            helperText: l10n.skillDescriptionHelp,
            prefixIcon: const Icon(LucideIcons.text, size: 20),
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _body,
          style: AppText.mono.copyWith(fontSize: 14),
          decoration: InputDecoration(labelText: l10n.skillBody, alignLabelWithHint: true, hintText: l10n.skillBodyHint),
          maxLines: 14,
          minLines: 6,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

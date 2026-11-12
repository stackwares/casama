import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// The skills library (D-104): GitHub import with a file preview, and updates with a diff. The
/// bundled catalog has its own page (skill_catalog_screen.dart).

Future<void> showGitHubSkillImport(BuildContext context) =>
    showAdaptiveSheet<void>(context: context, heightFactor: 0.9, dialogMaxWidth: 760, dialogMaxHeight: 820, builder: (_) => const _GitHubImport());

Future<void> showSkillUpdate(BuildContext context, SkillView skill) =>
    showAdaptiveSheet<void>(context: context, heightFactor: 0.85, dialogMaxWidth: 760, builder: (_) => _UpdateSheet(skill: skill));

/// Where to install: the whole workspace or one bot.
class _ScopePicker extends ConsumerWidget {
  const _ScopePicker({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return DropdownButtonFormField<String?>(
      key: const Key('skillScope'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.installFor, prefixIcon: const Icon(LucideIcons.target, size: 20)),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.wholeWorkspace)),
        for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name)),
      ],
      onChanged: hapticOnChanged(onChanged, haptic: HapticsHelper.selection),
    );
  }
}

class _GitHubImport extends ConsumerStatefulWidget {
  const _GitHubImport();

  @override
  ConsumerState<_GitHubImport> createState() => _GitHubImportState();
}

class _GitHubImportState extends ConsumerState<_GitHubImport> {
  final _url = TextEditingController();
  GitHubSkillPreview? _preview;
  String? _botId;
  var _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    setState(() => _busy = true);
    final p = await runGuarded(context, () => ref.read(backendProvider).previewGitHubSkill(org.id, _url.text.trim()));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _preview = p;
    });
  }

  Future<void> _install() async {
    final org = ref.read(currentOrgProvider);
    final p = _preview;
    if (org == null || p == null) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).installGitHubSkill(org.id, _url.text.trim(), p.commit, botId: _botId);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(skillsProvider);
      Navigator.pop(context);
      showSuccess(context, context.l10n.skillInstalled(p.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _preview;
    return FormSheet(
      icon: LucideIcons.gitBranch,
      title: l10n.importFromGitHub,
      subtitle: p == null ? l10n.importFromGitHubHelp : '${p.repo}${p.path.isEmpty ? '' : '/${p.path}'} @ ${p.commit.substring(0, 7)}',
      submitLabel: p == null ? l10n.preview : l10n.install,
      submitKey: const Key('githubSubmit'),
      onSubmit: _busy || _url.text.trim().isEmpty ? null : (p == null ? _load : _install),
      children: [
        TextField(
          key: const Key('githubUrl'),
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'GitHub', hintText: 'https://github.com/owner/repo/tree/main/skills/name', prefixIcon: Icon(LucideIcons.link, size: 20)),
          onChanged: (_) => setState(() => _preview = null),
        ),
        if (p != null) ...[
          _ScopePicker(value: _botId, onChanged: (v) => setState(() => _botId = v)),
          Text(p.name, style: context.textTheme.titleMedium),
          Text(p.description),
          FormNote(l10n.skillScriptsNote),
          _FileBlock(key: const Key('previewSkillMd'), title: 'SKILL.md', text: p.skillMd),
          for (final f in p.files) _FileBlock(title: '${f.path}${f.executable ? ' (executable)' : ''} · ${f.size.humanizedCount(context.l10n.localeName)} B', text: f.text ?? l10n.binaryFile),
        ],
      ],
    );
  }
}

class _FileBlock extends StatelessWidget {
  const _FileBlock({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(title, style: context.textTheme.labelLarge),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(color: context.appColors.codeBackground, borderRadius: AppRadius.tileAll),
            child: SingleChildScrollView(child: SelectableText(text, style: AppText.mono.copyWith(fontSize: 12))),
          ),
        ],
      );
}

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.skill});
  final SkillView skill;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  late final _check = ref.read(backendProvider).checkSkillUpdate(widget.skill.id);
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return FutureBuilder<SkillUpdateCheck>(
      future: _check,
      builder: (context, snap) {
        final c = snap.data;
        return FormSheet(
          icon: LucideIcons.gitCompare,
          title: l10n.skillUpdate(widget.skill.name),
          subtitle: c == null
              ? (snap.hasError ? errorText(context, snap.error!) : l10n.checkingForUpdates)
              : c.hasUpdate
                  ? '${c.currentCommit.substring(0, 7)} → ${c.latestCommit.substring(0, 7)}'
                  : l10n.skillUpToDate,
          submitLabel: l10n.update,
          submitKey: const Key('applySkillUpdate'),
          onSubmit: c == null || !c.hasUpdate || _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final ok = await runGuarded(context, () async {
                    await ref.read(backendProvider).applySkillUpdate(widget.skill.id, c.latestCommit);
                    return true;
                  });
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (ok == true) {
                    ref.invalidate(skillsProvider);
                    Navigator.pop(context);
                  }
                },
          children: [
            if (c != null && c.hasUpdate) ...[
              if (c.filesAdded.isNotEmpty) Text('${l10n.filesAdded}: ${c.filesAdded.join(', ')}'),
              if (c.filesChanged.isNotEmpty) Text('${l10n.filesChanged}: ${c.filesChanged.join(', ')}'),
              if (c.filesRemoved.isNotEmpty) Text('${l10n.filesRemoved}: ${c.filesRemoved.join(', ')}'),
              Container(
                key: const Key('skillDiff'),
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(color: colors.codeBackground, borderRadius: AppRadius.tileAll),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in c.diff)
                      Text(
                        line,
                        style: AppText.mono.copyWith(
                          fontSize: 12,
                          color: line.startsWith('+') ? colors.positive : (line.startsWith('-') ? colors.negative : null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

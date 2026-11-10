import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';

/// The skills library (D-104): the bundled catalog, GitHub import with a file preview, and updates
/// with a diff.

final skillCatalogProvider = FutureProvider.autoDispose<SkillCatalog>((ref) => ref.watch(backendProvider).skillCatalog());

Future<void> showSkillCatalog(BuildContext context) =>
    showAdaptiveSheet<void>(context: context, heightFactor: 0.9, dialogMaxWidth: 720, dialogMaxHeight: 760, builder: (_) => const _Catalog());

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
      onChanged: onChanged,
    );
  }
}

class _Catalog extends ConsumerStatefulWidget {
  const _Catalog();

  @override
  ConsumerState<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends ConsumerState<_Catalog> {
  var _query = '';
  String? _category;
  String? _botId;
  final _installed = <String>{};

  Future<void> _install(CatalogSkill s) async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).installCatalogSkill(org.id, s.id, botId: _botId);
      return true;
    });
    if (ok == true && mounted) {
      setState(() => _installed.add(s.id));
      ref.invalidate(skillsProvider);
      showMessage(context, context.l10n.skillInstalled(s.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final catalog = ref.watch(skillCatalogProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorText(context, e))),
        data: (cat) {
          final q = _query.toLowerCase();
          final items = cat.items
              .where((s) => (_category == null || s.category == _category) && (q.isEmpty || s.name.contains(q) || s.description.toLowerCase().contains(q)))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.sm,
            children: [
              Text(l10n.skillCatalog, style: context.textTheme.titleLarge),
              TextField(
                key: const Key('catalogSearch'),
                decoration: InputDecoration(hintText: l10n.searchSkills, prefixIcon: const Icon(LucideIcons.search, size: 20)),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  ChoiceChip(label: Text(l10n.all), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                  for (final c in cat.categories)
                    ChoiceChip(key: Key('category-$c'), label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
                ],
              ),
              _ScopePicker(value: _botId, onChanged: (v) => setState(() => _botId = v)),
              Expanded(
                child: ListView(
                  children: [
                    for (final s in items)
                      ListTile(
                        key: Key('catalog-${s.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.bookOpen),
                        title: Text(s.name),
                        subtitle: Text(
                          [s.description, if (s.files.isNotEmpty) l10n.skillFiles(s.files.length)].join(' · '),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _installed.contains(s.id)
                            ? Icon(LucideIcons.check, color: context.appColors.positive)
                            : TextButton(key: Key('install-${s.id}'), onPressed: () => _install(s), child: Text(l10n.install)),
                      ),
                    if (items.isEmpty) Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Text(l10n.noResults, style: TextStyle(color: scheme.onSurfaceVariant))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
      showMessage(context, context.l10n.skillInstalled(p.name));
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
          for (final f in p.files) _FileBlock(title: '${f.path}${f.executable ? ' (executable)' : ''} · ${f.size} B', text: f.text ?? l10n.binaryFile),
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

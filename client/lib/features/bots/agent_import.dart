import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import 'model_picker.dart';

/// Import an agent (D-122): an OpenClaw or Hermes Agent folder becomes a bot after a review step.
Future<void> importAgentFolder(BuildContext context, WidgetRef ref, {Future<Map<String, Uint8List>?> Function()? pickFolder, Future<Uint8List?> Function()? pickZip}) async {
  final l10n = context.l10n;
  await ref.read(organizationsProvider.future).catchError((Object _) => const <OrganizationWithRole>[]);
  final org = ref.read(currentOrgProvider);
  if (org == null || !context.mounted) return;
  final desktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);
  final how = await showAdaptiveSheet<String>(
    context: context,
    builder: (c) => FormSheet(
      icon: LucideIcons.folderInput,
      title: l10n.importAgent,
      subtitle: l10n.importAgentHelp,
      submitLabel: l10n.cancel,
      onSubmit: () => Navigator.pop(c),
      children: [
        if (desktop || pickFolder != null)
          ListTile(key: const Key('importAgentFolder'), leading: const Icon(LucideIcons.folderOpen), title: Text(l10n.importAgentPickFolder), onTap: () => Navigator.pop(c, 'folder')),
        ListTile(key: const Key('importAgentZip'), leading: const Icon(LucideIcons.fileArchive), title: Text(l10n.importAgentPickZip), onTap: () => Navigator.pop(c, 'zip')),
      ],
    ),
  );
  if (how == null || !context.mounted) return;
  final backend = ref.read(backendProvider);
  final plan = await runGuarded(context, () async {
    if (how == 'folder') {
      final files = await (pickFolder ?? readAgentFolder)();
      if (files == null) return null;
      return backend.startAgentImport(org.id, files: files);
    }
    final zip = await (pickZip ?? _pickZip)();
    if (zip == null) return null;
    return backend.startAgentImport(org.id, zip: zip);
  });
  if (plan == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgentImportReviewScreen(plan: plan)));
}

Future<Uint8List?> _pickZip() async {
  final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
  if (picked.isEmpty) return null;
  return picked.first.readAsBytes();
}

/// Reads a picked folder, leaving out what is never imported (logs, sessions, databases, git).
Future<Map<String, Uint8List>?> readAgentFolder() async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null) return null;
  final root = Directory(path);
  final out = <String, Uint8List>{};
  var total = 0;
  final skip = RegExp(r'(^|/)(\.git|node_modules|sessions|logs|state|__pycache__)(/|$)|\.(sqlite3?|db)(-wal|-shm)?$');
  await for (final e in root.list(recursive: true, followLinks: false)) {
    if (e is! File) continue;
    final rel = e.path.substring(root.path.length + 1).replaceAll('\\', '/');
    if (skip.hasMatch(rel)) continue;
    final bytes = await e.readAsBytes();
    total += bytes.length;
    if (out.length >= 3000 || total > 50 * 1024 * 1024) break;
    out[rel] = bytes;
  }
  return out;
}

class AgentImportReviewScreen extends ConsumerStatefulWidget {
  const AgentImportReviewScreen({super.key, required this.plan});
  final AgentImportPlan plan;

  @override
  ConsumerState<AgentImportReviewScreen> createState() => _AgentImportReviewScreenState();
}

class _AgentImportReviewScreenState extends ConsumerState<AgentImportReviewScreen> {
  late final _name = TextEditingController(text: widget.plan.template.name);
  late final Set<int> _skills = {for (var i = 0; i < (widget.plan.template.skills?.length ?? 0); i++) i};
  late final Set<int> _routines = {for (var i = 0; i < (widget.plan.template.routines?.length ?? 0); i++) i};
  late final Set<int> _memories = {for (var i = 0; i < (widget.plan.template.memories?.length ?? 0); i++) i};
  var _copyFiles = true;
  String? _credentialId;
  String _model = '';
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final org = ref.read(currentOrgProvider);
    if (org == null || _credentialId == null || _model.isEmpty) return;
    final t = widget.plan.template;
    List<T> pick<T>(List<T>? xs, Set<int> keep) => [
      for (var i = 0; i < (xs?.length ?? 0); i++)
        if (keep.contains(i)) xs![i],
    ];
    final chosen = BotTemplateFile(
      format: t.format,
      version: t.version,
      name: _name.text.trim().isEmpty ? t.name : _name.text.trim(),
      description: t.description,
      personaMd: t.personaMd,
      autonomy: t.autonomy,
      avatar: t.avatar,
      skills: pick(t.skills, _skills),
      routines: pick(t.routines, _routines),
      connections: t.connections,
      memories: pick(t.memories, _memories),
    );
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final r = await runGuarded(context, () => backend.importBot(org.id, chosen, credentialId: _credentialId!, model: _model));
    if (r == null || !mounted) return setState(() => _busy = false);
    ref.invalidate(botsProvider);
    final l10n = context.l10n;
    var message = l10n.botImported(chosen.name);
    if (_copyFiles && widget.plan.leftovers.isNotEmpty) {
      try {
        final n = await backend.writeAgentImportFiles(widget.plan.id, r.botId);
        message = l10n.agentImportedWithFiles(chosen.name, n);
      } catch (_) {
        message = l10n.agentImportedFilesLater(chosen.name);
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    showMessage(context, message);
    GoRouter.maybeOf(context)?.go('/bots/${r.botId}/chat');
  }

  Widget _check(Key key, String title, String? subtitle, bool value, ValueChanged<bool> onChanged, IconData icon) => CheckboxListTile(
    key: key,
    contentPadding: EdgeInsets.zero,
    secondary: Icon(icon, size: 18),
    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    value: value,
    onChanged: (v) => setState(() => onChanged(v ?? false)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = widget.plan;
    final t = p.template;
    final keys = ref.watch(credentialsProvider).value ?? const <Credential>[];
    _credentialId ??= keys.firstOrNull?.id;
    if (_model.isEmpty) {
      final key = keys.where((k) => k.id == _credentialId).firstOrNull;
      if (key != null) _model = ref.read(backendProvider).defaultModelFor(key.provider.value) ?? '';
    }
    final skills = t.skills ?? const <BotTemplateFileSkillsInner>[];
    final routines = t.routines ?? const <BotTemplateFileRoutinesInner>[];
    final memories = t.memories ?? const <BotTemplateFileMemoriesInner>[];
    return SubPage(
      title: l10n.importAgent,
      subtitle: p.kind == AgentImportPlanKindEnum.openclaw ? 'OpenClaw' : 'Hermes Agent',
      children: [
        FormNote(l10n.agentImportReviewHelp, icon: LucideIcons.listChecks),
        const SizedBox(height: AppSpace.md),
        TextField(
          key: const Key('agentImportName'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.botNameLabel),
        ),
        const SizedBox(height: AppSpace.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Text(t.personaMd.isEmpty ? l10n.agentImportNoPersona : t.personaMd, maxLines: 10, overflow: TextOverflow.ellipsis),
        ),
        for (final n in p.notes)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: FormNote(n, icon: LucideIcons.info),
          ),
        if (skills.isNotEmpty) SectionHeader(title: l10n.agentImportSkills(skills.length)),
        for (var i = 0; i < skills.length; i++)
          _check(Key('importSkill-$i'), skills[i].name, skills[i].description, _skills.contains(i), (v) => v ? _skills.add(i) : _skills.remove(i), LucideIcons.bookOpen),
        if (routines.isNotEmpty) SectionHeader(title: l10n.agentImportRoutines(routines.length)),
        for (var i = 0; i < routines.length; i++)
          _check(Key('importRoutine-$i'), routines[i].name, routines[i].scheduleCron, _routines.contains(i), (v) => v ? _routines.add(i) : _routines.remove(i), LucideIcons.clock),
        if (memories.isNotEmpty) SectionHeader(title: l10n.agentImportMemories(memories.length)),
        for (var i = 0; i < memories.length; i++)
          _check(Key('importMemory-$i'), memories[i].content, memories[i].kind.value, _memories.contains(i), (v) => v ? _memories.add(i) : _memories.remove(i), LucideIcons.brain),
        if (p.leftovers.isNotEmpty)
          SwitchListTile(
            key: const Key('agentImportFiles'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.agentImportLeftovers(p.leftovers.length)),
            subtitle: Text(p.leftovers.take(5).map((f) => f.path).join(', ')),
            value: _copyFiles,
            onChanged: (v) => setState(() => _copyFiles = v),
          ),
        if (p.skipped.isNotEmpty) FormNote(l10n.agentImportSkipped(p.skipped.map((s) => '${s.path} (${s.reason})').take(8).join(', ')), icon: LucideIcons.shieldCheck),
        SectionHeader(title: l10n.thinking0),
        DropdownButtonFormField<String>(
          key: const Key('agentImportKey'),
          initialValue: _credentialId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.modelKey),
          items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text(k.label))],
          onChanged: (v) => setState(() {
            _credentialId = v;
            _model = '';
          }),
        ),
        const SizedBox(height: AppSpace.sm),
        ModelPickerField(credentialId: _credentialId, value: _model, onChanged: (m) => setState(() => _model = m)),
        const SizedBox(height: AppSpace.lg),
        GlowButton.icon(
          key: const Key('agentImportGo'),
          onPressed: _busy || _credentialId == null || _model.isEmpty ? null : _import,
          icon: const Icon(LucideIcons.download, size: 18),
          label: Text(l10n.importAgent),
        ),
      ],
    );
  }
}

/// ChatGPT or Claude memory: copy a prompt, paste the answer back, keep what's right.
class MemoryImportSheet extends ConsumerStatefulWidget {
  const MemoryImportSheet({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<MemoryImportSheet> createState() => _MemoryImportSheetState();
}

class _MemoryImportSheetState extends ConsumerState<MemoryImportSheet> {
  final _answer = TextEditingController();
  late final Future<String> _prompt = ref.read(backendProvider).memoryImportPrompt();
  List<ImportedMemoryItem>? _items;
  final _keep = <int>{};
  var _busy = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final backend = ref.read(backendProvider);
    setState(() => _busy = true);
    if (_items == null) {
      final items = await runGuarded(context, () => backend.parseMemoryImport(_answer.text));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _items = items;
        _keep
          ..clear()
          ..addAll([for (var i = 0; i < (items?.length ?? 0); i++) i]);
      });
      return;
    }
    final keep = [
      for (var i = 0; i < _items!.length; i++)
        if (_keep.contains(i)) _items![i],
    ];
    final n = await runGuarded(context, () => backend.saveImportedMemories(widget.botId, keep));
    if (!mounted) return;
    setState(() => _busy = false);
    if (n != null) Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = _items;
    return FormSheet(
      icon: LucideIcons.brain,
      title: l10n.importMemoryTitle,
      subtitle: items == null ? l10n.importMemoryHelp : l10n.importMemoryPick,
      submitLabel: items == null ? l10n.next : l10n.save,
      submitKey: const Key('memoryImportSubmit'),
      onSubmit: _busy || (items == null ? _answer.text.trim().isEmpty : _keep.isEmpty) ? null : _submit,
      children: [
        if (items == null) ...[
          FutureBuilder<String>(
            future: _prompt,
            builder: (context, snap) => AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(snap.data ?? '…', key: const Key('memoryPrompt'), style: const TextStyle(fontSize: 13)),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const Key('copyMemoryPrompt'),
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: Text(l10n.copy),
                      onPressed: snap.data == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: snap.data!)).catchError((Object _) {});
                              showMessage(context, l10n.copied);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextField(
            key: const Key('memoryAnswer'),
            controller: _answer,
            minLines: 4,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.importMemoryPaste, alignLabelWithHint: true),
          ),
        ] else if (items.isEmpty)
          Text(l10n.importMemoryNone)
        else
          for (var i = 0; i < items.length; i++)
            CheckboxListTile(
              key: Key('memoryItem-$i'),
              contentPadding: EdgeInsets.zero,
              title: Text(items[i].content),
              subtitle: Text(items[i].kind == ImportedMemoryItemKindEnum.preference ? l10n.memoryPreference : l10n.memoryFact),
              value: _keep.contains(i),
              onChanged: (v) => setState(() => v == true ? _keep.add(i) : _keep.remove(i)),
            ),
      ],
    );
  }
}

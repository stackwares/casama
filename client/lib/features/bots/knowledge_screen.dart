import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Knowledge sources (D-125): documents this bot can search, plus the workspace's shared ones.
final knowledgeProvider = FutureProvider.autoDispose.family<List<KnowledgeSource>, String>((ref, botId) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).knowledgeSources(org.id, botId: botId);
});

typedef PickedFiles = Future<List<(String, Uint8List)>?> Function();

class KnowledgeScreen extends ConsumerWidget {
  const KnowledgeScreen({super.key, required this.botId, this.pickFiles});
  final String botId;
  final PickedFiles? pickFiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    Future<void> add() async {
      final org = ref.read(currentOrgProvider);
      if (org == null) return;
      final added = await showAdaptiveSheet<bool>(context: context, builder: (_) => _AddSource(orgId: org.id, botId: botId, pickFiles: pickFiles));
      if (added == true) ref.invalidate(knowledgeProvider(botId));
    }

    return SubPage(
      title: l10n.knowledge,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [IconButton(key: const Key('addKnowledge'), tooltip: l10n.addKnowledge, icon: const Icon(LucideIcons.plus), onPressed: add)],
      body: AsyncView(
        value: ref.watch(knowledgeProvider(botId)),
        onRetry: () => ref.invalidate(knowledgeProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.library, title: l10n.noKnowledge, message: l10n.knowledgeHelp, action: FilledButton(onPressed: add, child: Text(l10n.addKnowledge)))
            : PageColumn(
                children: [
                  FormNote(l10n.knowledgeHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final s in items)
                        GroupedTile(
                          key: Key('knowledge-${s.id}'),
                          icon: switch (s.kind) {
                            KnowledgeSourceKindEnum.website => LucideIcons.globe,
                            KnowledgeSourceKindEnum.github => LucideIcons.gitBranch,
                            KnowledgeSourceKindEnum.connection => LucideIcons.plug,
                            _ => LucideIcons.fileText,
                          },
                          title: s.name,
                          subtitle: [
                            if (s.botId == null) l10n.knowledgeShared,
                            switch (s.status) {
                              KnowledgeSourceStatusEnum.ready => l10n.knowledgeReady(s.documents, s.chunks),
                              KnowledgeSourceStatusEnum.error => s.error ?? l10n.knowledgeError,
                              KnowledgeSourceStatusEnum.syncing => l10n.knowledgeSyncing,
                              _ => l10n.knowledgePending,
                            },
                            if (s.status == KnowledgeSourceStatusEnum.ready && s.error != null) s.error!,
                          ].join(' · '),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('resync-${s.id}'),
                                tooltip: l10n.syncNow,
                                icon: const Icon(LucideIcons.refreshCw, size: 18),
                                onPressed: () async {
                                  await runGuarded(context, () => backend.resyncKnowledgeSource(s.id));
                                  ref.invalidate(knowledgeProvider(botId));
                                },
                              ),
                              IconButton(
                                key: Key('deleteKnowledge-${s.id}'),
                                tooltip: l10n.delete,
                                icon: const Icon(LucideIcons.trash2, size: 18),
                                onPressed: () async {
                                  await runGuarded(context, () => backend.deleteKnowledgeSource(s.id));
                                  ref.invalidate(knowledgeProvider(botId));
                                },
                              ),
                            ],
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

class _AddSource extends ConsumerStatefulWidget {
  const _AddSource({required this.orgId, required this.botId, this.pickFiles});
  final String orgId;
  final String botId;
  final PickedFiles? pickFiles;

  @override
  ConsumerState<_AddSource> createState() => _AddSourceState();
}

class _AddSourceState extends ConsumerState<_AddSource> {
  var _kind = CreateKnowledgeSourceRequestKindEnum.upload;
  final _name = TextEditingController();
  final _url = TextEditingController();
  List<(String, Uint8List)> _files = const [];
  var _shared = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final files = await (widget.pickFiles ??
        () async {
          final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'docx', 'md', 'txt', 'html', 'htm', 'csv']);
          return [for (final f in picked) (f.name, await f.readAsBytes())];
        })();
    if (files == null || !mounted) return;
    setState(() {
      _files = files;
      if (_name.text.isEmpty && files.isNotEmpty) _name.text = files.length == 1 ? files.first.$1 : '${files.first.$1} +${files.length - 1}';
    });
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      switch (_kind) {
        CreateKnowledgeSourceRequestKindEnum.upload => _files.isNotEmpty,
        _ => _url.text.trim().isNotEmpty,
      };

  Future<void> _submit() async {
    setState(() => _busy = true);
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).addKnowledgeSource(CreateKnowledgeSourceRequest(
            orgId: widget.orgId,
            botId: _shared ? null : widget.botId,
            kind: _kind,
            name: _name.text.trim(),
            files: _kind == CreateKnowledgeSourceRequestKindEnum.upload ? [for (final (n, b) in _files) CreateKnowledgeSourceRequestFilesInner(name: n, contentBase64: base64Encode(b))] : null,
            url: _kind == CreateKnowledgeSourceRequestKindEnum.website ? _url.text.trim() : null,
            repoUrl: _kind == CreateKnowledgeSourceRequestKindEnum.github ? _url.text.trim() : null,
          )),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final admin = ref.watch(currentOrgProvider)?.role.value == 'owner' || ref.watch(currentOrgProvider)?.role.value == 'admin';
    return FormSheet(
      icon: LucideIcons.library,
      title: l10n.addKnowledge,
      subtitle: l10n.addKnowledgeHelp,
      submitLabel: l10n.add,
      submitKey: const Key('saveKnowledge'),
      onSubmit: !_valid || _busy ? null : _submit,
      children: [
        SegmentedButton<CreateKnowledgeSourceRequestKindEnum>(
          segments: [
            ButtonSegment(value: CreateKnowledgeSourceRequestKindEnum.upload, label: Text(l10n.knowledgeFiles), icon: const Icon(LucideIcons.fileText, size: 16)),
            ButtonSegment(value: CreateKnowledgeSourceRequestKindEnum.website, label: Text(l10n.knowledgeWebsite), icon: const Icon(LucideIcons.globe, size: 16)),
            const ButtonSegment(value: CreateKnowledgeSourceRequestKindEnum.github, label: Text('GitHub'), icon: Icon(LucideIcons.gitBranch, size: 16)),
          ],
          selected: {_kind},
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        if (_kind == CreateKnowledgeSourceRequestKindEnum.upload) ...[
          OutlinedButton.icon(key: const Key('pickKnowledgeFiles'), onPressed: _pick, icon: const Icon(LucideIcons.upload, size: 18), label: Text(l10n.knowledgePickFiles)),
          for (final (n, b) in _files) Text('$n · ${(b.length / 1024).ceil()} KB'),
        ] else
          TextField(
            key: const Key('knowledgeUrl'),
            controller: _url,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: _kind == CreateKnowledgeSourceRequestKindEnum.website ? l10n.knowledgeWebsiteUrl : l10n.knowledgeRepoUrl),
          ),
        TextField(key: const Key('knowledgeName'), controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
        if (admin)
          SwitchListTile(
            key: const Key('knowledgeShared'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.knowledgeShareAll),
            value: _shared,
            onChanged: (v) => setState(() => _shared = v),
          ),
      ],
    );
  }
}

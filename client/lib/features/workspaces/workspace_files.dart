import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';

/// Routines and skills as files (D-124): export, import and git sync, for workspace admins.
final gitSyncProvider = FutureProvider.autoDispose.family<GitSyncStatus, String>((ref, orgId) => ref.watch(backendProvider).gitSync(orgId));

class WorkspaceFilesSection extends ConsumerWidget {
  const WorkspaceFilesSection({super.key, required this.orgId, this.pickZip, this.saveZip});
  final String orgId;
  final Future<Uint8List?> Function()? pickZip;
  final Future<void> Function(Uint8List bytes)? saveZip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final sync = ref.watch(gitSyncProvider(orgId)).value;

    Future<void> export() async {
      final zip = await runGuarded(context, () => backend.exportWorkspaceFiles(orgId));
      if (zip == null) return;
      await (saveZip ?? (b) => FilePicker.saveFile(fileName: 'casama-routines-and-skills.zip', bytes: b))(zip);
    }

    Future<void> import() async {
      final zip = await (pickZip ??
          () async {
            final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
            return picked.isEmpty ? null : picked.first.readAsBytes();
          })();
      if (zip == null || !context.mounted) return;
      final dry = await runGuarded(context, () => backend.importWorkspaceFiles(orgId, zip, dryRun: true));
      if (dry == null || !context.mounted) return;
      final ok = await showAdaptiveSheet<bool>(context: context, builder: (_) => _ImportPreview(result: dry));
      if (ok != true || !context.mounted) return;
      final r = await runGuarded(context, () => backend.importWorkspaceFiles(orgId, zip));
      if (r != null && context.mounted) showSuccess(context, l10n.filesImported(r.created.length, r.updated.length));
    }

    Future<void> configure() async {
      final s = await showAdaptiveSheet<GitSyncStatus>(context: context, builder: (_) => _GitSyncForm(orgId: orgId, current: sync));
      ref.invalidate(gitSyncProvider(orgId));
      if (s?.webhookSecret != null && context.mounted) await showAdaptiveSheet<void>(context: context, builder: (_) => _WebhookInfo(status: s!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.routinesAsFiles),
        FormNote(l10n.routinesAsFilesHelp),
        const SizedBox(height: AppSpace.sm),
        GroupedCard(
          children: [
            GroupedTile(key: const Key('exportFiles'), icon: LucideIcons.fileDown, title: l10n.exportFiles, onTap: export),
            GroupedTile(key: const Key('importFiles'), icon: LucideIcons.fileUp, title: l10n.importFiles, onTap: import),
            GroupedTile(
              key: const Key('gitSync'),
              icon: LucideIcons.gitBranch,
              title: l10n.gitSync,
              subtitle: sync == null || !sync.configured
                  ? l10n.gitSyncOff
                  : [
                      '${sync.repo}@${sync.branch}${sync.path.isUsable ? '/${sync.path}' : ''}',
                      if (!sync.hasToken) l10n.gitSyncNeedsToken,
                      if (sync.lastError.isUsable) sync.lastError!,
                      if (sync.lastSyncedAt != null) l10n.gitSyncLast(sync.lastSyncedAt!.toLocal().formattedDate(context)),
                    ].join(' · '),
              onTap: configure,
            ),
            if (sync?.openPrUrl != null)
              GroupedTile(icon: LucideIcons.gitPullRequest, title: l10n.gitSyncPr, subtitle: sync!.openPrUrl!),
            if (sync?.configured == true)
              GroupedTile(
                key: const Key('gitSyncNow'),
                icon: LucideIcons.refreshCw,
                title: l10n.syncNow,
                onTap: () async {
                  await runGuarded(context, () => backend.runGitSync(orgId));
                  ref.invalidate(gitSyncProvider(orgId));
                  if (context.mounted) showSuccess(context, l10n.syncQueued);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ImportPreview extends StatelessWidget {
  const _ImportPreview({required this.result});
  final WorkspaceFilesResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = result;
    return FormSheet(
      icon: LucideIcons.fileUp,
      title: l10n.importFiles,
      subtitle: l10n.filesPreview(r.created.length, r.updated.length, r.unchanged),
      submitLabel: l10n.importFilesApply,
      submitKey: const Key('applyImport'),
      onSubmit: r.created.isEmpty && r.updated.isEmpty ? null : () async => Navigator.pop(context, true),
      children: [
        for (final p in r.created) Text('+ $p'),
        for (final p in r.updated) Text('~ $p'),
        for (final e in r.errors) Text(e, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}

class _GitSyncForm extends ConsumerStatefulWidget {
  const _GitSyncForm({required this.orgId, this.current});
  final String orgId;
  final GitSyncStatus? current;

  @override
  ConsumerState<_GitSyncForm> createState() => _GitSyncFormState();
}

class _GitSyncFormState extends ConsumerState<_GitSyncForm> {
  late final _repo = TextEditingController(text: widget.current?.repo ?? '');
  late final _branch = TextEditingController(text: widget.current?.branch ?? 'main');
  late final _path = TextEditingController(text: widget.current?.path ?? '');
  late var _enabled = widget.current?.enabled ?? true;

  @override
  void dispose() {
    _repo.dispose();
    _branch.dispose();
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(_repo.text.trim());
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.gitBranch,
      title: l10n.gitSync,
      subtitle: l10n.gitSyncHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveGitSync'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !valid
          ? null
          : () async {
              final s = await runGuarded(
                context,
                () => ref.read(backendProvider).setGitSync(widget.orgId, repo: _repo.text.trim(), branch: _branch.text.trim(), path: _path.text.trim(), enabled: _enabled),
              );
              if (s != null && context.mounted) Navigator.pop(context, s);
            },
      children: [
        TextField(key: const Key('gitRepo'), controller: _repo, textInputAction: TextInputAction.next, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'owner/repository')),
        TextField(key: const Key('gitBranch'), controller: _branch, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.gitBranch)),
        TextField(key: const Key('gitPath'), controller: _path, textInputAction: TextInputAction.done, onSubmitted: (_) => submit?.call(), decoration: InputDecoration(labelText: l10n.gitFolder)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.gitSyncOn), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
        if (widget.current?.configured == true)
          TextButton(
            key: const Key('deleteGitSync'),
            onPressed: () async {
              final s = await runGuarded(context, () => ref.read(backendProvider).deleteGitSync(widget.orgId));
              if (s != null && context.mounted) Navigator.pop(context, s);
            },
            child: Text(l10n.gitSyncRemove),
          ),
      ],
    );
  }
}

class _WebhookInfo extends StatelessWidget {
  const _WebhookInfo({required this.status});
  final GitSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.webhook,
      title: l10n.gitWebhookTitle,
      subtitle: l10n.gitWebhookHelp,
      submitLabel: l10n.close,
      onSubmit: () async => Navigator.pop(context),
      children: [
        for (final (label, value) in [(l10n.gitWebhookUrl, status.webhookUrl ?? ''), (l10n.gitWebhookSecret, status.webhookSecret ?? '')])
          AppCard(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Row(children: [
              Expanded(child: SelectableText('$label\n$value', key: Key('webhook-$label'))),
              IconButton(icon: const Icon(LucideIcons.copy, size: 18), onPressed: () => Clipboard.setData(ClipboardData(text: value)).catchError((Object _) {})),
            ]),
          ),
      ],
    );
  }
}

import 'package:casama_sdk/casama_sdk.dart'
    show
        Bot,
        ExportPackRequest,
        ExportPackRequestLook,
        ExportPackRequestLookTypeEnum,
        PackExport,
        PackShare,
        SharePackRequest;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'pack_files.dart';

/// A pack can bring at most five bots (docs/PLUGINS-AND-PACKS-PLAN.md A.4).
const sharePackMaxBots = 5;

/// This device's look as a gallery theme document, or null when it can't be one (a color scheme
/// from the gallery or a photo background).
Map<String, Object?>? shareableLook(Appearance a) {
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(a.schemeId)) return null;
  final w = a.wallpaper;
  if (w.photo != null) return null;
  return {
    'v': 2,
    'scheme': a.schemeId,
    'headingFont': a.headingFont,
    'bodyFont': a.bodyFont,
    'wallpaper': {'pattern': w.pattern.name, 'palette': w.palette.name, 'intensity': w.intensity},
  };
}

/// Workspace settings → Share as pack (docs/PLUGINS-AND-PACKS-PLAN.md E): pick bots, workspace
/// skills and this device's look, check for lines that look like keys, then get a link (or a file).
class SharePackScreen extends ConsumerStatefulWidget {
  const SharePackScreen({super.key, this.botId});

  /// A bot to start with ticked.
  final String? botId;

  @override
  ConsumerState<SharePackScreen> createState() => _SharePackScreenState();
}

class _SharePackScreenState extends ConsumerState<SharePackScreen> {
  late final _bots = <String>{?widget.botId};
  final _skills = <String>{};
  final _name = TextEditingController();
  final _summary = TextEditingController();
  var _look = false;
  var _busy = false;

  /// Lines that look like keys, once checked; null before the check.
  List<String>? _findings;
  PackExport? _export;
  PackShare? _share;
  var _stopped = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _summary.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    super.dispose();
  }

  ExportPackRequest _request() {
    final doc = _look ? shareableLook(ref.read(appearanceProvider)) : null;
    return ExportPackRequest(
      name: _name.text.trim(),
      summary: _summary.text.trim(),
      botIds: _bots.toList(),
      workspaceSkillIds: _skills.isEmpty ? null : _skills.toList(),
      look: doc == null
          ? null
          : ExportPackRequestLook(type: ExportPackRequestLookTypeEnum.theme, name: _name.text.trim(), document: doc),
    );
  }

  Future<void> _check() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    setState(() => _busy = true);
    final out = await runGuarded(context, () => ref.read(backendProvider).exportPack(org.id, _request()));
    if (!mounted) return;
    if (out == null) return setState(() => _busy = false);
    _export = out;
    if (out.findings.isNotEmpty) {
      setState(() {
        _busy = false;
        _findings = [for (final f in out.findings) context.l10n.sharePackFinding(f.path, f.line, f.what)];
      });
      return;
    }
    await _doShare(ignore: false);
  }

  Future<void> _doShare({required bool ignore}) async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final r = _request();
    setState(() => _busy = true);
    try {
      final share = await ref
          .read(backendProvider)
          .sharePack(
            org.id,
            SharePackRequest(
              name: r.name,
              summary: r.summary,
              botIds: r.botIds,
              workspaceSkillIds: r.workspaceSkillIds,
              look: r.look,
              ignoreFindings: ignore ? true : null,
            ),
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _share = share;
        _findings = null;
      });
    } on PackError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'pack_has_secrets') {
          _findings = [for (final x in e.errors) '${x.path}: ${x.message}'];
        }
      });
      if (e.code != 'pack_has_secrets') showError(context, e);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, e, st);
    }
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) showSuccess(context, context.l10n.sharePackLinkCopied);
  }

  Future<void> _saveFile() async {
    final export = _export;
    if (export == null) return;
    final name = export.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    try {
      await FilePicker.saveFile(
        fileName: '${name.isEmpty ? 'pack' : name}.zip',
        bytes: packZip(export.name, export.files),
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _stop(String token) async {
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).revokePackShare(token);
      return true;
    });
    if (ok == true && mounted) {
      setState(() => _stopped = true);
      showSuccess(context, context.l10n.sharePackStopped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final share = _share;
    final findings = _findings;
    return SubPage(
      title: l10n.sharePackTitle,
      children: share != null
          ? _linkView(context, share)
          : findings != null
          ? _findingsView(context, findings)
          : _form(context),
    );
  }

  List<Widget> _form(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final skills = [
      for (final s in ref.watch(skillsProvider).value ?? const <SkillView>[])
        if (s.botId == null) s,
    ];
    final look = shareableLook(ref.watch(appearanceProvider));
    final ready =
        !_busy &&
        (_bots.isNotEmpty || _skills.isNotEmpty) &&
        _name.text.trim().isNotEmpty &&
        _summary.text.trim().isNotEmpty;
    return [
      FormNote(l10n.sharePackHelp, icon: LucideIcons.lock),
      SectionHeader(title: l10n.sharePackBots, count: '${_bots.length}/$sharePackMaxBots'),
      Text(l10n.sharePackBotsHelp, style: context.textTheme.bodySmall),
      const SizedBox(height: AppSpace.xs),
      GroupedCard(
        children: [
          for (final b in bots)
            CheckboxListTile(
              key: Key('shareBot-${b.id}'),
              value: _bots.contains(b.id),
              onChanged: !_bots.contains(b.id) && _bots.length >= sharePackMaxBots
                  ? null
                  : (v) => setState(() => v == true ? _bots.add(b.id) : _bots.remove(b.id)),
              title: Text(b.name),
            ),
        ],
      ),
      if (skills.isNotEmpty) ...[
        SectionHeader(title: l10n.sharePackSkills),
        GroupedCard(
          children: [
            for (final s in skills)
              CheckboxListTile(
                key: Key('shareSkill-${s.id}'),
                value: _skills.contains(s.id),
                onChanged: (v) => setState(() => v == true ? _skills.add(s.id) : _skills.remove(s.id)),
                title: Text(s.name),
                subtitle: s.description.isEmpty
                    ? null
                    : Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ],
      const SizedBox(height: AppSpace.md),
      TextField(
        key: const Key('shareName'),
        controller: _name,
        maxLength: 64,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: l10n.sharePackName),
      ),
      TextField(
        key: const Key('shareSummary'),
        controller: _summary,
        maxLength: 160,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: l10n.sharePackSummary),
      ),
      if (look != null)
        SwitchListTile(
          key: const Key('shareLook'),
          contentPadding: EdgeInsets.zero,
          value: _look,
          onChanged: (v) => setState(() => _look = v),
          title: Text(l10n.sharePackLook),
        ),
      const SizedBox(height: AppSpace.md),
      FilledButton.icon(
        key: const Key('shareCheck'),
        onPressed: ready ? _check : null,
        icon: _busy
            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(LucideIcons.shieldCheck, size: 18),
        label: Text(l10n.sharePackCheck),
      ),
      const SizedBox(height: AppSpace.xl),
    ];
  }

  List<Widget> _findingsView(BuildContext context, List<String> findings) {
    final l10n = context.l10n;
    return [
      FormNote(
        l10n.sharePackFindingsHelp,
        key: const Key('shareFindings'),
        icon: LucideIcons.shieldAlert,
        color: context.colorScheme.error,
      ),
      SectionHeader(title: l10n.sharePackFindingsTitle, count: '${findings.length}'),
      GroupedCard(
        children: [for (final f in findings) GroupedTile(icon: LucideIcons.keyRound, title: f)],
      ),
      const SizedBox(height: AppSpace.md),
      Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.xs,
        children: [
          OutlinedButton(
            key: const Key('shareGoBack'),
            onPressed: _busy ? null : () => setState(() => _findings = null),
            child: Text(l10n.sharePackGoBack),
          ),
          FilledButton(
            key: const Key('shareAnyway'),
            onPressed: _busy ? null : () => _doShare(ignore: true),
            child: Text(l10n.sharePackAnyway),
          ),
        ],
      ),
    ];
  }

  List<Widget> _linkView(BuildContext context, PackShare share) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMd(l10n.localeName).format(share.expiresAt.toLocal());
    return [
      SectionHeader(title: l10n.sharePackLinkTitle),
      AppCard(
        child: SelectableText(share.url, key: const Key('shareUrl'), style: context.textTheme.bodyLarge),
      ),
      const SizedBox(height: AppSpace.xs),
      Text(_stopped ? l10n.sharePackStopped : l10n.sharePackLinkHelp(date), style: context.textTheme.bodySmall),
      const SizedBox(height: AppSpace.md),
      if (!_stopped)
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xs,
          children: [
            FilledButton.icon(
              key: const Key('shareCopy'),
              onPressed: () => _copy(share.url),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text(l10n.copyLink),
            ),
            Builder(
              builder: (b) => OutlinedButton.icon(
                key: const Key('shareShare'),
                onPressed: () => shareText(share.url, origin: shareOrigin(b)),
                icon: const Icon(LucideIcons.share, size: 18),
                label: Text(l10n.sharePackShare),
              ),
            ),
            if (_export != null)
              OutlinedButton.icon(
                key: const Key('shareSaveFile'),
                onPressed: _saveFile,
                icon: const Icon(LucideIcons.fileArchive, size: 18),
                label: Text(l10n.sharePackSaveFile),
              ),
            TextButton(
              key: const Key('shareStop'),
              onPressed: () => _stop(share.token),
              child: Text(l10n.sharePackStop),
            ),
          ],
        ),
    ];
  }
}

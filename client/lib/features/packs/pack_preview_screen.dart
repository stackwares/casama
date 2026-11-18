import 'dart:typed_data';

import 'package:casama_sdk/casama_sdk.dart' show PackFileInput, PackPreview;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'pack_files.dart';
import 'pack_install.dart';
import 'pack_logic.dart';
import 'pack_parts.dart';

/// Where the pack preview page lives, for a GitHub link, a reviewed pack or a shared link.
String packPreviewLocation({String? url, String? commit, String? galleryId}) => Uri(
  path: '/settings/gallery/packs/add',
  queryParameters: {'url': ?url, 'commit': ?commit, 'gallery_id': ?galleryId},
).toString();

String packShareLocation(String token) => '/settings/gallery/packs/share/${Uri.encodeComponent(token)}';

/// A pack before anything exists (docs/PLUGINS-AND-PACKS-PLAN.md C.13–15): who made it, where it
/// lives, everything it adds, and what it can reach, with Add pack to start the wizard.
class PackPreviewScreen extends ConsumerStatefulWidget {
  const PackPreviewScreen({super.key, required this.from});
  final PackFrom from;

  @override
  ConsumerState<PackPreviewScreen> createState() => _PackPreviewScreenState();
}

class _PackPreviewScreenState extends ConsumerState<PackPreviewScreen> {
  AsyncValue<PackPreview> _preview = const AsyncValue.loading();
  var _started = false;

  @override
  void initState() {
    super.initState();
    // Once the workspace is known (it may still be loading when the page opens).
    ref.listenManual(currentOrgProvider, (_, org) {
      if (_started || org == null) return;
      _started = true;
      _load(org.id);
    }, fireImmediately: true);
  }

  Future<void> _load(String orgId) async {
    if (!_hasSource) return;
    setState(() => _preview = const AsyncValue.loading());
    final backend = ref.read(backendProvider);
    final token = widget.from.shareToken;
    final next = await AsyncValue.guard(
      () async =>
          token != null ? (await backend.packShare(token)).preview : await backend.previewPack(orgId, widget.from),
    );
    if (mounted) setState(() => _preview = next);
  }

  Future<void> _add(PackPreview p) async {
    final done = await showPackInstall(context, ref, preview: p, from: widget.from);
    if (done && mounted) {
      final org = ref.read(currentOrgProvider);
      if (org != null) _load(org.id);
    }
  }

  bool get _hasSource {
    final f = widget.from;
    bool given(String? v) => v != null && v.trim().isNotEmpty;
    return given(f.url) || given(f.galleryId) || given(f.shareToken) || (f.files?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Opened without a pack (a bare /pack link): offer the ways to add one instead of an error.
    if (!_hasSource) {
      return SubPage(
        title: l10n.packsShelfTitle,
        body: const PageColumn(children: [PackAddTiles(key: Key('packNoSource'))]),
      );
    }
    final p = _preview.value;
    return SubPage(
      title: p?.title ?? l10n.packsShelfTitle,
      body: AsyncView<PackPreview>(
        value: _preview,
        onRetry: () {
          final org = ref.read(currentOrgProvider);
          if (org != null) _load(org.id);
        },
        data: (p) => PageColumn(
          children: [
            PackHeader(preview: p),
            const SizedBox(height: AppSpace.md),
            if (packPreviewContents(l10n, p) case final line when line.isNotEmpty)
              Text(line, key: const Key('packContentsLine'), style: context.textTheme.labelLarge),
            if (p.description.isNotEmpty && p.description != p.summary) ...[
              const SizedBox(height: AppSpace.xs),
              Text(p.description, style: context.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpace.md),
            if (p.installed != null) ...[
              FormNote(l10n.packAlreadyHere, key: const Key('packAlreadyHere'), icon: LucideIcons.packageCheck),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('packSeeInstalled'),
                  onPressed: () => context.push('/settings/gallery/packs'),
                  child: Text(l10n.packOpenInstalled),
                ),
              ),
            ] else
              FilledButton.icon(
                key: const Key('packAdd'),
                onPressed: () => _add(p),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(l10n.packAdd),
              ),
            PackContentsList(preview: p),
            SectionHeader(title: l10n.packReachTitle),
            PackReachCard(reach: p.reach, reviewed: p.reviewed, warnings: p.warnings),
            const SizedBox(height: AppSpace.xl),
          ],
        ),
      ),
    );
  }
}

/// Asks for a GitHub link to a pack and opens its preview; "Add from a file" picks a .zip.
Future<void> showAddPackFromLink(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final answer = await showAdaptiveSheet<String>(
    context: context,
    dialogMaxWidth: 520,
    builder: (_) => const _AddFromLinkSheet(),
  );
  if (answer == null || !context.mounted) return;
  if (answer == _fileChoice) {
    await addPackFromFile(context);
    return;
  }
  router.push(packPreviewLocation(url: answer));
}

const _fileChoice = '\u0000file';

/// Picks a pack's .zip, reads its files and opens the preview for them.
Future<void> addPackFromFile(BuildContext context, {Future<Uint8List?> Function()? pick}) async {
  final l10n = context.l10n;
  final router = GoRouter.of(context);
  Uint8List? bytes;
  try {
    bytes = await (pick ?? _pickZip)();
  } catch (e) {
    if (context.mounted) showError(context, e);
    return;
  }
  if (bytes == null || !context.mounted) return;
  final files = packFilesFromZip(bytes);
  if (files is! List<PackFileInput>) {
    showMessage(context, files == PackFileProblem.tooBig ? l10n.packFileTooBig : l10n.packFileUnreadable);
    return;
  }
  router.push('/settings/gallery/packs/add', extra: PackFrom(files: files));
}

Future<Uint8List?> _pickZip() async {
  final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
  if (picked.isEmpty) return null;
  return picked.first.readAsBytes();
}

class _AddFromLinkSheet extends StatefulWidget {
  const _AddFromLinkSheet();

  @override
  State<_AddFromLinkSheet> createState() => _AddFromLinkSheetState();
}

class _AddFromLinkSheetState extends State<_AddFromLinkSheet> {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = packGitHubUrl(_url.text);
    void submit() => Navigator.of(context).pop(url);
    return FormSheet(
      key: const Key('packAddFromLinkSheet'),
      icon: LucideIcons.link,
      title: l10n.packAddFromLink,
      subtitle: l10n.packAddFromLinkHelp,
      submitLabel: l10n.preview,
      submitKey: const Key('packLinkPreview'),
      onSubmit: url == null ? null : submit,
      footer: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const Key('packAddFromFile'),
          onPressed: () => Navigator.of(context).pop(_fileChoice),
          icon: const Icon(LucideIcons.fileArchive, size: 18),
          label: Text(l10n.packAddFromFile),
        ),
      ),
      children: [
        TextField(
          key: const Key('packLinkField'),
          controller: _url,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (url != null) submit();
          },
          decoration: InputDecoration(labelText: l10n.packLinkLabel, hintText: 'https://github.com/owner/repo'),
        ),
      ],
    );
  }
}

/// The two ways in that aren't the shelf, as rows for the gallery page.
class PackAddTiles extends ConsumerWidget {
  const PackAddTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GroupedCard(
      children: [
        GroupedTile(
          key: const Key('packAddFromLinkTile'),
          icon: LucideIcons.link,
          title: l10n.packAddFromLink,
          subtitle: l10n.packAddFromLinkHelp,
          showChevron: true,
          onTap: () => showAddPackFromLink(context, ref),
        ),
        GroupedTile(
          key: const Key('packAddFromFileTile'),
          icon: LucideIcons.fileArchive,
          title: l10n.packAddFromFile,
          subtitle: l10n.packAddFromFileHelp,
          showChevron: true,
          onTap: () => addPackFromFile(context),
        ),
      ],
    );
  }
}

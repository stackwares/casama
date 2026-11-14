import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
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
import '../chat/media/chat_audio.dart';
import '../chat/media/chat_video.dart';
import '../files/file_preview.dart';
import '../pages/pages_screen.dart' show pageOpenerProvider;
import '../projects/projects_screen.dart' show projectsProvider;
import 'creation_tile.dart';
import 'library_providers.dart';

/// The file name a creation's bytes go out under: its title, with the extension its type wants.
String creationFileName(Creation c) {
  final title = c.title.trim().isEmpty ? c.id : c.title.trim();
  if (RegExp(r'\.[A-Za-z0-9]{1,5}$').hasMatch(title)) return title;
  final ext = switch (c.mime ?? '') {
    'image/png' => 'png',
    'image/jpeg' => 'jpg',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    'video/mp4' => 'mp4',
    'video/webm' => 'webm',
    'audio/mpeg' => 'mp3',
    'audio/wav' || 'audio/x-wav' => 'wav',
    'application/pdf' => 'pdf',
    _ => switch (c.kind) {
      CreationKind.image => 'png',
      CreationKind.video => 'mp4',
      CreationKind.audio => 'mp3',
      CreationKind.page => 'html',
      _ => '',
    },
  };
  return ext.isEmpty ? title : '$title.$ext';
}

/// One creation on its own page (phones, narrow windows): `/library/:id`.
class CreationDetailScreen extends ConsumerWidget {
  const CreationDetailScreen({super.key, required this.creationId});
  final String creationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(creationProvider(creationId)).value;
    return SubPage(
      title: c == null
          ? context.l10n.library
          : creationKindLabel(context.l10n, Creation.fromJson(c.toJson())),
      body: CreationDetailView(creationId: creationId),
    );
  }
}

/// What one creation shows (LIBRARY-PLAN §5.3): the preview, the title (tap to rename), who made
/// it and when, the main action for its kind, Change it, a menu (rename, pin, PDF, delete), where
/// it came from, and what was made alongside it. A full page on phones, a pane beside the grid on
/// wide windows ([pane]).
class CreationDetailView extends ConsumerWidget {
  const CreationDetailView({
    super.key,
    required this.creationId,
    this.pane = false,
    this.onClose,
    this.onChanged,
  });
  final String creationId;
  final bool pane;
  final VoidCallback? onClose;

  /// Tells the list a creation was renamed, pinned or deleted, so the grid follows at once.
  final void Function(Creation c, {bool removed})? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(creationProvider(creationId));
    return AsyncView(
      value: detail,
      onRetry: () => ref.invalidate(creationProvider(creationId)),
      loading: const Center(child: CircularProgressIndicator()),
      data: (d) => _Detail(
        detail: d,
        pane: pane,
        onClose: onClose,
        onChanged: onChanged,
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({
    required this.detail,
    required this.pane,
    this.onClose,
    this.onChanged,
  });
  final CreationDetail detail;
  final bool pane;
  final VoidCallback? onClose;
  final void Function(Creation c, {bool removed})? onChanged;

  Creation get c => Creation.fromJson(detail.toJson());

  Future<void> _markOpened(WidgetRef ref) async {
    try {
      await ref.read(backendProvider).updateCreation(c.id, opened: true);
    } catch (_) {}
  }

  /// The main action for the kind: open a page in the browser, view a picture or video, or hand a
  /// document or file to the system.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    unawaited(_markOpened(ref));
    final creation = c;
    final backend = ref.read(backendProvider);
    if (creation.kind == CreationKind.page && creation.pageId != null) {
      final url = await runGuarded(
        context,
        () => backend.pageViewLink(creation.pageId!),
      );
      if (url != null) await ref.read(pageOpenerProvider)(Uri.parse(url));
      return;
    }
    if (creation.mediaId != null) {
      await showComputerFile(
        context,
        computerId: '',
        path: 'media:${creation.mediaId}',
        name: creationFileName(creation),
      );
      return;
    }
    final bytes = await runGuarded(
      context,
      () => backend.creationContent(creation.id),
    );
    if (bytes != null && context.mounted) {
      await openFileBytes(context, creationFileName(creation), bytes);
    }
  }

  Future<void> _pdf(BuildContext context, WidgetRef ref) async {
    final pageId = c.pageId;
    if (pageId == null) return;
    final url = await runGuarded(
      context,
      () => ref.read(backendProvider).pageViewLink(pageId, pdf: true),
    );
    if (url != null) await ref.read(pageOpenerProvider)(Uri.parse(url));
  }

  /// Change it (§5.3): the chat it came from (else the bot's General) with the composer filled in.
  void _changeIt(BuildContext context) {
    final creation = c;
    final bot = creation.botId;
    if (bot == null) return;
    final draft = context.l10n.creationChangeDraft(creation.title);
    context.go(
      Uri(
        path: '/bots/$bot/chat',
        queryParameters: {'c': ?creation.conversationId, 'draft': draft},
      ).toString(),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final title = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => _RenameSheet(initial: c.title),
    );
    if (title == null ||
        title.trim().isEmpty ||
        title.trim() == c.title ||
        !context.mounted) {
      return;
    }
    final updated = await runGuarded(
      context,
      () => ref.read(backendProvider).updateCreation(c.id, title: title.trim()),
    );
    if (updated == null) return;
    ref.invalidate(creationProvider(c.id));
    onChanged?.call(updated);
  }

  Future<void> _pin(BuildContext context, WidgetRef ref) async {
    final updated = await runGuarded(
      context,
      () => ref.read(backendProvider).updateCreation(c.id, pinned: !c.pinned),
    );
    if (updated == null) return;
    ref.invalidate(creationProvider(c.id));
    onChanged?.call(updated);
  }

  /// Files it under a project, or takes it out of one (D-295).
  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final picked = await showAdaptiveSheet<_ProjectPick>(
      context: context,
      builder: (_) => _MoveToProject(current: c.projectId),
    );
    if (picked == null || picked.id == c.projectId || !context.mounted) return;
    final updated = await runGuarded(
      context,
      () => ref.read(backendProvider).moveCreation(c.id, picked.id),
    );
    if (updated == null) return;
    ref
      ..invalidate(creationProvider(c.id))
      ..invalidate(projectsProvider);
    onChanged?.call(updated);
  }

  /// Who can see it (D-281): private, the workspace, or anyone with a link. Public asks first and
  /// shows the link once, copied.
  Future<void> _visibility(
    BuildContext context,
    WidgetRef ref,
    CreationVisibilityEnum v,
  ) async {
    final l10n = context.l10n;
    if (v == CreationVisibilityEnum.public) {
      final ok = await showConfirm(
        context: context,
        title: l10n.pageMakePublicTitle,
        message: l10n.pageMakePublicBody,
        confirmLabel: l10n.pageMakePublic,
        icon: LucideIcons.globe,
        confirmKey: const Key('confirmPublic'),
      );
      if (!ok || !context.mounted) return;
    }
    final updated = await runGuarded(
      context,
      () => ref.read(backendProvider).updateCreation(c.id, visibility: v),
    );
    if (updated == null) return;
    ref.invalidate(creationProvider(c.id));
    onChanged?.call(updated);
    final link = updated.publicUrl;
    if (link != null && context.mounted) {
      unawaited(
        Clipboard.setData(ClipboardData(text: link)).catchError((Object _) {}),
      );
      await showAdaptiveSheet<void>(
        context: context,
        builder: (sheet) => FormSheet(
          icon: LucideIcons.globe,
          title: l10n.pagePublicLinkTitle,
          subtitle: l10n.pagePublicLinkBody,
          submitLabel: l10n.close,
          showCancel: false,
          onSubmit: () => Navigator.pop(sheet),
          children: [SelectableText(link, key: const Key('creationPublicUrl'))],
        ),
      );
    }
  }

  /// Deleting hides it at once with Undo; the server keeps it 30 days (D-274).
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final creation = c;
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final done = await runGuarded(context, () async {
      await backend.deleteCreation(creation.id);
      return true;
    });
    if (done != true || !context.mounted) return;
    onChanged?.call(creation, removed: true);
    if (!pane && context.canPop()) context.pop();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.creationDeleted(creation.title)),
        action: SnackBarAction(
          key: const Key('undoDeleteCreation'),
          label: l10n.undo,
          onPressed: () async {
            await backend.restoreCreation(creation.id);
            onChanged?.call(creation);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final creation = c;
    final mainLabel = switch (creation.kind) {
      CreationKind.page =>
        (creation.label ?? '').toLowerCase() == 'game'
            ? l10n.creationPlay
            : l10n.creationOpen,
      CreationKind.image ||
      CreationKind.video ||
      CreationKind.audio when creation.mediaId != null => l10n.creationView,
      _ => l10n.creationOpen,
    };
    final made = [
      if ((creation.botName ?? '').isNotEmpty)
        l10n.creationMadeBy(creation.botName!),
      relativeTime(creation.createdAt, context),
      if (creation.version > 1) l10n.creationVersion(creation.version),
      switch (creation.visibility) {
        CreationVisibilityEnum.public => l10n.pagePublic,
        CreationVisibilityEnum.workspace => l10n.pageWorkspace,
        _ => l10n.pagePrivate,
      },
    ].join(' · ');
    final media = creation.mediaId == null
        ? null
        : AttachmentRef(
            path: 'media:${creation.mediaId}',
            name: creationFileName(creation),
            mimeType: creation.mime ?? '',
            size: creation.size,
            width: creation.width,
            height: creation.height,
            durationS: creation.durationS?.toDouble(),
          );
    final Widget preview = switch (creation.kind) {
      CreationKind.video when media != null => Center(
        child: ChatVideo(attachment: media, maxWidth: 520),
      ),
      CreationKind.audio when media != null => ChatAudio(attachment: media),
      _ => ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: AspectRatio(
          aspectRatio: creation.kind == CreationKind.page ? 16 / 10 : 4 / 3,
          child: Material(
            color: scheme.surfaceContainerLow,
            child: InkWell(
              key: const Key('creationPreview'),
              onTap: () => _open(context, ref),
              child: CreationCover(creation: creation, big: true),
            ),
          ),
        ),
      ),
    };
    return ListView(
      key: Key('creationDetail-${creation.id}'),
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        pane ? AppSpace.md : AppSpace.xs,
        AppSpace.gutter,
        AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (pane && onClose != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              key: const Key('closeCreationPane'),
              tooltip: l10n.close,
              icon: const Icon(LucideIcons.x),
              onPressed: onClose,
            ),
          ),
        preview,
        const SizedBox(height: AppSpace.md),
        InkWell(
          key: const Key('creationTitle'),
          borderRadius: BorderRadius.circular(AppRadius.icon),
          onTap: creation.canChange ? () => _rename(context, ref) : null,
          child: Text(
            creation.title,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          made,
          key: const Key('creationMade'),
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: const Key('creationOpen'),
              onPressed: () => _open(context, ref),
              icon: Icon(
                creation.kind == CreationKind.page
                    ? LucideIcons.externalLink
                    : LucideIcons.eye,
                size: 18,
              ),
              label: Text(mainLabel),
            ),
            if (creation.botId != null)
              OutlinedButton.icon(
                key: const Key('creationChangeIt'),
                onPressed: () => _changeIt(context),
                icon: const Icon(LucideIcons.wandSparkles, size: 18),
                label: Text(l10n.creationChangeIt),
              ),
            MenuAnchor(
              menuChildren: [
                if (creation.canChange)
                  MenuItemButton(
                    key: const Key('creationRename'),
                    leadingIcon: const Icon(LucideIcons.pencil, size: 20),
                    onPressed: () => _rename(context, ref),
                    child: Text(l10n.renameTopic),
                  ),
                MenuItemButton(
                  key: const Key('creationPin'),
                  leadingIcon: Icon(
                    creation.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                    size: 20,
                  ),
                  onPressed: () => _pin(context, ref),
                  child: Text(creation.pinned ? l10n.unpin : l10n.pin),
                ),
                if (creation.canChange)
                  SubmenuButton(
                    key: const Key('creationVisibility'),
                    leadingIcon: Icon(switch (creation.visibility) {
                      CreationVisibilityEnum.public => LucideIcons.globe,
                      CreationVisibilityEnum.workspace => LucideIcons.users,
                      _ => LucideIcons.lock,
                    }, size: 20),
                    menuChildren: [
                      for (final (v, label) in [
                        (CreationVisibilityEnum.private, l10n.pagePrivate),
                        (CreationVisibilityEnum.workspace, l10n.pageWorkspace),
                        (CreationVisibilityEnum.public, l10n.pagePublic),
                      ])
                        MenuItemButton(
                          key: Key('creationVisibility-${v.value}'),
                          leadingIcon: Icon(
                            creation.visibility == v ? LucideIcons.check : null,
                            size: 18,
                          ),
                          onPressed: () => _visibility(context, ref, v),
                          child: Text(label),
                        ),
                    ],
                    child: Text(l10n.creationWhoCanSee),
                  ),
                if (creation.canChange)
                  MenuItemButton(
                    key: const Key('creationMove'),
                    leadingIcon: const Icon(LucideIcons.folderInput, size: 20),
                    onPressed: () => _move(context, ref),
                    child: Text(l10n.creationMoveToProject),
                  ),
                if (creation.kind == CreationKind.page &&
                    creation.pageId != null)
                  MenuItemButton(
                    key: const Key('creationPdf'),
                    leadingIcon: const Icon(LucideIcons.fileDown, size: 20),
                    onPressed: () => _pdf(context, ref),
                    child: Text(l10n.exportPdf),
                  ),
                if (creation.canChange) ...[
                  const Divider(),
                  MenuItemButton(
                    key: const Key('creationDelete'),
                    leadingIcon: Icon(
                      LucideIcons.trash2,
                      size: 20,
                      color: scheme.error,
                    ),
                    onPressed: () => _delete(context, ref),
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
              ],
              builder: (context, controller, _) => IconButton(
                key: const Key('creationMenu'),
                tooltip: l10n.moreActions,
                icon: const Icon(LucideIcons.ellipsis),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            if (creation.projectId != null)
              GroupedTile(
                key: const Key('creationProject'),
                icon: LucideIcons.folderKanban,
                title: creation.projectTitle ?? l10n.creationProjectLabel,
                subtitle: l10n.creationProjectLabel,
                onTap: () => context.push('/projects/${creation.projectId}'),
              ),
            if (creation.botId != null)
              GroupedTile(
                key: const Key('creationFrom'),
                icon: LucideIcons.messageCircle,
                title: creation.conversationId == null
                    ? l10n.creationFromBot(creation.botName ?? '')
                    : l10n.creationFromChat(creation.botName ?? ''),
                subtitle: l10n.creationFromHelp,
                onTap: () => context.go(
                  Uri(
                    path: '/bots/${creation.botId}/chat',
                    queryParameters: {'c': ?creation.conversationId},
                  ).toString(),
                ),
              ),
            GroupedTile(
              icon: LucideIcons.info,
              title: l10n.creationDetails,
              subtitle: [
                creationKindName(l10n, creation.kind),
                if (creation.size > 0)
                  formatBytes(creation.size, l10n.localeName),
                if (creation.width != null && creation.height != null)
                  '${creation.width} × ${creation.height}',
              ].join(' · '),
              showChevron: false,
            ),
          ],
        ),
        if (detail.siblings.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.creationAlongside,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          SizedBox(
            height:
                140 * 3 / 4 + 64 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              key: const Key('creationSiblings'),
              scrollDirection: Axis.horizontal,
              itemCount: detail.siblings.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
              itemBuilder: (context, i) => SizedBox(
                width: 140,
                child: CreationTile(
                  creation: detail.siblings[i],
                  onTap: () =>
                      context.push('/library/${detail.siblings[i].id}'),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// What the Move to Project sheet returns: a project, or none (taken out of its project).
class _ProjectPick {
  const _ProjectPick(this.id);
  final String? id;
}

/// The projects a creation can be filed under, with the one it's in ticked.
class _MoveToProject extends ConsumerWidget {
  const _MoveToProject({required this.current});
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final projects = (ref.watch(projectsProvider).value ?? const <Project>[])
        .where((p) => p.status != ProjectStatus.cancelled || p.id == current)
        .toList();
    return FormSheet(
      icon: LucideIcons.folderInput,
      title: l10n.creationMoveToProject,
      submitLabel: l10n.close,
      showCancel: false,
      onSubmit: () => Navigator.pop(context),
      children: [
        GroupedCard(
          children: [
            for (final p in projects)
              GroupedTile(
                key: Key('moveToProject-${p.id}'),
                icon: LucideIcons.folderKanban,
                title: p.title,
                selected: p.id == current,
                showChevron: false,
                trailing: p.id == current
                    ? const Icon(LucideIcons.check, size: 18)
                    : null,
                onTap: () => Navigator.pop(context, _ProjectPick(p.id)),
              ),
            if (current != null || projects.isEmpty)
              GroupedTile(
                key: const Key('moveToProject-none'),
                icon: LucideIcons.folderMinus,
                title: l10n.creationNoProject,
                showChevron: false,
                onTap: current == null
                    ? null
                    : () => Navigator.pop(context, const _ProjectPick(null)),
              ),
          ],
        ),
      ],
    );
  }
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});
  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.pencil,
      title: l10n.renameTopic,
      submitLabel: l10n.save,
      submitKey: const Key('saveCreationTitle'),
      onSubmit: _text.text.trim().isEmpty
          ? null
          : () => Navigator.pop(context, _text.text.trim()),
      children: [
        TextField(
          key: const Key('creationTitleField'),
          controller: _text,
          autofocus: true,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ],
    );
  }
}

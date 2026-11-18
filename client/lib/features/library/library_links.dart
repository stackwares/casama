import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../chat/chat_controller.dart' show ToolEntry, ToolStatus;

/// The Library item for a page or a picture or video a chat shows, or null when it isn't found.
/// The chat's parts carry the page or media id, not the creation's, so it is looked up: by title
/// first (a page), then among the newest of that kind.
Future<Creation?> findCreation(
  WidgetRef ref, {
  String? pageId,
  String? mediaId,
  String? title,
  CreationKind? kind,
}) async {
  final orgId = ref.read(currentOrgIdProvider);
  if (orgId == null || (pageId == null && mediaId == null)) return null;
  final backend = ref.read(backendProvider);
  bool hit(Creation c) =>
      (pageId != null && c.pageId == pageId) ||
      (mediaId != null && c.mediaId == mediaId);
  final k = pageId != null ? CreationKind.page : kind;
  final words = title?.trim() ?? '';
  try {
    if (words.isNotEmpty) {
      final byTitle = (await backend.creations(
        orgId,
        kind: k,
        q: words,
        limit: 100,
      )).items.where(hit).firstOrNull;
      if (byTitle != null) return byTitle;
    }
    return (await backend.creations(
      orgId,
      kind: k,
      limit: 100,
    )).items.where(hit).firstOrNull;
  } catch (_) {
    return null;
  }
}

/// Show in Library (LIBRARY-PLAN §5.4): opens the item, or the Library on its kind when it can't
/// be found.
Future<void> showInLibrary(
  BuildContext context,
  WidgetRef ref, {
  String? pageId,
  String? mediaId,
  String? title,
  CreationKind? kind,
}) async {
  final router = GoRouter.maybeOf(context);
  final c = await findCreation(
    ref,
    pageId: pageId,
    mediaId: mediaId,
    title: title,
    kind: kind,
  );
  if (router == null) return;
  if (c != null) {
    router.pushOnce('/library/${c.id}');
  } else {
    final k = pageId != null ? CreationKind.page : kind;
    router.pushOnce(
      Uri(path: '/library', queryParameters: {'kind': ?k?.value}).toString(),
    );
  }
}

/// The page a finished `pages.publish` step made or replaced: its id when the step knows it (a
/// republish names `page_id`; the result says `(page <id>, …)`) and its title. Null when none of
/// [steps] published a page.
({String? pageId, String? title})? publishedPageOf(Iterable<ToolEntry> steps) {
  final step = steps
      .where((t) => t.tool == 'pages.publish' && t.status == ToolStatus.done)
      .lastOrNull;
  if (step == null) return null;
  final fromArgs = step.args['page_id'];
  final id = fromArgs is String && fromArgs.isNotEmpty
      ? fromArgs
      : RegExp(r'\(page ([0-9a-fA-F-]{36})')
            .firstMatch('${step.output} ${step.preview ?? ''}')
            ?.group(1);
  final title = step.args['title'];
  return (
    pageId: id,
    title: title is String && title.trim().isNotEmpty
        ? title.trim()
        : step.preview?.trim(),
  );
}

/// The Library item for a page [botId] just published (D-294): by its page id when known, else
/// the newest of the bot's pages with that exact title, else its newest page matching the title.
Future<Creation?> findPublishedPage(
  WidgetRef ref, {
  required String botId,
  String? pageId,
  String? title,
}) async {
  final orgId = ref.read(currentOrgIdProvider);
  if (orgId == null) return null;
  final words = title?.trim() ?? '';
  try {
    final items =
        (await ref
                .read(backendProvider)
                .creations(
                  orgId,
                  kind: CreationKind.page,
                  botId: botId,
                  q: words.isEmpty ? null : words,
                  limit: 50,
                ))
            .items;
    if (pageId != null) {
      final hit = items.where((c) => c.pageId == pageId).firstOrNull;
      if (hit != null) return hit;
    }
    if (words.isEmpty) return null;
    return items
            .where((c) => c.title.trim().toLowerCase() == words.toLowerCase())
            .firstOrNull ??
        items.firstOrNull;
  } catch (_) {
    return null;
  }
}

/// Show in Library under a reply that published a page (D-294): opens that page's item, or the
/// Library on the bot's pages when it can't be found (the Library hasn't caught up, or the page
/// was deleted since).
class PublishedInLibraryButton extends ConsumerStatefulWidget {
  const PublishedInLibraryButton({
    super.key,
    required this.botId,
    required this.steps,
  });
  final String botId;
  final List<ToolEntry> steps;

  @override
  ConsumerState<PublishedInLibraryButton> createState() =>
      _PublishedInLibraryButtonState();
}

class _PublishedInLibraryButtonState
    extends ConsumerState<PublishedInLibraryButton> {
  var _busy = false;

  Future<void> _open() async {
    final router = GoRouter.maybeOf(context);
    final page = publishedPageOf(widget.steps);
    setState(() => _busy = true);
    final c = await findPublishedPage(
      ref,
      botId: widget.botId,
      pageId: page?.pageId,
      title: page?.title,
    );
    if (mounted) setState(() => _busy = false);
    if (router == null) return;
    router.pushOnce(
      c != null ? '/library/${c.id}' : '/library?kind=page&bot=${widget.botId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the workspace loaded, so the lookup has it when tapped.
    ref.watch(currentOrgIdProvider);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        icon: _busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.library, size: 16),
        label: Text(context.l10n.showInLibrary),
        onPressed: _busy ? null : _open,
      ),
    );
  }
}

/// A long-press (touch) or right-click (mouse) menu with Show in Library, around a chat card.
class ShowInLibraryMenu extends ConsumerWidget {
  const ShowInLibraryMenu({
    super.key,
    required this.child,
    this.pageId,
    this.mediaId,
    this.title,
    this.kind,
  });
  final Widget child;
  final String? pageId;
  final String? mediaId;
  final String? title;
  final CreationKind? kind;

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        at & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          key: const Key('showInLibrary'),
          value: 'library',
          child: Row(
            children: [
              const Icon(LucideIcons.library, size: 18),
              const SizedBox(width: 12),
              Text(context.l10n.showInLibrary),
            ],
          ),
        ),
      ],
    );
    if (picked == 'library' && context.mounted) {
      await showInLibrary(
        context,
        ref,
        pageId: pageId,
        mediaId: mediaId,
        title: title,
        kind: kind,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onLongPressStart: (d) => _menu(context, ref, d.globalPosition),
    onSecondaryTapDown: (d) => _menu(context, ref, d.globalPosition),
    child: child,
  );
}

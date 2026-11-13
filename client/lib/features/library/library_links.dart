import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

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
    router.push('/library/${c.id}');
  } else {
    final k = pageId != null ? CreationKind.page : kind;
    router.push(
      Uri(path: '/library', queryParameters: {'kind': ?k?.value}).toString(),
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

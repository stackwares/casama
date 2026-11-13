import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// What the Library shows: one kind (null for all), one bot (null for any), and the words typed.
typedef LibraryQuery = ({CreationKind? kind, String? botId, String q});

/// One loaded run of the Library: the items so far, the workspace's kinds (for the chips), and
/// the cursor for the next page.
class LibraryPage {
  const LibraryPage({
    required this.items,
    required this.kinds,
    this.next,
    this.loadingMore = false,
  });
  final List<Creation> items;
  final List<CreationKind> kinds;
  final String? next;
  final bool loadingMore;

  LibraryPage copyWith({
    List<Creation>? items,
    List<CreationKind>? kinds,
    String? next,
    bool clearNext = false,
    bool? loadingMore,
  }) => LibraryPage(
    items: items ?? this.items,
    kinds: kinds ?? this.kinds,
    next: clearNext ? null : (next ?? this.next),
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// The Library's list for a [LibraryQuery], 60 at a time (D-274's `GET /v1/creations`).
class LibraryNotifier extends AsyncNotifier<LibraryPage> {
  LibraryNotifier(this.query);
  final LibraryQuery query;

  static const pageSize = 60;

  @override
  Future<LibraryPage> build() async {
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId == null) return const LibraryPage(items: [], kinds: []);
    final list = await ref
        .watch(backendProvider)
        .creations(
          orgId,
          kind: query.kind,
          botId: query.botId,
          q: query.q,
          limit: pageSize,
        );
    return LibraryPage(
      items: list.items,
      kinds: list.kinds,
      next: list.nextCursor,
    );
  }

  /// The next page, when there is one and none is loading.
  Future<void> loadMore() async {
    final current = state.value;
    final orgId = ref.read(currentOrgIdProvider);
    if (current == null ||
        current.next == null ||
        current.loadingMore ||
        orgId == null) {
      return;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final list = await ref
          .read(backendProvider)
          .creations(
            orgId,
            kind: query.kind,
            botId: query.botId,
            q: query.q,
            cursor: current.next,
            limit: pageSize,
          );
      final seen = {for (final c in current.items) c.id};
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            for (final c in list.items)
              if (!seen.contains(c.id)) c,
          ],
          next: list.nextCursor,
          clearNext: list.nextCursor == null,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Puts a changed creation in place (renamed, pinned), takes it out (deleted), or puts it back
  /// where it belongs, newest first (Undo).
  void replace(Creation c, {bool removed = false}) {
    final current = state.value;
    if (current == null) return;
    final List<Creation> items;
    if (removed) {
      items = [
        for (final x in current.items)
          if (x.id != c.id) x,
      ];
    } else if (current.items.any((x) => x.id == c.id)) {
      items = [for (final x in current.items) x.id == c.id ? c : x];
    } else {
      items = [...current.items, c]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    state = AsyncData(current.copyWith(items: items));
  }
}

final libraryProvider = AsyncNotifierProvider.autoDispose
    .family<LibraryNotifier, LibraryPage, LibraryQuery>(LibraryNotifier.new);

/// One creation with the others from the same run.
final creationProvider = FutureProvider.autoDispose
    .family<CreationDetail, String>(
      (ref, id) => ref.watch(backendProvider).creation(id),
    );

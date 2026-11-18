import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/remote_config.dart' show appVersionProvider;
import 'gallery_logic.dart';

/// The whole gallery as this app shows it: every kind, with public use numbers folded in, and
/// nothing retired, undrawable or meant for a newer app (D-315).
class GalleryCatalog {
  const GalleryCatalog({required this.available, required this.items});
  final bool available;
  final List<GalleryItem> items;

  GalleryItem? find(String type, String id) =>
      items.where((i) => i.type == type && i.id == id).firstOrNull;
}

final galleryCatalogProvider = FutureProvider<GalleryCatalog>((ref) async {
  final backend = ref.watch(backendProvider);
  final results = await Future.wait<Object>([
    backend.galleryEverything(),
    backend.galleryStats().then<Map<String, GalleryStats>>(
      (s) => s,
      onError: (_) => const <String, GalleryStats>{},
    ),
  ]);
  final page = results[0] as GalleryPage;
  final stats = results[1] as Map<String, GalleryStats>;
  String? version;
  if (page.items.any((i) => i.minApp != null)) {
    try {
      version = await ref.watch(appVersionProvider.future);
    } catch (_) {
      // Unknown version: items with a min_app stay hidden.
    }
  }
  return GalleryCatalog(
    available: page.available,
    items: galleryVisible([
      for (final item in page.items)
        item.stats == null && stats[item.key] != null
            ? item.withStats(stats[item.key])
            : item,
    ], appVersion: version),
  );
});

/// Gallery looks used on this device, by `<type>/<id>`, with the version used. Looks live on the
/// device, so the Installed tab tracks them here and offers an update when the gallery has newer.
class GalleryLocalLook {
  const GalleryLocalLook({
    required this.type,
    required this.id,
    required this.name,
    required this.version,
  });
  final String type;
  final String id;
  final String name;
  final int version;

  String get key => '$type/$id';

  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'name': name,
    'version': version,
  };

  static GalleryLocalLook? fromJson(Object? j) {
    if (j is! Map || j['type'] is! String || j['id'] is! String) return null;
    return GalleryLocalLook(
      type: j['type'] as String,
      id: j['id'] as String,
      name: j['name'] as String? ?? j['id'] as String,
      version: (j['version'] as num?)?.toInt() ?? 1,
    );
  }
}

final galleryLocalLooksProvider =
    NotifierProvider<GalleryLocalLooksNotifier, List<GalleryLocalLook>>(
      GalleryLocalLooksNotifier.new,
    );

class GalleryLocalLooksNotifier extends Notifier<List<GalleryLocalLook>> {
  static const _key = 'gallery.localLooks';
  final _loaded = Completer<void>();

  @override
  List<GalleryLocalLook> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        state = [
          for (final j in jsonDecode(raw) as List)
            if (GalleryLocalLook.fromJson(j) case final GalleryLocalLook l) l,
        ];
      }
    } catch (_) {
      // A broken entry starts the list over.
    }
    if (!_loaded.isCompleted) _loaded.complete();
  }

  Future<void> _persist() async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode([for (final l in state) l.toJson()]),
      );
    } catch (_) {}
  }

  /// Notes [item] as used here at its version (using it again replaces the entry).
  Future<void> record(GalleryItem item) async {
    await _loaded.future;
    final look = GalleryLocalLook(
      type: item.type,
      id: item.id,
      name: item.name,
      version: item.version,
    );
    state = [
      look,
      for (final l in state)
        if (l.key != look.key) l,
    ];
    await _persist();
  }

  Future<void> remove(String key) async {
    await _loaded.future;
    state = [
      for (final l in state)
        if (l.key != key) l,
    ];
    await _persist();
  }
}

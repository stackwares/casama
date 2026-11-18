import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';

/// Content the server and the gallery send instead of copies in the app (D-372): links, names
/// for ids, the quick reactions and the gallery's lists. Every reader passes the app's own copy
/// as the fallback, so an older server, an offline start or a missing entry changes nothing.

/// The latest remote settings' lists, kept here so code without a [WidgetRef] (link handlers,
/// label helpers) reads them too. Set by [applyRemoteContent] whenever settings arrive.
class RemoteContent {
  RemoteContent._();

  static Map<String, String> _links = const {};
  static Map<String, Map<String, String>> _names = const {};
  static List<String>? _quickReactions;

  /// Tests start from nothing.
  @visibleForTesting
  static void reset() {
    _links = const {};
    _names = const {};
    _quickReactions = null;
  }
}

/// Takes the lists out of fresh (or saved) remote settings.
void applyRemoteContent(RemoteAppConfig? config) {
  if (config == null) return;
  RemoteContent._links = {
    for (final e in (config.links ?? const <String, String>{}).entries)
      if (e.value.startsWith('https://')) e.key: e.value,
  };
  RemoteContent._names = config.names ?? const {};
  final quick = [
    for (final e in config.quickReactions ?? const <String>[])
      if (e.isNotEmpty && e.length <= 32) e,
  ];
  RemoteContent._quickReactions = quick.isEmpty ? null : quick.take(8).toList();
}

/// The link the server's owner set for [name], or [fallback] (the app's own address).
String remoteLink(String name, String fallback) =>
    RemoteContent._links[name] ?? fallback;

/// [remoteLink] as a [Uri].
Uri remoteUri(String name, String fallback) =>
    Uri.tryParse(remoteLink(name, fallback)) ?? Uri.parse(fallback);

/// A display name the server sent for [id] in [list] (`apps`, `dns_providers`), or null.
String? remoteName(String list, String? id) =>
    id == null ? null : RemoteContent._names[list]?[id];

/// The reactions offered first, in order: the server's, or [fallback].
List<String> remoteQuickReactions(List<String> fallback) =>
    RemoteContent._quickReactions ?? fallback;

/// The gallery's content lists (search words, empty-state starters), from the server. Null when
/// the server is older or can't say: each screen keeps its own copy then.
final galleryListsProvider = FutureProvider<GalleryLists?>((ref) async {
  ref.watch(signedInProvider);
  try {
    return await ref.watch(backendProvider).galleryLists();
  } catch (_) {
    return null;
  }
});

/// Whether gallery text may replace the app's: the lists are written in English, so other
/// languages keep their translations.
bool galleryTextFits(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

import 'package:casama_sdk/casama_sdk.dart';

/// Logos for apps from the open gallery (D-239), by app id: single-color SVG marks the server
/// lists with the catalog. Built-in apps ship their marks in assets/apps instead. Filled whenever
/// the catalog loads, so a connection's logo finds its mark on any screen.
final Map<String, String> galleryAppMarks = {};

void rememberAppMarks(Iterable<CatalogApp> apps) {
  for (final a in apps) {
    final url = a.logoUrl;
    if (url != null && url.startsWith('https://')) galleryAppMarks[a.id] = url;
  }
}

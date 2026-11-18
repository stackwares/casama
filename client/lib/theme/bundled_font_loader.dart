import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled families the app loads when something first draws in them, rather than at launch.
///
/// Families in pubspec's `fonts:` are font-manifest fonts, and the web app downloads every one of
/// them before its first frame. The default look only needs Google Sans (and the icon fonts), so
/// these ship as plain assets instead: about 2.7 MB the web app no longer fetches up front. A
/// saved look's fonts are loaded before the app's first frame (see preloadFonts), a font picker's
/// preview loads its family as it appears, and code's mono face warms up once the app is showing.
/// Text drawn before a family arrives is laid out again when it does.
const lazyBundledFonts = <String, List<String>>{
  'Libre Baskerville': [
    'assets/fonts/LibreBaskerville-Regular.ttf',
    'assets/fonts/LibreBaskerville-Bold.ttf',
  ],
  'Lato': [
    'assets/fonts/Lato-Regular.ttf',
    'assets/fonts/Lato-Bold.ttf',
    'assets/fonts/Lato-Black.ttf',
  ],
  'Noto Serif': [
    'assets/fonts/NotoSerif-SemiBold.ttf',
    'assets/fonts/NotoSerif-Bold.ttf',
  ],
  'Fraunces': [
    'assets/fonts/Fraunces-SemiBold.ttf',
    'assets/fonts/Fraunces-Bold.ttf',
  ],
  'Figtree': [
    'assets/fonts/Figtree-Regular.ttf',
    'assets/fonts/Figtree-Medium.ttf',
    'assets/fonts/Figtree-SemiBold.ttf',
    'assets/fonts/Figtree-Bold.ttf',
    'assets/fonts/Figtree-ExtraBold.ttf',
  ],
  'JetBrains Mono': [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-Bold.ttf',
  ],
};

final _loads = <String, Future<void>>{};

/// Off under `flutter test` (test/flutter_test_config.dart): tests draw every family in a test
/// font, and a load finishing after a test ends would schedule a frame for a disposed tree.
@visibleForTesting
bool bundledFontLoadingEnabled = true;

/// Loads [family]'s bundled files once; later calls share the first load. Families that aren't in
/// [lazyBundledFonts] (manifest fonts, Google Fonts) need nothing. Never throws: a family that
/// can't load keeps drawing in the fallback face, and the next call tries again.
Future<void> loadBundledFont(String family) {
  final files = lazyBundledFonts[family];
  if (files == null || !bundledFontLoadingEnabled) return Future.value();
  return _loads[family] ??= () async {
    try {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    } catch (e) {
      _loads.remove(family);
      debugPrint('fonts: could not load $family: $e');
    }
  }();
}

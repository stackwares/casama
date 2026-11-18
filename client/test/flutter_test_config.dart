import 'dart:async';

import 'package:casama/theme/bundled_font_loader.dart';

/// Runs before every test file. Tests draw text in a test font, so the bundled families that load
/// on first use (lazyBundledFonts) stay unloaded: a load finishing after a test would schedule a
/// frame for a tree that is gone.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  bundledFontLoadingEnabled = false;
  await testMain();
}

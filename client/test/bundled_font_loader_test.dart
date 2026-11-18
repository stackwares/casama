import 'dart:io';

import 'package:casama/theme/bundled_font_loader.dart';
import 'package:casama/theme/fonts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every lazy family is bundled, ships its files, and stays out of the font manifest', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final manifestFonts = pubspec.substring(pubspec.indexOf('\n  fonts:'));
    for (final MapEntry(key: family, value: files)
        in lazyBundledFonts.entries) {
      expect(
        bundledFonts.contains(family) || family == 'JetBrains Mono',
        isTrue,
        reason: family,
      );
      expect(
        manifestFonts.contains('family: $family'),
        isFalse,
        reason: '$family would load before the first frame on the web',
      );
      for (final file in files) {
        expect(File(file).existsSync(), isTrue, reason: file);
      }
    }
    // The default look's face stays a manifest font, so the first frame draws in it.
    expect(manifestFonts.contains('family: Google Sans'), isTrue);
  });

  test('a family loads once and later calls share it', () async {
    bundledFontLoadingEnabled = true;
    addTearDown(() => bundledFontLoadingEnabled = false);
    final first = loadBundledFont('Lato');
    expect(identical(first, loadBundledFont('Lato')), isTrue);
    await first;
    await loadBundledFont('Not A Bundled Family');
  });
}

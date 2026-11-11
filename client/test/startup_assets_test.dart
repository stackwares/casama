import 'package:casama_app/core/startup_assets.dart';
import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mascots are decoded before a screen asks for them', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    PaintingBinding.instance.imageCache.clear();
    await tester.runAsync(() async {
      await precacheAssets(context: context, paths: startupStills);
      for (final path in startupStills) {
        // The same key MascotImage's Image.asset asks the cache for.
        final key = await AssetImage(path).obtainKey(ImageConfiguration.empty);
        expect(PaintingBinding.instance.imageCache.containsKey(key), isTrue, reason: path);
      }
    });
  });

  testWidgets('the app logos are parsed into the SVG cache ahead of the Connections screens', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    svg.cache.clear();
    await tester.runAsync(() => precacheAssets(context: context, paths: bundledLogoAssets));
    expect(svg.cache.count, bundledLogoAssets.length);
  });

  testWidgets('a missing file is skipped, not thrown', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    await tester.runAsync(() => precacheAssets(context: context, paths: ['assets/nope.png', 'assets/nope.svg']));
    expect(tester.takeException(), isNull);
  });
}

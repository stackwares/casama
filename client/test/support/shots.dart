// Pictures of what a test draws, with the app's real fonts and icons, for looking at a layout
// rather than measuring it. Nothing is compared: the files are for people.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Google Sans and the icon fonts, so text is text and icons are icons (tests otherwise
/// draw every glyph as a box).
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await family('Google Sans', [
    'assets/fonts/GoogleSans-Regular.ttf',
    'assets/fonts/GoogleSans-Medium.ttf',
    'assets/fonts/GoogleSans-Bold.ttf',
  ]);
  await family('packages/lucide_icons_flutter/Lucide', [
    'packages/lucide_icons_flutter/assets/lucide.ttf',
  ]);
}

/// Wrap the app in this to take pictures of it.
class ShotFrame extends StatelessWidget {
  const ShotFrame({super.key, required this.child});
  final Widget child;
  static final boundary = GlobalKey(debugLabel: 'shot');

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: boundary, child: child);
}

/// Writes what is on screen to `<dir>/<name>.png` at twice the size.
Future<void> shot(WidgetTester tester, String dir, String name) async {
  final render =
      ShotFrame.boundary.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '$dir/${name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')}.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

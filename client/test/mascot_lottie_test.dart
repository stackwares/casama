import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/ui/mascot.dart';
import 'package:lottie/lottie.dart';

/// Every mascot's Lottie loads and draws an 8 second loop. With MASCOT_FRAMES_DIR set, also writes frames as
/// PNGs (used to compare against the SVGs when changing scripts/casama-mascot-lottie.py).
void main() {
  final framesDir = Platform.environment['MASCOT_FRAMES_DIR'];

  final loops = {for (final m in Mascot.values) m.name: m.lottieAsset, 'blank': BlankBotImage.lottieAsset};
  for (final MapEntry(key: name, value: asset) in loops.entries) {
    testWidgets('$name plays as Lottie', (tester) async {
      final composition = (await tester.runAsync(() => AssetLottie(asset).load()))!;
      expect(composition.duration, const Duration(seconds: 8));
      expect(composition.images.values.every((i) => i.loadedImage != null), isTrue);
      final times = framesDir == null ? [0.0, 2.5, 5.0] : [for (var i = 0; i < 16; i++) i * .5];
      for (final t in times) {
        final key = GlobalKey();
        await tester.pumpWidget(Center(
          child: RepaintBoundary(
            key: key,
            child: Lottie(composition: composition, controller: AlwaysStoppedAnimation(t / 8), width: 256, height: 256),
          ),
        ));
        expect(tester.takeException(), isNull);
        if (framesDir != null) {
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$framesDir/$name-${(t * 1000).round()}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
      }
    });
  }
}

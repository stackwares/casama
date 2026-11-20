// The avatar cropper (docs/BOT-PICTURES-PLAN.md §4): frame in the final shape, the picture moving
// under it, live previews, see-through backgrounds, keyboard and screen reader, and the output.
import 'dart:ui' as ui;

import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/ui/avatar_cropper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A [w]×[h] PNG: solid [color], or (see-through) a [color] square in the middle of nothing.
/// With [topHalf], the top half is [topHalf] (to see where the frame sits).
Future<Uint8List> _png(
  int w,
  int h, {
  Color color = const Color(0xFF3366CC),
  bool seeThrough = false,
  Color? topHalf,
}) async {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  if (seeThrough) {
    c.drawRect(
      Rect.fromLTWH(w / 4, h / 4, w / 2, h / 2),
      Paint()..color = color,
    );
  } else {
    c.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = color,
    );
    if (topHalf != null) {
      c.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h / 2),
        Paint()..color = topHalf,
      );
    }
  }
  final img = await r.endRecording().toImage(w, h);
  final d = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return d!.buffer.asUint8List();
}

/// The colour of the result's pixel at (x, y).
Future<Color> _pixel(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final img = (await codec.getNextFrame()).image;
  final d = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final i = (y * img.width + x) * 4;
  return Color.fromARGB(
    d.getUint8(i + 3),
    d.getUint8(i),
    d.getUint8(i + 1),
    d.getUint8(i + 2),
  );
}

class _Host extends StatelessWidget {
  const _Host({
    required this.bytes,
    required this.onResult,
    this.shape = AvatarShape.bot,
    this.initial,
  });
  final Uint8List bytes;
  final ValueChanged<CroppedAvatar?> onResult;
  final AvatarShape shape;
  final AvatarCrop? initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => onResult(
              await showAvatarCropper(
                context,
                bytes: bytes,
                shape: shape,
                name: 'Ada',
                initial: initial,
                outputSide: 256,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

/// Lets the real decoding and encoding finish, then draws.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

Future<CroppedAvatar?> _done(
  WidgetTester tester, {
  required List<CroppedAvatar?> into,
}) async {
  await tester.tap(find.byKey(const Key('avatarCropDone')));
  await _settle(tester);
  return into.isEmpty ? null : into.last;
}

void main() {
  Future<List<CroppedAvatar?>> openWith(
    WidgetTester tester,
    Uint8List bytes, {
    AvatarShape shape = AvatarShape.bot,
    AvatarCrop? initial,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <CroppedAvatar?>[];
    await tester.pumpWidget(
      _Host(
        bytes: bytes,
        shape: shape,
        initial: initial,
        onResult: results.add,
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);
    return results;
  }

  testWidgets(
    'a square picture fills the frame, centred, and comes back as a square PNG',
    (tester) async {
      final bytes = (await tester.runAsync(() => _png(600, 600)))!;
      final results = await openWith(tester, bytes);
      expect(find.text('Move and Scale'), findsOneWidget);
      // Live previews: Ada in the sidebar rows, on light and dark.
      expect(find.text('Ada'), findsNWidgets(2));
      // Nothing changed yet: Reset waits.
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('avatarCropReset')))
            .onPressed,
        isNull,
      );
      final r = await _done(tester, into: results);
      expect(r, isNotNull);
      expect(r!.crop.x, closeTo(0.5, 0.001));
      expect(r.crop.y, closeTo(0.5, 0.001));
      expect(r.crop.scale, closeTo(1, 0.001));
      expect(r.zoomed, isFalse);
      expect(r.transparent, isFalse);
      final px = (await tester.runAsync(() => _pixel(r.png, 128, 128)))!;
      expect(px, const Color(0xFF3366CC));
    },
  );

  testWidgets('a portrait starts a little high, where faces are', (
    tester,
  ) async {
    final bytes = (await tester.runAsync(() => _png(400, 800)))!;
    final results = await openWith(tester, bytes);
    final r = await _done(tester, into: results);
    expect(r!.crop.y, lessThan(0.5));
    expect(r.crop.x, closeTo(0.5, 0.001));
  });

  testWidgets(
    'dragging moves the picture; past the edge it springs back inside',
    (tester) async {
      // Wide, so it can move sideways.
      final bytes = (await tester.runAsync(() => _png(1200, 600)))!;
      final results = await openWith(tester, bytes);
      final frame = find.byKey(const Key('avatarCropFrame'));
      await tester.drag(frame, const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('avatarCropReset')))
            .onPressed,
        isNotNull,
      );
      // Far past the left edge of the picture: it settles with the frame still covered.
      await tester.drag(frame, const Offset(3000, 0));
      await tester.pumpAndSettle();
      final r = await _done(tester, into: results);
      // The frame's centre can't go further left than a quarter of the way across (600 of 1200 px).
      expect(r!.crop.x, closeTo(0.25, 0.01));
    },
  );

  testWidgets(
    'rotating and mirroring are remembered, and Reset puts them back',
    (tester) async {
      final bytes = (await tester.runAsync(() => _png(600, 600)))!;
      final results = await openWith(tester, bytes);
      await tester.tap(find.byKey(const Key('avatarCropRotate')));
      await tester.tap(find.byKey(const Key('avatarCropMirror')));
      await tester.pumpAndSettle();
      final r = await _done(tester, into: results);
      expect(r!.crop.turns, 1);
      expect(r.crop.mirror, isTrue);
      expect(r.turned, isTrue);

      final again = await openWith(tester, bytes);
      await tester.tap(find.byKey(const Key('avatarCropRotate')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatarCropReset')));
      await tester.pumpAndSettle();
      final back = await _done(tester, into: again);
      expect(back!.crop.turns, 0);
    },
  );

  testWidgets('zooming in with the slider and the keyboard', (tester) async {
    final bytes = (await tester.runAsync(() => _png(1600, 1600)))!;
    final results = await openWith(tester, bytes);
    await tester.tap(find.byKey(const Key('avatarCropZoomIn')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pumpAndSettle();
    final r = await _done(tester, into: results);
    expect(r!.zoomed, isTrue);
    expect(r.crop.scale, lessThan(0.9));
  });

  testWidgets('arrows nudge the picture, Escape backs out', (tester) async {
    final bytes = (await tester.runAsync(() => _png(1200, 600)))!;
    final results = await openWith(tester, bytes);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    }
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('avatarCropReset')))
          .onPressed,
      isNotNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Move and Scale'), findsNothing);
    expect(results, [null]);
  });

  testWidgets(
    'a see-through logo offers backgrounds and bakes in the one picked',
    (tester) async {
      final bytes = (await tester.runAsync(
        () => _png(400, 400, seeThrough: true, color: const Color(0xFFE53935)),
      ))!;
      final results = await openWith(tester, bytes);
      expect(find.text('Background'), findsOneWidget);
      expect(find.text("Ada's color"), findsOneWidget);
      // It has room around it, so it starts with none.
      var r = await _done(tester, into: results);
      expect(r!.transparent, isTrue);
      expect(
        (await tester.runAsync(() => _pixel(r!.png, 2, 2)))!.a,
        lessThan(0.05),
      );

      final again = await openWith(tester, bytes);
      await tester.tap(find.byKey(const Key('avatarCropBackground-white')));
      await tester.pumpAndSettle();
      r = await _done(tester, into: again);
      expect(r!.transparent, isFalse);
      expect(r.crop.background, CropBackground.white);
      expect(
        (await tester.runAsync(() => _pixel(r!.png, 2, 2)))!,
        const Color(0xFFFFFFFF),
      );
    },
  );

  testWidgets('Re-crop opens where the last crop was left', (tester) async {
    final bytes = (await tester.runAsync(() => _png(1200, 600)))!;
    final results = await openWith(
      tester,
      bytes,
      initial: const AvatarCrop(x: 0.3, y: 0.5, scale: 0.8),
    );
    final r = await _done(tester, into: results);
    expect(r!.crop.x, closeTo(0.3, 0.005));
    expect(r.crop.scale, closeTo(0.8, 0.005));
  });

  testWidgets('a file that is not a picture says so, in plain words', (
    tester,
  ) async {
    final results = await openWith(
      tester,
      Uint8List.fromList(List.filled(64, 7)),
    );
    expect(
      find.text("This picture can't be opened here. Try a JPEG or PNG."),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('avatarCropDone')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('avatarCropCancel')));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('screen readers get the position, its zoom and actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final bytes = (await tester.runAsync(() => _png(600, 600)))!;
    await openWith(tester, bytes);
    final node = tester.getSemantics(find.bySemanticsLabel('Picture position'));
    expect(node.value, '100 %');
    expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    handle.dispose();
  });

  testWidgets('larger windows get a dialog; people get a round frame', (
    tester,
  ) async {
    final bytes = (await tester.runAsync(() => _png(600, 600)))!;
    final results = await openWith(
      tester,
      bytes,
      shape: AvatarShape.person,
      size: const Size(1280, 900),
    );
    expect(find.byType(Dialog), findsOneWidget);
    // No "Ada's color" for people, only plain backgrounds (and none show without see-through parts).
    expect(find.text("Ada's color"), findsNothing);
    final r = await _done(tester, into: results);
    expect(r, isNotNull);
  });
}

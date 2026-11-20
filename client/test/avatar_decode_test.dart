// The cropper opens ordinary pictures on every platform. On the web, ImageDescriptor can't tell a
// picture's size, so decoding through it called every PNG and JPEG "unreadable"; this runs there
// too (flutter test --platform chrome test/avatar_decode_test.dart).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casama/ui/avatar_cropper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<Uint8List> _png(
  int width,
  int height, {
  Color color = const Color(0xFF3366FF),
}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  test('a PNG opens at its own size, solid', () async {
    final s = await decodeAvatarSource(await _png(691, 530));
    expect((s.image.width, s.image.height), (691, 530));
    expect(s.transparent, isFalse);
    expect(s.animated, isFalse);
    s.image.dispose();
  });

  test('a big picture is scaled to 2,048 px on its long side', () async {
    final s = await decodeAvatarSource(await _png(4096, 1024));
    expect((s.image.width, s.image.height), (2048, 512));
    s.image.dispose();
  });

  test('a see-through PNG is found transparent', () async {
    final s = await decodeAvatarSource(
      await _png(100, 100, color: const Color(0x00000000)),
    );
    expect(s.transparent, isTrue);
    expect(s.margin, isTrue);
    s.image.dispose();
  });

  test('bytes that are not a picture are unreadable', () async {
    expect(
      () => decodeAvatarSource(Uint8List.fromList(List.filled(64, 7))),
      throwsA(isA<AvatarSourceError>().having((e) => e.bytes, 'bytes', isNull)),
    );
  });
}

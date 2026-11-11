import 'dart:io';

import 'package:casama_app/core/dictation_bytes_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a finished recording is returned and removed', () async {
    final dir = await Directory.systemTemp.createTemp('casama-dictation');
    final file = File('${dir.path}/clip.wav');
    await file.writeAsBytes(List<int>.filled(80, 7));
    final clip = await readDictationFile(file.path);
    expect(clip?.$1, hasLength(80));
    expect(clip?.$2, 'audio/wav');
    expect(file.existsSync(), isFalse);
    await dir.delete(recursive: true);
  });

  test('a header with no samples is nothing', () async {
    final dir = await Directory.systemTemp.createTemp('casama-dictation');
    final file = File('${dir.path}/clip.wav');
    await file.writeAsBytes(List<int>.filled(44, 0));
    expect(await readDictationFile(file.path), isNull);
    expect(file.existsSync(), isFalse);
    await dir.delete(recursive: true);
  });
}

import 'dart:io';
import 'dart:typed_data';

/// Phones and desktop: the recorder plugin writes the file.
Future<void> beginDictationCapture(Future<void> Function() startNative) => startNative();

Future<(Uint8List, String)?> endDictationCapture(Future<String?> Function() stopNative) async {
  final path = await stopNative();
  if (path == null || path.isEmpty) return null;
  return readDictationFile(path);
}

Future<void> cancelDictationCapture(Future<void> Function() cancelNative) => cancelNative();

/// Reads a recording once the file has stopped growing, then deletes it.
///
/// macOS finishes the file after `stop` returns, so a single read can catch a header with no
/// samples. Two matching sizes means the write is done.
Future<(Uint8List, String)?> readDictationFile(String path) async {
  final file = File(path);
  try {
    var last = -1;
    var stable = 0;
    for (var i = 0; i < 25; i++) {
      if (await file.exists()) {
        final len = await file.length();
        if (len == last) {
          stable++;
          if (stable >= 2) return await _clip(file, len);
        } else {
          stable = 0;
          last = len;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!await file.exists()) return null;
    return await _clip(file, await file.length());
  } finally {
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

Future<(Uint8List, String)?> _clip(File file, int len) async {
  final wav = file.path.endsWith('.wav');
  // A WAV header is 44 bytes. An m4a with no samples is a short container.
  if (len <= (wav ? 44 : 512)) return null;
  final bytes = await file.readAsBytes();
  return (bytes, wav ? 'audio/wav' : 'audio/mp4');
}

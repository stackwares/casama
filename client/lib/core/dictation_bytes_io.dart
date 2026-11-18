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
/// samples. Two matching sizes means the write is done. An m4a is only playable once its index
/// (the `moov` box) is written, which can come after the samples stop growing; sent without it,
/// the transcription service rejects the clip, so wait for that too.
Future<(Uint8List, String)?> readDictationFile(String path) async {
  final file = File(path);
  try {
    var last = -1;
    var stable = 0;
    for (var i = 0; i < 50; i++) {
      if (await file.exists()) {
        final len = await file.length();
        if (len == last) {
          stable++;
          if (stable >= 2) {
            final clip = await _clip(file, len);
            if (clip == null || clip.$2 != 'audio/mp4' || hasMp4Index(clip.$1)) return clip;
          }
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

/// Whether an MP4/m4a file has its `moov` box (the index a player needs). Walks the top-level
/// boxes rather than searching the bytes, so audio data that happens to spell "moov" can't fool it.
bool hasMp4Index(Uint8List bytes) {
  var at = 0;
  while (at + 8 <= bytes.length) {
    var size = (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3];
    final type = String.fromCharCodes(bytes.sublist(at + 4, at + 8));
    if (type == 'moov') return true;
    if (size == 1 && at + 16 <= bytes.length) {
      // A 64-bit size follows the type.
      var big = 0;
      for (var i = 8; i < 16; i++) {
        big = big * 256 + bytes[at + i];
      }
      size = big;
    } else if (size == 0) {
      return false; // The box runs to the end of the file.
    }
    if (size < 8) return false;
    at += size;
  }
  return false;
}

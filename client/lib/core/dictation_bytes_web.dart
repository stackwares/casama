import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

/// The browser's own recorder. The `record` plugin's web stream goes through an audio worklet,
/// and that callback never delivers samples in the Wasm build, so the saved clip was empty.

@JS('navigator.mediaDevices.getUserMedia')
external JSPromise<JSObject> _getUserMedia(JSAny constraints);

@JS('MediaRecorder')
extension type _MediaRecorder._(JSObject _) implements JSObject {
  external factory _MediaRecorder(JSObject stream, JSAny options);
  external static bool isTypeSupported(String type);
  external String get mimeType;
  external String get state;
  external void start(int timeslice);
  external void stop();
  external set ondataavailable(JSFunction? fn);
  external set onstop(JSFunction? fn);
}

extension type _BlobEvent._(JSObject _) implements JSObject {
  external _Blob get data;
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<_Blob> parts, JSAny options);
  external int get size;
  external String get type;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

extension type _MediaStream._(JSObject _) implements JSObject {
  external JSArray<JSObject> getAudioTracks();
}

extension type _Track._(JSObject _) implements JSObject {
  external void stop();
}

_MediaRecorder? _recorder;
JSObject? _stream;
final _chunks = <_Blob>[];
Completer<void>? _stopped;
String _mime = 'audio/webm';

Future<void> beginDictationCapture(Future<void> Function() _) async {
  await _release();
  final stream = await _getUserMedia({'audio': true}.jsify()!).toDart;
  final mime = _mimeType();
  final recorder = _MediaRecorder(stream, {'mimeType': mime, 'audioBitsPerSecond': 128000}.jsify()!);
  final stopped = Completer<void>();
  recorder.ondataavailable = ((JSObject event) {
    final blob = _BlobEvent._(event).data;
    if (blob.size > 0) _chunks.add(blob);
  }).toJS;
  recorder.onstop = ((JSObject _) {
    if (!stopped.isCompleted) stopped.complete();
  }).toJS;
  recorder.start(250);
  _recorder = recorder;
  _stream = stream;
  _stopped = stopped;
  _mime = mime.isEmpty ? 'audio/webm' : mime;
}

Future<(Uint8List, String)?> endDictationCapture(Future<String?> Function() _) async {
  final recorder = _recorder;
  final stopped = _stopped;
  if (recorder != null && (recorder.state == 'recording' || recorder.state == 'paused')) {
    recorder.stop();
    if (stopped != null && !stopped.isCompleted) {
      await stopped.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    }
  }
  final chunks = List<_Blob>.of(_chunks);
  final mime = _mime;
  await _release();
  if (chunks.isEmpty) return null;
  final blob = _Blob(chunks.toJS, {'type': mime}.jsify()!);
  final bytes = Uint8List.fromList((await blob.arrayBuffer().toDart).toDart.asUint8List());
  if (bytes.length < 16) return null;
  final type = mime.split(';').first.trim();
  return (bytes, type.startsWith('audio/') || type.startsWith('video/') ? type : 'audio/webm');
}

Future<void> cancelDictationCapture(Future<void> Function() _) => _release();

String _mimeType() {
  const types = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4'];
  for (final type in types) {
    try {
      if (_MediaRecorder.isTypeSupported(type)) return type;
    } catch (_) {}
  }
  return '';
}

Future<void> _release() async {
  final recorder = _recorder;
  _recorder = null;
  if (recorder != null && recorder.state == 'recording') {
    try {
      recorder.stop();
    } catch (_) {}
  }
  final stream = _stream;
  _stream = null;
  if (stream != null) {
    for (final track in _MediaStream._(stream).getAudioTracks().toDart) {
      try {
        _Track._(track).stop();
      } catch (_) {}
    }
  }
  _chunks.clear();
  final stopped = _stopped;
  _stopped = null;
  if (stopped != null && !stopped.isCompleted) stopped.complete();
}

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// The browser's name for a permission, for `navigator.permissions.query`.
String? _queryName(String id) => switch (id) {
  'location' => 'geolocation',
  'camera' => 'camera',
  'microphone' => 'microphone',
  'notifications' => 'notifications',
  _ => null,
};

String _state(String s) => switch (s) {
  'granted' => 'granted',
  'denied' => 'denied',
  'prompt' || 'default' => 'not_asked',
  _ => 'unknown',
};

/// What the browser has for [id], without asking (Permissions API; Firefox doesn't know camera
/// or microphone there, which reads as unknown).
Future<String> webPermissionState(String id) async {
  if (id == 'notifications') return _state(web.Notification.permission);
  final name = _queryName(id);
  if (name == null) return 'unavailable';
  try {
    final status = await web.window.navigator.permissions.query({'name': name}.jsify() as JSObject).toDart;
    return _state(status.state);
  } catch (_) {
    return 'unknown';
  }
}

/// Asks the browser for camera or microphone by opening them once and stopping right away.
/// Location goes through geolocator and notifications through push, in the caller.
Future<String> webPermissionRequest(String id) async {
  if (id != 'camera' && id != 'microphone') return webPermissionState(id);
  try {
    final constraints = id == 'camera' ? web.MediaStreamConstraints(video: true.toJS) : web.MediaStreamConstraints(audio: true.toJS);
    final stream = await web.window.navigator.mediaDevices.getUserMedia(constraints).toDart;
    for (final t in stream.getTracks().toDart) {
      t.stop();
    }
    return 'granted';
  } catch (_) {
    return webPermissionState(id);
  }
}

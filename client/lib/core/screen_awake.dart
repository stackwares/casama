import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the phone's screen on while a call screen is open and in front (D-327 §7), never in the
/// background. iOS and Android only, over the `casama/screen_awake` channel; elsewhere a no-op.
abstract final class ScreenAwake {
  static const _channel = MethodChannel('casama/screen_awake');
  static bool _on = false;

  static bool get on => _on;

  static Future<void> set(bool on) async {
    if (_on == on) return;
    _on = on;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('set', {'on': on});
    } on MissingPluginException {
      // A build without the native side.
    } catch (e) {
      debugPrint('screen awake: $e');
    }
  }
}

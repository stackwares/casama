import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Files, photos and text dragged onto Casama from the app beside it (D-411): Split View on an
/// iPhone Duo or an iPad. iOS only; desktop and the web use `desktop_drop` in the chat itself.
/// The native side (`DropBridge` in ios/Runner/AppDelegate.swift) refuses a drop while no chat
/// is taking them.
typedef DropHandler = void Function(List<String> files, String text);

abstract final class DroppedFiles {
  static const _channel = MethodChannel('casama/drop');
  static final _takers = <DropHandler>[];
  static var _wired = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static void _tell() => unawaited(
    _channel
        .invokeMethod<void>('accept', _takers.isNotEmpty)
        .catchError((Object _) {}),
  );

  /// [onDrop] takes what is dropped from now on (the chat on screen). The newest taker wins.
  static void take(DropHandler onDrop) {
    if (!_supported) return;
    if (!_wired) {
      _wired = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'dropped' || _takers.isEmpty) return;
        final args = (call.arguments as Map?) ?? const {};
        _takers.last([
          for (final f in (args['files'] as List?) ?? const []) f as String,
        ], (args['text'] as String?) ?? '');
      });
    }
    _takers.add(onDrop);
    _tell();
  }

  /// [onDrop] stops taking drops (its chat closed).
  static void release(DropHandler onDrop) {
    if (!_supported) return;
    _takers.remove(onDrop);
    _tell();
  }
}

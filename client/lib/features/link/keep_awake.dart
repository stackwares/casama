import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../selfhost/local_server.dart';

/// Keeps this Mac from sleeping while it is plugged in (D-296): a server on a Mac is only reachable
/// while the Mac is awake, and a laptop left closed or idle is the usual reason a phone finds its
/// server offline.
///
/// Done with macOS's own `caffeinate -s`, which holds the system awake only on mains power and
/// lets go when this app exits, so a forgotten switch never drains a battery. The choice is kept
/// on this computer and picked up again when the app starts.
abstract final class KeepAwake {
  static const _key = 'casama.link.keep_awake';
  static Process? _holder;

  /// Starts the holder process (tests replace it).
  static Future<Process> Function() start = () =>
      Process.start('/usr/bin/caffeinate', ['-s', '-w', '$pid']);

  /// Mac only, and only where the app can run a server at all (not the Mac App Store build).
  static bool get supported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.macOS &&
      localServerSupported;

  static bool get holding => _holder != null;

  static Future<bool> enabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> set(bool on) async {
    await (await SharedPreferences.getInstance()).setBool(_key, on);
    if (on) {
      await _hold();
    } else {
      release();
    }
  }

  /// At app start: hold again if the person left it on.
  static Future<void> restore() async {
    if (supported && await enabled()) await _hold();
  }

  static Future<void> _hold() async {
    if (_holder != null || !supported) return;
    try {
      final p = await start();
      _holder = p;
      unawaited(
        p.exitCode.then((_) {
          if (identical(_holder, p)) _holder = null;
        }),
      );
    } catch (_) {
      // No caffeinate (a stripped-down system): the switch simply has no effect.
    }
  }

  static void release() {
    _holder?.kill();
    _holder = null;
  }
}

/// Whether the person turned it on (the switch's state).
final keepAwakeProvider = FutureProvider.autoDispose<bool>(
  (ref) => KeepAwake.enabled(),
);

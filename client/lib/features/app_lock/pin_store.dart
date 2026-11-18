import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'session_store.dart';

/// The app lock's PIN (D-375), where the system has no unlock of its own (Linux, Android 8). Only
/// a salted PBKDF2-SHA256 hash is kept, in the system keychain (libsecret on Linux, the Keystore on
/// Android), never the PIN.
abstract final class PinStore {
  static const _key = 'casama.appLock.pin';
  static const length = 6;

  /// PBKDF2 rounds for a new PIN; each saved hash records its own. Lowered in tests.
  @visibleForTesting
  static int iterations = 120000;

  /// Saves [pin] (six digits). False when the keychain refused it.
  static Future<bool> save(String pin) async {
    assert(RegExp('^[0-9]{$length}\$').hasMatch(pin));
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    try {
      await appSecureStorage.write(
        key: _key,
        value: 'v1:$iterations:${base64Encode(salt)}:${base64Encode(hash)}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True when [pin] matches; null when there's no PIN or the keychain can't be read.
  static Future<bool?> verify(String pin) async {
    final String? saved;
    try {
      saved = await appSecureStorage.read(key: _key);
    } catch (_) {
      return null;
    }
    final parts = saved?.split(':');
    if (parts == null || parts.length != 4 || parts[0] != 'v1') return null;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return null;
    try {
      final hash = await _derive(pin, base64Decode(parts[2]), rounds);
      return _same(hash, base64Decode(parts[3]));
    } on FormatException {
      return null;
    }
  }

  static Future<bool> exists() async {
    try {
      return await appSecureStorage.containsKey(key: _key);
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    try {
      await appSecureStorage.delete(key: _key);
    } catch (_) {}
  }

  static Future<List<int>> _derive(String pin, List<int> salt, int rounds) {
    final job = (pin: pin, salt: salt, rounds: rounds);
    // Off the UI thread when it takes long enough to drop frames.
    return rounds > 10000 && !kIsWeb
        ? compute(_pbkdf2, job)
        : Future.value(_pbkdf2(job));
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2-HMAC-SHA256 with one 32-byte block (RFC 8018).
List<int> _pbkdf2(({String pin, List<int> salt, int rounds}) job) {
  final hmac = Hmac(sha256, utf8.encode(job.pin));
  var u = hmac.convert([...job.salt, 0, 0, 0, 1]).bytes;
  final out = List<int>.of(u);
  for (var i = 1; i < job.rounds; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}

@visibleForTesting
List<int> pbkdf2ForTest(String pin, List<int> salt, int rounds) =>
    _pbkdf2((pin: pin, salt: salt, rounds: rounds));

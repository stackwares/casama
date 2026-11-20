import 'package:biometric_signature/biometric_signature.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

/// Something stopped the screen-lock check, said plainly.
class DeviceKeyProblem implements Exception {
  const DeviceKeyProblem(this.message, {this.gone = false});
  final String message;

  /// This device's key no longer works (removed, or the device's lock changed): set it up again.
  final bool gone;
  @override
  String toString() => message;
}

/// The admin console's screen-lock check (D-453). A P-256 key made in the device's secure hardware
/// (Secure Enclave on iPhone and iPad, Keystore on Android), usable only after Face ID, a
/// fingerprint or the device passcode, signs a one-time challenge from the server. The server keeps
/// the public half; the private half never leaves the chip. Overridden in tests.
class AdminDeviceKeys {
  AdminDeviceKeys({BiometricSignature? plugin})
    : _plugin = plugin ?? BiometricSignature();
  final BiometricSignature _plugin;

  static String _pref(String userId) => 'casama.adminDeviceKey.$userId';
  static String _alias(String userId) => 'casama-admin-$userId';
  static String _declinedPref(String userId) =>
      'casama.adminDeviceKeyDeclined.$userId';

  /// Phones and tablets with a screen lock. Not the web, and not computers yet (the Mac needs a
  /// signed build with keychain access for the Secure Enclave).
  Future<bool> available() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _plugin.isDeviceLockSet();
    } catch (_) {
      return false;
    }
  }

  /// The server's id for this device's key, when this device is set up for [userId].
  Future<String?> keyId(String? userId) async {
    if (userId == null) return null;
    return (await SharedPreferences.getInstance()).getString(_pref(userId));
  }

  Future<bool> declined(String userId) async =>
      (await SharedPreferences.getInstance()).getBool(_declinedPref(userId)) ??
      false;

  Future<void> setDeclined(String userId, bool value) async =>
      (await SharedPreferences.getInstance()).setBool(
        _declinedPref(userId),
        value,
      );

  /// Makes this device's key (Face ID or the passcode once) and registers its public half. Needs
  /// a fresh check that isn't the PIN. False when the person closed the system sheet.
  Future<bool> enroll(
    Backend backend, {
    required String name,
    required String reason,
  }) async {
    final userId = backend.userId;
    if (userId == null) return false;
    final made = await _plugin.createKeys(
      keyAlias: _alias(userId),
      config: CreateKeysConfig(
        signatureType: SignatureType.ecdsa,
        enforceBiometric: true,
        useDeviceCredentials: true,
        // Adding a face or a finger keeps the key; the passcode works anyway.
        setInvalidatedByBiometricEnrollment: false,
      ),
      promptMessage: reason,
    );
    final publicKey = made.publicKey;
    if (made.code == BiometricError.userCanceled ||
        made.code == BiometricError.systemCanceled) {
      return false;
    }
    if (publicKey == null || publicKey.isEmpty) {
      throw DeviceKeyProblem(made.error ?? "This device couldn't make a key.");
    }
    final key = await backend.addAdminDeviceKey(name, publicKey);
    await (await SharedPreferences.getInstance()).setString(
      _pref(userId),
      key.id,
    );
    await setDeclined(userId, false);
    return true;
  }

  /// Signs the server's challenge after Face ID or the passcode. When the server recorded the
  /// check; null when the person closed the sheet. Throws [DeviceKeyProblem] with [gone] when the
  /// key no longer works, after forgetting it here.
  Future<DateTime?> check(Backend backend, {required String reason}) async {
    final userId = backend.userId;
    final id = await keyId(userId);
    if (userId == null || id == null) {
      throw const DeviceKeyProblem(
        'This device isn\'t set up for Face ID.',
        gone: true,
      );
    }
    final challenge = await backend.adminDeviceChallenge(id);
    if (challenge == null) {
      await forget(userId);
      throw const DeviceKeyProblem(
        'This device was removed. Set up Face ID again.',
        gone: true,
      );
    }
    final signed = await _plugin.createSignature(
      payload: 'casama-admin-check:${challenge.challenge}',
      keyAlias: _alias(userId),
      config: CreateSignatureConfig(allowDeviceCredentials: true),
      promptMessage: reason,
    );
    switch (signed.code) {
      case BiometricError.userCanceled || BiometricError.systemCanceled:
        return null;
      case BiometricError.keyNotFound || BiometricError.keyInvalidated:
        await forget(userId);
        throw const DeviceKeyProblem(
          'This device\'s key no longer works. Set up Face ID again.',
          gone: true,
        );
      default:
        break;
    }
    final signature = signed.signature;
    if (signature == null || signature.isEmpty) {
      throw DeviceKeyProblem(
        signed.error ?? 'Face ID didn\'t work. Try again.',
      );
    }
    return backend.adminDeviceCheck(challenge.id, signature);
  }

  /// Forgets this device's key here (the server's copy is removed under Admin → Security).
  Future<void> forget(String userId) async {
    await (await SharedPreferences.getInstance()).remove(_pref(userId));
    try {
      await _plugin.deleteKeys(keyAlias: _alias(userId));
    } catch (_) {}
  }
}

final adminDeviceKeysProvider = Provider<AdminDeviceKeys>(
  (ref) => AdminDeviceKeys(),
);

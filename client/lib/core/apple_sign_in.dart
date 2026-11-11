import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// iOS and macOS show Apple's own sheet. Everywhere else, Continue with Apple opens the browser.
bool get nativeAppleSignIn =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

/// Hex SHA-256 of [raw]. Apple puts this in the identity token; Supabase checks the raw nonce.
String appleNonceHash(String raw) => sha256.convert(utf8.encode(raw)).toString();

/// The name Apple shares, and only on the first authorization. Blank parts are left out.
/// Longer than a profile name allows (120) is cut to fit.
String? appleFullName(String? given, String? family) {
  final name = [given, family].map((part) => part?.trim()).whereType<String>().where((part) => part.isNotEmpty).join(' ');
  if (name.isEmpty) return null;
  return name.length <= 120 ? name : name.substring(0, 120);
}

/// The system sheet never opened, so the browser flow can still sign the person in.
/// An unsigned local Mac build has no Sign in with Apple entitlement and fails this way.
bool appleSheetUnavailable(Object error) {
  if (error is SignInWithAppleNotSupportedException) return true;
  if (error is SignInWithAppleAuthorizationException) {
    return error.code == AuthorizationErrorCode.notHandled || error.code == AuthorizationErrorCode.unknown;
  }
  return false;
}

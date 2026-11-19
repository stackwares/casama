import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// A refused Apple or Google sign-in that still knows which address the sheet gave (D-427): the
/// invite gate's sheets fill it in, so nobody types again what they just chose. For Apple's
/// "Hide My Email" it is the private relay address, which is the one Auth checks.
class IdTokenAuthException extends sb.AuthException {
  const IdTokenAuthException(
    super.message, {
    super.statusCode,
    super.code,
    this.email,
  });

  final String? email;
}

/// The `email` claim inside an ID token, read without checking the signature: only to fill in a
/// form field. Null when the token has none or can't be read.
String? emailInIdToken(String idToken) {
  try {
    final parts = idToken.split('.');
    if (parts.length < 2) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final email = payload is Map ? payload['email'] : null;
    return email is String && email.contains('@') ? email.trim() : null;
  } on FormatException {
    return null;
  }
}

/// Runs an ID-token sign-in; an Auth refusal comes back carrying the token's address.
Future<T> withIdTokenEmail<T>(
  String idToken,
  Future<T> Function() signIn,
) async {
  try {
    return await signIn();
  } on sb.AuthException catch (e) {
    if (e is IdTokenAuthException) rethrow;
    throw IdTokenAuthException(
      e.message,
      statusCode: e.statusCode,
      code: e.code,
      email: emailInIdToken(idToken),
    );
  }
}

/// Apple's private relay addresses ("Hide My Email").
bool isAppleRelayEmail(String email) =>
    email.trim().toLowerCase().endsWith('@privaterelay.appleid.com');

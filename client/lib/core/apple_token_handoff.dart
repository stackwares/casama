import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sign in with Apple token handoff (D-420, App Store 5.1.1(v)).
///
/// Deleting the account has to revoke the person's Apple tokens, and Supabase Auth keeps none the
/// server can revoke. So right after an Apple sign-in the app hands the server what Apple gave it:
/// the system sheet's one-time authorization code (iOS and macOS), or the browser sign-in's
/// refresh token (Supabase Auth's provider refresh token). The server checks it with Apple and keeps
/// a refresh token until the account is deleted.
///
/// Never in the way of signing in: every failure is swallowed.
class AppleTokenHandoff {
  AppleTokenHandoff._();

  static const path = '/v1/me/apple-sign-in';

  /// Marks that a browser sign-in with Apple has started, so the provider refresh token that comes
  /// back is known to be Apple's. Kept on disk: on the web the page reloads on the way back.
  static const _pendingKey = 'apple_browser_sign_in_started';

  /// A browser sign-in finished later than this was not this one.
  static const pendingFor = Duration(minutes: 15);

  static Future<void> markBrowserSignInStarted({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _pendingKey,
        (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Another provider's sign-in started: whatever token comes back isn't Apple's.
  static Future<void> clearBrowserSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingKey);
    } catch (_) {}
  }

  /// True (once) when an Apple browser sign-in started within [pendingFor].
  static Future<bool> takeBrowserSignIn({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final started = prefs.getInt(_pendingKey);
      if (started == null) return false;
      await prefs.remove(_pendingKey);
      final age = (now ?? DateTime.now()).difference(
        DateTime.fromMillisecondsSinceEpoch(started),
      );
      return !age.isNegative && age <= pendingFor;
    } catch (_) {
      return false;
    }
  }

  /// The request body for [authorizationCode] (the sheet) or [refreshToken] (the browser). Null
  /// when there's nothing to send.
  static Map<String, String>? body({
    String? authorizationCode,
    String? refreshToken,
  }) {
    final code = authorizationCode?.trim() ?? '';
    if (code.isNotEmpty) return {'authorization_code': code};
    final refresh = refreshToken?.trim() ?? '';
    if (refresh.isNotEmpty) return {'refresh_token': refresh};
    return null;
  }

  /// Sends it to the server. A server without the Sign in with Apple key answers `stored: false`;
  /// an older server without the route answers 404. Neither, nor any error, reaches the person.
  static Future<void> send(
    Dio dio,
    Map<String, String> headers, {
    String? authorizationCode,
    String? refreshToken,
  }) async {
    final data = body(
      authorizationCode: authorizationCode,
      refreshToken: refreshToken,
    );
    if (data == null || headers.isEmpty) return;
    try {
      await dio
          .post<Object>(
            path,
            data: data,
            options: Options(headers: headers, contentType: 'application/json'),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }
}

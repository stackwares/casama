import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('casama/web_auth');

/// macOS opens browser sign-ins (Apple without its own sheet, Google, SSO) in the system's sign-in
/// window over the app, which shares the browser's cookies and passkeys, instead of switching to
/// the browser.
bool get webAuthSheetPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// The sign-in window couldn't open, so the caller can use the browser instead.
class WebAuthUnavailable implements Exception {
  const WebAuthUnavailable([this.message]);
  final String? message;
}

/// Opens [url] in the sign-in window and waits for the server to send it to a [scheme]:// link.
/// Returns that link, or null when the person closed the window.
Future<Uri?> openWebAuthSheet(Uri url, {required String scheme}) async {
  try {
    final callback = await _channel.invokeMethod<String>('authenticate', {
      'url': url.toString(),
      'scheme': scheme,
    });
    return callback == null ? null : Uri.parse(callback);
  } on MissingPluginException {
    throw const WebAuthUnavailable();
  } on PlatformException catch (e) {
    if (e.code == 'canceled') return null;
    if (e.code == 'unavailable') throw WebAuthUnavailable(e.message);
    rethrow;
  }
}

/// The sign-in code in the link the server sent back, or the server's reason it has none
/// (`error_description`, then `error`, in the query or after the #).
({String? code, String? error}) oauthCallbackResult(Uri callback) {
  final params = {
    if (callback.fragment.contains('='))
      ...Uri.splitQueryString(callback.fragment),
    ...callback.queryParameters,
  };
  final code = params['code'];
  if (code != null && code.isNotEmpty) return (code: code, error: null);
  return (
    code: null,
    error:
        params['error_description'] ??
        params['error'] ??
        'The sign-in page did not send a sign-in code.',
  );
}

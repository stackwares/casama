import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Windows and Linux builds register nothing for casama:// links, so a browser sign-in (Apple,
/// Google, SSO) returns to a listener on this computer instead. iOS, macOS and Android open
/// casama:// links, so they keep that.
bool get loopbackSignInPlatform => Platform.isWindows || Platform.isLinux;

/// One browser sign-in waiting to come back. Starting another closes the one before it, so a
/// second tap never leaves two listeners.
class LoopbackSignIn {
  LoopbackSignIn._(this._server) : _port = _server.port;

  final HttpServer _server;
  final int _port;
  static LoopbackSignIn? _current;

  /// Listens on a free port on 127.0.0.1 only, never on the network.
  static Future<LoopbackSignIn> start() async {
    await _current?.close();
    final next = LoopbackSignIn._(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    return _current = next;
  }

  /// Where the server sends the browser after sign-in. The server's allow list has
  /// http://127.0.0.1:*/auth/callback for this.
  String get redirectUrl => 'http://127.0.0.1:$_port/auth/callback';

  /// Waits for the browser to come back, runs [finish] with the query (it returns an error to show,
  /// or null when signed in), and tells the browser tab how it went. Gives up after [timeout] so
  /// an abandoned sign-in leaves nothing listening.
  Future<void> wait(
    Future<String?> Function(Map<String, String> query) finish, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final timer = Timer(timeout, close);
    try {
      await for (final request in _server) {
        if (request.uri.path != '/auth/callback') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
        String? error;
        try {
          error = await finish(request.uri.queryParameters);
        } catch (e) {
          error = '$e';
        }
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..headers.set('Cache-Control', 'no-store')
          ..write(callbackPage(error));
        await request.response.close();
        break;
      }
    } finally {
      timer.cancel();
      await close();
    }
  }

  Future<void> close() async {
    if (identical(_current, this)) _current = null;
    await _server.close(force: true);
  }
}

/// The page the browser tab shows once it is back: signed in, or what went wrong.
String callbackPage(String? error) {
  final title = error == null ? 'You are signed in' : 'Sign-in did not finish';
  final body = error == null
      ? 'Go back to Casama. You can close this tab.'
      : '${const HtmlEscape().convert(error)}<br>Go back to Casama and try again.';
  return '<!doctype html><html lang="en"><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1"><title>Casama</title>'
      '<style>body{font-family:system-ui,sans-serif;display:grid;place-items:center;min-height:100vh;'
      'margin:0;background:#faf9f7;color:#1c1b1a}main{max-width:28rem;padding:1.5rem;text-align:center}'
      '@media (prefers-color-scheme:dark){body{background:#151413;color:#f2f0ed}}</style></head>'
      '<body><main><h1>$title</h1><p>$body</p></main></body></html>';
}

/// ChatGPT plan sign-in through a loopback listener (desktop apps and the CLI; `dart:io` only).
///
/// OpenAI redirects only to `http://127.0.0.1:<port>/auth/callback`, so this listens on the
/// loopback address, asks the Casama server to start a sign-in, opens the browser, and relays the
/// code back to the server. The server exchanges it and keeps the tokens; none reach this device.
library;

import 'dart:async';
import 'dart:io';

import 'package:casama_api/casama_api.dart';

/// The browser was closed, the person declined, or the sign-in timed out.
class ChatGptSignInException implements Exception {
  ChatGptSignInException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

const _donePage = '''<!doctype html><html><head><meta charset="utf-8"><title>Signed in</title>
<style>body{font-family:system-ui,sans-serif;display:grid;place-items:center;height:100vh;margin:0}</style>
</head><body><div><h2>You can close this tab.</h2><p>Return to the app to finish connecting your ChatGPT plan.</p></div></body></html>''';

/// Runs the whole sign-in and returns the connected (or updated) credential.
///
/// [openBrowser] opens the authorize URL (the CLI may also print it). Pass [credentialId] to
/// reconnect an existing ChatGPT credential.
Future<Credential> signInWithChatGpt(
  CredentialsApi api, {
  required String orgId,
  required Future<void> Function(Uri url) openBrowser,
  String? credentialId,
  Duration timeout = const Duration(minutes: 10),
}) async {
  // Never `localhost`: OpenAI requires the literal loopback address.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  try {
    final start = (await api.startChatGptSignIn(
      chatGptSignInStartRequest: ChatGptSignInStartRequest(
        orgId: orgId,
        redirectPort: server.port,
        credentialId: credentialId,
      ),
    ))
        .data!;
    final callback = Completer<Map<String, String>>();
    final sub = server.listen((req) async {
      if (req.uri.path != '/auth/callback') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final q = req.uri.queryParameters;
      req.response.headers.contentType = ContentType.html;
      req.response.write(_donePage);
      await req.response.close();
      // Only the callback for this sign-in counts.
      if (q['state'] == start.state && !callback.isCompleted) callback.complete(q);
    });
    try {
      await openBrowser(Uri.parse(start.authorizeUrl));
      final q = await callback.future.timeout(
        timeout,
        onTimeout: () => throw ChatGptSignInException('timeout', 'ChatGPT sign-in timed out. Try again.'),
      );
      return (await api.completeChatGptSignIn(
        chatGptSignInCompleteRequest: ChatGptSignInCompleteRequest(
          state: start.state,
          code: q['code'],
          clientId: q['client_id'],
          error: q['error'],
          errorDescription: q['error_description'],
        ),
      ))
          .data!;
    } finally {
      await sub.cancel();
    }
  } finally {
    await server.close(force: true);
  }
}

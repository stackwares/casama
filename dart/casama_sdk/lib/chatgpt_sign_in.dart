/// ChatGPT plan sign-in through a loopback listener (desktop apps and the CLI; `dart:io` only).
///
/// OpenAI redirects only to `http://127.0.0.1:<port>/auth/callback`, so this listens on the
/// loopback address, asks the Casama server to start a sign-in, opens the browser, and relays the
/// code back to the server. The server exchanges it and keeps the tokens; none reach this device.
library;

import 'dart:async';
import 'dart:convert' show HtmlEscape;
import 'dart:io';

import 'package:casama_api/casama_api.dart';

import 'src/client.dart' show problemOf;

/// The browser was closed, the person declined, or the sign-in timed out.
class ChatGptSignInException implements Exception {
  ChatGptSignInException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

String _page(String title, String line) => '<!doctype html><html><head><meta charset="utf-8"><title>${const HtmlEscape().convert(title)}</title>'
    '<style>body{font-family:system-ui,sans-serif;display:grid;place-items:center;height:100vh;margin:0;text-align:center}</style>'
    '</head><body><div><h2>${const HtmlEscape().convert(title)}</h2><p>${const HtmlEscape().convert(line)}</p></div></body></html>';

/// The server's code for OpenAI's first refusal: it issues Casama's client on that first sign-in
/// and refuses its code, and the next sign-in (with that client) goes through.
const _retryCode = 'chatgpt_sign_in_retry';

/// Runs the whole sign-in and returns the connected (or updated) credential.
///
/// [openBrowser] opens the authorize URL (the CLI may also print it). Pass [credentialId] to
/// reconnect an existing ChatGPT credential.
///
/// The first sign-in on a server ends with OpenAI refusing the code once (see [_retryCode]). The
/// browser tab that came back is kept open meanwhile; on that refusal a new sign-in starts and the
/// same tab is sent back to OpenAI, where the person is already signed in. So they never see the
/// failure, and it is tried again only once.
Future<Credential> signInWithChatGpt(
  CredentialsApi api, {
  required String orgId,
  required Future<void> Function(Uri url) openBrowser,
  String? credentialId,
  Duration timeout = const Duration(minutes: 10),
}) async {
  // Never `localhost`: OpenAI requires the literal loopback address.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  // The browser request waiting for the outcome: answered with the next step, not left hanging.
  HttpResponse? waiting;
  Future<void> answer(String title, String line) async {
    final res = waiting;
    waiting = null;
    if (res == null) return;
    try {
      res.headers.contentType = ContentType.html;
      res.write(_page(title, line));
      await res.close();
    } catch (_) {
      // The tab was closed: nothing to tell.
    }
  }

  Future<ChatGptSignInStart> start() async => (await api.startChatGptSignIn(
        chatGptSignInStartRequest: ChatGptSignInStartRequest(
          orgId: orgId,
          redirectPort: server.port,
          credentialId: credentialId,
        ),
      ))
          .data!;

  try {
    var attempt = await start();
    var state = attempt.state;
    var callback = Completer<Map<String, String>>();
    final sub = server.listen((req) async {
      if (req.uri.path != '/auth/callback') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final q = req.uri.queryParameters;
      // Only the callback for this sign-in counts.
      if (q['state'] != state || callback.isCompleted) {
        req.response.headers.contentType = ContentType.html;
        req.response.write(_page('This sign-in is no longer current.', 'Go back to the app and start it again.'));
        await req.response.close();
        return;
      }
      waiting = req.response;
      callback.complete(q);
    });
    // Opening the browser isn't waited for: the tab it opens is held until the server answers. A
    // failure to open it ends the wait with that error.
    void launch(String url) => openBrowser(Uri.parse(url)).catchError((Object e, StackTrace st) {
          if (!callback.isCompleted) callback.completeError(e, st);
        });
    try {
      launch(attempt.authorizeUrl);
      for (var tries = 0;; tries++) {
        final q = await callback.future.timeout(
          timeout,
          onTimeout: () => throw ChatGptSignInException('timeout', 'ChatGPT sign-in timed out. Try again.'),
        );
        try {
          final cred = (await api.completeChatGptSignIn(
            chatGptSignInCompleteRequest: ChatGptSignInCompleteRequest(
              state: attempt.state,
              code: q['code'],
              clientId: q['client_id'],
              error: q['error'],
              errorDescription: q['error_description'],
            ),
          ))
              .data!;
          await answer('You can close this tab.', 'Return to the app to finish connecting your ChatGPT plan.');
          return cred;
        } catch (e) {
          final problem = problemOf(e);
          if (problem?.code == _retryCode && tries == 0) {
            // Start again with the client OpenAI just issued, and send the open tab back to it.
            attempt = await start();
            state = attempt.state;
            callback = Completer<Map<String, String>>();
            final tab = waiting;
            waiting = null;
            if (tab != null) {
              try {
                tab.statusCode = HttpStatus.found;
                tab.headers.set(HttpHeaders.locationHeader, attempt.authorizeUrl);
                await tab.close();
              } catch (_) {
                // The tab was closed: open a new one instead.
                launch(attempt.authorizeUrl);
              }
            } else {
              launch(attempt.authorizeUrl);
            }
            continue;
          }
          await answer('ChatGPT sign-in didn’t finish.', problem?.detail ?? 'Go back to the app and try again.');
          rethrow;
        }
      }
    } finally {
      await sub.cancel();
    }
  } finally {
    await server.close(force: true);
  }
}

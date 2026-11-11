import 'dart:convert';
import 'dart:io';

import 'package:casama_api/casama_api.dart';
import 'package:casama_sdk/chatgpt_sign_in.dart';
import 'package:test/test.dart';

/// A fake Casama API whose authorize URL points at a fake consent page that redirects to the
/// loopback callback, like OpenAI does.
Future<(HttpServer, List<Map<String, dynamic>>)> fakeApi({String? error}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final completes = <Map<String, dynamic>>[];
  String? redirect;
  server.listen((req) async {
    final res = req.response..headers.contentType = ContentType.json;
    if (req.uri.path == '/v1/credentials/chatgpt/start') {
      final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
      redirect = 'http://127.0.0.1:${body['redirect_port']}/auth/callback';
      res.write(jsonEncode({
        'authorize_url': 'http://127.0.0.1:${server.port}/consent',
        'redirect_uri': redirect,
        'state': 'state-0123456789abcdef',
        'expires_at': DateTime.now().toUtc().toIso8601String(),
      }));
    } else if (req.uri.path == '/consent') {
      final q = error == null
          ? 'code=c1&client_id=oaiapp_1&state=state-0123456789abcdef'
          : 'error=$error&state=state-0123456789abcdef';
      res
        ..statusCode = 302
        ..headers.set('location', '$redirect?$q');
    } else if (req.uri.path == '/v1/credentials/chatgpt/complete') {
      completes.add(jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>);
      res.write(jsonEncode({
        'id': '11111111-1111-1111-1111-111111111111',
        'org_id': '22222222-2222-2222-2222-222222222222',
        'provider': 'chatgpt',
        'label': 'ChatGPT plan',
        'base_url': null,
        'key_hint': null,
        'last_tested_at': null,
        'last_test_ok': null,
        'owner_user_id': '33333333-3333-3333-3333-333333333333',
        'status': 'ok',
        'account': 'me@example.com',
        'fallback_on_limit': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }));
    } else {
      res.statusCode = 404;
    }
    await res.close();
  });
  return (server, completes);
}

/// Stands in for the browser: follows the consent redirect to the loopback callback.
Future<void> browser(Uri url) async {
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(url)).close();
    await res.drain<void>();
  } finally {
    client.close();
  }
}

void main() {
  test('relays the loopback callback to the server and returns the credential', () async {
    final (server, completes) = await fakeApi();
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    final cred = await signInWithChatGpt(api, orgId: '22222222-2222-2222-2222-222222222222', openBrowser: browser);
    expect(cred.provider, ProviderId.chatgpt);
    expect(cred.account, 'me@example.com');
    expect(completes.single, {'state': 'state-0123456789abcdef', 'code': 'c1', 'client_id': 'oaiapp_1'});
  });

  test('passes a declined consent on for the server to report', () async {
    final (server, completes) = await fakeApi(error: 'access_denied');
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    await signInWithChatGpt(api, orgId: '22222222-2222-2222-2222-222222222222', openBrowser: browser);
    expect(completes.single['error'], 'access_denied');
    expect(completes.single.containsKey('code'), isFalse);
  });

  test('times out when the browser never comes back', () async {
    final (server, _) = await fakeApi();
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    expect(
      signInWithChatGpt(api,
          orgId: '22222222-2222-2222-2222-222222222222',
          openBrowser: (_) async {},
          timeout: const Duration(milliseconds: 200)),
      throwsA(isA<ChatGptSignInException>()),
    );
  });
}

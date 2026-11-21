import 'dart:convert';
import 'dart:io';

import 'package:casama_api/casama_api.dart';
import 'package:casama_sdk/casama_sdk.dart' show problemOf;
import 'package:casama_sdk/chatgpt_sign_in.dart';
import 'package:test/test.dart';

/// A fake Casama API whose authorize URL points at a fake consent page that redirects to the
/// loopback callback, like OpenAI does.
///
/// [refuse] is how many of the first complete calls the server answers with [refuseCode] (OpenAI's
/// first refusal); each sign-in the app starts gets its own state.
Future<(HttpServer, List<Map<String, dynamic>>)> fakeApi({String? error, int refuse = 0, String refuseCode = 'chatgpt_sign_in_retry'}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final completes = <Map<String, dynamic>>[];
  var starts = 0;
  String? redirect;
  server.listen((req) async {
    final res = req.response..headers.contentType = ContentType.json;
    if (req.uri.path == '/v1/credentials/chatgpt/start') {
      final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
      redirect = 'http://127.0.0.1:${body['redirect_port']}/auth/callback';
      starts++;
      final state = starts == 1 ? 'state-0123456789abcdef' : 'state-$starts-0123456789abcdef';
      res.write(jsonEncode({
        'authorize_url': 'http://127.0.0.1:${server.port}/consent?state=$state',
        'redirect_uri': redirect,
        'state': state,
        'expires_at': DateTime.now().toUtc().toIso8601String(),
      }));
    } else if (req.uri.path == '/consent') {
      final state = req.uri.queryParameters['state'];
      final q = error == null ? 'code=c1&client_id=oaiapp_1&state=$state' : 'error=$error&state=$state';
      res
        ..statusCode = 302
        ..headers.set('location', '$redirect?$q');
    } else if (req.uri.path == '/v1/credentials/chatgpt/complete') {
      completes.add(jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>);
      if (completes.length <= refuse) {
        res
          ..statusCode = 400
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'type': 'https://casama.ai/problems/$refuseCode',
            'title': 'Bad Request',
            'status': 400,
            'code': refuseCode,
            'detail': 'ChatGPT didn\'t accept this sign-in. Try again: the next one finishes setting up.',
          }));
        await res.close();
        return;
      }
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
        'embedding_model': null,
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

  test('tries again by itself when OpenAI refuses the first code, in the same browser tab', () async {
    final (server, completes) = await fakeApi(refuse: 1);
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    var opened = 0;
    final cred = await signInWithChatGpt(api,
        orgId: '22222222-2222-2222-2222-222222222222',
        openBrowser: (u) {
          opened++;
          return browser(u);
        });
    expect(cred.provider, ProviderId.chatgpt);
    expect(opened, 1, reason: 'the same tab goes back to OpenAI; no second window');
    expect(completes, hasLength(2));
    expect(completes[0]['state'], 'state-0123456789abcdef');
    expect(completes[1]['state'], 'state-2-0123456789abcdef');
  });

  test('retries only once, then reports the refusal', () async {
    final (server, completes) = await fakeApi(refuse: 5);
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    await expectLater(
      signInWithChatGpt(api, orgId: '22222222-2222-2222-2222-222222222222', openBrowser: browser),
      throwsA(predicate<Object>((e) => problemOf(e)?.code == 'chatgpt_sign_in_retry')),
    );
    expect(completes, hasLength(2));
  });

  test('any other refusal is reported at once, without a second try', () async {
    final (server, completes) = await fakeApi(refuse: 5, refuseCode: 'chatgpt_sign_in_declined');
    addTearDown(() => server.close(force: true));
    final api = CasamaApi(basePathOverride: 'http://127.0.0.1:${server.port}').getCredentialsApi();
    await expectLater(
      signInWithChatGpt(api, orgId: '22222222-2222-2222-2222-222222222222', openBrowser: browser),
      throwsA(predicate<Object>((e) => problemOf(e)?.code == 'chatgpt_sign_in_declined')),
    );
    expect(completes, hasLength(1));
  });
}

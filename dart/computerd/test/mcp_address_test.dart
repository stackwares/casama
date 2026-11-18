import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:casama_computerd/computerd.dart';
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

/// A local MCP server at an address, with what D-363 needs: a fixed header, MCP OAuth (metadata,
/// registration, PKCE, refresh), the older HTTP+SSE transport and a question for the person.
class FakeHttpMcp {
  late HttpServer server;
  String? apiKey;
  var oauth = false;

  /// Where the protected-resource metadata says to sign in (another host in one test).
  String? authServerOverride;
  final clients = <String, String>{}; // client id -> redirect uri
  final codes = <String, (String, String)>{}; // code -> (client id, challenge)
  final accessTokens = <String>{};
  final refreshTokens = <String>{};
  var issued = 0;
  var refreshes = 0;
  final legacy = <String, StreamController<String>>{};
  final pendingAnswers = <String, Completer<Map<String, dynamic>>>{};

  Uri get base => Uri.parse('http://127.0.0.1:${server.port}');

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_handle);
  }

  Future<void> stop() => server.close(force: true);

  Future<void> _json(
    HttpRequest r,
    int status,
    Object body, [
    Map<String, String> headers = const {},
  ]) async {
    r.response.statusCode = status;
    headers.forEach(r.response.headers.set);
    r.response.headers.contentType = ContentType.json;
    r.response.write(jsonEncode(body));
    await r.response.close();
  }

  bool _authorized(HttpRequest r) {
    if (apiKey != null && r.headers.value('x-api-key') != apiKey) return false;
    if (oauth) {
      final h = r.headers.value('authorization') ?? '';
      if (!h.startsWith('Bearer ') || !accessTokens.contains(h.substring(7))) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic>? _answer(Map<String, dynamic> m) {
    final id = m['id'];
    switch (m['method']) {
      case 'initialize':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'protocolVersion': '2025-06-18',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'fake-http', 'version': '1'},
          },
        };
      case 'tools/list':
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'tools': [
              {
                'name': 'echo',
                'inputSchema': {'type': 'object'},
              },
              {
                'name': 'ask',
                'inputSchema': {'type': 'object'},
              },
            ],
          },
        };
      case 'tools/call':
        final args = (m['params']['arguments'] as Map?) ?? {};
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'content': [
              {'type': 'text', 'text': 'echo: ${args['text']}'},
            ],
          },
        };
    }
    return null;
  }

  Future<void> _handle(HttpRequest r) async {
    final path = r.uri.path;
    if (path == '/.well-known/oauth-protected-resource/mcp' && oauth) {
      return _json(r, 200, {
        'resource': '$base/mcp',
        'authorization_servers': [authServerOverride ?? '$base'],
        'scopes_supported': ['tools:read', 'tools:run'],
      });
    }
    if (path == '/.well-known/oauth-authorization-server' && oauth) {
      return _json(r, 200, {
        'issuer': '$base',
        'authorization_endpoint': '$base/authorize',
        'token_endpoint': '$base/token',
        'registration_endpoint': '$base/register',
        'code_challenge_methods_supported': ['S256'],
      });
    }
    if (path == '/register' && r.method == 'POST') {
      final body = jsonDecode(await utf8.decodeStream(r)) as Map;
      final id = 'client-${clients.length + 1}';
      clients[id] = (body['redirect_uris'] as List).single as String;
      return _json(r, 201, {'client_id': id});
    }
    if (path == '/authorize') {
      // Stands in for the person approving in the browser.
      final q = r.uri.queryParameters;
      final code = 'code-${codes.length + 1}';
      codes[code] = (q['client_id']!, q['code_challenge']!);
      final back = Uri.parse(clients[q['client_id']]!)
          .replace(queryParameters: {'code': code, 'state': q['state']!});
      r.response
        ..statusCode = 302
        ..headers.set('location', back.toString());
      return r.response.close();
    }
    if (path == '/token' && r.method == 'POST') {
      final form = Uri.splitQueryString(await utf8.decodeStream(r));
      if (form['grant_type'] == 'authorization_code') {
        final c = codes.remove(form['code']);
        if (c == null ||
            c.$1 != form['client_id'] ||
            pkceChallenge(form['code_verifier']!) != c.$2) {
          return _json(r, 400, {'error': 'invalid_grant'});
        }
      } else if (form['grant_type'] == 'refresh_token') {
        if (!refreshTokens.remove(form['refresh_token'])) {
          return _json(r, 400, {
            'error': 'invalid_grant',
            'error_description': 'refresh token revoked',
          });
        }
        refreshes++;
      } else {
        return _json(r, 400, {'error': 'unsupported_grant_type'});
      }
      issued++;
      final at = 'at-$issued', rt = 'rt-$issued';
      accessTokens.add(at);
      refreshTokens.add(rt);
      return _json(r, 200, {
        'access_token': at,
        'refresh_token': rt,
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'tools:read tools:run',
      });
    }
    if (path == '/sse' && r.method == 'GET') {
      if (!_authorized(r)) return _json(r, 401, {'error': 'unauthorized'});
      final id = 's${legacy.length + 1}';
      final c = StreamController<String>();
      legacy[id] = c;
      r.response.headers.contentType = ContentType('text', 'event-stream');
      r.response.bufferOutput = false;
      r.response.write('event: endpoint\ndata: /messages?session=$id\n\n');
      await r.response.flush();
      await for (final chunk in c.stream) {
        r.response.write(chunk);
        await r.response.flush();
      }
      return r.response.close();
    }
    if (path == '/messages' && r.method == 'POST') {
      final c = legacy[r.uri.queryParameters['session']];
      final m = (jsonDecode(await utf8.decodeStream(r)) as Map)
          .cast<String, dynamic>();
      r.response.statusCode = 202;
      await r.response.close();
      final a = _answer(m);
      if (a != null) c?.add('event: message\ndata: ${jsonEncode(a)}\n\n');
      return;
    }
    if (path == '/mcp' && r.method == 'POST') {
      if (!_authorized(r)) {
        return _json(
          r,
          401,
          {'error': 'unauthorized'},
          oauth
              ? {
                  'www-authenticate':
                      'Bearer resource_metadata="$base/.well-known/oauth-protected-resource/mcp"',
                }
              : {},
        );
      }
      final decoded = jsonDecode(await utf8.decodeStream(r));
      if (decoded is Map &&
          decoded['method'] == null &&
          decoded['id'] != null) {
        // The client's answer to our question.
        pendingAnswers
            .remove('${decoded['id']}')
            ?.complete(
              (decoded['result'] as Map?)?.cast<String, dynamic>() ??
                  {'code': (decoded['error'] as Map?)?['code']},
            );
        r.response.statusCode = 202;
        return r.response.close();
      }
      final m = (decoded as Map).cast<String, dynamic>();
      if (m['method'] == 'notifications/initialized' || m['id'] == null) {
        r.response.statusCode = 202;
        return r.response.close();
      }
      if (m['method'] == 'tools/call' && m['params']['name'] == 'ask') {
        // Asks the person a question on this request's stream, then answers with what they said.
        r.response.headers.contentType = ContentType('text', 'event-stream');
        r.response.headers.set('mcp-session-id', 'sess-1');
        r.response.bufferOutput = false;
        final qid = 'q${pendingAnswers.length + 1}';
        final answer = Completer<Map<String, dynamic>>();
        pendingAnswers[qid] = answer;
        r.response.write(
          'event: message\ndata: ${jsonEncode({
            'jsonrpc': '2.0',
            'id': qid,
            'method': 'elicitation/create',
            'params': {
              'message': 'Your name?',
              'requestedSchema': {
                'type': 'object',
                'properties': {
                  'name': {'type': 'string'},
                },
              },
            },
          })}\n\n',
        );
        await r.response.flush();
        final got = await answer.future;
        final text = got['action'] == 'accept'
            ? 'hello ${got['content']['name']}'
            : 'no answer (${got['action'] ?? got['code']})';
        r.response.write(
          'event: message\ndata: ${jsonEncode({
            'jsonrpc': '2.0',
            'id': m['id'],
            'result': {
              'content': [
                {'type': 'text', 'text': text},
              ],
            },
          })}\n\n',
        );
        return r.response.close();
      }
      r.response.headers.set('mcp-session-id', 'sess-1');
      return _json(
        r,
        200,
        _answer(m) ??
            {
              'jsonrpc': '2.0',
              'id': m['id'],
              'error': {'code': -32601, 'message': 'nope'},
            },
      );
    }
    // POST to the legacy server's /sse, or anything unknown.
    return _json(r, 404, {'error': 'not found'});
  }
}

/// Follows the sign-in like a browser would: the authorize page redirects to the callback.
Future<Map<String, String>> approveInBrowser(Uri url) async {
  final c = HttpClient();
  final req = await c.getUrl(url);
  req.followRedirects = false;
  final res = await req.close();
  await res.drain<void>();
  c.close();
  return Uri.parse(res.headers.value('location')!).queryParameters;
}

void main() {
  late Directory home;
  late FakeHttpMcp fake;
  Computerd? server;
  late Uri base;
  final headers = {
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
    'accept': 'application/json, text/event-stream',
  };
  final saved = <String, McpOAuthCredentials?>{};

  Future<void> start(Map<String, LocalMcpServer> servers) async {
    server = Computerd(
      ComputerdConfig(
        home: home.path,
        token: token,
        port: 0,
        address: '127.0.0.1',
        allowedRoots: [home.path],
        capabilities: {'mcp'},
        mcpServers: servers,
        onMcpCredentials: (key, creds) => saved[key] = creds,
      ),
    );
    await server!.start();
    base = Uri.parse('http://127.0.0.1:${server!.port}');
  }

  Future<http.Response> post(String key, Object body) => http.post(
    base.replace(path: '/mcp/$key'),
    headers: headers,
    body: jsonEncode(body),
  );

  List<Map<String, dynamic>> events(String body) => [
    for (final line in const LineSplitter().convert(body))
      if (line.startsWith('data:'))
        (jsonDecode(line.substring(5).trim()) as Map).cast<String, dynamic>(),
  ];

  Future<List<String>> toolNames(String key) async {
    final res = await post(key, {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/list',
    });
    expect(res.statusCode, 200, reason: res.body);
    return [
      for (final t in events(res.body).single['result']['tools'] as List)
        '${t['name']}',
    ];
  }

  setUp(() async {
    home = Directory.systemTemp.createTempSync('mcp-addr');
    fake = FakeHttpMcp();
    await fake.start();
    saved.clear();
  });
  tearDown(() async {
    await server?.stop();
    server = null;
    await fake.stop();
    home.deleteSync(recursive: true);
  });

  test('a fixed header reaches the server; a wrong one is reported as a refused token', () async {
    fake.apiKey = 'k-123';
    await start({
      'good': LocalMcpServer(
        key: 'good',
        kind: 'loopback',
        url: '${fake.base}/mcp',
        headers: {'x-api-key': 'k-123'},
      ),
      'bad': LocalMcpServer(
        key: 'bad',
        kind: 'loopback',
        url: '${fake.base}/mcp',
        headers: {'x-api-key': 'wrong'},
        label: 'My server',
      ),
    });
    expect(await toolNames('good'), ['echo', 'ask']);
    final bad = await post('bad', {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/list',
    });
    expect(bad.statusCode, 401);
    expect(jsonDecode(bad.body)['code'], 'mcp_token_refused');
    expect(
      jsonDecode(bad.body)['message'],
      contains('My server refused its token'),
    );
  });

  test('signs in with MCP OAuth, refreshes on its own, and asks again when refreshing fails', () async {
    fake.oauth = true;
    final mcpUrl = Uri.parse('${fake.base}/mcp');

    // Without a sign-in the bridge says so.
    await start({
      't3': LocalMcpServer(
        key: 't3',
        kind: 'loopback',
        url: '$mcpUrl',
        label: 'T3 Code',
      ),
    });
    final unsigned = await post('t3', {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/list',
    });
    expect(unsigned.statusCode, 401);
    expect(jsonDecode(unsigned.body)['code'], 'mcp_sign_in_needed');
    expect(
      jsonDecode(unsigned.body)['message'],
      contains('T3 Code needs a sign-in'),
    );
    await server!.stop();

    // The desktop app's sign-in.
    final oauth = McpOAuth();
    final probe = await oauth.probe(mcpUrl);
    expect(probe.needsSignIn, isTrue);
    expect(
      probe.resourceMetadata.toString(),
      '${fake.base}/.well-known/oauth-protected-resource/mcp',
    );
    final startSignIn = await oauth.signInUrl(
      mcpUrl,
      redirectUri: 'http://127.0.0.1:9/auth/callback',
      resourceMetadata: probe.resourceMetadata,
    );
    expect(startSignIn.url.queryParameters['code_challenge_method'], 'S256');
    expect(startSignIn.url.queryParameters['resource'], '$mcpUrl');
    expect(startSignIn.url.queryParameters['scope'], 'tools:read tools:run');
    final creds = await oauth.finishSignIn(
      startSignIn,
      await approveInBrowser(startSignIn.url),
    );
    expect(creds.accessToken, 'at-1');
    expect(creds.refreshToken, 'rt-1');
    // A callback for another request is refused.
    await expectLater(
      oauth.finishSignIn(startSignIn, {'code': 'x', 'state': 'other'}),
      throwsA(isA<McpOAuthError>()),
    );

    // The round trip through JSON keeps everything the bridge needs.
    final stored = McpOAuthCredentials.fromJson(
      jsonDecode(jsonEncode(creds.toJson())) as Map<String, dynamic>,
    );
    await start({
      't3': LocalMcpServer(
        key: 't3',
        kind: 'loopback',
        url: '$mcpUrl',
        oauth: stored,
        label: 'T3 Code',
      ),
    });
    expect(await toolNames('t3'), ['echo', 'ask']);

    // The server drops the access token: the bridge refreshes once and carries on.
    fake.accessTokens.clear();
    final call = await post('t3', {
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'tools/call',
      'params': {
        'name': 'echo',
        'arguments': {'text': 'hi'},
      },
    });
    expect(call.statusCode, 200, reason: call.body);
    expect(
      events(call.body).single['result']['content'][0]['text'],
      'echo: hi',
    );
    expect(fake.refreshes, 1);
    expect(
      saved['t3']?.accessToken,
      'at-2',
      reason: 'the app is given the new tokens to keep',
    );

    // Both tokens revoked: the person has to sign in again.
    fake.accessTokens.clear();
    fake.refreshTokens.clear();
    final again = await post('t3', {
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/call',
      'params': {
        'name': 'echo',
        'arguments': {'text': 'hi'},
      },
    });
    expect(again.statusCode, 401, reason: again.body);
    expect(jsonDecode(again.body)['code'], 'mcp_sign_in_needed');
    expect(saved.containsKey('t3') && saved['t3'] == null, isTrue);
    oauth.close();
  });

  test('refuses a sign-in that sends the browser to another host', () async {
    fake.oauth = true;
    fake.authServerOverride = 'https://login.example.com';
    final oauth = McpOAuth();
    await expectLater(
      oauth.signInUrl(
        Uri.parse('${fake.base}/mcp'),
        redirectUri: 'http://127.0.0.1:9/auth/callback',
      ),
      throwsA(
        isA<McpOAuthError>().having(
          (e) => e.message,
          'message',
          contains('login.example.com'),
        ),
      ),
    );
    oauth.close();
  });

  test('bridges the older HTTP+SSE transport', () async {
    await start({
      'old': LocalMcpServer(
        key: 'old',
        kind: 'loopback',
        url: '${fake.base}/sse',
      ),
    });
    expect(await toolNames('old'), ['echo', 'ask']);
    final call = await post('old', {
      'jsonrpc': '2.0',
      'id': 5,
      'method': 'tools/call',
      'params': {
        'name': 'echo',
        'arguments': {'text': 'legacy'},
      },
    });
    expect(
      events(call.body).single['result']['content'][0]['text'],
      'echo: legacy',
    );
  });

  test("passes the server's question to a caller that can answer it, and its answer back", () async {
    await start({
      'q': LocalMcpServer(key: 'q', kind: 'loopback', url: '${fake.base}/mcp'),
    });
    final init = await post('q', {
      'jsonrpc': '2.0',
      'id': 0,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-06-18',
        'capabilities': {'elicitation': {}},
        'clientInfo': {'name': 'w', 'version': '1'},
      },
    });
    expect(init.statusCode, 200);

    final client = http.Client();
    final req = http.Request('POST', base.replace(path: '/mcp/q'))
      ..headers.addAll(headers)
      ..body = jsonEncode({
        'jsonrpc': '2.0',
        'id': 9,
        'method': 'tools/call',
        'params': {'name': 'ask', 'arguments': {}},
      });
    final streamed = await client.send(req);
    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((l) => l.startsWith('data:'))
        .map(
          (l) => (jsonDecode(l.substring(5).trim()) as Map)
              .cast<String, dynamic>(),
        );
    final it = StreamIterator(lines);
    expect(await it.moveNext(), isTrue);
    final question = it.current;
    expect(question['method'], 'elicitation/create');
    expect(question['params']['message'], 'Your name?');
    expect(
      question['id'],
      startsWith('e'),
      reason: 'the caller sees an id of its own',
    );

    final answer = await post('q', {
      'jsonrpc': '2.0',
      'id': question['id'],
      'result': {
        'action': 'accept',
        'content': {'name': 'Ann'},
      },
    });
    expect(answer.statusCode, 202);
    expect(await it.moveNext(), isTrue);
    expect(it.current['id'], 9);
    expect(it.current['result']['content'][0]['text'], 'hello Ann');
    await it.cancel();
    client.close();
  });

  test(
    "a caller that can't answer questions gets them refused for it",
    () async {
      await start({
        'q': LocalMcpServer(
          key: 'q',
          kind: 'loopback',
          url: '${fake.base}/mcp',
        ),
      });
      await post('q', {
        'jsonrpc': '2.0',
        'id': 0,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2025-06-18',
          'capabilities': {},
          'clientInfo': {'name': 'w', 'version': '1'},
        },
      });
      final res = await post('q', {
        'jsonrpc': '2.0',
        'id': 9,
        'method': 'tools/call',
        'params': {'name': 'ask', 'arguments': {}},
      });
      final last = events(res.body).last;
      expect(last['id'], 9);
      expect(last['result']['content'][0]['text'], contains('no answer'));
    },
  );

  test('an address server that is not running says so', () async {
    final port = fake.server.port;
    await fake.stop();
    await start({
      'gone': LocalMcpServer(
        key: 'gone',
        kind: 'loopback',
        url: 'http://127.0.0.1:$port/mcp',
        label: 'Gone',
      ),
    });
    final res = await post('gone', {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'tools/list',
    });
    expect(res.statusCode, 502);
    expect(jsonDecode(res.body)['code'], 'mcp_unreachable');
    fake = FakeHttpMcp();
    await fake.start();
  });

  test(
    'addresses: this computer only, unless the person allows their network',
    () {
      Uri u(String s) => Uri.parse(s);
      expect(localMcpAddressProblem(u('http://127.0.0.1:3773/mcp')), isNull);
      expect(localMcpAddressProblem(u('http://[::1]:3773/mcp')), isNull);
      expect(
        localMcpAddressProblem(u('http://192.168.1.5:8080/mcp')),
        isNotNull,
      );
      expect(
        localMcpAddressProblem(u('https://mcp.example.com/mcp')),
        isNotNull,
      );

      expect(
        localMcpAddressProblem(u('http://192.168.1.5:8080/mcp'), network: true),
        isNull,
      );
      expect(
        localMcpAddressProblem(u('http://10.0.0.2/mcp'), network: true),
        isNull,
      );
      expect(
        localMcpAddressProblem(u('http://172.20.0.2/mcp'), network: true),
        isNull,
      );
      expect(
        localMcpAddressProblem(u('http://100.100.1.1/mcp'), network: true),
        isNull,
        reason: 'Tailscale',
      );
      expect(
        localMcpAddressProblem(u('http://nas.local:8080/mcp'), network: true),
        isNull,
      );
      expect(
        localMcpAddressProblem(
          u('http://homeassistant:8123/mcp'),
          network: true,
        ),
        isNull,
      );
      expect(
        localMcpAddressProblem(u('http://[fd12::5]/mcp'), network: true),
        isNull,
      );
      expect(
        localMcpAddressProblem(
          u('https://mcp.corp.example.com/mcp'),
          network: true,
        ),
        isNull,
      );
      expect(
        localMcpAddressProblem(u('http://mcp.example.com/mcp'), network: true),
        isNotNull,
        reason: 'plain http outside the network',
      );
      expect(
        localMcpAddressProblem(u('http://8.8.8.8/mcp'), network: true),
        isNotNull,
      );
      expect(
        localMcpAddressProblem(u('ftp://127.0.0.1/mcp'), network: true),
        isNotNull,
      );
      expect(
        localMcpAddressProblem(u('http://user:pw@127.0.0.1/mcp')),
        isNotNull,
      );
    },
  );

  test(
    'servers Casama pushes never reach the network, even when asked',
    () async {
      server = Computerd(
        ComputerdConfig(
          home: home.path,
          token: token,
          port: 0,
          address: '127.0.0.1',
        ),
      );
      await server!.start();
      base = Uri.parse('http://127.0.0.1:${server!.port}');
      final put = await http.put(
        base.replace(path: '/mcp-servers'),
        headers: headers,
        body: jsonEncode({
          'lan': {
            'kind': 'loopback',
            'url': 'http://192.168.1.5/mcp',
            'network': true,
          },
        }),
      );
      expect(put.statusCode, 200);
      final res = await post('lan', {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/list',
      });
      expect(res.statusCode, 400);
      expect(jsonDecode(res.body)['code'], 'mcp_not_loopback');
    },
  );
}

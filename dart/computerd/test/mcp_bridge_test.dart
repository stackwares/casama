import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kasama_computerd/computerd.dart';
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

/// Local MCP servers through computerd (companion mode, D-096).
void main() {
  late Directory home;
  late Computerd server;
  late Uri base;
  final headers = {'authorization': 'Bearer $token', 'content-type': 'application/json', 'accept': 'application/json, text/event-stream'};

  Future<void> start(Set<String> caps) async {
    server = Computerd(ComputerdConfig(
      home: home.path,
      token: token,
      port: 0,
      address: '127.0.0.1',
      allowedRoots: [home.path],
      capabilities: caps,
      mcpServers: {
        'fake': LocalMcpServer(key: 'fake', kind: 'stdio', command: Platform.resolvedExecutable, args: ['run', 'test/fixtures/fake_mcp_server.dart']),
      },
    ));
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  }

  /// Posts one JSON-RPC message; returns the messages from the event stream (or JSON body).
  Future<List<Map<String, dynamic>>> rpc(Object body) async {
    final res = await http.post(base.replace(path: '/mcp/fake'), headers: headers, body: jsonEncode(body));
    if (res.statusCode == 202) return [];
    expect(res.statusCode, 200, reason: res.body);
    return [
      for (final line in const LineSplitter().convert(res.body))
        if (line.startsWith('data:')) (jsonDecode(line.substring(5).trim()) as Map).cast<String, dynamic>(),
    ];
  }

  Map<String, dynamic> call(Object id, String name, [Map<String, dynamic> args = const {}, Object? progress]) => {
        'jsonrpc': '2.0',
        'id': id,
        'method': 'tools/call',
        'params': {'name': name, 'arguments': args, if (progress != null) '_meta': {'progressToken': progress}},
      };

  setUp(() => home = Directory.systemTemp.createTempSync('mcp-home'));
  tearDown(() async {
    await server.stop();
    home.deleteSync(recursive: true);
  });

  test('initializes once, serves many callers, and routes ids and progress', () async {
    await start({'mcp'});
    final init = {'jsonrpc': '2.0', 'id': 0, 'method': 'initialize', 'params': {'protocolVersion': '2025-06-18', 'capabilities': {}, 'clientInfo': {'name': 'a', 'version': '1'}}};
    final first = await rpc(init);
    expect(first.single['result']['serverInfo']['name'], 'fake');
    expect((await rpc(init)).single['id'], 0);
    expect(await rpc({'jsonrpc': '2.0', 'method': 'notifications/initialized'}), isEmpty);

    final tools = await rpc({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'});
    expect((tools.single['result']['tools'] as List).map((t) => t['name']), ['echo', 'slow']);

    // Two callers using the same request id at once still get their own answers.
    final results = await Future.wait([rpc(call(7, 'echo', {'text': 'a'})), rpc(call(7, 'echo', {'text': 'b'}))]);
    expect(results.map((r) => r.single['result']['content'][0]['text']).toSet(), {'echo: a', 'echo: b'});
    expect(results.every((r) => r.single['id'] == 7), isTrue);

    final slow = await rpc(call(9, 'slow', {}, 'tok-1'));
    final progress = slow.where((m) => m['method'] == 'notifications/progress').toList();
    expect(progress.map((m) => m['params']['progressToken']), ['tok-1', 'tok-1']);
    expect(slow.last['result']['content'][0]['text'], 'slow done');

    final count = await rpc(call(10, 'init_count'));
    expect(count.single['result']['content'][0]['text'], '1');
  });

  test('needs the user to allow local tools', () async {
    await start({'shell'});
    final res = await http.post(base.replace(path: '/mcp/fake'), headers: headers, body: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}');
    expect(res.statusCode, 403);
    expect(jsonDecode(res.body)['code'], 'capability_not_allowed');
  });

  test('unknown servers are not found', () async {
    await start({'mcp'});
    final res = await http.post(base.replace(path: '/mcp/nope'), headers: headers, body: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}');
    expect(res.statusCode, 404);
  });

  test('a bot computer takes its plugin servers over PUT /mcp-servers', () async {
    server = Computerd(ComputerdConfig(home: home.path, token: token, port: 0, address: '127.0.0.1'));
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
    final none = await http.post(base.replace(path: '/mcp/plug'), headers: headers, body: '{}');
    expect(none.statusCode, 404);
    final put = await http.put(base.replace(path: '/mcp-servers'), headers: headers, body: jsonEncode({
      'plug': {'kind': 'stdio', 'command': Platform.resolvedExecutable, 'args': ['run', '${Directory.current.path}/test/fixtures/fake_mcp_server.dart']},
    }));
    expect(put.statusCode, 200, reason: put.body);
    final init = {'jsonrpc': '2.0', 'id': 0, 'method': 'initialize', 'params': {'protocolVersion': '2025-06-18', 'capabilities': {}, 'clientInfo': {'name': 'a', 'version': '1'}}};
    final res = await http.post(base.replace(path: '/mcp/plug'), headers: headers, body: jsonEncode(init));
    expect(res.statusCode, 200, reason: res.body);
    expect(res.body, contains('"fake"'));
    // Removing it stops it.
    await http.put(base.replace(path: '/mcp-servers'), headers: headers, body: '{}');
    expect((await http.post(base.replace(path: '/mcp/plug'), headers: headers, body: jsonEncode(init))).statusCode, 404);
  });
}

// A tiny stdio MCP server for tests: echo, slow (with progress), init_count.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

var inits = 0;

void send(Map<String, dynamic> m) => stdout.writeln(jsonEncode(m));

Future<void> main() async {
  stdout.writeln('starting fake server'); // not JSON: the bridge must ignore it
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final m = jsonDecode(line) as Map<String, dynamic>;
    final id = m['id'];
    switch (m['method']) {
      case 'initialize':
        inits++;
        send({'jsonrpc': '2.0', 'id': id, 'result': {'protocolVersion': '2025-06-18', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'fake', 'version': '1'}}});
      case 'tools/list':
        send({'jsonrpc': '2.0', 'id': id, 'result': {'tools': [
          {'name': 'echo', 'description': 'Echo text', 'inputSchema': {'type': 'object', 'properties': {'text': {'type': 'string'}}}},
          {'name': 'slow', 'description': 'Takes a while', 'inputSchema': {'type': 'object'}},
        ]}});
      case 'tools/call':
        final params = m['params'] as Map<String, dynamic>;
        final args = (params['arguments'] as Map?) ?? {};
        switch (params['name']) {
          case 'echo':
            send({'jsonrpc': '2.0', 'id': id, 'result': {'content': [{'type': 'text', 'text': 'echo: ${args['text']}'}]}});
          case 'init_count':
            send({'jsonrpc': '2.0', 'id': id, 'result': {'content': [{'type': 'text', 'text': '$inits'}]}});
          case 'slow':
            final token = (params['_meta'] as Map?)?['progressToken'];
            unawaited(() async {
              for (var i = 1; i <= 2; i++) {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (token != null) send({'jsonrpc': '2.0', 'method': 'notifications/progress', 'params': {'progressToken': token, 'progress': i, 'total': 2}});
              }
              send({'jsonrpc': '2.0', 'id': id, 'result': {'content': [{'type': 'text', 'text': 'slow done'}]}});
            }());
        }
      default:
        if (id != null) send({'jsonrpc': '2.0', 'id': id, 'error': {'code': -32601, 'message': 'no'}});
    }
  }
}

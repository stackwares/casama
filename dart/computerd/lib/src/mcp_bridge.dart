/// Local MCP servers on the user's computer (companion mode, D-096).
///
/// The worker reaches `POST /mcp/<key>` through the API's device tunnel, speaking MCP Streamable
/// HTTP. The bridge owns one session per server: it starts a stdio server (or talks to a loopback
/// server), initializes it once, answers later `initialize` calls from its cache, rewrites request
/// ids and progress tokens so concurrent callers never collide, and stops idle stdio servers.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A local MCP server the user added in the desktop app. Environment values (tokens) stay here.
class LocalMcpServer {
  LocalMcpServer({required this.key, required this.kind, this.command, this.args = const [], this.cwd, this.env = const {}, this.url});

  factory LocalMcpServer.fromJson(String key, Map<String, dynamic> j) => LocalMcpServer(
        key: key,
        kind: j['kind'] == 'loopback' ? 'loopback' : 'stdio',
        command: j['command'] as String?,
        args: [for (final a in (j['args'] as List? ?? const [])) '$a'],
        cwd: j['cwd'] as String?,
        env: {for (final e in (j['env'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        url: j['url'] as String?,
      );

  final String key;

  /// stdio (a command) or loopback (an http://127.0.0.1 or [::1] address).
  final String kind;
  final String? command;
  final List<String> args;
  final String? cwd;
  final Map<String, String> env;
  final String? url;

  /// Parses `{key: {kind, command, args, cwd, env, url}}` (COMPUTERD_MCP_SERVERS).
  static Map<String, LocalMcpServer> parseAll(String? json) {
    if (json == null || json.trim().isEmpty) return {};
    final m = jsonDecode(json) as Map<String, dynamic>;
    return {for (final e in m.entries) e.key: LocalMcpServer.fromJson(e.key, (e.value as Map).cast<String, dynamic>())};
  }
}

class McpBridgeError implements Exception {
  McpBridgeError(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
}

typedef Json = Map<String, dynamic>;

const _protocolVersion = '2025-06-18';

abstract class _Upstream {
  /// Sends messages; the returned stream carries what comes back (it may carry other callers'
  /// messages too, which the dispatcher filters out).
  Future<Stream<Json>> exchange(List<Json> messages);
  Future<void> close();
  bool get alive;
}

class _StdioUpstream implements _Upstream {
  _StdioUpstream(this.process) {
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isEmpty) return;
      try {
        final msg = jsonDecode(line);
        if (msg is Map && !_incoming.isClosed) _incoming.add(msg.cast<String, dynamic>());
      } catch (_) {
        // Servers sometimes log to stdout; ignore lines that aren't JSON-RPC.
      }
    });
    process.stderr.drain<void>();
    process.exitCode.then((_) {
      _alive = false;
      if (!_incoming.isClosed) _incoming.add({'_kasama_exit': true});
    });
  }

  final Process process;
  final _incoming = StreamController<Json>.broadcast();
  var _alive = true;

  @override
  bool get alive => _alive;

  void write(Json msg) => process.stdin.writeln(jsonEncode(msg));

  @override
  Future<Stream<Json>> exchange(List<Json> messages) async {
    final stream = _incoming.stream;
    for (final m in messages) {
      write(m);
    }
    return stream;
  }

  @override
  Future<void> close() async {
    _alive = false;
    process.kill();
    await _incoming.close();
  }
}

class _LoopbackUpstream implements _Upstream {
  _LoopbackUpstream(this.url);
  final Uri url;
  final _http = HttpClient();
  String? sessionId;
  var _alive = true;

  @override
  bool get alive => _alive;

  @override
  Future<Stream<Json>> exchange(List<Json> messages) async {
    final req = await _http.postUrl(url);
    req.headers
      ..set('content-type', 'application/json')
      ..set('accept', 'application/json, text/event-stream')
      ..set('mcp-protocol-version', _protocolVersion);
    if (sessionId != null) req.headers.set('mcp-session-id', sessionId!);
    req.add(utf8.encode(jsonEncode(messages.length == 1 ? messages.single : messages)));
    final res = await req.close();
    sessionId = res.headers.value('mcp-session-id') ?? sessionId;
    if (res.statusCode == 202) {
      await res.drain<void>();
      return const Stream.empty();
    }
    if (res.statusCode >= 400) {
      final text = await res.transform(utf8.decoder).join();
      throw McpBridgeError(502, 'mcp_upstream_error', 'The local MCP server answered ${res.statusCode}: ${text.length > 200 ? text.substring(0, 200) : text}');
    }
    final type = res.headers.contentType?.mimeType ?? '';
    if (type == 'text/event-stream') return _sse(res);
    final body = jsonDecode(await res.transform(utf8.decoder).join());
    final list = body is List ? body : [body];
    return Stream.fromIterable([for (final m in list) (m as Map).cast<String, dynamic>()]);
  }

  Stream<Json> _sse(HttpClientResponse res) async* {
    final data = <String>[];
    await for (final line in res.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          final msg = jsonDecode(data.join('\n'));
          data.clear();
          if (msg is Map) yield msg.cast<String, dynamic>();
        }
      } else if (line.startsWith('data:')) {
        data.add(line.substring(5).trimLeft());
      }
    }
  }

  @override
  Future<void> close() async {
    _alive = false;
    _http.close(force: true);
  }
}

class _Session {
  _Session(this.server);
  final LocalMcpServer server;
  _Upstream? upstream;
  Json? initResult;
  Future<void>? _starting;
  Timer? _idle;
  var _seq = 0;
  var pending = 0;

  String nextId() => 'k${++_seq}';
}

/// Bridges MCP Streamable HTTP (from the worker, through the tunnel) to local servers.
class McpBridge {
  McpBridge(this.servers, {this.idleTimeout = const Duration(minutes: 10), this.checkCwd});

  Map<String, LocalMcpServer> servers;
  final Duration idleTimeout;

  /// Throws when a working folder is outside the folders the user shared.
  final void Function(String cwd)? checkCwd;
  final _sessions = <String, _Session>{};

  /// Replaces the configured servers (the desktop app edits them); removed ones stop.
  Future<void> update(Map<String, LocalMcpServer> next) async {
    servers = next;
    for (final key in _sessions.keys.toList()) {
      if (!next.containsKey(key)) await _stop(key);
    }
  }

  Future<void> stopAll() async {
    for (final key in _sessions.keys.toList()) {
      await _stop(key);
    }
  }

  Future<void> _stop(String key) async {
    final s = _sessions.remove(key);
    s?._idle?.cancel();
    await s?.upstream?.close();
  }

  Future<void> _ensureStarted(_Session s) {
    if (s.upstream?.alive == true && s.initResult != null) return Future.value();
    return s._starting ??= _start(s).whenComplete(() => s._starting = null);
  }

  Future<void> _start(_Session s) async {
    final srv = s.server;
    if (srv.kind == 'loopback') {
      final uri = Uri.tryParse(srv.url ?? '');
      if (uri == null || uri.scheme != 'http' || !(uri.host == '127.0.0.1' || uri.host == '::1' || uri.host == '[::1]')) {
        throw McpBridgeError(400, 'mcp_not_loopback', 'Local MCP addresses must be http://127.0.0.1 or http://[::1]');
      }
      s.upstream = _LoopbackUpstream(uri);
    } else {
      final cmd = srv.command;
      if (cmd == null || cmd.isEmpty) throw McpBridgeError(400, 'mcp_no_command', 'This MCP server has no command');
      if (srv.cwd != null) checkCwd?.call(srv.cwd!);
      final Process proc;
      try {
        proc = await Process.start(cmd, srv.args, workingDirectory: srv.cwd, environment: srv.env, runInShell: Platform.isWindows);
      } on ProcessException catch (e) {
        throw McpBridgeError(502, 'mcp_start_failed', 'Could not start ${srv.key}: ${e.message}');
      }
      s.upstream = _StdioUpstream(proc);
    }
    // Initialize once; later callers get this result from the cache.
    final init = {
      'jsonrpc': '2.0',
      'id': 'kasama-init',
      'method': 'initialize',
      'params': {
        'protocolVersion': _protocolVersion,
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'kasama-companion', 'version': '1'},
      },
    };
    final stream = await s.upstream!.exchange([init]);
    final reply = await stream
        .firstWhere((m) => m['id'] == 'kasama-init' || m['_kasama_exit'] == true)
        .timeout(const Duration(seconds: 30), onTimeout: () => throw McpBridgeError(504, 'mcp_init_timeout', '${srv.key} did not answer initialize'));
    if (reply['_kasama_exit'] == true || reply['result'] is! Map) {
      await s.upstream!.close();
      throw McpBridgeError(502, 'mcp_init_failed', '${srv.key} failed to start: ${reply['error'] ?? 'it exited'}');
    }
    s.initResult = (reply['result'] as Map).cast<String, dynamic>();
    await (await s.upstream!.exchange([
      {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
    ]))
        .drain<void>()
        .timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  void _touch(_Session s) {
    s._idle?.cancel();
    if (s.server.kind != 'stdio') return;
    s._idle = Timer(idleTimeout, () async {
      if (s.pending > 0) return _touch(s);
      await _stop(s.server.key);
    });
  }

  /// Handles one MCP Streamable HTTP request for server [key].
  Future<void> handle(HttpRequest req, String key) async {
    final res = req.response;
    if (req.method != 'POST') {
      // No server-initiated stream: callers use POST only.
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }
    final srv = servers[key];
    if (srv == null) throw McpBridgeError(404, 'mcp_server_not_found', 'No local MCP server "$key" on this computer');
    final s = _sessions.putIfAbsent(key, () => _Session(srv));
    final decoded = jsonDecode(await utf8.decodeStream(req));
    final messages = [for (final m in (decoded is List ? decoded : [decoded])) (m as Map).cast<String, dynamic>()];

    await _ensureStarted(s);
    _touch(s);

    final local = <Json>[];
    final outgoing = <Json>[];
    final idMap = <String, Object?>{}; // upstream id -> caller id
    final tokenMap = <String, Object?>{}; // upstream progress token -> caller token
    for (final m in messages) {
      final method = m['method'] as String?;
      final hasId = m.containsKey('id') && m['id'] != null;
      if (method == 'initialize' && hasId) {
        local.add({'jsonrpc': '2.0', 'id': m['id'], 'result': s.initResult});
      } else if (method == 'notifications/initialized') {
        // Already initialized.
      } else if (method != null && hasId) {
        final upId = s.nextId();
        idMap[upId] = m['id'];
        final params = (m['params'] as Map?)?.cast<String, dynamic>();
        final meta = (params?['_meta'] as Map?)?.cast<String, dynamic>();
        if (meta != null && meta.containsKey('progressToken')) {
          final upToken = 'p$upId';
          tokenMap[upToken] = meta['progressToken'];
          meta['progressToken'] = upToken;
          params!['_meta'] = meta;
        }
        outgoing.add({...m, 'id': upId, 'params': ?params});
      } else if (method == 'notifications/cancelled') {
        outgoing.add(m);
      } else if (method != null) {
        outgoing.add(m);
      }
      // Responses to server-initiated requests are not supported and dropped.
    }

    if (idMap.isEmpty && local.isEmpty) {
      if (outgoing.isNotEmpty) await (await s.upstream!.exchange(outgoing)).drain<void>().timeout(const Duration(seconds: 5), onTimeout: () {});
      res.statusCode = HttpStatus.accepted;
      await res.close();
      return;
    }

    res.statusCode = 200;
    res.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..set('cache-control', 'no-cache');
    res.bufferOutput = false;
    void send(Json msg) => res.write('event: message\ndata: ${jsonEncode(msg)}\n\n');
    for (final m in local) {
      send(m);
    }
    if (idMap.isEmpty) {
      await res.close();
      return;
    }

    s.pending++;
    final waiting = Set<String>.of(idMap.keys);
    final done = Completer<void>();
    StreamSubscription<Json>? sub;
    void finishWithErrors(String message) {
      for (final id in waiting) {
        send({'jsonrpc': '2.0', 'id': idMap[id], 'error': {'code': -32000, 'message': message}});
      }
      waiting.clear();
      if (!done.isCompleted) done.complete();
    }

    try {
      final stream = await s.upstream!.exchange(outgoing);
      sub = stream.listen(
        (m) {
          if (m['_kasama_exit'] == true) return finishWithErrors('The local MCP server exited');
          final id = m['id'];
          final method = m['method'] as String?;
          if (method != null && id != null) {
            // A request from the server (sampling and the like): not supported here.
            if (s.upstream is _StdioUpstream) {
              (s.upstream as _StdioUpstream).write({'jsonrpc': '2.0', 'id': id, 'error': {'code': -32601, 'message': 'Not supported by Kasama'}});
            }
            return;
          }
          if (method == 'notifications/progress') {
            final params = (m['params'] as Map?)?.cast<String, dynamic>() ?? {};
            final token = '${params['progressToken']}';
            if (tokenMap.containsKey(token)) send({...m, 'params': {...params, 'progressToken': tokenMap[token]}});
            return;
          }
          if (id != null && waiting.remove('$id')) {
            send({...m, 'id': idMap['$id']});
            if (waiting.isEmpty && !done.isCompleted) done.complete();
          }
        },
        onError: (Object e) => finishWithErrors('The local MCP server failed: $e'),
        onDone: () {
          if (s.upstream is _LoopbackUpstream) finishWithErrors('The local MCP server closed the stream');
        },
      );
      // The caller hanging up (Stop, or a timeout) cancels the requests upstream.
      unawaited(res.done.catchError((_) {}).then((_) {
        if (done.isCompleted) return;
        for (final id in waiting) {
          s.upstream?.exchange([
            {'jsonrpc': '2.0', 'method': 'notifications/cancelled', 'params': {'requestId': id, 'reason': 'Cancelled by Kasama'}},
          ]);
        }
        waiting.clear();
        done.complete();
      }));
      await done.future;
    } finally {
      s.pending--;
      _touch(s);
      await sub?.cancel();
      try {
        await res.close();
      } catch (_) {}
    }
  }
}

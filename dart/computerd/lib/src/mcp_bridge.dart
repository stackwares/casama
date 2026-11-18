/// Local MCP servers on the user's computer (companion mode, D-096, D-363).
///
/// The worker reaches `POST /mcp/<key>` through the API's device tunnel, speaking MCP Streamable
/// HTTP. The bridge owns one session per server: it starts a stdio server (or talks to a server at
/// an address), initializes it once, answers later `initialize` calls from its cache, rewrites
/// request ids and progress tokens so concurrent callers never collide, and stops idle stdio
/// servers. Servers at an address may want a token or an OAuth sign-in (D-363): the bridge adds
/// the header, refreshes OAuth tokens and reports `mcp_sign_in_needed` when the person has to sign
/// in again. Older servers that speak HTTP+SSE (`GET /sse`) are bridged too. A server's request to
/// ask the person something (elicitation) is passed to the caller when it can answer.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp_address.dart';
import 'mcp_oauth.dart';

/// A local MCP server the user added in the desktop app. Environment values, headers and sign-in
/// tokens stay here.
class LocalMcpServer {
  LocalMcpServer({
    required this.key,
    required this.kind,
    this.command,
    this.args = const [],
    this.cwd,
    this.env = const {},
    this.url,
    this.plugin,
    this.headers = const {},
    this.oauth,
    this.network = false,
    this.label,
  });

  /// Parses servers from COMPUTERD_MCP_SERVERS or Casama's PUT /mcp-servers. Headers come across;
  /// sign-in tokens and network addresses only from the desktop app's own settings.
  factory LocalMcpServer.fromJson(String key, Map<String, dynamic> j) => LocalMcpServer(
        key: key,
        kind: j['kind'] == 'loopback' ? 'loopback' : 'stdio',
        command: j['command'] as String?,
        args: [for (final a in (j['args'] as List? ?? const [])) '$a'],
        cwd: j['cwd'] as String?,
        env: {for (final e in (j['env'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        url: j['url'] as String?,
        headers: {for (final e in (j['headers'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
      );

  final String key;

  /// stdio (a command) or loopback (an address; on this computer unless [network]).
  final String kind;
  final String? command;
  final List<String> args;
  final String? cwd;
  final Map<String, String> env;
  final String? url;

  /// A plugin's server pushed by Casama (D-344): its working folder is the plugin's own folder,
  /// not one of the shared folders.
  final String? plugin;

  /// Sent with every request to a server at an address (a token, an API key header).
  final Map<String, String> headers;

  /// The server's OAuth sign-in, when it has one (D-363). The bridge refreshes it.
  final McpOAuthCredentials? oauth;

  /// May the address be elsewhere on the network (D-363)? Only the person's own servers, never
  /// ones Casama pushes.
  final bool network;

  /// What the person calls it, for messages.
  final String? label;

  String get _name => label ?? key;

  String get _signature => jsonEncode([kind, command, args, cwd, env, url, plugin, headers, oauth?.clientId, oauth?.refreshToken, network]);

  /// Parses `{key: {kind, command, args, cwd, env, url, headers}}` (COMPUTERD_MCP_SERVERS).
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
  @override
  String toString() => '$code: $message';
}

typedef Json = Map<String, dynamic>;

const _protocolVersion = '2025-06-18';

abstract class _Upstream {
  /// Sends messages; the returned stream carries what comes back (it may carry other callers'
  /// messages too, which the dispatcher filters out).
  Future<Stream<Json>> exchange(List<Json> messages);

  /// Sends one message that needs no answer (a reply to the server's own request).
  Future<void> send(Json message);
  Future<void> close();
  bool get alive;

  /// A stream that ends after each exchange (HTTP) rather than one shared for the session.
  bool get perRequest => false;
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
      if (!_incoming.isClosed) _incoming.add({'_casama_exit': true});
    });
  }

  final Process process;
  final _incoming = StreamController<Json>.broadcast();
  var _alive = true;

  @override
  bool get alive => _alive;
  @override
  bool get perRequest => false;

  void write(Json msg) => process.stdin.writeln(jsonEncode(msg));

  @override
  Future<void> send(Json message) async => write(message);

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

/// Headers for a server at an address: its fixed ones plus a fresh OAuth token.
class _Auth {
  _Auth(this.server, this.oauth, this.onCredentials) : creds = server.oauth;

  final LocalMcpServer server;
  final McpOAuth oauth;
  final void Function(String key, McpOAuthCredentials? creds)? onCredentials;
  McpOAuthCredentials? creds;
  Future<void>? _refreshing;

  /// The sign-in can't be used any more (refused, or no refresh token): ask the person.
  var signInNeeded = false;

  bool get hasOAuth => creds != null;

  Future<Map<String, String>> headers() async {
    final c = creds;
    if (c != null && c.expiring()) await refresh();
    if (signInNeeded) throw _signInNeeded(server, again: hasOAuth);
    return {...server.headers, if (creds != null) 'authorization': 'Bearer ${creds!.accessToken}'};
  }

  /// Refreshes once however many requests ask at the same time.
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final c = creds;
    if (c == null || c.refreshToken == null) {
      signInNeeded = true;
      return;
    }
    try {
      creds = await oauth.refresh(c);
      onCredentials?.call(server.key, creds);
    } on McpOAuthError {
      signInNeeded = true;
      onCredentials?.call(server.key, null);
    } catch (_) {
      // Unreachable token endpoint: keep the old token; the server decides.
    }
  }
}

McpBridgeError _signInNeeded(LocalMcpServer s, {bool again = true}) => McpBridgeError(
      401,
      'mcp_sign_in_needed',
      again
          ? '${s._name} needs you to sign in again. On this computer, open Casama → This computer → Local MCP servers and tap Sign in.'
          : '${s._name} needs a sign-in. On this computer, open Casama → This computer → Local MCP servers and tap Sign in.',
    );

/// Answers a 401: refresh and retry once, else ask the person to sign in (or fix the token).
Future<HttpClientResponse> _authorized(_Auth auth, Future<HttpClientResponse> Function(Map<String, String> headers) send) async {
  var res = await send(await auth.headers());
  if (res.statusCode != 401) return res;
  final challenge = res.headers.value('www-authenticate') ?? '';
  await res.drain<void>();
  if (auth.hasOAuth && auth.creds?.refreshToken != null && !auth.signInNeeded) {
    await auth.refresh();
    if (!auth.signInNeeded) {
      res = await send(await auth.headers());
      if (res.statusCode != 401) return res;
      await res.drain<void>();
    }
  }
  if (auth.hasOAuth || (auth.server.headers.isEmpty && challenge.toLowerCase().startsWith('bearer'))) {
    auth.signInNeeded = true;
    throw _signInNeeded(auth.server, again: auth.hasOAuth);
  }
  throw McpBridgeError(
    401,
    auth.server.headers.isEmpty ? 'mcp_sign_in_needed' : 'mcp_token_refused',
    auth.server.headers.isEmpty
        ? '${auth.server._name} needs a sign-in. On this computer, open Casama → This computer → Local MCP servers and add a token or sign in.'
        : '${auth.server._name} refused its token. Update it in Casama on this computer (This computer → Local MCP servers).',
  );
}

Stream<Json> _sseMessages(Stream<List<int>> body, {void Function(String event, String data)? onEvent}) async* {
  final data = <String>[];
  var event = 'message';
  await for (final line in body.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        final text = data.join('\n');
        data.clear();
        if (event == 'message') {
          try {
            final msg = jsonDecode(text);
            if (msg is Map) yield msg.cast<String, dynamic>();
            if (msg is List) {
              for (final m in msg) {
                if (m is Map) yield m.cast<String, dynamic>();
              }
            }
          } catch (_) {}
        } else {
          onEvent?.call(event, text);
        }
      }
      event = 'message';
    } else if (line.startsWith('data:')) {
      data.add(line.substring(5).trimLeft());
    } else if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    }
  }
}

/// MCP Streamable HTTP: one POST per exchange, answered with JSON or an event stream.
class _HttpUpstream implements _Upstream {
  _HttpUpstream(this.url, this.auth);
  final Uri url;
  final _Auth auth;
  final _http = HttpClient();
  String? sessionId;
  var _alive = true;

  @override
  bool get alive => _alive;
  @override
  bool get perRequest => true;

  Future<HttpClientResponse> _post(List<Json> messages) => _authorized(auth, (headers) async {
        final req = await _http.postUrl(url);
        req.headers
          ..set('content-type', 'application/json')
          ..set('accept', 'application/json, text/event-stream')
          ..set('mcp-protocol-version', _protocolVersion);
        headers.forEach(req.headers.set);
        if (sessionId != null) req.headers.set('mcp-session-id', sessionId!);
        req.add(utf8.encode(jsonEncode(messages.length == 1 ? messages.single : messages)));
        return req.close();
      });

  @override
  Future<void> send(Json message) async => (await exchange([message])).drain<void>().timeout(const Duration(seconds: 5), onTimeout: () {});

  @override
  Future<Stream<Json>> exchange(List<Json> messages) async {
    final res = await _post(messages);
    sessionId = res.headers.value('mcp-session-id') ?? sessionId;
    if (res.statusCode == 202) {
      await res.drain<void>();
      return const Stream.empty();
    }
    if (res.statusCode == 404 && sessionId != null) {
      // The server forgot the session (it restarted): start again on the next call.
      await res.drain<void>();
      _alive = false;
      throw McpBridgeError(502, 'mcp_session_lost', 'The local MCP server restarted');
    }
    if ((res.statusCode == 404 || res.statusCode == 405) && sessionId == null) {
      await res.drain<void>();
      throw McpBridgeError(502, 'mcp_not_streamable', 'The server does not take MCP over POST at ${url.path}');
    }
    if (res.statusCode >= 400) {
      final text = await res.transform(utf8.decoder).join();
      throw McpBridgeError(502, 'mcp_upstream_error', 'The local MCP server answered ${res.statusCode}: ${text.length > 200 ? text.substring(0, 200) : text}');
    }
    final type = res.headers.contentType?.mimeType ?? '';
    if (type == 'text/event-stream') return _sseMessages(res);
    final text = await res.transform(utf8.decoder).join();
    if (text.trim().isEmpty) return const Stream.empty();
    final body = jsonDecode(text);
    final list = body is List ? body : [body];
    return Stream.fromIterable([for (final m in list) (m as Map).cast<String, dynamic>()]);
  }

  @override
  Future<void> close() async {
    _alive = false;
    final id = sessionId;
    if (id != null) {
      // Tell the server we're done; it may not support it.
      try {
        final req = await _http.deleteUrl(url).timeout(const Duration(seconds: 2));
        req.headers.set('mcp-session-id', id);
        (await auth.headers().catchError((_) => <String, String>{})).forEach(req.headers.set);
        await (await req.close().timeout(const Duration(seconds: 2))).drain<void>();
      } catch (_) {}
    }
    _http.close(force: true);
  }
}

/// The older HTTP+SSE transport: a long GET stream carries everything back; messages go by POST
/// to the address its first `endpoint` event names.
class _LegacySseUpstream implements _Upstream {
  _LegacySseUpstream._(this._http, this.auth, this.endpoint, this._sub);

  final HttpClient _http;
  final _Auth auth;
  final Uri endpoint;
  final StreamSubscription<Json>? _sub;
  final _incoming = StreamController<Json>.broadcast();
  var _alive = true;

  @override
  bool get alive => _alive;
  @override
  bool get perRequest => false;

  static Future<_LegacySseUpstream> connect(Uri url, _Auth auth) async {
    final http = HttpClient();
    final HttpClientResponse res;
    try {
      res = await _authorized(auth, (headers) async {
        final req = await http.getUrl(url).timeout(const Duration(seconds: 10));
        req.headers.set('accept', 'text/event-stream');
        headers.forEach(req.headers.set);
        return req.close().timeout(const Duration(seconds: 10));
      });
    } catch (e) {
      http.close(force: true);
      rethrow;
    }
    if (res.statusCode != 200 || res.headers.contentType?.mimeType != 'text/event-stream') {
      await res.drain<void>().catchError((_) {});
      http.close(force: true);
      throw McpBridgeError(502, 'mcp_upstream_error', 'The local MCP server answered ${res.statusCode} and no event stream');
    }
    final endpoint = Completer<Uri>();
    late final _LegacySseUpstream up;
    final controller = StreamController<Json>.broadcast();
    final sub = _sseMessages(res, onEvent: (event, data) {
      if (event == 'endpoint' && !endpoint.isCompleted) endpoint.complete(url.resolve(data.trim()));
    }).listen(controller.add, onDone: () {
      if (!endpoint.isCompleted) endpoint.completeError(McpBridgeError(502, 'mcp_upstream_error', 'The event stream ended before it named an endpoint'));
      controller.add({'_casama_exit': true});
    }, onError: (Object _) => controller.add({'_casama_exit': true}));
    final Uri target;
    try {
      target = await endpoint.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      await sub.cancel();
      http.close(force: true);
      if (e is McpBridgeError) rethrow;
      throw McpBridgeError(504, 'mcp_init_timeout', 'The event stream named no endpoint');
    }
    if (target.host != url.host || target.port != url.port || target.scheme != url.scheme) {
      await sub.cancel();
      http.close(force: true);
      throw McpBridgeError(502, 'mcp_upstream_error', 'The server named an endpoint on another host');
    }
    up = _LegacySseUpstream._(http, auth, target, sub);
    controller.stream.listen((m) {
      if (m['_casama_exit'] == true) up._alive = false;
      if (!up._incoming.isClosed) up._incoming.add(m);
    });
    return up;
  }

  Future<void> _postOne(Json m) async {
    final res = await _authorized(auth, (headers) async {
      final req = await _http.postUrl(endpoint);
      req.headers.set('content-type', 'application/json');
      headers.forEach(req.headers.set);
      req.add(utf8.encode(jsonEncode(m)));
      return req.close();
    });
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) throw McpBridgeError(502, 'mcp_upstream_error', 'The local MCP server answered ${res.statusCode}: ${text.length > 200 ? text.substring(0, 200) : text}');
  }

  @override
  Future<void> send(Json message) => _postOne(message);

  @override
  Future<Stream<Json>> exchange(List<Json> messages) async {
    // Listen before posting: the answer can come down the event stream before the POST returns.
    final out = StreamController<Json>();
    final sub = _incoming.stream.listen(out.add, onDone: out.close);
    out.onCancel = sub.cancel;
    try {
      for (final m in messages) {
        await _postOne(m);
      }
    } catch (_) {
      await sub.cancel();
      rethrow;
    }
    return out.stream;
  }

  @override
  Future<void> close() async {
    _alive = false;
    // Dropping the connection ends the event stream; waiting on the cancel can hang on it.
    _http.close(force: true);
    unawaited(_sub?.cancel());
    unawaited(_incoming.close());
  }
}

class _Session {
  _Session(this.server);
  final LocalMcpServer server;
  _Upstream? upstream;
  _Auth? auth;
  Json? initResult;
  Future<void>? _starting;
  Timer? _idle;
  var _seq = 0;
  var pending = 0;

  /// Did the latest caller say it can answer the server's questions (elicitation)?
  var callerElicits = false;

  /// Questions passed to a caller, by the id the caller sees: the server's own id.
  final elicitations = <String, Object?>{};

  String nextId() => 'k${++_seq}';
}

/// Bridges MCP Streamable HTTP (from the worker, through the tunnel) to local servers.
class McpBridge {
  McpBridge(this.servers, {this.idleTimeout = const Duration(minutes: 10), this.checkCwd, this.onCredentials, this.extraPath = const [], McpOAuth? oauth}) : _oauth = oauth ?? McpOAuth();

  /// Folders added to a stdio server's PATH (and searched for its command): an app opened from
  /// the Finder gets a minimal PATH without Homebrew, so `npx` and `node` weren't found.
  final List<String> extraPath;

  Map<String, LocalMcpServer> servers;

  /// Plugin servers Casama placed on this computer (D-344), kept apart from the user's own so
  /// neither list replaces the other. The user's own win on a clash.
  var pluginServers = <String, LocalMcpServer>{};
  final Duration idleTimeout;

  /// Throws when a working folder is outside the folders the user shared.
  final void Function(String cwd)? checkCwd;

  /// A server's OAuth tokens changed (refreshed), or null when the person must sign in again. The
  /// desktop app saves them with the server.
  final void Function(String key, McpOAuthCredentials? creds)? onCredentials;
  final McpOAuth _oauth;
  final _sessions = <String, _Session>{};

  /// Replaces the configured servers (the desktop app edits them); removed ones stop.
  Future<void> update(Map<String, LocalMcpServer> next) async {
    servers = next;
    await _stopGone();
  }

  /// Replaces the plugin servers (D-344); removed or changed ones stop (changed ones start again
  /// on their next call, with the new settings).
  Future<void> updatePlugins(Map<String, LocalMcpServer> next) async {
    pluginServers = next;
    await _stopGone();
  }

  LocalMcpServer? _lookup(String key) => servers[key] ?? pluginServers[key];

  Future<void> _stopGone() async {
    for (final e in _sessions.entries.toList()) {
      final now = _lookup(e.key);
      if (now == null || now._signature != e.value.server._signature) await _stop(e.key);
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
    await s.upstream?.close().catchError((_) {});
    s.upstream = null;
    s.initResult = null;
    final init = {
      'jsonrpc': '2.0',
      'id': 'casama-init',
      'method': 'initialize',
      'params': {
        'protocolVersion': _protocolVersion,
        // Questions from the server are passed on to callers that can answer them.
        'capabilities': <String, dynamic>{'elicitation': <String, dynamic>{}},
        'clientInfo': {'name': 'casama-companion', 'version': '1'},
      },
    };
    Stream<Json> stream;
    if (srv.kind == 'loopback') {
      final uri = Uri.tryParse(srv.url ?? '');
      final problem = localMcpAddressProblem(uri, network: srv.network && srv.plugin == null);
      if (problem != null) throw McpBridgeError(400, 'mcp_not_loopback', problem);
      // Keep the sign-in state across restarts of the session (a refreshed token, a refusal).
      final auth = s.auth ??= _Auth(srv, _oauth, onCredentials);
      final legacyFirst = uri!.path.endsWith('/sse');
      if (!legacyFirst) {
        final http = _HttpUpstream(uri, auth);
        s.upstream = http;
        try {
          stream = await http.exchange([init]);
        } on McpBridgeError catch (e) {
          await http.close();
          s.upstream = null;
          if (e.code != 'mcp_not_streamable') rethrow;
          s.upstream = await _LegacySseUpstream.connect(uri, auth);
          stream = await s.upstream!.exchange([init]);
        } on SocketException catch (e) {
          await http.close();
          s.upstream = null;
          throw McpBridgeError(502, 'mcp_unreachable', '${srv._name} is not answering at ${uri.host}:${uri.port} (${e.osError?.message ?? e.message}). Is it running?');
        }
      } else {
        try {
          s.upstream = await _LegacySseUpstream.connect(uri, auth);
        } on SocketException catch (e) {
          throw McpBridgeError(502, 'mcp_unreachable', '${srv._name} is not answering at ${uri.host}:${uri.port} (${e.osError?.message ?? e.message}). Is it running?');
        }
        stream = await s.upstream!.exchange([init]);
      }
    } else {
      final cmd = srv.command;
      if (cmd == null || cmd.isEmpty) throw McpBridgeError(400, 'mcp_no_command', 'This MCP server has no command');
      if (srv.cwd != null && srv.plugin == null) checkCwd?.call(srv.cwd!);
      final sep = Platform.isWindows ? ';' : ':';
      final path = srv.env['PATH'] ?? [...extraPath, Platform.environment['PATH'] ?? '/usr/bin:/bin'].where((p) => p.isNotEmpty).join(sep);
      final Process proc;
      try {
        proc = await Process.start(_which(cmd, path.split(sep)), srv.args, workingDirectory: srv.cwd, environment: {...srv.env, 'PATH': path}, runInShell: Platform.isWindows);
      } on ProcessException catch (e) {
        throw McpBridgeError(502, 'mcp_start_failed', 'Could not start ${srv.key}: ${e.message}');
      }
      s.upstream = _StdioUpstream(proc);
      stream = await s.upstream!.exchange([init]);
    }
    // Initialize once; later callers get this result from the cache.
    final reply = await stream
        .firstWhere((m) => m['id'] == 'casama-init' || m['_casama_exit'] == true)
        .timeout(const Duration(seconds: 30), onTimeout: () => throw McpBridgeError(504, 'mcp_init_timeout', '${srv.key} did not answer initialize'));
    if (reply['_casama_exit'] == true || reply['result'] is! Map) {
      await s.upstream!.close();
      throw McpBridgeError(502, 'mcp_init_failed', '${srv.key} failed to start: ${reply['error'] ?? 'it exited'}');
    }
    s.initResult = (reply['result'] as Map).cast<String, dynamic>();
    await s.upstream!.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'});
  }

  /// The command's full path when it's a bare name found in [dirs]; otherwise as given.
  static String _which(String cmd, List<String> dirs) {
    if (Platform.isWindows || cmd.contains('/')) return cmd;
    for (final d in dirs) {
      final f = File('$d/$cmd');
      if (d.isNotEmpty && f.existsSync()) return f.path;
    }
    return cmd;
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
    final srv = _lookup(key);
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
        final caps = ((m['params'] as Map?)?['capabilities'] as Map?) ?? const {};
        s.callerElicits = caps.containsKey('elicitation');
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
      } else if (method != null) {
        outgoing.add(m);
      } else if (hasId && s.elicitations.containsKey('${m['id']}')) {
        // The caller's answer to a question the server asked: back to the server under its own id.
        outgoing.add({...m, 'id': s.elicitations.remove('${m['id']}')});
      }
      // Other responses to server-initiated requests are not expected and dropped.
    }

    if (idMap.isEmpty && local.isEmpty) {
      if (s.upstream!.perRequest) {
        if (outgoing.isNotEmpty) await (await s.upstream!.exchange(outgoing)).drain<void>().timeout(const Duration(seconds: 5), onTimeout: () {});
      } else {
        for (final m in outgoing) {
          await s.upstream!.send(m);
        }
      }
      res.statusCode = HttpStatus.accepted;
      await res.close();
      return;
    }

    // Send first so a refused sign-in or a restarted server answers as an error, not a broken stream.
    Stream<Json>? stream;
    if (idMap.isNotEmpty) {
      try {
        stream = await s.upstream!.exchange(outgoing);
      } on McpBridgeError catch (e) {
        if (e.code != 'mcp_session_lost') rethrow;
        await _ensureStarted(s);
        stream = await s.upstream!.exchange(outgoing);
      }
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
    if (stream == null) {
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

    final upstream = s.upstream!;
    try {
      sub = stream.listen(
        (m) {
          if (m['_casama_exit'] == true) return finishWithErrors('The local MCP server exited');
          final id = m['id'];
          final method = m['method'] as String?;
          if (method != null && id != null) {
            // A question for the person (elicitation): passed to a caller that can answer it, on
            // this request's stream, under an id of its own. Anything else isn't supported here.
            if (method == 'elicitation/create' && s.callerElicits && waiting.isNotEmpty) {
              final eid = 'e${s.nextId()}';
              s.elicitations[eid] = id;
              send({...m, 'id': eid});
            } else {
              unawaited(upstream.send({'jsonrpc': '2.0', 'id': id, 'error': {'code': -32601, 'message': 'Not supported by Casama'}}).catchError((_) {}));
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
          if (upstream.perRequest) finishWithErrors('The local MCP server closed the stream');
        },
      );
      // The caller hanging up (Stop, or a timeout) cancels the requests upstream.
      unawaited(res.done.catchError((_) {}).then((_) {
        if (done.isCompleted) return;
        for (final id in waiting) {
          upstream.send({'jsonrpc': '2.0', 'method': 'notifications/cancelled', 'params': {'requestId': id, 'reason': 'Cancelled by Casama'}}).catchError((_) {});
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

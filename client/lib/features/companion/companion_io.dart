import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:casama_computerd/computerd.dart';
import 'package:url_launcher/url_launcher.dart';

import '../permissions/companion_hook.dart';
import 'companion.dart';
import 'mcp_import.dart';
import 'os_label.dart';
import '../../core/desktop_sign_in_io.dart' show LoopbackSignIn;
import '../../core/distribution.dart';

Companion createCompanion() => IoCompanion();

/// This computer's own name ("Olivers-iMac.local" reads as "Olivers iMac"), so a phone or a bot
/// can tell it apart. Null when the system has none worth showing.
String? localComputerName() {
  try {
    return cleanComputerName(Platform.localHostname);
  } catch (_) {
    return null;
  }
}
DeviceTokenStore createTokenStore() => _TokenStore();
LocalMcpStore createMcpStore() => _McpStore();

class _McpStore implements LocalMcpStore {
  static const _secure = FlutterSecureStorage();
  String _key(String orgId) => 'casama.mcp.$orgId';

  File _file(String orgId) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.config/casama/devices/$orgId.mcp.json');
  }

  @override
  Future<List<LocalMcpConfig>> read(String orgId) async {
    String? v;
    try {
      v = await _secure.read(key: _key(orgId));
    } catch (_) {}
    if (v == null && _file(orgId).existsSync()) v = _file(orgId).readAsStringSync();
    if (v == null || v.isEmpty) return const [];
    try {
      return [for (final s in jsonDecode(v) as List) LocalMcpConfig.fromJson((s as Map).cast<String, dynamic>())];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(String orgId, List<LocalMcpConfig> servers) async {
    final v = jsonEncode([for (final s in servers) s.toJson()]);
    try {
      await _secure.write(key: _key(orgId), value: v);
      return;
    } catch (_) {}
    final f = _file(orgId)..parent.createSync(recursive: true);
    f.writeAsStringSync(v);
    if (!Platform.isWindows) await Process.run('chmod', ['600', f.path]);
  }
}

class _TokenStore implements DeviceTokenStore {
  static const _secure = FlutterSecureStorage();
  String _key(String orgId) => 'casama.aiice.$orgId';

  File _file(String orgId) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.config/casama/devices/$orgId.token');
  }

  @override
  Future<(String, String)?> read(String orgId) async {
    String? v;
    try {
      v = await _secure.read(key: _key(orgId));
    } catch (_) {}
    if (v == null && _file(orgId).existsSync()) v = _file(orgId).readAsStringSync().trim();
    if (v == null || !v.contains(':')) return null;
    final i = v.indexOf(':');
    return (v.substring(0, i), v.substring(i + 1));
  }

  @override
  Future<void> write(String orgId, String deviceId, String token) async {
    try {
      await _secure.write(key: _key(orgId), value: '$deviceId:$token');
      return;
    } catch (_) {}
    final f = _file(orgId)..parent.createSync(recursive: true);
    f.writeAsStringSync('$deviceId:$token');
    if (!Platform.isWindows) await Process.run('chmod', ['600', f.path]);
  }

  @override
  Future<void> delete(String orgId) async {
    try {
      await _secure.delete(key: _key(orgId));
    } catch (_) {}
    if (_file(orgId).existsSync()) _file(orgId).deleteSync();
  }
}

/// Desktop companion (macOS, Windows, Linux): an embedded computerd on 127.0.0.1, limited to the
/// folders and capabilities the user approved, reached by the API over one WebSocket (D-066).
class IoCompanion implements Companion {
  @override
  Future<List<String>> detectCodingAgents({Iterable<String> bins = builtInCodingAgentBins}) async {
    // Apps launched from Finder get a minimal PATH; look where installers usually put them too.
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final dirs = {
      ...(Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':'),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '$home/.local/bin',
      '$home/.npm-global/bin',
    }.where((d) => d.isNotEmpty);
    final found = <String>[];
    // Only plain command names: a list from the server never makes the app look outside these folders.
    for (final bin in {...bins}.where(isAgentBin)) {
      final names = Platform.isWindows ? ['$bin.cmd', '$bin.exe'] : [bin];
      if (dirs.any((d) => names.any((n) => File('$d/$n').existsSync()))) found.add(bin);
    }
    return found;
  }

  static String get _home => Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

  /// Where each app keeps its MCP servers on this computer.
  static List<(String, McpSettingsFormat, String)> _settingsFiles() {
    final home = _home;
    final appData = Platform.environment['APPDATA'] ?? '$home/AppData/Roaming';
    final support = Platform.isMacOS ? '$home/Library/Application Support' : Platform.isWindows ? appData : '$home/.config';
    final codex = Platform.environment['CODEX_HOME'] ?? '$home/.codex';
    return [
      ('T3 Code', McpSettingsFormat.t3Runtime, '$home/.t3/userdata/server-runtime.json'),
      ('Claude Code', McpSettingsFormat.mcpServers, '$home/.claude.json'),
      ('Claude Desktop', McpSettingsFormat.mcpServers, '$support/Claude/claude_desktop_config.json'),
      ('Cursor', McpSettingsFormat.mcpServers, '$home/.cursor/mcp.json'),
      ('VS Code', McpSettingsFormat.vscode, '$support/Code/User/mcp.json'),
      ('VS Code', McpSettingsFormat.vscode, '$support/Code/User/settings.json'),
      ('Codex', McpSettingsFormat.codexToml, '$codex/config.toml'),
      ('Windsurf', McpSettingsFormat.mcpServers, '$home/.codeium/windsurf/mcp_config.json'),
    ];
  }

  @override
  Future<List<FoundMcpServer>> findMcpServers() async {
    final out = <FoundMcpServer>[];
    for (final (source, format, path) in _settingsFiles()) {
      try {
        final f = File(path);
        if (!f.existsSync() || f.lengthSync() > 5 * 1024 * 1024) continue;
        out.addAll(parseMcpSettings(source, format, await f.readAsString(), env: Platform.environment));
      } catch (_) {
        // Unreadable settings are skipped.
      }
    }
    return out;
  }

  @override
  Future<String?> t3CodeMcpUrl() async {
    final found = await findMcpServers();
    return found.where((f) => f.config.source == 't3code').firstOrNull?.config.url;
  }

  @override
  Future<Map<String, dynamic>> signInMcp(LocalMcpConfig server) async {
    final url = Uri.parse(server.url ?? '');
    final oauth = McpOAuth();
    LoopbackSignIn? listener;
    try {
      final probe = await oauth.probe(url, headers: server.headers);
      listener = await LoopbackSignIn.start();
      final start = await oauth.signInUrl(url, redirectUri: listener.redirectUrl, clientName: 'Casama on ${Platform.localHostname}', resourceMetadata: probe.resourceMetadata);
      final done = Completer<McpOAuthCredentials>();
      unawaited(listener.wait((query) async {
        try {
          final creds = await oauth.finishSignIn(start, query);
          if (!done.isCompleted) done.complete(creds);
          return null;
        } catch (e) {
          if (!done.isCompleted) done.completeError(e);
          return '$e';
        }
      }).whenComplete(() {
        if (!done.isCompleted) done.completeError(McpOAuthError('The sign-in timed out. Try again.'));
      }));
      if (!await launchUrl(start.url, mode: LaunchMode.externalApplication)) throw McpOAuthError('Could not open the browser.');
      return (await done.future).toJson();
    } on SocketException catch (e) {
      throw McpOAuthError('${server.label} is not answering at ${url.host}:${url.port} (${e.osError?.message ?? e.message}). Is it running?');
    } finally {
      oauth.close();
    }
  }

  final _status = ValueNotifier(CompanionStatus.off);
  final _activity = ValueNotifier<CompanionActivity?>(null);
  Computerd? _computerd;
  String? _token;
  WebSocket? _ws;
  String? _os;
  var _running = false;
  // Each start gets a generation; an older connect loop exits instead of reconnecting.
  var _generation = 0;
  var _backoff = const Duration(seconds: 1);
  final _client = HttpClient();
  final _inflight = <String, HttpClientRequest>{};
  // Commands started through the tunnel, by request id: a cancel kills the command, not just the stream.
  final _execIds = <String, String>{};
  final _activeRuns = <String, int>{};

  @override
  ValueListenable<CompanionStatus> get status => _status;
  @override
  ValueListenable<CompanionActivity?> get activity => _activity;
  @override
  bool get supported => !isMacAppStoreBuild && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static String _secret() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(24, (_) => r.nextInt(256)));
  }

  @override
  Future<void> start({required String apiUrl, required String deviceToken, required CompanionSettings settings}) async {
    await stop();
    _running = true;
    final generation = ++_generation;
    _status.value = CompanionStatus.connecting;
    _token = _secret();
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? Directory.current.path;
    _computerd = Computerd(ComputerdConfig(
      home: home,
      token: _token!,
      port: 0,
      address: '127.0.0.1',
      allowedRoots: settings.roots,
      capabilities: settings.capabilities,
      // Apps launched from Finder get a minimal PATH; Homebrew holds agent-browser and agent-desktop,
      // and local MCP servers often need npx, node, uvx or bun (D-363).
      extraPath: ['/opt/homebrew/bin', '/usr/local/bin', '$home/.local/bin', '$home/.npm-global/bin', '$home/.bun/bin', '$home/.cargo/bin', '$home/.volta/bin'],
      // Its own agent-browser namespace: never touch the user's other browser sessions.
      extraEnv: const {'AGENT_BROWSER_NAMESPACE': 'casama', 'AGENT_BROWSER_SESSION': 'casama-companion'},
      // Local MCP servers (D-096): their environment never leaves this computer.
      mcpServers: {
        for (final s in settings.mcpServers)
          s.key: LocalMcpServer(
            key: s.key,
            kind: s.kind,
            command: s.command,
            args: s.args,
            cwd: s.cwd,
            env: s.env,
            url: s.url,
            label: s.label,
            // Sign-ins (D-363): a token or header, or OAuth tokens the bridge refreshes.
            headers: s.headers,
            oauth: s.oauth == null ? null : McpOAuthCredentials.fromJson(s.oauth!),
            network: s.network,
          ),
      },
      onMcpCredentials: settings.onMcpCredentials == null ? null : (key, creds) => settings.onMcpCredentials!(key, creds?.toJson()),
    ));
    await _computerd!.start();
    _os ??= await currentOsLabel();
    unawaited(_connectLoop(apiUrl, deviceToken, generation));
  }

  Future<void> _connectLoop(String apiUrl, String deviceToken, int generation) async {
    final url = '${apiUrl.replaceFirst(RegExp('^http'), 'ws')}/v1/local-computer/connect';
    bool current() => _running && generation == _generation;
    while (current()) {
      try {
        final ws = await WebSocket.connect(url, headers: {'authorization': 'Device $deviceToken', 'x-casama-os': ?_os});
        if (!current()) {
          await ws.close();
          break;
        }
        // Pings find a dead connection (sleep, a network change, a proxy dropping it) so the loop
        // dials again; without them a half-open socket looked online forever while bots saw offline.
        ws.pingInterval = const Duration(seconds: 20);
        _ws = ws;
        _backoff = const Duration(seconds: 1);
        _status.value = CompanionStatus.online;
        await for (final raw in ws) {
          if (raw is String) unawaited(_onMessage(ws, raw));
        }
      } catch (_) {
        if (_running) _status.value = CompanionStatus.error;
      }
      if (!current()) break;
      _ws = null;
      _status.value = CompanionStatus.connecting;
      await Future<void>.delayed(_backoff);
      // Short: a restarting server is back within seconds, and bots treat this computer as offline
      // when it hasn't returned within the server's grace period.
      _backoff = Duration(seconds: min(_backoff.inSeconds * 2, 5));
    }
  }

  void _send(WebSocket ws, Map<String, Object?> m) {
    if (ws.readyState == WebSocket.open) ws.add(jsonEncode(m));
  }

  Future<void> _onMessage(WebSocket ws, String raw) async {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final id = m['id'] as String?;
    if (m['type'] == 'cancel' && id != null) {
      _inflight.remove(id)?.abort();
      final execId = _execIds.remove(id);
      if (execId != null) unawaited(_killExec(execId));
      return;
    }
    // A permissions card tapped on another device (D-376): prompt or open settings here.
    if (m['type'] == 'permission') {
      unawaited(companionPermissionHandler?.call(m).catchError((_) {}));
      return;
    }
    if (m['type'] != 'request' || id == null) return;
    final a = (m['activity'] as Map?)?.cast<String, dynamic>();
    final runId = a?['run_id'] as String?;
    if (a != null && runId != null) {
      _activeRuns[runId] = (_activeRuns[runId] ?? 0) + 1;
      _activity.value = CompanionActivity(
        runId: runId,
        bot: '${a['bot'] ?? ''}',
        botId: a['bot_id'] as String?,
        tool: '${a['tool'] ?? ''}',
        summary: '${a['summary'] ?? ''}',
      );
    }
    try {
      final port = _computerd!.port;
      final req = await _client.openUrl(m['method'] as String, Uri.parse('http://127.0.0.1:$port${m['path']}'));
      _inflight[id] = req;
      (m['headers'] as Map?)?.forEach((k, v) => req.headers.set('$k', '$v'));
      req.headers.set('authorization', 'Bearer $_token');
      final body = m['body'] as String?;
      if (body != null) req.add(base64Decode(body));
      final res = await req.close();
      final execId = res.headers.value('x-exec-id');
      if (execId != null) _execIds[id] = execId;
      final headers = <String, String>{};
      res.headers.forEach((k, v) => headers[k] = v.join(', '));
      _send(ws, {'type': 'response', 'id': id, 'status': res.statusCode, 'headers': headers});
      await for (final chunk in res) {
        _send(ws, {'type': 'chunk', 'id': id, 'data': base64Encode(chunk)});
      }
      _send(ws, {'type': 'end', 'id': id});
    } catch (e) {
      debugPrint('companion request ${m['method']} ${m['path']} failed: $e');
      _send(ws, {'type': 'error', 'id': id, 'message': '$e'});
    } finally {
      _inflight.remove(id);
      _execIds.remove(id);
      if (runId != null) {
        final left = (_activeRuns[runId] ?? 1) - 1;
        if (left <= 0) {
          _activeRuns.remove(runId);
          // Keep the overlay up briefly so short actions are still visible.
          Timer(const Duration(seconds: 2), () {
            if (_activeRuns.isEmpty && _activity.value?.runId == runId) _activity.value = null;
          });
        } else {
          _activeRuns[runId] = left;
        }
      }
    }
  }

  /// Stops a command computerd is running; hanging up its stream alone leaves it working.
  Future<void> _killExec(String execId) async {
    final port = _computerd?.port;
    if (port == null) return;
    try {
      final req = await _client.postUrl(Uri.parse('http://127.0.0.1:$port/exec/${Uri.encodeComponent(execId)}/kill'));
      req.headers.set('authorization', 'Bearer $_token');
      await (await req.close()).drain<void>();
    } catch (e) {
      debugPrint('companion kill $execId failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    for (final r in _inflight.values) {
      r.abort();
    }
    _inflight.clear();
    // Turning bots off stops what they were running here.
    await Future.wait(_execIds.values.map(_killExec));
    _execIds.clear();
    await _ws?.close();
    _ws = null;
    await _computerd?.stop();
    _computerd = null;
    _activity.value = null;
    _activeRuns.clear();
    _status.value = CompanionStatus.off;
  }
}

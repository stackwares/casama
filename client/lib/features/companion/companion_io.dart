import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:casama_computerd/computerd.dart';

import 'companion.dart';
import '../../core/distribution.dart';

Companion createCompanion() => IoCompanion();
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
  Future<List<String>> detectCodingAgents() async {
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
    for (final bin in const ['claude', 'codex', 'cursor-agent']) {
      final names = Platform.isWindows ? ['$bin.cmd', '$bin.exe'] : [bin];
      if (dirs.any((d) => names.any((n) => File('$d/$n').existsSync()))) found.add(bin);
    }
    return found;
  }

  final _status = ValueNotifier(CompanionStatus.off);
  final _activity = ValueNotifier<CompanionActivity?>(null);
  Computerd? _computerd;
  String? _token;
  WebSocket? _ws;
  var _running = false;
  // Each start gets a generation; an older connect loop exits instead of reconnecting.
  var _generation = 0;
  var _backoff = const Duration(seconds: 1);
  final _client = HttpClient();
  final _inflight = <String, HttpClientRequest>{};
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
      // Apps launched from Finder get a minimal PATH; Homebrew holds agent-browser and agent-desktop.
      extraPath: const ['/opt/homebrew/bin', '/usr/local/bin'],
      // Its own agent-browser namespace: never touch the user's other browser sessions.
      extraEnv: const {'AGENT_BROWSER_NAMESPACE': 'casama', 'AGENT_BROWSER_SESSION': 'casama-companion'},
      // Local MCP servers (D-096): their environment never leaves this computer.
      mcpServers: {
        for (final s in settings.mcpServers)
          s.key: LocalMcpServer(key: s.key, kind: s.kind, command: s.command, args: s.args, cwd: s.cwd, env: s.env, url: s.url),
      },
    ));
    await _computerd!.start();
    unawaited(_connectLoop(apiUrl, deviceToken, generation));
  }

  Future<void> _connectLoop(String apiUrl, String deviceToken, int generation) async {
    final url = '${apiUrl.replaceFirst(RegExp('^http'), 'ws')}/v1/local-computer/connect';
    bool current() => _running && generation == _generation;
    while (current()) {
      try {
        final ws = await WebSocket.connect(url, headers: {'authorization': 'Device $deviceToken'});
        if (!current()) {
          await ws.close();
          break;
        }
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
      _backoff = Duration(seconds: min(_backoff.inSeconds * 2, 30));
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

  @override
  Future<void> stop() async {
    _running = false;
    for (final r in _inflight.values) {
      r.abort();
    }
    _inflight.clear();
    await _ws?.close();
    _ws = null;
    await _computerd?.stop();
    _computerd = null;
    _activity.value = null;
    _activeRuns.clear();
    _status.value = CompanionStatus.off;
  }
}

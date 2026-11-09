import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// computerd configuration. Inside a computer: HOME=/home/kasama, workspace under it.
class ComputerdConfig {
  ComputerdConfig({
    required this.home,
    required this.token,
    this.port = 7070,
    this.address = '0.0.0.0',
    this.maxOutputBytes = 10 * 1024 * 1024,
    this.defaultTimeout = const Duration(minutes: 10),
  });

  final String home;
  final String token;
  final int port;
  final String address;
  final int maxOutputBytes;
  final Duration defaultTimeout;

  String get workspace => p.join(home, 'workspace');

  factory ComputerdConfig.fromEnvironment(Map<String, String> env) {
    final token = env['COMPUTERD_TOKEN'];
    if (token == null || token.length < 16) {
      throw StateError('COMPUTERD_TOKEN (at least 16 characters) is required');
    }
    return ComputerdConfig(
      home: env['COMPUTERD_HOME'] ?? env['HOME'] ?? '/home/kasama',
      token: token,
      port: int.tryParse(env['COMPUTERD_PORT'] ?? '') ?? 7070,
      address: env['COMPUTERD_ADDRESS'] ?? '0.0.0.0',
    );
  }
}

class _ApiError implements Exception {
  _ApiError(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
}

class _Exec {
  _Exec(this.id, this.process);
  final String id;
  final Process process;
  bool killed = false;
}

/// The computerd HTTP server.
class Computerd {
  Computerd(this.config);

  final ComputerdConfig config;
  final _execs = <String, _Exec>{};
  final _started = DateTime.now();
  var _activeTerminals = 0;
  final _terminals = <Process>{};
  var _lastActivity = DateTime.now();
  HttpServer? _server;
  var _seq = 0;

  int get port => _server!.port;

  Future<void> start() async {
    Directory(config.workspace).createSync(recursive: true);
    _server = await HttpServer.bind(config.address, config.port);
    _server!.listen(_handle);
  }

  Future<void> stop() async {
    for (final e in _execs.values) {
      _killTree(e.process);
    }
    for (final t in _terminals) {
      _killTree(t);
    }
    await _server?.close(force: true);
  }

  // ---------------------------------------------------------------------------

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.uri.path == '/health') return await _health(req);
      final auth = req.headers.value('authorization') ?? '';
      if (auth != 'Bearer ${config.token}') throw _ApiError(401, 'unauthorized', 'Invalid computerd token');
      _lastActivity = DateTime.now();
      final segments = req.uri.pathSegments;
      switch ((req.method, segments)) {
        case ('POST', ['exec']):
          return await _exec(req);
        case ('POST', ['exec', final id, 'kill']):
          return await _kill(req, id);
        case ('GET', ['files']):
          return await _readFile(req);
        case ('PUT', ['files']):
          return await _writeFile(req);
        case ('DELETE', ['files']):
          return await _deleteFile(req);
        case ('GET', ['files', 'list']):
          return await _listDir(req);
        case ('POST', ['files', 'search']):
          return await _search(req);
        case ('POST', ['archive']):
          return await _archive(req);
        case ('POST', ['restore']):
          return await _restore(req);
        case ('GET', ['terminal']):
          return await _terminal(req);
        case ('GET', ['screenshot']):
          return await _screenshot(req);
        case ('POST', ['input']):
          return await _input(req);
        default:
          throw _ApiError(404, 'not_found', 'No such endpoint');
      }
    } on _ApiError catch (e) {
      await _json(res, e.status, {'code': e.code, 'message': e.message});
    } on FileSystemException catch (e) {
      final notFound = e.osError?.errorCode == 2;
      await _json(res, notFound ? 404 : 400, {'code': notFound ? 'not_found' : 'fs_error', 'message': e.message});
    } catch (e) {
      try {
        await _json(res, 500, {'code': 'internal_error', 'message': e.toString()});
      } catch (_) {}
    }
  }

  Future<void> _json(HttpResponse res, int status, Object body) async {
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    await res.close();
  }

  Future<Map<String, dynamic>> _body(HttpRequest req) async {
    final text = await utf8.decodeStream(req);
    if (text.isEmpty) return {};
    final v = jsonDecode(text);
    if (v is! Map<String, dynamic>) throw _ApiError(400, 'bad_request', 'Expected a JSON object');
    return v;
  }

  /// Resolves a path: absolute paths as given, relative ones against the workspace.
  String _resolve(String? path) {
    if (path == null || path.isEmpty) return config.workspace;
    final expanded = path == '~' ? config.home : (path.startsWith('~/') ? p.join(config.home, path.substring(2)) : path);
    return p.normalize(p.isAbsolute(expanded) ? expanded : p.join(config.workspace, expanded));
  }

  Future<void> _health(HttpRequest req) async {
    var diskFree = -1;
    try {
      final df = await Process.run('df', ['-Pk', config.home]);
      final parts = (df.stdout as String).trim().split('\n').last.split(RegExp(r'\s+'));
      diskFree = int.parse(parts[3]) * 1024;
    } catch (_) {}
    await _json(req.response, 200, {
      'ok': true,
      'uptime_s': DateTime.now().difference(_started).inSeconds,
      'running_execs': _execs.length,
      'open_terminals': _activeTerminals,
      'idle_s': (_execs.isEmpty && _activeTerminals == 0) ? DateTime.now().difference(_lastActivity).inSeconds : 0,
      'disk_free_bytes': diskFree,
      'display': Platform.environment['DISPLAY'] != null,
    });
  }

  // ---------------------------------------------------------------------------
  // exec

  /// Commands run in their own process group; signal the whole group.
  void _killTree(Process process) {
    Process.runSync('kill', ['-KILL', '-${process.pid}']);
    process.kill(ProcessSignal.sigkill);
  }

  /// Starts a command as the leader of a new process group (setsid on Linux; perl setpgrp elsewhere).
  Future<Process> _startGroup(List<String> argv, {required String cwd, required Map<String, String> env}) => Platform.isLinux
      ? Process.start('setsid', argv, workingDirectory: cwd, environment: env, includeParentEnvironment: false)
      : Process.start('perl', ['-e', 'setpgrp(0,0); exec @ARGV or die', ...argv],
          workingDirectory: cwd, environment: env, includeParentEnvironment: false);

  /// POST /exec {cmd, cwd?, env?, timeout_ms?, stdin?}. Streams NDJSON lines:
  /// {"type":"start","exec_id"} {"type":"stdout"|"stderr","data"} ... {"type":"exit","code","timed_out","truncated"}
  Future<void> _exec(HttpRequest req) async {
    final body = await _body(req);
    final cmd = body['cmd'];
    if (cmd is! String || cmd.isEmpty) throw _ApiError(400, 'bad_request', 'cmd is required');
    final cwd = _resolve(body['cwd'] as String?);
    if (!Directory(cwd).existsSync()) throw _ApiError(400, 'bad_cwd', 'Working directory does not exist: $cwd');
    final env = <String, String>{
      ...Platform.environment,
      'HOME': config.home,
      'TERM': 'dumb',
      ...((body['env'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {}),
    }..remove('COMPUTERD_TOKEN');
    final timeout = Duration(milliseconds: (body['timeout_ms'] as num?)?.toInt() ?? config.defaultTimeout.inMilliseconds);

    final process = await _startGroup(['bash', '-lc', cmd], cwd: cwd, env: env);
    final id = 'x${++_seq}-${process.pid}';
    final exec = _Exec(id, process);
    _execs[id] = exec;

    final res = req.response;
    res.statusCode = 200;
    res.headers.contentType = ContentType('application', 'x-ndjson', charset: 'utf-8');
    res.headers.set('x-exec-id', id);
    res.bufferOutput = false;
    void line(Map<String, Object?> m) => res.write('${jsonEncode(m)}\n');
    line({'type': 'start', 'exec_id': id});

    final stdinText = body['stdin'];
    if (stdinText is String) process.stdin.write(stdinText);
    await process.stdin.close();

    var bytes = 0;
    var truncated = false;
    Future<void> pump(Stream<List<int>> s, String type) =>
        s.transform(const Utf8Decoder(allowMalformed: true)).forEach((chunk) {
          if (truncated) return;
          bytes += chunk.length;
          if (bytes > config.maxOutputBytes) {
            truncated = true;
            line({'type': type, 'data': '\n[output truncated at ${config.maxOutputBytes} bytes]\n'});
            return;
          }
          line({'type': type, 'data': chunk});
        });

    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      _killTree(process);
    });
    final done = Future.wait([pump(process.stdout, 'stdout'), pump(process.stderr, 'stderr')]);
    final code = await process.exitCode;
    await done;
    timer.cancel();
    _execs.remove(id);
    _lastActivity = DateTime.now();
    line({'type': 'exit', 'code': code, 'timed_out': timedOut, 'killed': exec.killed, 'truncated': truncated});
    await res.close();
  }

  Future<void> _kill(HttpRequest req, String id) async {
    final e = _execs[id];
    if (e == null) throw _ApiError(404, 'not_found', 'No running exec $id');
    e.killed = true;
    _killTree(e.process);
    await _json(req.response, 200, {'killed': id});
  }

  // ---------------------------------------------------------------------------
  // files

  Future<void> _readFile(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path']);
    final file = File(path);
    if (!file.existsSync()) throw _ApiError(404, 'not_found', 'No such file: $path');
    final res = req.response;
    res.headers.contentType = ContentType.binary;
    res.headers.contentLength = file.lengthSync();
    await res.addStream(file.openRead());
    await res.close();
  }

  Future<void> _writeFile(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path']);
    final file = File(path);
    file.parent.createSync(recursive: true);
    final sink = file.openWrite();
    await sink.addStream(req);
    await sink.close();
    await _json(req.response, 200, {'path': path, 'size': file.lengthSync()});
  }

  Future<void> _deleteFile(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path']);
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) throw _ApiError(404, 'not_found', 'No such path: $path');
    if (path == config.home || path == config.workspace || path == '/') throw _ApiError(400, 'refused', 'Refusing to delete $path');
    if (type == FileSystemEntityType.directory) {
      Directory(path).deleteSync(recursive: true);
    } else {
      File(path).deleteSync();
    }
    await _json(req.response, 200, {'deleted': path});
  }

  Future<void> _listDir(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path']);
    final dir = Directory(path);
    if (!dir.existsSync()) throw _ApiError(404, 'not_found', 'No such directory: $path');
    final entries = <Map<String, Object?>>[];
    for (final e in dir.listSync(followLinks: false)) {
      final stat = e.statSync();
      entries.add({
        'name': p.basename(e.path),
        'path': e.path,
        'type': switch (stat.type) {
          FileSystemEntityType.directory => 'dir',
          FileSystemEntityType.link => 'link',
          _ => 'file',
        },
        'size': stat.size,
        'modified': stat.modified.toUtc().toIso8601String(),
      });
      if (entries.length >= 5000) break;
    }
    entries.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    await _json(req.response, 200, {'path': path, 'entries': entries});
  }

  /// POST /files/search {query, path?, max_results?}: case-insensitive text search (grep).
  Future<void> _search(HttpRequest req) async {
    final body = await _body(req);
    final query = body['query'];
    if (query is! String || query.isEmpty) throw _ApiError(400, 'bad_request', 'query is required');
    final path = _resolve(body['path'] as String?);
    final max = (body['max_results'] as num?)?.toInt() ?? 100;
    final r = await Process.run('grep', ['-rniI', '--exclude-dir=.git', '--exclude-dir=node_modules', '-m', '5', '-F', '--', query, path]);
    final lines = (r.stdout as String).split('\n').where((l) => l.isNotEmpty).take(max).map((l) {
      final m = RegExp(r'^(.*?):(\d+):(.*)$').firstMatch(l);
      return m == null ? {'line_text': l} : {'path': m[1], 'line': int.parse(m[2]!), 'text': m[3]!.length > 300 ? m[3]!.substring(0, 300) : m[3]};
    }).toList();
    await _json(req.response, 200, {'matches': lines});
  }

  // ---------------------------------------------------------------------------
  // archives (sleep and checkpoints)

  /// POST /archive {path?, exclude?}: streams a gzip tarball of a directory (default: home).
  Future<void> _archive(HttpRequest req) async {
    final body = await _body(req);
    final path = _resolve((body['path'] as String?) ?? config.home);
    final excludes = <String>[
      ...((body['exclude'] as List?)?.cast<String>() ?? const []),
      '.cache/ms-playwright',
      '.npm/_cacache',
      '.cache/pip',
      '.kasama-restore-*',
    ];
    final process = await Process.start('tar', [
      '-czf', '-',
      for (final e in excludes) '--exclude=./$e',
      '-C', path, '.',
    ]);
    final res = req.response;
    res.headers.contentType = ContentType('application', 'gzip');
    res.bufferOutput = false;
    final err = utf8.decodeStream(process.stderr);
    await res.addStream(process.stdout);
    final code = await process.exitCode;
    // tar exits 1 when files changed while reading; the archive is still usable.
    if (code > 1) stderr.writeln('archive failed: ${await err}');
    await res.close();
  }

  /// POST /restore?path=: replaces a directory's contents with the uploaded gzip tarball.
  Future<void> _restore(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path'] ?? config.home);
    final dir = Directory(path);
    // Stage inside the target: the parent may be read-only (the home volume is the only writable place).
    final staging = Directory(p.join(path, '.kasama-restore-${DateTime.now().microsecondsSinceEpoch}'));
    staging.createSync(recursive: true);
    final process = await Process.start('tar', ['-xzf', '-', '-C', staging.path]);
    await process.stdin.addStream(req);
    await process.stdin.close();
    final err = await utf8.decodeStream(process.stderr);
    final code = await process.exitCode;
    if (code != 0) {
      staging.deleteSync(recursive: true);
      throw _ApiError(400, 'restore_failed', err.trim());
    }
    // Swap contents in place (the directory itself may be a mount point).
    if (dir.existsSync()) {
      for (final e in dir.listSync(followLinks: false)) {
        if (e.path == staging.path) continue;
        e.deleteSync(recursive: true);
      }
    } else {
      dir.createSync(recursive: true);
    }
    for (final e in staging.listSync(followLinks: false)) {
      e.renameSync(p.join(path, p.basename(e.path)));
    }
    staging.deleteSync(recursive: true);
    Directory(config.workspace).createSync(recursive: true);
    await _json(req.response, 200, {'restored': path});
  }

  // ---------------------------------------------------------------------------
  // terminal (WebSocket): binary frames carry terminal bytes both ways;
  // text frames carry JSON control messages, e.g. {"type":"resize","cols":120,"rows":40}.

  Future<void> _terminal(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) throw _ApiError(400, 'bad_request', 'WebSocket upgrade required');
    final cols = int.tryParse(req.uri.queryParameters['cols'] ?? '') ?? 120;
    final rows = int.tryParse(req.uri.queryParameters['rows'] ?? '') ?? 32;
    final ws = await WebSocketTransformer.upgrade(req);
    final env = <String, String>{...Platform.environment, 'HOME': config.home, 'TERM': 'xterm-256color', 'COLUMNS': '$cols', 'LINES': '$rows'}
      ..remove('COMPUTERD_TOKEN');
    // `script` allocates a pseudo-terminal for an interactive login shell.
    final process = Platform.isLinux
        ? await _startGroup(['script', '-qfc', 'stty cols $cols rows $rows; exec bash -l', '/dev/null'], cwd: config.workspace, env: env)
        : await _startGroup(['script', '-q', '/dev/null', 'bash', '-l'], cwd: config.workspace, env: env);
    _activeTerminals++;
    _terminals.add(process);
    final out = process.stdout.listen((b) => ws.add(b));
    final err = process.stderr.listen((b) => ws.add(b));
    ws.listen(
      (msg) {
        _lastActivity = DateTime.now();
        if (msg is List<int>) {
          process.stdin.add(msg);
        } else if (msg is String) {
          try {
            final m = jsonDecode(msg) as Map<String, dynamic>;
            if (m['type'] == 'input' && m['data'] is String) process.stdin.write(m['data']);
            // Resizing needs the pty's ioctl, which `script` does not expose; ignored for now.
          } catch (_) {}
        }
      },
      onDone: () => _killTree(process),
      cancelOnError: true,
    );
    await process.exitCode;
    await out.cancel();
    await err.cancel();
    _activeTerminals--;
    _terminals.remove(process);
    await ws.close();
  }

  // ---------------------------------------------------------------------------
  // desktop (Phase 5 uses these through agent-desktop's screenshot fallback)

  Future<void> _screenshot(HttpRequest req) async {
    if (Platform.environment['DISPLAY'] == null) throw _ApiError(501, 'no_display', 'This computer has no desktop running');
    final r = await Process.run('import', ['-window', 'root', 'png:-'], stdoutEncoding: null);
    if (r.exitCode != 0) throw _ApiError(500, 'screenshot_failed', '${r.stderr}');
    final res = req.response;
    res.headers.contentType = ContentType('image', 'png');
    res.add(r.stdout as List<int>);
    await res.close();
  }

  /// POST /input {type:"click"|"move"|"type"|"key"|"scroll", x?, y?, button?, text?, key?, dy?}
  Future<void> _input(HttpRequest req) async {
    if (Platform.environment['DISPLAY'] == null) throw _ApiError(501, 'no_display', 'This computer has no desktop running');
    final b = await _body(req);
    final args = switch (b['type']) {
      'move' => ['mousemove', '${b['x']}', '${b['y']}'],
      'click' => ['mousemove', '${b['x']}', '${b['y']}', 'click', '${b['button'] ?? 1}'],
      'type' => ['type', '--delay', '12', '--', '${b['text'] ?? ''}'],
      'key' => ['key', '--', '${b['key']}'],
      'scroll' => ['click', ((b['dy'] as num?) ?? 0) > 0 ? '5' : '4'],
      _ => throw _ApiError(400, 'bad_request', 'Unknown input type'),
    };
    final r = await Process.run('xdotool', args);
    if (r.exitCode != 0) throw _ApiError(500, 'input_failed', '${r.stderr}');
    await _json(req.response, 200, {'ok': true});
  }
}

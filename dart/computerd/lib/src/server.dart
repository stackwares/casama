import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'mcp_bridge.dart';
import 'mcp_oauth.dart';
import 'thumbnails.dart';

/// computerd configuration. Inside a computer: HOME=/home/casama, workspace under it.
class ComputerdConfig {
  ComputerdConfig({
    required this.home,
    required this.token,
    this.port = 7070,
    this.address = '0.0.0.0',
    this.maxOutputBytes = 10 * 1024 * 1024,
    this.defaultTimeout = const Duration(minutes: 10),
    this.allowedRoots,
    this.capabilities,
    this.extraPath = const [],
    this.extraEnv = const {},
    this.mcpServers = const {},
    this.onMcpCredentials,
    this.imessageDb,
    this.imessageSendCommand,
    this.imessageSendFileCommand,
    this.thumbnailTools,
    this.thumbnailCacheDir,
    this.streamerCommand,
    this.streamPort = 8080,
    this.pluginsDir,
  });

  /// Companion mode: where plugin packages Casama places on this computer live (D-344):
  /// `<dir>/plugins/<name>` (PLUGIN_ROOT) and `<dir>/plugin-data/<name>` (PLUGIN_DATA). Defaults to
  /// `~/.casama`, outside the shared folders on purpose: bots can't edit a plugin's code.
  final String? pluginsDir;

  /// Live view: a streamer to run instead of Neko, and the port it answers on. Tests pass a fake,
  /// which also stands in for the desktop, so they need no display.
  final List<String>? streamerCommand;
  final int streamPort;

  /// Thumbnails (D-226): the tools that make them (tests pass fakes) and where they are cached.
  /// The cache defaults to ~/.cache/casama/thumbs in a bot computer (left out of archives) and the
  /// system temp folder on a person's own computer.
  final ThumbnailTools? thumbnailTools;
  final String? thumbnailCacheDir;

  /// iMessage chat apps (D-134): the Messages database to read (default ~/Library/Messages/chat.db).
  final String? imessageDb;

  /// iMessage: a command run with the recipient and text as its last two arguments, instead of
  /// AppleScript (tests).
  final List<String>? imessageSendCommand;

  /// iMessage: a command run with the recipient and a file path as its last two arguments, instead
  /// of AppleScript (tests).
  final List<String>? imessageSendFileCommand;

  /// Companion mode: local MCP servers the user added (D-096), reached at `/mcp/<key>`.
  final Map<String, LocalMcpServer> mcpServers;

  /// A local MCP server's OAuth tokens were refreshed, or null when the person must sign in again
  /// (D-363). The desktop app saves them with the server.
  final void Function(String key, McpOAuthCredentials? creds)? onMcpCredentials;

  final String home;

  /// Companion mode (D-066): file paths and working directories must stay inside these folders.
  /// Null inside a bot computer (the whole container is the bot's).
  final List<String>? allowedRoots;

  /// Companion mode: which tool families the user approved (shell, files, browser, desktop).
  /// Null inside a bot computer (everything allowed).
  final Set<String>? capabilities;

  /// Extra PATH entries (for example Homebrew on macOS, where apps start with a minimal PATH).
  final List<String> extraPath;

  /// Added to every command's environment (the companion isolates agent-browser with its own
  /// namespace and session so it never touches the user's other browser sessions).
  final Map<String, String> extraEnv;

  bool get companion => allowedRoots != null;
  bool can(String capability) => capabilities == null || capabilities!.contains(capability);
  final String token;
  final int port;
  final String address;
  final int maxOutputBytes;
  final Duration defaultTimeout;

  /// The default working directory: ~/workspace in a bot computer, the first allowed folder on a
  /// user's machine.
  String get workspace => allowedRoots?.isNotEmpty == true ? allowedRoots!.first : p.join(home, 'workspace');

  factory ComputerdConfig.fromEnvironment(Map<String, String> env) {
    final token = env['COMPUTERD_TOKEN'];
    if (token == null || token.length < 16) {
      throw StateError('COMPUTERD_TOKEN (at least 16 characters) is required');
    }
    return ComputerdConfig(
      home: env['COMPUTERD_HOME'] ?? env['HOME'] ?? '/home/casama',
      token: token,
      port: int.tryParse(env['COMPUTERD_PORT'] ?? '') ?? 7070,
      address: env['COMPUTERD_ADDRESS'] ?? '0.0.0.0',
      // Companion mode: colon-separated folders and comma-separated capabilities.
      allowedRoots: env['COMPUTERD_ALLOWED_ROOTS']?.split(':').where((r) => r.isNotEmpty).toList(),
      capabilities: env['COMPUTERD_CAPABILITIES']?.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toSet(),
      mcpServers: LocalMcpServer.parseAll(env['COMPUTERD_MCP_SERVERS']),
      pluginsDir: env['COMPUTERD_PLUGINS_DIR'],
      imessageDb: env['COMPUTERD_IMESSAGE_DB'],
      imessageSendCommand: env['COMPUTERD_IMESSAGE_SEND_CMD']?.split(' ').where((s) => s.isNotEmpty).toList(),
      imessageSendFileCommand: env['COMPUTERD_IMESSAGE_SEND_FILE_CMD']?.split(' ').where((s) => s.isNotEmpty).toList(),
    );
  }
}

/// Whether `agent-desktop permissions` output says Screen Recording is denied (D-376).
bool screenRecordingDenied(String agentDesktopOutput) {
  try {
    final env = jsonDecode(agentDesktopOutput.trim());
    if (env is! Map) return false;
    final data = env['data'];
    if (data is! Map) return false;
    final sr = data['screen_recording'];
    return sr is Map && sr['state'] == 'denied';
  } catch (_) {
    return false;
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

  late final ThumbnailService _thumbs = ThumbnailService(
    tools: config.thumbnailTools ?? ThumbnailTools(extraPath: config.extraPath),
    cacheDir:
        config.thumbnailCacheDir ??
        (config.companion ? p.join(Directory.systemTemp.path, 'casama-thumbs') : p.join(config.home, '.cache', 'casama', 'thumbs')),
  );

  /// Local MCP servers (companion mode, D-096).
  late final McpBridge mcp = McpBridge(config.mcpServers, checkCwd: (cwd) => _allowed(cwd), onCredentials: config.onMcpCredentials, extraPath: config.extraPath);

  Future<void> start() async {
    if (!config.companion) Directory(config.workspace).createSync(recursive: true);
    _server = await HttpServer.bind(config.address, config.port);
    _server!.listen(_handle);
  }

  Future<void> stop() async {
    await _stopStreamer();
    for (final e in _execs.values) {
      _killTree(e.process);
    }
    for (final t in _terminals) {
      _killTree(t);
    }
    await mcp.stopAll();
    await _server?.close(force: true);
  }

  // ---------------------------------------------------------------------------

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.uri.path == '/health') return await _health(req);
      final auth = req.headers.value('authorization') ?? '';
      // Behind a proxy that uses Authorization itself (Kubernetes pod proxy, D-139), the token comes in X-Computerd-Token.
      final alt = req.headers.value('x-computerd-token');
      if (auth != 'Bearer ${config.token}' && alt != config.token) throw _ApiError(401, 'unauthorized', 'Invalid computerd token');
      _lastActivity = DateTime.now();
      final segments = req.uri.pathSegments;
      switch ((req.method, segments)) {
        // Plugin MCP servers in a bot's computer (D-121); the companion's come from the app.
        case ('PUT', ['mcp-servers']) when !config.companion:
          final body = await utf8.decoder.bind(req).join();
          await mcp.update(LocalMcpServer.parseAll(body));
          return await _json(res, 200, {'ok': true, 'servers': mcp.servers.keys.toList()});
        // Plugin servers placed on a person's own computer (D-344), pushed by the API itself.
        case ('GET', ['plugins']) || ('PUT', ['plugins', _]) || ('PUT', ['plugin-servers']) when !config.companion:
          throw _ApiError(404, 'not_found', 'No such endpoint');
        case ('GET', ['plugins']):
          _need('mcp');
          return await _json(res, 200, {'commits': _pluginCommits(), 'servers': mcp.pluginServers.keys.toList()});
        case ('PUT', ['plugins', final name]):
          _need('mcp');
          return await _putPlugin(req, name);
        case ('PUT', ['plugin-servers']):
          _need('mcp');
          return await _putPluginServers(req);
        case ('POST' || 'GET', ['mcp', final key]):
          if (config.companion) _need('mcp');
          return await mcp.handle(req, key);
        // iMessage chat apps (D-134): only on a user's Mac, with Messages allowed.
        case ('GET', ['imessage', 'new']) || ('POST', ['imessage', 'send']) || ('GET', ['imessage', 'attachment', _]) when !config.companion:
          throw _ApiError(404, 'not_found', 'No such endpoint');
        case ('GET', ['imessage', 'new']):
          _need('messages');
          return await _imessageNew(req);
        case ('POST', ['imessage', 'send']):
          _need('messages');
          return await _imessageSend(req);
        case ('GET', ['imessage', 'attachment', final id]):
          _need('messages');
          return await _imessageAttachment(req, id);
        case ('POST', ['exec']):
          return await _exec(req);
        case ('POST', ['exec', final id, 'kill']):
          return await _kill(req, id);
        case ('GET' || 'PUT' || 'DELETE', ['files', ...]) || ('POST', ['files', 'search']) when config.companion && !config.can('files'):
          _need('files');
        case ('POST', ['archive']) || ('POST', ['restore']) || ('GET', ['terminal']) || ('POST', ['stream', ...]) when config.companion:
          throw _ApiError(403, 'not_on_companion', 'Not available on a personal computer');
        case ('GET', ['screenshot']) || ('POST', ['input']) when config.companion && !config.can('desktop'):
          _need('desktop');
        case ('GET', ['files']):
          return await _readFile(req);
        case ('PUT', ['files']):
          return await _writeFile(req);
        case ('DELETE', ['files']):
          return await _deleteFile(req);
        case ('GET', ['files', 'list']):
          return await _listDir(req);
        case ('GET', ['files', 'thumbnail']):
          return await _thumbnail(req);
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
        case ('POST', ['stream', 'start']):
          return await _streamStart(req);
        case ('POST', ['stream', 'stop']):
          await _stopStreamer();
          return await _json(res, 200, {'ok': true});
        case ('GET', ['stream']):
          return await _json(res, 200, {'running': _streamer != null, 'port': config.streamPort});
        default:
          throw _ApiError(404, 'not_found', 'No such endpoint');
      }
    } on McpBridgeError catch (e) {
      await _json(res, e.status, {'code': e.code, 'message': e.message});
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

  // ---------------------------------------------------------------------------
  // iMessage (D-134)

  String get _messagesDb => config.imessageDb ?? p.join(config.home, 'Library', 'Messages', 'chat.db');

  Future<List<dynamic>> _messagesQuery(String q) async {
    if (!File(_messagesDb).existsSync()) throw _ApiError(501, 'no_messages', 'Messages has no database on this computer');
    final r = await Process.run('sqlite3', ['-readonly', '-json', _messagesDb, q]);
    if (r.exitCode != 0) {
      throw _ApiError(502, 'messages_unreadable', 'Could not read Messages (give the Casama app Full Disk Access): ${(r.stderr as String).trim()}');
    }
    final out = (r.stdout as String).trim();
    return out.isEmpty ? const [] : jsonDecode(out) as List<dynamic>;
  }

  /// Messages received since a row id (from other people, with text or attachments), oldest first,
  /// plus the newest row id so the first call can take a baseline without answering old messages.
  /// Attachments (D-342) are listed with their ids, for /imessage/attachment/{id}.
  Future<void> _imessageNew(HttpRequest req) async {
    final since = int.tryParse(req.uri.queryParameters['since'] ?? '') ?? 0;
    final latest = await _messagesQuery('select coalesce(max(ROWID), 0) as latest from message');
    final hasAttachments = (await _messagesQuery("select count(*) as n from sqlite_master where name in ('attachment', 'message_attachment_join')")).first['n'] == 2;
    final List<dynamic> rows;
    if (since <= 0) {
      rows = const [];
    } else if (hasAttachments) {
      rows = await _messagesQuery(
        'select m.ROWID as rowid, h.id as handle, m.text as text, '
        "(select json_group_array(json_object('id', a.ROWID, 'name', a.transfer_name, 'mime', a.mime_type, 'size', a.total_bytes)) "
        'from message_attachment_join j join attachment a on a.ROWID = j.attachment_id where j.message_id = m.ROWID) as attachments '
        'from message m join handle h on h.ROWID = m.handle_id '
        "where m.is_from_me = 0 and m.ROWID > $since and ((m.text is not null and m.text != '') "
        'or exists (select 1 from message_attachment_join j where j.message_id = m.ROWID)) order by m.ROWID limit 50',
      );
      for (final r in rows.cast<Map<String, dynamic>>()) {
        final list = r['attachments'] is String ? jsonDecode(r['attachments'] as String) as List<dynamic> : const [];
        r['attachments'] = list;
        // Messages puts U+FFFC in the text where an attachment sits.
        final text = (r['text'] as String?)?.replaceAll('\uFFFC', '').trim();
        r['text'] = text == null || text.isEmpty ? null : text;
      }
    } else {
      rows = await _messagesQuery(
        'select m.ROWID as rowid, h.id as handle, m.text as text from message m join handle h on h.ROWID = m.handle_id '
        'where m.is_from_me = 0 and m.ROWID > $since and m.text is not null and m.text != \'\' order by m.ROWID limit 50',
      );
    }
    await _json(req.response, 200, {'latest': (latest.isEmpty ? 0 : (latest.first as Map)['latest']) ?? 0, 'messages': rows});
  }

  /// The bytes of an attachment someone sent (D-342); only attachments of messages from others.
  Future<void> _imessageAttachment(HttpRequest req, String id) async {
    final n = int.tryParse(id);
    if (n == null) throw _ApiError(400, 'invalid_request', 'Bad attachment id');
    final rows = await _messagesQuery(
      'select a.filename as filename, a.mime_type as mime from attachment a join message_attachment_join j on j.attachment_id = a.ROWID '
      'join message m on m.ROWID = j.message_id where a.ROWID = $n and m.is_from_me = 0 limit 1',
    );
    if (rows.isEmpty) throw _ApiError(404, 'not_found', 'No such attachment');
    final raw = (rows.first as Map)['filename'] as String? ?? '';
    final path = raw.startsWith('~/') ? p.join(config.home, raw.substring(2)) : raw;
    final file = File(path);
    if (raw.isEmpty || !file.existsSync()) throw _ApiError(404, 'not_found', 'The attachment is not on this Mac (still downloading, or offloaded to iCloud)');
    if (file.lengthSync() > 25 * 1024 * 1024) throw _ApiError(413, 'too_large', 'The attachment is larger than 25 MB');
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.parse((rows.first as Map)['mime'] as String? ?? 'application/octet-stream');
    await req.response.addStream(file.openRead());
    await req.response.close();
  }

  Future<void> _imessageSend(HttpRequest req) async {
    final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
    final to = body['to'] as String? ?? '';
    final text = body['text'] as String? ?? '';
    final file = body['file'] as Map<String, dynamic>?;
    if (to.isEmpty) throw _ApiError(400, 'invalid_request', 'Need to');
    // A file (D-342): written to an outbox folder Messages can read, then sent as an attachment.
    // The text that comes with it is the file's link, for older Macs; it isn't sent as well.
    if (file != null) return _imessageSendFile(req, to, file);
    if (text.isEmpty) throw _ApiError(400, 'invalid_request', 'Need to and text');
    final cmd =
        config.imessageSendCommand ??
        [
          'osascript',
          '-e',
          'on run argv',
          '-e',
          'tell application "Messages" to send (item 2 of argv) to participant (item 1 of argv) of (1st account whose service type = iMessage)',
          '-e',
          'end run',
        ];
    final r = await Process.run(cmd.first, [...cmd.skip(1), to, text]);
    if (r.exitCode != 0) throw _ApiError(502, 'send_failed', 'Messages could not send: ${(r.stderr as String).trim()}');
    await _json(req.response, 200, {'ok': true});
  }

  Future<void> _imessageSendFile(HttpRequest req, String to, Map<String, dynamic> file) async {
    final name = p.basename(file['name'] as String? ?? 'file').replaceAll(RegExp(r'[/\\:\x00]'), '_').replaceAll(RegExp(r'^\.+'), '');
    final data = base64Decode(file['data'] as String? ?? '');
    if (data.isEmpty) throw _ApiError(400, 'invalid_request', 'Empty file');
    final outbox = Directory(p.join(config.home, 'Library', 'Application Support', 'Casama', 'iMessage Outbox'));
    await outbox.create(recursive: true);
    // Messages reads the file after the send call returns: files stay a day, then go.
    final now = DateTime.now();
    for (final old in outbox.listSync().whereType<Directory>()) {
      if (now.difference(old.statSync().modified).inHours >= 24) old.deleteSync(recursive: true);
    }
    final dir = await Directory(p.join(outbox.path, '${now.microsecondsSinceEpoch}')).create();
    final path = p.join(dir.path, name.isEmpty ? 'file' : name);
    await File(path).writeAsBytes(data);
    final cmd =
        config.imessageSendFileCommand ??
        [
          'osascript',
          '-e',
          'on run argv',
          '-e',
          'tell application "Messages" to send (POSIX file (item 2 of argv)) to participant (item 1 of argv) of (1st account whose service type = iMessage)',
          '-e',
          'end run',
        ];
    final r = await Process.run(cmd.first, [...cmd.skip(1), to, path]);
    if (r.exitCode != 0) throw _ApiError(502, 'send_failed', 'Messages could not send the file: ${(r.stderr as String).trim()}');
    await _json(req.response, 200, {'ok': true});
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
    if (path == null || path.isEmpty) return _allowed(config.workspace);
    final expanded = path == '~' ? config.home : (path.startsWith('~/') ? p.join(config.home, path.substring(2)) : path);
    return _allowed(p.normalize(p.isAbsolute(expanded) ? expanded : p.join(config.workspace, expanded)));
  }

  /// Companion mode: refuses paths outside the folders the user chose (symlinks resolved).
  String _allowed(String path) {
    final roots = config.allowedRoots;
    if (roots == null) return path;
    if (roots.isEmpty) throw _ApiError(403, 'outside_allowed_folders', 'No folders are shared with bots on this computer');
    String real(String x) {
      try {
        return File(x).resolveSymbolicLinksSync();
      } catch (_) {
        // A path that does not exist yet: check its parent.
        final parent = p.dirname(x);
        return parent == x ? x : p.join(real(parent), p.basename(x));
      }
    }

    final resolved = real(path);
    for (final r in roots) {
      final root = real(r);
      if (resolved == root || p.isWithin(root, resolved)) return path;
    }
    throw _ApiError(403, 'outside_allowed_folders', 'That path is outside the folders shared with bots on this computer');
  }

  // ---------------------------------------------------------------------------
  // Plugin servers on a person's own computer (D-344)

  String get _pluginsBase => config.pluginsDir ?? p.join(config.home, '.casama');
  String _pluginRoot(String name) => p.join(_pluginsBase, 'plugins', name);
  String _pluginData(String name) => p.join(_pluginsBase, 'plugin-data', name);
  static final _pluginName = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
  static final _safePath = RegExp(r'^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$');

  void _checkPluginName(String name) {
    if (!_pluginName.hasMatch(name) || name.contains('..')) throw _ApiError(400, 'bad_plugin_name', 'Not a plugin name: $name');
  }

  /// The commit of each plugin package on this computer.
  Map<String, String> _pluginCommits() {
    final dir = Directory(p.join(_pluginsBase, 'plugins'));
    if (!dir.existsSync()) return {};
    return {
      for (final d in dir.listSync().whereType<Directory>())
        if (File(p.join(d.path, '.casama-commit')).existsSync()) p.basename(d.path): File(p.join(d.path, '.casama-commit')).readAsStringSync().trim(),
    };
  }

  /// Writes a plugin package: `{commit, files: [{path, base64, executable}]}` replaces the folder.
  Future<void> _putPlugin(HttpRequest req, String name) async {
    _checkPluginName(name);
    final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
    final commit = '${body['commit'] ?? ''}';
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) throw _ApiError(400, 'bad_commit', 'A plugin package needs its commit');
    final files = [for (final f in (body['files'] as List? ?? const [])) (f as Map).cast<String, dynamic>()];
    for (final f in files) {
      final path = '${f['path']}';
      if (!_safePath.hasMatch(path) || path.split('/').any((s) => s == '..' || s == '.')) {
        throw _ApiError(400, 'bad_path', '$path isn\'t a safe file name');
      }
    }
    final root = Directory(_pluginRoot(name));
    if (root.existsSync()) root.deleteSync(recursive: true);
    root.createSync(recursive: true);
    Directory(_pluginData(name)).createSync(recursive: true);
    for (final f in files) {
      final file = File(p.joinAll([root.path, ...'${f['path']}'.split('/')]));
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(base64Decode('${f['base64'] ?? ''}'));
      if (f['executable'] == true && !Platform.isWindows) await Process.run('chmod', ['+x', file.path]);
    }
    File(p.join(root.path, '.casama-commit')).writeAsStringSync(commit);
    await _json(req.response, 200, {'ok': true, 'files': files.length});
  }

  /// Replaces the plugin servers: `{servers: {key: {plugin, command, args, cwd, env}}}`. Paths
  /// starting with `./` and `${PLUGIN_ROOT}`/`${PLUGIN_DATA}` are resolved here, in this
  /// computer's own folders. Packages no server uses any more are removed (their data stays).
  Future<void> _putPluginServers(HttpRequest req) async {
    final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
    final given = (body['servers'] as Map? ?? const {}).cast<String, dynamic>();
    final next = <String, LocalMcpServer>{};
    for (final e in given.entries) {
      final j = (e.value as Map).cast<String, dynamic>();
      final plugin = '${j['plugin'] ?? ''}';
      _checkPluginName(plugin);
      final root = _pluginRoot(plugin);
      final data = _pluginData(plugin);
      String x(String s) => s.replaceAll(r'${PLUGIN_ROOT}', root).replaceAll(r'${PLUGIN_DATA}', data);
      String local(String s) => s.startsWith('./') ? p.joinAll([root, ...s.substring(2).split('/')]) : x(s);
      final command = '${j['command'] ?? ''}';
      if (command.isEmpty) throw _ApiError(400, 'mcp_no_command', '${e.key} has no command');
      final cwd = j['cwd'] == null ? root : p.normalize(local('${j['cwd']}'));
      if (!(cwd == root || p.isWithin(root, cwd) || cwd == data || p.isWithin(data, cwd))) {
        throw _ApiError(400, 'bad_cwd', '${e.key} must run inside its plugin\'s folders');
      }
      Directory(data).createSync(recursive: true);
      next[e.key] = LocalMcpServer(
        key: e.key,
        kind: 'stdio',
        command: command.startsWith('./') ? local(command) : command,
        args: [for (final a in (j['args'] as List? ?? const [])) x('$a')],
        cwd: cwd,
        env: {
          for (final v in (j['env'] as Map? ?? const {}).entries) '${v.key}': x('${v.value}'),
          'PLUGIN_ROOT': root,
          'PLUGIN_DATA': data,
        },
        plugin: plugin,
      );
    }
    await mcp.updatePlugins(next);
    final used = {for (final s in next.values) s.plugin};
    for (final name in _pluginCommits().keys) {
      if (!used.contains(name)) Directory(_pluginRoot(name)).deleteSync(recursive: true);
    }
    await _json(req.response, 200, {'ok': true, 'servers': next.keys.toList()});
  }

  void _need(String capability) {
    if (!config.can(capability)) {
      final setting = _capabilityLabels[capability] ?? capability;
      throw _ApiError(403, 'capability_not_allowed',
          'This computer doesn\'t allow "$setting". The person can turn it on in the Casama app: Settings → Use this computer for bots.');
    }
  }

  /// The desktop app's names for each capability, so a refusal points at the switch to turn on.
  static const _capabilityLabels = {
    'shell': 'Run commands',
    'files': 'Read and edit files in shared folders',
    'browser': 'Use a browser',
    'desktop': 'Use desktop apps',
    'messages': 'Messages (iMessage)',
    'mcp': 'Local tools (MCP)',
  };

  /// Companion mode: which capability a command needs.
  static String _capabilityFor(String cmd) {
    final first = cmd.trimLeft().split(RegExp(r'\s+')).first;
    if (first == 'agent-browser') return 'browser';
    if (first == 'agent-desktop') return 'desktop';
    return 'shell';
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
      'display': Platform.isMacOS || Platform.environment['DISPLAY'] != null,
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
      : Process.start('perl', ['-e', 'setpgrp(0,0); exec @ARGV or die', ...argv], workingDirectory: cwd, environment: env, includeParentEnvironment: false);

  /// POST /exec {cmd, cwd?, env?, timeout_ms?, stdin?}. Streams NDJSON lines:
  /// {"type":"start","exec_id"} {"type":"stdout"|"stderr","data"} ... {"type":"exit","code","timed_out","truncated"}
  Future<void> _exec(HttpRequest req) async {
    final body = await _body(req);
    final cmd = body['cmd'];
    if (cmd is! String || cmd.isEmpty) throw _ApiError(400, 'bad_request', 'cmd is required');
    if (config.companion) _need(_capabilityFor(cmd));
    // A companion with no shared folders (browser or desktop only) runs commands in a temp folder.
    final cwd = config.companion && config.allowedRoots!.isEmpty && body['cwd'] == null ? Directory.systemTemp.path : _resolve(body['cwd'] as String?);
    if (!Directory(cwd).existsSync()) throw _ApiError(400, 'bad_cwd', 'Working directory does not exist: $cwd');
    final path = [...config.extraPath, Platform.environment['PATH'] ?? '/usr/bin:/bin'].join(':');
    final env = <String, String>{
      ...Platform.environment,
      ...config.extraEnv,
      'PATH': path,
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
    Future<void> pump(Stream<List<int>> s, String type) => s.transform(const Utf8Decoder(allowMalformed: true)).forEach((chunk) {
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

  /// GET /files/thumbnail?path=&size= (D-226): a JPEG or PNG no larger than size (128–640, default
  /// 480) of a video's first frame, an image or a PDF's first page. 404 no_thumbnail when the file
  /// has none or the computer lacks the tool; 503 thumbnail_busy when too many are waiting.
  Future<void> _thumbnail(HttpRequest req) async {
    final raw = req.uri.queryParameters['path'];
    if (raw == null || raw.isEmpty) throw _ApiError(400, 'bad_request', 'path is required');
    final path = _resolve(raw);
    if (!FileSystemEntity.isFileSync(path)) throw _ApiError(404, 'not_found', 'No such file: $path');
    final size = (int.tryParse(req.uri.queryParameters['size'] ?? '') ?? 480).clamp(128, 640);
    final Thumbnail? t;
    try {
      t = await _thumbs.thumbnail(File(path), size);
    } on ThumbnailBusy {
      throw _ApiError(503, 'thumbnail_busy', 'Too many thumbnails are being made; try again shortly');
    }
    if (t == null) throw _ApiError(404, 'no_thumbnail', 'No thumbnail for this file');
    final res = req.response;
    res.headers.contentType = ContentType.parse(t.contentType);
    res.headers.contentLength = t.bytes.length;
    res.headers.set('x-file-mtime', '${t.modified.millisecondsSinceEpoch}');
    if (t.durationMs != null) res.headers.set('x-duration-ms', '${t.durationMs}');
    res.add(t.bytes);
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
    final excludes = <String>[...((body['exclude'] as List?)?.cast<String>() ?? const []), '.cache/ms-playwright', '.npm/_cacache', '.cache/pip', '.cache/casama/thumbs', '.casama-restore-*'];
    final process = await Process.start('tar', ['-czf', '-', for (final e in excludes) '--exclude=./$e', '-C', path, '.']);
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

  /// Moves [from] to [to]; when [to] survived the clean-up, merges directories entry by entry and
  /// skips what can't be replaced.
  void _moveInto(FileSystemEntity from, String to) {
    final existing = FileSystemEntity.typeSync(to, followLinks: false);
    if (existing == FileSystemEntityType.notFound) {
      from.renameSync(to);
      return;
    }
    if (from is Directory && existing == FileSystemEntityType.directory) {
      for (final child in from.listSync(followLinks: false)) {
        _moveInto(child, p.join(to, p.basename(child.path)));
      }
      return;
    }
    try {
      File(to).deleteSync();
      from.renameSync(to);
    } on FileSystemException catch (err) {
      stderr.writeln('restore: skipped $to: ${err.osError?.message ?? err.message}');
    }
  }

  /// POST /restore?path=: replaces a directory's contents with the uploaded gzip tarball.
  Future<void> _restore(HttpRequest req) async {
    final path = _resolve(req.uri.queryParameters['path'] ?? config.home);
    final dir = Directory(path);
    // Stage inside the target: the parent may be read-only (the home volume is the only writable place).
    final staging = Directory(p.join(path, '.casama-restore-${DateTime.now().microsecondsSinceEpoch}'));
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
    // Swap contents in place (the directory itself may be a mount point). Entries that can't be
    // removed (for example root-owned files from an older image) are kept and merged into, so a
    // restore never stops halfway with the user's files left in staging.
    if (dir.existsSync()) {
      for (final e in dir.listSync(followLinks: false)) {
        if (e.path == staging.path) continue;
        try {
          e.deleteSync(recursive: true);
        } on FileSystemException catch (err) {
          stderr.writeln('restore: kept ${e.path}: ${err.osError?.message ?? err.message}');
        }
      }
    } else {
      dir.createSync(recursive: true);
    }
    for (final e in staging.listSync(followLinks: false)) {
      _moveInto(e, p.join(path, p.basename(e.path)));
    }
    try {
      staging.deleteSync(recursive: true);
    } on FileSystemException catch (err) {
      stderr.writeln('restore: could not remove ${staging.path}: ${err.message}');
    }
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
    final env = <String, String>{...Platform.environment, 'HOME': config.home, 'TERM': 'xterm-256color', 'COLUMNS': '$cols', 'LINES': '$rows'}..remove('COMPUTERD_TOKEN');
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
    final List<int> png;
    if (Platform.isMacOS) {
      png = await _macScreenshot();
    } else {
      if (Platform.environment['DISPLAY'] == null) throw _ApiError(501, 'no_display', 'This computer has no desktop running');
      final r = await Process.run('import', ['-window', 'root', 'png:-'], stdoutEncoding: null);
      if (r.exitCode != 0) throw _ApiError(500, 'screenshot_failed', '${r.stderr}');
      png = r.stdout as List<int>;
    }
    final res = req.response;
    res.headers.contentType = ContentType('image', 'png');
    res.add(png);
    await res.close();
  }

  /// A Mac (companion mode, D-376) has no X display: screencapture takes it. Without Screen
  /// Recording macOS hands back only the wallpaper instead of failing, so agent-desktop (when it's
  /// installed) is asked first; the code lets the run show the person a card to turn it on.
  Future<List<int>> _macScreenshot() async {
    try {
      final p = await Process.run('agent-desktop', ['permissions']).timeout(const Duration(seconds: 5));
      if (screenRecordingDenied('${p.stdout}')) {
        throw _ApiError(403, 'screen_recording_denied', 'Screen Recording is off for Casama on this Mac');
      }
    } on _ApiError {
      rethrow;
    } catch (_) {
      // No agent-desktop, or it didn't answer: try the screenshot anyway.
    }
    final dir = await Directory.systemTemp.createTemp('casama-shot');
    try {
      final file = File('${dir.path}/screen.png');
      final r = await Process.run('screencapture', ['-x', '-t', 'png', file.path]);
      if (r.exitCode != 0 || !await file.exists()) {
        final err = '${r.stderr}'.trim();
        throw _ApiError(500, 'screenshot_failed', err.isEmpty ? 'screencapture failed' : err);
      }
      return await file.readAsBytes();
    } finally {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
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

  // ---------------------------------------------------------------------------
  // live view: the Neko WebRTC streamer, started only while someone watches (D-054)

  Process? _streamer;
  Map<String, Object?>? _streamUsers;

  /// Names the relay outside this server that the running streamer was given, if any (ice_key).
  String? _streamIceKey;

  static String _secret() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(24, (_) => r.nextInt(256))).replaceAll('=', '');
  }

  static Future<String?> _ownAddress() async {
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in i.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
    return null;
  }

  /// POST /stream/start {ice_servers?: [...], ice_key?: "...", screen?: "1280x800@30"} -> {port, users:{viewer, controller}}
  ///
  /// A running streamer keeps the relays it started with. `ice_key` names a relay outside this
  /// server (someone watching from away, D-296): when the running streamer wasn't given that one,
  /// it starts again with these, because Neko reads its relays only when it starts.
  Future<void> _streamStart(HttpRequest req) async {
    if (Platform.environment['DISPLAY'] == null && config.streamerCommand == null) {
      throw _ApiError(501, 'no_display', 'This computer has no desktop running');
    }
    final b = await _body(req);
    final key = b['ice_key'];
    final iceKey = key is String && key.isNotEmpty ? key : null;
    if (_streamer != null && iceKey != null && iceKey != _streamIceKey) await _stopStreamer();
    if (_streamer == null) {
      final viewer = {'username': 'viewer', 'password': _secret()};
      final controller = {'username': 'controller', 'password': _secret()};
      // Multiuser: every login is its own session, so several people can watch at once.
      // "Admin" here only means the controller password; neither profile is a Neko admin.
      Map<String, Object?> profile({required bool host}) => {
        'name': host ? 'User' : 'Viewer',
        'is_admin': false,
        'can_login': true,
        'can_connect': true,
        'can_watch': true,
        'can_host': host,
        'can_access_clipboard': host,
        'can_share_media': false,
        'sends_inactive_cursor': false,
        'can_see_inactive_cursors': false,
      };
      final address = await _ownAddress();
      final env = {
        ...Platform.environment,
        'NEKO_SERVER_BIND': ':${config.streamPort}',
        'NEKO_MEMBER_PROVIDER': 'multiuser',
        'NEKO_MEMBER_MULTIUSER_USER_PASSWORD': viewer['password']!,
        'NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD': controller['password']!,
        'NEKO_MEMBER_MULTIUSER_USER_PROFILE': jsonEncode(profile(host: false)),
        'NEKO_MEMBER_MULTIUSER_ADMIN_PROFILE': jsonEncode(profile(host: true)),
        'NEKO_DESKTOP_SCREEN': '${b['screen'] ?? '1280x800@30'}',
        'NEKO_DESKTOP_INPUT_ENABLED': 'false',
        'NEKO_CAPTURE_MICROPHONE_ENABLED': 'false',
        'NEKO_PLUGINS_ENABLED': 'false',
        'NEKO_FILETRANSFER_ENABLED': 'false',
        'NEKO_CHAT_ENABLED': 'false',
        'NEKO_SESSION_IMPLICIT_HOSTING': 'false',
        'NEKO_WEBRTC_ICESERVERS_BACKEND': jsonEncode(b['ice_servers'] ?? const []),
        'NEKO_WEBRTC_ICESERVERS_FRONTEND': '[]',
        // Never look up a public IP; media goes through the TURN relay.
        'NEKO_WEBRTC_NAT1TO1': ?address,
        'NEKO_WEBRTC_IP_RETRIEVAL_URL': '',
      };
      final log = File('/tmp/neko.log').openWrite();
      final command = config.streamerCommand ?? const ['neko', 'serve'];
      final process = await Process.start(command.first, command.skip(1).toList(), environment: env);
      // Both streams go to one file; never let a logging error take computerd down.
      process.stdout.listen(log.add, onError: (_) {});
      process.stderr.listen(log.add, onError: (_) {});
      unawaited(process.exitCode.then((_) => log.close()).catchError((_) => null));
      _streamer = process;
      _streamUsers = {'viewer': viewer, 'controller': controller};
      _streamIceKey = iceKey;
      unawaited(
        process.exitCode.then((_) {
          if (identical(_streamer, process)) {
            _streamer = null;
            _streamUsers = null;
            _streamIceKey = null;
          }
        }),
      );
      final client = HttpClient();
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      var ready = false;
      while (DateTime.now().isBefore(deadline) && _streamer != null) {
        try {
          final r = await (await client.get('127.0.0.1', config.streamPort, '/health')).close();
          await r.drain<void>();
          if (r.statusCode == 200) {
            ready = true;
            break;
          }
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      client.close(force: true);
      if (!ready) {
        await _stopStreamer();
        throw _ApiError(500, 'stream_failed', 'The streamer did not start (see /tmp/neko.log)');
      }
    }
    await _json(req.response, 200, {'port': config.streamPort, 'users': _streamUsers});
  }

  Future<void> _stopStreamer() async {
    final s = _streamer;
    _streamer = null;
    _streamUsers = null;
    _streamIceKey = null;
    if (s == null) return;
    s.kill(ProcessSignal.sigint);
    await s.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        s.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  }
}

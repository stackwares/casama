import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'companion_stub.dart' if (dart.library.io) 'companion_io.dart' as impl;
import 'mcp_import.dart';

export 'mcp_import.dart' show FoundMcpServer;

/// What a bot is doing on this computer right now (shown in the overlay and tray).
class CompanionActivity {
  const CompanionActivity({required this.runId, required this.bot, required this.tool, required this.summary, this.botId});
  final String runId;
  final String bot;

  /// The acting bot's id, for its avatar; older servers don't send it.
  final String? botId;
  final String tool;
  final String summary;
}

enum CompanionStatus { off, connecting, online, error }

/// Settings the user approved on this machine (D-066). Capabilities: shell, files, browser, desktop.
class CompanionSettings {
  const CompanionSettings({required this.capabilities, required this.roots, this.mcpServers = const [], this.onMcpCredentials});
  final Set<String> capabilities;
  final List<String> roots;

  /// Local MCP servers (D-096), with their environment, passed to the embedded computerd.
  final List<LocalMcpConfig> mcpServers;

  /// A local server's OAuth tokens were refreshed (or null: sign in again), to keep with it (D-363).
  final void Function(String key, Map<String, dynamic>? oauth)? onMcpCredentials;
}

/// A local MCP server the user added (D-096). The whole thing, environment included, stays on this
/// computer; the workspace only sees [key], [label], [kind] and [summary].
class LocalMcpConfig {
  const LocalMcpConfig({
    required this.key,
    required this.label,
    required this.kind,
    this.command,
    this.args = const [],
    this.cwd,
    this.env = const {},
    this.url,
    this.timeoutS,
    this.headers = const {},
    this.auth = 'none',
    this.oauth,
    this.network = false,
    this.source,
  });

  factory LocalMcpConfig.fromJson(Map<String, dynamic> j) => LocalMcpConfig(
        key: j['key'] as String,
        label: j['label'] as String? ?? j['key'] as String,
        kind: j['kind'] == 'loopback' ? 'loopback' : 'stdio',
        command: j['command'] as String?,
        args: [for (final a in (j['args'] as List? ?? const [])) '$a'],
        cwd: j['cwd'] as String?,
        env: {for (final e in (j['env'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        url: j['url'] as String?,
        timeoutS: j['timeout_s'] as int?,
        headers: {for (final e in (j['headers'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        auth: const {'token', 'header', 'oauth'}.contains(j['auth']) ? j['auth'] as String : 'none',
        oauth: (j['oauth'] as Map?)?.cast<String, dynamic>(),
        network: j['network'] == true,
        source: j['source'] as String?,
      );

  final String key;
  final String label;

  /// stdio (a command) or loopback (an address on this computer).
  final String kind;
  final String? command;
  final List<String> args;
  final String? cwd;
  final Map<String, String> env;
  final String? url;
  final int? timeoutS;

  /// Sent with every request to a server at an address: a token as `Authorization: Bearer …`, or
  /// a header of its own (D-363). Kept on this computer.
  final Map<String, String> headers;

  /// How it signs in: none, token, header or oauth (a browser sign-in on this computer, D-363).
  final String auth;

  /// The OAuth sign-in's tokens (computerd's McpOAuthCredentials as JSON); null until signed in,
  /// or after the server refused them.
  final Map<String, dynamic>? oauth;

  /// May the address be elsewhere on the network (D-363)?
  final bool network;

  /// Where it came from when its address can change: "t3code" re-reads T3 Code's port at start.
  final String? source;

  /// Signs in with the browser, and isn't signed in now.
  bool get needsSignIn => auth == 'oauth' && oauth == null;

  /// What the workspace sees: the command or address, never the environment.
  String get summary => kind == 'loopback' ? (url ?? '') : [command ?? '', ...args].join(' ').trim();

  LocalMcpConfig copyWith({String? key, String? label, String? url, Map<String, String>? env, Map<String, String>? headers, Map<String, dynamic>? Function()? oauth}) => LocalMcpConfig(
        key: key ?? this.key,
        label: label ?? this.label,
        kind: kind,
        command: command,
        args: args,
        cwd: cwd,
        env: env ?? this.env,
        url: url ?? this.url,
        timeoutS: timeoutS,
        headers: headers ?? this.headers,
        auth: auth,
        oauth: oauth != null ? oauth() : this.oauth,
        network: network,
        source: source,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'kind': kind,
        'command': ?command,
        'args': args,
        'cwd': ?cwd,
        'env': env,
        'url': ?url,
        'timeout_s': ?timeoutS,
        if (headers.isNotEmpty) 'headers': headers,
        if (auth != 'none') 'auth': auth,
        'oauth': ?oauth,
        if (network) 'network': true,
        'source': ?source,
      };

  /// A key from a label: lower case letters, digits and underscores, starting with a letter.
  static String keyFor(String label, Iterable<String> taken) {
    var base = label.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp('^_+|_+\$'), '');
    if (base.isEmpty || !RegExp('^[a-z]').hasMatch(base)) base = 'mcp_$base';
    base = base.length > 24 ? base.substring(0, 24) : base;
    var key = base;
    for (var i = 2; taken.contains(key); i++) {
      key = '${base}_$i';
    }
    return key;
  }
}

/// Where local MCP servers are kept: secure storage, or a 0600 file when the keychain is unavailable.
abstract class LocalMcpStore {
  Future<List<LocalMcpConfig>> read(String orgId);
  Future<void> write(String orgId, List<LocalMcpConfig> servers);
}

final localMcpStoreProvider = Provider<LocalMcpStore>((ref) => impl.createMcpStore());

/// The desktop companion: runs computerd locally and answers the API's tunnel requests.
/// Keeps this machine's device id and token per workspace (secure storage; a 0600 file if the
/// keychain is unavailable, for example in unsigned development builds).
abstract class DeviceTokenStore {
  Future<(String, String)?> read(String orgId);
  Future<void> write(String orgId, String deviceId, String token);
  Future<void> delete(String orgId);
}

abstract class Companion {
  ValueListenable<CompanionStatus> get status;
  ValueListenable<CompanionActivity?> get activity;
  bool get supported;
  Future<void> start({required String apiUrl, required String deviceToken, required CompanionSettings settings});
  Future<void> stop();

  /// Coding agents installed on this computer (D-097): which of [bins] (the server's list, D-370;
  /// by default the agents this app knows) are on PATH or in the usual install folders.
  Future<List<String>> detectCodingAgents({Iterable<String> bins = builtInCodingAgentBins});

  /// MCP servers set up in other apps on this computer (D-363): T3 Code, Claude Code, Claude
  /// Desktop, Cursor, VS Code, Codex, Windsurf.
  Future<List<FoundMcpServer>> findMcpServers();

  /// Signs in to a local MCP server with the browser (MCP OAuth, D-363) and returns its tokens.
  Future<Map<String, dynamic>> signInMcp(LocalMcpConfig server);

  /// T3 Code's MCP address right now (its port can change between launches), or null.
  Future<String?> t3CodeMcpUrl();
}

/// The coding agents this app knows, for servers older than the catalog (D-370) and offline.
/// Older servers run exactly these five.
const builtInCodingAgents = <({String id, String label, String bin})>[
  (id: 'claude_code', label: 'Claude Code', bin: 'claude'),
  (id: 'codex', label: 'Codex', bin: 'codex'),
  (id: 'cursor', label: 'Cursor', bin: 'cursor-agent'),
  (id: 'pi', label: 'Pi', bin: 'pi'),
  (id: 't3code', label: 'T3 Code', bin: 't3'),
];
const builtInCodingAgentBins = ['claude', 'codex', 'cursor-agent', 'pi', 't3'];

/// A command name the scan may look for: letters, digits, dot, underscore, dash (no paths).
bool isAgentBin(String bin) => RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(bin);

final deviceTokenStoreProvider = Provider<DeviceTokenStore>((ref) => impl.createTokenStore());

final companionProvider = Provider<Companion>((ref) {
  final c = impl.createCompanion();
  ref.onDispose(c.stop);
  return c;
});

/// Splits a command line into words, keeping "quoted parts" together.
List<String> splitCommand(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  String? quote;
  var any = false;
  for (final ch in line.trim().split('')) {
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buf.write(ch);
      }
    } else if (ch == '"' || ch == "'") {
      quote = ch;
      any = true;
    } else if (ch == ' ' || ch == '\t') {
      if (buf.isNotEmpty || any) out.add(buf.toString());
      buf.clear();
      any = false;
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty || any) out.add(buf.toString());
  return out;
}

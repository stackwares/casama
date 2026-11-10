import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'companion_stub.dart' if (dart.library.io) 'companion_io.dart' as impl;

/// What a bot is doing on this computer right now (shown in the overlay and tray).
class CompanionActivity {
  const CompanionActivity({required this.runId, required this.bot, required this.tool, required this.summary});
  final String runId;
  final String bot;
  final String tool;
  final String summary;
}

enum CompanionStatus { off, connecting, online, error }

/// Settings the user approved on this machine (D-066). Capabilities: shell, files, browser, desktop.
class CompanionSettings {
  const CompanionSettings({required this.capabilities, required this.roots, this.mcpServers = const []});
  final Set<String> capabilities;
  final List<String> roots;

  /// Local MCP servers (D-096), with their environment, passed to the embedded computerd.
  final List<LocalMcpConfig> mcpServers;
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

  /// What the workspace sees: the command or address, never the environment.
  String get summary => kind == 'loopback' ? (url ?? '') : [command ?? '', ...args].join(' ').trim();

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

  /// Coding agents installed on this computer (D-097): any of claude, codex, cursor-agent.
  Future<List<String>> detectCodingAgents();
}

final deviceTokenStoreProvider = Provider<DeviceTokenStore>((ref) => impl.createTokenStore());

final companionProvider = Provider<Companion>((ref) {
  final c = impl.createCompanion();
  ref.onDispose(c.stop);
  return c;
});

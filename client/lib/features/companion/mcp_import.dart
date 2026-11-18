/// Finding MCP servers the person already set up in other apps (D-363): T3 Code, Claude Code,
/// Claude Desktop, Cursor, VS Code, Codex and Windsurf. This file only reads their settings; the
/// desktop app reads the files (companion_io.dart) and the person picks what to add.
library;

import 'dart:convert';

import 'package:casama_computerd/mcp_address.dart';

import 'companion.dart';

/// One server found in another app's settings.
class FoundMcpServer {
  const FoundMcpServer({
    required this.source,
    required this.name,
    required this.config,
    this.missing = const [],
    this.remote = false,
  });

  /// The app it came from, as people know it ("Claude Code").
  final String source;
  final String name;

  /// Ready to add, apart from [missing] values.
  final LocalMcpConfig config;

  /// Environment or header names whose values the app only refers to (`${GITHUB_TOKEN}`), and
  /// which aren't set here: the person types them in.
  final List<String> missing;

  /// A server on the internet: usually a workspace connection instead. Adding it here makes it
  /// reachable only through this computer.
  final bool remote;

  /// What identifies it, to tell whether it's already added.
  String get identity => config.summary;
}

/// The apps whose settings are read, and how.
enum McpSettingsFormat {
  /// `{"mcpServers": {name: {command, args, env} | {url | serverUrl, headers}}}`: Claude Desktop,
  /// Cursor, Windsurf, and Claude Code (which also has per-project lists under `projects`).
  mcpServers,

  /// VS Code: `{"servers": {...}, "inputs": [...]}` in mcp.json, or under `"mcp"` in settings.
  vscode,

  /// Codex: `[mcp_servers.<name>]` tables in config.toml.
  codexToml,

  /// T3 Code's server-runtime.json: its MCP server is at `<origin>/mcp` and signs in with OAuth.
  t3Runtime,
}

final _placeholder = RegExp(
  r'\$\{(?:env:)?([A-Za-z_][A-Za-z0-9_]*)(?::-([^}]*))?\}|\$\{input:([^}]+)\}',
);

/// Replaces `${VAR}`, `${env:VAR}` and `${VAR:-default}` with values from [env]. Names it can't
/// fill go in [missing] and are left empty.
String _fill(String s, Map<String, String> env, Set<String> missing) =>
    s.replaceAllMapped(_placeholder, (m) {
      final input = m.group(3);
      if (input != null) {
        missing.add(input);
        return '';
      }
      final name = m.group(1)!;
      final v = env[name] ?? m.group(2);
      if (v == null || v.isEmpty) {
        missing.add(name);
        return '';
      }
      return v;
    });

Map<String, String> _strings(Object? m) => {
  if (m is Map)
    for (final e in m.entries)
      if (e.value != null) '${e.key}': '${e.value}',
};

/// Reads one app's settings file. Bad or unknown content gives nothing rather than an error.
List<FoundMcpServer> parseMcpSettings(
  String source,
  McpSettingsFormat format,
  String text, {
  Map<String, String> env = const {},
}) {
  try {
    switch (format) {
      case McpSettingsFormat.t3Runtime:
        final j = jsonDecode(text) as Map<String, dynamic>;
        final origin = j['origin'] as String?;
        if (origin == null || origin.isEmpty) return const [];
        return [
          FoundMcpServer(
            source: source,
            name: 'T3 Code',
            config: LocalMcpConfig(
              key: 't3_code',
              label: 'T3 Code',
              kind: 'loopback',
              url: '${origin.replaceAll(RegExp(r'/+$'), '')}/mcp',
              auth: 'oauth',
              source: 't3code',
            ),
          ),
        ];
      case McpSettingsFormat.mcpServers:
        final j = jsonDecode(text) as Map<String, dynamic>;
        final out = <FoundMcpServer>[..._entries(source, j['mcpServers'], env)];
        // Claude Code keeps servers per project too.
        final projects = j['projects'];
        if (projects is Map) {
          for (final p in projects.values) {
            if (p is Map) out.addAll(_entries(source, p['mcpServers'], env));
          }
        }
        return _unique(out);
      case McpSettingsFormat.vscode:
        final j = jsonDecode(_stripJsonComments(text)) as Map<String, dynamic>;
        final block = j['servers'] != null
            ? j
            : (j['mcp'] as Map<String, dynamic>? ?? const {});
        return _unique(_entries(source, block['servers'], env).toList());
      case McpSettingsFormat.codexToml:
        final tables = parseTomlTables(text);
        final servers = <String, Map<String, Object?>>{};
        for (final e in tables.entries) {
          final parts = e.key.split('.');
          if (parts.length < 2 || parts.first != 'mcp_servers') continue;
          final name = parts[1];
          final s = servers.putIfAbsent(name, () => {});
          if (parts.length == 2) {
            s.addAll(e.value);
          } else if (parts.length == 3) {
            s[parts[2]] = e.value;
          }
        }
        final out = <FoundMcpServer>[];
        servers.forEach((name, raw) {
          final m = Map<String, Object?>.from(raw);
          // Codex names env vars to pass through, and a bearer token by its env var.
          final pass = m['env_vars'];
          if (pass is List) {
            final envMap = Map<String, Object?>.from(
              (m['env'] as Map?) ?? const {},
            );
            for (final v in pass) {
              envMap['$v'] = '\${$v}';
            }
            m['env'] = envMap;
          }
          final bearer = m['bearer_token_env_var'];
          final headers = Map<String, Object?>.from(
            (m['http_headers'] as Map?) ?? const {},
          );
          if (bearer is String) headers['Authorization'] = 'Bearer \${$bearer}';
          final envHeaders = m['env_http_headers'];
          if (envHeaders is Map) {
            envHeaders.forEach((k, v) => headers['$k'] = '\${$v}');
          }
          m['headers'] = headers;
          final f = _entry(source, name, m, env);
          if (f != null) out.add(f);
        });
        return out;
    }
  } catch (_) {
    return const [];
  }
}

Iterable<FoundMcpServer> _entries(
  String source,
  Object? servers,
  Map<String, String> env,
) sync* {
  if (servers is! Map) return;
  for (final e in servers.entries) {
    if (e.value is! Map) continue;
    final f = _entry(
      source,
      '${e.key}',
      (e.value as Map).cast<String, Object?>(),
      env,
    );
    if (f != null) yield f;
  }
}

List<FoundMcpServer> _unique(List<FoundMcpServer> found) {
  final seen = <String>{};
  return [
    for (final f in found)
      if (seen.add(f.identity)) f,
  ];
}

FoundMcpServer? _entry(
  String source,
  String name,
  Map<String, Object?> m,
  Map<String, String> env,
) {
  if (m['disabled'] == true || m['enabled'] == false) return null;
  final missing = <String>{};
  final label = name.trim().isEmpty ? 'MCP server' : name.trim();
  final key = LocalMcpConfig.keyFor(label, const {});
  final url = (m['url'] ?? m['serverUrl'] ?? m['httpUrl']) as String?;
  if (url != null && url.isNotEmpty) {
    final u = Uri.tryParse(_fill(url, env, missing));
    if (u == null || !u.hasScheme) return null;
    final headers = {
      for (final e in _strings(m['headers']).entries)
        e.key: _fill(e.value, env, missing),
    };
    final local = localMcpAddressProblem(u) == null;
    final lan =
        !local &&
        localMcpAddressProblem(u, network: true) == null &&
        isLocalNetworkHost(u.host);
    final remote = !local && !lan;
    if (remote && u.scheme != 'https') return null;
    final bearer = headers.entries
        .where(
          (e) =>
              e.key.toLowerCase() == 'authorization' &&
              e.value.toLowerCase().startsWith('bearer '),
        )
        .firstOrNull;
    final auth = headers.isEmpty
        ? 'none'
        : (bearer != null && headers.length == 1 ? 'token' : 'header');
    return FoundMcpServer(
      source: source,
      name: label,
      remote: remote,
      missing: missing.toList()..sort(),
      config: LocalMcpConfig(
        key: key,
        label: label,
        kind: 'loopback',
        url: u.toString(),
        headers: headers,
        auth: auth,
        network: !local,
      ),
    );
  }
  final command = m['command'] as String?;
  if (command == null || command.trim().isEmpty) return null;
  // A whole command line in "command" (some apps allow it) is split like the form does.
  final words = (m['args'] == null && command.contains(' '))
      ? splitCommand(command)
      : [command];
  final args = [
    ...words.skip(1),
    for (final a in (m['args'] as List? ?? const [])) _fill('$a', env, missing),
  ];
  final envOut = {
    for (final e in _strings(m['env']).entries)
      e.key: _fill(e.value, env, missing),
  };
  final cwd = m['cwd'] as String?;
  return FoundMcpServer(
    source: source,
    name: label,
    missing: missing.toList()..sort(),
    config: LocalMcpConfig(
      key: key,
      label: label,
      kind: 'stdio',
      command: _fill(words.first, env, missing),
      args: args,
      env: envOut,
      cwd: cwd == null ? null : _fill(cwd, env, missing),
    ),
  );
}

/// VS Code's settings allow // and /* */ comments and trailing commas.
String _stripJsonComments(String s) {
  final out = StringBuffer();
  var inString = false;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (inString) {
      out.write(c);
      if (c == r'\' && i + 1 < s.length) {
        out.write(s[++i]);
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') {
      inString = true;
      out.write(c);
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '/') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      out.write('\n');
    } else if (c == '/' && i + 1 < s.length && s[i + 1] == '*') {
      i += 2;
      while (i + 1 < s.length && !(s[i] == '*' && s[i + 1] == '/')) {
        i++;
      }
      i++;
    } else {
      out.write(c);
    }
  }
  return out.toString().replaceAllMapped(
    RegExp(r',(\s*[}\]])'),
    (m) => m.group(1)!,
  );
}

/// Just enough TOML for Codex's MCP tables: `[a.b]` headers and `key = value` lines with strings,
/// numbers, booleans, arrays and inline tables. Returns `{"a.b": {key: value}}`.
Map<String, Map<String, Object?>> parseTomlTables(String text) {
  final tables = <String, Map<String, Object?>>{'': {}};
  var current = '';
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('[') && !line.startsWith('[[')) {
      final end = line.indexOf(']');
      if (end < 0) continue;
      current = line
          .substring(1, end)
          .split('.')
          .map((p) => _unquote(p.trim()))
          .join('.');
      tables.putIfAbsent(current, () => {});
      continue;
    }
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = _unquote(line.substring(0, eq).trim());
    final p = _TomlValue(line.substring(eq + 1).trim());
    try {
      tables[current]![key] = p.value();
    } catch (_) {}
  }
  return tables;
}

String _unquote(String s) =>
    (s.length >= 2 &&
        (s.startsWith('"') && s.endsWith('"') ||
            s.startsWith("'") && s.endsWith("'")))
    ? s.substring(1, s.length - 1)
    : s;

class _TomlValue {
  _TomlValue(this.s);
  final String s;
  var i = 0;

  void _ws() {
    while (i < s.length && (s[i] == ' ' || s[i] == '\t')) {
      i++;
    }
  }

  Object? value() {
    _ws();
    if (i >= s.length) throw const FormatException('no value');
    final c = s[i];
    if (c == '"') return _basic();
    if (c == "'") return _literal();
    if (c == '[') return _array();
    if (c == '{') return _inline();
    final start = i;
    while (i < s.length && !',]}#'.contains(s[i])) {
      i++;
    }
    final word = s.substring(start, i).trim();
    if (word == 'true') return true;
    if (word == 'false') return false;
    return num.tryParse(word.replaceAll('_', '')) ?? word;
  }

  String _basic() {
    i++;
    final b = StringBuffer();
    while (i < s.length && s[i] != '"') {
      if (s[i] == r'\' && i + 1 < s.length) {
        i++;
        final e = s[i];
        b.write(switch (e) {
          'n' => '\n',
          't' => '\t',
          '"' => '"',
          r'\' => r'\',
          _ => e,
        });
      } else {
        b.write(s[i]);
      }
      i++;
    }
    i++;
    return b.toString();
  }

  String _literal() {
    i++;
    final start = i;
    while (i < s.length && s[i] != "'") {
      i++;
    }
    final out = s.substring(start, i);
    i++;
    return out;
  }

  List<Object?> _array() {
    i++;
    final out = <Object?>[];
    for (;;) {
      _ws();
      if (i >= s.length) break;
      if (s[i] == ']') {
        i++;
        break;
      }
      out.add(value());
      _ws();
      if (i < s.length && s[i] == ',') i++;
    }
    return out;
  }

  Map<String, Object?> _inline() {
    i++;
    final out = <String, Object?>{};
    for (;;) {
      _ws();
      if (i >= s.length) break;
      if (s[i] == '}') {
        i++;
        break;
      }
      final eq = s.indexOf('=', i);
      if (eq < 0) break;
      final key = _unquote(s.substring(i, eq).trim());
      i = eq + 1;
      out[key] = value();
      _ws();
      if (i < s.length && s[i] == ',') i++;
    }
    return out;
  }
}

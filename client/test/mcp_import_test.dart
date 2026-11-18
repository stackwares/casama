import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/companion/mcp_import.dart';

/// Reading MCP servers from other apps' settings (D-363).
void main() {
  test('Claude Code: top-level and per-project servers, filled from the environment', () {
    final found = parseMcpSettings(
      'Claude Code',
      McpSettingsFormat.mcpServers,
      r'''{"mcpServers": {"gh": {"command": "npx", "args": ["-y", "gh-mcp"], "env": {"TOKEN": "${GH_TOKEN}", "MODE": "${MODE:-fast}"}}},
          "projects": {"/x": {"mcpServers": {"figma": {"type": "http", "url": "http://127.0.0.1:3845/mcp"}, "gh": {"command": "npx", "args": ["-y", "gh-mcp"], "env": {"TOKEN": "${GH_TOKEN}", "MODE": "${MODE:-fast}"}}}}}}''',
      env: {'GH_TOKEN': 'ghp_1'},
    );
    expect(found.map((f) => f.name), [
      'gh',
      'figma',
    ], reason: 'the same server in a project is listed once');
    expect(found.first.config.env, {'TOKEN': 'ghp_1', 'MODE': 'fast'});
    expect(found.first.missing, isEmpty);
    expect(found.last.config.kind, 'loopback');
    expect(found.last.config.network, isFalse);
  });

  test('values that aren\'t set are asked for; internet servers need https and are marked', () {
    final found = parseMcpSettings(
      'Cursor',
      McpSettingsFormat.mcpServers,
      r'''{"mcpServers": {
        "a": {"url": "https://mcp.example.com/mcp", "headers": {"Authorization": "Bearer ${API_KEY}"}},
        "b": {"url": "http://mcp.example.com/mcp"},
        "c": {"url": "http://192.168.1.5:9000/mcp"},
        "d": {"command": "x", "disabled": true}
      }}''',
    );
    expect(found.map((f) => f.name), ['a', 'c']);
    expect(found[0].remote, isTrue);
    expect(found[0].missing, ['API_KEY']);
    expect(found[0].config.auth, 'token');
    expect(found[1].remote, isFalse);
    expect(found[1].config.network, isTrue);
  });

  test('VS Code: comments, trailing commas and inputs', () {
    final found = parseMcpSettings('VS Code', McpSettingsFormat.vscode, r'''{
      // my servers
      "inputs": [{"id": "key", "type": "promptString"}],
      "servers": {
        "fs": {"type": "stdio", "command": "npx", "args": ["fs-mcp", "${input:key}"],},
      },
    }''');
    expect(found.single.name, 'fs');
    expect(found.single.missing, ['key']);
  });

  test('Codex: TOML tables, env passthrough and a bearer token by env var', () {
    final found = parseMcpSettings(
      'Codex',
      McpSettingsFormat.codexToml,
      '''
model = "gpt-5"
[mcp_servers.docs]
command = "npx"
args = ["-y", "docs-mcp"] # comment
env_vars = ["DOCS_KEY"]

[mcp_servers.docs.env]
LEVEL = "2"

[mcp_servers.api]
url = "http://localhost:7000/mcp"
bearer_token_env_var = "API_TOKEN"
http_headers = { "X-Team" = "core" }
''',
      env: {'API_TOKEN': 't1'},
    );
    final docs = found.firstWhere((f) => f.name == 'docs');
    expect(docs.config.args, ['-y', 'docs-mcp']);
    expect(docs.config.env, {'LEVEL': '2', 'DOCS_KEY': ''});
    expect(docs.missing, ['DOCS_KEY']);
    final api = found.firstWhere((f) => f.name == 'api');
    expect(api.config.headers, {
      'X-Team': 'core',
      'Authorization': 'Bearer t1',
    });
    expect(api.config.auth, 'header');
  });

  test('T3 Code: its MCP server signs in with the browser', () {
    final found = parseMcpSettings(
      'T3 Code',
      McpSettingsFormat.t3Runtime,
      '{"origin": "http://127.0.0.1:3773/"}',
    );
    expect(found.single.config.url, 'http://127.0.0.1:3773/mcp');
    expect(found.single.config.auth, 'oauth');
    expect(found.single.config.source, 't3code');
    expect(
      parseMcpSettings('T3 Code', McpSettingsFormat.t3Runtime, 'not json'),
      isEmpty,
    );
  });
}

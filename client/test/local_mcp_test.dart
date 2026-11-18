import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/companion/companion.dart';
import 'package:casama/features/companion/companion_screen.dart';
import 'package:casama/features/companion/mcp_import.dart';
import 'package:casama/l10n/generated/app_localizations.dart';

import 'app_test.dart' show setSize;
import 'companion_test.dart' show FakeCompanion, MemoryMcp, MemoryTokens;
import 'fake_backend.dart';


void main() {
  test('splits command lines and makes keys', () {
    expect(splitCommand('npx -y "@acme/mcp server" --flag'), ['npx', '-y', '@acme/mcp server', '--flag']);
    expect(LocalMcpConfig.keyFor('Claude Code', {}), 'claude_code');
    expect(LocalMcpConfig.keyFor('Claude Code', {'claude_code'}), 'claude_code_2');
    expect(LocalMcpConfig.keyFor('3D tools', {}), 'mcp_3d_tools');
  });

  testWidgets('adds a local MCP server: secrets stay on the computer, the rest syncs', (tester) async {
    await setSize(tester, const Size(700, 1800));
    final backend = FakeBackend();
    final companion = FakeCompanion();
    final tokens = MemoryTokens();
    final mcp = MemoryMcp();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        companionProvider.overrideWithValue(companion),
        deviceTokenStoreProvider.overrideWithValue(tokens),
        localMcpStoreProvider.overrideWithValue(mcp),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompanionScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pairComputer')));
    await tester.pumpAndSettle();
    // Local tools are under Advanced (D-182).
    await tester.scrollUntilVisible(find.byKey(const Key('advanced-companion')), 200);
    await tester.tap(find.byKey(const Key('advanced-companion')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('cap-mcp')), 200);
    await tester.tap(find.byKey(const Key('cap-mcp')));
    await tester.pumpAndSettle();
    expect(companion.started?.capabilities, {'mcp'});

    await tester.scrollUntilVisible(find.byKey(const Key('addLocalMcp')), 200);
    await tester.tap(find.byKey(const Key('addLocalMcp')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('localMcpLabel')), 'Codex');
    await tester.enterText(find.byKey(const Key('localMcpCommand')), 'codex mcp-server');
    await tester.enterText(find.byKey(const Key('localMcpEnv')), 'OPENAI_API_KEY=sk-secret-123');
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();

    final saved = mcp.m[orgId]!.single;
    expect(saved.command, 'codex');
    expect(saved.args, ['mcp-server']);
    expect(saved.env, {'OPENAI_API_KEY': 'sk-secret-123'});
    final synced = backend.localMcpSyncs.last.single;
    expect(synced.key, 'codex');
    expect(synced.summary, 'codex mcp-server');
    expect(synced.toJson().toString(), isNot(contains('sk-secret')));
    expect(companion.started?.mcpServers.single.key, 'codex');
    expect(find.byKey(const Key('localMcp-codex')), findsOneWidget);

    // Test runs the workspace's check for this server and says what it found.
    await tester.tap(find.byKey(const Key('testLocalMcp-codex')));
    await tester.pumpAndSettle();
    expect(backend.tested, ['local-codex']);
    expect(find.text('Connected, 2 tools'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byKey(const Key('localMcp-codex')), matching: find.byTooltip('Delete')));
    await tester.pumpAndSettle();
    expect(mcp.m[orgId], isEmpty);
    expect(backend.localMcpSyncs.last, isEmpty);
  });

  testWidgets('shows coding agents found on this computer and turns on commands for them', (tester) async {
    await setSize(tester, const Size(700, 1800));
    final backend = FakeBackend();
    final companion = FakeCompanion()..codingAgents = ['claude', 'codex'];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        companionProvider.overrideWithValue(companion),
        deviceTokenStoreProvider.overrideWithValue(MemoryTokens()),
        localMcpStoreProvider.overrideWithValue(MemoryMcp()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompanionScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pairComputer')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('advanced-companion')), 200);
    await tester.tap(find.byKey(const Key('advanced-companion')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('codingAgent-codex')), 200);
    expect(find.text('Claude Code'), findsOneWidget);
    // Installed another one while the page was open: Refresh finds it.
    companion.codingAgents = ['claude', 'codex', 'cursor-agent', 'pi', 't3'];
    await tester.scrollUntilVisible(find.byKey(const Key('refreshCodingAgents')), -200);
    await tester.tap(find.byKey(const Key('refreshCodingAgents')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('codingAgent-cursor-agent')), findsOneWidget);
    expect(find.text('T3 Code'), findsOneWidget);
    expect(find.text('Found 5 coding agents'), findsOneWidget);
    expect(find.text('Pi'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('allowCodingAgents')), 200);
    await tester.tap(find.byKey(const Key('allowCodingAgents')));
    await tester.pumpAndSettle();
    expect(companion.started?.capabilities, contains('shell'));
  });

  testWidgets('a new device id registers the servers already on this computer, once', (tester) async {
    await setSize(tester, const Size(700, 1800));
    final backend = FakeBackend();
    final created = await backend.createLocalDevice(orgId, 'Mac', 'macos');
    final tokens = MemoryTokens()..m[orgId] = (created.id, 'kdev_test');
    final mcp = MemoryMcp()..m[orgId] = [const LocalMcpConfig(key: 't3code', label: 't3code', kind: 'stdio', command: 'node', args: ['t3-mcp.mjs'])];
    Widget app() => ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            companionProvider.overrideWithValue(FakeCompanion()),
            deviceTokenStoreProvider.overrideWithValue(tokens),
            localMcpStoreProvider.overrideWithValue(mcp),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CompanionScreen(),
          ),
        );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(backend.localMcpSyncs.single.single.key, 't3code', reason: 'the workspace had nothing for this device id');

    // Next launch: the workspace already has it under this id, so nothing is re-registered.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(backend.localMcpSyncs, hasLength(1));
  });

  /// Pairs this computer, turns on local MCP servers and scrolls to their section.
  Future<(FakeBackend, FakeCompanion, MemoryMcp)> openSection(WidgetTester tester, {List<FoundMcpServer> found = const []}) async {
    await setSize(tester, const Size(700, 2000));
    final backend = FakeBackend();
    final companion = FakeCompanion()..found = found;
    final mcp = MemoryMcp();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        companionProvider.overrideWithValue(companion),
        deviceTokenStoreProvider.overrideWithValue(MemoryTokens()),
        localMcpStoreProvider.overrideWithValue(mcp),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompanionScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pairComputer')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('advanced-companion')), 200);
    await tester.tap(find.byKey(const Key('advanced-companion')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('cap-mcp')), 200);
    await tester.tap(find.byKey(const Key('cap-mcp')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('addLocalMcp')), 200);
    return (backend, companion, mcp);
  }

  Future<void> addAddress(WidgetTester tester, String label, String url, {String auth = 'None'}) async {
    await tester.tap(find.byKey(const Key('addLocalMcp')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('localMcpLabel')), label);
    await tester.tap(find.text('An Address'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('localMcpUrl')), url);
    await tester.pumpAndSettle();
    if (auth != 'None') {
      await tester.tap(find.descendant(of: find.byKey(const Key('localMcpAuth')), matching: find.text(auth)));
      await tester.pumpAndSettle();
    }
  }

  const networkWarning = "This server isn't on this computer. Bots that can use this computer can reach it.";

  testWidgets('an address with a token: the token stays on the computer, the workspace knows the kind (D-363)', (tester) async {
    final (backend, companion, mcp) = await openSection(tester);
    await addAddress(tester, 'Figma', 'http://127.0.0.1:3845/mcp', auth: 'Token');
    expect(find.text(networkWarning), findsNothing);
    await tester.enterText(find.byKey(const Key('localMcpToken')), 'tok-secret');
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();

    final saved = mcp.m[orgId]!.single;
    expect(saved.headers, {'Authorization': 'Bearer tok-secret'});
    expect(saved.auth, 'token');
    expect(saved.network, isFalse);
    final synced = backend.localMcpSyncs.last.single;
    expect(synced.auth?.value, 'token');
    expect(synced.toJson().toString(), isNot(contains('tok-secret')));
    expect(companion.started?.mcpServers.single.headers, {'Authorization': 'Bearer tok-secret'});

    // Editing keeps the token and the key, and changes the name.
    await tester.tap(find.byKey(const Key('editLocalMcp-figma')));
    await tester.pumpAndSettle();
    expect(find.text('tok-secret'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('localMcpLabel')), 'Figma desktop');
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();
    final edited = mcp.m[orgId]!.single;
    expect((edited.key, edited.label), ('figma', 'Figma desktop'));
    expect(edited.headers, {'Authorization': 'Bearer tok-secret'});
  });

  testWidgets('an address on the local network warns, and the internet needs https', (tester) async {
    final (_, _, mcp) = await openSection(tester);
    await addAddress(tester, 'NAS', 'http://nas.example.com/mcp');
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();
    expect(mcp.m[orgId], isNull, reason: 'plain http on the internet is refused');

    await tester.enterText(find.byKey(const Key('localMcpUrl')), 'http://192.168.1.20:8080/mcp');
    await tester.pumpAndSettle();
    expect(find.text(networkWarning), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();
    final saved = mcp.m[orgId]!.single;
    expect(saved.network, isTrue);
    expect(saved.url, 'http://192.168.1.20:8080/mcp');
  });

  testWidgets('browser sign-in: adding signs in and keeps the sign-in on this computer', (tester) async {
    final (backend, companion, mcp) = await openSection(tester);
    await addAddress(tester, 'T3 Code', 'http://127.0.0.1:3773/mcp', auth: 'Browser');
    await tester.tap(find.byKey(const Key('saveLocalMcp')));
    await tester.pumpAndSettle();
    expect(companion.signIns, ['t3_code']);
    final saved = mcp.m[orgId]!.single;
    expect(saved.auth, 'oauth');
    expect(saved.oauth?['access_token'], 'a');
    expect(saved.needsSignIn, isFalse);
    expect(backend.localMcpSyncs.last.single.auth?.value, 'oauth');
    expect(backend.localMcpSyncs.last.single.toJson().toString(), isNot(contains('access_token')));
    expect(find.text('Signed in to T3 Code'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    // Signing in again from the row.
    await tester.tap(find.byKey(const Key('signInLocalMcp-t3_code')));
    await tester.pumpAndSettle();
    expect(companion.signIns, ['t3_code', 't3_code']);
  });

  testWidgets('adds servers found in other apps, asking for values they only refer to', (tester) async {
    final found = [
      ...parseMcpSettings('Claude Code', McpSettingsFormat.mcpServers, r'''
        {"mcpServers": {
          "github": {"command": "npx", "args": ["-y", "@acme/github-mcp"], "env": {"GITHUB_TOKEN": "${GITHUB_TOKEN}"}},
          "linear": {"url": "https://mcp.linear.app/mcp"}
        }}'''),
      ...parseMcpSettings('T3 Code', McpSettingsFormat.t3Runtime, '{"origin": "http://127.0.0.1:3773"}'),
    ];
    expect(found.map((f) => f.name), ['github', 'linear', 'T3 Code']);
    final (_, companion, mcp) = await openSection(tester, found: found);
    await tester.tap(find.byKey(const Key('importLocalMcp')));
    await tester.pumpAndSettle();
    expect(find.textContaining('On the internet'), findsOneWidget);
    // Internet servers aren't picked by default; the others are.
    await tester.enterText(find.byKey(const Key('importLocalMcpValue-0-GITHUB_TOKEN')), 'ghp_x');
    await tester.tap(find.byKey(const Key('importLocalMcpAdd')));
    await tester.pumpAndSettle();
    final saved = mcp.m[orgId]!;
    expect(saved.map((s) => s.key), ['github', 't3_code']);
    expect(saved.first.env, {'GITHUB_TOKEN': 'ghp_x'});
    expect(saved.last.source, 't3code');
    expect(companion.signIns, ['t3_code'], reason: 'T3 Code signs in with the browser');

    // Opening it again shows them as already added.
    await tester.tap(find.byKey(const Key('importLocalMcp')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Already added'), findsNWidgets(2));
  });
}

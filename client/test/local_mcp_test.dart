import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/companion/companion.dart';
import 'package:casama_app/features/companion/companion_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';

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
    await tester.scrollUntilVisible(find.byKey(const Key('codingAgent-codex')), 200);
    expect(find.text('Claude Code'), findsOneWidget);
    await tester.tap(find.byKey(const Key('allowCodingAgents')));
    await tester.pumpAndSettle();
    expect(companion.started?.capabilities, contains('shell'));
  });
}

import 'package:casama/core/providers.dart';
import 'package:casama/features/companion/coding_agents_section.dart';
import 'package:casama/features/companion/companion.dart';
import 'package:casama/features/companion/companion_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'companion_test.dart' show FakeCompanion, MemoryMcp, MemoryTokens;
import 'fake_backend.dart';

/// The companion page, paired, with commands on and Advanced open.
Future<void> openCodingAgents(
  WidgetTester tester,
  FakeBackend backend,
  FakeCompanion companion,
) async {
  await setSize(tester, const Size(700, 2400));
  await tester.pumpWidget(
    ProviderScope(
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
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('pairComputer')));
  await tester.pumpAndSettle();
  await backend.updateLocalDevice('dev1', capabilities: {'shell'});
  await tester.scrollUntilVisible(
    find.byKey(const Key('advanced-companion')),
    200,
  );
  await tester.tap(find.byKey(const Key('advanced-companion')));
  await tester.pumpAndSettle();
}

void main() {
  test('makes keys for own agents', () {
    expect(ownAgentKey('Aider', {}), 'aider');
    expect(ownAgentKey('Aider', {'aider'}), 'aider_2');
    expect(ownAgentKey('3 Bots', {}), 'agent_3_bots');
    expect(isAgentBin('aider'), isTrue);
    expect(isAgentBin('../bin/sh'), isFalse);
  });

  testWidgets(
    'looks for the server\'s agents and needs one Allow for a new one',
    (tester) async {
      final backend = FakeBackend();
      final companion = FakeCompanion()..codingAgents = ['claude', 'kimi'];
      await openCodingAgents(tester, backend, companion);
      // The scan looked for every command the server listed.
      expect(companion.lookedFor.last, containsAll(['claude', 'kimi', 't3']));
      await tester.scrollUntilVisible(
        find.byKey(const Key('codingAgent-kimi')),
        200,
      );
      expect(find.text('Kimi Code'), findsOneWidget);
      // Claude Code runs whenever commands are on; Kimi Code needs one Allow here.
      expect(find.byKey(const Key('allowAgent-claude_code')), findsNothing);
      final starts = companion.started;
      await tester.tap(find.byKey(const Key('allowAgent-kimi')));
      await tester.pumpAndSettle();
      expect(backend.deviceUpdates.last, 'agents:kimi');
      expect(find.byKey(const Key('allowAgent-kimi')), findsNothing);
      expect(find.text('Allowed'), findsOneWidget);
      // Allowing doesn't restart the companion (and what bots run on it).
      expect(identical(companion.started, starts), isTrue);
    },
  );

  testWidgets('an older server: the agents this app knows, no own agents', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..codingCatalog = null
      ..ownAgents = null;
    final companion = FakeCompanion()..codingAgents = ['codex', 'kimi'];
    await openCodingAgents(tester, backend, companion);
    await tester.scrollUntilVisible(
      find.byKey(const Key('codingAgent-codex')),
      200,
    );
    expect(find.byKey(const Key('codingAgent-kimi')), findsNothing);
    expect(find.byKey(const Key('addOwnAgent')), findsNothing);
    expect(find.byKey(const Key('allowAgent-codex')), findsNothing);
  });

  testWidgets('shows an agent id this app has never heard of', (tester) async {
    final backend = FakeBackend()
      ..codingCatalog = [
        CodingAgentInfo(
          id: 'zed_agent',
          label: 'Zed Agent',
          bin: 'zed-agent',
          where: const ['my_computer', 'somewhere_new'],
          needsFolder: false,
          hint: null,
          preallowed: false,
        ),
        CodingAgentInfo(
          id: 'bad',
          label: 'Bad',
          bin: '../sh',
          where: const ['my_computer'],
          needsFolder: false,
          hint: null,
          preallowed: false,
        ),
      ];
    final companion = FakeCompanion()..codingAgents = ['zed-agent', '../sh'];
    await openCodingAgents(tester, backend, companion);
    await tester.scrollUntilVisible(
      find.byKey(const Key('codingAgent-zed-agent')),
      200,
    );
    expect(find.text('Zed Agent'), findsOneWidget);
    // Never a path.
    expect(companion.lookedFor.last, isNot(contains('../sh')));
    expect(find.byKey(const Key('allowAgent-zed_agent')), findsOneWidget);
  });

  testWidgets('adds your own agent, tests it and shows it as yours', (
    tester,
  ) async {
    final backend = FakeBackend();
    final companion = FakeCompanion()..codingAgents = ['aider'];
    await openCodingAgents(tester, backend, companion);
    await tester.scrollUntilVisible(find.byKey(const Key('addOwnAgent')), 200);
    await tester.tap(find.byKey(const Key('addOwnAgent')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ownAgentLabel')), 'Aider');
    await tester.enterText(find.byKey(const Key('ownAgentBin')), 'aider');
    await tester.enterText(
      find.byKey(const Key('ownAgentCommand')),
      'aider --message {task} --yes',
    );
    await tester.ensureVisible(find.byKey(const Key('testOwnAgent')));
    await tester.tap(find.byKey(const Key('testOwnAgent')));
    await tester.pumpAndSettle();
    expect(backend.agentTests.single.command, 'aider --message {task} --yes');
    expect(backend.agentTests.single.result, 'tail');
    expect(find.text('It answered: pong'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('saveOwnAgent')));
    await tester.tap(find.byKey(const Key('saveOwnAgent')));
    await tester.pumpAndSettle();
    expect(backend.ownAgents!.single.toJson(), containsPair('id', 'own_aider'));
    expect(backend.ownAgents!.single.timeoutMin, 30);
    await tester.scrollUntilVisible(
      find.byKey(const Key('ownAgent-aider')),
      200,
    );
    expect(find.text('Yours'), findsOneWidget);
    expect(find.text('aider --message {task} --yes'), findsOneWidget);
    // Removing it.
    await tester.tap(find.byKey(const Key('deleteOwnAgent-aider')));
    await tester.pumpAndSettle();
    expect(backend.ownAgents, isEmpty);
  });

  testWidgets('a failed test says so and shows the output', (tester) async {
    final backend = FakeBackend()
      ..agentTestResult = CodingAgentTestResult(
        ok: false,
        exitCode: 127,
        timedOut: false,
        reply: '',
        output: 'sh: aider: command not found',
        command: 'aider',
      );
    final companion = FakeCompanion();
    await openCodingAgents(tester, backend, companion);
    await tester.scrollUntilVisible(find.byKey(const Key('addOwnAgent')), 200);
    await tester.tap(find.byKey(const Key('addOwnAgent')));
    await tester.pumpAndSettle();
    // Not enough to test yet.
    await tester.ensureVisible(find.byKey(const Key('testOwnAgent')));
    await tester.tap(find.byKey(const Key('testOwnAgent')));
    await tester.pumpAndSettle();
    expect(backend.agentTests, isEmpty);
    expect(find.textContaining('a command with {task}'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('ownAgentLabel')), 'Aider');
    await tester.enterText(find.byKey(const Key('ownAgentBin')), 'aider');
    await tester.enterText(
      find.byKey(const Key('ownAgentCommand')),
      'aider --message {task}',
    );
    await tester.ensureVisible(find.byKey(const Key('testOwnAgent')));
    await tester.tap(find.byKey(const Key('testOwnAgent')));
    await tester.pumpAndSettle();
    expect(
      find.text("It didn't answer as expected (exit 127)."),
      findsOneWidget,
    );
    expect(find.text('sh: aider: command not found'), findsOneWidget);
  });
}

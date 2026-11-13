import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets(
    'voice settings start from the bot\'s settings, and connected-app tools can be added to calls',
    (tester) async {
      await setSize(tester, const Size(700, 1400));
      final backend = FakeBackend()
        ..botVoice = {'tts_provider': 'openai', 'realtime_voice': 'Puck'}
        ..integrationList.add(
          Integration(
            id: 'gh',
            orgId: orgId,
            kind: IntegrationKind.mcp,
            name: 'github',
            status: IntegrationStatusEnum.ok,
            error: null,
            tools: [
              IntegrationToolsInner(
                name: 'create_issue',
                description: 'Open an issue',
              ),
              IntegrationToolsInner(
                name: 'delete_repo',
                description: 'Delete a repository',
              ),
            ],
            toolsCachedAt: null,
            createdAt: DateTime(2026),
          ),
        )
        ..attached.add('gh');
      await tester.pumpWidget(
        harness(
          backend,
          const Scaffold(body: VoiceSettingsDialog(botId: botId)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Only the built-in voice tools'), findsOneWidget);

      await tester.tap(find.byKey(const Key('callToolsRow')));
      await tester.pumpAndSettle();
      expect(find.text('github'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('callTool-mcp.github.create_issue')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saveCallTools')));
      await tester.pumpAndSettle();
      expect(backend.botVoice?['call_tools'], ['mcp.github.create_issue']);
      expect(find.text('1 connected-app tool added'), findsOneWidget);

      // Saving the sheet keeps the other voice settings, including ones it doesn't show, and
      // clears a read-aloud service picked before there was only Gemini (D-260).
      await tester.tap(find.byKey(const Key('saveVoice')));
      await tester.pumpAndSettle();
      expect(backend.botVoice, {
        'realtime_voice': 'Puck',
        'call_tools': ['mcp.github.create_issue'],
      });
    },
  );

  testWidgets('there is no voice service to pick; a server that provides voice says so', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend()..serverVoice = {'live', 'read_aloud'};
    await tester.pumpWidget(harness(backend, const Scaffold(body: VoiceSettingsDialog(botId: botId))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ttsProvider')), findsNothing);
    expect(find.byKey(const Key('sttProvider')), findsNothing);
    expect(find.textContaining('This server provides voice'), findsOneWidget);

    final none = FakeBackend();
    await tester.pumpWidget(harness(none, const Scaffold(body: VoiceSettingsDialog(botId: botId))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ttsProvider')), findsNothing);
    expect(find.textContaining('This server provides voice'), findsNothing);
  });
}

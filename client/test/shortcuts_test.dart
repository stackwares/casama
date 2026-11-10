import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/shortcuts.dart';
import 'package:kasama_app/features/quick_ask/quick_ask_screen.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test('shortcut paths and the list App Intents read', () {
    expect(askPath(botId: 'b1', text: 'hi there'), '/quick-ask?text=hi+there&bot=b1');
    expect(routinePath('r1', 'b1'), '/run-routine/r1:b1');
    final f = FakeBackend();
    final json = jsonDecode(shortcutsJson([f.bot()], {
      botId: [
        Routine(
          id: 'r1',
          botId: botId,
          name: 'Morning',
          instructionsMd: 'x',
          scheduleCron: '0 8 * * *',
          timezone: 'UTC',
          trigger: RoutineTrigger.schedule,
          notify: true,
          enabled: true,
          nextRunAt: null,
          lastRunAt: null,
          conversationId: null,
          createdAt: DateTime(2026),
        ),
      ],
    })) as Map;
    expect(json['bots'], [{'id': botId, 'name': 'Ada'}]);
    expect(json['routines'], [{'id': 'r1:$botId', 'name': 'Morning', 'detail': 'Ada'}]);
  });

  testWidgets('"Ask a bot" opens quick ask with that bot and the question', (tester) async {
    await setSize(tester, const Size(600, 900));
    await tester.pumpWidget(harness(FakeBackend(), const QuickAskScreen(initialText: 'What is new?', initialBotId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('What is new?'), findsOneWidget);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama/features/bots/plugins_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('add a plugin after seeing what it adds, update it from a diff, and uninstall it', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const PluginsScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('No plugins yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addPlugin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pluginUrl')), 'https://github.com/acme/agent-plugins/tree/main/plugins/weather');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pluginSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('plan-trip'), findsOneWidget);
    expect(find.textContaining("Runs on the bot's computer: ./bin/forecast"), findsOneWidget);
    // No computer of mine can take its tools, so there's nothing to choose.
    expect(find.byKey(const Key('pluginPlace-bot')), findsNothing);
    // Needs its secret before installing.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('pluginSubmit'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('pluginSecret-WEATHER_KEY')), 'wk-1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pluginSubmit')));
    await tester.pumpAndSettle();
    expect(backend.pluginActions.last, 'install:${'1' * 40}:wk-1');
    expect(find.text('weather 1.0.0'), findsOneWidget);
    expect(find.textContaining('forecast (Low risk)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pluginMenu-plugin-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for Update'));
    await tester.pumpAndSettle();
    expect(find.text('Changed skills: plan-trip'), findsOneWidget);
    expect(find.text('New tool servers: tides'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pluginUpdate')));
    await tester.pumpAndSettle();
    expect(backend.pluginActions.last, 'update:${'2' * 40}');
    expect(find.text('weather 2.0.0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pluginMenu-plugin-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uninstall'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmUninstall')));
    await tester.pumpAndSettle();
    expect(backend.pluginActions.last, 'uninstall:plugin-1');
    expect(find.text('No plugins yet'), findsOneWidget);
  });

  testWidgets('a plugin a bot suggested opens straight into its preview', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(
      backend,
      const PluginsScreen(botId: botId, install: 'https://github.com/acme/agent-plugins/tree/main/plugins/weather'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('plan-trip'), findsOneWidget);
    expect(backend.pluginActions, ['preview:https://github.com/acme/agent-plugins/tree/main/plugins/weather']);
  });

  testWidgets('a plugin\'s tools can run on my own computer, and the card says where', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..device = LocalDevice(
        id: 'dev1',
        orgId: orgId,
        userId: 'me',
        computerId: 'local-computer',
        name: 'Studio Mac',
        platform: LocalDevicePlatformEnum.macos,
        capabilities: LocalCapabilities(mcp: true),
        allowedRoots: const [],
        allowedBotIds: const [],
        enabled: true,
        online: true,
        lastSeenAt: null,
        createdAt: DateTime(2026),
      );
    await tester.pumpWidget(harness(backend, const PluginsScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addPlugin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pluginUrl')), 'https://github.com/acme/agent-plugins/tree/main/plugins/weather');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pluginSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Where its tools run'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('pluginPlace-bot'))).selected, isTrue);
    await tester.tap(find.byKey(const Key('pluginPlace-dev1')));
    await tester.pumpAndSettle();
    expect(find.text('My computer: Studio Mac'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pluginSecret-WEATHER_KEY')), 'wk-1');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pluginSubmit')));
    await tester.pumpAndSettle();
    expect(backend.pluginActions.last, 'install:${'1' * 40}:wk-1:on:dev1');
    expect(find.text('Runs on Studio Mac'), findsOneWidget);
    expect(find.text('Its tools work only in chats with the person whose computer it is'), findsOneWidget);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/plugins_screen.dart';

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
}

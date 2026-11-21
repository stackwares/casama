// An Allow card answered Not Now stays folded when the run's events bring it back after a relaunch.
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama_sdk/casama_sdk.dart' show DeviceKind;
import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const entry = DeviceAccessEntry(
    kind: DeviceKind.calendar,
    reason: "To read today's events",
    botId: botId,
    runId: 'run-1',
  );

  Widget card() => Scaffold(
    body: DeviceAccessPrompt(key: UniqueKey(), entry: entry, botName: 'Milo'),
  );

  testWidgets('Not Now is remembered for that run and kind', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, card()));
    await tester.pumpAndSettle();
    expect(find.text('Milo would like to use your calendar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('deviceAccessSkip')));
    await tester.pumpAndSettle();
    expect(find.text('Not shared: your calendar'), findsOneWidget);

    // A new card for the same run, as after a relaunch: folded, not asking again.
    await tester.pumpWidget(harness(backend, card()));
    await tester.pumpAndSettle();
    expect(find.text('Not shared: your calendar'), findsOneWidget);
    expect(find.byKey(const Key('deviceAccessAllow')), findsNothing);
  });
}

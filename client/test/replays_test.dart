import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/bots/replays_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('replays list with their record, run with parameters, delete', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ReplaysScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 steps · run 3 times, 1 needed help'), findsOneWidget);
    await tester.tap(find.text('file-expense'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('replayParam-amount'))).controller!.text, '42.50');
    await tester.enterText(find.byKey(const Key('replayParam-amount')), '99');
    await tester.tap(find.byKey(const Key('runReplay')));
    await tester.pumpAndSettle();
    expect(backend.replayActions, ['run:rp-1:99']);
    await tester.tap(find.byKey(const Key('deleteReplay-rp-1')));
    await tester.pumpAndSettle();
    expect(find.text('No replays yet'), findsOneWidget);
  });
}

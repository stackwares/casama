import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/watchers_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the bot screen lists watchers with pause and delete', (tester) async {
    await setSize(tester, const Size(900, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const WatchersScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Price drop'), findsOneWidget);
    expect(find.textContaining('fired 2 times'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle-w1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-w1')));
    await tester.pumpAndSettle();
    expect(backend.watcherActions, ['pause:w1', 'delete:w1']);
  });
}

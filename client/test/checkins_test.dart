import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/inbox/inbox_screen.dart';
import 'package:casama/features/bots/bot_profile_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('For you shows the brief and suggestions; accepting hands it to the bot', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Today: 10:00 Standup.'), findsOneWidget);
    expect(find.text('Reply to Ana'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accept-s1')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['accept:s1']);
  });

  testWidgets('dismissing can ask the bot not to suggest it again', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismiss-s1')));
    await tester.pumpAndSettle();
    // The sheet shows what is being dismissed and what each choice does.
    expect(find.descendant(of: find.byKey(const Key('dismissPreview')), matching: find.text('Reply to Ana')), findsOneWidget);
    expect(find.textContaining('will remember'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dismissNever')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['never:s1']);
    expect(find.textContaining("won't suggest that again"), findsOneWidget);
  });

  testWidgets('dismissing just this once, or cancelling, from the sheet', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismiss-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismissCancel')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, isEmpty);
    await tester.tap(find.byKey(const Key('dismiss-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismissOnce')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['dismiss:s1']);
    expect(find.textContaining("won't suggest that again"), findsNothing);
  });

  testWidgets('check-ins turn on from bot settings', (tester) async {
    await setSize(tester, const Size(1000, 3200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BotProfileScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('botCheckins')));
    await tester.tap(find.byKey(const Key('botCheckins')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkinsEnabled')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveCheckins')));
    await tester.pumpAndSettle();
    expect(backend.checkins.enabled, isTrue);
  });
}

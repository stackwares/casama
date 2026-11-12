// Tapping the tab you're already on scrolls its list back to the top, as on iOS and Android.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/ui/floating_tab_chrome.dart';
import 'package:casama_app/ui/tab_reselect.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Widget _longTab({bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: PrimaryScrollController(
        controller: TabReselect.inbox,
        child: Scaffold(
          body: ListView(children: [for (var i = 0; i < 100; i++) SizedBox(height: 80, child: Text('row $i'))]),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('the tab list animates back to the top', (tester) async {
    await tester.pumpWidget(_longTab());
    TabReselect.inbox.jumpTo(2000);
    await tester.pump();
    TabReselect.scrollToTop(tester.element(find.byType(ListView)), 1);
    await tester.pump();
    expect(TabReselect.inbox.offset, greaterThan(0), reason: 'it animates rather than jumps');
    await tester.pumpAndSettle();
    expect(TabReselect.inbox.offset, 0);
  });

  testWidgets('with reduced motion it jumps straight to the top', (tester) async {
    await tester.pumpWidget(_longTab(reduceMotion: true));
    TabReselect.inbox.jumpTo(2000);
    await tester.pump();
    TabReselect.scrollToTop(tester.element(find.byType(ListView)), 1);
    expect(TabReselect.inbox.offset, 0);
  });

  testWidgets('tapping the current tab stays on it; the tab pages use the tab controllers', (tester) async {
    await setSize(tester, const Size(400, 860));
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
    await tester.pumpAndSettle();
    expect(TabReselect.chats.hasClients, isTrue, reason: 'the Chats list picks up the tab controller');

    final bar = find.byType(FloatingTabChrome);
    await tester.tap(find.descendant(of: bar, matching: find.text('Chats')));
    await tester.pumpAndSettle();
    expect(GoRouter.of(tester.element(bar)).state.uri.path, '/bots');
    expect(tester.takeException(), isNull);

    await tester.tap(find.descendant(of: bar, matching: find.text('Inbox')));
    await tester.pumpAndSettle();
    expect(TabReselect.inbox.hasClients, isTrue, reason: 'the Inbox list picks up the tab controller');

    await tester.tap(find.descendant(of: bar, matching: find.text('Tasks')));
    await tester.pumpAndSettle();
    expect(TabReselect.tasks.hasClients, isTrue, reason: 'the Tasks list picks up the tab controller');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}

// The ends of lists and sheets clear the system navigation bar instead of being cut off above it
// (BottomPadding at the end of the scrollable, not a SafeArea around it).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/widgets.dart';
import 'package:casama_app/ui/adaptive_modal.dart';
import 'package:casama_app/ui/bottom_padding.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('BottomPadding is the bar height, or the minimum where there is no bar', (tester) async {
    late double withBar, bigMinimum, withoutBar;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
        child: Builder(
          builder: (context) {
            withBar = BottomPadding.of(context);
            bigMinimum = BottomPadding.of(context, minimum: 40);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            withoutBar = BottomPadding.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(withBar, 34);
    expect(bigMinimum, 40);
    expect(withoutBar, 16);
  });

  Future<void> openListSheet(WidgetTester tester, {required bool contentPadsBottom}) async {
    await setSize(tester, const Size(390, 844));
    tester.view.padding = const FakeViewPadding(bottom: 34);
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAdaptiveSheet<void>(
                  context: context,
                  heightFactor: 0.7,
                  contentPadsBottom: contentPadsBottom,
                  builder: (sheet) => ListView(
                    key: const Key('sheetList'),
                    padding: EdgeInsets.only(bottom: BottomPadding.of(sheet)),
                    children: [for (var i = 0; i < 40; i++) SizedBox(height: 56, child: Text('row $i'))],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a list sheet runs to the bottom edge and ends with room for the bar', (tester) async {
    await openListSheet(tester, contentPadsBottom: true);
    expect(tester.getRect(find.byKey(const Key('sheetList'))).bottom, 844);
    final list = tester.widget<ListView>(find.byKey(const Key('sheetList')));
    expect((list.padding! as EdgeInsets).bottom, 34);
  });

  testWidgets('sheets that end in buttons keep the bar out with a SafeArea', (tester) async {
    await openListSheet(tester, contentPadsBottom: false);
    expect(tester.getRect(find.byKey(const Key('sheetList'))).bottom, 844 - 34);
  });

  testWidgets('an empty state keeps its content clear of the bar', (tester) async {
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(bottom: 120)),
            child: const Scaffold(
              body: EmptyState(icon: Icons.inbox, message: 'Nothing here'),
            ),
          ),
        ),
      ),
    );
    expect(find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.fromLTRB(32, 24, 32, 120)), findsOneWidget);
  });
}

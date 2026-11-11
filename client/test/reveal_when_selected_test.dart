// A tapped tab in a horizontal row scrolls fully into view, and only the row scrolls.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/ui/reveal_when_selected.dart';

class _Row extends StatefulWidget {
  const _Row({this.initial = 0});
  final int initial;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late int _selected = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    height: 40,
    child: ListView(
      key: const Key('row'),
      scrollDirection: Axis.horizontal,
      children: [
        for (var i = 0; i < 10; i++)
          RevealWhenSelected(
            selected: i == _selected,
            child: GestureDetector(key: Key('tab-$i'), behavior: HitTestBehavior.opaque, onTap: () => setState(() => _selected = i), child: const SizedBox(width: 100, height: 40)),
          ),
      ],
    ),
  );
}

// The row sits inside a vertical page, so a reveal that also scrolled the page would show.
Widget _page(Widget row) => MaterialApp(
  home: Scaffold(
    body: ListView(
      children: [
        const SizedBox(height: 300),
        Align(alignment: Alignment.topLeft, child: row),
        const SizedBox(height: 2000),
      ],
    ),
  ),
);

void expectFullyInRow(WidgetTester tester, String tab) {
  final row = tester.getRect(find.byKey(const Key('row')));
  final rect = tester.getRect(find.byKey(Key(tab)));
  expect(rect.left, greaterThanOrEqualTo(row.left));
  expect(rect.right, lessThanOrEqualTo(row.right));
}

void main() {
  testWidgets('tapping a half-visible tab scrolls it fully into view, centered', (tester) async {
    await tester.pumpWidget(_page(const _Row()));
    // Tab 2 spans 200 to 300 in a 250-wide row: only its first half shows.
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('tab-2'))) + const Offset(10, 10));
    await tester.pumpAndSettle();
    expectFullyInRow(tester, 'tab-2');
    expect(tester.getCenter(find.byKey(const Key('tab-2'))).dx, moreOrLessEquals(tester.getCenter(find.byKey(const Key('row'))).dx));
  });

  testWidgets('only the row scrolls, not the page around it', (tester) async {
    await tester.pumpWidget(_page(const _Row()));
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('tab-2'))) + const Offset(10, 10));
    await tester.pumpAndSettle();
    final page = tester.state<ScrollableState>(find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down));
    expect(page.position.pixels, 0);
  });

  testWidgets('a tab already selected when the row appears is brought into view', (tester) async {
    await tester.pumpWidget(_page(const _Row(initial: 3)));
    await tester.pumpAndSettle();
    expectFullyInRow(tester, 'tab-3');
  });
}

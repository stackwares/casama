// Horizontal lists fade an edge only while there is more to scroll that way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/ui/edge_fade.dart';

Widget _row({int count = 12, TextDirection direction = TextDirection.ltr}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Center(
      child: SizedBox(
        width: 300,
        height: 40,
        child: EdgeFade(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (var i = 0; i < count; i++) SizedBox(key: Key('item-$i'), width: 100)],
          ),
        ),
      ),
    ),
  ),
);

EdgeFadeState _fade(WidgetTester tester) => tester.state<EdgeFadeState>(find.byType(EdgeFade));

void main() {
  testWidgets('at the start only the end fades; at the end only the start fades', (tester) async {
    await tester.pumpWidget(_row());
    await tester.pump();
    expect(_fade(tester).before, 0);
    expect(_fade(tester).after, 1);

    await tester.drag(find.byType(ListView), const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(_fade(tester).before, 1);
    expect(_fade(tester).after, 0);
  });

  testWidgets('a row that fits has no fade', (tester) async {
    await tester.pumpWidget(_row(count: 2));
    await tester.pump();
    expect(_fade(tester).before, 0);
    expect(_fade(tester).after, 0);
  });

  testWidgets('right to left: the row runs leftwards and its far end still fades', (tester) async {
    await tester.pumpWidget(_row(direction: TextDirection.rtl));
    await tester.pump();
    expect(_fade(tester).direction, AxisDirection.left);
    expect(_fade(tester).before, 0);
    expect(_fade(tester).after, 1);
  });
}

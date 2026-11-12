// A sideways list on a page reaches the page's edges while its first item lines up with the page.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/theme/app_tokens.dart';
import 'package:casama_app/ui/page.dart';

import 'app_test.dart' show setSize;

Widget _page() => MaterialApp(
  home: Scaffold(
    body: PageColumn(
      children: [
        const SizedBox(key: Key('section'), height: 20),
        PageBleed(
          child: SizedBox(
            key: const Key('row'),
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              children: [for (var i = 0; i < 10; i++) SizedBox(key: Key('item-$i'), width: 100)],
            ),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('on a phone the list spans the screen and starts in line with the page', (tester) async {
    await setSize(tester, const Size(375, 667));
    await tester.pumpWidget(_page());
    expect(tester.getTopLeft(find.byKey(const Key('section'))).dx, AppSpace.gutter);
    expect(tester.getRect(find.byKey(const Key('row'))).left, 0);
    expect(tester.getRect(find.byKey(const Key('row'))).width, 375);
    expect(tester.getTopLeft(find.byKey(const Key('item-0'))).dx, AppSpace.gutter);
  });

  testWidgets('on a wide window it spans the centered page column, not the whole window', (tester) async {
    await setSize(tester, const Size(1200, 800));
    await tester.pumpWidget(_page());
    const inset = (1200 - kPageMaxWidth) / 2;
    expect(tester.getTopLeft(find.byKey(const Key('section'))).dx, inset + AppSpace.gutter);
    expect(tester.getRect(find.byKey(const Key('row'))).left, inset);
    expect(tester.getRect(find.byKey(const Key('row'))).width, kPageMaxWidth);
    expect(tester.getTopLeft(find.byKey(const Key('item-0'))).dx, inset + AppSpace.gutter);
  });
}

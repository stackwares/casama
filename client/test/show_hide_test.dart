// ShowHide: things that come and go after a load slide open and closed instead of jumping, and
// what's there on the first build just shows.
import 'package:casama/ui/motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget? child, {bool still = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Scaffold(
      body: Column(
        children: [
          ShowHide(child: child),
          const Text('below', key: Key('below')),
        ],
      ),
    ),
  ),
);

const _banner = SizedBox(height: 100, child: Text('banner'));

void main() {
  testWidgets('there on the first build: shown at once', (tester) async {
    await tester.pumpWidget(_host(_banner));
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 100);
  });

  testWidgets('appearing grows open, so what is below slides down', (
    tester,
  ) async {
    await tester.pumpWidget(_host(null));
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 0);
    await tester.pumpWidget(_host(_banner));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getTopLeft(find.byKey(const Key('below'))).dy;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(100));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 100);
  });

  testWidgets('going away shrinks closed, then leaves nothing behind', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_banner));
    await tester.pumpWidget(_host(null));
    await tester.pump(const Duration(milliseconds: 100));
    // Still on screen while it closes.
    expect(find.text('banner'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('banner'), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 0);
  });

  testWidgets('with reduced motion it just appears and goes', (tester) async {
    await tester.pumpWidget(_host(null, still: true));
    await tester.pumpWidget(_host(_banner, still: true));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key('below'))).dy, 100);
    await tester.pumpWidget(_host(null, still: true));
    await tester.pump();
    expect(find.text('banner'), findsNothing);
  });
}

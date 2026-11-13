// The celebration (a new bot, a new space) plays on a soft wash of the page colour, so the page's
// own mascot behind it fades back, and then removes itself.
import 'package:casama_app/ui/celebration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('plays on a wash of the page colour, then goes away by itself', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    showCelebration(ctx, 'Say hi to Pip');
    await tester.pump(); // the clock starts on the first frame
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Say hi to Pip'), findsOneWidget);
    final wash = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient is RadialGradient,
    );
    expect(wash, findsOneWidget);
    final colors =
        ((tester.widget<DecoratedBox>(wash).decoration as BoxDecoration)
                    .gradient
                as RadialGradient)
            .colors;
    expect(colors.first.a, greaterThan(0.9), reason: 'densest behind the bot');
    expect(colors.last.a, lessThan(colors.first.a));

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Say hi to Pip'), findsNothing);
    expect(wash, findsNothing);
  });
}

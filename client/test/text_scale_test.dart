import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/ui/text_scale.dart';

void main() {
  Future<TextScaler> scalerAt(WidgetTester tester, double systemScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late TextScaler scaler;
    await tester.pumpWidget(
      MaterialApp(
        builder: limitTextScale,
        home: Builder(
          builder: (context) {
            scaler = MediaQuery.textScalerOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return scaler;
  }

  testWidgets('the largest system text sizes are held at the cap', (tester) async {
    expect((await scalerAt(tester, 2.0)).scale(10), closeTo(10 * kMaxTextScale, 0.001));
    expect((await scalerAt(tester, 3.1)).scale(10), closeTo(10 * kMaxTextScale, 0.001));
  });

  testWidgets('sizes up to the cap pass through as they are', (tester) async {
    expect((await scalerAt(tester, 1.15)).scale(10), closeTo(11.5, 0.001));
    expect((await scalerAt(tester, 1.0)).scale(10), closeTo(10, 0.001));
    expect((await scalerAt(tester, 0.85)).scale(10), closeTo(8.5, 0.001));
  });
}

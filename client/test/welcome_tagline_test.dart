import 'package:casama_app/features/auth/welcome_tagline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: WelcomeTagline(
            taglines: [
              'Short.',
              'A much longer tagline that wraps onto more lines.',
            ],
            interval: Duration(seconds: 2),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('cycles the taglines and keeps a steady height', (tester) async {
    await tester.pumpWidget(_app());
    final height = tester.getSize(find.byType(WelcomeTagline)).height;
    expect(
      find.text('Short.'),
      findsNWidgets(2),
    ); // the visible one and its sizing copy

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Short.'), findsOneWidget);
    expect(
      find.text('A much longer tagline that wraps onto more lines.'),
      findsNWidgets(2),
    );
    expect(tester.getSize(find.byType(WelcomeTagline)).height, height);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Short.'), findsNWidgets(2));
  });

  testWidgets('stays on the first tagline with reduced motion', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Short.'), findsNWidgets(2));
    expect(
      find.text('A much longer tagline that wraps onto more lines.'),
      findsOneWidget,
    );
  });
}

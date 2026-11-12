// Vertical lists show a scrollbar on phones too, so people see where they are and how much is left.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/ui/app_scroll_behavior.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('vertical lists get a scrollbar on phones; horizontal rows do not', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 60,
                child: ListView(
                  key: const Key('row'),
                  scrollDirection: Axis.horizontal,
                  children: [for (var i = 0; i < 30; i++) SizedBox(width: 80, child: Text('chip $i'))],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const Key('list'),
                  children: [for (var i = 0; i < 60; i++) SizedBox(height: 56, child: Text('row $i'))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.descendant(of: find.byKey(const Key('list')), matching: find.byType(Scrollbar)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('row')), matching: find.byType(Scrollbar)), findsNothing);

    // Scrolling shows it without errors.
    await tester.drag(find.byKey(const Key('list')), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('the app uses the scrollbar behavior', (tester) async {
    await setSize(tester, const Size(400, 860));
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).scrollBehavior, isA<AppScrollBehavior>());
  });
}

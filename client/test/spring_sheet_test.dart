import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/adaptive_modal.dart';
import 'package:casama_app/ui/spring_sheet.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          key: const Key('openSheet'),
          onPressed: () => showAdaptiveSheet<void>(
            context: context,
            builder: (_) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sheet body', key: Key('sheetBody')),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a phone sheet opens on a spring and closes with a drag down', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('openSheet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheetBody')), findsOneWidget);
    expect(find.byType(SheetContainer), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.drag(find.byKey(const Key('sheetBody')), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheetBody')), findsNothing);
  });

  testWidgets('a small drag springs back, a tap outside closes', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('openSheet')));
    await tester.pumpAndSettle();
    final open = tester.getTopLeft(find.byKey(const Key('sheetBody')));
    await tester.drag(find.byKey(const Key('sheetBody')), const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('sheetBody'))), open);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheetBody')), findsNothing);
  });

  testWidgets('with reduced motion the sheet is in place on the next frame', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.tap(find.byKey(const Key('openSheet')));
    await tester.pump();
    await tester.pump();
    final first = tester.getTopLeft(find.byKey(const Key('sheetBody')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('sheetBody'))), first);
  });
}

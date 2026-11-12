import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/adaptive_modal.dart';

Widget _app() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          key: const Key('openTall'),
          onPressed: () => showAdaptiveSheet<void>(
            context: context,
            heightFactor: 0.8,
            builder: (_) => ListView(
              children: [for (var i = 0; i < 40; i++) ListTile(key: Key('row$i'), title: Text('Row $i'))],
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
  testWidgets('a tall phone sheet closes with its X', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('openTall')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('row0')), findsOneWidget);
    expect(ModalRoute.of(tester.element(find.byKey(const Key('row0')))), isA<StupidSimpleSheetRoute<void>>());
    await tester.tap(find.byKey(const Key('sheetClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('row0')), findsNothing);
  });

  testWidgets('a tall phone sheet closes when pulled down from the top', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('openTall')));
    await tester.pumpAndSettle();
    await tester.timedDrag(find.byKey(const Key('row0')), const Offset(0, 500), const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('row0')), findsNothing);
  });

  testWidgets('on iOS the tall sheet is the glass sheet', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _phone(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('openTall')));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(tester.element(find.byKey(const Key('row0')))), isA<StupidSimpleGlassSheetRoute<void>>());
    await tester.tap(find.byKey(const Key('sheetClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('row0')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

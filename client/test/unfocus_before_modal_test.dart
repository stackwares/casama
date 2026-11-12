import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/adaptive_modal.dart';

Widget _page(FocusNode field) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Column(
        children: [
          TextField(key: const Key('field'), focusNode: field),
          TextButton(
            key: const Key('openSheet'),
            onPressed: () => showAdaptiveSheet<void>(
              context: context,
              builder: (sheet) => TextButton(key: const Key('closeSheet'), onPressed: () => Navigator.pop(sheet), child: const Text('Close')),
            ),
            child: const Text('Open'),
          ),
          PopupMenuButton<String>(
            key: const Key('menu'),
            onOpened: unfocusBeforeModal,
            itemBuilder: (_) => const [PopupMenuItem(value: 'a', child: Text('Pick A'))],
            onSelected: (_) {},
          ),
        ],
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
  testWidgets('closing a sheet does not bring the keyboard back on a phone', (tester) async {
    await _phone(tester);
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(_page(field));
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(field.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('openSheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('closeSheet')));
    await tester.pumpAndSettle();
    expect(field.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('closing a menu does not bring the keyboard back on a phone', (tester) async {
    await _phone(tester);
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(_page(field));
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick A'));
    await tester.pumpAndSettle();
    expect(field.hasFocus, isFalse);
  });

  testWidgets('on desktop a sheet opened from the keyboard gives the field its focus back', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await _phone(tester);
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(_page(field));
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(field.hasFocus, isTrue);
    // Like a keyboard shortcut: no click outside the field first (a click would unfocus it).
    tester.widget<TextButton>(find.byKey(const Key('openSheet'))).onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('closeSheet')));
    await tester.pumpAndSettle();
    expect(field.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });
}

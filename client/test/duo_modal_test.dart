// Sheets and dialogs on an iPhone Duo (D-411): a bottom sheet on the outer screen, a dialog on
// the inner one, never under the side strip, and never on the fold while it divides the window.
import 'package:casama/core/fold/fold.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama/ui/adaptive_modal.dart';
import 'package:casama/ui/spring_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/poses.dart';

final _iphone = TargetPlatformVariant.only(TargetPlatform.iOS);

Future<void> _pump(WidgetTester tester, DuoPose pose) async {
  setPose(tester, pose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FoldScope(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showConfirm(
                  context: context,
                  title: 'Send this email?',
                  message: 'To marta@northwind.co',
                  confirmLabel: 'Allow',
                ),
                child: const Text('ask'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ask'));
  await tester.pumpAndSettle();
}

Future<void> _move(WidgetTester tester, DuoPose pose) async {
  setPose(tester, pose);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('closed: a bottom sheet over the page, not under the strip', (
    tester,
  ) async {
    await _pump(tester, DuoPose.closed);
    expect(find.byType(Dialog), findsNothing);
    final sheet = tester.getRect(find.byType(SheetContainer));
    expect(sheet.left, 0);
    expect(sheet.right, 466 - 84);
    expect(sheet.bottom, 678);
  }, variant: _iphone);

  testWidgets('open wide: a dialog centered in the page', (tester) async {
    await _pump(tester, DuoPose.openWide);
    expect(find.byType(SheetContainer), findsNothing);
    final dialog = tester.getRect(find.byType(Material).hitTestable().last);
    final card = tester.getRect(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    );
    expect(card.center.dx, closeTo((951 - 84) / 2, 1));
    expect(dialog.right, lessThanOrEqualTo(951 - 84));
  }, variant: _iphone);

  testWidgets(
    'book: the dialog opens on the right half, clear of the fold and the strip',
    (tester) async {
      await _pump(tester, DuoPose.book);
      final card = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card.left, greaterThanOrEqualTo(495.5));
      expect(card.right, lessThanOrEqualTo(951 - 84));
    },
    variant: _iphone,
  );

  testWidgets('laptop: a sheet keeps to the lower half', (tester) async {
    await _pump(tester, DuoPose.laptop);
    final sheet = tester.getRect(find.byType(SheetContainer));
    expect(sheet.top, greaterThanOrEqualTo(495.5));
    expect(sheet.bottom, 951);
  }, variant: _iphone);

  testWidgets(
    'a sheet opened on the outer screen stays a sheet, in the right half, when the device opens half way',
    (tester) async {
      await _pump(tester, DuoPose.closed);
      expect(find.byType(SheetContainer), findsOneWidget);
      await _move(tester, DuoPose.book);
      final sheet = tester.getRect(find.byType(SheetContainer));
      expect(sheet.left, greaterThanOrEqualTo(495.5));
      expect(sheet.right, lessThanOrEqualTo(951 - 84));
      // Flat, it is no wider than a sheet should be and keeps off the strip.
      await _move(tester, DuoPose.openWide);
      final flat = tester.getRect(find.byType(SheetContainer));
      expect(flat.width, lessThanOrEqualTo(640));
      expect(flat.right, lessThanOrEqualTo(951 - 84));
    },
    variant: _iphone,
  );

  testWidgets(
    'a dialog opened on the inner screen fits the outer one when the device closes',
    (tester) async {
      await _pump(tester, DuoPose.openWide);
      await _move(tester, DuoPose.closed);
      final card = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(466 - 84));
    },
    variant: _iphone,
  );
}

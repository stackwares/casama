// Pages outside the app shell (sign-in, the welcome steps, the paywall) on a folding phone
// (D-411): clear of the side strip, on the half you touch while the fold divides the window, and
// keeping what was typed when the device is folded around them. Toasts follow the same rule.
import 'package:casama/core/fold/fold.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama/ui/casama_mark.dart';
import 'package:casama/ui/outside_shell.dart';
import 'package:casama/ui/toast.dart';
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
        home: OutsideShell(
          child: Scaffold(
            key: const Key('page'),
            body: Builder(
              builder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 240,
                      child: TextField(key: Key('email')),
                    ),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            toastSnackBar(
                              context,
                              'Check your email',
                              key: const Key('toast'),
                            ),
                          ),
                      child: const Text('send'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Rect _page(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('page')));

void main() {
  testWidgets(
    'the page keeps clear of the strip, and takes the half you touch while the fold divides the window',
    (tester) async {
      await _pump(tester, DuoPose.closed);
      expect(_page(tester), const Rect.fromLTRB(0, 0, 466 - 84, 678));
      expect(find.byType(CasamaMark), findsNothing);
      await tester.enterText(
        find.byKey(const Key('email')),
        'oliver@example.com',
      );

      setPose(tester, DuoPose.openWide);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_page(tester), const Rect.fromLTRB(0, 0, 951 - 84, 669));

      // Held like a book: the page on the right half, Casama's mark on the left.
      setPose(tester, DuoPose.book);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_page(tester), const Rect.fromLTRB(495.5, 0, 951 - 84, 669));
      expect(
        tester.getRect(find.byType(CasamaMark)).right,
        lessThanOrEqualTo(455.5),
      );

      // Propped up: the page on the lower half.
      setPose(tester, DuoPose.laptop);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_page(tester), const Rect.fromLTRB(0, 495.5, 669, 951));
      expect(
        tester.getRect(find.byType(CasamaMark)).bottom,
        lessThanOrEqualTo(455.5),
      );

      // Folding and opening never lost what was typed.
      expect(find.text('oliver@example.com'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
    variant: _iphone,
  );

  testWidgets(
    'a toast shows in the page: not under the strip, not on the fold',
    (tester) async {
      await _pump(tester, DuoPose.closed);
      await tester.tap(find.text('send'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.getRect(find.byKey(const Key('toast'))).right,
        lessThanOrEqualTo(466 - 84),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));

      await _pump(tester, DuoPose.book);
      await tester.tap(find.text('send'));
      await tester.pump(const Duration(milliseconds: 600));
      final toast = tester.getRect(find.byKey(const Key('toast')));
      expect(toast.left, greaterThanOrEqualTo(495.5));
      expect(toast.right, lessThanOrEqualTo(951 - 84));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
    variant: _iphone,
  );
}

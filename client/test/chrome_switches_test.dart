import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Casama for Chrome's workspace switches (D-323 G9).
void main() {
  testWidgets(
    'admins turn off bots in members\' browsers, and the extension with it',
    (tester) async {
      await setSize(tester, const Size(900, 1200));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const Scaffold(body: ChromeSwitches(orgId: orgId))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Casama for Chrome'), findsOneWidget);
      expect(find.text("Bots in Members' Browsers"), findsOneWidget);
      await tester.tap(find.byKey(const Key('chromeActSwitch')));
      await tester.pumpAndSettle();
      expect(backend.chromeActOn, isFalse);
      expect(backend.chromeExtensionOn, isTrue);
      await tester.tap(find.byKey(const Key('chromeActSwitch')));
      await tester.pumpAndSettle();
      expect(backend.chromeActOn, isTrue);
      // Without the extension, Act can't be on either.
      await tester.tap(find.byKey(const Key('chromeExtensionSwitch')));
      await tester.pumpAndSettle();
      expect(backend.chromeExtensionOn, isFalse);
      expect(
        tester.widget<Switch>(find.byKey(const Key('chromeActSwitch'))).value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('chromeActSwitch')))
            .onChanged,
        isNull,
      );
    },
  );
}

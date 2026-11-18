import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets(
    'admins turn on full access after confirming, and off at once (D-394)',
    (tester) async {
      await setSize(tester, const Size(800, 600));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const Scaffold(body: FullAccessSwitch(orgId: orgId))),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(find.byKey(const Key('fullAccess'))).value,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('fullAccess')));
      await tester.pumpAndSettle();
      expect(find.text('Turn on full access?'), findsOneWidget);
      expect(backend.fullAccessOn, isFalse);
      await tester.tap(find.byKey(const Key('confirmFullAccess')));
      await tester.pumpAndSettle();
      expect(backend.fullAccessOn, isTrue);
      expect(
        tester.widget<Switch>(find.byKey(const Key('fullAccess'))).value,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('fullAccess')));
      await tester.pumpAndSettle();
      expect(find.text('Turn on full access?'), findsNothing);
      expect(backend.fullAccessOn, isFalse);
    },
  );
}

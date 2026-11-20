import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Existing console tests still enter through the real authentication screen.
Future<void> unlockAdmin(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  await tester.enterText(
    find.byKey(const Key('adminPassword')),
    'test-password',
  );
  await tester.tap(find.byKey(const Key('adminUnlockPassword')));
  await tester.pumpAndSettle();
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/home/home_shell.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a suspended workspace shows a banner above the screen', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..orgSuspended = true;
    await tester.pumpWidget(harness(backend, const HomeShell(location: '/settings/privacy', child: Text('screen'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suspendedBanner')), findsOneWidget);
    expect(find.text('screen'), findsOneWidget);
  });

  testWidgets('no banner otherwise', (tester) async {
    await setSize(tester, const Size(500, 900));
    await tester.pumpWidget(harness(FakeBackend(), const HomeShell(location: '/settings/privacy', child: Text('screen'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suspendedBanner')), findsNothing);
  });
}

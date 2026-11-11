import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/workspaces/spaces.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _Host extends StatelessWidget {
  const _Host();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: SizedBox(width: 300, child: WorkspaceSwitcher())));
}

void main() {
  testWidgets('the switcher lists workspaces with badges and creates a new one', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const _Host()));
    await tester.pumpAndSettle();
    expect(find.text('Test Org'), findsOneWidget);
    await tester.tap(find.byKey(const Key('workspaceSwitcher')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('space-$orgId')), findsOneWidget);
    expect(find.text('3'), findsOneWidget, reason: '1 approval + 2 unread');

    await tester.tap(find.byKey(const Key('newWorkspace')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('workspaceNameField')), 'Home');
    await tester.tap(find.byKey(const Key('icon-house')));
    await tester.tap(find.byKey(const Key('color-#22aa66')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createWorkspaceSubmit')));
    await tester.pumpAndSettle();
    expect(backend.createdOrgs, 1);
    expect(backend.orgIcon, 'house');
    expect(backend.orgColor, '#22aa66');
  });
}

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
  test('reads tokens from pasted invite links', () {
    expect(inviteTokenFrom('https://app.example.com/join/kjoin_abcdefghijklmnopqrst'), 'kjoin_abcdefghijklmnopqrst');
    expect(inviteTokenFrom('kjoin_abcdefghijklmnopqrst'), 'kjoin_abcdefghijklmnopqrst');
    expect(inviteTokenFrom('hello'), isNull);
  });

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

  testWidgets('joins a workspace from a pasted link', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const _Host()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workspaceSwitcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('joinWorkspace')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('inviteLinkField')), 'https://app.example.com/join/kjoin_abcdefghijklmnopqrst');
    await tester.tap(find.byKey(const Key('joinWorkspaceSubmit')));
    await tester.pumpAndSettle();
    expect(backend.joined, ['kjoin_abcdefghijklmnopqrst']);
    expect(find.text('You joined Friends.'), findsOneWidget);
  });

  testWidgets('workspace settings create, show and revoke invite links', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const WorkspaceSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createInviteLink')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('createdLink')), findsOneWidget);
    expect(backend.links, hasLength(1));
    await tester.tap(find.byKey(const Key('revoke-l1')));
    await tester.pumpAndSettle();
    expect(backend.links, isEmpty);
  });
}

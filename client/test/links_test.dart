import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/bots/links_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Linked agents (D-143).
void main() {
  testWidgets('invite a contact, accept an invite, see exchanges, unlink', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const LinksScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('No linked bots yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inviteLink')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('inviteName')), 'Sam');
    await tester.tap(find.byKey(const Key('inviteName-ok')));
    await tester.pumpAndSettle();
    expect(find.text('kasama-link:abc123'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your contact to accept'), findsOneWidget);

    await tester.tap(find.byKey(const Key('acceptLink')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('acceptInvite')), 'kasama-link:xyz');
    await tester.enterText(find.byKey(const Key('acceptName')), 'Lee');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveAcceptLink')));
    await tester.pumpAndSettle();
    expect(backend.linkActions, ['invite:Sam', 'accept:kasama-link:xyz:Lee']);
    expect(find.text('Linked with Ben'), findsOneWidget);

    await tester.tap(find.text('Lee'));
    await tester.pumpAndSettle();
    expect(find.text('Find a dinner slot for 4 next week'), findsOneWidget);
    expect(find.text('Thursday at 7pm works.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('revokeLink')));
    await tester.pumpAndSettle();
    expect(backend.linkActions.last, 'revoke:lk-2');
    expect(find.text('Unlinked'), findsOneWidget);
  });
}

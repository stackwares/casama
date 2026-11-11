import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/workspaces/join_flow.dart';
import 'package:casama_app/features/workspaces/people_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _NoWelcome extends FakeBackend {
  @override
  Future<WelcomeChat> startWelcome({String? firstName}) => Completer<WelcomeChat>().future;
}

Future<ProviderContainer> _app(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(backend)], child: const CasamaApp()));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return ProviderScope.containerOf(tester.element(find.byType(CasamaApp)));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('reads links, tokens and codes however they are typed', () {
    expect(inviteFrom('https://app.example.com/join/kjoin_abcdefghijklmnopqrst'), 'kjoin_abcdefghijklmnopqrst');
    expect(inviteFrom('kinv_abcdefghijklmnopqrst'), 'kinv_abcdefghijklmnopqrst');
    expect(inviteFrom('7f3q 9xwd'), '7F3Q-9XWD');
    expect(inviteFrom('https://casama.example.com/join/7F3Q-9XWD'), '7F3Q-9XWD');
    expect(inviteFrom('o1li-abcd'), '0111-ABCD');
    expect(inviteFrom('hello'), isNull);
    expect(inviteServerFrom('https://casama.example.com/join/7F3Q-9XWD'), 'https://casama.example.com');
    expect(inviteServerFrom('7F3Q-9XWD'), isNull);
    expect(parseEmails('a@x.com, B@x.com\nb@x.com; nope'), ['a@x.com', 'b@x.com']);
  });

  testWidgets('a link shows the workspace first, then joins and welcomes', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/join/kjoin_abcdefghijklmnopqrst');
    await _settle(tester);
    expect(find.byKey(const Key('joinPreview')), findsOneWidget);
    expect(find.text('Sam invited you to join'), findsOneWidget);
    expect(find.text('4 members · You\'ll join as a member'), findsOneWidget);
    expect(backend.joined, isEmpty, reason: 'nothing happens before the person says so');
    await tester.tap(find.byKey(const Key('joinConfirm')));
    await _settle(tester);
    expect(backend.joined, ['kjoin_abcdefghijklmnopqrst']);
    expect(find.byKey(const Key('joinedWelcome')), findsOneWidget);
    expect(find.text('Welcome to Friends'), findsOneWidget);
  });

  testWidgets('signed out, the preview asks to sign in and keeps the invite', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()..signedIn = false;
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/join/7F3Q-9XWD');
    await _settle(tester);
    expect(find.text('Sign in to join'), findsOneWidget);
    await tester.tap(find.byKey(const Key('joinConfirm')));
    await _settle(tester);
    expect(c.read(pendingJoinTokenProvider), '7F3Q-9XWD');
    expect(c.read(routerProvider).state.matchedLocation, '/sign-in');
  });

  testWidgets('a link that asks first sends a request', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/join/kjoin_gateabcdefghijklmnop');
    await _settle(tester);
    expect(find.text('An admin approves new people before they join.'), findsOneWidget);
    expect(find.text('Ask to join'), findsOneWidget);
    await tester.tap(find.byKey(const Key('joinConfirm')));
    await _settle(tester);
    expect(find.byKey(const Key('joinRequested')), findsOneWidget);
  });

  testWidgets('a broken invite says so', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend());
    c.read(routerProvider).go('/join/kjoin_badbadbadbadbadbadbad');
    await _settle(tester);
    expect(find.byKey(const Key('joinInvalid')), findsOneWidget);
  });

  testWidgets('the join sheet takes a typed code and opens its preview', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend());
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const JoinSpaceSheet()));
    await _settle(tester);
    final submit = find.byKey(const Key('joinWorkspaceSubmit'));
    await tester.enterText(find.byKey(const Key('inviteLinkField')), 'not an invite');
    await tester.pump();
    await tester.tap(submit, warnIfMissed: false);
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.path, isNot(startsWith('/join/')), reason: 'nothing to open yet');
    await tester.enterText(find.byKey(const Key('inviteLinkField')), '7f3q 9xwd');
    await tester.pump();
    await tester.tap(submit);
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.path, '/join/7F3Q-9XWD');
    expect(find.byKey(const Key('joinPreview')), findsOneWidget);
  });

  testWidgets('new people whose team is here can join it instead of starting fresh', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = _NoWelcome()
      ..hasOrg = false
      ..joinableList = [JoinableWorkspace(id: 'w1', name: 'Acme HQ', icon: null, color: null, memberCount: 12, domain: 'acme.dev')];
    final c = await _app(tester, backend);
    await _settle(tester);
    expect(find.byKey(const Key('joinTeam')), findsOneWidget);
    expect(find.text('Acme HQ'), findsOneWidget);
    await tester.tap(find.byKey(const Key('joinDomain-w1')));
    await _settle(tester);
    expect(backend.domainJoins, ['w1']);
    expect(c.read(routerProvider).state.uri.path, startsWith('/joined/'));
  });

  testWidgets('starting your own workspace skips the team screen', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = _NoWelcome()
      ..hasOrg = false
      ..joinableList = [JoinableWorkspace(id: 'w1', name: 'Acme HQ', icon: null, color: null, memberCount: 12, domain: 'acme.dev')];
    final c = await _app(tester, backend);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('startOwnWorkspace')));
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.path, '/welcome');
  });

  testWidgets('People: copy the standing link, ask first, get a code, reset', (tester) async {
    await setSize(tester, const Size(900, 2400));
    final backend = FakeBackend();
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await tester.pumpWidget(harness(backend, const PeopleScreen()));
    await tester.pumpAndSettle();
    expect(find.text('https://app.example.com/join/kjoin_default0abcdefghijk'), findsOneWidget);
    await tester.tap(find.byKey(const Key('copyInvite')));
    await tester.pump();
    expect(clipboard, 'https://app.example.com/join/kjoin_default0abcdefghijk');
    expect(find.byKey(const Key('shareInvite')), findsOneWidget);

    await tester.tap(find.byKey(const Key('qrInvite')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inviteQr')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inviteApproval')));
    await tester.pumpAndSettle();
    expect(backend.defaultApproval, isTrue);
    expect(find.text('Anyone with this link can ask to join. You approve them below.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('makeInviteCode')));
    await tester.pumpAndSettle();
    expect(find.text('7F3Q-9XWD'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resetInvite')));
    await tester.pumpAndSettle();
    expect(backend.defaultResets, 0, reason: 'resetting asks first');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset link').last);
    await tester.pumpAndSettle();
    expect(backend.defaultResets, 1);
    expect(find.text('https://app.example.com/join/kjoin_default1abcdefghijk'), findsOneWidget);
  });

  testWidgets('People: email invites, requests, pending invites, domain', (tester) async {
    await setSize(tester, const Size(900, 2600));
    final backend = FakeBackend()
      ..joinRequestList.add(JoinRequest.fromJson({
        'id': 'r1',
        'org_id': orgId,
        'user_id': 'u9',
        'email': 'pat@acme.dev',
        'display_name': 'Pat',
        'role': 'member',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }))
      ..pendingInviteList.add(PendingInvite.fromJson({
        'id': 'i1',
        'email': 'lee@acme.dev',
        'role': 'member',
        'expires_at': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }));
    await tester.pumpWidget(harness(backend, const PeopleScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('inviteEmails')), 'ana@acme.dev, ben@acme.dev');
    await tester.pump();
    expect(find.text('Send 2 invites'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sendInvites')));
    await tester.pumpAndSettle();
    expect(backend.invitedEmails, ['ana@acme.dev', 'ben@acme.dev']);

    expect(find.text('Pat'), findsOneWidget);
    await tester.tap(find.byKey(const Key('approve-r1')));
    await tester.pumpAndSettle();
    expect(backend.decided, contains('r1:approve'));
    expect(find.byKey(const Key('request-r1')), findsNothing);

    await tester.tap(find.byKey(const Key('pendingMenu-i1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel invite'));
    await tester.pumpAndSettle();
    expect(backend.revokedInvites, ['i1']);

    await tester.ensureVisible(find.byKey(const Key('joinDomain')));
    expect(find.text('Anyone with a verified @acme.dev email can join'), findsOneWidget);
    await tester.tap(find.byKey(const Key('joinDomain')));
    await tester.pumpAndSettle();
    expect(backend.joinDomainList, ['acme.dev']);
  });
}

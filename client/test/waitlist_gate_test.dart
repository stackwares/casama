import 'dart:convert';

import 'package:casama/core/backend.dart';
import 'package:casama/core/id_token_email.dart';
import 'package:casama/features/admin/admin_screen.dart';
import 'package:casama/features/auth/invite_gate.dart';
import 'package:casama/features/auth/sign_in_screen.dart';
import 'package:casama/features/referrals/invite_friends.dart';
import 'package:casama_sdk/casama_sdk.dart'
    show
        InviteCodePreview,
        InviteCodePreviewKindEnum,
        PublicConfigSignupGate,
        Referral,
        ReferralInvites,
        SignupGateModeEnum;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'admin_test_helpers.dart';

/// Casama Cloud's waitlist and invite gate in the app (D-427, WAITLIST-PLAN Phase 2).

const _refusal =
    'Casama Cloud is invite-only for now. Join the waitlist or enter an invite code at casama.ai/waitlist.';

/// A server whose Auth refuses new accounts, as the gate's hook does.
class _RefusingBackend extends FakeBackend {
  @override
  Future<void> sendMagicLink(String email) async =>
      throw const sb.AuthException(_refusal, statusCode: '403');
}

/// An Apple sign-in refused by the gate, as the backend passes it on: with the token's address.
class _RefusingAppleBackend extends FakeBackend {
  _RefusingAppleBackend(this.email);
  final String email;
  @override
  Future<void> signInWithProvider(String provider) async =>
      throw IdTokenAuthException(_refusal, statusCode: '403', email: email);
}

/// An ID token whose payload is [claims] (unsigned: only the payload is read).
String _idToken(Map<String, Object?> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(claims)}.sig';
}

FakeBackend _gated([FakeBackend? backend]) => (backend ?? FakeBackend())
  ..signedIn = false
  ..signUpsByInvitation = true
  ..signupGate = PublicConfigSignupGate(
    mode: 'invite_only',
    waitlistUrl: 'https://casama.ai/waitlist',
  );

Future<void> _openSignIn(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(harness(backend, const SignInScreen()));
  // The bots float for as long as the screen shows, so it never settles: pump a few frames.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sign-in screen', () {
    testWidgets(
      'shows the invite-only line and both buttons while the gate is on',
      (tester) async {
        await setSize(tester, const Size(500, 1100));
        await _openSignIn(tester, _gated());
        expect(
          find.text('Casama Cloud is invite-only for now.'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('joinWaitlist')), findsOneWidget);
        expect(find.byKey(const Key('haveInvite')), findsOneWidget);

        // The sign-in sheet carries it in place of build 44's "by invitation" line.
        await tester.tap(find.byKey(const Key('openSignIn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('signUpsByInvitation')), findsNothing);
        expect(find.byKey(const Key('inviteGate')), findsNWidgets(2));
        // Existing accounts still have every way in.
        expect(find.byKey(const Key('appleSignIn')), findsOneWidget);
        expect(find.byKey(const Key('continueWithEmail')), findsOneWidget);
      },
    );

    testWidgets('a server without the gate shows none of it', (tester) async {
      await setSize(tester, const Size(500, 1100));
      // A self-hosted server that only takes invited emails (D-145): the old line, no waitlist.
      final backend = FakeBackend()
        ..signedIn = false
        ..signUpsByInvitation = true;
      await _openSignIn(tester, backend);
      expect(find.byKey(const Key('inviteGate')), findsNothing);
      expect(find.text('Casama Cloud is invite-only for now.'), findsNothing);
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('signUpsByInvitation')), findsOneWidget);
      expect(find.byKey(const Key('joinWaitlist')), findsNothing);
    });

    testWidgets('a refused sign-up opens the sheet instead of a toast', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      await _openSignIn(tester, _gated(_RefusingBackend()));
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueWithEmail')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), 'new@example.com');
      await tester.tap(find.byKey(const Key('sendMagicLink')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteRefusal')), findsOneWidget);
      expect(find.byKey(const Key('refusalJoinWaitlist')), findsOneWidget);
      expect(find.byKey(const Key('refusalHaveInvite')), findsOneWidget);
      // No toast with the raw sentence.
      expect(find.text(_refusal), findsNothing);

      await tester.tap(find.byKey(const Key('refusalHaveInvite')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteRefusal')), findsNothing);
      expect(find.byKey(const Key('haveInviteCode')), findsOneWidget);
    });

    testWidgets('Join the Waitlist after a refusal has the typed address filled in', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      final backend = _gated(_RefusingBackend());
      await _openSignIn(tester, backend);
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueWithEmail')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email')), 'new@example.com');
      await tester.tap(find.byKey(const Key('sendMagicLink')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('refusalJoinWaitlist')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(const Key('waitlistEmail')));
      expect(field.controller!.text, 'new@example.com');
      expect(find.byKey(const Key('waitlistAppleRelay')), findsNothing);
      await tester.tap(find.byKey(const Key('waitlistSubmit')));
      await tester.pumpAndSettle();
      expect(backend.waitlistJoins.single.email, 'new@example.com');
    });

    testWidgets('an Apple refusal fills in the relay address, and says what it is', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      const relay = 'q9w8e7@privaterelay.appleid.com';
      final backend = _gated(_RefusingAppleBackend(relay));
      await _openSignIn(tester, backend);
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appleSignIn')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteRefusal')), findsOneWidget);
      await tester.tap(find.byKey(const Key('refusalJoinWaitlist')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(const Key('waitlistEmail')));
      expect(field.controller!.text, relay);
      expect(find.byKey(const Key('waitlistAppleRelay')), findsOneWidget);
      // Typing a real address instead takes the note away.
      await tester.enterText(find.byKey(const Key('waitlistEmail')), 'ana@example.com');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('waitlistAppleRelay')), findsNothing);
    });
  });

  test('reads the address inside an ID token, and nothing from a bad one', () {
    expect(emailInIdToken(_idToken({'email': 'ana@gmail.com'})), 'ana@gmail.com');
    expect(emailInIdToken(_idToken({'sub': '1'})), isNull);
    expect(emailInIdToken('not-a-token'), isNull);
    expect(emailInIdToken('a.%%%.c'), isNull);
    expect(isAppleRelayEmail('X@PrivateRelay.AppleID.com'), isTrue);
    expect(isAppleRelayEmail(' X@Private.iCloud.com '), isTrue);
    expect(isAppleRelayEmail('ana@icloud.com'), isFalse);
  });

  test('matches only the gate\'s sentences', () {
    expect(inviteRefusalMessage(const sb.AuthException(_refusal)), _refusal);
    expect(
      inviteRefusalMessage(
        const sb.AuthException(
          'Your invite is for another email address. With Apple, choose Share My Email, or use Continue with Email.',
        ),
      ),
      isNotNull,
    );
    expect(
      inviteRefusalMessage(const sb.AuthException('Invalid login credentials')),
      isNull,
    );
    expect(inviteRefusalMessage(Exception('invite-only')), isNull);
  });

  test('an invite link becomes its code', () {
    expect(inviteCodeFrom(' SHOWHN-DEC8 '), 'SHOWHN-DEC8');
    expect(
      inviteCodeFrom('https://casama.ai/invite/SHOWHN-DEC8'),
      'SHOWHN-DEC8',
    );
    expect(inviteCodeFrom('casama.ai/i/K7M2QX?utm_source=x'), 'K7M2QX');
    expect(inviteCodeFrom('https://www.casama.ai/i/K7M2QX/'), 'K7M2QX');
  });

  testWidgets('Join the Waitlist sends the form and says you\'re on the list', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _gated();
    await _openSignIn(tester, backend);
    await tester.tap(find.byKey(const Key('joinWaitlist')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('joinWaitlistForm')), findsOneWidget);

    // A bad address is caught before anything is sent.
    await tester.enterText(find.byKey(const Key('waitlistEmail')), 'nope');
    await tester.tap(find.byKey(const Key('waitlistSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(backend.waitlistJoins, isEmpty);

    await tester.enterText(
      find.byKey(const Key('waitlistEmail')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('waitlistNote')),
      'Sort my inbox',
    );
    await tester.tap(find.byKey(const Key('waitlistSelfHosting')));
    await tester.pumpAndSettle();
    // The monthly email stays unticked unless ticked.
    await tester.tap(find.byKey(const Key('waitlistSubmit')));
    await tester.pumpAndSettle();
    expect(backend.waitlistJoins, hasLength(1));
    final join = backend.waitlistJoins.single;
    expect(join.email, 'ana@example.com');
    expect(join.note, 'Sort my inbox');
    expect(join.selfHosting, isTrue);
    expect(join.newsletter, isFalse);
    expect(find.byKey(const Key('waitlistJoined')), findsOneWidget);
    expect(find.text("You're on the list."), findsOneWidget);
    expect(find.byKey(const Key('waitlistHaveInvite')), findsOneWidget);
  });

  group('I Have an Invite', () {
    testWidgets(
      'code, then email: claims it and sends a sign-in email carrying the code',
      (tester) async {
        await setSize(tester, const Size(500, 1100));
        final backend = _gated();
        await _openSignIn(tester, backend);
        await tester.tap(find.byKey(const Key('haveInvite')));
        await tester.pumpAndSettle();

        // An unknown code says so under the field.
        await tester.enterText(find.byKey(const Key('inviteCode')), 'NOPE-123');
        await tester.tap(find.byKey(const Key('inviteCheck')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            "That code doesn't match any invite. Check it and try again.",
          ),
          findsOneWidget,
        );

        // A pasted link works.
        await tester.enterText(
          find.byKey(const Key('inviteCode')),
          'https://casama.ai/invite/SHOWHN-DEC8',
        );
        await tester.tap(find.byKey(const Key('inviteCheck')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('haveInviteChoose')), findsOneWidget);
        expect(find.text('Your invite: Show HN'), findsOneWidget);
        expect(find.byKey(const Key('inviteApple')), findsOneWidget);
        expect(find.byKey(const Key('inviteGoogle')), findsOneWidget);

        await tester.tap(find.byKey(const Key('inviteWithEmail')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('inviteEmail')),
          'ana@example.com',
        );
        await tester.tap(find.byKey(const Key('inviteEmailSubmit')));
        await tester.pumpAndSettle();
        expect(backend.inviteRedeems, [('SHOWHN-DEC8', 'ana@example.com')]);
        expect(backend.inviteMagicLinks, [('ana@example.com', 'SHOWHN-DEC8')]);
        expect(find.byKey(const Key('haveInviteInbox')), findsOneWidget);
      },
    );

    testWidgets(
      'a used-up code puts the address on the waitlist, ahead of the line',
      (tester) async {
        await setSize(tester, const Size(500, 1100));
        final backend = _gated()
          ..inviteCodes['GONE-CODE'] = InviteCodePreview(
            kind: InviteCodePreviewKindEnum.campaign,
            label: 'Launch',
            inviterName: null,
            available: false,
            welcomeUsd: 0,
          );
        await _openSignIn(tester, backend);
        await tester.tap(find.byKey(const Key('haveInvite')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('inviteCode')),
          'GONE-CODE',
        );
        await tester.tap(find.byKey(const Key('inviteCheck')));
        await tester.pumpAndSettle();
        // Straight to the email: no Apple or Google for a code with nothing left.
        expect(find.byKey(const Key('haveInviteEmail')), findsOneWidget);
        expect(find.byKey(const Key('inviteApple')), findsNothing);
        await tester.enterText(
          find.byKey(const Key('inviteEmail')),
          'ben@example.com',
        );
        await tester.tap(find.byKey(const Key('inviteEmailSubmit')));
        await tester.pumpAndSettle();
        expect(backend.inviteRedeems, [('GONE-CODE', 'ben@example.com')]);
        expect(backend.inviteMagicLinks, isEmpty);
        expect(
          find.text(
            "These invites are gone, but you're ahead of the line.",
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Apple with the code: waitlisted shows the same calm line', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      final backend = _gated()
        ..inviteSignInResult = InviteSignInResult.waitlisted;
      await _openSignIn(tester, backend);
      await tester.tap(find.byKey(const Key('haveInvite')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inviteCode')),
        'SHOWHN-DEC8',
      );
      await tester.tap(find.byKey(const Key('inviteCheck')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inviteApple')));
      await tester.pumpAndSettle();
      expect(backend.inviteRedeems, [('SHOWHN-DEC8', 'apple')]);
      expect(find.byKey(const Key('haveInviteWaitlisted')), findsOneWidget);
    });

    testWidgets('no Apple or Google where the token can\'t come first', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1100));
      final backend = _gated()..inviteProviders = {};
      await _openSignIn(tester, backend);
      await tester.tap(find.byKey(const Key('haveInvite')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inviteCode')),
        'SHOWHN-DEC8',
      );
      await tester.tap(find.byKey(const Key('inviteCheck')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteApple')), findsNothing);
      expect(find.byKey(const Key('inviteGoogle')), findsNothing);
      expect(find.byKey(const Key('inviteWithEmail')), findsOneWidget);
    });
  });

  testWidgets(
    'an invite link opened signed out lands on I Have an Invite, filled in',
    (tester) async {
      await setSize(tester, const Size(500, 1100));
      final backend = _gated()
        ..inviteCodes['ANA234'] = InviteCodePreview(
          kind: InviteCodePreviewKindEnum.personal,
          label: null,
          inviterName: 'Ana',
          available: true,
          welcomeUsd: 2,
        );
      await tester.pumpWidget(
        harness(backend, const InviteLinkScreen(code: 'ANA234')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('referralAccept')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('haveInviteChoose')), findsOneWidget);
      expect(find.text('Ana invited you to Casama'), findsOneWidget);
    },
  );

  testWidgets('Invite Friends shows the invites left, and when they unlock', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1400));
    Referral withInvites(ReferralInvites invites) {
      final r = FakeBackend().referralState;
      return Referral(
        enabled: r.enabled,
        code: r.code,
        link: r.link,
        rewardUsd: r.rewardUsd,
        welcomeUsd: r.welcomeUsd,
        rewardCap: r.rewardCap,
        invited: r.invited,
        rewarded: r.rewarded,
        pending: r.pending,
        earnedUsd: r.earnedUsd,
        invitedBy: r.invitedBy,
        redeemUntil: r.redeemUntil,
        invites: invites,
      );
    }

    final backend = FakeBackend()
      ..referralState = withInvites(
        ReferralInvites(total: 3, used: 1, left: 2, unlocked: true),
      );
    await tester.pumpWidget(harness(backend, const InviteFriendsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('2 invites left'), findsOneWidget);
    expect(
      find.text('1 of 3 used. Each one lets a friend make an account.'),
      findsOneWidget,
    );

    backend.referralState = withInvites(
      ReferralInvites(total: 3, used: 0, left: 3, unlocked: false),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(backend, const InviteFriendsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('3 invites left'), findsOneWidget);
    expect(
      find.text('Your invites unlock after your first finished chat.'),
      findsOneWidget,
    );
  });

  testWidgets('Invite Friends without the gate shows no invites line', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1400));
    await tester.pumpWidget(
      harness(FakeBackend(), const InviteFriendsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inviteFriendsInvites')), findsNothing);
  });

  group('Admin → Waitlist', () {
    Future<FakeBackend> openTab(WidgetTester tester) async {
      await setSize(tester, const Size(900, 2600));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const AdminScreen(tab: 'waitlist')),
      );
      await tester.pumpAndSettle();
      await unlockAdmin(tester);
      return backend;
    }

    testWidgets('shows the numbers, the gate, campaign codes and the list', (
      tester,
    ) async {
      final backend = await openTab(tester);
      expect(find.byKey(const Key('waitlistWaiting')), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('4 of 25'), findsOneWidget);
      expect(find.byKey(const Key('waitlistLastBatch')), findsNothing);
      expect(find.byKey(const Key('gateBatchHour')), findsNothing);
      expect(find.byKey(const Key('waitlistSource-app_ios')), findsOneWidget);
      expect(find.byKey(const Key('campaign-SELFHOST-2026')), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text('ben@example.com'), findsOneWidget);

      // Search goes to the server.
      await tester.enterText(find.byKey(const Key('waitlistSearch')), 'ana');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(backend.waitlistQueries.last, 'ana');
      expect(find.text('ben@example.com'), findsNothing);
    });

    testWidgets('newer servers add the batch hour and the last batch', (
      tester,
    ) async {
      await setSize(tester, const Size(900, 2600));
      final backend = FakeBackend()
        ..batchHourUtc = 15
        ..lastBatch = WaitlistLastBatch(
          at: DateTime.utc(2026, 11, 19, 15),
          count: 20,
        );
      await tester.pumpWidget(
        harness(backend, const AdminScreen(tab: 'waitlist')),
      );
      await tester.pumpAndSettle();
      await unlockAdmin(tester);
      expect(find.byKey(const Key('gateBatchHour')), findsOneWidget);
      expect(find.text('15:00 UTC'), findsOneWidget);
      expect(find.text('20 let in'), findsOneWidget);
    });

    testWidgets('Admit asks how many, confirms, then lets them in', (
      tester,
    ) async {
      final backend = await openTab(tester);
      await tester.tap(find.byKey(const Key('waitlistAdmit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admitCount')), '7');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Let in the next 7 in line?'), findsOneWidget);
      expect(backend.waitlistAdmits, isEmpty);
      await tester.tap(find.byKey(const Key('confirmAdmit')));
      await tester.pumpAndSettle();
      expect(backend.waitlistAdmits, [7]);
    });

    testWidgets('switching the gate asks first, then saves', (tester) async {
      final backend = await openTab(tester);
      await tester.tap(find.byKey(const Key('signupGateSwitch')));
      await tester.pumpAndSettle();
      expect(find.text('Open sign-ups to everyone?'), findsOneWidget);
      expect(backend.signupGateChanges, isEmpty);
      await tester.tap(find.byKey(const Key('confirmSignupGate')));
      await tester.pumpAndSettle();
      expect(backend.signupGateChanges, [
        {'mode': 'open'},
      ]);
      expect(backend.signupGateSetting.mode, SignupGateModeEnum.open);

      // A number: the daily email limit.
      await tester.tap(find.byKey(const Key('gateDailyEmails')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('gateField-daily_emails_max')),
        '60',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(backend.signupGateChanges.last, {'daily_emails_max': 60});
    });

    testWidgets(
      'adds addresses by hand, removes one, and runs campaign codes',
      (tester) async {
        final backend = await openTab(tester);
        await tester.tap(find.byKey(const Key('waitlistAdd')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('waitlistAddEmails')),
          'cy@example.com, dee@example.com',
        );
        await tester.tap(find.byKey(const Key('waitlistAddSubmit')));
        await tester.pumpAndSettle();
        expect(backend.waitlistAdded.single.$1, [
          'cy@example.com',
          'dee@example.com',
        ]);
        expect(backend.waitlistAdded.single.$2, isFalse);

        await tester.tap(find.byKey(const Key('waitlistRemove-e1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmWaitlistRemove')));
        await tester.pumpAndSettle();
        expect(backend.waitlistRemoved, ['e1']);

        await tester.tap(find.byKey(const Key('campaignToggle-SELFHOST-2026')));
        await tester.pumpAndSettle();
        expect(backend.updatedCampaigns.single.$2.disabled, isTrue);

        await tester.tap(find.byKey(const Key('campaignNew')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('campaignCode')),
          'showhn-dec8',
        );
        await tester.enterText(
          find.byKey(const Key('campaignLabel')),
          'Show HN',
        );
        await tester.enterText(find.byKey(const Key('campaignTotal')), '200');
        await tester.enterText(find.byKey(const Key('campaignPerDay')), '50');
        await tester.tap(find.byKey(const Key('campaignCreate')));
        await tester.pumpAndSettle();
        final made = backend.createdCampaigns.single;
        expect(made.code, 'SHOWHN-DEC8');
        expect(made.maxUses, 200);
        expect(made.perDay, 50);
        expect(find.byKey(const Key('campaign-SHOWHN-DEC8')), findsOneWidget);
      },
    );
  });
}

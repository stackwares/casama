import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/referrals/invite_friends.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

/// Invite friends (D-211).
Future<ProviderContainer> _app(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: const CasamaApp(),
    ),
  );
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Settings shows Invite friends with the code, progress and a field for a friend\'s code',
    (tester) async {
      await setSize(tester, const Size(500, 1400));
      final backend = FakeBackend();
      final c = await _app(tester, backend);
      c.read(routerProvider).go('/settings');
      await _settle(tester);
      expect(find.byKey(const Key('settingsInvite')), findsOneWidget);
      expect(
        find.text('Earn \$2.00 of free usage for each friend who joins'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('settingsInvite')));
      await _settle(tester);
      expect(find.text('Give \$2, Get \$2'), findsOneWidget);
      expect(
        find.text(
          'When they finish their first chat, you each get \$2 of free usage',
        ),
        findsOneWidget,
      );
      expect(find.text('K7M2QX'), findsOneWidget);
      expect(find.text('1 hasn\'t finished a first chat yet'), findsOneWidget);
      expect(
        find.text('18 more friends can earn you a reward'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('referralCodeField')),
        'ana 234',
      );
      await tester.tap(find.byKey(const Key('referralRedeem')));
      await _settle(tester);
      expect(backend.redeemedReferrals, ['ana 234']);
      expect(
        find.text(
          "You joined through Ana's invite. Your \$2 welcome bonus arrives after your first chat.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('referralCodeField')), findsNothing);
    },
  );

  testWidgets('Invite friends is hidden where the server has it off', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1400));
    final backend = FakeBackend()
      ..referralState = Referral(
        enabled: false,
        code: null,
        link: null,
        rewardUsd: 0,
        welcomeUsd: 0,
        rewardCap: 0,
        invited: 0,
        rewarded: 0,
        pending: 0,
        earnedUsd: 0,
        invitedBy: null,
        redeemUntil: null,
      );
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/settings');
    await _settle(tester);
    expect(find.byKey(const Key('settingsInvite')), findsNothing);
  });

  testWidgets(
    'a friend\'s link signed out keeps the code through sign-in, then asks once',
    (tester) async {
      await setSize(tester, const Size(500, 1000));
      final backend = FakeBackend()..signedIn = false;
      final c = await _app(tester, backend);
      c.read(routerProvider).go('/i/ANA234');
      await _settle(tester);
      expect(find.text('Ana invited you'), findsOneWidget);
      expect(
        find.textContaining('get \$2 of free usage after your first chat'),
        findsOneWidget,
      );
      expect(
        backend.redeemedReferrals,
        isEmpty,
        reason: 'nothing happens before the person says so',
      );
      await tester.tap(find.byKey(const Key('referralAccept')));
      await _settle(tester);
      expect(c.read(pendingReferralProvider), 'ANA234');
      expect(c.read(routerProvider).state.matchedLocation, '/sign-in');
    },
  );

  testWidgets('signed in, accepting a friend\'s link redeems it and moves on', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(pendingReferralProvider.notifier).set('ANA234');
    await _settle(tester);
    expect(c.read(routerProvider).state.matchedLocation, '/i/ANA234');
    await tester.tap(find.byKey(const Key('referralAccept')));
    await _settle(tester);
    expect(backend.redeemedReferrals, ['ANA234']);
    expect(c.read(pendingReferralProvider), isNull);
    expect(
      c.read(routerProvider).state.matchedLocation,
      isNot(startsWith('/i/')),
    );
  });

  testWidgets('a broken invite link says so', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend());
    c.read(routerProvider).go('/i/ZZZZZZ');
    await _settle(tester);
    expect(find.byKey(const Key('referralInvalid')), findsOneWidget);
  });
}

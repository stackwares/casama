// Settings → Watch (D-410 §6.10): the signed-in watches and Remove, signing one in with a code,
// what a watch may allow, Show details with the app lock, quick replies and the how-to.
import 'dart:async';
import 'dart:convert';

import 'package:casama/core/backend.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/watch/watch_key_store.dart';
import 'package:casama/features/watch/watch_screen.dart';
import 'package:casama_sdk/casama_sdk.dart' show OrganizationWithRole, OrgRole;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_test.dart' show harness, setSize;
import '../../fake_backend.dart';

class _LockOn extends AppLockSettingsNotifier {
  @override
  AppLockSettings build() => const AppLockSettings(enabled: true, userId: 'me');
}

WatchKeyView _watch(
  String id,
  String name, {
  DateTime? lastUsed,
  String? org,
}) => WatchKeyView(
  id: id,
  orgId: org ?? orgId,
  platform: WatchSystem.watchos,
  name: name,
  model: 'Apple Watch Series 10',
  lastUsedAt: lastUsed,
  createdAt: DateTime.utc(2026, 11, 1),
);

void main() {
  late FakeBackend backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    backend = FakeBackend();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> open(
    WidgetTester tester, {
    bool lockOn = false,
    Size size = const Size(800, 3000),
    TargetPlatform? platform,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    await setSize(tester, size);
    await tester.pumpWidget(
      harness(
        backend,
        const WatchScreen(),
        overrides: [
          if (lockOn) appLockSettingsProvider.overrideWith(_LockOn.new),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the watches, and Remove asks first then removes', (
    tester,
  ) async {
    backend.watchKeys = [
      _watch(
        'w1',
        "Oliver's Apple Watch",
        lastUsed: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _watch('w2', 'Kitchen watch'),
      _watch('w3', 'Other workspace', org: 'elsewhere'),
    ];
    await open(tester);
    expect(find.text("Oliver's Apple Watch"), findsOneWidget);
    expect(find.textContaining('Last used'), findsOneWidget);
    expect(find.textContaining('Not used yet'), findsOneWidget);
    expect(find.text('Other workspace'), findsNothing);

    await tester.tap(find.byKey(const Key('removeWatch-w2')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Kitchen watch?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('watchRemoveConfirm')));
    await tester.pumpAndSettle();
    expect(backend.watchKeysDeleted, ['w2']);
    expect(find.text('Kitchen watch'), findsNothing);
  });

  testWidgets('no watches: says it signs in by itself', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('watchNone')), findsOneWidget);
  });

  testWidgets(
    'a watch this phone signed in that is still in another workspace is listed, with where',
    (tester) async {
      const other = '66666666-6666-4666-8666-666666666666';
      backend.extraOrgs.add(
        OrganizationWithRole(
          id: other,
          name: 'Second',
          slug: 'second',
          plan: 'selfhost',
          region: 'local',
          createdAt: DateTime(2026),
          role: OrgRole.owner,
        ),
      );
      backend.watchKeys = [_watch('w9', 'Kitchen watch', org: other)];
      // The phone switched workspace offline: the watch couldn't follow yet.
      backend.watchRegisterError = Exception('offline');
      SharedPreferences.setMockInitialValues({
        WatchKeyStore.prefKey: jsonEncode([
          const WatchRecord(
            fingerprint: 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
            platform: WatchSystem.watchos,
            name: 'Kitchen watch',
            model: 'Apple Watch Series 10',
            keyId: 'w9',
            orgId: other,
            userId: 'me',
          ).toJson(),
        ]),
      });
      await open(tester);
      expect(find.byKey(const Key('watchNone')), findsNothing);
      expect(find.text('Kitchen watch'), findsOneWidget);
      expect(
        find.text('Apple Watch Series 10 · Signed in to Second'),
        findsOneWidget,
      );
      // It can be removed from here too.
      await tester.tap(find.byKey(const Key('removeWatch-w9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchRemoveConfirm')));
      await tester.pumpAndSettle();
      expect(backend.watchKeysDeleted, ['w9']);
      expect(find.text('Kitchen watch'), findsNothing);
      expect(await WatchKeyStore.load(), isEmpty);
    },
  );

  testWidgets(
    'a code: shows which watch is asking, then signs it in to this workspace',
    (tester) async {
      backend.watchCodes['KQ7M2XAB'] = WatchCodeView(
        platform: WatchSystem.wearos,
        name: 'Pixel Watch 3',
        model: 'Pixel Watch 3, 45 mm',
        expiresAt: DateTime.now().add(const Duration(minutes: 9)),
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('watchUseCode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('watchCodeField')),
        'kq7m-2xab',
      );
      await tester.tap(find.byKey(const Key('watchCodeNext')));
      await tester.pumpAndSettle();
      expect(find.text('Sign in Pixel Watch 3?'), findsOneWidget);
      expect(
        find.textContaining('signed in to Test Org as you'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('watchCodeAllow')));
      await tester.pumpAndSettle();
      expect(backend.watchCodesClaimed, [('KQ7M2XAB', orgId)]);
      expect(find.text('Pixel Watch 3 is signed in'), findsOneWidget);
      // The list shows it.
      expect(find.text('Pixel Watch 3'), findsWidgets);
    },
  );

  testWidgets('a wrong code says so and signs nothing in', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('watchUseCode')));
    await tester.pumpAndSettle();
    // Too short to be a code.
    await tester.enterText(find.byKey(const Key('watchCodeField')), 'KQ7');
    await tester.tap(find.byKey(const Key('watchCodeNext')));
    await tester.pumpAndSettle();
    expect(
      find.text("That code didn't work. Check it on your watch"),
      findsOneWidget,
    );
    // The right shape, but no watch shows it.
    await tester.enterText(
      find.byKey(const Key('watchCodeField')),
      'ZZZZ 9999',
    );
    await tester.tap(find.byKey(const Key('watchCodeNext')));
    await tester.pumpAndSettle();
    expect(
      find.text("That code didn't work. Check it on your watch"),
      findsOneWidget,
    );
    expect(find.byKey(const Key('watchCodeAllow')), findsNothing);
    expect(backend.watchCodesClaimed, isEmpty);
  });

  testWidgets(
    'a code that could not be checked (no connection, too many tries) is not called wrong',
    (tester) async {
      backend.watchCodeError = Exception(
        'Too many wrong codes; try again later',
      );
      await open(tester);
      await tester.tap(find.byKey(const Key('watchUseCode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('watchCodeField')),
        'KQ7M 2XAB',
      );
      await tester.tap(find.byKey(const Key('watchCodeNext')));
      await tester.pumpAndSettle();
      expect(
        find.text("That code didn't work. Check it on your watch"),
        findsNothing,
      );
      expect(find.byKey(const Key('watchCodeField')), findsOneWidget);
      // Let the error message go before the test ends.
      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets('a second Go while the code is being checked does nothing', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('watchUseCode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('watchCodeField')),
      'ZZZZ 9999',
    );
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(backend.watchCodeLookups, 1, reason: 'one try spent, not two');
  });

  testWidgets(
    'a watch still signed in to another account says so, and nothing is signed in',
    (tester) async {
      backend.watchCodes['KQ7M2XAB'] = WatchCodeView(
        platform: WatchSystem.watchos,
        name: 'Old watch',
        expiresAt: DateTime.now().add(const Duration(minutes: 9)),
      );
      backend.watchCodeTaken = true;
      await open(tester);
      await tester.tap(find.byKey(const Key('watchUseCode')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('watchCodeField')),
        'KQ7M 2XAB',
      );
      await tester.tap(find.byKey(const Key('watchCodeNext')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchCodeAllow')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('still signed in to another account'),
        findsOneWidget,
      );
      expect(
        find.text("That code didn't work. Check it on your watch"),
        findsNothing,
      );
      expect(backend.watchCodesClaimed, isEmpty);
    },
  );

  testWidgets('Allow from the watch: picking a level saves it', (tester) async {
    await open(tester);
    expect(find.text('Low and medium risk'), findsOneWidget);
    await tester.tap(find.byKey(const Key('watchAllow-low')));
    await tester.pumpAndSettle();
    expect(backend.watchPrefsUpdates.single.allow, WatchAllowance.low);
    expect(backend.storedWatchPrefs!.allow, WatchAllowance.low);
    await tester.tap(find.byKey(const Key('watchAllow-none')));
    await tester.pumpAndSettle();
    expect(backend.storedWatchPrefs!.allow, WatchAllowance.none);
  });

  testWidgets(
    'Show details: with the app lock on, the first visit turns it off and says why',
    (tester) async {
      await open(tester, lockOn: true);
      expect(backend.watchPrefsUpdates.single.showDetails, false);
      expect(
        find.textContaining('Turned off because the app lock is on'),
        findsOneWidget,
      );
      expect(
        tester.widget<Switch>(find.byKey(const Key('watchShowDetails'))).value,
        isFalse,
      );
      // The person can turn it back on.
      await tester.tap(find.byKey(const Key('watchShowDetails')));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.showDetails, isTrue);
    },
  );

  testWidgets('Show details: without the app lock, left as it is', (
    tester,
  ) async {
    await open(tester);
    expect(backend.watchPrefsUpdates, isEmpty);
    expect(
      tester.widget<Switch>(find.byKey(const Key('watchShowDetails'))).value,
      isTrue,
    );
  });

  testWidgets(
    'Show details: a visit with the lock off spends nothing, so turning the lock on later still turns it off',
    (tester) async {
      await open(tester);
      expect(backend.watchPrefsUpdates, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await open(tester, lockOn: true);
      expect(backend.watchPrefsUpdates.single.showDetails, false);
    },
  );

  testWidgets(
    'Show details: once the person turned it back on, the app lock leaves it',
    (tester) async {
      await open(tester, lockOn: true);
      expect(backend.storedWatchPrefs!.showDetails, isFalse);
      await tester.tap(find.byKey(const Key('watchShowDetails')));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.showDetails, isTrue);
      await tester.pumpWidget(const SizedBox());
      await open(tester, lockOn: true);
      expect(backend.storedWatchPrefs!.showDetails, isTrue);
      expect(
        find.textContaining('Turned off because the app lock is on'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'two quick changes are saved one at a time, and a refused one puts back only what it changed',
    (tester) async {
      await open(tester);
      final first = backend.watchPrefsGate = Completer<void>();
      await tester.tap(find.byKey(const Key('watchAllow-low')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('watchShowDetails')));
      await tester.pump();
      expect(
        backend.watchPrefsUpdates,
        hasLength(1),
        reason: 'the second waits for the first',
      );
      // The server refuses the first.
      first.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(backend.watchPrefsUpdates, hasLength(2));
      expect(backend.storedWatchPrefs!.allow, WatchAllowance.medium);
      expect(backend.storedWatchPrefs!.showDetails, isFalse);
      // The screen shows what the server has: the level back, the switch still off.
      expect(
        tester
            .widget<RadioGroup<WatchAllowance>>(
              find.byType(RadioGroup<WatchAllowance>),
            )
            .groupValue,
        WatchAllowance.medium,
      );
      expect(
        tester.widget<Switch>(find.byKey(const Key('watchShowDetails'))).value,
        isFalse,
      );
      // Let the error message go before the test ends.
      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'a change made just before leaving Settings → Watch is still sent',
    (tester) async {
      await open(tester);
      final first = backend.watchPrefsGate = Completer<void>();
      await tester.tap(find.byKey(const Key('watchAllow-low')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('watchShowDetails')));
      await tester.pump();
      expect(
        backend.watchPrefsUpdates,
        hasLength(1),
        reason: 'the second waits for the first',
      );
      // The person goes back while the first save is still out.
      await tester.pumpWidget(const SizedBox());
      first.complete();
      await tester.pumpAndSettle();
      expect(backend.watchPrefsUpdates, hasLength(2));
      expect(backend.storedWatchPrefs!.allow, WatchAllowance.low);
      expect(
        backend.storedWatchPrefs!.showDetails,
        isFalse,
        reason: 'what the screen showed as chosen reached the server',
      );
    },
  );

  testWidgets(
    'two refused changes to one setting go back to what the server has, not to the first unsaved one',
    (tester) async {
      await open(tester);
      final first = backend.watchPrefsGate = Completer<void>();
      await tester.tap(find.byKey(const Key('watchAllow-low')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('watchAllow-none')));
      await tester.pump();
      // Offline: both are refused, one after the other.
      backend.watchPrefsError = Exception('offline');
      first.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(backend.watchPrefsUpdates, hasLength(2));
      expect(backend.storedWatchPrefs!.allow, WatchAllowance.medium);
      expect(
        tester
            .widget<RadioGroup<WatchAllowance>>(
              find.byType(RadioGroup<WatchAllowance>),
            )
            .groupValue,
        WatchAllowance.medium,
        reason: 'Low was never saved either',
      );
      // Let the error messages go before the test ends.
      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'a refused change waits for a later change to the same setting instead of undoing it',
    (tester) async {
      await open(tester);
      final first = backend.watchPrefsGate = Completer<void>();
      await tester.tap(find.byKey(const Key('watchAllow-low')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('watchAllow-none')));
      await tester.pump();
      // The first is refused; the second goes through.
      first.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.allow, WatchAllowance.none);
      expect(
        tester
            .widget<RadioGroup<WatchAllowance>>(
              find.byType(RadioGroup<WatchAllowance>),
            )
            .groupValue,
        WatchAllowance.none,
      );
      await tester.pump(const Duration(seconds: 10));
    },
  );

  testWidgets(
    'Show details: an earlier build already settled it on this device, so the app lock leaves it as the person set it',
    (tester) async {
      // What the first builds kept after the first visit to Settings → Watch.
      SharedPreferences.setMockInitialValues({
        WatchDetailsSettled.legacyKey: true,
      });
      await open(tester, lockOn: true);
      expect(backend.watchPrefsUpdates, isEmpty);
      expect(
        tester.widget<Switch>(find.byKey(const Key('watchShowDetails'))).value,
        isTrue,
      );
      expect(
        find.textContaining('Turned off because the app lock is on'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'quick replies: add up to six, each at most 40 characters, move, delete, reset',
    (tester) async {
      backend.storedWatchPrefs = const WatchPrefsView(
        quickReplies: ['Yes', 'No'],
      );
      await open(tester);
      // Add one; a long reply is cut to 40 characters.
      await tester.tap(find.byKey(const Key('quickReplyAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('quickReplyField')),
        'x' * 50,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('quickReplySave')));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.quickReplies, ['Yes', 'No', 'x' * 40]);

      // Move "No" up.
      await tester.tap(find.byKey(const Key('quickReplyUp-1')));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.quickReplies, ['No', 'Yes', 'x' * 40]);

      // Up to six: the add button turns off.
      for (final r in ['A', 'B', 'C']) {
        await tester.tap(find.byKey(const Key('quickReplyAdd')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('quickReplyField')), r);
        await tester.pump();
        await tester.tap(find.byKey(const Key('quickReplySave')));
        await tester.pumpAndSettle();
      }
      expect(backend.storedWatchPrefs!.quickReplies, hasLength(6));
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('quickReplyAdd')))
            .onPressed,
        isNull,
      );

      // An empty reply can't be saved.
      await tester.tap(find.byKey(const Key('quickReply-0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('quickReplyField')), '   ');
      await tester.tap(find.byKey(const Key('quickReplySave')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('quickReplyField')),
        findsOneWidget,
        reason: 'still open',
      );
      expect(backend.storedWatchPrefs!.quickReplies.first, 'No');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Delete one.
      await tester.tap(find.byKey(const Key('quickReplyDelete-5')));
      await tester.pumpAndSettle();
      expect(backend.storedWatchPrefs!.quickReplies, hasLength(5));

      // Back to the built-in list: sent as empty.
      await tester.tap(find.byKey(const Key('quickReplyReset')));
      await tester.pumpAndSettle();
      expect(backend.watchPrefsUpdates.last.quickReplies, isEmpty);
      expect(backend.storedWatchPrefs!.quickReplies, [
        'On my way',
        'Thanks',
        'Yes',
        'No',
      ]);
    },
  );

  testWidgets('the last quick reply cannot be deleted', (tester) async {
    backend.storedWatchPrefs = const WatchPrefsView(quickReplies: ['Yes']);
    await open(tester);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('quickReplyDelete-0')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'a server without watches: no settings sections, the list still shows',
    (tester) async {
      backend.storedWatchPrefs = null;
      await open(tester);
      expect(find.byKey(const Key('watchNone')), findsOneWidget);
      expect(find.byKey(const Key('watchShowDetails')), findsNothing);
    },
  );

  testWidgets(
    'the how-to: Apple on iPhone, Wear OS on Android, both elsewhere; fits a phone',
    (tester) async {
      await open(
        tester,
        platform: TargetPlatform.iOS,
        size: const Size(390, 3000),
      );
      expect(find.byKey(const Key('watchHowToApple')), findsOneWidget);
      expect(find.byKey(const Key('watchHowToWear')), findsNothing);
      await open(
        tester,
        platform: TargetPlatform.android,
        size: const Size(390, 3000),
      );
      expect(find.byKey(const Key('watchHowToApple')), findsNothing);
      expect(find.byKey(const Key('watchHowToWear')), findsOneWidget);
      await open(tester, platform: TargetPlatform.macOS);
      expect(find.byKey(const Key('watchHowToApple')), findsOneWidget);
      expect(find.byKey(const Key('watchHowToWear')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

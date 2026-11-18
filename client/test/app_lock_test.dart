import 'dart:convert';

import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/app_lock/app_lock_screen.dart';
import 'package:casama/features/app_lock/confirm_identity.dart';
import 'package:casama/features/app_lock/lock_screen.dart';
import 'package:casama/features/app_lock/pin_store.dart';
import 'package:casama/features/app_lock/session_store.dart';
import 'package:casama/features/privacy/privacy_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SharedPreferencesLocalStorage;

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'fake_unlockers.dart';

/// The lock's saved settings for the fake backend's person ('me').
String saved(AppLockSettings s) => jsonEncode(s.toJson());

/// The app's builder with the gate, over a page that stands for the app.
Widget gated(FakeBackend backend, FakeUnlockers unlockers) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    unlockersProvider.overrideWithValue(unlockers),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => AppLockGate(child: child!),
    home: const Scaffold(
      body: Center(child: Text('Private chat', key: Key('behindLock'))),
    ),
  ),
);

Future<void> startLocked(AppLockSettings settings) async {
  SharedPreferences.setMockInitialValues({
    AppLockSettingsNotifier.prefKey: saved(settings),
  });
  await AppLockSettingsNotifier.preload();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    AppLockController.now = DateTime.now;
    PinStore.iterations = 1000;
  });

  group('the PIN', () {
    test('PBKDF2-HMAC-SHA256 matches the published test vectors', () {
      String hex(List<int> b) =>
          b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
      final salt = utf8.encode('salt');
      expect(
        hex(pbkdf2ForTest('password', salt, 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        hex(pbkdf2ForTest('password', salt, 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
      expect(
        hex(pbkdf2ForTest('password', salt, 4096)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('only a salted hash is kept, and it checks the PIN', () async {
      expect(await PinStore.verify('123456'), isNull, reason: 'no PIN yet');
      expect(await PinStore.save('123456'), isTrue);
      final stored = await appSecureStorage.readAll();
      expect(stored.values.single, startsWith('v1:1000:'));
      expect(stored.values.single, isNot(contains('123456')));
      expect(await PinStore.verify('123456'), isTrue);
      expect(await PinStore.verify('654321'), isFalse);
      expect(await PinStore.exists(), isTrue);
      await PinStore.clear();
      expect(await PinStore.exists(), isFalse);
    });
  });

  group('settings', () {
    test('survive a round trip, and belong to one account', () {
      const s = AppLockSettings(
        enabled: true,
        method: LockMethod.pin,
        after: LockAfter.fiveMinutes,
        askBeforeRisky: false,
        blockScreenshots: true,
        userId: 'me',
      );
      expect(AppLockSettings.fromJson(jsonDecode(jsonEncode(s.toJson()))), s);
      expect(s.activeFor('me'), isTrue);
      expect(s.activeFor('someone-else'), isFalse);
      expect(
        const AppLockSettings(enabled: true).activeFor('me'),
        isFalse,
        reason: 'no owner',
      );
      expect(s.off.enabled, isFalse);
      expect(s.off.after, LockAfter.fiveMinutes);
      expect(AppLockSettings.fromJson('junk'), const AppLockSettings());
    });
  });

  group('the sign-in store', () {
    test(
      'moves the session into the keychain while the lock is on, and back',
      () async {
        const url = 'https://abc.supabase.co';
        final key = AuthSessionStore.keyFor(url);
        expect(key, 'sb-abc-auth-token');
        SharedPreferences.setMockInitialValues({key: '{"session":1}'});
        final store = AuthSessionStore.create(url) as AuthSessionStore;
        await store.initialize();
        expect(await store.accessToken(), '{"session":1}');

        await store.useKeychain(true);
        expect(
          (await SharedPreferences.getInstance()).getString(key),
          isNull,
          reason: 'gone from the plain file',
        );
        expect(await appSecureStorage.read(key: key), '{"session":1}');
        expect(await store.accessToken(), '{"session":1}');
        await store.persistSession('{"session":2}');
        expect(await appSecureStorage.read(key: key), '{"session":2}');

        await store.useKeychain(false);
        expect(await appSecureStorage.read(key: key), isNull);
        final prefs = SharedPreferencesLocalStorage(persistSessionKey: key);
        await prefs.initialize();
        expect(await prefs.accessToken(), '{"session":2}');

        await store.removePersistedSession();
        expect(await store.hasAccessToken(), isFalse);
        AuthSessionStore.instance = null;
      },
    );
  });

  group('the lock', () {
    ProviderContainer container(FakeBackend backend) {
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          unlockersProvider.overrideWithValue(FakeUnlockers()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'starts locked when it is on, and locks again after the chosen time away',
      () async {
        await startLocked(
          const AppLockSettings(
            enabled: true,
            after: LockAfter.fiveMinutes,
            userId: 'me',
          ),
        );
        var now = DateTime(2026, 11, 18, 9);
        AppLockController.now = () => now;
        final c = container(FakeBackend());
        final lock = c.read(appLockProvider.notifier);
        expect(
          c.read(appLockProvider).locked,
          isTrue,
          reason: 'a cold start is locked',
        );
        expect(await lock.unlock(() async => UnlockResult.ok), UnlockResult.ok);
        expect(c.read(appLockProvider).locked, isFalse);

        // Four minutes away: still open.
        lock.lifecycle(AppLifecycleState.hidden, computer: false);
        now = now.add(const Duration(minutes: 4));
        lock.lifecycle(AppLifecycleState.resumed, computer: false);
        expect(c.read(appLockProvider).locked, isFalse);

        // Five: locked.
        lock.lifecycle(AppLifecycleState.paused, computer: false);
        now = now.add(const Duration(minutes: 5));
        lock.lifecycle(AppLifecycleState.resumed, computer: false);
        expect(c.read(appLockProvider).locked, isTrue);
      },
    );

    test('a phone ignores a pulled-down Control Center; a computer counts time behind other apps', () async {
      await startLocked(
        const AppLockSettings(
          enabled: true,
          after: LockAfter.immediately,
          userId: 'me',
        ),
      );
      final c = container(FakeBackend());
      final lock = c.read(appLockProvider.notifier);
      await lock.unlock(() async => UnlockResult.ok);
      lock.lifecycle(AppLifecycleState.inactive, computer: false);
      lock.lifecycle(AppLifecycleState.resumed, computer: false);
      expect(c.read(appLockProvider).locked, isFalse);
      lock.lifecycle(AppLifecycleState.inactive, computer: true);
      lock.lifecycle(AppLifecycleState.resumed, computer: true);
      expect(c.read(appLockProvider).locked, isTrue);
    });

    test('its own prompts are not time away', () async {
      await startLocked(
        const AppLockSettings(
          enabled: true,
          after: LockAfter.immediately,
          userId: 'me',
        ),
      );
      final c = container(FakeBackend());
      final lock = c.read(appLockProvider.notifier);
      await lock.unlock(() async {
        // Face ID moves the app out of the front while it asks.
        lock.lifecycle(AppLifecycleState.inactive, computer: true);
        lock.lifecycle(AppLifecycleState.hidden, computer: true);
        return UnlockResult.ok;
      });
      lock.lifecycle(AppLifecycleState.resumed, computer: true);
      expect(c.read(appLockProvider).locked, isFalse);
    });

    test('settings read after launch still start locked', () async {
      SharedPreferences.setMockInitialValues({
        AppLockSettingsNotifier.prefKey: saved(
          const AppLockSettings(enabled: true, userId: 'me'),
        ),
      });
      final c = container(FakeBackend());
      expect(c.read(appLockProvider).locked, isFalse, reason: 'not read yet');
      await pumpEventQueue();
      expect(c.read(appLockSettingsProvider).enabled, isTrue);
      expect(c.read(appLockProvider).locked, isTrue);
    });

    test(
      "is off for another account, and failures are counted until one passes",
      () async {
        await startLocked(
          const AppLockSettings(enabled: true, userId: 'someone-else'),
        );
        final c = container(FakeBackend());
        expect(c.read(appLockProvider).locked, isFalse);
        c.read(appLockProvider.notifier).lock();
        expect(c.read(appLockProvider).locked, isFalse);

        await c
            .read(appLockSettingsProvider.notifier)
            .save(const AppLockSettings(enabled: true, userId: 'me'));
        final lock = c.read(appLockProvider.notifier)..lock();
        expect(c.read(appLockProvider).locked, isTrue);
        await lock.unlock(() async => UnlockResult.failed);
        await lock.unlock(() async => UnlockResult.cancelled);
        expect(
          c.read(appLockProvider).failures,
          1,
          reason: 'closing the prompt is not a failure',
        );
        await lock.unlock(() async => UnlockResult.ok);
        expect(c.read(appLockProvider).failures, 0);
      },
    );
  });

  group('the gate', () {
    testWidgets('covers the app until the device unlock passes', (
      tester,
    ) async {
      await startLocked(const AppLockSettings(enabled: true, userId: 'me'));
      final unlockers = FakeUnlockers(
        deviceOn: true,
        deviceResult: UnlockResult.failed,
      );
      await tester.pumpWidget(gated(FakeBackend(), unlockers));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appLockScreen')), findsOneWidget);
      expect(
        find.byKey(const Key('behindLock')),
        findsNothing,
        reason: 'nothing behind the lock is drawn',
      );
      // It asked by itself once, and that failed.
      expect(unlockers.reasons, ['Unlock Casama']);
      expect(find.text("That didn't work. Try again."), findsOneWidget);

      unlockers.deviceResult = UnlockResult.ok;
      await tester.tap(find.byKey(const Key('appLockUnlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appLockScreen')), findsNothing);
      expect(find.byKey(const Key('behindLock')), findsOneWidget);
    });

    testWidgets(
      'a PIN stops after five wrong tries, and signing out turns the lock off',
      (tester) async {
        await setSize(tester, const Size(500, 900));
        await startLocked(
          const AppLockSettings(
            enabled: true,
            method: LockMethod.pin,
            userId: 'me',
          ),
        );
        final backend = FakeBackend();
        final unlockers = FakeUnlockers(pinValue: '246810');
        await tester.pumpWidget(gated(backend, unlockers));
        await tester.pumpAndSettle();
        expect(
          unlockers.reasons,
          isEmpty,
          reason: 'a PIN never opens a system prompt',
        );
        await tester.enterText(find.byKey(const Key('appLockPin')), '111111');
        await tester.pumpAndSettle();
        expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.enterText(find.byKey(const Key('appLockPin')), '111111');
          await tester.pumpAndSettle();
        }
        expect(find.byKey(const Key('appLockPin')), findsNothing);
        expect(find.textContaining('Too many wrong PINs'), findsOneWidget);
        expect(unlockers.pinChecks, 5);

        await tester.tap(find.byKey(const Key('appLockSignOut')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('appLockConfirmSignOut')));
        await tester.pumpAndSettle();
        expect(backend.signedIn, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(
          AppLockSettings.fromJson(
            jsonDecode(prefs.getString(AppLockSettingsNotifier.prefKey)!),
          ).enabled,
          isFalse,
        );
      },
    );

    testWidgets('a right PIN opens the app', (tester) async {
      await startLocked(
        const AppLockSettings(
          enabled: true,
          method: LockMethod.pin,
          userId: 'me',
        ),
      );
      await tester.pumpWidget(
        gated(FakeBackend(), FakeUnlockers(pinValue: '246810')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('appLockPin')), '246810');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('behindLock')), findsOneWidget);
    });

    testWidgets('the web unlocks with a passkey after a click', (tester) async {
      await startLocked(
        const AppLockSettings(
          enabled: true,
          method: LockMethod.passkey,
          userId: 'me',
        ),
      );
      final backend = FakeBackend()..passkeyConfirm = false;
      await tester.pumpWidget(gated(backend, FakeUnlockers()));
      await tester.pumpAndSettle();
      expect(backend.passkeyConfirms, 0, reason: 'browsers want a click first');
      await tester.tap(find.byKey(const Key('appLockUnlock')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('appLockScreen')),
        findsOneWidget,
        reason: "another account's passkey",
      );
      backend.passkeyConfirm = true;
      await tester.tap(find.byKey(const Key('appLockUnlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('behindLock')), findsOneWidget);
    });

    testWidgets(
      'a phone covers the app in the app switcher while the lock is on',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await startLocked(
          const AppLockSettings(
            enabled: true,
            after: LockAfter.oneHour,
            userId: 'me',
          ),
        );
        final unlockers = FakeUnlockers(deviceOn: true);
        await tester.pumpWidget(gated(FakeBackend(), unlockers));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('behindLock')),
          findsOneWidget,
          reason: 'unlocked by itself at launch',
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(find.byKey(const Key('appLockCover')), findsOneWidget);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(find.byKey(const Key('appLockCover')), findsNothing);
        expect(
          find.byKey(const Key('behindLock')),
          findsOneWidget,
          reason: 'an hour has not passed',
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('a workspace that requires the lock gets it turned on first', (
      tester,
    ) async {
      final backend = FakeBackend()..requireAppLockValue = true;
      final unlockers = FakeUnlockers(deviceOn: true);
      await tester.pumpWidget(gated(backend, unlockers));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appLockRequired')), findsOneWidget);
      expect(
        find.text(
          'Test Org requires the app lock on every device that opens Casama.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('behindLock')), findsNothing);
      await tester.tap(find.byKey(const Key('appLockRequiredTurnOn')));
      await tester.pumpAndSettle();
      expect(unlockers.reasons, ['Turn on the app lock']);
      expect(find.byKey(const Key('behindLock')), findsOneWidget);
    });
  });

  group('Settings → App lock', () {
    testWidgets(
      'turns on with a PIN where the system has no unlock, and asks for it to turn off',
      (tester) async {
        await setSize(tester, const Size(500, 1400));
        final backend = FakeBackend();
        final unlockers = FakeUnlockers();
        await tester.pumpWidget(
          harness(backend, const AppLockScreen(), unlockers: unlockers),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('appLockSwitch')));
        await tester.pumpAndSettle();
        expect(find.text('Choose a PIN'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('appLockPinNew')),
          '135790',
        );
        await tester.pumpAndSettle();
        expect(find.text('Enter the PIN Again'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('appLockPinAgain')),
          '135790',
        );
        await tester.pumpAndSettle();
        expect(await PinStore.verify('135790'), isTrue);
        expect(
          tester.widget<Switch>(find.byKey(const Key('appLockSwitch'))).value,
          isTrue,
        );
        expect(find.text('Unlocks with a 6-digit PIN'), findsOneWidget);
        expect(find.byKey(const Key('appLockChangePin')), findsOneWidget);

        // Turning it off asks for the PIN.
        unlockers.pinValue = '135790';
        await tester.tap(find.byKey(const Key('appLockSwitch')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('appLockPinCheck')),
          '135790',
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Switch>(find.byKey(const Key('appLockSwitch'))).value,
          isFalse,
        );
        expect(await PinStore.exists(), isFalse);
      },
    );

    testWidgets('mismatched PINs start over', (tester) async {
      await setSize(tester, const Size(500, 1400));
      await tester.pumpWidget(harness(FakeBackend(), const AppLockScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appLockSwitch')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('appLockPinNew')), '111111');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('appLockPinAgain')),
        '222222',
      );
      await tester.pumpAndSettle();
      expect(
        find.text("The PINs didn't match. Choose one again."),
        findsOneWidget,
      );
      expect(find.text('Choose a PIN'), findsOneWidget);
      expect(await PinStore.exists(), isFalse);
    });

    testWidgets(
      "a workspace's requirement keeps it on; admins require it once their own is on",
      (tester) async {
        await setSize(tester, const Size(500, 1600));
        final backend = FakeBackend();
        final unlockers = FakeUnlockers(deviceOn: true);
        await tester.pumpWidget(
          harness(backend, const AppLockScreen(), unlockers: unlockers),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('requireAppLock')));
        await tester.tap(find.byKey(const Key('requireAppLock')));
        await tester.pumpAndSettle();
        expect(backend.requireAppLockValue, isFalse);
        expect(
          find.text('Turn on the app lock on this device first.'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('appLockSwitch')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Switch>(find.byKey(const Key('appLockSwitch'))).value,
          isTrue,
        );
        await tester.ensureVisible(find.byKey(const Key('requireAppLock')));
        await tester.tap(find.byKey(const Key('requireAppLock')));
        await tester.pumpAndSettle();
        expect(backend.requireAppLockValue, isTrue);
        expect(find.text('On. Required by Test Org'), findsOneWidget);
        expect(
          tester
              .widget<Switch>(find.byKey(const Key('appLockSwitch')))
              .onChanged,
          isNull,
        );
      },
    );
  });

  group('risky actions', () {
    Future<bool?> check(
      WidgetTester tester,
      FakeUnlockers unlockers, {
      AppLockSettings? settings,
    }) async {
      if (settings != null) await startLocked(settings);
      bool? answer;
      await tester.pumpWidget(
        KeyedSubtree(
          // A new scope each time, so saved settings are read again.
          key: UniqueKey(),
          child: harness(
            FakeBackend(),
            Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async =>
                      answer = await confirmIdentity(context, ref),
                  child: const Text('Do it'),
                ),
              ),
            ),
            unlockers: unlockers,
          ),
        ),
      );
      await tester.tap(find.text('Do it'));
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('ask for the device unlock, with or without the lock', (
      tester,
    ) async {
      final unlockers = FakeUnlockers(deviceOn: true);
      expect(await check(tester, unlockers), isTrue);
      expect(unlockers.reasons, ["Confirm it's you"]);
      unlockers.deviceResult = UnlockResult.cancelled;
      expect(await check(tester, unlockers), isFalse);
      unlockers.deviceResult = UnlockResult.failed;
      expect(await check(tester, unlockers), isFalse);
      expect(find.text("Couldn't confirm it's you."), findsOneWidget);
    });

    testWidgets(
      'go straight through with nothing to ask with, or when turned off',
      (tester) async {
        expect(await check(tester, FakeUnlockers()), isTrue);
        final unlockers = FakeUnlockers(deviceOn: true);
        expect(
          await check(
            tester,
            unlockers,
            settings: const AppLockSettings(askBeforeRisky: false),
          ),
          isTrue,
        );
        expect(unlockers.reasons, isEmpty);
      },
    );

    testWidgets('deleting the account waits for the check', (tester) async {
      await setSize(tester, const Size(800, 1600));
      final backend = FakeBackend();
      final unlockers = FakeUnlockers(
        deviceOn: true,
        deviceResult: UnlockResult.cancelled,
      );
      await tester.pumpWidget(
        harness(backend, const PrivacyScreen(), unlockers: unlockers),
      );
      await tester.pumpAndSettle();
      Future<void> delete() async {
        await tester.ensureVisible(find.byKey(const Key('deleteAccount')));
        await tester.tap(find.byKey(const Key('deleteAccount')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('confirmEmail')),
          'tester@example.com',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('confirmDelete')));
        await tester.pumpAndSettle();
      }

      await delete();
      expect(backend.deletedWith, isNull);
      unlockers.deviceResult = UnlockResult.ok;
      await delete();
      expect(backend.deletedWith, 'tester@example.com');
    });
  });
}

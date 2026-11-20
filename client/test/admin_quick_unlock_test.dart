import 'dart:convert';

import 'package:casama/core/admin_device_key.dart';
import 'package:casama/core/admin_security.dart';
import 'package:casama/core/backend.dart' show Backend;
import 'package:casama/core/backend.dart' show AuthMethods, PasskeyInfo;
import 'package:casama/features/admin/admin_security_gate.dart';
import 'package:casama/features/admin/security_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

/// A token whose last real sign-in was [ago] (only the payload is read on the device).
String tokenSignedIn(Duration ago, {String method = 'password'}) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final at = DateTime.now().subtract(ago).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256'})}.${part({
    'session_id': 'session-1',
    'amr': [
      {'method': method, 'timestamp': at},
    ],
  })}.sig';
}

FakeBackend passkeyBackend() => FakeBackend()
  ..authMethodsValue = const AuthMethods(passkeys: true)
  ..passkeyList.add(
    PasskeyInfo(id: 'p1', name: 'iPhone', createdAt: DateTime(2026)),
  );

class _TwoStepAfterPassword extends FakeBackend {
  @override
  Future<void> signIn(String email, String password) async {
    await super.signIn(email, password);
    twoStepCodeNeeded = true;
  }
}

/// This phone's secure-chip key, without the chip (D-453).
class FakeDeviceKeys extends AdminDeviceKeys {
  FakeDeviceKeys({this.on = true, this.enrolledFor});
  bool on;
  String? enrolledFor;
  var declinedValue = false;

  /// What a check answers: true records one, null is a closed sheet, an exception is thrown.
  Object? answer = true;
  final prompts = <String>[];
  var enrolls = 0;

  @override
  Future<bool> available() async => on;
  @override
  Future<String?> keyId(String? userId) async =>
      userId != null && userId == enrolledFor ? 'key-1' : null;
  @override
  Future<bool> declined(String userId) async => declinedValue;
  @override
  Future<void> setDeclined(String userId, bool value) async =>
      declinedValue = value;
  @override
  Future<bool> enroll(
    Backend backend, {
    required String name,
    required String reason,
  }) async {
    enrolls++;
    prompts.add(reason);
    await backend.addAdminDeviceKey(name, 'spki');
    enrolledFor = backend.userId;
    return true;
  }

  @override
  Future<DateTime?> check(Backend backend, {required String reason}) async {
    prompts.add(reason);
    final a = answer;
    if (a is Exception) throw a;
    if (a == null) return null;
    return backend.adminDeviceCheck('c1', 'sig');
  }

  @override
  Future<void> forget(String userId) async => enrolledFor = null;
}

Future<void> pumpGate(
  WidgetTester tester,
  FakeBackend backend, {
  FakeDeviceKeys? keys,
  Widget child = const Text('private data'),
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    harness(
      backend,
      AdminSecurityGate(child: child),
      overrides: [
        adminDeviceKeysProvider.overrideWithValue(
          keys ?? FakeDeviceKeys(on: false),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    AdminSecurity.forgetVerification();
    AdminSecurity.codeSentTo = null;
    AdminSecurity.accessToken = null;
    AdminSecurity.systemSheets = 0;
    AdminSecurity.checkAt = null;
    AdminSecurity.checkSession = null;
    AdminAuthentication.lastAutoDevice = null;
  });

  group('passkey', () {
    testWidgets('verifies and unlocks with a fresh sign-in', (tester) async {
      final backend = passkeyBackend();
      await pumpGate(tester, backend);
      expect(find.byKey(const Key('adminPasskey')), findsOneWidget);
      // The password stays as the way in when the passkey can't be used.
      expect(find.byKey(const Key('adminPassword')), findsOneWidget);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsOneWidget);
      expect(backend.adminPasskeyChecks, 1);
      // A real sign-in: the next change doesn't ask again right away.
      expect(AdminSecurity.recentlyVerified(backend.userId), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('another account\'s passkey stays locked and says so', (
      tester,
    ) async {
      final backend = passkeyBackend()..adminPasskeyAnswer = false;
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.textContaining('Could not verify'), findsOneWidget);
      expect(AdminSecurity.recentlyVerified(backend.userId), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('closing the sheet is not a failure', (tester) async {
      final backend = passkeyBackend()..adminPasskeyAnswer = null;
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.textContaining('Could not verify'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a passkey is enough on a two-step account (D-452)', (
      tester,
    ) async {
      final backend = passkeyBackend()..twoStepCodeNeeded = true;
      await pumpGate(tester, backend);
      // The session owes its code, so the form starts there, with the passkey as the other way.
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
      await tester.tap(find.byKey(const Key('adminTwoStepPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsOneWidget);
      expect(AdminSecurity.lastVerifiedMethod, 'passkey');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('after a password, a two-step account still gives its code', (
      tester,
    ) async {
      final backend = _TwoStepAfterPassword();
      await pumpGate(tester, backend);
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('confirmations offer the passkey too', (tester) async {
      final backend = passkeyBackend();
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      AdminSecurity.forgetVerification();
      final answer = AdminSecurity.authenticate!(true);
      await tester.pumpAndSettle();
      expect(find.text('Confirm admin action'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(backend.adminPasskeyChecks, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('without a passkey, the lock screen suggests one', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..authMethodsValue = const AuthMethods(passkeys: true);
      await pumpGate(tester, backend);
      expect(find.byKey(const Key('adminPasskey')), findsNothing);
      expect(find.byKey(const Key('adminPasskeyTip')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('where passkeys don\'t work, neither button nor tip shows', (
      tester,
    ) async {
      await pumpGate(tester, FakeBackend());
      expect(find.byKey(const Key('adminPasskey')), findsNothing);
      expect(find.byKey(const Key('adminPasskeyTip')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('a system sheet that pauses the app doesn\'t lock the console', (
    tester,
  ) async {
    final backend = passkeyBackend();
    await pumpGate(tester, backend);
    await tester.tap(find.byKey(const Key('adminPasskey')));
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsOneWidget);
    AdminSecurity.systemSheets = 1;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsOneWidget);
    // Without a sheet open, the same pause locks it.
    AdminSecurity.systemSheets = 0;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('admin PIN', () {
    testWidgets('unlocks with the PIN, as both steps', (tester) async {
      final backend = FakeBackend()
        ..adminPin = '482913'
        ..twoStepCodeNeeded = false;
      await pumpGate(tester, backend);
      await tester.enterText(find.byKey(const Key('adminPin')), '482913');
      await tester.pumpAndSettle();
      expect(backend.adminPinChecks, ['482913']);
      expect(find.text('private data'), findsOneWidget);
      expect(AdminSecurity.lastVerifiedMethod, 'pin');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'a wrong PIN says how many tries are left, the fifth turns it off',
      (tester) async {
        final backend = FakeBackend()..adminPin = '482913';
        await pumpGate(tester, backend);
        await tester.enterText(find.byKey(const Key('adminPin')), '111111');
        await tester.pumpAndSettle();
        expect(find.text('private data'), findsNothing);
        expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.enterText(find.byKey(const Key('adminPin')), '111111');
          await tester.pumpAndSettle();
        }
        expect(backend.adminPinDisabled, isTrue);
        expect(find.byKey(const Key('adminPin')), findsNothing);
        expect(
          find.textContaining('the admin PIN is turned off'),
          findsOneWidget,
        );
        // The password still works.
        expect(find.byKey(const Key('adminPassword')), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('no PIN set: no PIN field', (tester) async {
      await pumpGate(tester, FakeBackend());
      expect(find.byKey(const Key('adminPin')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('confirming a PIN change never offers the PIN', (tester) async {
      final backend = FakeBackend()..adminPin = '482913';
      await pumpGate(tester, backend);
      await tester.enterText(find.byKey(const Key('adminPin')), '482913');
      await tester.pumpAndSettle();
      final context = tester.element(find.text('private data'));
      final answer = showAdminConfirmation(context, allowPin: false);
      await tester.pumpAndSettle();
      expect(find.text('Confirm admin action'), findsOneWidget);
      expect(find.byKey(const Key('adminPin')), findsNothing);
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(AdminSecurity.lastVerifiedMethod, 'password');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('Security sets the PIN after a password check, not the PIN', (
    tester,
  ) async {
    final backend = FakeBackend();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      harness(
        backend,
        const AdminSecurityGate(child: Scaffold(body: AdminSecurityTab())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
    await tester.tap(find.byKey(const Key('adminUnlockPassword')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminPinSet')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appLockPinNew')), '482913');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appLockPinAgain')), '482913');
    await tester.pumpAndSettle();
    // Verified by password moments ago: no second ask.
    expect(backend.adminPin, '482913');
    expect(find.byKey(const Key('adminPinRemove')), findsOneWidget);
    // Verified by the PIN: changing it asks for the password.
    AdminSecurity.verified(backend.userId, method: 'pin');
    await tester.tap(find.byKey(const Key('adminPinRemove')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm admin action'), findsOneWidget);
    expect(find.byKey(const Key('adminPin')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(backend.adminPin, '482913');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Face ID with this phone\'s key (D-453)', () {
    testWidgets('opens by itself and is the whole check, even with two-step', (
      tester,
    ) async {
      final backend = FakeBackend()..twoStepCodeNeeded = true;
      final keys = FakeDeviceKeys(enrolledFor: backend.userId);
      await pumpGate(tester, backend, keys: keys);
      expect(keys.prompts, hasLength(1));
      expect(backend.adminDeviceChecks, 1);
      expect(find.text('private data'), findsOneWidget);
      expect(AdminSecurity.lastVerifiedMethod, 'device');
      // A real check: the next change doesn't ask again right away.
      expect(AdminSecurity.recentlyVerified(backend.userId), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'a new lock screen right away doesn\'t open it again: no loop',
      (tester) async {
        final backend = FakeBackend();
        final keys = FakeDeviceKeys(enrolledFor: backend.userId)..answer = null;
        await pumpGate(tester, backend, keys: keys);
        expect(keys.prompts, hasLength(1));
        // Something locks and rebuilds the console (the loop's trigger): no second prompt.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpGate(tester, backend, keys: keys);
        expect(keys.prompts, hasLength(1));
        // The button still works.
        keys.answer = true;
        await tester.tap(find.byKey(const Key('adminUnlockDevice')));
        await tester.pumpAndSettle();
        expect(find.text('private data'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('confirmations use it too', (tester) async {
      final backend = FakeBackend();
      final keys = FakeDeviceKeys(enrolledFor: backend.userId);
      await pumpGate(tester, backend, keys: keys);
      AdminSecurity.forgetVerification();
      AdminAuthentication.lastAutoDevice = null;
      final answer = AdminSecurity.authenticate!(true);
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(backend.adminDeviceChecks, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a removed key hides the button and says so', (tester) async {
      final backend = FakeBackend();
      final keys = FakeDeviceKeys(enrolledFor: backend.userId)
        ..answer = const DeviceKeyProblem(
          'This device was removed.',
          gone: true,
        );
      await pumpGate(tester, backend, keys: keys);
      await tester.pump();
      expect(find.text('private data'), findsNothing);
      expect(find.byKey(const Key('adminUnlockDevice')), findsNothing);
      expect(find.text('This device was removed.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('after a password, it offers Face ID for next time', (
      tester,
    ) async {
      final backend = FakeBackend();
      final keys = FakeDeviceKeys();
      await pumpGate(
        tester,
        backend,
        keys: keys,
        child: const Scaffold(body: Text('private data')),
      );
      expect(find.byKey(const Key('adminUnlockDevice')), findsNothing);
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      expect(find.text('Use Face ID next time?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adminDeviceOfferYes')));
      await tester.pumpAndSettle();
      expect(keys.enrolls, 1);
      expect(backend.adminDeviceKeyList, hasLength(1));
      expect(find.text('private data'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('not after the PIN, and "Not now" isn\'t asked again', (
      tester,
    ) async {
      final backend = FakeBackend()..adminPin = '482913';
      final keys = FakeDeviceKeys();
      await pumpGate(tester, backend, keys: keys);
      await tester.enterText(find.byKey(const Key('adminPin')), '482913');
      await tester.pumpAndSettle();
      expect(find.text('Use Face ID next time?'), findsNothing);
      AdminSecurity.lock!();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminDeviceOfferNo')));
      await tester.pumpAndSettle();
      expect(keys.declinedValue, isTrue);
      AdminSecurity.lock!();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      expect(find.text('Use Face ID next time?'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Security turns it on and removes it', (tester) async {
      final backend = FakeBackend();
      final keys = FakeDeviceKeys()..declinedValue = true;
      await pumpGate(
        tester,
        backend,
        keys: keys,
        child: const Scaffold(body: AdminSecurityTab()),
      );
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminDeviceTurnOn')));
      await tester.pumpAndSettle();
      expect(keys.enrolls, 1);
      expect(find.textContaining('(This phone)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('adminDeviceRemove-key-1')));
      await tester.pumpAndSettle();
      expect(backend.adminDeviceKeyList, isEmpty);
      expect(keys.enrolledFor, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

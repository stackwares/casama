import 'dart:convert';

import 'package:casama/core/admin_security.dart';
import 'package:casama/core/backend.dart' show AuthMethods, PasskeyInfo;
import 'package:casama/features/admin/admin_security_gate.dart';
import 'package:casama/features/app_lock/app_lock.dart' show UnlockResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';
import 'fake_unlockers.dart';

/// A token whose last real sign-in was [ago] (only the payload is read on the device).
String tokenSignedIn(Duration ago, {String method = 'password'}) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final at = DateTime.now().subtract(ago).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256'})}.${part({
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

class _PasskeyTwoStepBackend extends FakeBackend {
  @override
  Future<bool?> signInAgainWithPasskey() async {
    // Supabase rates a passkey sign-in aal1: an account with an authenticator still owes its code.
    twoStepCodeNeeded = true;
    return super.signInAgainWithPasskey();
  }
}

Future<void> pumpGate(
  WidgetTester tester,
  FakeBackend backend, {
  FakeUnlockers? unlockers,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    harness(
      backend,
      const AdminSecurityGate(child: Text('private data')),
      unlockers: unlockers,
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
  });

  group('server window', () {
    test('reads the newest real sign-in from the token', () {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(minutes: 1));
      final left = AdminSecurity.serverWindowLeft()!;
      expect(left.inSeconds, inInclusiveRange(238, 240));
    });

    test('a passkey sign-in counts', () {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(seconds: 10), method: 'passkey');
      expect(AdminSecurity.serverWindowLeft()!.inSeconds, greaterThan(280));
    });

    test('an old sign-in has no window left', () {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(minutes: 9));
      expect(AdminSecurity.serverWindowLeft(), Duration.zero);
    });

    test('a refresh, a missing token or garbage never counts', () {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(Duration.zero, method: 'token_refresh');
      expect(AdminSecurity.serverWindowLeft(), isNull);
      AdminSecurity.accessToken = () => null;
      expect(AdminSecurity.serverWindowLeft(), isNull);
      AdminSecurity.accessToken = () => 'not.a.token';
      expect(AdminSecurity.serverWindowLeft(), isNull);
    });
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
      expect(backend.passkeyReSignIns, 1);
      // A real sign-in: the next change doesn't ask again right away.
      expect(AdminSecurity.recentlyVerified(backend.userId), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('another account\'s passkey stays locked and says so', (
      tester,
    ) async {
      final backend = passkeyBackend()..passkeyReSignIn = false;
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.textContaining('Could not verify'), findsOneWidget);
      expect(AdminSecurity.recentlyVerified(backend.userId), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('closing the sheet is not a failure', (tester) async {
      final backend = passkeyBackend()..passkeyReSignIn = null;
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.textContaining('Could not verify'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a two-step account still gives its code after the passkey', (
      tester,
    ) async {
      final backend = _PasskeyTwoStepBackend()
        ..authMethodsValue = const AuthMethods(passkeys: true)
        ..passkeyList.add(
          PasskeyInfo(id: 'p1', name: 'iPhone', createdAt: DateTime(2026)),
        );
      await pumpGate(tester, backend);
      await tester.tap(find.byKey(const Key('adminPasskey')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('adminTwoStepCode')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('adminVerifyTwoStep')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsOneWidget);
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
      expect(backend.passkeyReSignIns, 2);
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

  group('Face ID', () {
    testWidgets(
      'opens by itself and unlocks while the server still accepts the sign-in',
      (tester) async {
        AdminSecurity.accessToken = () =>
            tokenSignedIn(const Duration(minutes: 1));
        final unlockers = FakeUnlockers(deviceOn: true);
        final backend = FakeBackend();
        await pumpGate(tester, backend, unlockers: unlockers);
        expect(unlockers.reasons, ['Unlock the admin console']);
        expect(find.text('private data'), findsOneWidget);
        // Only the app's own lock: a change still asks for a real sign-in.
        expect(AdminSecurity.recentlyVerified(backend.userId), isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('isn\'t offered once the server window is nearly over', (
      tester,
    ) async {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(seconds: 280));
      final unlockers = FakeUnlockers(deviceOn: true);
      await pumpGate(tester, FakeBackend(), unlockers: unlockers);
      expect(unlockers.reasons, isEmpty);
      expect(find.byKey(const Key('adminUnlockDevice')), findsNothing);
      expect(find.text('private data'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('isn\'t offered while two-step is still owed', (tester) async {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(minutes: 1));
      final unlockers = FakeUnlockers(deviceOn: true);
      await pumpGate(
        tester,
        FakeBackend()..twoStepCodeNeeded = true,
        unlockers: unlockers,
      );
      expect(unlockers.reasons, isEmpty);
      expect(find.text('private data'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a cancelled check leaves the button to try again', (
      tester,
    ) async {
      AdminSecurity.accessToken = () =>
          tokenSignedIn(const Duration(minutes: 1));
      final unlockers = FakeUnlockers(
        deviceOn: true,
        deviceResult: UnlockResult.cancelled,
      );
      await pumpGate(tester, FakeBackend(), unlockers: unlockers);
      expect(find.text('private data'), findsNothing);
      expect(find.byKey(const Key('adminUnlockDevice')), findsOneWidget);
      unlockers.deviceResult = UnlockResult.ok;
      await tester.tap(find.byKey(const Key('adminUnlockDevice')));
      await tester.pumpAndSettle();
      expect(unlockers.reasons, hasLength(2));
      expect(find.text('private data'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'locking after leaving the app opens the check on return, once',
      (tester) async {
        AdminSecurity.accessToken = () =>
            tokenSignedIn(const Duration(minutes: 1));
        final unlockers = FakeUnlockers(deviceOn: true);
        await pumpGate(tester, FakeBackend(), unlockers: unlockers);
        expect(find.text('private data'), findsOneWidget);
        for (final s in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(s);
        }
        await tester.pumpAndSettle();
        // No frames are drawn in the background; the check waits for the return.
        expect(unlockers.reasons, hasLength(1));
        for (final s in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(s);
        }
        await tester.pumpAndSettle();
        // A second check: the console had locked.
        expect(unlockers.reasons, hasLength(2));
        expect(find.text('private data'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
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
}

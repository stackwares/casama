import 'dart:async';

import 'package:casama/core/admin_security.dart';
import 'package:casama/features/admin/admin_security_gate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin_test_helpers.dart';
import 'app_test.dart' show harness;
import 'fake_backend.dart';

import 'package:casama/core/backend.dart' show TwoStepFactor;

class _DelayedBackend extends FakeBackend {
  final verification = Completer<void>();
  @override
  Future<void> signIn(String email, String password) => verification.future;
}

class _TwoStepBackend extends FakeBackend {
  @override
  Future<void> signIn(String email, String password) async {
    await super.signIn(email, password);
    twoStepCodeNeeded = true;
  }
}

/// Leaving the app: the states a phone goes through on the way to the background.
void leaveApp(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void returnToApp(WidgetTester tester) {
  for (final s in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
}

void main() {
  tearDown(() {
    AdminSecurity.forgetVerification();
    AdminSecurity.codeSentTo = null;
  });

  testWidgets('email code entry survives checking mail in another app', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const AdminSecurityGate(child: Text('private data'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminSendCode')));
    await tester.pumpAndSettle();
    leaveApp(tester);
    await tester.pump();
    returnToApp(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminCode')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('adminCode')), '123456');
    await tester.tap(find.byKey(const Key('adminUnlockCode')));
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('console is initially hidden, verifies, and locks after idle', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        const AdminSecurityGate(child: Text('private data')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsNothing);
    await unlockAdmin(tester);
    expect(find.text('private data'), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('backgrounding during verification cannot unlock the console', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final backend = _DelayedBackend();
    await tester.pumpWidget(
      harness(backend, const AdminSecurityGate(child: Text('private data'))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('adminPassword')),
      'test-password',
    );
    await tester.tap(find.byKey(const Key('adminUnlockPassword')));
    await tester.pump();
    leaveApp(tester);
    // Complete before a frame removes the old form: generation must still reject it.
    backend.verification.complete();
    returnToApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('private data'), findsNothing);
    expect(find.byKey(const Key('adminPassword')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'locking dismisses pending confirmations and cancels their action',
    (tester) async {
      await tester.pumpWidget(
        harness(
          FakeBackend(),
          const AdminSecurityGate(child: Text('private data')),
        ),
      );
      await tester.pumpAndSettle();
      await unlockAdmin(tester);
      final confirmation = AdminSecurity.authenticate!(true);
      await tester.pumpAndSettle();
      expect(find.text('Confirm admin action'), findsOneWidget);
      leaveApp(tester);
      await tester.pumpAndSettle();
      expect(await confirmation, isFalse);
      // No frames are drawn while the app is in the background; look on return.
      returnToApp(tester);
      await tester.pumpAndSettle();
      expect(find.text('Confirm admin action'), findsNothing);
      expect(find.text('private data'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(AdminSecurity.authenticate, isNull);
    },
  );

  testWidgets(
    'another window taking focus neither locks nor drops a confirmation',
    (tester) async {
      await tester.pumpWidget(
        harness(
          FakeBackend(),
          const AdminSecurityGate(child: Text('private data')),
        ),
      );
      await tester.pumpAndSettle();
      await unlockAdmin(tester);
      final confirmation = AdminSecurity.authenticate!(true);
      await tester.pumpAndSettle();
      // A password manager, the mail app's window, the Face ID autofill sheet.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(find.text('Confirm admin action'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byKey(const Key('adminPassword')),
        ),
        'test-password',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byKey(const Key('adminUnlockPassword')),
        ),
      );
      await tester.pumpAndSettle();
      expect(await confirmation, isTrue);
      expect(find.text('private data'), findsOneWidget);
    },
  );

  testWidgets('two changes at once share one confirmation', (tester) async {
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        const AdminSecurityGate(child: Text('private data')),
      ),
    );
    await tester.pumpAndSettle();
    await unlockAdmin(tester);
    final first = AdminSecurity.authenticate!(true);
    final second = AdminSecurity.authenticate!(true);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byKey(const Key('adminPassword')),
      ),
      'test-password',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byKey(const Key('adminUnlockPassword')),
      ),
    );
    await tester.pumpAndSettle();
    expect(await first, isTrue);
    expect(await second, isTrue);
  });

  testWidgets(
    'an account with two-step sign-in finishes with its code, in place',
    (tester) async {
      final backend = _TwoStepBackend();
      await tester.pumpWidget(
        harness(backend, const AdminSecurityGate(child: Text('private data'))),
      );
      await tester.pumpAndSettle();
      expect(AdminSecurity.openAuthForms, greaterThan(0));
      await unlockAdmin(tester);
      // The password alone doesn't open it: the server would refuse an aal1 session.
      expect(find.text('private data'), findsNothing);
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('adminTwoStepCode')),
        '000000',
      );
      await tester.tap(find.byKey(const Key('adminVerifyTwoStep')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('adminTwoStepCode')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('adminVerifyTwoStep')));
      await tester.pumpAndSettle();
      expect(find.text('private data'), findsOneWidget);
      expect(backend.twoStepCodeNeeded, isFalse);
    },
  );

  testWidgets(
    'a session that still owes its code starts at the code after a lock',
    (tester) async {
      final backend = FakeBackend()..twoStepCodeNeeded = true;
      await tester.pumpWidget(
        harness(backend, const AdminSecurityGate(child: Text('private data'))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adminPassword')), findsNothing);
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
    },
  );

  testWidgets('without two-step sign-in, the lock suggests turning it on', (
    tester,
  ) async {
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const AdminSecurityGate(child: Text('private data'))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminTwoStepTip')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    backend.twoStep.add(
      TwoStepFactor(id: 'f', name: 'Phone', createdAt: DateTime(2026)),
    );
    await tester.pumpWidget(
      harness(backend, const AdminSecurityGate(child: Text('private data'))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adminTwoStepTip')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('owner actions elsewhere confirm in a dialog over any screen', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    late BuildContext screen;
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        Builder(
          builder: (context) {
            screen = context;
            return const Text('chat');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final result = showAdminConfirmation(screen);
    await tester.pumpAndSettle();
    expect(find.text('Confirm admin action'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
    await tester.tap(find.byKey(const Key('adminUnlockPassword')));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(AdminSecurity.recentlyVerified('me'), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

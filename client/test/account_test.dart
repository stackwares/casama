import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/auth/account_screen.dart';
import 'package:casama_app/features/auth/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('forgot password emails a reset, and its code asks for a new password', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = FakeBackend()..signedIn = false;
    await tester.pumpWidget(harness(backend, const SignInScreen()));
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueWithEmail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('forgotPassword')));
    await tester.pump();
    expect(backend.passwordResetEmail, isNull);
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'ana@example.com');
    await tester.tap(find.byKey(const Key('forgotPassword')));
    await tester.pumpAndSettle();
    expect(backend.passwordResetEmail, 'ana@example.com');
    expect(find.byKey(const Key('checkInbox')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('emailCode')), '123456');
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.newPasswordNeeded, isTrue);
  });

  testWidgets('the new-password screen saves a matching password, or can be skipped', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()..newPasswordNeeded = true;
    await tester.pumpWidget(harness(backend, const NewPasswordScreen()));
    await tester.enterText(find.byKey(const Key('newPassword')), 'brand-new-pw');
    await tester.enterText(find.byKey(const Key('newPasswordAgain')), 'different');
    await tester.tap(find.byKey(const Key('savePassword')));
    await tester.pump();
    expect(find.text("The passwords don't match"), findsOneWidget);
    expect(backend.password, isNull);

    await tester.tap(find.byKey(const Key('skipNewPassword')));
    await tester.pump();
    expect(backend.newPasswordNeeded, isFalse);
  });

  testWidgets('changing the password on an old session asks for the emailed code', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()..reauthCode = '424242';
    await tester.pumpWidget(harness(backend, const AccountScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('accountPassword')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('newPassword')), 'brand-new-pw');
    await tester.enterText(find.byKey(const Key('newPasswordAgain')), 'brand-new-pw');
    await tester.tap(find.byKey(const Key('savePassword')));
    await tester.pumpAndSettle();
    expect(backend.reauthCodesSent, 1);
    expect(backend.password, isNull);
    expect(find.byKey(const Key('reauthCode')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reauthCode')), '424242');
    await tester.pumpAndSettle();
    expect(backend.password, 'brand-new-pw');
    expect(find.byKey(const Key('reauthCode')), findsNothing);
  });

  testWidgets('changing the email shows it as waiting for confirmation', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AccountScreen()));
    await tester.pumpAndSettle();
    expect(find.text('tester@example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accountEmail')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('newEmail')), 'ana@new.example');
    await tester.pump();
    await tester.tap(find.text('Send confirmation'));
    await tester.pumpAndSettle();
    expect(backend.pendingEmail, 'ana@new.example');
    expect(find.text('Waiting for confirmation: ana@new.example'), findsOneWidget);
  });

  testWidgets('signs out everywhere after confirming', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AccountScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signOutEverywhere')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out everywhere').last);
    await tester.pumpAndSettle();
    expect(backend.signedOutEverywhere, isTrue);
    expect(backend.signedIn, isFalse);
  });

  testWidgets('suggests a passkey once per device, only when the account has none', (tester) async {
    await setSize(tester, const Size(900, 1400));
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend()..authMethodsValue = const AuthMethods(passkeys: true);
    await tester.pumpWidget(harness(backend, const PasskeySuggestion(child: Scaffold(body: Text('home')))));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Sign in faster next time?'), findsOneWidget);
    await tester.tap(find.text('Add a passkey'));
    await tester.pumpAndSettle();
    expect(backend.passkeyList, hasLength(1));

    // Not again on this device.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(backend, const PasskeySuggestion(child: Scaffold(body: Text('home')))));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Sign in faster next time?'), findsNothing);
  });
}

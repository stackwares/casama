import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/passkeys.dart';
import 'package:casama_app/features/auth/passkeys_screen.dart';
import 'package:casama_app/features/auth/sign_in_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  Future<void> openOptions(WidgetTester tester, FakeBackend backend) async {
    await tester.pumpWidget(harness(backend, const SignInScreen()));
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
  }

  testWidgets('no passkey or SSO button when the server has neither', (tester) async {
    await setSize(tester, const Size(500, 1100));
    await openOptions(tester, FakeBackend()..signedIn = false);
    expect(find.byKey(const Key('passkeySignIn')), findsNothing);
    await tester.tap(find.byKey(const Key('moreSignInOptions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ssoSignIn')), findsNothing);
  });

  testWidgets('signs in with a passkey; closing the sheet changes nothing', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = FakeBackend()
      ..signedIn = false
      ..authMethodsValue = const AuthMethods(passkeys: true)
      ..passkeySheetFinishes = false;
    await openOptions(tester, backend);
    await tester.tap(find.byKey(const Key('passkeySignIn')));
    await tester.pumpAndSettle();
    expect(backend.passkeySignIns, 0);
    expect(find.byType(SnackBar), findsNothing);

    backend.passkeySheetFinishes = true;
    await tester.tap(find.byKey(const Key('passkeySignIn')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.passkeySignIns, 1);
  });

  testWidgets('no passkey button when creating an account', (tester) async {
    await setSize(tester, const Size(500, 1100));
    await openOptions(tester, FakeBackend()
      ..signedIn = false
      ..authMethodsValue = const AuthMethods(passkeys: true));
    await tester.tap(find.byKey(const Key('continueWithEmail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleMode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('passkeySignIn')), findsNothing);
  });

  testWidgets('a sign-up that needs confirming goes to the check-inbox step', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = FakeBackend()
      ..signedIn = false
      ..signUpSignsIn = false;
    await openOptions(tester, backend);
    await tester.tap(find.byKey(const Key('continueWithEmail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleMode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'ana@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret-pw');
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkInbox')), findsOneWidget);
    expect(find.textContaining('ana@example.com'), findsWidgets);
    expect(find.byKey(const Key('emailCode')), findsOneWidget);
  });

  testWidgets('settings adds, renames and removes passkeys', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const PasskeysScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Add a Passkey'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addPasskey')));
    await tester.pumpAndSettle();
    expect(backend.passkeyList.single.name, 'iCloud Keychain');
    expect(find.text('Add Another Passkey'), findsOneWidget);

    await tester.tap(find.byKey(const Key('renamePasskey-pk1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Work phone');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(backend.passkeyList.single.name, 'Work phone');

    await tester.tap(find.byKey(const Key('removePasskey-pk1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(backend.passkeyList, isEmpty);
  });

  test('the apps only use passkeys made for casama.ai', () {
    expect(() => PasskeyCeremony.checkDomain('casama.ai', web: false), returnsNormally);
    expect(() => PasskeyCeremony.checkDomain('example.com', web: false), throwsA(isA<PasskeyProblem>()));
    expect(() => PasskeyCeremony.checkDomain('example.com', web: true, pageHost: 'example.com'), returnsNormally);
    expect(() => PasskeyCeremony.checkDomain('casama.ai', web: true, pageHost: 'app.casama.ai'), returnsNormally);
    expect(() => PasskeyCeremony.checkDomain('casama.ai', web: true, pageHost: 'localhost'), throwsA(isA<PasskeyProblem>()));
    expect(() => PasskeyCeremony.checkDomain('casama.ai', web: true, pageHost: 'notcasama.ai'), throwsA(isA<PasskeyProblem>()));
  });
}

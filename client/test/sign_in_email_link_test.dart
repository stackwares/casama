import 'package:casama/features/auth/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test('an address from a link is trimmed, and anything that is not one is ignored', () {
    expect(SignInScreen.emailFromLink('  rae@example.com '), 'rae@example.com');
    expect(
      SignInScreen.emailFromLink('rae+tag@mail.example.co'),
      'rae+tag@mail.example.co',
    );
    for (final bad in [
      null,
      '',
      '   ',
      'rae',
      '@example.com',
      'rae@',
      'a@b@c',
      'rae @example.com',
      '${'a' * 250}@b.co',
    ]) {
      expect(SignInScreen.emailFromLink(bad), isNull, reason: '$bad');
    }
  });

  testWidgets(
    'a link with an address opens the ways in with it typed in, and sends nothing',
    (tester) async {
      await setSize(tester, const Size(500, 1100));
      final backend = FakeBackend()..signedIn = false;
      await tester.pumpWidget(
        harness(backend, const SignInScreen(initialEmail: 'rae@example.com')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('continueWithEmail')),
        findsNothing,
        reason: 'the email field is already open',
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('email')),
      );
      expect(field.controller!.text, 'rae@example.com');
      expect(
        find.byKey(const Key('sendMagicLink')),
        findsOneWidget,
        reason: 'the person still presses the button',
      );
    },
  );

  testWidgets('without an address the screen waits for the button, as before', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1100));
    await tester.pumpWidget(
      harness(FakeBackend()..signedIn = false, const SignInScreen()),
    );
    // The floating bots never stop moving, so this screen never settles on its own.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('email')), findsNothing);
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continueWithEmail')), findsOneWidget);
  });
}

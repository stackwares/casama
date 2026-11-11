import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/apple_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  test('the nonce Apple sees is the sha256 of the raw nonce Supabase checks', () {
    expect(appleNonceHash('hello'), '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');
  });

  test('Apple names join the given and family name, and skip blanks', () {
    expect(appleFullName('Ada', 'Lovelace'), 'Ada Lovelace');
    expect(appleFullName('Ada', '  '), 'Ada');
    expect(appleFullName(null, null), isNull);
    expect(appleFullName('A' * 121, null)!.length, 120);
  });

  test('a missing Apple sheet falls back to the browser; a cancel does not', () {
    expect(
      appleSheetUnavailable(const SignInWithAppleNotSupportedException(message: 'no')),
      isTrue,
    );
    expect(
      appleSheetUnavailable(const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.unknown, message: 'error 1000')),
      isTrue,
    );
    expect(
      appleSheetUnavailable(const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.canceled, message: 'cancel')),
      isFalse,
    );
    expect(
      appleSheetUnavailable(const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.failed, message: 'failed')),
      isFalse,
    );
  });
}

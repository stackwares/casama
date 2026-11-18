import 'package:crypto/crypto.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('counts leading zero bits like the server', () {
    expect(leadingZeroBits([0x00, 0x0f]), 12);
    expect(leadingZeroBits([0x80]), 0);
    expect(leadingZeroBits([0x01]), 7);
  });

  test('solves a puzzle the server would accept', () {
    const challenge = 'v1.10.9999999999999.abc.def';
    final nonce = solveSignupChallenge(challenge, 10);
    expect(leadingZeroBits(sha256.convert('$challenge:$nonce'.codeUnits).bytes), greaterThanOrEqualTo(10));
  });
}

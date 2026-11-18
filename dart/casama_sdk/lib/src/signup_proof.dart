import 'package:crypto/crypto.dart';
import 'package:casama_api/casama_api.dart';

/// Leading zero bits of a digest.
int leadingZeroBits(List<int> digest) {
  var bits = 0;
  for (final byte in digest) {
    if (byte == 0) {
      bits += 8;
      continue;
    }
    var b = byte;
    while (b & 0x80 == 0) {
      bits++;
      b <<= 1;
    }
    break;
  }
  return bits;
}

/// Solves a sign-up puzzle (D-094): a nonce so sha256(`<challenge>:<nonce>`) starts with
/// [difficulty] zero bits. About 2^difficulty hashes; run it off the UI thread in apps.
String solveSignupChallenge(String challenge, int difficulty) {
  for (var n = 0;; n++) {
    final digest = sha256.convert('$challenge:$n'.codeUnits).bytes;
    if (leadingZeroBits(digest) >= difficulty) return '$n';
  }
}

/// The `signup_proof` a new account carries when the server asks for one, or null.
///
/// [solve] runs the puzzle (apps pass an isolate-backed version); App Check tokens are added by
/// apps that have Firebase App Check set up.
Future<Map<String, Object?>?> signupProof(
  CasamaApi api,
  PublicConfig config, {
  Future<String> Function(String challenge, int difficulty)? solve,
}) async {
  final kinds = config.signupProofs ?? const [];
  if (kinds.isEmpty || !kinds.contains(PublicConfigSignupProofsEnum.pow)) return null;
  final ch = (await api.getSystemApi().getSignupChallenge()).data!;
  final nonce = solve == null
      ? solveSignupChallenge(ch.challenge, ch.difficulty)
      : await solve(ch.challenge, ch.difficulty);
  return {'kind': 'pow', 'challenge': ch.challenge, 'nonce': nonce};
}

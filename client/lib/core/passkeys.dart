import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// The domain the apps are tied to for passkeys (Associated Domains on iOS, Digital Asset Links on
/// Android; the files live in site/.well-known). A server with another relying party can still use
/// passkeys on the web, but not in these apps.
const passkeyAppDomains = {'casama.ai'};

/// Mac builds signed by scripts/package-macos*.sh carry the Associated Domains entitlement that
/// passkeys need; unsigned local builds can't, so they don't offer passkeys.
const signedMacBuild = bool.fromEnvironment('CASAMA_SIGNED_MAC');

/// Where this build can make and use passkeys.
bool get passkeysSupportedHere =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    (defaultTargetPlatform == TargetPlatform.macOS && signedMacBuild);

/// Something stopped the passkey sheet, said plainly.
class PasskeyProblem implements Exception {
  const PasskeyProblem(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The system passkey sheet: turns the server's WebAuthn options (W3C JSON) into a credential the
/// server can check, in the same JSON format. Returns null when the person closes the sheet.
class PasskeyCeremony {
  PasskeyCeremony([PasskeyAuthenticator? authenticator]) : _authenticator = authenticator ?? PasskeyAuthenticator();

  final PasskeyAuthenticator _authenticator;

  Future<Map<String, dynamic>?> create(Map<String, dynamic> options) {
    checkDomain((options['rp'] as Map?)?['id'] as String? ?? '');
    return _guard(() async => (await _authenticator.register(RegisterRequestType.fromJson(options))).toJson());
  }

  Future<Map<String, dynamic>?> get(Map<String, dynamic> options) {
    checkDomain(options['rpId'] as String? ?? '');
    // Not only passkeys on this device: also another phone (QR code) and password managers.
    final request = AuthenticateRequestType.fromJson(options, preferImmediatelyAvailableCredentials: false);
    return _guard(() async => (await _authenticator.authenticate(request)).toJson());
  }

  @visibleForTesting
  static void checkDomain(String rpId, {bool web = kIsWeb, String? pageHost}) {
    if (web) {
      // The browser only allows passkeys for the page's own domain or a parent of it, so a local
      // web build on localhost can't use casama.ai passkeys.
      final host = pageHost ?? Uri.base.host;
      if (rpId.isEmpty || (host != rpId && !host.endsWith('.$rpId'))) {
        throw PasskeyProblem(
          "This server's passkeys only work on ${rpId.isEmpty ? 'its own site' : rpId}, not on $host. Sign in another way.",
        );
      }
      return;
    }
    if (!passkeyAppDomains.contains(rpId)) {
      throw PasskeyProblem("This server's passkeys are for ${rpId.isEmpty ? 'another site' : rpId}, which this app can't use. Sign in another way.");
    }
  }

  static Future<T?> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on CredentialNotAuthenticatedException {
      throw const PasskeyProblem("That passkey didn't work. Try another one, or sign in another way.");
    } on PasskeyAuthCancelledException {
      return null;
    } on NoCredentialsAvailableException {
      throw const PasskeyProblem('No passkey for Casama on this device. Sign in another way, then add one in Settings.');
    } on ExcludeCredentialsCanNotBeRegisteredException {
      throw const PasskeyProblem('This device already has a passkey for your account.');
    } on SyncAccountNotAvailableException {
      throw const PasskeyProblem('Sign in to a Google account on this phone to save passkeys.');
    } on MissingGoogleSignInException {
      throw const PasskeyProblem('Sign in to a Google account on this phone to save passkeys.');
    } on DeviceNotSupportedException {
      throw const PasskeyProblem("This device can't use passkeys.");
    } on PasskeyUnsupportedException {
      throw const PasskeyProblem("This device can't use passkeys.");
    } on DomainNotAssociatedException {
      throw const PasskeyProblem("Passkeys aren't set up for this app yet. Sign in another way.");
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Casama's iOS client (bundle ai.casama.app), used on iPhone and Mac. Empty: those use the browser.
///
/// Not a build define on purpose: Google's iOS SDK stops the app when the reversed id is not a URL
/// scheme in Info.plist, so this and both Info.plist files change together (a test checks).
const googleIosClientId =
    '278631205206-ma3i1l9a9q2sb3ac2coeucm43nqqt2lj.apps.googleusercontent.com';

/// The URL scheme Google's iOS SDK returns to: the client id read backwards.
String googleReversedClientId(String clientId) =>
    'com.googleusercontent.apps.${clientId.replaceFirst(RegExp(r'\.apps\.googleusercontent\.com$'), '')}';

/// The client id Google's own sheet signs in with on this platform, given the ids the server's Auth
/// accepts ([serverIds], the web client first; D-217). Android asks for a token addressed to that
/// web client, which works when it is in the same Google project as the app's Android client.
/// iPhone and Mac use the app's iOS client, so the server must list it. Null where there is no
/// sheet (Windows, Linux, the web) or this server can't take the token: those use the browser.
String? googleNativeClient(
  TargetPlatform platform,
  List<String> serverIds, {
  bool web = kIsWeb,
}) {
  if (web || serverIds.isEmpty) return null;
  return switch (platform) {
    TargetPlatform.android => serverIds.first,
    TargetPlatform.iOS || TargetPlatform.macOS =>
      googleIosClientId.isNotEmpty && serverIds.contains(googleIosClientId)
          ? googleIosClientId
          : null,
    _ => null,
  };
}

/// Google's sheet failed without the person cancelling it: no Google account on the phone, no Play
/// services, a missing keychain entitlement on a local Mac build, a client Google doesn't know.
/// The browser can still sign them in.
bool googleSheetUnavailable(Object error) => switch (error) {
  GoogleSignInException(:final code) =>
    code != GoogleSignInExceptionCode.canceled,
  PlatformException() || MissingPluginException() => true,
  _ => false,
};

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// How a sign-in in the browser ended, as far as the app can tell.
enum SignInSheetResult {
  /// The sign-in reached casama-auth://done?status=ok and the sheet closed itself.
  finished,

  /// It reached casama-auth://done?status=error (cancelled or refused at the provider).
  failed,

  /// The person closed the sheet before the end.
  closed,

  /// Opened in a separate browser (web, desktop, or the sheet couldn't open): the app finds out
  /// by checking, as before.
  browser,
}

/// The scheme the server ends a sign-in on when the app asked it to (`return_to_app`).
const signInReturnScheme = 'casama-auth';

const _channel = MethodChannel('casama/sign_in_sheet');

/// Opens a sign-in in the browser; tests replace it.
@visibleForTesting
Future<void> Function(Uri url) openInBrowser = (url) =>
    launchUrl(url, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');

/// Phones sign in through the system's sign-in sheet (D-243): ASWebAuthenticationSession on iOS
/// (AppDelegate.swift), a Custom Tab on Android (MainActivity.kt). It shares the browser's
/// sign-ins, Google allows it (unlike a WebView), and it closes itself when the server sends the
/// browser to casama-auth://done. Desktop and web keep opening the browser.
bool get signInSheetAvailable =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// Opens [url] for signing in and returns when that's over (or, in a separate browser, once it's open).
/// Pass `returnToApp: signInSheetAvailable` when asking the server for [url].
Future<SignInSheetResult> openSignIn(String url) async {
  if (signInSheetAvailable) {
    try {
      final back = await _channel.invokeMethod<String>('open', {'url': url, 'scheme': signInReturnScheme});
      if (back == null) return SignInSheetResult.closed;
      return Uri.tryParse(back)?.queryParameters['status'] == 'ok'
          ? SignInSheetResult.finished
          : SignInSheetResult.failed;
    } on PlatformException {
      // The sheet couldn't open: the browser still works, and the server finishes the sign-in.
    } on MissingPluginException {
      // Tests, and engines without the channel.
    }
  }
  try {
    await openInBrowser(Uri.parse(url));
  } catch (_) {
    // No browser handler (tests, locked-down devices): the caller offers to open it again.
  }
  return SignInSheetResult.browser;
}

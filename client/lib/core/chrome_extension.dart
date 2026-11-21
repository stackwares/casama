import 'chrome_extension_web.dart'
    if (dart.library.io) 'chrome_extension_stub.dart'
    as impl;

/// Casama for Chrome's extension ids (D-323). The web app hands it a sign-in link only through
/// these. The id comes from the manifest key in apps/extension/src/manifest.ts; when the store
/// item exists, its public key becomes that key, so dev builds and the store share one id.
/// apps/extension/test/ids.test.ts keeps this list, the server's default and the manifest in step.
/// Edge Add-ons gives the same package its own id (D-323 Phase 5): add it here once the Edge item
/// exists, and to the server's CHROME_EXTENSION_IDS, so Connect Chrome works in Edge too. Firefox
/// can't take a sign-in from a web page, so it has no id here.
const chromeExtensionIds = ['kkfppfhkjnenffibmnkphnbejidkmbkj'];

enum ChromeHandover {
  /// The extension is signed in.
  signedIn,

  /// The extension opened its first-run screen; the sign-in finishes there.
  finishInChrome,

  /// No Casama for Chrome in this browser.
  notInstalled,

  /// It answered but couldn't sign in; [ChromeHandoverResult.error] says why.
  failed,
}

class ChromeHandoverResult {
  const ChromeHandoverResult(this.outcome, [this.error]);
  final ChromeHandover outcome;
  final String? error;
}

typedef ChromeSender = Future<Map<String, Object?>?> Function(
  String id,
  Map<String, Object?> message,
);

/// How messages reach the extension; tests swap it.
ChromeSender chromeSender = impl.sendToChromeExtension;

/// "Connect Chrome" (plan §9.2, route 1): hands Casama for Chrome the sign-in [link] from Sign In
/// on Another Device. The link works once, so the sheet shows a new code afterwards either way.
Future<ChromeHandoverResult> connectChrome(String link) async {
  for (final id in chromeExtensionIds) {
    final reply = await chromeSender(id, {
      'type': 'casama.signIn',
      'link': link,
    });
    if (reply == null || reply['ok'] is! bool) continue;
    if (reply['ok'] == true) {
      return ChromeHandoverResult(
        reply['pending'] == true
            ? ChromeHandover.finishInChrome
            : ChromeHandover.signedIn,
      );
    }
    return ChromeHandoverResult(
      ChromeHandover.failed,
      reply['error'] as String?,
    );
  }
  return const ChromeHandoverResult(ChromeHandover.notInstalled);
}

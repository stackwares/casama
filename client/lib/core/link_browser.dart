import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where web links from bots, pages and help open on a phone: the system's in-app browser
/// (Safari View Controller, Chrome Custom Tabs) or the default browser app. Not a web view in the
/// app: both are the system's own browser. Desktop always uses the default browser and the web a
/// new tab, so the choice only shows on iOS and Android.
///
/// Sign-in, payment, key and download links don't follow it: they open in the default browser,
/// where the person is already signed in and the store rules are met.
bool get linkBrowserChoiceShown =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Settings → App → **Open links in the app**, kept on this device. On until turned off.
class LinkBrowserInApp extends Notifier<bool> {
  static const _key = 'links.inApp';

  /// What [openWebLink] reads, so code without a ref follows the switch too.
  static bool _current = true;

  /// Read during startup, so the first link opened already follows the saved choice.
  static Future<void> preload() async {
    try {
      _current = (await SharedPreferences.getInstance()).getBool(_key) ?? true;
    } catch (_) {}
  }

  @visibleForTesting
  static void debugSet(bool inApp) => _current = inApp;

  @override
  bool build() => _current;

  Future<void> set(bool inApp) async {
    _current = inApp;
    state = inApp;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, inApp);
    } catch (_) {}
  }
}

final linkBrowserInAppProvider = NotifierProvider<LinkBrowserInApp, bool>(
  LinkBrowserInApp.new,
);

/// Opens a web address in the browser chosen in Settings (see [LinkBrowserInApp]); anything that
/// isn't http or https is ignored. Falls back to the default browser when the in-app one can't
/// open it. Says whether something opened it.
Future<bool> openWebLink(Uri uri) async {
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  try {
    if (linkBrowserChoiceShown && LinkBrowserInApp._current) {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
    }
  } catch (_) {}
  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}

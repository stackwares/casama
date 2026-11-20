import 'package:web/web.dart' as web;

/// Where `web/boot.js` leaves the address it took out of the page's link.
const _key = 'casama-sign-in-email';

/// The address `web/boot.js` kept for the sign-in screen, removed as it is read (so it is used
/// once). Null when there is none, or when the browser has storage turned off.
String? takeSignInEmailFromPage() {
  try {
    final value = web.window.sessionStorage.getItem(_key);
    if (value != null) web.window.sessionStorage.removeItem(_key);
    return value;
  } catch (_) {
    return null;
  }
}

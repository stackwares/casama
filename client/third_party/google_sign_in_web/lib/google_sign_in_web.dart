import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Registers nothing. The real plugin starts downloading Google Identity Services
/// (accounts.google.com/gsi/client) as soon as it registers, before the app's first frame, though
/// the web app never signs in through it (see README.md).
class GoogleSignInPlugin {
  static void registerWith(Registrar registrar) {}
}

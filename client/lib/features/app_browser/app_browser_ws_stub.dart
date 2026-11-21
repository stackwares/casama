import 'app_browser_socket.dart';

/// No device socket on the web (the phone browser exists only on phones).
AppBrowserTransport createAppBrowserTransport() => _NoTransport();

class _NoTransport implements AppBrowserTransport {
  @override
  Future<AppBrowserConnection> connect(Uri url, Map<String, String> headers) =>
      Future.error(UnsupportedError('No device socket here'));
}

String? appBrowserOsLabel() => null;

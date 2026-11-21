import 'dart:async';
import 'dart:io';

import 'app_browser_socket.dart';

/// The device socket over dart:io (phones).
AppBrowserTransport createAppBrowserTransport() => _IoTransport();

class _IoTransport implements AppBrowserTransport {
  @override
  Future<AppBrowserConnection> connect(
    Uri url,
    Map<String, String> headers,
  ) async {
    final ws = await WebSocket.connect(url.toString(), headers: headers);
    // Pings find a dead connection (a network change, sleep) so the loop dials again.
    ws.pingInterval = const Duration(seconds: 20);
    return _IoConnection(ws);
  }
}

class _IoConnection implements AppBrowserConnection {
  _IoConnection(this._ws);
  final WebSocket _ws;

  @override
  Stream<String> get messages => _ws.where((m) => m is String).cast<String>();

  @override
  void send(String message) {
    if (_ws.readyState == WebSocket.open) _ws.add(message);
  }

  @override
  Future<void> close() => _ws.close();
}

/// "iOS 26.1" or "Android", for `x-casama-os`; null elsewhere.
String? appBrowserOsLabel() {
  try {
    final v = RegExp(r'\d+(\.\d+)*')
        .firstMatch(Platform.operatingSystemVersion)
        ?.group(0);
    if (Platform.isIOS) return v == null ? 'iOS' : 'iOS $v';
    // Dart reports the kernel's version on Android, not the system's.
    if (Platform.isAndroid) return 'Android';
  } catch (_) {}
  return null;
}

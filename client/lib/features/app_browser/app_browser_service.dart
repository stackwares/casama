import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/chat_focus.dart';
import '../../core/providers.dart';
import '../../core/remote_config.dart' show appVersionProvider;
import 'app_browser_controller.dart';
import 'app_browser_flag.dart';
import 'app_browser_socket.dart';
import 'app_browser_ws_stub.dart'
    if (dart.library.io) 'app_browser_ws_io.dart'
    as ws;

/// Where this phone keeps its browser's device token (it comes back once, at pairing).
abstract interface class AppBrowserTokenStore {
  Future<String?> read(String deviceId);
  Future<void> write(String deviceId, String token);
  Future<void> delete(String deviceId);
}

class SecureAppBrowserTokenStore implements AppBrowserTokenStore {
  static const _secure = FlutterSecureStorage();
  String _key(String deviceId) => 'casama.app_browser.$deviceId';

  @override
  Future<String?> read(String deviceId) => _secure.read(key: _key(deviceId));
  @override
  Future<void> write(String deviceId, String token) =>
      _secure.write(key: _key(deviceId), value: token);
  @override
  Future<void> delete(String deviceId) => _secure.delete(key: _key(deviceId));
}

/// For tests.
class MemoryAppBrowserTokenStore implements AppBrowserTokenStore {
  final tokens = <String, String>{};
  @override
  Future<String?> read(String deviceId) async => tokens[deviceId];
  @override
  Future<void> write(String deviceId, String token) async =>
      tokens[deviceId] = token;
  @override
  Future<void> delete(String deviceId) async => tokens.remove(deviceId);
}

final appBrowserTokenStoreProvider = Provider<AppBrowserTokenStore>(
  (ref) => SecureAppBrowserTokenStore(),
);
final appBrowserTransportProvider = Provider<AppBrowserTransport>(
  (ref) => defaultAppBrowserTransport(),
);

/// This install's id, the one the chat focus uses (the server pairs the phone browser with it).
final appBrowserClientIdProvider = FutureProvider<String>(
  (ref) => ref.watch(chatFocusProvider).clientId(),
);

/// Whether this person may use the phone browser here, and this install's device. Null in a build
/// without it, off a phone, or with no workspace.
final appBrowserStatusProvider = FutureProvider<AppBrowserState?>((ref) async {
  if (!kAppBrowserCode || !ref.watch(appBrowserOnProvider)) return null;
  final org = ref.watch(currentOrgIdProvider);
  final system = appBrowserSystem;
  if (org == null || system == null) return null;
  final clientId = await ref.watch(appBrowserClientIdProvider.future);
  return ref
      .watch(backendProvider)
      .appBrowserState(org, system: system, clientId: clientId);
});

/// Pairing and the device socket: connected only while the feature is on for this phone, a device
/// is paired and switched on, and the app is in front (PROTOCOL.md §1). Kept alive by the app.
class AppBrowserService with WidgetsBindingObserver {
  AppBrowserService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _foreground = _isFront(WidgetsBinding.instance.lifecycleState);
    _ref.listen(
      appBrowserStatusProvider,
      (_, next) => unawaited(_sync(next.value)),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  AppBrowserSocket? _socket;
  String? _socketDevice;
  bool _foreground = true;
  bool _disposed = false;

  /// The socket's state, for the settings screen.
  final link = ValueNotifier(AppBrowserLink.off);

  static bool _isFront(AppLifecycleState? s) =>
      s == null || s == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final front = _isFront(state);
    if (front == _foreground) return;
    _foreground = front;
    unawaited(_sync(_ref.read(appBrowserStatusProvider).value));
    // Back in front: ask the server again (the stage or the workspace switch may have changed).
    if (front) _ref.invalidate(appBrowserStatusProvider);
  }

  Future<void> _sync(AppBrowserState? status) async {
    if (_disposed) return;
    final device = status?.device;
    final controller = _ref.read(appBrowserProvider.notifier);
    controller.device = device;
    final token = device == null
        ? null
        : await _ref.read(appBrowserTokenStoreProvider).read(device.id);
    final want =
        status != null &&
        status.available &&
        device != null &&
        device.enabled &&
        _foreground &&
        token != null;
    if (!want) return _stop();
    if (_socket != null && _socketDevice == device.id) return;
    await _stop();
    final version = await _ref
        .read(appVersionProvider.future)
        .catchError((_) => '');
    if (_disposed) return;
    final socket = _socket = AppBrowserSocket(
      transport: _ref.read(appBrowserTransportProvider),
      apiUrl: _ref.read(backendProvider).apiUrl,
      token: token,
      os: ws.appBrowserOsLabel(),
      version: version,
      onCall: (call) => _ref.read(appBrowserProvider.notifier).handle(call),
    );
    _socketDevice = device.id;
    socket.link.addListener(() => link.value = socket.link.value);
    socket.start();
  }

  Future<void> _stop() async {
    final s = _socket;
    _socket = null;
    _socketDevice = null;
    if (s == null) return;
    await s.stop();
    link.value = AppBrowserLink.off;
    // Whatever a bot was waiting on can't be answered now.
    _ref.read(appBrowserProvider.notifier).disconnected();
  }

  /// Pairs this phone's browser after the person said yes on the consent screen.
  Future<LocalDevice> pair({required String name}) async {
    final org = _ref.read(currentOrgIdProvider);
    final system = appBrowserSystem;
    if (org == null || system == null) {
      throw StateError('No workspace or not a phone');
    }
    final clientId = await _ref.read(appBrowserClientIdProvider.future);
    final created = await _ref
        .read(backendProvider)
        .pairAppBrowser(org, name: name, system: system, clientId: clientId);
    await _ref
        .read(appBrowserTokenStoreProvider)
        .write(created.id, created.token);
    _ref.invalidate(appBrowserStatusProvider);
    return LocalDevice.fromJson(created.toJson()..remove('token'));
  }

  /// Whether this phone still holds the device's token (a reinstall loses it: pair again).
  Future<bool> hasToken(String deviceId) async =>
      await _ref.read(appBrowserTokenStoreProvider).read(deviceId) != null;

  /// Forgets this phone's browser: the device row and its token.
  Future<void> unpair(String deviceId) async {
    await _stop();
    await _ref.read(backendProvider).deleteLocalDevice(deviceId);
    await _ref.read(appBrowserTokenStoreProvider).delete(deviceId);
    _ref.invalidate(appBrowserStatusProvider);
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_socket?.stop());
    _socket = null;
  }
}

/// Started with the app (only in builds with the phone browser, on a phone).
final appBrowserServiceProvider = Provider<AppBrowserService>((ref) {
  final s = AppBrowserService(ref);
  ref.onDispose(s.dispose);
  return s;
});

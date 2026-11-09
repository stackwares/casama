import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend.dart';
import 'providers.dart';
import 'router.dart';

/// Firebase settings come from --dart-define so no Firebase config files live in the repo.
/// Without FIREBASE_PROJECT_ID push is off and the in-app inbox (Realtime) still works.
class PushConfig {
  const PushConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  static bool get enabled => projectId.isNotEmpty && apiKey.isNotEmpty && appId.isNotEmpty && senderId.isNotEmpty;

  static FirebaseOptions get options =>
      const FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId);
}

String _platform() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    _ => 'linux',
  };
}

/// Registers this device for push after sign-in and opens deep links from tapped notifications.
class PushRegistrar {
  PushRegistrar(this._backend, this._openLink);

  final Backend _backend;
  final void Function(String link) _openLink;
  final _subs = <StreamSubscription<Object?>>[];
  var _started = false;

  Future<void> start() async {
    if (_started || !PushConfig.enabled) return;
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    if (kIsWeb && PushConfig.vapidKey.isEmpty) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: PushConfig.options);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // The worker sends with FCM HTTP v1 `message.token`, so register the classic token
      // (firebase_messaging 17 deprecates it in favour of installation-ID direct send; see DECISIONS D-051).
      // ignore: deprecated_member_use
      final token = await messaging.getToken(vapidKey: kIsWeb ? PushConfig.vapidKey : null);
      if (token != null) await _backend.registerDevice(_platform(), token);
      // ignore: deprecated_member_use
      _subs.add(messaging.onTokenRefresh.listen((t) => _backend.registerDevice(_platform(), t)));
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      // Push is best effort; the in-app inbox still has every notification.
      debugPrint('push registration failed: $e');
    }
  }

  void _open(RemoteMessage message) {
    final link = message.data['link'];
    if (link is String && link.startsWith('/')) _openLink(link);
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}

/// Starts push once signed in; watched by the app root.
final pushProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(ref.watch(backendProvider), (link) => ref.read(routerProvider).go(link));
  ref.onDispose(registrar.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true) unawaited(registrar.start());
  }, fireImmediately: true);
  return registrar;
});

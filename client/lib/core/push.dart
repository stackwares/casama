import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/voice/phone_calls.dart' show casamaBackgroundMessage;
import 'backend.dart';
import 'providers.dart';
import 'router.dart';
import 'web_notification_prompt_web.dart' if (dart.library.io) 'web_notification_prompt_stub.dart';
import 'analytics.dart';

/// Firebase settings come from --dart-define (official builds: `--dart-define-from-file=config/firebase.json`,
/// the public client identifiers of the `kasama-ai` project). Self-hosters building their own apps
/// point this at their own Firebase project. Without a project id push is off and the in-app inbox
/// (Realtime) still works.
class PushConfig {
  const PushConfig._();

  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  // Generic values (one app for every platform) are the fallback for per-platform ones.
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: _apiKey);
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: _appId);
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const _androidApiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: _apiKey);
  static const _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: _appId);
  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: _apiKey);
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: _appId);
  static const _webAuthDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');

  static (String apiKey, String appId) get _keys {
    if (kIsWeb) return (_webApiKey, _webAppId);
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => (_androidApiKey, _androidAppId),
      _ => (_iosApiKey, _iosAppId), // iOS and macOS share the Apple app.
    };
  }

  static bool get enabled => projectId.isNotEmpty && senderId.isNotEmpty && _keys.$1.isNotEmpty && _keys.$2.isNotEmpty;

  /// Address of `web/firebase-messaging-sw.js` for this build. Root-absolute so a
  /// registration from `/chat/…` still loads the worker at the site root.
  static String? get messagingServiceWorkerPath {
    if (!kIsWeb || !enabled) return null;
    final (apiKey, appId) = _keys;
    return firebaseMessagingServiceWorkerPath(
      apiKey: apiKey,
      appId: appId,
      senderId: senderId,
      projectId: projectId,
      authDomain: _webAuthDomain,
    );
  }

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: _keys.$1,
    appId: _keys.$2,
    messagingSenderId: senderId,
    projectId: projectId,
    iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    authDomain: kIsWeb && _webAuthDomain.isNotEmpty ? _webAuthDomain : null,
  );
}

/// `web/firebase-messaging-sw.js` plus the public Firebase app, for [PushConfig.messagingServiceWorkerPath].
String firebaseMessagingServiceWorkerPath({
  required String apiKey,
  required String appId,
  required String senderId,
  required String projectId,
  String authDomain = '',
}) {
  final query = <String, String>{
    'apiKey': apiKey,
    'appId': appId,
    'messagingSenderId': senderId,
    'projectId': projectId,
    if (authDomain.isNotEmpty) 'authDomain': authDomain,
  };
  final qs = query.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  return '/firebase-messaging-sw.js?$qs';
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
  PushRegistrar(this._backend, this._openLink, {this.onOpened});

  final Backend _backend;
  final void Function(String link) _openLink;

  /// Called with the notification id when a push is tapped, so the inbox marks it read.
  final void Function(String notificationId)? onOpened;
  final _subs = <StreamSubscription<Object?>>[];
  var _started = false;

  /// Whether to show our own "Turn on notifications" page first (phones and Macs, never asked, not
  /// snoozed): the system prompt comes from its button, with the reason in view.
  final needsAsk = ValueNotifier(false);

  /// Chrome has already blocked this site, so the page explains the address-bar setting
  /// instead of expecting a prompt that will not appear.
  final webBlocked = ValueNotifier(false);

  static const _askedKey = 'push.asked';
  static const _snoozedKey = 'push.snoozedUntil';

  Future<void> start() async {
    if (_started || !PushConfig.enabled) return;
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    if (kIsWeb && PushConfig.vapidKey.isEmpty) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: PushConfig.options);
      // Phone calls (D-135): on Android a call push rings even when the app is closed.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) FirebaseMessaging.onBackgroundMessage(casamaBackgroundMessage);
      final messaging = FirebaseMessaging.instance;
      final status = (await messaging.getNotificationSettings()).authorizationStatus;
      if (status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional) {
        await _register(messaging);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final snoozed = DateTime.tryParse(prefs.getString(_snoozedKey) ?? '');
      final snoozeOver = snoozed == null || snoozed.isBefore(DateTime.now());
      // On the web, Chrome's answer is the only "asked". A Turn on click that never
      // produced a prompt used to set the flag and then hide the page for good.
      // A Block from Chrome cannot be asked again from the page. Say so, unless they snoozed it.
      if (kIsWeb && status == AuthorizationStatus.denied && snoozeOver) {
        webBlocked.value = true;
        needsAsk.value = true;
        return;
      }
      final unanswered = kIsWeb ? status == AuthorizationStatus.notDetermined : prefs.getBool(_askedKey) != true;
      if (unanswered && snoozeOver) needsAsk.value = true;
    } catch (e) {
      // Push is best effort; the in-app inbox still has every notification.
      debugPrint('push registration failed: $e');
    }
  }

  /// "Turn on": the system prompt, then this device's push registration.
  ///
  /// On the web the prompt has to start inside the click (see [bindNotificationButton]).
  /// This waits for that answer. A dismissed prompt leaves the page up so Turn on
  /// can be tried again; Block remembers the choice.
  Future<bool> enable() async {
    if (kIsWeb) {
      try {
        final status = await takeWebNotificationPermission();
        Analytics.log('push_permission_result', {'result': status == 'granted' ? 'granted' : status == 'denied' ? 'denied' : 'dismissed'});
        if (status != 'granted') {
          if (status == 'denied') {
            webBlocked.value = true;
            (await SharedPreferences.getInstance()).setBool(_askedKey, true).ignore();
          }
          return false;
        }
        webBlocked.value = false;
        needsAsk.value = false;
        (await SharedPreferences.getInstance()).setBool(_askedKey, true).ignore();
        await _register(FirebaseMessaging.instance);
        return true;
      } catch (e) {
        debugPrint('push registration failed: $e');
        return false;
      }
    }
    needsAsk.value = false;
    try {
      (await SharedPreferences.getInstance()).setBool(_askedKey, true).ignore();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final denied = settings.authorizationStatus == AuthorizationStatus.denied;
      Analytics.log('push_permission_result', {'result': denied ? 'denied' : 'granted'});
      if (denied) return false;
      await _register(messaging);
      return true;
    } catch (e) {
      debugPrint('push registration failed: $e');
      return false;
    }
  }

  /// "Not now": asked again in a week.
  Future<void> snooze() async {
    needsAsk.value = false;
    Analytics.log('push_permission_result', {'result': 'snoozed'});
    try {
      await (await SharedPreferences.getInstance()).setString(_snoozedKey, DateTime.now().add(const Duration(days: 7)).toIso8601String());
    } catch (_) {}
  }

  Future<void> _register(FirebaseMessaging messaging) async {
    try {
      // The worker sends with FCM HTTP v1 `message.token`, so register the classic token
      // (firebase_messaging 17 deprecates it in favour of installation-ID direct send; see DECISIONS D-051).
      // ignore: deprecated_member_use
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? PushConfig.vapidKey : null,
        serviceWorkerScriptPath: PushConfig.messagingServiceWorkerPath,
      );
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

  /// What a notification was about, from its in-app link (never the link itself).
  @visibleForTesting
  static String pushKind(String? link) {
    if (link == null) return 'other';
    if (link.startsWith('/approvals')) return 'approval';
    if (link.contains('/call') || link.startsWith('/calls')) return 'call';
    if (link.contains('/runs/')) return 'run';
    if (link.startsWith('/inbox')) return 'checkin';
    if (link.contains('/chat')) return 'mention';
    return 'other';
  }

  void _open(RemoteMessage message) {
    final link = message.data['link'];
    Analytics.log('push_opened', {'kind': pushKind(link is String ? link : null)});
    final id = message.data['notification_id'];
    if (id is String && id.isNotEmpty) onOpened?.call(id);
    if (link is String && link.startsWith('/')) _openLink(link);
  }

  void dispose() {
    needsAsk.dispose();
    webBlocked.dispose();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
  }
}

/// Starts push once signed in; watched by the app root.
final pushProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(
    ref.watch(backendProvider),
    (link) => ref.read(routerProvider).go(link),
    onOpened: (id) => unawaited(ref.read(notificationsProvider.notifier).markRead(id).catchError((_) {})),
  );
  ref.onDispose(registrar.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true) unawaited(registrar.start());
  }, fireImmediately: true);
  return registrar;
});

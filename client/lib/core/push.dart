import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/voice/phone_calls.dart' show casamaBackgroundMessage;
import 'backend.dart';
import 'chat_focus.dart';
import 'desktop_notifications.dart';
import 'providers.dart';
import 'router.dart';
import 'timezone_sync.dart';
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
  // The web app's Google Analytics stream (D-397); only used when GA4 is on (see Telemetry.ga4On).
  static const _webMeasurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

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
    measurementId: kIsWeb && _webMeasurementId.isNotEmpty ? _webMeasurementId : null,
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

  /// Shows what came of an Approve or Deny tapped on a notification (D-325), once it's done.
  void Function(bool approved, Object? error)? onDecided;

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
      // Phone calls (D-135): on Android a call push rings even when the app is closed. On both
      // phones a call's cancel stops a ring another device took (D-425; iPhones: in the app's isolate).
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        FirebaseMessaging.onBackgroundMessage(casamaBackgroundMessage);
      }
      final messaging = FirebaseMessaging.instance;
      await _listenForTaps(messaging);
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

  /// Every sign-in, not just the first: another account signing in after a sign-out, without the
  /// app restarting, registers this device again so its pushes go to whoever is signed in now
  /// (D-437).
  Future<void> signedIn() async {
    if (!_started) return start();
    try {
      final messaging = FirebaseMessaging.instance;
      final status = (await messaging.getNotificationSettings()).authorizationStatus;
      if (status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional) {
        await _register(messaging);
      }
    } catch (e) {
      debugPrint('push registration failed: $e');
    }
  }

  /// This phone's Firebase token without asking for notification permission (D-324): a Live
  /// Activity's server updates need it beside the activity's own token, even with alerts off.
  /// Null when push isn't set up or the phone has no token yet.
  Future<String?> silentToken() async {
    if (kIsWeb || !PushConfig.enabled) return null;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: PushConfig.options);
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
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

  var _listening = false;

  /// [_register] runs on every sign-in; one token refresh listener is enough.
  var _refreshing = false;

  /// Taps first, before the token: getting one waits on APNs and the network and can fail (no APNs
  /// token yet on an iPhone's first launch, offline, a server error), and a tap that started the app
  /// has to open its screen even then.
  Future<void> _listenForTaps(FirebaseMessaging messaging) async {
    if (_listening) return;
    _listening = true;
    try {
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
      // Android draws approval pushes itself (D-325): a tapped Approve or Deny comes from there.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        notificationsChannel.setMethodCallHandler((call) async {
          if (call.method == 'action' && call.arguments is Map) _nativeAction(Map<String, dynamic>.from(call.arguments as Map));
          return null;
        });
        final pending = await notificationsChannel.invokeMethod<Map<Object?, Object?>>('takeAction').catchError((_) => null);
        if (pending != null) _nativeAction(Map<String, dynamic>.from(pending));
      }
    } catch (e) {
      debugPrint('push taps unavailable: $e');
    }
  }

  Future<void> _register(FirebaseMessaging messaging) async {
    await _listenForTaps(messaging);
    try {
      // The worker sends with FCM HTTP v1 `message.token`, so register the classic token
      // (firebase_messaging 17 deprecates it in favour of installation-ID direct send; see DECISIONS D-051).
      // ignore: deprecated_member_use
      final token = await messaging.getToken(
        vapidKey: kIsWeb ? PushConfig.vapidKey : null,
        serviceWorkerScriptPath: PushConfig.messagingServiceWorkerPath,
      );
      // Phones and Macs: with the app open, the in-app banner (from the live inbox) shows what
      // arrives, never the system one on top of it (D-325). The badge still updates.
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
        await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);
      }
      if (token != null) await _backend.registerDevice(_platform(), token);
      if (!_refreshing) {
        _refreshing = true;
        // ignore: deprecated_member_use
        _subs.add(messaging.onTokenRefresh.listen((t) => _backend.registerDevice(_platform(), t)));
      }
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
    if (link.contains('/chat') && link.contains('c=')) return 'reply';
    if (link.contains('/chat')) return 'mention';
    return 'other';
  }

  void _open(RemoteMessage message) {
    final link = message.data['link'];
    final kind = message.data['kind'];
    Analytics.log('push_opened', {'kind': kind == 'suggestion' || kind == 'reply' ? kind : pushKind(link is String ? link : null)});
    final id = message.data['notification_id'];
    if (id is String && id.isNotEmpty) onOpened?.call(id);
    final decision = approvalDecision(message.data, message.actionIdentifier);
    if (decision != null) unawaited(_decide(decision.$1, decision.$2));
    final target = openTarget(message.data, message.actionIdentifier);
    if (target != null) _openLink(target);
  }

  /// Approve or Deny tapped on an Android approval notification the app drew itself.
  void _nativeAction(Map<String, dynamic> data) {
    final id = data['notification_id'];
    if (id is String && id.isNotEmpty) onOpened?.call(id);
    final action = data['action'];
    final decision = approvalDecision(data, action is String ? action : null);
    if (decision != null) unawaited(_decide(decision.$1, decision.$2));
    final target = openTarget(data, action is String ? action : null);
    if (target != null) _openLink(target);
  }

  Future<void> _decide(String approvalId, bool approve) async {
    try {
      await _backend.decideApproval(approvalId, approve: approve);
      onDecided?.call(approve, null);
    } catch (e) {
      // Already answered elsewhere, expired, or offline: the chat card or approval screen it
      // opens says which.
      onDecided?.call(approve, e);
    }
  }

  /// The approval an Approve or Deny button answers (iOS APPROVAL category, Android buttons,
  /// D-325), or null for any other tap. A high-risk approval never has these buttons.
  @visibleForTesting
  static (String, bool)? approvalDecision(Map<String, dynamic> data, String? actionIdentifier) {
    if (actionIdentifier != approvalApprove && actionIdentifier != approvalDeny) return null;
    final id = data['approval_id'];
    if (id is! String || id.isEmpty || data['risk'] == 'high') return null;
    return (id, actionIdentifier == approvalApprove);
  }

  /// Where a tapped push goes. "Do it" on a suggestion (the iOS SUGGESTION category's `accept`
  /// action, D-247) accepts it; "Not now" never opens the app; anything else follows its link.
  @visibleForTesting
  static String? openTarget(Map<String, dynamic> data, String? actionIdentifier) {
    final suggestion = data['suggestion_id'];
    if (actionIdentifier == suggestionAccept && suggestion is String && suggestion.isNotEmpty) {
      final bot = data['bot_id'];
      return '/suggestions/${Uri.encodeComponent(suggestion)}/accept${bot is String && bot.isNotEmpty ? '?bot=${Uri.encodeQueryComponent(bot)}' : ''}';
    }
    final approval = data['approval_id'];
    if (approval is String && approval.isNotEmpty) {
      // An approval asked in a chat opens that chat, where its card waits (and shows the answer
      // an Approve or Deny button gave). One with no chat (a routine) opens the approval screen.
      final bot = data['bot_id'];
      final conversation = data['conversation_id'];
      if (bot is String && bot.isNotEmpty && conversation is String && conversation.isNotEmpty) {
        return '/bots/${Uri.encodeComponent(bot)}/chat?c=${Uri.encodeQueryComponent(conversation)}';
      }
      if (actionIdentifier == approvalApprove || actionIdentifier == approvalDeny) return '/approvals/${Uri.encodeComponent(approval)}';
    }
    final link = data['link'];
    // Nothing to open (a push from a server that set no link): the inbox has the notification.
    if (link == null) return '/inbox';
    if (link is! String || !link.startsWith('/') || link.startsWith('//')) return null;
    // A bot's chat with no conversation named opens whichever one was open or newest; the push
    // names the one it's about (older servers sent suggestions and check-ins this way).
    final conversation = data['conversation_id'];
    final uri = Uri.tryParse(link);
    if (uri != null &&
        conversation is String &&
        conversation.isNotEmpty &&
        RegExp(r'^/bots/[^/]+/chat$').hasMatch(uri.path) &&
        !uri.queryParameters.containsKey('c')) {
      return uri.replace(queryParameters: {...uri.queryParameters, 'c': conversation}).toString();
    }
    return link;
  }

  /// The "Do it" action on suggestion notifications (iOS category and Android buttons, D-247).
  static const suggestionAccept = 'accept';

  /// The Approve and Deny actions on approval notifications (iOS APPROVAL category and Android
  /// buttons, D-325).
  static const approvalApprove = 'approve';
  static const approvalDeny = 'deny';

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
  // The approval screen the button opened shows the answer; refresh the lists behind it.
  registrar.onDecided = (_, _) => ref.invalidate(approvalsProvider);
  ref.onDispose(registrar.dispose);
  // The profile's timezone follows this device (D-250); kept alive here, with push, for the
  // app's lifetime.
  ref.listen(timezoneSyncProvider, (_, _) {});
  // Windows and Linux draw system notifications from the live inbox (D-325).
  ref.listen(desktopNotificationsProvider, (_, _) {});
  // The iPhone's app icon badge follows the inbox count (D-325); the Mac's dock badge already
  // does (mac_bridge.dart), and Android launchers count notifications on screen.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    ref.listen<int>(inboxBadgeProvider, (_, count) => unawaited(notificationsChannel.invokeMethod('badge', {'count': count}).catchError((_) => null)), fireImmediately: true);
  }
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true) unawaited(registrar.signedIn());
  }, fireImmediately: true);
  return registrar;
});

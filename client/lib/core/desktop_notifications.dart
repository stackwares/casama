import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications_linux/flutter_local_notifications_linux.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'backend.dart';
import 'chat_focus.dart';
import 'providers.dart';
import 'router.dart';

/// System notifications on Windows and Linux (D-325). Neither has Firebase Messaging, so while
/// Casama runs (its window open or in the tray) it draws what the live inbox brings: the same
/// rows, words and links a phone gets as pushes. Only rows the server pushed (`push_status` sent),
/// never a reply to the chat on screen, and only while the window isn't in front (then the in-app
/// banner shows it instead).
class DesktopNotifier {
  DesktopNotifier(this._open, this._chatFocus);

  final void Function(String link) _open;
  final ChatFocusReporter _chatFocus;
  final _shown = <String>{};
  bool _ready = false;
  int _next = 1;
  final _links = <int, String>{};

  static bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

  /// Windows' toast registration: Casama's app id and a fixed activation GUID.
  static const windowsAppId = 'Stackwares.Casama.Desktop';
  static const windowsGuid = '6f6d2b51-3c0e-4c1a-9a7e-2f5b8d3c4e71';

  final _windows = defaultTargetPlatform == TargetPlatform.windows && !kIsWeb ? FlutterLocalNotificationsWindows() : null;
  final _linux = defaultTargetPlatform == TargetPlatform.linux && !kIsWeb ? LinuxFlutterLocalNotificationsPlugin() : null;

  Future<void> start() async {
    if (!supported || _ready) return;
    try {
      if (_windows != null) {
        _ready = await _windows.initialize(
          settings: const WindowsInitializationSettings(appName: 'Casama', appUserModelId: windowsAppId, guid: windowsGuid),
          onDidReceiveNotificationResponse: _tapped,
        );
      } else if (_linux != null) {
        _ready =
            await _linux.initialize(
              settings: const LinuxInitializationSettings(defaultActionName: 'Open'),
              onDidReceiveNotificationResponse: _tapped,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('desktop notifications unavailable: $e');
    }
  }

  /// Whether [n] becomes a system notification now.
  @visibleForTesting
  static bool shouldShow(NotificationView n, {required bool windowInFront, String? chatOnScreen}) {
    if (n.readAt != null || n.kind == 'call') return false;
    // Rows from a server before D-325 have no push_status: treat them as sent.
    if (n.pushStatus != null && n.pushStatus != 'sent') return false;
    if (windowInFront) return false;
    if (n.isReply && n.conversationId != null && n.conversationId == chatOnScreen) return false;
    return true;
  }

  Future<void> handle(NotificationView n) async {
    if (!_ready || !_shown.add(n.id)) return;
    final front = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!shouldShow(n, windowInFront: front, chatOnScreen: _chatFocus.conversation)) return;
    final id = _next++;
    final link = n.link;
    if (link != null && link.startsWith('/')) _links[id] = link;
    try {
      if (_windows != null) {
        await _windows.show(id: id, title: n.title, body: n.body, payload: link);
      } else {
        await _linux?.show(id: id, title: n.title, body: n.body, payload: link);
      }
    } catch (e) {
      debugPrint('desktop notification failed: $e');
    }
  }

  void _tapped(NotificationResponse r) {
    final link = r.payload ?? (r.id == null ? null : _links[r.id]);
    final w = WindowManager.instance.getCurrent();
    w?.show();
    w?.focus();
    _open(link != null && link.startsWith('/') ? link : '/inbox');
  }
}

/// Started with push on desktop (kept alive by [pushProvider]); feeds from the live inbox.
final desktopNotificationsProvider = Provider<DesktopNotifier?>((ref) {
  if (!DesktopNotifier.supported) return null;
  final notifier = DesktopNotifier((link) => ref.read(routerProvider).go(link), ref.watch(chatFocusProvider));
  if (ref.watch(signedInProvider).value != true) return notifier;
  unawaited(notifier.start());
  final sub = ref.watch(backendProvider).watchNotifications().listen((n) => unawaited(notifier.handle(n)));
  ref.onDispose(sub.cancel);
  return notifier;
});

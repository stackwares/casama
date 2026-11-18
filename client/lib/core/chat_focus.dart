import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';
import 'providers.dart';

/// Tells the server which chat is on screen on this install (D-325), so a reply to it doesn't
/// push to any of the person's devices, and clears that chat's notifications from the system.
///
/// The chat screen calls [open] and [close]. While a chat is open and the app is in front, the
/// focus is sent again every [refresh]; the server ignores one older than 45 seconds, so a killed
/// app never silences replies for long. Going to the background sends null at once.
class ChatFocusReporter with WidgetsBindingObserver {
  ChatFocusReporter(this._backend, {this.prefs}) {
    WidgetsBinding.instance.addObserver(this);
    _foreground = _isForeground(WidgetsBinding.instance.lifecycleState);
  }

  final Backend _backend;

  /// Where the install's id is kept (tests pass their own).
  SharedPreferences? prefs;

  static const refresh = Duration(seconds: 30);
  static const _clientKey = 'push.client_id';

  String? _conversation;
  bool _foreground = true;
  String? _sent;
  bool _sentOnce = false;
  Timer? _timer;
  bool _disposed = false;

  /// The chat on screen, as last reported by the chat screen.
  String? get conversation => _conversation;

  /// What the server should see now: the open chat while the app is in front.
  @visibleForTesting
  String? get focus => _foreground ? _conversation : null;

  void open(String? conversationId) {
    if (conversationId == _conversation) return;
    _conversation = conversationId;
    if (conversationId != null) unawaited(clearSystemNotifications(conversationId));
    _sync();
  }

  /// Only clears when [conversationId] is still the open one (another chat may have opened first).
  void close(String? conversationId) {
    if (conversationId != _conversation) return;
    _conversation = null;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final front = _isForeground(state);
    if (front == _foreground) return;
    _foreground = front;
    if (front && _conversation != null) unawaited(clearSystemNotifications(_conversation!));
    _sync();
  }

  static bool _isForeground(AppLifecycleState? state) => state == null || state == AppLifecycleState.resumed;

  void _sync() {
    if (_disposed) return;
    final want = focus;
    _timer?.cancel();
    _timer = null;
    if (want != null) _timer = Timer.periodic(refresh, (_) => unawaited(_send(want, force: true)));
    unawaited(_send(want));
  }

  Future<void> _send(String? conversationId, {bool force = false}) async {
    // Nothing to clear on a fresh start: an install that never reported has no row.
    if (!force && _sentOnce && conversationId == _sent) return;
    if (!force && !_sentOnce && conversationId == null) return;
    _sent = conversationId;
    _sentOnce = true;
    try {
      await _backend.setChatFocus(await clientId(), conversationId);
    } catch (e) {
      // Best effort: a server from before D-325 has no chat_focus table, and the push still comes.
      debugPrint('chat focus not sent: $e');
    }
  }

  /// A random id for this install, kept across launches.
  Future<String> clientId() async {
    final store = prefs ??= await SharedPreferences.getInstance();
    final existing = store.getString(_clientKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = [for (var i = 0; i < 16; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
    await store.setString(_clientKey, id);
    return id;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// The native side of notifications (D-325): clearing a chat's notifications, the iPhone badge,
/// and approval buttons tapped on Android. Missing on platforms without it.
const notificationsChannel = MethodChannel('casama/notifications');

/// Removes this conversation's reply notifications from the notification centre (Android: by
/// tag; iPhone and Mac: by thread).
Future<void> clearSystemNotifications(String conversationId) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS) return;
  try {
    await notificationsChannel.invokeMethod('clear', {'conversation_id': conversationId, 'tag': 'reply-$conversationId'});
  } catch (_) {
    // Older native code without the channel: nothing to clear.
  }
}

final chatFocusProvider = Provider<ChatFocusReporter>((ref) {
  final reporter = ChatFocusReporter(ref.watch(backendProvider));
  ref.onDispose(reporter.dispose);
  return reporter;
});

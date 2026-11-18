import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_activities/live_activities.dart';

import '../../core/mobile_extras.dart' show appGroupId;
import '../../l10n/generated/app_localizations.dart';
import 'active_call.dart';
import 'call_bubble.dart' show callClock;
import 'call_system.dart';

/// A live call as glanceable surfaces outside the app's window show it (D-327 §9): the iPhone's
/// Live Activity (lock screen and Dynamic Island) and the Mac's menu bar, later the Mac notch
/// (D-324's island). Everything they need to draw, nothing they decide.
@immutable
class CallGlance {
  const CallGlance({
    required this.id,
    required this.botId,
    required this.botName,
    this.botAvatar,
    required this.link,
    this.since,
    this.muted = false,
    this.held = false,
    this.reconnecting = false,
    this.doing,
    this.needsYou = false,
  });

  /// The call's server record, or its bot while it connects.
  final String id;
  final String botId;
  final String botName;

  /// The bot's icon as it stores it (`mascot:<name>`; null for its initials).
  final String? botAvatar;

  /// The call screen's route.
  final String link;

  /// When the call went live (null while connecting): native timers count from it.
  final DateTime? since;
  final bool muted;
  final bool held;
  final bool reconnecting;

  /// The job the bot is on, if any.
  final String? doing;

  /// A job waits for the person (an approval or a takeover).
  final bool needsYou;

  /// The one line under the bot's name.
  String status(AppLocalizations l10n) {
    final job = doing;
    if (since == null) return l10n.callConnecting;
    if (reconnecting) return l10n.callReconnecting;
    if (held) return l10n.callOnHold;
    if (job != null && needsYou) return l10n.callJobNeedsYou(job);
    if (job != null) return l10n.callJobStrip(job);
    if (muted) return l10n.callNotificationMuted;
    return l10n.callNotificationLive;
  }

  /// For the island's feed (D-324) once it carries the call.
  Map<String, Object?> toJson(AppLocalizations l10n) => {
    'id': id,
    'bot_id': botId,
    'bot': botName,
    'link': link,
    'since': since?.millisecondsSinceEpoch,
    'muted': muted,
    'held': held,
    'reconnecting': reconnecting,
    'doing': doing,
    'needs_you': needsYou,
    'status': status(l10n),
  };

  @override
  bool operator ==(Object other) =>
      other is CallGlance &&
      other.id == id &&
      other.botId == botId &&
      other.botName == botName &&
      other.botAvatar == botAvatar &&
      other.link == link &&
      other.since == since &&
      other.muted == muted &&
      other.held == held &&
      other.reconnecting == reconnecting &&
      other.doing == doing &&
      other.needsYou == needsYou;

  @override
  int get hashCode => Object.hash(
    id,
    botId,
    botName,
    botAvatar,
    link,
    since,
    muted,
    held,
    reconnecting,
    doing,
    needsYou,
  );
}

/// The glance for [c], or null when there's no call going on.
CallGlance? callGlanceOf(CallController? c) {
  if (c == null || c.over || c.ending) return null;
  final job = c.activeJob;
  return CallGlance(
    id: c.liveCallId ?? c.botId,
    botId: c.botId,
    botName: c.botName,
    botAvatar: c.botAvatar,
    link: callPath(c),
    since: c.connectedAt,
    muted: c.muted,
    held: c.held,
    reconnecting: c.reconnecting,
    doing: job?.title,
    needsYou:
        job != null &&
        (job.state == CallJobState.needsApproval ||
            job.state == CallJobState.needsTakeover),
  );
}

/// The call going on, as surfaces outside the window show it. Changes only when what they show
/// changes (not on every word said).
class CallGlanceNotifier extends Notifier<CallGlance?> {
  @override
  CallGlance? build() {
    final active = ref.watch(activeCallProvider);
    var closed = false;
    void sync() {
      // The call notifies while widgets build: update just after.
      scheduleMicrotask(() {
        if (closed) return;
        final next = callGlanceOf(active.live);
        if (next != state) state = next;
      });
    }

    active.addListener(sync);
    ref.onDispose(() {
      closed = true;
      active.removeListener(sync);
    });
    return callGlanceOf(active.live);
  }
}

final callGlanceProvider = NotifierProvider<CallGlanceNotifier, CallGlance?>(
  CallGlanceNotifier.new,
);

/// One glanceable surface for the call (the iPhone's Live Activity; the island later).
abstract class CallGlanceSurface {
  /// Shows [glance], or updates what's shown.
  Future<void> show(CallGlance glance);

  /// The call is over.
  Future<void> hide();

  /// Buttons pressed on the surface.
  Stream<CallSystemAction> get actions;

  void dispose();
}

class NoCallGlanceSurface implements CallGlanceSurface {
  @override
  Future<void> show(CallGlance glance) async {}

  @override
  Future<void> hide() async {}

  @override
  Stream<CallSystemAction> get actions => const Stream.empty();

  @override
  void dispose() {}
}

/// The call on the iPhone's lock screen and Dynamic Island: the bot, the timer, the job and, on
/// iOS 17 and later, Mute and End Call (`RunActivityWidget` in CasamaWidgets.swift draws it when
/// `kind` is `call`). The buttons come back over `casama/call_glance` (AppDelegate.swift).
class LiveActivityCallGlance implements CallGlanceSurface {
  LiveActivityCallGlance({LiveActivities? plugin, MethodChannel? channel})
    : _plugin = plugin ?? LiveActivities(),
      _channel = channel ?? const MethodChannel('casama/call_glance') {
    _channel.setMethodCallHandler((m) async {
      if (m.method != 'action') return;
      final action = switch ((m.arguments as Map?)?['action']) {
        'mute' => CallSystemAction.mute,
        'unmute' => CallSystemAction.unmute,
        'end' => CallSystemAction.end,
        'open' => CallSystemAction.open,
        _ => null,
      };
      if (action != null) _actions.add(action);
    });
  }

  final LiveActivities _plugin;
  final MethodChannel _channel;
  final _actions = StreamController<CallSystemAction>.broadcast();
  bool? _ready;
  String? _shown;

  @override
  Stream<CallSystemAction> get actions => _actions.stream;

  Future<bool> _init() async {
    final ready = _ready;
    if (ready != null) return ready;
    try {
      await _plugin.init(appGroupId: appGroupId, urlScheme: 'casama');
      _ready = await _plugin.areActivitiesEnabled();
    } catch (e) {
      debugPrint('call live activity unavailable: $e');
      _ready = false;
    }
    return _ready!;
  }

  /// What the widget reads, all strings (the App Group stores them as they are).
  static Map<String, dynamic> data(CallGlance g, AppLocalizations l10n) => {
    'kind': 'call',
    'bot': g.botName,
    'bot_id': g.botId,
    'avatar': g.botAvatar ?? '',
    'step': g.status(l10n),
    'since': g.since == null
        ? ''
        : (g.since!.millisecondsSinceEpoch / 1000).toStringAsFixed(0),
    'muted': g.muted ? '1' : '0',
    'link': 'casama://app${g.link}',
    'mute': l10n.mute,
    'unmute': l10n.unmute,
    'end': l10n.callEndCall,
  };

  @override
  Future<void> show(CallGlance glance) async {
    if (!await _init()) return;
    final d = data(glance, callStrings());
    try {
      if (_shown == glance.id) {
        await _plugin.updateActivity(glance.id, d);
        return;
      }
      // The id changes once, when the call gets its server record: one activity per call.
      final old = _shown;
      _shown = glance.id;
      if (old != null) await _plugin.endActivity(old);
      await _plugin.createActivity(
        glance.id,
        d,
        // The call lives in the app: it ends with it.
        removeWhenAppIsKilled: true,
        iOSEnableRemoteUpdates: false,
      );
    } catch (e) {
      debugPrint('call live activity failed: $e');
    }
  }

  @override
  Future<void> hide() async {
    final id = _shown;
    _shown = null;
    if (id == null || _ready != true) return;
    try {
      await _plugin.endActivity(id);
    } catch (e) {
      debugPrint('call live activity not ended: $e');
    }
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_actions.close());
  }
}

/// The surface for this platform (iPhone: the Live Activity; elsewhere none yet).
CallGlanceSurface deviceCallGlanceSurface() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
    ? LiveActivityCallGlance()
    : NoCallGlanceSurface();

final callGlanceSurfaceProvider = Provider<CallGlanceSurface>((ref) {
  final s = deviceCallGlanceSurface();
  ref.onDispose(s.dispose);
  return s;
});

/// Keeps the glanceable surfaces showing the call, and carries out their buttons. Kept for the
/// app's life (app.dart).
final callGlanceSyncProvider = Provider<void>((ref) {
  final surface = ref.watch(callGlanceSurfaceProvider);
  final active = ref.watch(activeCallProvider);
  final sub = surface.actions.listen(active.act);
  ref.onDispose(sub.cancel);
  // One change at a time, in order (create before update, update before end).
  var queue = Future<void>.value();
  void apply(CallGlance? g) {
    queue = queue.then((_) => g == null ? surface.hide() : surface.show(g));
  }

  ref.listen(callGlanceProvider, (_, g) => apply(g), fireImmediately: true);
});

/// The Mac's menu bar during a call (D-327 §9): the status line, Mute or Unmute, End Call and
/// Show Call, above the menu's usual items. Pure, for tests; DesktopShell draws it.
class CallMenu {
  const CallMenu({required this.status, required this.items});

  /// "Ava · Working on: book the flight".
  final String status;

  /// Each button's label and what it does.
  final List<(String, CallSystemAction)> items;
}

CallMenu callMenu(CallGlance g, AppLocalizations l10n) => CallMenu(
  status: '${g.botName} · ${g.status(l10n)}',
  items: [
    if (g.muted)
      (l10n.unmute, CallSystemAction.unmute)
    else
      (l10n.mute, CallSystemAction.mute),
    (l10n.callEndCall, CallSystemAction.end),
    (l10n.callMenuShow, CallSystemAction.open),
  ],
);

/// The menu bar's title during a call: "● Ava 3:12", the timer counting from [now].
String callMenuTitle(CallGlance g, DateTime now) {
  final since = g.since;
  if (since == null) return '● ${g.botName}';
  return '● ${g.botName} ${callClock(now.difference(since))}';
}

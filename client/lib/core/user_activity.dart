import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Activity-based keep-awake (D-195, refines D-178). A computer sleeps after 5 idle minutes
/// (`IDLE_SLEEP_MS` on the server); an open live view or terminal keeps it awake only while a
/// person is actually there. The server touches the computer at most once per 30 s per connection
/// (`TOUCH_THROTTLE_MS` in apps/server/src/api/keep-awake.ts).
abstract final class KeepAwake {
  /// How often the live view and terminal send `{"event":"presence"}` while the person is there.
  static const presenceInterval = Duration(seconds: 60);

  /// The person counts as there while they touched the app (pointer, key or scroll) this recently
  /// and the window is visible and focused.
  static const recentInput = Duration(minutes: 3);

  /// The live view asks "Still watching?" after this long without input, unless a bot is working.
  /// Presence stops 3 minutes after the last input and an idle computer sleeps 5 minutes after
  /// that, so asking at 5 (paused at 6) comes before the computer would drop the stream.
  static const stillWatchingAfter = Duration(minutes: 5);

  /// Unanswered for this long, the live view closes its stream ("Paused to save power").
  static const answerWindow = Duration(seconds: 60);
}

/// Input anywhere in the app: pointer down, move, hover or scroll, and hardware keys. Listeners
/// are told on every input; the global hooks are installed only while someone listens.
class UserActivity {
  UserActivity._();
  static final instance = UserActivity._();

  final _listeners = <VoidCallback>{};

  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      HardwareKeyboard.instance.addHandler(_onKey);
    }
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    if (!_listeners.remove(listener) || _listeners.isNotEmpty) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
  }

  /// Something the person did that the global hooks don't see (for example soft-keyboard typing).
  void mark() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void _onPointer(PointerEvent e) {
    if (e is PointerDownEvent || e is PointerMoveEvent || e is PointerHoverEvent || e is PointerSignalEvent || e is PointerPanZoomUpdateEvent) mark();
  }

  bool _onKey(KeyEvent e) {
    mark();
    return false;
  }

  /// The window is visible and focused (null before the first lifecycle report counts as visible).
  static bool get appVisible {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }
}

/// Whether the person gave input within [window]. Starts active: opening the screen took input.
/// [onQuiet] runs when the window passes without input, [onActive] when input returns.
class RecentInput {
  RecentInput(this.window, {this.onQuiet, this.onActive}) {
    UserActivity.instance.addListener(_input);
    _timer = Timer(window, _quiet);
  }

  final Duration window;
  final VoidCallback? onQuiet;
  final VoidCallback? onActive;
  Timer? _timer;
  var _active = true;

  bool get active => _active;

  void _input() {
    _timer?.cancel();
    _timer = Timer(window, _quiet);
    if (_active) return;
    _active = true;
    onActive?.call();
  }

  void _quiet() {
    _active = false;
    onQuiet?.call();
  }

  void dispose() {
    _timer?.cancel();
    UserActivity.instance.removeListener(_input);
  }
}

/// Calls [send] every [KeepAwake.presenceInterval] while the app is visible and focused and the
/// person touched it within [KeepAwake.recentInput].
class PresenceBeat {
  PresenceBeat(this.send) {
    _timer = Timer.periodic(KeepAwake.presenceInterval, (_) => beat());
  }

  final VoidCallback send;
  final _recent = RecentInput(KeepAwake.recentInput);
  Timer? _timer;

  void beat() {
    if (_recent.active && UserActivity.appVisible) send();
  }

  void dispose() {
    _timer?.cancel();
    _recent.dispose();
  }
}

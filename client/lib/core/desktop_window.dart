import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// The first window's size on [screen] (logical points): room for the sidebar (272), a comfortable
/// chat and the computer panel (420) side by side on common screens, while leaving the menu bar
/// and dock or taskbar visible. 1320 × 760 on a 1440 × 900 laptop, 1440 × 940 on a 1080p monitor.
Size defaultWindowSize(Size screen) {
  final width = math.min((screen.width - 120).clamp(960.0, 1440.0), screen.width - 40);
  final height = math.min((screen.height - 140).clamp(640.0, 960.0), screen.height - 80);
  return Size(math.max(width, 420), math.max(height, 560));
}

/// Smallest the window gets: below the tablet width the app switches to its phone layout.
const minimumWindowSize = Size(420, 560);

/// Where the frame's corner was and how big the content was. Not the frame's size: before the
/// window is shown GTK doesn't know its decorations yet, so a frame size set at startup became
/// the content's size and the window grew by its title bar every launch (Linux). The content
/// size and the frame position read back exactly what was set. (window.bounds held frame sizes.)
const _boundsKey = 'window.placement';

/// macOS sizes and remembers its window natively (MainFlutterWindow.swift: the screen's usable area
/// and frame autosave); this covers Windows and Linux.
bool get _isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

/// Sizes the main window: where it was last (if that still fits on a screen, maximized or not),
/// otherwise [defaultWindowSize] centered on the main screen. Then remembers moves and resizes.
Future<void> setUpDesktopWindow() async {
  if (!_isDesktop) return;
  try {
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    window.minimumSize = minimumWindowSize.toNative();
    final screens = [
      for (final d in PlatformDispatcher.instance.displays)
        if (d.devicePixelRatio > 0) Size(d.size.width / d.devicePixelRatio, d.size.height / d.devicePixelRatio),
    ];
    final main = screens.isEmpty ? const Size(1440, 900) : screens.first;
    final prefs = await SharedPreferences.getInstance();
    final saved = _decode(prefs.getString(_boundsKey));
    if (saved != null && saved.rect.width <= main.width + 1 && saved.rect.height <= main.height + 1) {
      // Off the main screen (a monitor since unplugged, say): same size, centered, never lost.
      final onMain = (Offset.zero & main).contains(saved.rect.center);
      window.contentSize = saved.rect.size.toNative();
      if (onMain) {
        window.position = saved.rect.topLeft.toNative();
      } else {
        window.center();
      }
      if (saved.maximized) window.maximize();
    } else {
      final size = defaultWindowSize(main);
      window.bounds = Rect.fromLTWH((main.width - size.width) / 2, (main.height - size.height) / 2, size.width, size.height).toNative();
    }
    // Remembered by checking every few seconds rather than through window events (their FFI
    // structs break release AOT builds).
    var last = '';
    Timer.periodic(const Duration(seconds: 3), (_) {
      try {
        if (window.isFullScreen || window.isMinimized) return;
        final maximized = window.isMaximized;
        final rect = maximized ? (saved?.rect ?? _placement(window)) : _placement(window);
        final value = jsonEncode({'x': rect.left, 'y': rect.top, 'w': rect.width, 'h': rect.height, 'max': maximized});
        if (value == last) return;
        last = value;
        unawaited(prefs.setString(_boundsKey, value));
      } catch (_) {}
    });
  } catch (e) {
    // The platform's own window size stays; nothing else depends on this.
    debugPrint('window setup: $e');
  }
}

/// The frame's corner and the content's size (see [_boundsKey]).
Rect _placement(Window window) => window.position.toOffset() & window.contentSize.toSize();

({Rect rect, bool maximized})? _decode(String? raw) {
  if (raw == null) return null;
  try {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final rect = Rect.fromLTWH((j['x'] as num).toDouble(), (j['y'] as num).toDouble(), (j['w'] as num).toDouble(), (j['h'] as num).toDouble());
    if (rect.width < minimumWindowSize.width || rect.height < minimumWindowSize.height) return null;
    return (rect: rect, maximized: j['max'] == true);
  } catch (_) {
    return null;
  }
}

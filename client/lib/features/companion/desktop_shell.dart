import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/linux_desktop_entry.dart';
import '../../core/router.dart';
import '../island/island_bridge.dart';
import '../island/island_feed.dart';
import '../island/island_tray.dart';
import '../desktop/desktop_context.dart';
import '../../core/analytics.dart';
import '../../core/nav.dart';
import '../voice/active_call.dart';
import '../voice/call_glance.dart';
import '../voice/call_system.dart';

bool get isDesktop =>
    !kIsWeb && const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

/// Desktop extras (Phase 6): a tray icon on Windows and Linux whose menu carries the island feed
/// (D-324, Phase 6: each run with Stop, Allow and Deny, Open; island_tray.dart), and a global
/// shortcut (Cmd/Ctrl+Shift+K) that opens the quick-ask window. During a live call (D-327 §9) the
/// menu starts with the call and the title counts it. On macOS the native menu bar item and the
/// notch take the tray's place (D-324, Island.swift), the call included. Best effort: failures
/// never block the app.
class DesktopShell {
  DesktopShell(this.ref);
  final Ref ref;
  TrayIcon? _tray;
  String? _lastMenu;
  AppLifecycleListener? _exitListener;

  static final quickAskHotKey = HotKey(
    key: PhysicalKeyboardKey.keyK,
    modifiers: [defaultTargetPlatform == TargetPlatform.macOS ? HotKeyModifier.meta : HotKeyModifier.control, HotKeyModifier.shift],
  );

  /// The live call, at the top of the menu while it goes on.
  CallGlance? _call;
  Timer? _callTimer;

  Future<void> start() async {
    if (!isDesktop) return;
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      _startTray();
      // The tray's native library frees leftover icons in a static destructor that runs after its
      // own tables are gone, so quitting with the icon still alive crashed (SIGSEGV) on Linux.
      // Closing the window asks the app first; free the icon then.
      _exitListener = AppLifecycleListener(
        onExitRequested: () async {
          _freeTray();
          return AppExitResponse.exit;
        },
      );
    }
    // Linux: the portal that grants the shortcut looks the app up by its desktop entry.
    await ensureLinuxDesktopEntry();
    try {
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(quickAskHotKey, keyDownHandler: (_) => openQuickAsk());
    } catch (e) {
      debugPrint('global shortcut unavailable: $e');
    }
  }

  void _startTray() {
    try {
      _tray = TrayIcon.create();
      final tray = _tray;
      if (tray != null) {
        tray.icon = ImageAsset.fromAsset('assets/tray_icon.png');
        tray.setTooltip('Casama');
        tray.setContextMenuTrigger(ContextMenuTrigger.clicked);
        _showFeed(ref.read(islandFeedProvider));
        tray.setVisible(true);
        ref.listen(islandFeedProvider, (_, feed) => _showFeed(feed));
      }
    } catch (e) {
      debugPrint('tray unavailable: $e');
    }
  }

  /// A call started, changed (mute, hold, the job) or ended (D-327 §9): the menu starts with it
  /// and the title counts it.
  void setCall(CallGlance? call) {
    _call = call;
    _showFeed(ref.read(islandFeedProvider));
    if (call == null) {
      _callTimer?.cancel();
      _callTimer = null;
      return;
    }
    _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _showCallTitle());
    _showCallTitle();
  }

  void _showCallTitle() {
    final call = _call;
    if (call == null) return;
    try {
      _tray?.setTitle(callMenuTitle(call, DateTime.now()));
    } catch (_) {}
  }

  /// Rebuilds the tray menu from the island feed (only when what it shows changed).
  void _showFeed(List<IslandItem> feed) {
    final tray = _tray;
    if (tray == null) return;
    final l10n = ref.read(islandL10nProvider);
    final entries = trayEntries(feed, l10n);
    final call = _call;
    final callItems = call == null ? null : callMenu(call, callStrings());
    final key = '${callItems?.status} ${callItems?.items}\n${entries.join('\n')}';
    if (key == _lastMenu) return;
    _lastMenu = key;
    try {
      final menu = Menu.create()!;
      void item(String label, {void Function()? onClick}) {
        final m = MenuItem.createWithLabelAndType(label, MenuItemType.normal)!;
        if (onClick == null) {
          m.isEnabled = false;
        } else {
          m.addListener((e) {
            if (e is MenuItemClickedEvent) onClick();
          });
        }
        menu.addItem(m);
      }

      // A live call comes first (D-327 §9).
      if (callItems != null) {
        item(callItems.status);
        for (final (label, action) in callItems.items) {
          item('    $label', onClick: () {
            if (action == CallSystemAction.open) showWindow();
            ref.read(activeCallProvider).act(action);
          });
        }
        menu.addSeparator();
      }
      for (final e in entries) {
        final action = e.action;
        if (action == null) {
          item(e.label);
        } else {
          item('    ${e.label}', onClick: () => _act(action));
        }
      }
      menu.addSeparator();
      item(l10n.islandOpenCasama, onClick: showWindow);
      item(l10n.islandQuickAsk, onClick: openQuickAsk);
      tray.setContextMenu(menu);
      tray.setTooltip(callItems?.status ?? trayTooltip(feed, l10n));
      // During a call the title is the call's (its timer, every second).
      if (call == null) tray.setTitle(trayTitle(feed, l10n));
    } catch (e) {
      debugPrint('tray menu failed: $e');
    }
  }

  /// A click in the tray menu: the same actions the Mac's notch sends. Open also brings the window
  /// forward, since the menu has no window of its own.
  void _act(Map<String, Object?> action) {
    final bridge = ref.read(islandBridgeProvider);
    if (bridge == null) return;
    if (action['kind'] == 'open') showWindow();
    unawaited(bridge.handle(MethodCall('action', action)));
  }

  /// Brings Casama's window forward.
  void showWindow() {
    final w = WindowManager.instance.getCurrent();
    w?.show();
    w?.focus();
  }

  void openQuickAsk() {
    Analytics.feature('desktop_hotkey');
    // Read what's in front (selection, window, tab) before Casama's window takes focus (D-152).
    unawaited(() async {
      final c = await ref.read(desktopContextReaderProvider).capture().timeout(const Duration(milliseconds: 2500), onTimeout: () => const DesktopContext()).catchError((_) => const DesktopContext());
      ref.read(pendingDesktopContextProvider.notifier).set(c.isEmpty ? null : c);
      showWindow();
      ref.read(routerProvider).pushOnce('/quick-ask');
    }());
  }

  /// Removes the tray icon and frees its native handle (hiding it alone left one per server change).
  void _freeTray() {
    final tray = _tray;
    _tray = null;
    _lastMenu = null;
    if (tray == null) return;
    try {
      tray.setVisible(false);
      tray.dispose();
    } catch (_) {}
  }

  Future<void> stop() async {
    _callTimer?.cancel();
    _callTimer = null;
    _exitListener?.dispose();
    _exitListener = null;
    _freeTray();
    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {}
  }
}

final desktopShellProvider = Provider<DesktopShell>((ref) {
  final shell = DesktopShell(ref);
  unawaited(
    shell.start().then((_) {
      // Gone already (a short-lived container): nothing to show.
      if (ref.mounted) shell.setCall(ref.read(callGlanceProvider));
    }),
  );
  ref.listen(callGlanceProvider, (_, call) => shell.setCall(call));
  ref.onDispose(() => unawaited(shell.stop()));
  return shell;
});

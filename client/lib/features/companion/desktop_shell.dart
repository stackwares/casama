import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/router.dart';
import 'companion.dart';
import '../desktop/desktop_context.dart';
import '../../core/analytics.dart';

bool get isDesktop =>
    !kIsWeb && const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

/// Desktop extras (Phase 6): a tray or menu-bar icon with status, and a global shortcut
/// (Cmd/Ctrl+Shift+K) that opens the quick-ask window. Best effort: failures never block the app.
class DesktopShell {
  DesktopShell(this.ref);
  final Ref ref;
  TrayIcon? _tray;
  MenuItem? _statusItem;

  static final quickAskHotKey = HotKey(
    key: PhysicalKeyboardKey.keyK,
    modifiers: [defaultTargetPlatform == TargetPlatform.macOS ? HotKeyModifier.meta : HotKeyModifier.control, HotKeyModifier.shift],
  );

  Future<void> start() async {
    if (!isDesktop) return;
    try {
      _tray = TrayIcon.create();
      final tray = _tray;
      if (tray != null) {
        tray.icon = ImageAsset.fromAsset('assets/tray_icon.png');
        tray.setTooltip('Casama');
        final menu = Menu.create()!;
        _statusItem = MenuItem.createWithLabelAndType('Casama: no bot is using this computer', MenuItemType.normal);
        _statusItem?.isEnabled = false;
        if (_statusItem != null) menu.addItem(_statusItem!);
        menu.addSeparator();
        void item(String label, void Function() onClick) {
          final m = MenuItem.createWithLabelAndType(label, MenuItemType.normal)!;
          m.addListener((e) {
            if (e is MenuItemClickedEvent) onClick();
          });
          menu.addItem(m);
        }

        item('Open Casama', _showWindow);
        item('Quick ask…', openQuickAsk);
        tray.setContextMenu(menu);
        tray.setContextMenuTrigger(ContextMenuTrigger.clicked);
        tray.setVisible(true);
        ref.read(companionProvider).activity.addListener(_onActivity);
      }
    } catch (e) {
      debugPrint('tray unavailable: $e');
    }
    try {
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(quickAskHotKey, keyDownHandler: (_) => openQuickAsk());
    } catch (e) {
      debugPrint('global shortcut unavailable: $e');
    }
  }

  void _onActivity() {
    final a = ref.read(companionProvider).activity.value;
    final label = a == null ? 'Casama: no bot is using this computer' : '${a.bot}: ${a.summary.isEmpty ? a.tool : a.summary}';
    _statusItem?.label = label;
    _tray?.setTooltip(a == null ? 'Casama' : label);
    _tray?.setTitle(a == null ? null : '● ${a.bot}');
  }

  void _showWindow() {
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
      _showWindow();
      ref.read(routerProvider).push('/quick-ask');
    }());
  }

  Future<void> stop() async {
    try {
      await hotKeyManager.unregisterAll();
      _tray?.setVisible(false);
    } catch (_) {}
  }
}

final desktopShellProvider = Provider<DesktopShell>((ref) {
  final shell = DesktopShell(ref);
  unawaited(shell.start());
  ref.onDispose(() => unawaited(shell.stop()));
  return shell;
});

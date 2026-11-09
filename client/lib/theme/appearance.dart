import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Theme mode and accent from Settings → Appearance, kept on this device.
class Appearance {
  const Appearance({this.mode = ThemeMode.system, this.accent = AppAccent.kasama});
  final ThemeMode mode;
  final AppAccent accent;

  Appearance copyWith({ThemeMode? mode, AppAccent? accent}) => Appearance(mode: mode ?? this.mode, accent: accent ?? this.accent);
}

class AppearanceNotifier extends Notifier<Appearance> {
  static const _modeKey = 'appearance.mode';
  static const _accentKey = 'appearance.accent';

  @override
  Appearance build() {
    _load();
    return const Appearance();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = ThemeMode.values.asNameMap()[prefs.getString(_modeKey)];
      final accent = AppAccent.values.asNameMap()[prefs.getString(_accentKey)];
      if (mode != null || accent != null) state = state.copyWith(mode: mode, accent: accent);
    } catch (_) {
      // Preferences unavailable (tests, a locked keychain): keep the defaults.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    try {
      await (await SharedPreferences.getInstance()).setString(_modeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setAccent(AppAccent accent) async {
    state = state.copyWith(accent: accent);
    try {
      await (await SharedPreferences.getInstance()).setString(_accentKey, accent.name);
    } catch (_) {}
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(AppearanceNotifier.new);

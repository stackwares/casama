import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'schemes.dart';
import 'wallpaper.dart';

/// Settings → Appearance: light or dark, the color scheme and the wallpaper, kept on this device.
@immutable
class Appearance {
  const Appearance({this.mode = ThemeMode.system, this.schemeId = 'kasama', this.wallpaper = const WallpaperSpec()});
  final ThemeMode mode;

  /// `kasama` or a FlexScheme name (see [themeChoices]).
  final String schemeId;
  final WallpaperSpec wallpaper;

  ThemeChoice get scheme => themeChoiceById(schemeId);

  Appearance copyWith({ThemeMode? mode, String? schemeId, WallpaperSpec? wallpaper}) =>
      Appearance(mode: mode ?? this.mode, schemeId: schemeId ?? this.schemeId, wallpaper: wallpaper ?? this.wallpaper);
}

class AppearanceNotifier extends Notifier<Appearance> {
  static const _modeKey = 'appearance.mode';
  static const _schemeKey = 'appearance.scheme';
  static const _patternKey = 'appearance.wallpaper.pattern';
  static const _paletteKey = 'appearance.wallpaper.palette';
  static const _intensityKey = 'appearance.wallpaper.intensity';
  static const _everywhereKey = 'appearance.wallpaper.everywhere';

  @override
  Appearance build() {
    _load();
    return const Appearance();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final defaults = const WallpaperSpec();
      state = Appearance(
        mode: ThemeMode.values.asNameMap()[p.getString(_modeKey)] ?? ThemeMode.system,
        schemeId: themeChoiceById(p.getString(_schemeKey) ?? 'kasama').id,
        wallpaper: WallpaperSpec(
          pattern: WallpaperPattern.values.asNameMap()[p.getString(_patternKey)] ?? defaults.pattern,
          palette: WallpaperPalette.values.asNameMap()[p.getString(_paletteKey)] ?? defaults.palette,
          intensity: p.getDouble(_intensityKey) ?? defaults.intensity,
          everywhere: p.getBool(_everywhereKey) ?? defaults.everywhere,
        ),
      );
    } catch (_) {
      // Preferences unavailable (tests, a locked keychain): keep the defaults.
    }
  }

  Future<void> _save(Future<void> Function(SharedPreferences p) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _save((p) => p.setString(_modeKey, mode.name));
  }

  Future<void> setScheme(String id) async {
    state = state.copyWith(schemeId: id);
    await _save((p) => p.setString(_schemeKey, id));
  }

  Future<void> setWallpaper(WallpaperSpec spec) async {
    state = state.copyWith(wallpaper: spec);
    await _save((p) async {
      await p.setString(_patternKey, spec.pattern.name);
      await p.setString(_paletteKey, spec.palette.name);
      await p.setDouble(_intensityKey, spec.intensity);
      await p.setBool(_everywhereKey, spec.everywhere);
    });
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(AppearanceNotifier.new);

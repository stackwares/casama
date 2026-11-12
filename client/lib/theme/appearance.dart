import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fonts.dart';
import 'schemes.dart';
import 'wallpaper.dart';

/// Settings → Appearance: light or dark, the color scheme, the fonts and the wallpaper, kept on
/// this device. A theme preset (see presets.dart) sets everything but [mode] at once.
@immutable
class Appearance {
  const Appearance({
    this.mode = ThemeMode.system,
    this.schemeId = 'casama',
    this.headingFont = defaultHeadingFont,
    this.bodyFont = defaultBodyFont,
    this.wallpaper = const WallpaperSpec(),
    this.fewerEffects = false,
  });
  final ThemeMode mode;

  /// `casama` or a FlexScheme name (see [themeChoices]).
  final String schemeId;

  /// Google Font family names for headlines and for everything else.
  final String headingFont;
  final String bodyFont;
  final WallpaperSpec wallpaper;

  /// No decorative motion: no celebration bursts, no bouncing tabs, no wiggling or animated bots
  /// (see [Effects]). The Plain theme turns it on.
  final bool fewerEffects;

  ThemeChoice get scheme => themeChoiceById(schemeId);

  Appearance copyWith({
    ThemeMode? mode,
    String? schemeId,
    String? headingFont,
    String? bodyFont,
    WallpaperSpec? wallpaper,
    bool? fewerEffects,
  }) => Appearance(
    mode: mode ?? this.mode,
    schemeId: schemeId ?? this.schemeId,
    headingFont: headingFont ?? this.headingFont,
    bodyFont: bodyFont ?? this.bodyFont,
    wallpaper: wallpaper ?? this.wallpaper,
    fewerEffects: fewerEffects ?? this.fewerEffects,
  );
}

class AppearanceNotifier extends Notifier<Appearance> {
  static const _modeKey = 'appearance.mode';
  static const _schemeKey = 'appearance.scheme';
  static const _headingKey = 'appearance.font.heading';
  static const _bodyKey = 'appearance.font.body';
  static const _wallpaperKey = 'appearance.wallpaper';
  static const _fewerEffectsKey = 'appearance.fewerEffects';
  static const _galleryKey = 'appearance.gallerySchemes';
  // Before wallpapers were saved as one JSON value.
  static const _patternKey = 'appearance.wallpaper.pattern';
  static const _paletteKey = 'appearance.wallpaper.palette';
  static const _intensityKey = 'appearance.wallpaper.intensity';
  static const _everywhereKey = 'appearance.wallpaper.everywhere';

  /// [initial]: the saved look when startup has already read it (see [readSaved]), so the first
  /// frame draws it instead of the defaults; null reads it here.
  AppearanceNotifier([this._initial]);
  final Appearance? _initial;

  @override
  Appearance build() {
    final initial = _initial;
    // Read before the app started, its gallery schemes already registered: nothing to load.
    if (initial != null) return initial;
    gallerySchemeChoices.clear();
    _load();
    return const Appearance();
  }

  /// The look saved on this device, with its gallery color schemes registered so its scheme
  /// resolves; null when preferences can't be read. Startup reads it while the app connects.
  static Future<Appearance?> readSaved() async {
    try {
      final p = await SharedPreferences.getInstance();
      _restoreGallery(p.getString(_galleryKey));
      return Appearance(
        mode:
            ThemeMode.values.asNameMap()[p.getString(_modeKey)] ??
            ThemeMode.system,
        schemeId: themeChoiceById(p.getString(_schemeKey) ?? 'casama').id,
        headingFont: p.getString(_headingKey) ?? defaultHeadingFont,
        bodyFont: p.getString(_bodyKey) ?? defaultBodyFont,
        wallpaper: _loadWallpaper(p),
        fewerEffects: p.getBool(_fewerEffectsKey) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final saved = await readSaved();
      if (saved != null) state = saved;
    } catch (_) {
      // Preferences unavailable (tests, a locked keychain): keep the defaults.
    }
  }

  static void _restoreGallery(String? raw) {
    gallerySchemeChoices.clear();
    if (raw == null) return;
    final map = jsonDecode(raw);
    if (map is! Map) return;
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final light = value['light'];
      final dark = value['dark'];
      final name = value['name'];
      if (light is! String || dark is! String || name is! String) continue;
      // Exact colors when they were saved (full gallery schemes keep theirs), else the seeds.
      final choice =
          galleryChoiceFromColors(
            id: '${entry.key}',
            name: name,
            light: value['lightColors'],
            dark: value['darkColors'],
          ) ??
          galleryChoiceFromSeeds(
            id: '${entry.key}',
            name: name,
            light: light,
            dark: dark,
          );
      gallerySchemeChoices[choice.id] = choice;
    }
  }

  String _galleryJson() => jsonEncode({
    for (final entry in gallerySchemeChoices.entries)
      entry.key: {
        'name': entry.value.name,
        'light': hexFromColor(entry.value.data.light.primary),
        'dark': hexFromColor(entry.value.data.dark.primary),
        'lightColors': schemeColorsToJson(entry.value.data.light),
        'darkColors': schemeColorsToJson(entry.value.data.dark),
      },
  });

  static WallpaperSpec _loadWallpaper(SharedPreferences p) {
    final json = p.getString(_wallpaperKey);
    if (json != null) {
      try {
        return WallpaperSpec.fromJson(
          (jsonDecode(json) as Map).cast<String, Object?>(),
        );
      } catch (_) {}
    }
    return WallpaperSpec.fromJson({
      'pattern': p.getString(_patternKey),
      'palette': p.getString(_paletteKey),
      'intensity': p.getDouble(_intensityKey),
      'everywhere': p.getBool(_everywhereKey),
    });
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

  Future<void> setFewerEffects(bool on) async {
    state = state.copyWith(fewerEffects: on);
    await _save((p) => p.setBool(_fewerEffectsKey, on));
  }

  Future<void> setScheme(String id) async {
    state = state.copyWith(schemeId: id);
    await _save((p) => p.setString(_schemeKey, id));
  }

  Future<void> setFonts({String? heading, String? body}) async {
    state = state.copyWith(headingFont: heading, bodyFont: body);
    await _save((p) async {
      await p.setString(_headingKey, state.headingFont);
      await p.setString(_bodyKey, state.bodyFont);
    });
  }

  Future<void> setWallpaper(WallpaperSpec spec) async {
    state = state.copyWith(wallpaper: spec);
    await _save((p) => p.setString(_wallpaperKey, jsonEncode(spec.toJson())));
  }

  /// Applies a gallery scheme and keeps its seeds so it survives a restart.
  Future<void> applyGalleryScheme(ThemeChoice choice) async {
    gallerySchemeChoices[choice.id] = choice;
    state = state.copyWith(schemeId: choice.id);
    await _save((p) async {
      await p.setString(_schemeKey, choice.id);
      await p.setString(_galleryKey, _galleryJson());
    });
  }

  /// A whole look at once, from a preset, a saved theme or the gallery. Light or dark and "Show in
  /// the whole app" stay as they are: they're this person's preferences, not part of a look. The
  /// look changes in one step, then it's saved. [gallery] is registered first when the scheme
  /// comes from the gallery.
  Future<void> apply({
    required String schemeId,
    ThemeChoice? gallery,
    required String headingFont,
    required String bodyFont,
    required WallpaperSpec wallpaper,
    bool? fewerEffects,
  }) async {
    if (gallery != null) gallerySchemeChoices[gallery.id] = gallery;
    wallpaper = wallpaper.copyWith(everywhere: state.wallpaper.everywhere);
    state = state.copyWith(
      schemeId: themeChoiceById(schemeId).id,
      headingFont: headingFont,
      bodyFont: bodyFont,
      wallpaper: wallpaper,
      fewerEffects: fewerEffects,
    );
    await _save((p) async {
      if (fewerEffects != null) await p.setBool(_fewerEffectsKey, fewerEffects);
      await p.setString(_schemeKey, state.schemeId);
      await p.setString(_headingKey, headingFont);
      await p.setString(_bodyKey, bodyFont);
      await p.setString(_wallpaperKey, jsonEncode(wallpaper.toJson()));
      if (gallerySchemeChoices.isNotEmpty) {
        await p.setString(_galleryKey, _galleryJson());
      }
    });
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

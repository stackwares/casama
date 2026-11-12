import 'dart:convert';

import 'package:flutter/material.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appearance.dart';
import 'fonts.dart';
import 'wallpaper.dart';

/// A whole look: color scheme, fonts and wallpaper (D-087). Built-in presets ship with the app;
/// people save their own and share them as a `casama-theme:` code, which is the format a theme
/// gallery would exchange later.
@immutable
class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.schemeId,
    this.headingFont = defaultHeadingFont,
    this.bodyFont = defaultBodyFont,
    this.wallpaper = const WallpaperSpec(),
    this.builtIn = false,
    this.fewerEffects = false,
  });

  final String id;
  final String name;
  final String schemeId;
  final String headingFont;
  final String bodyFont;
  final WallpaperSpec wallpaper;
  final bool builtIn;

  /// Whether it turns decorative motion off (see [Appearance.fewerEffects]).
  final bool fewerEffects;

  static const codePrefix = 'casama-theme:';

  factory ThemePreset.fromAppearance(Appearance a, {required String id, required String name}) =>
      ThemePreset(id: id, name: name, schemeId: a.schemeId, headingFont: a.headingFont, bodyFont: a.bodyFont, wallpaper: a.wallpaper, fewerEffects: a.fewerEffects);

  /// Whether [a] currently looks like this preset. "Show in the whole app" is a preference, not part
  /// of the look, so turning it off keeps the theme.
  bool matches(Appearance a) =>
      a.schemeId == schemeId &&
      a.headingFont == headingFont &&
      a.bodyFont == bodyFont &&
      a.wallpaper.copyWith(everywhere: true) == wallpaper.copyWith(everywhere: true);

  Map<String, Object?> toJson() => {
    'v': 1,
    'id': id,
    'name': name,
    'scheme': schemeId,
    'headingFont': headingFont,
    'bodyFont': bodyFont,
    'wallpaper': _shareableWallpaper.toJson(),
    if (fewerEffects) 'fewerEffects': true,
  };

  factory ThemePreset.fromJson(Map<String, Object?> j) => ThemePreset(
    id: j['id'] as String? ?? 'theme-${DateTime.now().millisecondsSinceEpoch}',
    name: (j['name'] as String? ?? 'Theme').trim().characters(60),
    schemeId: j['scheme'] as String? ?? 'casama',
    headingFont: j['headingFont'] as String? ?? defaultHeadingFont,
    bodyFont: j['bodyFont'] as String? ?? defaultBodyFont,
    wallpaper: j['wallpaper'] is Map ? WallpaperSpec.fromJson((j['wallpaper']! as Map).cast<String, Object?>()) : const WallpaperSpec(),
    fewerEffects: j['fewerEffects'] == true,
  );

  /// Local photos (files, data URIs) stay on this device; a shared theme only carries web photos.
  WallpaperSpec get _shareableWallpaper {
    final photo = wallpaper.photo;
    return photo != null && !photo.startsWith('https://') ? wallpaper.copyWith(clearPhoto: true) : wallpaper;
  }

  /// A short text people can paste into Settings → Appearance → Import a theme.
  String toCode() => codePrefix + base64Url.encode(utf8.encode(jsonEncode(toJson()..remove('id'))));

  /// The theme in [code], or null when it isn't one.
  static ThemePreset? fromCode(String code) {
    final text = code.trim();
    if (!text.startsWith(codePrefix)) return null;
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(text.substring(codePrefix.length)))));
      if (json is! Map) return null;
      return ThemePreset.fromJson({...json.cast<String, Object?>(), 'id': 'theme-${DateTime.now().millisecondsSinceEpoch}'});
    } catch (_) {
      return null;
    }
  }
}

extension on String {
  String characters(int max) => length <= max ? this : substring(0, max);
}

// The Plain theme: a flat surface with no pattern, neutral grays with one quiet accent, one clean
// sans-serif, and no decorative motion. Light or dark follows the app's own switch.
const _plainWallpaper = WallpaperSpec(pattern: WallpaperPattern.none, palette: WallpaperPalette.flat);

const builtInPresets = [
  ThemePreset(
    id: 'plain',
    name: 'Plain',
    schemeId: 'shadNeutral',
    headingFont: 'Google Sans',
    bodyFont: 'Google Sans',
    wallpaper: _plainWallpaper,
    fewerEffects: true,
    builtIn: true,
  ),
  ThemePreset(
    id: 'casama',
    name: 'Casama',
    schemeId: 'casama',
    // Exactly the out-of-the-box look, so a new install shows Casama in use rather than a custom
    // look. Clouds on the theme's own colors: orchid, rose and periwinkle with Casama's scheme.
    wallpaper: WallpaperSpec(),
    builtIn: true,
  ),
  ThemePreset(
    id: 'editorial',
    name: 'Editorial',
    schemeId: 'sepia',
    headingFont: 'Fraunces',
    bodyFont: 'Figtree',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.none, palette: WallpaperPalette.peach, intensity: 0.3),
    builtIn: true,
  ),
  ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    schemeId: 'blueWhale',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.sea, palette: WallpaperPalette.ocean),
    builtIn: true,
  ),
  ThemePreset(
    id: 'forest',
    name: 'Forest',
    schemeId: 'jungle',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.garden, palette: WallpaperPalette.forest),
    builtIn: true,
  ),
  ThemePreset(
    id: 'sakura',
    name: 'Sakura',
    schemeId: 'sakura',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.treats, palette: WallpaperPalette.cotton),
    builtIn: true,
  ),
  ThemePreset(
    id: 'sunset',
    name: 'Sunset',
    schemeId: 'mango',
    headingFont: 'Fraunces',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.doodles, palette: WallpaperPalette.sunset),
    builtIn: true,
  ),
  ThemePreset(
    id: 'cosmos',
    name: 'Cosmos',
    schemeId: 'deepPurple',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.space, palette: WallpaperPalette.lavender),
    builtIn: true,
  ),
  ThemePreset(
    id: 'graphite',
    name: 'Graphite',
    schemeId: 'shadZinc',
    headingFont: 'Google Sans',
    wallpaper: WallpaperSpec(pattern: WallpaperPattern.tech, palette: WallpaperPalette.graphite, intensity: 0.35),
    builtIn: true,
  ),
];

/// The themes this person saved, kept on this device.
class SavedThemesNotifier extends Notifier<List<ThemePreset>> {
  static const _key = 'appearance.savedThemes';

  @override
  List<ThemePreset> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      state = [for (final j in jsonDecode(raw) as List) ThemePreset.fromJson((j as Map).cast<String, Object?>())];
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      // Saved themes keep local photos too, unlike shared codes.
      final list = [for (final t in state) {...t.toJson(), 'wallpaper': t.wallpaper.toJson()}];
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(list));
    } catch (_) {}
  }

  Future<ThemePreset> save(String name, Appearance a) async {
    final preset = ThemePreset.fromAppearance(a, id: 'theme-${DateTime.now().millisecondsSinceEpoch}', name: name);
    state = [...state, preset];
    await _persist();
    return preset;
  }

  /// Adds [preset], or replaces the saved theme with the same id (using a gallery theme again).
  Future<void> add(ThemePreset preset) async {
    final i = state.indexWhere((t) => t.id == preset.id);
    state = i < 0 ? [...state, preset] : ([...state]..[i] = preset);
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [for (final t in state) if (t.id != id) t];
    await _persist();
  }
}

final savedThemesProvider = NotifierProvider<SavedThemesNotifier, List<ThemePreset>>(SavedThemesNotifier.new);

extension ApplyPreset on AppearanceNotifier {
  Future<void> applyPreset(ThemePreset p) => apply(
    schemeId: p.schemeId,
    headingFont: p.headingFont,
    bodyFont: p.bodyFont,
    wallpaper: p.wallpaper,
    fewerEffects: p.fewerEffects,
  );
}

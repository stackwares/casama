# Fix: Text opens in the default font, then swaps to the font picked in Settings

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/google-fonts-glitch
- **Needs new dependency**: none (`google_fonts` is already in `pubspec.yaml`)

## Why

Six families ship with the app. Any other Google Font someone picks in Settings → Themes/Fonts (Inter, Lora, Poppins…) comes through the `google_fonts` package, which loads the font file only when text first asks for it: from the network the first time, from disk on every cold start after that. Until it's loaded, text draws in a fallback font and then jumps to the chosen one. On top of that, the saved look is read from storage only after the app's first frame, so every cold start for anyone with a non-default look begins in Lato and Libre Baskerville and then morphs to their own. The article's fix is to load the fonts during the splash (here, the "Connecting…" screen) so text shows in the right typography from frame one.

## Where

```dart
// lib/theme/fonts.dart:65-74 — current (non-bundled families go through google_fonts; nothing waits for them)
/// [base] in [family]: bundled families by name (every weight available), others through
/// google_fonts (downloaded on first use). Unknown families fall back to [base].
TextStyle fontStyle(String family, TextStyle base) {
  if (bundledFonts.contains(family)) return base.copyWith(fontFamily: family);
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}
```

```dart
// lib/theme/app_theme.dart:255-264 — current (read only; this decides which weights must be preloaded)
  static TextTheme _typography(TextTheme theme, {required String heading, required String body}) {
    TextStyle? serif(TextStyle? style, double spacing) => style == null
        ? null
        : fontStyle(heading, style.copyWith(fontWeight: FontWeight.w600, letterSpacing: spacing, leadingDistribution: TextLeadingDistribution.even));
    TextStyle? sans(TextStyle? style, double spacing, [FontWeight? weight]) => style == null
        ? null
        : fontStyle(
            body,
            style.copyWith(letterSpacing: spacing, fontWeight: weight ?? style.fontWeight, leadingDistribution: TextLeadingDistribution.even),
          );
```

From the rest of `_typography` (lines 265-281), the theme loads exactly these upright (non-italic) styles:

- **Heading family** at weight 600: all display, headline and `titleLarge` styles.
- **Body family** at 400 (`bodyLarge`/`bodyMedium`/`bodySmall`, which keep Material 3's 400), 500 (`labelMedium`, `labelSmall`) and 600 (`titleMedium`, `titleSmall`, `labelLarge`).

`google_fonts` registers each weight as its own family (for example `Inter_600`). A widget that later does `copyWith(fontWeight: FontWeight.w800)` reuses that file, so no other weights are fetched. All four styles appear on the first screen (titles, text, labels, buttons), so all four are awaited. Nothing is left for the background.

```dart
// lib/theme/appearance.dart:62-85 — current (the saved look is read only after the first frame)
  @override
  Appearance build() {
    gallerySchemeChoices.clear();
    _load();
    return const Appearance();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _restoreGallery(p.getString(_galleryKey));
      state = Appearance(
        mode:
            ThemeMode.values.asNameMap()[p.getString(_modeKey)] ??
            ThemeMode.system,
        schemeId: themeChoiceById(p.getString(_schemeKey) ?? 'casama').id,
        headingFont: p.getString(_headingKey) ?? defaultHeadingFont,
        bodyFont: p.getString(_bodyKey) ?? defaultBodyFont,
        wallpaper: _loadWallpaper(p),
      );
    } catch (_) {
      // Preferences unavailable (tests, a locked keychain): keep the defaults.
    }
  }
```

```dart
// lib/theme/appearance.dart:87 and :118 — current (instance methods that use no instance state)
  void _restoreGallery(String? raw) {
  WallpaperSpec _loadWallpaper(SharedPreferences p) {
```

```dart
// lib/main.dart:28-42 — current (runs behind the "Connecting…" screen; the app is built here)
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config, {VoidCallback? onServerMoved}) async {
  final saved = await ServerConfigCache.read(config.apiUrl);
  final server = saved ?? (await CasamaClient.connect(config.apiUrl)).config;
  if (saved == null) unawaited(ServerConfigCache.write(config.apiUrl, server));
  await Supabase.initialize(url: server.supabaseUrl, publishableKey: server.supabaseAnonKey);
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase, config: server);
  final backend = SupabaseBackend(supabase, api, config: server);
  if (saved != null) unawaited(_refreshServerConfig(config.apiUrl, api, backend, saved, onServerMoved));
  final app = ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(openLocalCache())],
    child: const CasamaApp(),
  );
  return (app as Widget, backend);
}
```

There is no `pendingFonts` anywhere in `lib/`.

## The fix

The article's fix is to await `GoogleFonts.pendingFonts([...])` during the splash for the exact weights the app uses. Applied here:

1. A `preloadFonts` helper next to `fontStyle`. It builds the theme's four styles through the same `fontStyle` call (so it triggers the same `google_fonts` loads) and awaits them.
2. Startup reads the saved look while it connects, preloads that look's fonts, and hands the look to the app. The first frame then already draws the right fonts (and the right scheme and wallpaper), with nothing swapping a moment later.

`lib/theme/fonts.dart`, add at the end of the file:

```dart

/// The weights the theme draws each family at (AppTheme's `_typography`): headlines at 600; body
/// text at 400 (paragraphs), 500 (small labels) and 600 (titles and buttons). All upright.
const _headingWeights = [FontWeight.w600];
const _bodyWeights = [FontWeight.w400, FontWeight.w500, FontWeight.w600];

/// Loads the Google Fonts the theme will use for [heading] and [body], so text opens in them
/// instead of in a fallback that swaps a moment later. Bundled families need nothing. Never throws,
/// and gives up after [timeout]: a font that can't download (a first start offline) must not hold
/// the app, which then falls back as before.
Future<void> preloadFonts({required String heading, required String body, Duration timeout = const Duration(seconds: 2)}) async {
  final styles = <TextStyle>[
    if (!bundledFonts.contains(heading))
      for (final weight in _headingWeights) fontStyle(heading, TextStyle(fontWeight: weight)),
    if (!bundledFonts.contains(body))
      for (final weight in _bodyWeights) fontStyle(body, TextStyle(fontWeight: weight)),
  ];
  if (styles.isEmpty) return;
  try {
    await GoogleFonts.pendingFonts(styles).timeout(timeout);
  } catch (_) {
    // Offline, or the family is no longer on Google Fonts.
  }
}
```

`google_fonts` picks the file from `fontWeight` and `fontStyle` only. These styles have no `fontStyle`, so they resolve to the same files as the theme's (non-italic) styles. `pendingFonts` throws if a load fails; that is caught.

`lib/theme/appearance.dart`, three changes inside `AppearanceNotifier`:

(a) Directly below the line `  static const _everywhereKey = 'appearance.wallpaper.everywhere';` (line 60), add:

```dart

  /// [initial]: the saved look when startup has already read it (see [readSaved]), so the first
  /// frame draws it instead of the defaults; null reads it here.
  AppearanceNotifier([this._initial]);
  final Appearance? _initial;
```

(b) Replace `build()` and `_load()` (lines 62-85, quoted in "Where") with:

```dart
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
```

(c) Make the two helpers static, since `readSaved` is static and they use no instance state. Line 87 becomes `  static void _restoreGallery(String? raw) {` and line 118 becomes `  static WallpaperSpec _loadWallpaper(SharedPreferences p) {`. Their bodies don't change.

`appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(AppearanceNotifier.new)` stays as it is. The constructor's parameter is optional, so the tear-off still fits and every test that doesn't override the provider behaves as before.

`lib/main.dart`, target for `bootstrap` plus one new private function directly below it:

```dart
Future<(Widget, SupabaseBackend)> bootstrap(AppConfig config, {VoidCallback? onServerMoved}) async {
  // The saved look and its Google Fonts load alongside the connection, so the app's first frame
  // already draws them and no text swaps fonts a moment later.
  final look = _savedLookWithFonts();
  final saved = await ServerConfigCache.read(config.apiUrl);
  final server = saved ?? (await CasamaClient.connect(config.apiUrl)).config;
  if (saved == null) unawaited(ServerConfigCache.write(config.apiUrl, server));
  await Supabase.initialize(url: server.supabaseUrl, publishableKey: server.supabaseAnonKey);
  final supabase = Supabase.instance.client;
  final api = await SupabaseBackend.connectApi(config.apiUrl, supabase, config: server);
  final backend = SupabaseBackend(supabase, api, config: server);
  if (saved != null) unawaited(_refreshServerConfig(config.apiUrl, api, backend, saved, onServerMoved));
  final appearance = await look;
  final app = ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      localCacheProvider.overrideWithValue(openLocalCache()),
      appearanceProvider.overrideWith(() => AppearanceNotifier(appearance)),
    ],
    child: const CasamaApp(),
  );
  return (app as Widget, backend);
}

/// The look saved on this device once its Google Fonts have loaded (see [preloadFonts]); null when
/// preferences are slow or unreadable, and the app then reads the look itself, as before.
Future<Appearance?> _savedLookWithFonts() async {
  try {
    final look = await AppearanceNotifier.readSaved().timeout(const Duration(seconds: 2));
    if (look != null) await preloadFonts(heading: look.headingFont, body: look.bodyFont);
    return look;
  } catch (_) {
    return null;
  }
}
```

Timing: `_savedLookWithFonts` starts first and runs while the app reaches Supabase and the API, so on a normal start it adds no wait. At worst it adds 2 s (stuck preferences) plus 2 s (a font that can't download). It never throws, so if `bootstrap` fails before `await look`, nothing goes unhandled. A server switch or reconnect runs `bootstrap` again and reads the look fresh.

## Steps

1. In `lib/theme/fonts.dart`, add the `_headingWeights`, `_bodyWeights` and `preloadFonts` code from "The fix" at the end of the file. Edit by hand. Never run `dart format` on an existing file or directory.
2. In `lib/theme/appearance.dart`, make change (a): the constructor and `_initial` field directly below the `_everywhereKey` line.
3. In `lib/theme/appearance.dart`, make change (b): replace `build()` and `_load()` with the target. Copy the `Appearance(...)` arguments exactly as shown (they are today's `_load` arguments).
4. In `lib/theme/appearance.dart`, make change (c): add `static ` in front of `void _restoreGallery(` and in front of `WallpaperSpec _loadWallpaper(`. Don't touch `setMode`, `setScheme`, `setFonts`, `setWallpaper`, `applyGalleryScheme`, `apply` or `_galleryJson`.
5. In `lib/main.dart`, add `import 'theme/appearance.dart';` and `import 'theme/fonts.dart';` as new lines among the imports at the top. Any position in the import block is fine; other changes may have added imports there.
6. In `lib/main.dart`, replace `bootstrap` (lines 28-42, quoted in "Where") with the target, and add `_savedLookWithFonts` directly below it, above `_refreshServerConfig`. Leave `_refreshServerConfig`, `main()` and `StartupGate` unchanged.
7. Create `test/font_preload_test.dart` with exactly this content, then run `dart format -l 200 test/font_preload_test.dart` (a new file, so formatting it is fine):

```dart
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startup reads the saved look, so the very first frame already has its fonts', () async {
    SharedPreferences.setMockInitialValues({
      'appearance.font.heading': 'Fraunces',
      'appearance.font.body': 'Figtree',
      'appearance.mode': 'dark',
    });
    final look = (await AppearanceNotifier.readSaved())!;
    expect(look.headingFont, 'Fraunces');
    expect(look.bodyFont, 'Figtree');
    expect(look.mode, ThemeMode.dark);
    final container = ProviderContainer(overrides: [appearanceProvider.overrideWith(() => AppearanceNotifier(look))]);
    addTearDown(container.dispose);
    // The first read, with nothing awaited: the saved look, not the defaults.
    expect(container.read(appearanceProvider).headingFont, 'Fraunces');
    expect(container.read(appearanceProvider).mode, ThemeMode.dark);
  });

  test('without a look from startup, the notifier still reads the saved one itself', () async {
    SharedPreferences.setMockInitialValues({'appearance.font.body': 'Figtree'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(appearanceProvider, (_, _) {});
    expect(container.read(appearanceProvider).bodyFont, defaultBodyFont);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(appearanceProvider).bodyFont, 'Figtree');
  });

  test('bundled fonts need nothing, and a font that cannot load never blocks startup', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);
    await preloadFonts(heading: defaultHeadingFont, body: defaultBodyFont);
    // Not bundled and not fetchable here: it gives up quietly instead of throwing.
    await preloadFonts(heading: 'Lora', body: 'Inter', timeout: const Duration(seconds: 1));
  });
}
```

8. Run `flutter test test/font_preload_test.dart test/design_test.dart test/offline_launch_test.dart test/startup_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/theme/fonts.dart lib/theme/appearance.dart lib/main.dart test/font_preload_test.dart` reports no errors and no warnings. One `curly_braces_in_flow_control_structures` info in `appearance.dart` (the `if (gallerySchemeChoices.isNotEmpty)` line in `apply`) was there before this change; leave it.
- `grep -c "GoogleFonts.pendingFonts" lib/theme/fonts.dart` → `1`
- `grep -c "FontWeight.w400, FontWeight.w500, FontWeight.w600" lib/theme/fonts.dart` → `1`
- `grep -c "static Future<Appearance?> readSaved" lib/theme/appearance.dart` → `1`
- `grep -c "static void _restoreGallery" lib/theme/appearance.dart` → `1`
- `grep -c "static WallpaperSpec _loadWallpaper" lib/theme/appearance.dart` → `1`
- `grep -c "appearanceProvider.overrideWith(() => AppearanceNotifier(appearance))" lib/main.dart` → `1`
- `grep -c "preloadFonts(heading: look.headingFont, body: look.bodyFont)" lib/main.dart` → `1`
- The `flutter test` command in step 8 passes.

## Don't touch

- `lib/theme/app_theme.dart`: `_typography` already makes the styles; the preload mirrors its weights. If those weights ever change, `_headingWeights`/`_bodyWeights` in `fonts.dart` must change with them, and their comment says so.
- `lib/features/settings/fonts_screen.dart`: the picker's previews load fonts on demand, and picking a new font downloads it then. That's a choice made in the moment, not a cold start.
- `fontStyle`, `bundledFonts` and the curated lists in `fonts.dart`: unchanged.
- `main()` and `StartupGate` in `lib/main.dart`: other changes may edit those parts. This plan only changes `bootstrap` and adds `_savedLookWithFonts`.
- `pubspec.yaml`: no font assets added; the bundled families stay as they are.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key`.
- No new dependencies. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `lib/theme/app_theme.dart`'s `_typography` uses weights other than the ones listed in "Where" (it moved on; the preload list would be wrong).
- The fix seems to require touching something in "Don't touch".
- A test in step 8 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. The saved look and its Google Fonts now load while the app shows "Connecting…", so the first frame draws the chosen fonts (and scheme and wallpaper) instead of starting in Lato and Libre Baskerville and swapping. If a font can't load, startup waits at most two seconds and carries on as before. To see it, pick a non-bundled font such as Inter in Settings → Themes → Fonts, then quit and reopen the app.

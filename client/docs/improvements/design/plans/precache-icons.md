# Fix: Mascots and logos paint a few frames after their screen

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/precache-icons
- **Needs new dependency**: none (`flutter_svg` is already in `pubspec.yaml`)

## Why

Flutter loads and decodes a bundled picture only when a widget first asks for it, so it is painted a frame or two after the rest of its screen. In Casama that's the first thing people see. On the sign-in screen all ten cloud mascots blink in after the page. After that, the Google and Apple marks pop into the sign-in sheet as it slides up. Signed-in people see the home screen's Casama mark and the bots' mascot avatars appear late. Decoding them while the app shows its "Connecting…" screen means they're ready the moment their screen paints.

## Where

The bundled pictures, and the startup screen that will preload them:

```dart
// lib/ui/mascot.dart:69-93 — current (every mascot still: sign-in, welcome, home mark, bot avatars, name and notification pages)
  /// Pixel size the still poses are rendered at (see scripts/casama-mascot-render.mjs). Enough for
  /// a 96pt avatar on a 3x screen; never decode above it.
  static const assetPx = 320;

  /// Big mascots follow the display (up to 120 fps); small ones draw at the loop's own 60 fps.
  static const _fullRateFrom = 64.0;

  @override
  Widget build(BuildContext context) {
    final moving = animate && !MediaQuery.disableAnimationsOf(context);
    final drawn = size * _zoom;
    final px = (drawn * MediaQuery.devicePixelRatioOf(context)).round().clamp(
      16,
      assetPx,
    );
    final still = Image.asset(
      mascot.stillAsset,
      width: drawn,
      height: drawn,
      cacheWidth: px,
      cacheHeight: px,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
```

Each mascot is decoded again for every size it's drawn at: `cacheWidth`/`cacheHeight` make a separate image-cache entry per pixel size. The sign-in screen alone draws the ten mascots at sizes that depend on the window (`lib/features/auth/floating_mascots.dart:86`), so a preload can't guess those keys. The fix decodes each still once at the art's own size (all ten PNGs in `assets/mascots/` are 320 × 320) and shares that copy everywhere. That costs about 4 MB of image cache for all ten. Today the same mascot drawn at 30, 46 and 104 pt makes three decodes.

```dart
// lib/ui/brand_sign_in_buttons.dart:8 and :16 — current (the strings are 6 and 3 lines long; unchanged)
const _googleG =
const _appleLogo =
```

```dart
// lib/ui/brand_sign_in_buttons.dart:41 — current (sign-in sheet, Google button)
      logo: SvgPicture.string(_googleG, width: 20, height: 20),
```

```dart
// lib/ui/brand_sign_in_buttons.dart:65-70 — current (sign-in sheet, Apple button)
      logo: SvgPicture.string(
        _appleLogo,
        width: 18,
        height: 20,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
```

```dart
// lib/features/integrations/app_logo.dart:8-13 — current
/// Apps with a bundled brand mark (assets/apps, from Simple Icons, CC0).
const _bundledLogos = {
  'airtable', 'asana', 'atlassian', 'box', 'cloudflare', 'figma', 'github', 'gmail', 'google_calendar', //
  'google_drive', 'hubspot', 'huggingface', 'intercom', 'linear', 'mcp', 'notion', 'posthog', 'sentry', //
  'slack', 'stripe', 'supabase', 'vercel', 'webflow', 'zapier',
};
```

```dart
// lib/features/integrations/app_logo.dart:90 — current (Connections screens and the connect sheet)
        child: SvgPicture.asset('assets/apps/$appId.svg', colorFilter: ColorFilter.mode(ink, BlendMode.srcIn)),
```

```dart
// lib/main.dart:75-98 — current (the "Connecting…" screen: this app's splash, shown before the first real screen)
class _StartupGateState extends State<StartupGate> {
  Widget? _app;
  Object? _error;
  late AppConfig _config = widget.config;

  @override
  void initState() {
    super.initState();
    // Self-hosters point the app at their own server (D-076); the choice is remembered.
    onChangeServer = _switchServer;
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      _config = await ServerAddress.load(fallback: widget.config);
      final connect = widget.connect ?? (c) async => (await bootstrap(c, onServerMoved: _reconnect)).$1;
      final app = await connect(_config).timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _app = app);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }
```

```dart
// test/mascot_test.dart:45 and :54 — current (they assert the per-size decode this plan removes)
    expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName, 'assets/mascots/giggly.png');
    expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName, 'assets/mascots/wow.png');
```

There is no `precacheImage` or `svg.cache` anywhere in `lib/`.

## The fix

The article's fix is a `precacheAssets` helper (`svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null))` for SVGs, `precacheImage(AssetImage(path), context)` for the rest), run from the splash screen. It awaits what the first screen shows and loads the rest in the background.

**What is preloaded, and why:**

- **Waited for (first screens):** the ten mascot stills, `assets/mascots/<name>.png`. The sign-in screen shows all ten, the welcome and name pages show Winky, the notifications page shows Wow, and the home screen's Casama mark and the bots' avatars use them. They are ten small PNGs. They decode while the app connects, and the gate waits at most 500 ms after connecting for them, so startup never gets noticeably slower.
- **Background, not waited for:** the Google and Apple marks (the sign-in sheet, one tap away) and the 24 bundled app logos in `assets/apps/` (the Connections screens, several taps away).
- **Not preloaded:** the Lottie loops (`assets/mascots/*.json`, about 2 MB). Each mascot's still pose already stands in until its loop loads.

New file `lib/core/startup_assets.dart`, exactly:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/integrations/app_logo.dart';
import '../ui/brand_sign_in_buttons.dart';
import '../ui/mascot.dart';

/// Decodes bundled pictures before a screen asks for them, so they paint with the screen instead of
/// a few frames later. SVGs go into flutter_svg's cache, everything else into Flutter's image cache.
/// A file that can't load is skipped: its widget shows its own fallback when it gets there.
Future<void> precacheAssets({required BuildContext context, required List<String> paths}) async {
  for (final path in paths) {
    if (!context.mounted) return;
    try {
      if (path.endsWith('.svg')) {
        final loader = SvgAssetLoader(path);
        await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
      } else {
        await precacheImage(AssetImage(path), context, onError: (_, _) {});
      }
    } catch (_) {}
  }
}

/// Run by the startup gate while the app connects. Waits for what the first screens show: the ten
/// cloud mascots (the sign-in screen shows all of them; the home screen's Casama mark and the bots'
/// avatars use them). Then starts, without waiting, what comes a tap or more later: the Google and
/// Apple marks in the sign-in sheet and the bundled app logos on the Connections screens. The Lottie
/// loops are left alone: each mascot's still pose stands in until its loop loads.
Future<void> precacheStartupAssets(BuildContext context) async {
  await precacheAssets(context: context, paths: [for (final m in Mascot.values) m.stillAsset]);
  if (!context.mounted) return;
  unawaited(_precacheLater(context));
}

Future<void> _precacheLater(BuildContext context) async {
  for (final loader in brandMarkLoaders) {
    try {
      await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    } catch (_) {}
  }
  if (!context.mounted) return;
  await precacheAssets(context: context, paths: bundledLogoAssets);
}
```

The cache keys match what the widgets ask for:

- `MascotImage` will draw `Image.asset(mascot.stillAsset)`, whose key is the same `AssetImage` the helper preloads.
- `SvgPicture.asset('assets/apps/$appId.svg')` builds `SvgAssetLoader('assets/apps/$appId.svg')`. Its `colorFilter` is applied when painting and isn't part of the key.
- `SvgPicture.string(_googleG)` builds `SvgStringLoader(_googleG)`, which equals the loader in `brandMarkLoaders`.
- The app sets no `DefaultSvgTheme`, so `cacheKey(null)` equals the key the widgets compute.

`lib/ui/mascot.dart`, target for the part quoted in "Where" (the `assetPx` constant and its comment are removed; `_fullRateFrom` stays):

```dart
  /// Big mascots follow the display (up to 120 fps); small ones draw at the loop's own 60 fps.
  static const _fullRateFrom = 64.0;

  @override
  Widget build(BuildContext context) {
    final moving = animate && !MediaQuery.disableAnimationsOf(context);
    final drawn = size * _zoom;
    // Decoded once at the art's own 320 px and shared by every size it is drawn at, so the copy
    // decoded while the app connects (precacheStartupAssets) is the one every screen paints.
    final still = Image.asset(
      mascot.stillAsset,
      width: drawn,
      height: drawn,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
```

`lib/ui/brand_sign_in_buttons.dart`, new declaration directly below the `_appleLogo` constant (after the line `    '</svg>';` that ends it, line 19):

```dart

/// The Google and Apple marks as the flutter_svg loaders the buttons draw them with, so startup can
/// parse them before the sign-in sheet opens.
const brandMarkLoaders = [SvgStringLoader(_googleG), SvgStringLoader(_appleLogo)];
```

`lib/features/integrations/app_logo.dart`, new declaration directly below the `_bundledLogos` set (after its closing `};`, line 13):

```dart

/// The bundled marks' files, so startup can parse them before the Connections screens open.
List<String> get bundledLogoAssets => [for (final id in _bundledLogos) 'assets/apps/$id.svg'];
```

`lib/main.dart`, target for `_StartupGateState` from its first line through the end of `_start()`. Everything after `_start()` stays as it is.

```dart
class _StartupGateState extends State<StartupGate> {
  Widget? _app;
  Object? _error;
  late AppConfig _config = widget.config;

  /// The first screens' pictures, decoding while the app connects (see [precacheStartupAssets]).
  Future<void>? _assets;

  @override
  void initState() {
    super.initState();
    // Self-hosters point the app at their own server (D-076); the choice is remembered.
    onChangeServer = _switchServer;
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assets ??= precacheStartupAssets(context);
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      _config = await ServerAddress.load(fallback: widget.config);
      final connect = widget.connect ?? (c) async => (await bootstrap(c, onServerMoved: _reconnect)).$1;
      final app = await connect(_config).timeout(const Duration(seconds: 20));
      // The first screen opens with its pictures decoded; never more than half a second's wait.
      await (_assets ?? Future<void>.value()).timeout(const Duration(milliseconds: 500), onTimeout: () {});
      if (mounted) setState(() => _app = app);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }
```

The preload starts in `didChangeDependencies`, not `initState`, because `precacheImage` reads inherited widgets from `context`. The `??=` makes it run once. Retries and server switches reuse the finished future. In widget tests, asset decoding never finishes inside fake time, so the gate simply waits the 500 ms cap while its spinner animates; `test/startup_test.dart`'s `pumpAndSettle` keeps pumping through it.

## Steps

1. Create `lib/core/startup_assets.dart` with the exact content from "The fix", then run `dart format -l 200 lib/core/startup_assets.dart`. That file only: never run `dart format` on any existing file or directory.
2. In `lib/ui/mascot.dart`, replace the excerpt quoted in "Where" (from the comment `/// Pixel size the still poses are rendered at` through the closing `);` of `final still = Image.asset(`) with the target from "The fix". Before you edit, run `grep -rn "assetPx" lib test`. It must list only `lib/ui/mascot.dart`; if anything else uses `assetPx`, STOP. Leave the rest of `build()` (the Lottie part, `Semantics`, `SizedBox`/`OverflowBox`) unchanged.
3. In `lib/ui/brand_sign_in_buttons.dart`, add the `brandMarkLoaders` declaration from "The fix" directly below the `_appleLogo` constant. The file already imports `package:flutter_svg/flutter_svg.dart`, which exports `SvgStringLoader`. Don't change the buttons.
4. In `lib/features/integrations/app_logo.dart`, add the `bundledLogoAssets` getter from "The fix" directly below the `_bundledLogos` set. Don't change anything else in this file.
5. In `lib/main.dart`, add `import 'core/startup_assets.dart';` as a new line among the `import 'core/…';` lines at the top. Any position in that block is fine; other changes may have added imports there.
6. In `lib/main.dart`, change `_StartupGateState` to the target from "The fix". It is three additions: the `_assets` field with its comment, the `didChangeDependencies` override between `initState` and `_start`, and the two lines (comment plus `await (_assets ?? …)`) directly below `final app = await connect(_config)…`. If another change already added lines below that `final app = …` line, keep them and put these two lines directly below the `final app = …` line. Leave `_switchServer`, `_reconnect` and `build` unchanged.
7. In `test/mascot_test.dart`, change line 45 to `    expect((image.image as AssetImage).assetName, 'assets/mascots/giggly.png');` and line 54 to `    expect((image.image as AssetImage).assetName, 'assets/mascots/wow.png');`. The still is no longer wrapped in a per-size `ResizeImage`.
8. Create `test/startup_assets_test.dart` with exactly this content, then run `dart format -l 200 test/startup_assets_test.dart`:

```dart
import 'package:casama_app/core/startup_assets.dart';
import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:casama_app/ui/mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mascots are decoded before a screen asks for them', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    PaintingBinding.instance.imageCache.clear();
    await tester.runAsync(() async {
      await precacheAssets(context: context, paths: [for (final m in Mascot.values) m.stillAsset]);
      for (final m in Mascot.values) {
        // The same key MascotImage's Image.asset asks the cache for.
        final key = await AssetImage(m.stillAsset).obtainKey(ImageConfiguration.empty);
        expect(PaintingBinding.instance.imageCache.containsKey(key), isTrue, reason: m.name);
      }
    });
  });

  testWidgets('the app logos are parsed into the SVG cache ahead of the Connections screens', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    svg.cache.clear();
    await tester.runAsync(() => precacheAssets(context: context, paths: bundledLogoAssets));
    expect(svg.cache.count, bundledLogoAssets.length);
  });

  testWidgets('a missing file is skipped, not thrown', (tester) async {
    await tester.pumpWidget(const Placeholder());
    final context = tester.element(find.byType(Placeholder));
    await tester.runAsync(() => precacheAssets(context: context, paths: ['assets/nope.png', 'assets/nope.svg']));
    expect(tester.takeException(), isNull);
  });
}
```

9. Run `flutter test test/startup_assets_test.dart test/mascot_test.dart test/app_test.dart test/startup_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/core/startup_assets.dart lib/ui/mascot.dart lib/ui/brand_sign_in_buttons.dart lib/features/integrations/app_logo.dart lib/main.dart test/mascot_test.dart test/startup_assets_test.dart` reports no issues.
- `grep -c "cacheWidth" lib/ui/mascot.dart` → `0`
- `grep -c "assetPx" lib/ui/mascot.dart` → `0`
- `grep -c "const brandMarkLoaders" lib/ui/brand_sign_in_buttons.dart` → `1`
- `grep -c "bundledLogoAssets" lib/features/integrations/app_logo.dart` → `1`
- `grep -c "precacheStartupAssets(context)" lib/main.dart` → `1`
- `grep -c "milliseconds: 500" lib/main.dart` → `1`
- `grep -c "ResizeImage" test/mascot_test.dart` → `0`
- `grep -c "svg.cache.putIfAbsent" lib/core/startup_assets.dart` → `2`
- The `flutter test` command in step 9 passes.

## Don't touch

- `lib/features/voice/call_mascot.dart` and the Lottie `*.json` loops: not pictures `precacheImage` can hold, about 2 MB, and the still pose already covers them while they load.
- `lib/features/auth/two_step_screen.dart`'s `SvgPicture.string(enrolling.qrSvg, …)`: a QR code from the server, different every time, so it can't be preloaded.
- `assets/tray_icon.png` (`lib/features/companion/desktop_shell.dart`): the native tray draws it, not Flutter.
- `bootstrap()` and `main()` in `lib/main.dart`, and `_StartupGateState.build`: other changes may edit those parts. This plan only changes the fields, `initState`/`didChangeDependencies` and `_start()` of `_StartupGateState`.
- The buttons in `brand_sign_in_buttons.dart`, `AppLogo.build`, `FloatingMascots`, `CasamaMark`, `BotAvatar`: they stay as they are; the preload works through cache keys.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key`.
- No new dependencies. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `grep -rn "assetPx" lib test` finds a use outside `lib/ui/mascot.dart`.
- The fix seems to require touching something in "Don't touch".
- A test in step 9 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. The mascots now decode while the app shows "Connecting…", so they paint with their screen instead of a few frames late. The sign-in sheet's Google and Apple marks and the Connections screens' app logos are parsed in the background right after. Each mascot is decoded once instead of once per size. To see it, sign out and reopen the app: the sign-in screen's ten bots appear together with the page.

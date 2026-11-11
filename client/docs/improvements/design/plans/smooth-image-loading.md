# Fix: Web pictures pop in with no placeholder, and a logo that fails to load shows nothing

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-image-loading
- **Needs new dependency**: `image_fade: ^0.6.2`. It is the article's package: it holds a placeholder while any `ImageProvider` loads, cross-fades to the picture, and cross-fades to an error widget if it fails. 0.6.2 is its latest release (MIT). Its SDK range ends at `<3.0.0`, which Dart 3 reads as `<4.0.0`. Packages already resolved in `pubspec.lock` (`scroll_to_index`, `visibility_detector`, `timezone`) have the same range, so `flutter pub get` resolves it the same way.

## Why

Pictures from the web pop in with no transition. In the wallpaper photo picker (Settings → Background → Browse photos), each thumbnail snaps onto its tile when it arrives. In the Composio/Pipedream app list, each remote logo snaps into its tile. When a remote logo fails, the fallback letter is drawn in a color that disappears on the tile: white on the white tile in light mode, near-black on the dark tile in dark mode. So the tile looks broken and empty. The app should hold a calm tone until the picture is ready, fade it in, and show a small, quiet mark if it fails. It should never show a technical message.

## Where

Every network image in `lib/`. There are two widget call sites, both fixed by this plan:

```dart
// lib/features/integrations/app_logo.dart:76-86 — current
    if (imageUrl != null) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.16),
        // Decoded at the tile's size: remote logos are often 512 px or more.
        child: Image.network(
          imageUrl!,
          fit: BoxFit.contain,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          errorBuilder: (_, _, _) => _initial(ink),
        ),
      );
```

`ink` above is worked out from the brand color, not from the tile this logo sits on. Remote logos sit on a neutral tile (`Colors.white` in light mode, `scheme.surfaceContainerHighest` in dark mode, line 98). `lib/features/integrations/provider_setup.dart:234` passes no color, so `ink` comes out white in light mode and `0xFF1B1B1F` in dark mode. Either way the fallback letter can't be seen on its tile.

```dart
// lib/features/settings/photo_picker.dart:157-161 — current
                                Image.network(
                                  p.thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox(),
                                ),
```

This sits in a `Stack(fit: StackFit.expand)` inside a `Material` painted with the photo's own color, `_hex(p.color) ?? scheme.surfaceContainer` (line 150). That tone is already a good placeholder. What's missing is the fade, and a failure mark (today a failed photo is just a blank tile).

Checked and deliberately left alone (see "Don't touch"):

```dart
// lib/core/local_image.dart:16 — current
  if (source.startsWith('http://') || source.startsWith('https://')) return NetworkImage(source);
```

```dart
// lib/core/local_image/local_image_web.dart:9 — current
ImageProvider fileImage(String path) => NetworkImage(path);
```

Both only feed the wallpaper photo (`lib/theme/wallpaper.dart:578`, `_PhotoLoader`). The wallpaper is painted by a custom `RenderBox`, not an image widget. It already shows the theme's gradient until the photo arrives and keeps the gradient if the photo fails.

## The fix

The article's fix is to load through `ImageFade`, with a plain placeholder while loading, a cross-fade to the image, and an `errorBuilder` that shows a small, subtle icon. Applied here as one shared widget, so every web picture in the app behaves the same.

Create `lib/ui/smooth_network_image.dart` with exactly this content:

```dart
import 'package:flutter/material.dart';
import 'package:image_fade/image_fade.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_tokens.dart';

/// A picture from the web that eases in: a plain tone holds its place while it loads, it fades in
/// when ready, and if it can't load a small, faint broken-image mark shows instead (never a
/// technical message). It fills the box it is given, so give it a sized tile or a grid cell.
class SmoothNetworkImage extends StatelessWidget {
  const SmoothNetworkImage(this.url, {super.key, this.fit = BoxFit.cover, this.decodeWidth, this.placeholderColor, this.error});

  final String url;
  final BoxFit fit;

  /// Decodes at this many pixels wide instead of the file's own size (remote logos are often
  /// 512 px or more for a 40 pt tile). Null decodes at full size.
  final int? decodeWidth;

  /// The tone shown while loading and behind the failure mark. Defaults to the theme's
  /// surfaceContainerHighest. Pass Colors.transparent when the box behind is already a placeholder.
  final Color? placeholderColor;

  /// Shown, centered, if the picture can't load. Defaults to a faint broken-image icon.
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final tone = placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    // Faint on any tone: light marks on dark tones, dark marks on light ones.
    final mark = ThemeData.estimateBrightnessForColor(tone) == Brightness.dark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.25);
    return SizedBox.expand(
      child: ImageFade(
        image: ResizeImage.resizeIfNeeded(decodeWidth, null, NetworkImage(url)),
        fit: fit,
        duration: AppMotion.of(context, AppMotion.duration),
        // Pictures already in memory (scrolling back, reopening a screen) show at once.
        syncDuration: Duration.zero,
        curve: AppMotion.curve,
        placeholder: ColoredBox(color: tone),
        errorBuilder: (context, _) => ColoredBox(
          color: tone,
          child: Center(child: error ?? Icon(LucideIcons.imageOff, size: 20, color: mark)),
        ),
      ),
    );
  }
}
```

Why each choice:

- `SizedBox.expand` gives `ImageFade` tight constraints, so a logo that isn't square stays centered in its tile. Without it, `ImageFade`'s inner `Stack` would pin the image to the top-left.
- `ResizeImage.resizeIfNeeded(decodeWidth, null, NetworkImage(url))` is exactly what `Image.network(cacheWidth: …)` does today, so logos still decode at tile size.
- `AppMotion.of` gives zero duration when the system asks to reduce motion.

The two call sites:

```dart
// lib/features/integrations/app_logo.dart — target
    if (imageUrl != null) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.16),
        // Decoded at the tile's size: remote logos are often 512 px or more. The neutral tile is the
        // placeholder; the logo fades in, and one that can't load shows the app's initial.
        child: SmoothNetworkImage(
          imageUrl!,
          fit: BoxFit.contain,
          decodeWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          placeholderColor: Colors.transparent,
          error: _initial(scheme.onSurfaceVariant),
        ),
      );
```

The tile itself (white or `surfaceContainerHighest`) already is the plain placeholder, so no extra grey box is drawn inside it. The failure mark stays the app's initial, which is what every other logo-less app in this file shows. It is now drawn in `scheme.onSurfaceVariant`, which reads quietly on the neutral tile in both themes.

```dart
// lib/features/settings/photo_picker.dart — target
                                SmoothNetworkImage(
                                  p.thumbUrl,
                                  placeholderColor: _hex(p.color) ?? scheme.surfaceContainer,
                                ),
```

The placeholder is Unsplash's own color for the photo, the same tone the tile already paints, so the photo fades in from its own color. A failed photo shows the faint mark on that tone.

## Steps

1. In `pubspec.yaml`, under `dependencies:`, add the line `  image_fade: ^0.6.2` directly below the existing line `  flutter_svg: ^2.3.2` (two spaces of indent, like its neighbours). Edit by hand.
2. Run `flutter pub get` in `client/`.
3. Create `lib/ui/smooth_network_image.dart` with the exact content from "The fix". Then run `dart format -l 200 lib/ui/smooth_network_image.dart`. That file only: never run `dart format` on any existing file or directory.
4. In `lib/features/integrations/app_logo.dart`, add `import '../../ui/smooth_network_image.dart';` on a new line directly below `import '../../theme/app_colors.dart';`.
5. In `lib/features/integrations/app_logo.dart`, replace the `if (imageUrl != null) { mark = Padding(…); }` branch body quoted in "Where" (lines 76-86) with the target from "The fix". Keep `final scheme = Theme.of(context).colorScheme;` (line 68) as it is; the target uses it. Leave `else if (hasMark)`, `else if (icon != null)` and `else` as they are.
6. In `lib/features/settings/photo_picker.dart`, add `import '../../ui/smooth_network_image.dart';` on a new line directly below `import '../../theme/app_tokens.dart';`.
7. In `lib/features/settings/photo_picker.dart`, replace the `Image.network(…)` widget quoted in "Where" (lines 157-161) with the target from "The fix". Keep the `Align(...)` with the photographer's name below it, the `InkWell` and its `Key('photo-${p.id}')` unchanged.
8. Create `test/smooth_network_image_test.dart` with exactly this content, then run `dart format -l 200 test/smooth_network_image_test.dart`:

```dart
import 'package:casama_app/features/integrations/app_logo.dart';
import 'package:casama_app/ui/smooth_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_fade/image_fade.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 120, height: 160, child: child))),
  );

  // Widget tests answer every web request with HTTP 400, so these pictures always fail.
  Future<void> letItFail(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('a web picture holds a plain tone while loading, then a faint mark if it fails', (tester) async {
    await tester.pumpWidget(host(const SmoothNetworkImage('https://example.com/photo.jpg', placeholderColor: Color(0xFF336699))));
    expect(find.byType(ImageFade), findsOneWidget);
    expect(find.byIcon(LucideIcons.imageOff), findsNothing);
    await letItFail(tester);
    expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a remote app logo that cannot load shows the app initial, not a broken mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppLogo(name: 'Notion', imageUrl: 'https://example.com/logo.png', size: 40))),
      ),
    );
    await letItFail(tester);
    expect(find.text('N'), findsOneWidget);
    expect(find.byIcon(LucideIcons.imageOff), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
```

9. Run `flutter test test/smooth_network_image_test.dart test/design_test.dart test/phone_layout_test.dart` in `client/`.

## Check it

- `dart analyze lib/ui/smooth_network_image.dart lib/features/integrations/app_logo.dart lib/features/settings/photo_picker.dart test/smooth_network_image_test.dart` reports no errors and no warnings. Two `curly_braces_in_flow_control_structures` infos in `photo_picker.dart` (the `if (!snap.hasData)` and `if (items.isEmpty)` lines) were there before this change; leave them.
- `grep -c "Image.network" lib/features/integrations/app_logo.dart` → `0`
- `grep -c "SmoothNetworkImage(" lib/features/integrations/app_logo.dart` → `1`
- `grep -c "_initial(scheme.onSurfaceVariant)" lib/features/integrations/app_logo.dart` → `1`
- `grep -c "Image.network" lib/features/settings/photo_picker.dart` → `0`
- `grep -c "SmoothNetworkImage(" lib/features/settings/photo_picker.dart` → `1`
- `grep -c "image_fade: \^0.6.2" pubspec.yaml` → `1`
- `grep -c "class SmoothNetworkImage" lib/ui/smooth_network_image.dart` → `1`
- The `flutter test` command in step 9 passes.

## Don't touch

- `lib/core/local_image.dart`, `lib/core/local_image/local_image_web.dart` and `lib/theme/wallpaper.dart`. The wallpaper photo is painted by `_RenderWallpaper`, not by an image widget, so `ImageFade` can't wrap it. It already has a placeholder (the theme gradient) and a failure state (the gradient stays). A fade there would mean changing the custom painter and its page-transition repaint logic, which is out of scope.
- Images inside bot replies (`![…](https://…)` in `lib/features/chat/widgets/chat_markdown.dart`). `markdown_widget` builds those with its own `Image.network`. Replacing them through `ImgConfig.builder` would drop the package's tap-to-zoom viewer, and their size isn't known before they load, so a placeholder box can't be sized. Leave for a separate change.
- `lib/ui/mascot.dart`, `SvgPicture.asset` logos and every other bundled asset: assets are out of scope for this rule.
- `lib/features/integrations/provider_setup.dart`: the call site doesn't change.
- No git commands (others commit in this tree). No `dart format` on existing files or folders. Keep every existing widget `Key`.
- No new dependencies beyond `image_fade`. No refactors, renames or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written). Line numbers may have shifted because of other changes; only the quoted code has to match.
- `flutter pub get` can't resolve `image_fade: ^0.6.2`.
- The fix seems to require touching something in "Don't touch".
- A test in step 9 fails because of this change, or any check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different. Pictures from the web now hold a calm tone, fade in when ready, and show a small faint mark (or, for app logos, the app's initial in a visible color) when they can't load. To see it, open Settings → Background → Browse photos and scroll the grid.

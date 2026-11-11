# Fix: Gallery wallpaper thumbnails pop in

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-image-loading
- **Needs new dependency**: none (the app already has a fade-in widget, so no image_fade package)

## Why

Pictures from the web should hold a plain tone while they load, fade in when ready, and show only a faint broken-image mark if they fail. The app has a shared widget for this (`SmoothNetworkImage`), but the wallpaper thumbnails in Settings → Gallery still use a bare `Image.network`, so they pop in with no transition.

## Where

All paths are relative to `client/`. A full sweep of `lib/` for `Image.network|NetworkImage|CachedNetworkImage|ExtendedImage|FadeInImage|image_fade` found exactly one place that renders a web picture without the fade:

```dart
// lib/features/settings/gallery_previews.dart:390 — current
    if (thumb != null) {
      return ColoredBox(
        color: colors.surfaceContainerHigh,
        child: Image.network(
          thumb,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              LucideIcons.imageOff,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      );
    }
```

The other hits are already handled or out of scope:
- `lib/ui/smooth_network_image.dart:37` is the shared widget itself.
- `lib/features/settings/photo_picker.dart:163` and `lib/features/integrations/app_logo.dart:85` already use `SmoothNetworkImage`.
- `lib/core/local_image.dart:16` and `lib/core/local_image/local_image_web.dart:9` feed the wallpaper photo painter (`_PhotoLoader` in `lib/theme/wallpaper.dart`), which paints the gradient until the photo is ready. That's a painted background, not an image widget, so it's out of scope.

The thumbnail is always given a sized box. Its only caller, `lib/features/settings/gallery_screen.dart:790`, puts it in `AspectRatio(aspectRatio: 3 / 4)` inside a `Stack(fit: StackFit.expand)`.

## The fix

The article's fix is a placeholder while loading, a cross-fade to the image, and a subtle error widget ("a small icon at most, no technical messages"). The article uses the `image_fade` package. This app already has the same behaviour with no package in `lib/ui/smooth_network_image.dart`:
- `SmoothNetworkImage(url, {fit, decodeWidth, placeholderColor, error})` shows `placeholderColor` while loading.
- It fades the picture in with `frameBuilder`.
- On failure it shows `error`, centered on the same tone.
- It fills the box it's given.

Pass the gallery's own scheme colors, because the preview renders a scheme that may differ from the app's current theme:

```dart
// target
    if (thumb != null) {
      return SmoothNetworkImage(
        thumb,
        placeholderColor: colors.surfaceContainerHigh,
        error: Icon(
          LucideIcons.imageOff,
          color: colors.onSurfaceVariant,
          size: 20,
        ),
      );
    }
```

(`fit` defaults to `BoxFit.cover`. `gaplessPlayback` is dropped: the widget shows pictures already in memory at once without a fade.) Imitate `lib/features/settings/photo_picker.dart:163`.

## Steps

1. In `lib/features/settings/gallery_previews.dart`, add `import '../../ui/smooth_network_image.dart';` after `import '../../theme/wallpaper.dart';` (the last import).
2. Replace the whole `return ColoredBox(...);` inside `if (thumb != null) { ... }` (lines 391–405) with the target `return SmoothNetworkImage(...);` above.
3. Don't run `dart format` on this existing file. Match the indentation by hand.

## Check it

- From `client/`, `flutter analyze lib/features/settings/gallery_previews.dart` reports no issues.
- `grep -c "Image.network" lib/features/settings/gallery_previews.dart` → 0.
- `grep -c "SmoothNetworkImage(" lib/features/settings/gallery_previews.dart` → 1.
- `flutter test test/gallery_test.dart test/design_test.dart test/smooth_network_image_test.dart` passes.

## Don't touch

- `lib/ui/smooth_network_image.dart`. Use it as is.
- The wallpaper photo painter in `lib/theme/wallpaper.dart`, and `lib/core/local_image.dart`.
- The pattern-preview branch below the thumbnail branch in `GalleryWallpaperPreview`.
- No new dependencies (don't add `image_fade`).
- No refactors, renames or cleanups beyond the fix.

## Repo rules

- Never `git add -A` or `git add .`. Stage by path only. **Don't commit**; the developer commits.
- Only run `dart format` on new files.

## STOP if

- The code at the location doesn't match the excerpt (the codebase moved on).
- `GalleryWallpaperPreview` turns out to be used somewhere without a sized box (`SmoothNetworkImage` fills its box).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, that gallery wallpaper thumbnails now hold a soft tone, fade in when they load, and show a faint broken-image mark if one fails. Point them to Settings → Gallery → Wallpapers.

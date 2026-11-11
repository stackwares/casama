import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../theme/appearance.dart';
import '../../theme/fonts.dart';
import '../../theme/schemes.dart';
import '../../theme/wallpaper.dart';

/// Gallery previews (D-184): every look is drawn as a small Casama chat in its own colors, fonts
/// and background, from the document the gallery list already carries.

const galleryHost = 'https://gallery.casama.ai';

Map<String, Object?> _doc(GalleryItem item) =>
    item.document ?? const <String, Object?>{};

Map<String, Object?>? _map(Object? v) =>
    v is Map ? v.cast<String, Object?>() : null;

/// The scheme id a gallery item applies. Themes get their own id, so a theme and a color scheme
/// with the same name never overwrite each other's colors.
String gallerySchemeId(GalleryItem item) =>
    item.type == 'theme' ? 'gallery:theme-${item.id}' : 'gallery:${item.id}';

ThemeChoice? _fromSeeds(String id, String name, Map<String, Object?>? doc) {
  final light = _map(doc?['light'])?['seed'];
  final dark = _map(doc?['dark'])?['seed'];
  if (light is! String || dark is! String) return null;
  try {
    return galleryChoiceFromSeeds(id: id, name: name, light: light, dark: dark);
  } catch (_) {
    return null;
  }
}

/// The colors a theme or color scheme brings, or null when it keeps the current ones.
ThemeChoice? galleryChoiceOf(GalleryItem item) {
  final doc = _doc(item);
  switch (item.type) {
    case 'scheme':
      return _fromSeeds(gallerySchemeId(item), item.name, doc);
    case 'theme':
      final scheme = doc['scheme'];
      if (scheme is String) return themeChoiceById(scheme);
      return _fromSeeds(gallerySchemeId(item), item.name, _map(scheme));
  }
  return null;
}

/// The background a theme or wallpaper brings, or null when it keeps the current one. With
/// [thumb], an image wallpaper uses its small copy (for cards).
WallpaperSpec? galleryWallpaperOf(GalleryItem item, {bool thumb = false}) {
  final doc = _doc(item);
  final raw = switch (item.type) {
    'wallpaper' => doc,
    'theme' => _map(doc['wallpaper']),
    _ => null,
  };
  if (raw == null) return null;
  if (raw['kind'] == 'image') {
    final file = thumb ? raw['thumb'] ?? raw['file'] : raw['file'];
    if (file is! String) return null;
    return WallpaperSpec(
      pattern: WallpaperPattern.none,
      photo: '$galleryHost/wallpapers/${item.id}/$file',
      photoCredit: item.authorName,
      photoCreditUrl: item.authorUrl,
    );
  }
  final pattern = WallpaperPattern.values.asNameMap()[raw['pattern']];
  final palette = WallpaperPalette.values.asNameMap()[raw['palette']];
  if (pattern == null || palette == null) return null;
  final intensity = raw['intensity'];
  return WallpaperSpec(
    pattern: pattern,
    palette: palette,
    intensity: intensity is num ? intensity.toDouble().clamp(0, 1) : 0.5,
  );
}

/// A small copy of an image wallpaper, for cards.
String? galleryThumbOf(GalleryItem item) {
  if (item.type != 'wallpaper') return null;
  final doc = _doc(item);
  if (doc['kind'] != 'image') return null;
  final file = doc['thumb'] ?? doc['file'];
  return file is String ? '$galleryHost/wallpapers/${item.id}/$file' : null;
}

String? galleryHeadingFontOf(GalleryItem item) =>
    item.type == 'theme' ? _doc(item)['headingFont'] as String? : null;
String? galleryBodyFontOf(GalleryItem item) =>
    item.type == 'theme' ? _doc(item)['bodyFont'] as String? : null;

/// What the screen looks like with [item]: everything it brings, the rest from [current]. With
/// [alone], a color scheme is shown on a plain background so schemes compare on their own.
class GalleryLook {
  const GalleryLook({
    required this.scheme,
    required this.headingFont,
    required this.bodyFont,
    this.wallpaper,
  });
  final ThemeChoice scheme;
  final String headingFont;
  final String bodyFont;

  /// Null draws the plain surface.
  final WallpaperSpec? wallpaper;

  factory GalleryLook.of(
    GalleryItem item,
    Appearance current, {
    bool alone = false,
    bool thumb = false,
  }) => GalleryLook(
    scheme: galleryChoiceOf(item) ?? current.scheme,
    headingFont: galleryHeadingFontOf(item) ?? current.headingFont,
    bodyFont: galleryBodyFontOf(item) ?? current.bodyFont,
    wallpaper: switch (item.type) {
      'scheme' => alone ? null : current.wallpaper,
      _ => galleryWallpaperOf(item, thumb: thumb) ?? current.wallpaper,
    },
  );
}

/// Whether [item] is what this device uses now.
bool galleryInUse(GalleryItem item, Appearance a) {
  bool sameWall(WallpaperSpec? b) {
    if (b == null) return false;
    final w = a.wallpaper;
    if (b.photo != null) return w.photo == b.photo;
    return w.photo == null && w.pattern == b.pattern && w.palette == b.palette;
  }

  switch (item.type) {
    case 'scheme':
      return a.schemeId == gallerySchemeId(item);
    case 'wallpaper':
      return sameWall(galleryWallpaperOf(item));
    case 'theme':
      final scheme = _doc(item)['scheme'];
      final id = scheme is String ? scheme : gallerySchemeId(item);
      return a.schemeId == id &&
          a.headingFont == galleryHeadingFontOf(item) &&
          a.bodyFont == galleryBodyFontOf(item) &&
          sameWall(galleryWallpaperOf(item));
  }
  return false;
}

final _schemes = <String, ColorScheme>{};

/// The full color scheme the app builds from [choice], with the app's own settings (see
/// AppTheme), without building a whole theme per card.
ColorScheme galleryColorScheme(ThemeChoice choice, Brightness brightness) {
  final key =
      '${choice.id}/${choice.data.light.primary.toARGB32()}/$brightness';
  final hit = _schemes[key];
  if (hit != null) return hit;
  if (_schemes.length > 96) _schemes.clear();
  const keys = FlexKeyColors(
    useKeyColors: true,
    useSecondary: true,
    useTertiary: true,
    keepPrimary: true,
    keepSecondary: true,
    keepTertiary: true,
  );
  final scheme = brightness == Brightness.dark
      ? FlexColorScheme.dark(
          colors: choice.data.dark,
          keyColors: keys,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 12,
          useMaterial3: true,
        ).toScheme
      : FlexColorScheme.light(
          colors: choice.data.light,
          keyColors: keys,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 6,
          useMaterial3: true,
        ).toScheme;
  return _schemes[key] = scheme;
}

/// A Casama chat drawn at a fixed size and scaled into its box like a screenshot, so a card and
/// the detail sheet show the same picture at different sizes.
class GalleryChatPreview extends StatelessWidget {
  const GalleryChatPreview({
    super.key,
    required this.look,
    required this.brightness,
    this.aspectRatio = 4 / 3,
  });

  final GalleryLook look;
  final Brightness brightness;
  final double aspectRatio;

  static const _width = 320.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = galleryColorScheme(look.scheme, brightness);
    final dark = brightness == Brightness.dark;
    final height = _width / aspectRatio;
    final heading = fontStyle(
      look.headingFont,
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        height: 1.1,
      ),
    );
    final body = fontStyle(
      look.bodyFont,
      TextStyle(fontSize: 12.5, color: scheme.onSurface, height: 1.32),
    );
    final botFill = dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
    final meFill = Color.alphaBlend(
      scheme.primary.withValues(alpha: dark ? 0.32 : 0.18),
      botFill,
    );
    Widget bubble(String text, Color fill, {required bool mine}) => Container(
      constraints: const BoxConstraints(maxWidth: _width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(mine ? 16 : 5),
          topRight: Radius.circular(mine ? 16 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: Radius.circular(mine ? 5 : 16),
        ),
      ),
      child: Text(text, style: body),
    );
    final wallpaper = look.wallpaper;
    // The header, then the conversation anchored to the bottom like a chat: when a wide font makes
    // the bubbles taller than the screen, the top is cut off under the clip instead of overflowing.
    final header = // On a translucent bar like the app's header, so the name reads on any background.
    Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.cloud, size: 13, color: scheme.onPrimary),
            ),
            const SizedBox(width: 8),
            Text('Casama', style: heading),
          ],
        ),
      ),
    );
    final chat = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: bubble(l10n.previewAsk, meFill, mine: true),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: bubble(l10n.previewDone, botFill, mine: false),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: dark
                                ? scheme.surfaceContainer
                                : scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.previewMessage,
                            style: body.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.arrowUp,
                          size: 16,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(alignment: Alignment.topLeft, child: header),
        ],
      ),
    );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _width,
          height: height,
          child: MediaQuery.withNoTextScaling(
            child: wallpaper == null
                ? ColoredBox(color: scheme.surface, child: chat)
                : Wallpaper(
                    force: true,
                    specOverride: WallpaperTheme.of(wallpaper, scheme),
                    child: chat,
                  ),
          ),
        ),
      ),
    );
  }
}

/// A wallpaper on its own: the image, or the pattern in the current colors.
class GalleryWallpaperPreview extends StatelessWidget {
  const GalleryWallpaperPreview({
    super.key,
    required this.item,
    required this.scheme,
    required this.brightness,
  });
  final GalleryItem item;
  final ThemeChoice scheme;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final colors = galleryColorScheme(scheme, brightness);
    final thumb = galleryThumbOf(item);
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
    final spec = galleryWallpaperOf(item);
    if (spec == null) return ColoredBox(color: colors.surfaceContainerHigh);
    return Wallpaper(
      force: true,
      specOverride: WallpaperTheme.of(spec, colors),
      child: const SizedBox.expand(),
    );
  }
}

/// A color scheme as fields of its own colors: the primary large with type on it, its container,
/// secondary and tertiary beside it, so schemes tell apart at a glance in a row of cards.
class GallerySchemeSwatch extends StatelessWidget {
  const GallerySchemeSwatch({
    super.key,
    required this.scheme,
    required this.brightness,
    required this.headingFont,
    this.aspectRatio = 4 / 3,
  });
  final ThemeChoice scheme;
  final Brightness brightness;
  final String headingFont;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final c = galleryColorScheme(scheme, brightness);
    Widget block(Color fill, Color ink, {double size = 13}) => ColoredBox(
      color: fill,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 8, 7),
          child: Text(
            'Aa',
            style: fontStyle(
              headingFont,
              TextStyle(
                fontSize: size,
                color: ink,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: MediaQuery.withNoTextScaling(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: block(c.primary, c.onPrimary, size: 30)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: block(c.primaryContainer, c.onPrimaryContainer),
                  ),
                  Expanded(child: block(c.secondary, c.onSecondary)),
                  Expanded(child: block(c.tertiary, c.onTertiary)),
                  Expanded(child: block(c.surface, c.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

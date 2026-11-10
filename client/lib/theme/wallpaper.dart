// Render-object fields are private with public setters; their constructor can't use this._x.
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Doodle patterns drawn over the wallpaper gradient, Telegram style, from Lucide glyphs.
enum WallpaperPattern {
  none('Plain', []),
  clouds('Clouds', [
    LucideIcons.cloud,
    LucideIcons.cloudSun,
    LucideIcons.star,
    LucideIcons.sparkle,
    LucideIcons.cloudMoon,
    LucideIcons.moon,
    LucideIcons.sparkles,
    LucideIcons.orbit,
    LucideIcons.rainbow,
  ]),
  doodles('Doodles', [
    LucideIcons.messageCircle,
    LucideIcons.heart,
    LucideIcons.star,
    LucideIcons.smile,
    LucideIcons.coffee,
    LucideIcons.music,
    LucideIcons.rocket,
    LucideIcons.gift,
    LucideIcons.sun,
    LucideIcons.cat,
    LucideIcons.bot,
    LucideIcons.pencil,
    LucideIcons.camera,
    LucideIcons.umbrella,
    LucideIcons.headphones,
    LucideIcons.gamepad2,
  ]),
  treats('Treats', [
    LucideIcons.iceCreamCone,
    LucideIcons.cake,
    LucideIcons.candy,
    LucideIcons.popsicle,
    LucideIcons.cookie,
    LucideIcons.donut,
    LucideIcons.lollipop,
    LucideIcons.croissant,
    LucideIcons.cherry,
    LucideIcons.citrus,
    LucideIcons.coffee,
    LucideIcons.heart,
  ]),
  garden('Garden', [
    LucideIcons.leaf,
    LucideIcons.flower,
    LucideIcons.flower2,
    LucideIcons.sprout,
    LucideIcons.sun,
    LucideIcons.cherry,
    LucideIcons.trees,
    LucideIcons.bug,
    LucideIcons.clover,
    LucideIcons.snail,
    LucideIcons.feather,
  ]),
  space('Space', [
    LucideIcons.rocket,
    LucideIcons.orbit,
    LucideIcons.moon,
    LucideIcons.star,
    LucideIcons.sparkles,
    LucideIcons.satellite,
    LucideIcons.telescope,
    LucideIcons.earth,
    LucideIcons.sparkle,
    LucideIcons.ghost,
  ]),
  pets('Pets', [
    LucideIcons.cat,
    LucideIcons.dog,
    LucideIcons.pawPrint,
    LucideIcons.bone,
    LucideIcons.fish,
    LucideIcons.heart,
    LucideIcons.bird,
    LucideIcons.rabbit,
    LucideIcons.turtle,
    LucideIcons.squirrel,
  ]),
  sea('Seaside', [
    LucideIcons.shell,
    LucideIcons.waves,
    LucideIcons.sailboat,
    LucideIcons.anchor,
    LucideIcons.fish,
    LucideIcons.palmtree,
    LucideIcons.sun,
    LucideIcons.umbrella,
    LucideIcons.cloud,
  ]),
  tech('Tech', [
    LucideIcons.bot,
    LucideIcons.monitor,
    LucideIcons.laptop,
    LucideIcons.terminal,
    LucideIcons.cpu,
    LucideIcons.code,
    LucideIcons.cloud,
    LucideIcons.zap,
    LucideIcons.wifi,
    LucideIcons.mousePointer2,
    LucideIcons.keyboard,
    LucideIcons.server,
  ]);

  const WallpaperPattern(this.label, this.glyphs);
  final String label;
  final List<IconData> glyphs;
}

/// A soft four-color gradient behind the pattern. `theme` follows the chosen color scheme.
enum WallpaperPalette {
  theme('Theme', []),
  kasama(
    'Kasama',
    [Color(0xFFEEE2FB), Color(0xFFFBE3EE), Color(0xFFDDE9FF), Color(0xFFDDF7F5)],
    dark: [Color(0xFF25102F), Color(0xFF34123A), Color(0xFF151F3F), Color(0xFF0F292E)],
  ),
  lavender('Lavender', [Color(0xFFE7DEFF), Color(0xFFF3E6FF), Color(0xFFDCD3FF), Color(0xFFFBEFFF)]),
  cotton('Cotton candy', [Color(0xFFFFDDEB), Color(0xFFE1E4FF), Color(0xFFFFE9F2), Color(0xFFDCEFFF)]),
  peach('Peach', [Color(0xFFFFE3D3), Color(0xFFFFD6DF), Color(0xFFFFF0D4), Color(0xFFFFE2EA)]),
  sunset('Sunset', [Color(0xFFFFD9BF), Color(0xFFFFC9D6), Color(0xFFF2D3FF), Color(0xFFFFE6C2)]),
  mint('Mint', [Color(0xFFD5F5E7), Color(0xFFE3FAF3), Color(0xFFCDEFDE), Color(0xFFEDFBEF)]),
  ocean('Ocean', [Color(0xFFD4EAFF), Color(0xFFCFF1F8), Color(0xFFDDE3FF), Color(0xFFC9E8FF)]),
  forest('Forest', [Color(0xFFDDEDD2), Color(0xFFCFE8D7), Color(0xFFECF2D0), Color(0xFFD6ECE3)]),
  graphite('Graphite', [Color(0xFFE9EBEF), Color(0xFFE1E4EA), Color(0xFFEEF0F3), Color(0xFFDDE1E7)]);

  const WallpaperPalette(this.label, this.light, {this.dark});
  final String label;
  final List<Color> light;
  final List<Color>? dark;

  /// The four gradient colors for [scheme]'s brightness.
  List<Color> colorsFor(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (this == WallpaperPalette.theme) {
      // The scheme's own hues, washed out (light) or deepened (dark), so every scheme gets a
      // matching wallpaper.
      final toward = isDark ? const Color(0xFF0C0B11) : Colors.white;
      final k = isDark ? 0.0 : 0.04;
      return [
        Color.lerp(scheme.primary, toward, 0.84 + k)!,
        Color.lerp(scheme.tertiary, toward, 0.82 + k)!,
        Color.lerp(scheme.secondary, toward, 0.84 + k)!,
        Color.lerp(scheme.primary, toward, 0.9 + k)!,
      ];
    }
    final base = light;
    if (!isDark) return base;
    // Night versions: the same hues, deep and quiet.
    return dark ?? [for (final c in base) Color.lerp(c, const Color(0xFF0C0B11), 0.86)!];
  }
}

/// What Settings → Background chose.
@immutable
class WallpaperSpec {
  const WallpaperSpec({this.pattern = WallpaperPattern.clouds, this.palette = WallpaperPalette.theme, this.intensity = 0.5, this.everywhere = true});

  final WallpaperPattern pattern;
  final WallpaperPalette palette;

  /// How strongly the pattern shows, 0 to 1.
  final double intensity;

  /// Behind every screen, or only behind chats.
  final bool everywhere;

  WallpaperSpec copyWith({WallpaperPattern? pattern, WallpaperPalette? palette, double? intensity, bool? everywhere}) => WallpaperSpec(
    pattern: pattern ?? this.pattern,
    palette: palette ?? this.palette,
    intensity: intensity ?? this.intensity,
    everywhere: everywhere ?? this.everywhere,
  );

  @override
  bool operator ==(Object other) =>
      other is WallpaperSpec && other.pattern == pattern && other.palette == palette && other.intensity == intensity && other.everywhere == everywhere;

  @override
  int get hashCode => Object.hash(pattern, palette, intensity, everywhere);
}

/// The wallpaper as the theme carries it, so every page can paint it without reaching for state.
class WallpaperTheme extends ThemeExtension<WallpaperTheme> {
  const WallpaperTheme({required this.spec, required this.colors, required this.ink, required this.surface});

  factory WallpaperTheme.of(WallpaperSpec spec, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final ink = isDark ? Color.lerp(scheme.primary, Colors.white, 0.35)! : Color.lerp(scheme.primary, Colors.black, 0.25)!;
    return WallpaperTheme(spec: spec, colors: spec.palette.colorsFor(scheme), ink: ink, surface: scheme.surface);
  }

  final WallpaperSpec spec;
  final List<Color> colors;

  /// The doodles' color before [WallpaperSpec.intensity] is applied.
  final Color ink;

  /// Plain background, for pages when the wallpaper is set to chats only.
  final Color surface;

  @override
  WallpaperTheme copyWith({WallpaperSpec? spec, List<Color>? colors, Color? ink, Color? surface}) =>
      WallpaperTheme(spec: spec ?? this.spec, colors: colors ?? this.colors, ink: ink ?? this.ink, surface: surface ?? this.surface);

  @override
  WallpaperTheme lerp(covariant WallpaperTheme? other, double t) {
    if (other == null) return this;
    return WallpaperTheme(
      spec: t < 0.5 ? spec : other.spec,
      colors: [for (var i = 0; i < colors.length && i < other.colors.length; i++) Color.lerp(colors[i], other.colors[i], t)!],
      ink: Color.lerp(ink, other.ink, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

/// Paints the wallpaper behind [child]. Pages get it from [WallpaperPageTransitionsBuilder];
/// chats use `force` so they keep it when the wallpaper is set to chats only.
class Wallpaper extends StatelessWidget {
  const Wallpaper({super.key, required this.child, this.force = false, this.specOverride});
  final Widget child;
  final bool force;

  /// Previews in Settings show a choice before it is applied.
  final WallpaperTheme? specOverride;

  @override
  Widget build(BuildContext context) {
    final theme = specOverride ?? Theme.of(context).extension<WallpaperTheme>();
    if (theme == null) return child;
    final plain = !force && !theme.spec.everywhere;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: _WallpaperLayer(
              theme: theme,
              plain: plain,
              screen: specOverride != null ? null : MediaQuery.sizeOf(context),
              textDirection: Directionality.of(context),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Wraps every page route's content in a [Wallpaper], so each page is opaque during transitions
/// and the wallpaper shows behind every screen.
class WallpaperPageTransitionsBuilder extends PageTransitionsBuilder {
  const WallpaperPageTransitionsBuilder(this.base);
  final PageTransitionsBuilder base;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      base.buildTransitions(route, context, animation, secondaryAnimation, Wallpaper(child: child));
}

class _WallpaperLayer extends LeafRenderObjectWidget {
  const _WallpaperLayer({required this.theme, required this.plain, required this.screen, required this.textDirection});
  final WallpaperTheme theme;
  final bool plain;

  /// The window size, so the gradient and pattern line up across the shell's panes. Null in
  /// previews, which paint relative to themselves.
  final Size? screen;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWallpaper(theme: theme, plain: plain, screen: screen, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderWallpaper renderObject) {
    renderObject
      ..theme = theme
      ..plain = plain
      ..screen = screen
      ..textDirection = textDirection;
  }
}

class _RenderWallpaper extends RenderBox {
  _RenderWallpaper({required WallpaperTheme theme, required bool plain, required Size? screen, required TextDirection textDirection})
    : _theme = theme,
      _plain = plain,
      _screen = screen,
      _textDirection = textDirection;

  WallpaperTheme _theme;
  set theme(WallpaperTheme v) {
    if (v == _theme) return;
    _theme = v;
    markNeedsPaint();
  }

  bool _plain;
  set plain(bool v) {
    if (v == _plain) return;
    _plain = v;
    markNeedsPaint();
  }

  Size? _screen;
  set screen(Size? v) {
    if (v == _screen) return;
    _screen = v;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rect = offset & size;
    if (_plain) {
      canvas.drawRect(rect, Paint()..color = _theme.surface);
      return;
    }
    // Paint in window coordinates so neighbouring panes (sidebar, chat, computer panel) join up.
    final global = _screen == null ? Offset.zero : localToGlobal(Offset.zero);
    final world = Rect.fromLTWH(offset.dx - global.dx, offset.dy - global.dy, (_screen ?? size).width, (_screen ?? size).height);
    canvas.save();
    canvas.clipRect(rect);
    _paintGradient(canvas, world, _theme.colors);
    final spec = _theme.spec;
    if (spec.pattern != WallpaperPattern.none && spec.intensity > 0) {
      final dark = _theme.surface.computeLuminance() < 0.2;
      final alpha = (dark ? 0.16 : 0.22) * spec.intensity;
      _paintPattern(canvas, rect, world.topLeft, spec.pattern, _theme.ink.withValues(alpha: alpha.clamp(0, 1)));
    }
    canvas.restore();
  }

  static void _paintGradient(Canvas canvas, Rect world, List<Color> c) {
    if (c.length < 4) {
      canvas.drawRect(world, Paint()..color = c.isEmpty ? Colors.transparent : c.first);
      return;
    }
    canvas.drawRect(world, Paint()..color = c[0]);
    final r = world.longestSide * 0.85;
    // Three soft blobs on the base, like Telegram's gradient wallpapers.
    for (final (color, at) in [(c[1], const Offset(0.85, 0.12)), (c[2], const Offset(0.15, 0.55)), (c[3], const Offset(0.7, 0.92))]) {
      final center = Offset(world.left + world.width * at.dx, world.top + world.height * at.dy);
      canvas.drawRect(
        world,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  static const _tile = 260.0;
  static final Map<(WallpaperPattern, int), ui.Picture> _tiles = {};

  static ui.Picture _tileFor(WallpaperPattern pattern, Color ink) {
    final key = (pattern, ink.toARGB32());
    final cached = _tiles[key];
    if (cached != null) return cached;
    if (_tiles.length > 24) _tiles.clear();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rnd = math.Random(pattern.index * 7919 + 17);
    const cells = 4;
    const cell = _tile / cells;
    for (var row = 0; row < cells; row++) {
      for (var col = 0; col < cells; col++) {
        final glyph = pattern.glyphs[rnd.nextInt(pattern.glyphs.length)];
        final size = 17 + rnd.nextDouble() * 10;
        // Offset every other row by half a cell so the doodles don't line up in columns.
        final x = (col + 0.5 + (row.isOdd ? 0.5 : 0)) * cell + (rnd.nextDouble() - 0.5) * cell * 0.35;
        final y = (row + 0.5) * cell + (rnd.nextDouble() - 0.5) * cell * 0.35;
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(glyph.codePoint),
            style: TextStyle(fontFamily: glyph.fontFamily, package: glyph.fontPackage, fontSize: size, color: ink, height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final angle = (rnd.nextDouble() - 0.5) * 0.7;
        // Glyphs that cross an edge are drawn again on the far side, so tiles join seamlessly.
        for (final dx in const [0.0, -_tile, _tile]) {
          for (final dy in const [0.0, -_tile, _tile]) {
            final px = x + dx, py = y + dy;
            if (px < -size || px > _tile + size || py < -size || py > _tile + size) continue;
            canvas.save();
            canvas.translate(px, py);
            canvas.rotate(angle);
            painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
            canvas.restore();
          }
        }
        painter.dispose();
      }
    }
    return _tiles[key] = recorder.endRecording();
  }

  static void _paintPattern(Canvas canvas, Rect rect, Offset origin, WallpaperPattern pattern, Color ink) {
    final tile = _tileFor(pattern, ink);
    final startX = origin.dx + ((rect.left - origin.dx) / _tile).floor() * _tile;
    final startY = origin.dy + ((rect.top - origin.dy) / _tile).floor() * _tile;
    for (var y = startY; y < rect.bottom; y += _tile) {
      for (var x = startX; x < rect.right; x += _tile) {
        canvas.save();
        canvas.translate(x, y);
        // Each tile shows only its own square; the wrapped copies fill in across the seams.
        canvas.clipRect(const Rect.fromLTWH(0, 0, _tile, _tile));
        canvas.drawPicture(tile);
        canvas.restore();
      }
    }
  }
}

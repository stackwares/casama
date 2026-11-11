// Render-object fields are private with public setters; their constructor can't use this._x.
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/local_image.dart';

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
  casama(
    'Casama',
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
  const WallpaperSpec({
    this.pattern = WallpaperPattern.clouds,
    this.palette = WallpaperPalette.theme,
    this.intensity = 0.5,
    this.everywhere = true,
    this.photo,
    this.photoBlur = 0.3,
    this.photoDim = 0.15,
    this.photoCredit,
    this.photoCreditUrl,
  });

  final WallpaperPattern pattern;
  final WallpaperPalette palette;

  /// How strongly the pattern shows, 0 to 1.
  final double intensity;

  /// Behind every screen, or only behind chats.
  final bool everywhere;

  /// A photo instead of the gradient: a file path, an https URL (Unsplash), or a data: URI (web).
  final String? photo;

  /// Photo blur and darkening (0 to 1), so text on top stays readable.
  final double photoBlur;
  final double photoDim;

  /// Who took the photo, for Unsplash attribution.
  final String? photoCredit;
  final String? photoCreditUrl;

  WallpaperSpec copyWith({
    WallpaperPattern? pattern,
    WallpaperPalette? palette,
    double? intensity,
    bool? everywhere,
    String? photo,
    bool clearPhoto = false,
    double? photoBlur,
    double? photoDim,
    String? photoCredit,
    String? photoCreditUrl,
  }) => WallpaperSpec(
    pattern: pattern ?? this.pattern,
    palette: palette ?? this.palette,
    intensity: intensity ?? this.intensity,
    everywhere: everywhere ?? this.everywhere,
    photo: clearPhoto ? null : (photo ?? this.photo),
    photoBlur: photoBlur ?? this.photoBlur,
    photoDim: photoDim ?? this.photoDim,
    photoCredit: clearPhoto ? null : (photoCredit ?? this.photoCredit),
    photoCreditUrl: clearPhoto ? null : (photoCreditUrl ?? this.photoCreditUrl),
  );

  /// The same wallpaper with its photo credit replaced (null clears it).
  WallpaperSpec copyWithCredit(String? credit, String? url) => WallpaperSpec(
    pattern: pattern,
    palette: palette,
    intensity: intensity,
    everywhere: everywhere,
    photo: photo,
    photoBlur: photoBlur,
    photoDim: photoDim,
    photoCredit: credit,
    photoCreditUrl: url,
  );

  Map<String, Object?> toJson() => {
    'pattern': pattern.name,
    'palette': palette.name,
    'intensity': intensity,
    'everywhere': everywhere,
    if (photo != null) 'photo': photo,
    'photoBlur': photoBlur,
    'photoDim': photoDim,
    if (photoCredit != null) 'photoCredit': photoCredit,
    if (photoCreditUrl != null) 'photoCreditUrl': photoCreditUrl,
  };

  factory WallpaperSpec.fromJson(Map<String, Object?> j) {
    const d = WallpaperSpec();
    double unit(Object? v, double fallback) => v is num ? v.toDouble().clamp(0, 1) : fallback;
    return WallpaperSpec(
      pattern: WallpaperPattern.values.asNameMap()[j['pattern']] ?? d.pattern,
      palette: WallpaperPalette.values.asNameMap()[j['palette']] ?? d.palette,
      intensity: unit(j['intensity'], d.intensity),
      everywhere: j['everywhere'] is bool ? j['everywhere']! as bool : d.everywhere,
      photo: j['photo'] as String?,
      photoBlur: unit(j['photoBlur'], d.photoBlur),
      photoDim: unit(j['photoDim'], d.photoDim),
      photoCredit: j['photoCredit'] as String?,
      photoCreditUrl: j['photoCreditUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is WallpaperSpec && const DeepCollectionEqualityLite().equals(toJson(), other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().entries.map((e) => Object.hash(e.key, e.value)));
}

/// Map equality for flat JSON maps, without pulling in package:collection.
class DeepCollectionEqualityLite {
  const DeepCollectionEqualityLite();
  bool equals(Map<String, Object?> a, Map<String, Object?> b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
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

  // Equal values compare equal, so a rebuilt theme with the same wallpaper isn't a theme change
  // (which would animate the whole app) and the wallpaper isn't repainted.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WallpaperTheme || other.spec != spec || other.ink != ink || other.surface != surface || other.colors.length != colors.length) return false;
    for (var i = 0; i < colors.length; i++) {
      if (other.colors[i] != colors[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(spec, ink, surface, Object.hashAll(colors));

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
class Wallpaper extends StatefulWidget {
  const Wallpaper({super.key, required this.child, this.force = false, this.specOverride});
  final Widget child;
  final bool force;

  /// Previews in Settings show a choice before it is applied.
  final WallpaperTheme? specOverride;

  @override
  State<Wallpaper> createState() => _WallpaperState();
}

class _WallpaperState extends State<Wallpaper> {
  // The layer paints in window coordinates, measured when it paints. Behind its repaint boundary a
  // page transition only moves the cached picture, so repaint once a transition settles; otherwise
  // the picture keeps the mid-animation position (a misaligned photo and an undimmed strip).
  var _epoch = 0;
  final _watched = <Animation<double>>[];

  void _settled(AnimationStatus s) {
    if ((s == AnimationStatus.completed || s == AnimationStatus.dismissed) && mounted) setState(() => _epoch++);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final now = [?route?.animation, ?route?.secondaryAnimation];
    if (now.length == _watched.length && now.indexed.every((e) => identical(e.$2, _watched[e.$1]))) return;
    for (final a in _watched) {
      a.removeStatusListener(_settled);
    }
    _watched
      ..clear()
      ..addAll(now);
    for (final a in _watched) {
      a.addStatusListener(_settled);
    }
  }

  @override
  void dispose() {
    for (final a in _watched) {
      a.removeStatusListener(_settled);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specOverride = widget.specOverride;
    final child = widget.child;
    final force = widget.force;
    final theme = specOverride ?? Theme.of(context).extension<WallpaperTheme>();
    if (theme == null) return child;
    final plain = !force && !theme.spec.everywhere;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: _PhotoLoader(
              source: plain ? null : theme.spec.photo,
              builder: (photo) => _WallpaperLayer(
                epoch: _epoch,
                theme: theme,
                plain: plain,
                photo: photo,
                screen: specOverride != null ? null : MediaQuery.sizeOf(context),
                textDirection: Directionality.of(context),
              ),
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

/// Loads the wallpaper photo, if there is one, and hands the decoded image to [builder]. Until it
/// arrives (or if it fails) the gradient shows.
class _PhotoLoader extends StatefulWidget {
  const _PhotoLoader({required this.source, required this.builder});
  final String? source;
  final Widget Function(ui.Image? photo) builder;

  @override
  State<_PhotoLoader> createState() => _PhotoLoaderState();
}

class _PhotoLoaderState extends State<_PhotoLoader> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_PhotoLoader old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) _resolve();
  }

  void _resolve() {
    final source = widget.source;
    if (source == null) {
      _stop();
      if (_info != null) setState(() => _info = null);
      return;
    }
    // Decoded no larger than this display (a 24-megapixel photo is ~100 MB as pixels otherwise).
    final display = View.maybeOf(context)?.display.size;
    final longest = display == null ? 2560 : math.max(display.width, display.height).round().clamp(1024, 2560);
    final provider = ResizeImage.resizeIfNeeded(longest, longest, imageProviderFor(source));
    final stream = (provider is ResizeImage ? ResizeImage(provider.imageProvider, width: longest, height: longest, policy: ResizeImagePolicy.fit) : provider).resolve(
      createLocalImageConfiguration(context),
    );
    if (stream.key == _stream?.key) return;
    _stop();
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _info = info);
      },
      onError: (e, _) => debugPrint('wallpaper photo: $e'),
    );
    stream.addListener(_listener!);
  }

  void _stop() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.source == null ? null : _info?.image);
}

class _WallpaperLayer extends LeafRenderObjectWidget {
  const _WallpaperLayer({required this.theme, required this.plain, required this.screen, required this.textDirection, this.photo, this.epoch = 0});
  final WallpaperTheme theme;

  /// Bumped to repaint after the page moved (see [_WallpaperState]).
  final int epoch;
  final bool plain;
  final ui.Image? photo;

  /// The window size, so the gradient and pattern line up across the shell's panes. Null in
  /// previews, which paint relative to themselves.
  final Size? screen;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWallpaper(
    theme: theme,
    plain: plain,
    screen: screen,
    textDirection: textDirection,
    photo: photo,
  )..pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;

  @override
  void updateRenderObject(BuildContext context, _RenderWallpaper renderObject) {
    renderObject
      ..pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1
      ..theme = theme
      ..plain = plain
      ..photo = photo
      ..screen = screen
      ..textDirection = textDirection
      ..epoch = epoch;
  }
}

class _RenderWallpaper extends RenderBox {
  _RenderWallpaper({required WallpaperTheme theme, required bool plain, required Size? screen, required TextDirection textDirection, ui.Image? photo})
    : _theme = theme,
      _photo = photo,
      _plain = plain,
      _screen = screen,
      _textDirection = textDirection;

  WallpaperTheme _theme;
  set theme(WallpaperTheme v) {
    if (v == _theme) return;
    _theme = v;
    markNeedsPaint();
  }

  ui.Image? _photo;
  set photo(ui.Image? v) {
    if (v == _photo) return;
    _photo = v;
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

  int _epoch = 0;
  set epoch(int v) {
    if (v == _epoch) return;
    _epoch = v;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsPaint();
  }

  /// The screen's pixel density, so the pattern tile is drawn sharp.
  double _pixelRatio = 1;
  set pixelRatio(double v) {
    if (v == _pixelRatio) return;
    _pixelRatio = v;
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
    final spec = _theme.spec;
    final photo = _photo;
    if (photo != null) {
      _paintPhoto(canvas, world, rect, photo, spec, _theme.surface);
    } else {
      _paintGradient(canvas, world, _theme.colors, cover: world.expandToInclude(rect));
    }
    if (spec.pattern != WallpaperPattern.none && spec.intensity > 0) {
      final dark = _theme.surface.computeLuminance() < 0.2;
      final alpha = (dark ? 0.16 : 0.22) * spec.intensity;
      _paintPattern(canvas, rect, world.topLeft, spec.pattern, _theme.ink.withValues(alpha: alpha.clamp(0, 1)), _pixelRatio);
    }
    canvas.restore();
  }

  /// The photo covering the whole window, blurred and dimmed toward the surface color so text on
  /// top stays readable.
  static void _paintPhoto(Canvas canvas, Rect world, Rect painted, ui.Image photo, WallpaperSpec spec, Color surface) {
    final sigma = spec.photoBlur * 40;
    // Drawn a little larger than the window so the blur doesn't fade at the edges, and always over
    // everything painted (a frame painted mid-transition may sit partly outside the window).
    final cover = world.expandToInclude(painted);
    final target = cover.inflate(sigma * 2);
    if (sigma > 0.5) {
      final blurred = _blurredPhoto(photo, sigma, target.size);
      canvas.drawImageRect(
        blurred,
        Offset.zero & Size(blurred.width.toDouble(), blurred.height.toDouble()),
        target,
        Paint()
          ..filterQuality = FilterQuality.low
          ..isAntiAlias = false,
      );
    } else {
      final src = Offset.zero & Size(photo.width.toDouble(), photo.height.toDouble());
      final fitted = applyBoxFit(BoxFit.cover, src.size, target.size);
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = false;
      canvas.drawImageRect(photo, Alignment.center.inscribe(fitted.source, src), target, paint);
    }
    if (spec.photoDim > 0) {
      canvas.drawRect(cover, Paint()..color = surface.withValues(alpha: spec.photoDim * 0.85));
    }
  }

  static void _paintGradient(Canvas canvas, Rect world, List<Color> c, {Rect? cover}) {
    final base = cover ?? world;
    if (c.length < 4) {
      canvas.drawRect(base, Paint()..color = c.isEmpty ? Colors.transparent : c.first);
      return;
    }
    canvas.drawRect(base, Paint()..color = c[0]);
    final r = world.longestSide * 0.85;
    // Three soft blobs on the base, like Telegram's gradient wallpapers. They are placed by the
    // window but drawn over everything painted: a page cached mid-transition sits partly outside the
    // window, and clipping the blobs to the window left that part bare base color, a dark strip that
    // slid in with the page.
    for (final (color, at) in [(c[1], const Offset(0.85, 0.12)), (c[2], const Offset(0.15, 0.55)), (c[3], const Offset(0.7, 0.92))]) {
      final center = Offset(world.left + world.width * at.dx, world.top + world.height * at.dy);
      canvas.drawRect(
        base,
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  // The blurred photo, made once at a fraction of the window's size and then only stretched: a
  // Gaussian blur over the whole window on every frame is the most a page could cost the GPU, and
  // a blurred picture loses nothing at low resolution. Pages share it.
  static ({ui.Image photo, double sigma, int width, int height, ui.Image image})? _blur;

  static ui.Image _blurredPhoto(ui.Image photo, double sigma, Size target) {
    // Small enough to be cheap, large enough that the blur still spans 4 pixels.
    final scale = (sigma / 4).clamp(1.0, 8.0);
    // Sizes in steps of 16 pixels, so resizing a window doesn't redo it on every frame.
    int step(double v) => math.max(16, ((v / scale) / 16).ceil() * 16);
    final width = step(target.width), height = step(target.height);
    final cached = _blur;
    if (cached != null && cached.sigma == sigma && cached.width == width && cached.height == height && cached.photo.isCloneOf(photo)) return cached.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final src = Offset.zero & Size(photo.width.toDouble(), photo.height.toDouble());
    final size = Size(width.toDouble(), height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, src.size, size);
    canvas.drawImageRect(
      photo,
      Alignment.center.inscribe(fitted.source, src),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma / scale, sigmaY: sigma / scale, tileMode: TileMode.clamp),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    // The old picture may still be on screen in a layer, which keeps its own reference.
    cached?.photo.dispose();
    _blur = (photo: photo.clone(), sigma: sigma, width: width, height: height, image: image);
    return image;
  }

  static const _tile = 260.0;
  static final Map<(WallpaperPattern, int), ui.Picture> _tiles = {};
  static final Map<(WallpaperPattern, int), ui.Image> _masks = {};

  /// The pattern tile as a white mask at the screen's density, tinted when drawn: the pattern is
  /// then one draw of a repeating image rather than hundreds of rotated glyphs on every frame.
  static ui.Image _maskFor(WallpaperPattern pattern, double pixelRatio) {
    final px = (_tile * pixelRatio).ceil();
    final key = (pattern, px);
    final cached = _masks[key];
    if (cached != null) return cached;
    if (_masks.length >= 4) _masks.clear();
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(px / _tile)
      ..clipRect(const Rect.fromLTWH(0, 0, _tile, _tile))
      ..drawPicture(_tileFor(pattern, const Color(0xFFFFFFFF)));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(px, px);
    picture.dispose();
    return _masks[key] = image;
  }

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

  static void _paintPattern(Canvas canvas, Rect rect, Offset origin, WallpaperPattern pattern, Color ink, double pixelRatio) {
    final mask = _maskFor(pattern, pixelRatio);
    // Image pixels to canvas: scaled to one tile, and anchored at the window's origin so panes join.
    final s = _tile / mask.width;
    final matrix = Float64List(16)
      ..[0] = s
      ..[5] = s
      ..[10] = 1
      ..[12] = origin.dx
      ..[13] = origin.dy
      ..[15] = 1;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ImageShader(mask, TileMode.repeated, TileMode.repeated, matrix, filterQuality: FilterQuality.low)
        ..colorFilter = ColorFilter.mode(ink, BlendMode.srcIn),
    );
  }
}

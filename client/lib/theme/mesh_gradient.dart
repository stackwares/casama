import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A mesh gradient: a 3×3 grid of colors at (possibly warped) points, blended smoothly.
///
/// The grid is interpolated with Catmull-Rom splines, colors in OKLab so blends between hues stay
/// clean instead of passing through grey. The result is drawn as one triangle mesh with per-vertex
/// colors, fine enough that the triangles don't show. Meshes are cached by size and colors, so
/// repainting a page only redraws the cached vertices.
abstract final class MeshGradient {
  /// The evenly spaced 3×3 grid, row by row from the top left.
  static const evenPoints = [
    Offset.zero,
    Offset(0.5, 0),
    Offset(1, 0),
    Offset(0, 0.5),
    Offset(0.5, 0.5),
    Offset(1, 0.5),
    Offset(0, 1),
    Offset(0.5, 1),
    Offset(1, 1),
  ];

  /// Paints the mesh laid out over [world] (points are fractions of it). The mesh's outer edge
  /// runs on a window's width past [world], so a page painted partly outside the window (mid
  /// transition) still has no bare strip. The mesh only depends on the window's size, so moving
  /// pages reuse the cached one.
  static void paint(
    Canvas canvas,
    Rect world,
    List<Color> colors,
    List<Offset> points,
  ) {
    assert(colors.length == 9 && points.length == 9);
    final key = _Key(colors, points, world.size);
    var vertices = _cache.remove(key);
    vertices ??= _build(key);
    _cache[key] = vertices;
    if (_cache.length > 48) _cache.remove(_cache.keys.first);
    canvas
      ..save()
      ..translate(world.left, world.top)
      ..drawVertices(vertices, BlendMode.dst, Paint())
      ..restore();
  }

  // Insertion-ordered, so the first key is the least recently used.
  static final _cache = <_Key, ui.Vertices>{};

  static ui.Vertices _build(_Key k) {
    final world = Offset.zero & k.size;
    final cover = world.inflate(world.longestSide);
    // Cells per side: enough for smooth curves on a full window, few for a small swatch.
    final n = (world.longestSide / 40).clamp(6, 28).round();
    final labs = [for (final c in k.colors) _toLab(c)];
    final colorGrid = [
      for (var r = 0; r < 3; r++) [for (var c = 0; c < 3; c++) labs[r * 3 + c]],
    ];
    final pointGrid = [
      for (var r = 0; r < 3; r++)
        [
          for (var c = 0; c < 3; c++)
            [k.points[r * 3 + c].dx, k.points[r * 3 + c].dy],
        ],
    ];
    // One extra ring outside the window repeats the edge colors out to [cover].
    final side = n + 3;
    final positions = Float32List(side * side * 2);
    final vertexColors = Int32List(side * side);
    for (var r = 0; r <= n; r++) {
      for (var c = 0; c <= n; c++) {
        final u = c / n;
        final v = r / n;
        final p = _sample(pointGrid, u, v);
        final x = world.left + p[0] * world.width;
        final y = world.top + p[1] * world.height;
        final color = _fromLab(_sample(colorGrid, u, v));
        // This vertex, and the ring copies it sits next to.
        for (final rr in [r + 1, if (r == 0) 0, if (r == n) n + 2]) {
          for (final cc in [c + 1, if (c == 0) 0, if (c == n) n + 2]) {
            final i = rr * side + cc;
            positions[i * 2] = cc == 0
                ? cover.left
                : cc == n + 2
                ? cover.right
                : x;
            positions[i * 2 + 1] = rr == 0
                ? cover.top
                : rr == n + 2
                ? cover.bottom
                : y;
            vertexColors[i] = color;
          }
        }
      }
    }
    final cells = side - 1;
    final indices = Uint16List(cells * cells * 6);
    var j = 0;
    for (var r = 0; r < cells; r++) {
      for (var c = 0; c < cells; c++) {
        final a = r * side + c;
        final b = a + 1;
        final d = a + side;
        final e = d + 1;
        indices
          ..[j++] = a
          ..[j++] = b
          ..[j++] = e
          ..[j++] = a
          ..[j++] = e
          ..[j++] = d;
      }
    }
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      colors: vertexColors,
      indices: indices,
    );
  }

  /// The grid's value at (u, v), each 0 to 1. Outside the grid, ghost points mirror the edge so
  /// the curve keeps its slope there.
  static List<double> _sample(List<List<List<double>>> g, double u, double v) {
    final x = u * 2;
    final y = v * 2;
    final ci = math.min(1, x.floor());
    final ri = math.min(1, y.floor());
    final tx = x - ci;
    final ty = y - ri;
    List<double> at(int r, int c) {
      final rr = r.clamp(0, 2);
      final cc = c.clamp(0, 2);
      if (r == rr && c == cc) return g[r][c];
      final edge = g[rr][cc];
      final inner = g[r == rr ? rr : 1][c == cc ? cc : 1];
      return [for (var i = 0; i < edge.length; i++) 2 * edge[i] - inner[i]];
    }

    final k = g[0][0].length;
    final out = List<double>.filled(k, 0);
    for (var i = 0; i < k; i++) {
      final rows = [
        for (var r = -1; r <= 2; r++)
          _catmullRom(
            at(ri + r, ci - 1)[i],
            at(ri + r, ci)[i],
            at(ri + r, ci + 1)[i],
            at(ri + r, ci + 2)[i],
            tx,
          ),
      ];
      out[i] = _catmullRom(rows[0], rows[1], rows[2], rows[3], ty);
    }
    return out;
  }

  static double _catmullRom(
    double p0,
    double p1,
    double p2,
    double p3,
    double t,
  ) =>
      0.5 *
      (2 * p1 +
          (p2 - p0) * t +
          (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t +
          (3 * p1 - p0 - 3 * p2 + p3) * t * t * t);

  static double _toLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static int _fromLinear(double x) {
    final v = x.clamp(0.0, 1.0);
    final s = v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
    return (s * 255).round().clamp(0, 255);
  }

  static double _cbrt(double x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  static List<double> _toLab(Color color) {
    final r = _toLinear(color.r);
    final g = _toLinear(color.g);
    final b = _toLinear(color.b);
    final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    ];
  }

  /// OKLab to an opaque ARGB int.
  static int _fromLab(List<double> lab) {
    final l = math.pow(
      lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2],
      3,
    );
    final m = math.pow(
      lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2],
      3,
    );
    final s = math.pow(
      lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2],
      3,
    );
    final r = _fromLinear(
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    );
    final g = _fromLinear(
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    );
    final b = _fromLinear(
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    );
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  /// The mesh's color at (u, v), for tests.
  @visibleForTesting
  static Color colorAt(List<Color> colors, double u, double v) {
    final labs = [for (final c in colors) _toLab(c)];
    final grid = [
      for (var r = 0; r < 3; r++) [for (var c = 0; c < 3; c++) labs[r * 3 + c]],
    ];
    return Color(_fromLab(_sample(grid, u, v)));
  }
}

class _Key {
  _Key(this.colors, this.points, this.size)
    : _hash = Object.hash(Object.hashAll(colors), Object.hashAll(points), size);

  final List<Color> colors;
  final List<Offset> points;
  final Size size;
  final int _hash;

  @override
  bool operator ==(Object other) {
    if (other is! _Key || other._hash != _hash || other.size != size) {
      return false;
    }
    for (var i = 0; i < 9; i++) {
      if (other.colors[i] != colors[i] || other.points[i] != points[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => _hash;
}

/// A mesh that isn't built in: nine light colors, nine night colors and where they sit. Gallery
/// wallpapers and themes bring these as data, so new meshes need no app release.
@immutable
class WallpaperMesh {
  const WallpaperMesh({
    required this.light,
    required this.dark,
    this.points = MeshGradient.evenPoints,
  });

  final List<Color> light;
  final List<Color> dark;
  final List<Offset> points;

  /// The lightest a light color and the darkest a night color may be, so text on transparent
  /// headers stays readable. The gallery's checker applies the same limits.
  static const minLightLuminance = 0.55;
  static const maxDarkLuminance = 0.05;

  List<Color> colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Reads `{"light": [9 × "#RRGGBB"], "dark": [...], "points": [[x, y] × 9]}`, or null when
  /// anything is missing, malformed or too low in contrast. Points are optional; corners are
  /// pinned and edge points kept on their edge, so the mesh always covers the window.
  static WallpaperMesh? fromJson(Object? raw) {
    if (raw is! Map) return null;
    List<Color>? colors(Object? v) {
      if (v is! List || v.length != 9) return null;
      final out = <Color>[];
      for (final hex in v) {
        if (hex is! String || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
          return null;
        }
        out.add(Color(0xFF000000 | int.parse(hex.substring(1), radix: 16)));
      }
      return out;
    }

    final light = colors(raw['light']);
    final dark = colors(raw['dark']);
    if (light == null || dark == null) return null;
    if (light.any((c) => c.computeLuminance() < minLightLuminance) ||
        dark.any((c) => c.computeLuminance() > maxDarkLuminance)) {
      return null;
    }
    var points = MeshGradient.evenPoints;
    final rawPoints = raw['points'];
    if (rawPoints != null) {
      if (rawPoints is! List || rawPoints.length != 9) return null;
      final read = <Offset>[];
      for (var i = 0; i < 9; i++) {
        final p = rawPoints[i];
        if (p is! List ||
            p.length != 2 ||
            p[0] is! num ||
            p[1] is! num ||
            !(p[0] as num).isFinite ||
            !(p[1] as num).isFinite) {
          return null;
        }
        var x = (p[0] as num).toDouble().clamp(0.0, 1.0);
        var y = (p[1] as num).toDouble().clamp(0.0, 1.0);
        final col = i % 3;
        final row = i ~/ 3;
        if (col != 1) x = col / 2;
        if (row != 1) y = row / 2;
        // Inner points stay off the edges, so the mesh can't fold over itself.
        if (col == 1) x = x.clamp(0.2, 0.8);
        if (row == 1) y = y.clamp(0.2, 0.8);
        read.add(Offset(x, y));
      }
      points = read;
    }
    return WallpaperMesh(light: light, dark: dark, points: points);
  }

  Map<String, Object?> toJson() {
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return {
      'light': [for (final c in light) hex(c)],
      'dark': [for (final c in dark) hex(c)],
      'points': [
        for (final p in points) [p.dx, p.dy],
      ],
    };
  }

  @override
  bool operator ==(Object other) =>
      other is WallpaperMesh &&
      listEquals(other.light, light) &&
      listEquals(other.dark, dark) &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(light),
    Object.hashAll(dark),
    Object.hashAll(points),
  );
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_parsing/path_parsing.dart';

/// One drawing in a wallpaper pattern: Lucide-style shapes on a 24 × 24 grid, drawn as 2-unit
/// strokes with round ends and no fill. Built-in patterns are generated from `client/looks`
/// (`looks.g.dart`); gallery wallpapers bring their own as data (gallery README, "Doodles").
@immutable
class Doodle {
  const Doodle(this.shapes);

  final List<DoodleShape> shapes;

  static const maxDoodles = 24;
  static const maxShapes = 24;
  static const maxPathLength = 1500;

  /// The stroke outline on the 24 × 24 grid, built once per doodle.
  ui.Path get path => _paths.putIfAbsent(this, () {
    final path = ui.Path();
    for (final s in shapes) {
      s.addTo(path);
    }
    return path;
  });

  static final _paths = <Doodle, ui.Path>{};

  /// A list of doodles, or null when it breaks the gallery rules.
  static List<Doodle>? listFromJson(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.length > maxDoodles) return null;
    final out = <Doodle>[];
    for (final d in raw) {
      final doodle = fromJson(d);
      if (doodle == null) return null;
      out.add(doodle);
    }
    return out;
  }

  /// Reads `[[tag, {attributes}], ...]`, or null when anything is off.
  static Doodle? fromJson(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.length > maxShapes) return null;
    final shapes = <DoodleShape>[];
    for (final node in raw) {
      final shape = DoodleShape.fromJson(node);
      if (shape == null) return null;
      shapes.add(shape);
    }
    return Doodle(shapes);
  }

  List<Object> toJson() => [for (final s in shapes) s.toJson()];

  @override
  bool operator ==(Object other) =>
      other is Doodle && listEquals(other.shapes, shapes);

  @override
  int get hashCode => Object.hashAll(shapes);
}

/// One element of a [Doodle].
@immutable
sealed class DoodleShape {
  const DoodleShape();

  void addTo(ui.Path path);

  /// `[tag, {attributes}]`, Lucide's node format.
  List<Object> toJson();

  static final _pathChars = RegExp(r'^[MmLlHhVvCcSsQqTtAaZz0-9.,eE+\-\s]+$');
  static final _pointsChars = RegExp(r'^[0-9.,eE+\-\s]+$');

  static DoodleShape? fromJson(Object? raw) {
    if (raw is! List ||
        raw.length != 2 ||
        raw[0] is! String ||
        raw[1] is! Map) {
      return null;
    }
    final a = (raw[1] as Map).cast<Object?, Object?>();
    double? number(String key, {required bool size, bool optional = false}) {
      final v = a[key];
      if (v == null) return optional ? 0 : null;
      final n = v is num
          ? v.toDouble()
          : (v is String ? double.tryParse(v) : null);
      if (n == null || !n.isFinite) return null;
      if (size ? (n < 0 || n > 26) : (n < -2 || n > 26)) return null;
      return n;
    }

    switch (raw[0]) {
      case 'path':
        final d = a['d'];
        if (d is! String ||
            d.isEmpty ||
            d.length > Doodle.maxPathLength ||
            !_pathChars.hasMatch(d)) {
          return null;
        }
        try {
          writeSvgPathDataToPath(d, _Bounds());
        } catch (_) {
          return null;
        }
        return DoodlePath(d);
      case 'circle':
        final cx = number('cx', size: false);
        final cy = number('cy', size: false);
        final r = number('r', size: true);
        if (cx == null || cy == null || r == null) return null;
        return DoodleCircle(cx, cy, r);
      case 'ellipse':
        final cx = number('cx', size: false);
        final cy = number('cy', size: false);
        final rx = number('rx', size: true);
        final ry = number('ry', size: true);
        if (cx == null || cy == null || rx == null || ry == null) return null;
        return DoodleEllipse(cx, cy, rx, ry);
      case 'rect':
        final x = number('x', size: false, optional: true);
        final y = number('y', size: false, optional: true);
        final w = number('width', size: true);
        final h = number('height', size: true);
        final rx = a['rx'] == null ? null : number('rx', size: true);
        final ry = a['ry'] == null ? null : number('ry', size: true);
        if (x == null || y == null || w == null || h == null) return null;
        if ((a['rx'] != null && rx == null) ||
            (a['ry'] != null && ry == null)) {
          return null;
        }
        return DoodleRect(x, y, w, h, rx: rx ?? ry ?? 0, ry: ry ?? rx ?? 0);
      case 'line':
        final x1 = number('x1', size: false);
        final y1 = number('y1', size: false);
        final x2 = number('x2', size: false);
        final y2 = number('y2', size: false);
        if (x1 == null || y1 == null || x2 == null || y2 == null) return null;
        return DoodleLine(x1, y1, x2, y2);
      case 'polyline' || 'polygon':
        final p = a['points'];
        if (p is! String ||
            p.length > Doodle.maxPathLength ||
            !_pointsChars.hasMatch(p)) {
          return null;
        }
        final values = [
          for (final part in p.trim().split(RegExp(r'[\s,]+')))
            if (part.isNotEmpty) double.tryParse(part),
        ];
        if (values.length < 4 ||
            values.length.isOdd ||
            values.any((v) => v == null || v < -2 || v > 26)) {
          return null;
        }
        return DoodlePoly([
          for (final v in values) v!,
        ], closed: raw[0] == 'polygon');
    }
    return null;
  }
}

String _n(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

class DoodlePath extends DoodleShape {
  const DoodlePath(this.d);
  final String d;

  @override
  void addTo(ui.Path path) => writeSvgPathDataToPath(d, _PathProxy(path));

  @override
  List<Object> toJson() => [
    'path',
    {'d': d},
  ];

  @override
  bool operator ==(Object other) => other is DoodlePath && other.d == d;

  @override
  int get hashCode => d.hashCode;
}

class DoodleCircle extends DoodleShape {
  const DoodleCircle(this.cx, this.cy, this.r);
  final double cx, cy, r;

  @override
  void addTo(ui.Path path) =>
      path.addOval(ui.Rect.fromCircle(center: ui.Offset(cx, cy), radius: r));

  @override
  List<Object> toJson() => [
    'circle',
    {'cx': _n(cx), 'cy': _n(cy), 'r': _n(r)},
  ];

  @override
  bool operator ==(Object other) =>
      other is DoodleCircle && other.cx == cx && other.cy == cy && other.r == r;

  @override
  int get hashCode => Object.hash('circle', cx, cy, r);
}

class DoodleEllipse extends DoodleShape {
  const DoodleEllipse(this.cx, this.cy, this.rx, this.ry);
  final double cx, cy, rx, ry;

  @override
  void addTo(ui.Path path) => path.addOval(
    ui.Rect.fromCenter(
      center: ui.Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    ),
  );

  @override
  List<Object> toJson() => [
    'ellipse',
    {'cx': _n(cx), 'cy': _n(cy), 'rx': _n(rx), 'ry': _n(ry)},
  ];

  @override
  bool operator ==(Object other) =>
      other is DoodleEllipse &&
      other.cx == cx &&
      other.cy == cy &&
      other.rx == rx &&
      other.ry == ry;

  @override
  int get hashCode => Object.hash('ellipse', cx, cy, rx, ry);
}

class DoodleRect extends DoodleShape {
  const DoodleRect(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.rx = 0,
    this.ry = 0,
  });
  final double x, y, width, height, rx, ry;

  @override
  void addTo(ui.Path path) {
    final rect = ui.Rect.fromLTWH(x, y, width, height);
    if (rx == 0 && ry == 0) {
      path.addRect(rect);
    } else {
      path.addRRect(
        ui.RRect.fromRectXY(
          rect,
          rx.clamp(0, width / 2),
          ry.clamp(0, height / 2),
        ),
      );
    }
  }

  @override
  List<Object> toJson() => [
    'rect',
    {
      'x': _n(x),
      'y': _n(y),
      'width': _n(width),
      'height': _n(height),
      if (rx != 0) 'rx': _n(rx),
      if (ry != 0) 'ry': _n(ry),
    },
  ];

  @override
  bool operator ==(Object other) =>
      other is DoodleRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.rx == rx &&
      other.ry == ry;

  @override
  int get hashCode => Object.hash('rect', x, y, width, height, rx, ry);
}

class DoodleLine extends DoodleShape {
  const DoodleLine(this.x1, this.y1, this.x2, this.y2);
  final double x1, y1, x2, y2;

  @override
  void addTo(ui.Path path) => path
    ..moveTo(x1, y1)
    ..lineTo(x2, y2);

  @override
  List<Object> toJson() => [
    'line',
    {'x1': _n(x1), 'y1': _n(y1), 'x2': _n(x2), 'y2': _n(y2)},
  ];

  @override
  bool operator ==(Object other) =>
      other is DoodleLine &&
      other.x1 == x1 &&
      other.y1 == y1 &&
      other.x2 == x2 &&
      other.y2 == y2;

  @override
  int get hashCode => Object.hash('line', x1, y1, x2, y2);
}

/// A polyline, or a polygon when [closed].
class DoodlePoly extends DoodleShape {
  const DoodlePoly(this.points, {required this.closed});

  /// x, y, x, y, …
  final List<double> points;
  final bool closed;

  @override
  void addTo(ui.Path path) {
    path.moveTo(points[0], points[1]);
    for (var i = 2; i + 1 < points.length; i += 2) {
      path.lineTo(points[i], points[i + 1]);
    }
    if (closed) path.close();
  }

  @override
  List<Object> toJson() => [
    closed ? 'polygon' : 'polyline',
    {'points': points.map(_n).join(' ')},
  ];

  @override
  bool operator ==(Object other) =>
      other is DoodlePoly &&
      other.closed == closed &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(closed, Object.hashAll(points));
}

class _PathProxy extends PathProxy {
  _PathProxy(this.path);
  final ui.Path path;

  @override
  void close() => path.close();

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

/// Parses a path without building it, to check it during validation.
class _Bounds extends PathProxy {
  @override
  void close() {}

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {}

  @override
  void lineTo(double x, double y) {}

  @override
  void moveTo(double x, double y) {}
}

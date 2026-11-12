import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Small motion toolkit on plain animation controllers: no timers, so nothing is left running when
/// a widget goes away, and every effect respects the system's reduce-motion setting.

/// Fades a child in with a small slide or scale, after an optional [delay].
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.offset = const Offset(0, 0.04),
    this.scale = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting offset as a fraction of the child's size.
  final Offset offset;

  /// Starting scale (1 = none).
  final double scale;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0 ? 0.0 : widget.delay.inMicroseconds / total.inMicroseconds;
    // The delay is the start of the interval, so it needs no timer.
    _t = CurvedAnimation(parent: _controller, curve: Interval(start, 1, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        Widget out = FractionalTranslation(translation: Offset.lerp(widget.offset, Offset.zero, v)!, child: child);
        if (widget.scale != 1) out = Transform.scale(scale: widget.scale + (1 - widget.scale) * v, child: out);
        return _Fade(opacity: v, child: out);
      },
    );
  }
}

/// [Opacity] that paints straight through once opaque. Flutter's [Opacity] keeps its own layer at
/// any opacity above zero, so every list row that ever faded in would carry one for good, and
/// every frame would composite it.
class _Fade extends SingleChildRenderObjectWidget {
  const _Fade({required this.opacity, super.child});
  final double opacity;

  @override
  _RenderFade createRenderObject(BuildContext context) => _RenderFade(opacity);

  @override
  void updateRenderObject(BuildContext context, _RenderFade renderObject) => renderObject.opacity = opacity;
}

class _RenderFade extends RenderProxyBox {
  _RenderFade(double opacity) : _alpha = Color.getAlphaFromOpacity(opacity);

  int _alpha;
  set opacity(double value) {
    final alpha = Color.getAlphaFromOpacity(value);
    if (alpha == _alpha) return;
    final composited = alwaysNeedsCompositing;
    _alpha = alpha;
    if (composited != alwaysNeedsCompositing) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _alpha > 0 && _alpha < 255;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _alpha == 0) {
      layer = null;
      return;
    }
    if (_alpha == 255) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushOpacity(offset, _alpha, super.paint, oldLayer: layer as OpacityLayer?);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && _alpha > 0) visitor(child!);
  }
}

/// Repeats a gentle scale (and optional fade) back and forth: status dots, recording.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.from = 0.85, this.to = 1.08, this.fadeFrom, this.duration = const Duration(milliseconds: 900)});
  final Widget child;
  final double from;
  final double to;
  final double? fadeFrom;
  final Duration duration;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) {
        final v = curve.value;
        final scaled = Transform.scale(scale: widget.from + (widget.to - widget.from) * v, child: child);
        final fade = widget.fadeFrom;
        return fade == null ? scaled : Opacity(opacity: fade + (1 - fade) * v, child: scaled);
      },
    );
  }
}

/// A highlight that sweeps across the child, for "working" text and placeholders.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, required this.color, this.duration = const Duration(milliseconds: 1600)});
  final Widget child;
  final Color color;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final x = -1.5 + 3 * _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 0.6, 0),
            end: Alignment(x + 0.6, 0),
            // Fade the highlight to its own color at zero alpha, not to transparent black, which
            // leaves grey bands either side of the shine.
            colors: [widget.color.withValues(alpha: 0), widget.color, widget.color.withValues(alpha: 0)],
            stops: const [0, 0.5, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

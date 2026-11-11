import 'package:flutter/material.dart';

/// Fades the edges of a scroll view where it has more to show, so a row of chips or cards reads as
/// scrollable even when no item is cut in half. Wrap the scroll view itself.
///
/// Each edge fades only while there is more to scroll that way (a row that fits shows no fade),
/// easing out over the last [extent] pixels. It follows the reading direction and `reverse`. The
/// mask is alpha-only, so it works over any background and in light and dark mode.
class EdgeFade extends StatefulWidget {
  const EdgeFade({super.key, required this.child, this.extent = 40});

  /// The scroll view to fade.
  final Widget child;

  /// How far each fade reaches into the scroll view, in logical pixels.
  final double extent;

  @override
  State<EdgeFade> createState() => EdgeFadeState();
}

class EdgeFadeState extends State<EdgeFade> {
  double _before = 0;
  double _after = 0;
  AxisDirection _direction = AxisDirection.right;

  /// How strongly the edge where scrolling starts fades, from 0 (sharp) to 1.
  @visibleForTesting
  double get before => _before;

  /// How strongly the edge where scrolling ends fades, from 0 (sharp) to 1.
  @visibleForTesting
  double get after => _after;

  /// The direction the scroll view's content runs in.
  @visibleForTesting
  AxisDirection get direction => _direction;

  bool _onMetrics(ScrollMetrics metrics, int depth) {
    // Only the scroll view this wraps; lists inside its items (a board column) report a higher depth.
    if (depth != 0) return false;
    final before = (metrics.extentBefore / widget.extent).clamp(0.0, 1.0);
    final after = (metrics.extentAfter / widget.extent).clamp(0.0, 1.0);
    if (before != _before || after != _after || metrics.axisDirection != _direction) {
      setState(() {
        _before = before;
        _after = after;
        _direction = metrics.axisDirection;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      // The first layout, and content that grows or shrinks without a scroll.
      onNotification: (n) => _onMetrics(n.metrics, n.depth),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics, n.depth),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final length = axisDirectionToAxis(_direction) == Axis.horizontal ? bounds.width : bounds.height;
            final stop = length <= 0 ? 0.0 : (widget.extent / length).clamp(0.0, 0.5);
            // From the edge where scrolling starts to the edge where it ends: right to left in
            // right-to-left layouts and in reversed lists.
            final (begin, end) = switch (_direction) {
              AxisDirection.right => (Alignment.centerLeft, Alignment.centerRight),
              AxisDirection.left => (Alignment.centerRight, Alignment.centerLeft),
              AxisDirection.down => (Alignment.topCenter, Alignment.bottomCenter),
              AxisDirection.up => (Alignment.bottomCenter, Alignment.topCenter),
            };
            return LinearGradient(
              begin: begin,
              end: end,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 1 - _before),
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFFFF).withValues(alpha: 1 - _after),
              ],
              stops: [0, stop, 1 - stop, 1],
            ).createShader(bounds);
          },
          child: widget.child,
        ),
      ),
    );
  }
}

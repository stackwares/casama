import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Scrolls [child] into view and gives it a gentle, single pulse when a deep link asks to
/// highlight a specific setting (`?highlight=<id>`). Never auto-activates controls, uses zero
/// timers, and omits motion when reduced motion is enabled.
class HighlightTarget extends StatefulWidget {
  const HighlightTarget({
    super.key,
    required this.active,
    required this.child,
    this.borderRadius,
  });

  final bool active;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<HighlightTarget> createState() => _HighlightTargetState();
}

class _HighlightTargetState extends State<HighlightTarget>
    with SingleTickerProviderStateMixin {
  final _targetKey = GlobalKey();
  late final AnimationController _controller;
  var _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _schedule();
  }

  @override
  void didUpdateWidget(covariant HighlightTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _triggered = false;
      _schedule();
    } else if (!widget.active) {
      _triggered = false;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _schedule() {
    if (_triggered) return;
    _triggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      final target = _targetKey.currentContext;
      if (target != null && Scrollable.maybeOf(target) != null) {
        Scrollable.ensureVisible(
          target,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.3,
        );
      }
      if (!reduce) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.tileAll;
    final primary = Theme.of(context).colorScheme.primary;
    final reduce = MediaQuery.disableAnimationsOf(context);

    Widget content = KeyedSubtree(key: _targetKey, child: widget.child);
    if (!widget.active) return content;

    if (reduce) {
      return DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: primary.withValues(alpha: 0.5), width: 2),
          color: primary.withValues(alpha: 0.06),
        ),
        child: content,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final strength = math.sin(math.pi * _controller.value).clamp(0.0, 1.0);
        if (strength <= 0.001) return child!;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: primary.withValues(alpha: 0.65 * strength),
              width: 2,
            ),
            color: primary.withValues(alpha: 0.12 * strength),
          ),
          child: child,
        );
      },
      child: content,
    );
  }
}

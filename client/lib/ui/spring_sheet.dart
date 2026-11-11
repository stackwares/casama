import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Shows a modal sheet anchored to the bottom edge of the screen.
///
/// A spring-driven replacement for showModalBottomSheet. The sheet enters
/// and exits on smooth springs, and dragging it drives the route animation
/// directly, so the velocity of a released fling is carried into the open
/// or close spring.
///
/// The sheet surface comes from [SheetContainer]; the widget returned by
/// [builder] brings only its content and padding. Build it on a Column with
/// mainAxisSize: MainAxisSize.min so the sheet is only as tall as its content.
///
/// [useRootNavigator] puts the sheet above everything, the phone's floating
/// tab bar included, like the showModalBottomSheet argument of the same name.
///
/// Returns a [Future] that resolves to the value passed to [Navigator.pop]
/// when the sheet is closed.
Future<T?> showSpringBottomSheet<T>({required BuildContext context, required WidgetBuilder builder, bool useRootNavigator = false}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    SpringSheetRoute<T>(
      builder: builder,
      // A sheet on the root navigator still gets the themes of the screen that opened it.
      capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

/// A route that shows a spring-driven modal sheet at the bottom of the
/// screen.
class SpringSheetRoute<T> extends PopupRoute<T> {
  SpringSheetRoute({required this.builder, this.capturedThemes, this.barrierLabel, super.settings});

  /// Builds the content of the sheet.
  final WidgetBuilder builder;

  /// The themes of the screen that opened the sheet.
  final CapturedThemes? capturedThemes;

  /// What screen readers call the dimmed area behind the sheet.
  @override
  final String? barrierLabel;

  // SwiftUI's .smooth spring written out as plain numbers: critically
  // damped, stiffness 4pi^2 / duration^2, at 300ms in and 200ms out.
  static const SpringDescription _enterSpring = SpringDescription(mass: 1, stiffness: 438.6, damping: 41.9);
  static const SpringDescription _exitSpring = SpringDescription(mass: 1, stiffness: 987.0, damping: 62.8);

  // Resistance applied when dragging past fully open.
  static const double _overdragResistance = 100;

  // Thresholds past which a released drag closes the sheet: fling speed in
  // sheet heights per second, or resting position as a fraction of height.
  static const double _closeVelocity = 0.9;
  static const double _closePosition = 0.5;

  // The widest the sheet grows, like Material's bottom sheet.
  static const double _maxWidth = 640;

  // Release velocity in sheet heights per second (positive is downward),
  // carried from the drag into the close simulation.
  double? _releaseVelocity;

  bool _popped = false;

  @override
  Color? get barrierColor => const Color(0x8A000000);

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  // When the system asks to reduce motion, the sheet appears and leaves
  // without moving.
  bool get _reduceMotion {
    final BuildContext? context = navigator?.context;
    return context != null && (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  // The scrim fades with the clamped animation so that dragging past fully
  // open does not push the barrier curve out of range. The slide reads the
  // raw controller.
  @override
  Animation<double>? get animation {
    final Animation<double>? raw = super.animation;
    if (raw == null) return null;

    return _ClampedAnimation(raw);
  }

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(duration: transitionDuration, reverseDuration: reverseTransitionDuration, vsync: navigator!);
  }

  @override
  Simulation? createSimulation({required bool forward}) {
    final double velocity = _releaseVelocity ?? 0;
    _releaseVelocity = null;
    final double target = forward ? 1 : 0;
    if (_reduceMotion) return _InstantSimulation(target);

    return SpringSimulation(forward ? _enterSpring : _exitSpring, controller?.value ?? 0, target, -velocity, snapToEnd: true);
  }

  @override
  bool didPop(T? result) {
    _popped = true;

    return super.didPop(result);
  }

  void _dragBy(double relativeDelta) {
    if (_popped) return;

    final AnimationController controller = this.controller!;

    double delta = relativeDelta;
    if (controller.value > 1) {
      final double overshoot = controller.value - 1;
      delta *= 1 / (1 + overshoot * _overdragResistance);
    }
    controller.value -= delta;
  }

  void _endDrag(double relativeVelocity) {
    if (_popped) return;
    final AnimationController controller = this.controller!;
    final double value = controller.value;

    if (value > 1) {
      // Dragged past fully open. Settle back, damping the velocity by the
      // same resistance that was applied while dragging.
      final double overshoot = value - 1;
      final double damped = relativeVelocity / (1 + overshoot * _overdragResistance);
      _settle(value, damped);

      return;
    }

    final bool close = switch (relativeVelocity) {
      > _closeVelocity => true,
      < -_closeVelocity => false,
      _ => value < _closePosition,
    };

    if (close) {
      _releaseVelocity = relativeVelocity;
      navigator?.pop();
    } else {
      _settle(value, relativeVelocity);
    }
  }

  // Springs back to fully open from [from], carrying [velocity].
  void _settle(double from, double velocity) {
    controller!.animateWith(_reduceMotion ? _InstantSimulation(1) : SpringSimulation(_enterSpring, from, 1, -velocity, snapToEnd: true));
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget sheet = Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: AnimatedBuilder(
          animation: controller!,
          builder: (context, child) {
            return FractionalTranslation(translation: Offset(0, 1 - controller!.value), child: child);
          },
          child: Builder(
            builder: (context) {
              // Drag deltas are normalized by the sheet's own height, so the
              // gesture and the route animation share one coordinate space.
              double height() => context.size?.height ?? 1;

              return GestureDetector(
                excludeFromSemantics: true,
                onVerticalDragUpdate: (details) {
                  _dragBy(details.primaryDelta! / height());
                },
                onVerticalDragEnd: (details) {
                  _endDrag(details.velocity.pixelsPerSecond.dy / height());
                },
                onVerticalDragCancel: () {
                  _endDrag(0);
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: MaterialLocalizations.of(context).bottomSheetLabel,
                    child: SheetContainer(child: builder(context)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    // Never under the status bar or the notch, however tall the content gets.
    final Widget safe = SafeArea(left: false, right: false, bottom: false, child: sheet);

    return capturedThemes?.wrap(safe) ?? safe;
  }
}

/// The surface for sheets shown with [showSpringBottomSheet]: the app's sheet
/// colour, 28px rounded top corners and a drag handle, so the content brings
/// only itself and its padding.
class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BottomSheetThemeData sheetTheme = theme.bottomSheetTheme;

    // The coloured surface is the Material itself, so list tiles and buttons in the sheet show
    // their ink on it (a ColoredBox over a transparent Material would hide it).
    return Material(
      color: sheetTheme.modalBackgroundColor ?? sheetTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DragHandle(color: sheetTheme.dragHandleColor ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// The 32x4 grabber at the top of the sheet, in a 48px strip. Screen readers
/// get a "Dismiss" button here, as on Material's sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      button: true,
      onTap: () => Navigator.of(context).maybePop(),
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.circular(2))),
          ),
        ),
      ),
    );
  }
}

/// An animation that forwards [parent] with its value clamped to the range
/// 0.0 to 1.0, for consumers such as the modal barrier that should not see
/// values past fully open.
class _ClampedAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _ClampedAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}

/// Sits at [target] from the first frame, for reduced motion.
class _InstantSimulation extends Simulation {
  _InstantSimulation(this.target);

  final double target;

  @override
  double x(double time) => target;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => true;
}

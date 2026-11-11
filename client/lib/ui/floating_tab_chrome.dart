import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Floating bottom tab bar for phones: a slim stadium-shaped pill on a neutral surface with a
/// hairline border. The selected tab sits on an accent-tinted indicator that glides between slots.
/// An optional round action (search) floats beside the pill, the same height.
class FloatingTabChrome extends StatelessWidget {
  const FloatingTabChrome({super.key, required this.destinations, required this.currentIndex, required this.onDestinationSelected, this.action});

  final List<FloatingTabDestination> destinations;

  /// The selected tab, or -1 when none is (a screen opened from a tab).
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// The round button beside the pill.
  final FloatingTabAction? action;

  static const double barHeight = 64;
  static const double tabSlotWidth = 88;
  static const double _actionGap = 10;
  static const Duration motionDuration = Duration(milliseconds: 250);
  static const Curve motionCurve = Curves.easeOutCubic;

  /// Bottom space a tab screen reserves so the bar never covers its last item.
  static double bottomInset(BuildContext context) => barHeight + 16 + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // Slots shrink on narrow phones so every tab fits (up to tabSlotWidth each).
        child: LayoutBuilder(
          builder: (context, c) {
            final room = c.maxWidth - 14 - (action == null ? 0 : barHeight + _actionGap);
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PillBar(
                    destinations: destinations,
                    currentIndex: currentIndex,
                    onSelected: onDestinationSelected,
                    slotWidth: destinations.isEmpty ? tabSlotWidth : (room / destinations.length).clamp(40.0, tabSlotWidth),
                  ),
                  if (action != null) ...[const SizedBox(width: _actionGap), _ActionButton(action: action!)],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The round button beside the tab pill.
class FloatingTabAction {
  const FloatingTabAction({required this.icon, required this.label, required this.onPressed, this.key});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final FloatingTabAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = context.isDark;
    final background = dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    return Tooltip(
      message: action.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: action.label,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            shadows: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.45 : 0.10), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Material(
            color: background.withValues(alpha: 0.96),
            shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.9))),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: action.key,
              onTap: () {
                HapticFeedback.selectionClick();
                action.onPressed();
              },
              child: SizedBox.square(dimension: FloatingTabChrome.barHeight, child: Icon(action.icon, size: 22, color: scheme.onSurfaceVariant)),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingTabDestination {
  const FloatingTabDestination({required this.icon, required this.selectedIcon, required this.label, this.badge = 0});
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Count shown on the icon (unread inbox items).
  final int badge;
}

class _PillBar extends StatelessWidget {
  const _PillBar({required this.destinations, required this.currentIndex, required this.onSelected, required this.slotWidth});

  final double slotWidth;

  final List<FloatingTabDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = context.isDark;
    final background = dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.45 : 0.10), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: background.withValues(alpha: 0.96),
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.9))),
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: FloatingTabChrome.barHeight,
          padding: const EdgeInsets.all(6),
          child: Stack(children: [
            if (currentIndex >= 0)
              AnimatedPositionedDirectional(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                start: currentIndex * slotWidth,
                top: 0,
                bottom: 0,
                width: slotWidth,
                child: DecoratedBox(decoration: ShapeDecoration(shape: const StadiumBorder(), color: scheme.primary.withValues(alpha: 0.16))),
              ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < destinations.length; i++)
                SizedBox(
                  width: slotWidth,
                  child: _TabButton(
                    spec: destinations[i],
                    selected: i == currentIndex,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.spec, required this.selected, required this.onTap});

  final FloatingTabDestination spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : FloatingTabChrome.motionDuration;
    return Tooltip(
      message: spec.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: spec.badge > 0 ? '${spec.label}, ${spec.badge}' : spec.label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: duration,
              curve: FloatingTabChrome.motionCurve,
              builder: (context, tint, _) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedScale(
                  scale: selected ? 1 : 0.92,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: Badge(
                    isLabelVisible: spec.badge > 0,
                    label: Text(spec.badge > 99 ? '99+' : '${spec.badge}', style: const TextStyle(fontFeatures: AppText.tabular)),
                    backgroundColor: scheme.primary,
                    textColor: scheme.onPrimary,
                    child: Icon(selected ? spec.selectedIcon : spec.icon, size: 22, color: tint),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: tint,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

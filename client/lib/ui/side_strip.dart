import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'floating_tab_chrome.dart';

/// The side strip (D-411). An iPhone Duo keeps a column down one edge for the camera, the clock
/// and the battery; Apple's apps stack their Back button, toolbar buttons and tabs under them
/// ("vertical bars"), which UIKit only does for its own navigation classes. So the shell draws
/// the tabs at the bottom of that column ([StripTabs]), and each page's header puts its buttons
/// in the zone above them ([StripButtons]). The title stays with the page.

/// The zone of the strip a page's header buttons go in, in window coordinates. Null where there
/// is no strip, and in a pane whose headers keep their buttons (the list of a two-pane layout).
class StripSlot extends InheritedWidget {
  const StripSlot({super.key, required this.rect, required super.child});
  final Rect? rect;

  static Rect? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StripSlot>()?.rect;

  @override
  bool updateShouldNotify(StripSlot old) => old.rect != rect;
}

/// Draws [buttons] in the strip at [rect] while [child] (the header's title row) stays in the
/// page. The buttons remain this page's own widgets (their keys, their state, their navigator),
/// only painted over there. They cross-fade with the page as it comes and goes, and sit under any
/// sheet or dialog that covers the app.
class StripButtons extends StatefulWidget {
  const StripButtons({
    super.key,
    required this.rect,
    required this.buttons,
    required this.child,
  });
  final Rect rect;
  final List<Widget> buttons;
  final Widget child;

  @override
  State<StripButtons> createState() => _StripButtonsState();
}

class _StripButtonsState extends State<StripButtons> {
  final _portal = OverlayPortalController();

  /// Keeps the title row's state while the portal around it comes and goes.
  final _page = GlobalKey();

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  Widget build(BuildContext context) {
    final page = KeyedSubtree(key: _page, child: widget.child);
    // Only while this page is on stage. A page kept alive under another one is not laid out, and
    // buttons it left in the window's overlay would never be laid out either (Flutter asserts on
    // that), so such a page has no portal at all.
    if (!TickerMode.valuesOf(context).enabled) return page;
    final route = ModalRoute.of(context);
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context) {
        Widget column = _StripColumn(children: widget.buttons);
        final coming = route?.animation;
        final covered = route?.secondaryAnimation;
        if (route != null && coming != null && covered != null) {
          column = AnimatedBuilder(
            animation: Listenable.merge([coming, covered]),
            builder: (context, child) {
              // In with its own page, out as the next page comes over it.
              final shown = (coming.value * (1 - covered.value)).clamp(
                0.0,
                1.0,
              );
              return IgnorePointer(
                ignoring: shown < 0.5,
                child: Opacity(
                  opacity: Curves.easeOut.transform(shown),
                  child: child,
                ),
              );
            },
            child: column,
          );
        }
        return Positioned.fromRect(rect: widget.rect, child: column);
      },
      child: page,
    );
  }
}

/// A page's buttons, top to bottom. When the room runs short (the keyboard is up, or the phone
/// stands on its side) the gaps close first, and only then does the column scroll.
class _StripColumn extends StatelessWidget {
  const _StripColumn({required this.children});
  final List<Widget> children;

  static const double _slot = 40;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final n = children.length;
        final gap = n < 2
            ? 0.0
            : ((box.maxHeight - n * _slot) / (n - 1)).clamp(2.0, 10.0);
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < n; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                  child: SizedBox(
                    height: _slot,
                    width: double.infinity,
                    child: Center(child: children[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The three places and the round button under them, stacked for the bottom of the strip. Icons
/// only, as iOS shows tabs there; each carries its name for VoiceOver and as a tooltip.
class StripTabs extends StatelessWidget {
  const StripTabs({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    this.action,
  });

  final List<FloatingTabDestination> destinations;

  /// The selected tab, or -1 when none is.
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final FloatingTabAction? action;

  static const double slot = 46;
  static const double _pad = 4;
  static const double _gap = 8;

  /// The room the tabs (and the button under them) take at the bottom of the strip.
  static double heightFor(int tabs, {required bool action}) =>
      tabs * slot + 2 * _pad + 2 + (action ? _gap + slot : 0);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = context.isDark;
    final background = dark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
    final border = BorderSide(
      color: scheme.outlineVariant.withValues(alpha: dark ? 1 : 0.9),
    );
    final moving = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : FloatingTabChrome.motionDuration;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          key: const Key('stripTabs'),
          color: background.withValues(alpha: 0.96),
          shape: StadiumBorder(side: border),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: SizedBox(
              width: slot,
              height: destinations.length * slot,
              child: Stack(
                children: [
                  if (currentIndex >= 0)
                    AnimatedPositioned(
                      duration: moving,
                      curve: FloatingTabChrome.motionCurve,
                      top: currentIndex * slot,
                      left: 0,
                      right: 0,
                      height: slot,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          color: scheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                  Column(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        _StripTab(
                          key: Key('stripTab-$i'),
                          spec: destinations[i],
                          selected: i == currentIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelected(i);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (action case final action?) ...[
          const SizedBox(height: _gap),
          Tooltip(
            message: action.label,
            excludeFromSemantics: true,
            child: Semantics(
              button: true,
              label: action.label,
              excludeSemantics: true,
              child: Material(
                color: background.withValues(alpha: 0.96),
                shape: CircleBorder(side: border),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: action.key,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    action.onPressed();
                  },
                  child: SizedBox.square(
                    dimension: slot,
                    child: Icon(
                      action.icon,
                      size: 21,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StripTab extends StatelessWidget {
  const _StripTab({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });
  final FloatingTabDestination spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Tooltip(
      message: spec.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: spec.badge > 0 ? '${spec.label}, ${spec.badge}' : spec.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: StripTabs.slot,
            child: Center(
              child: Badge(
                isLabelVisible: spec.badge > 0,
                label: Text(
                  spec.badge > 99 ? '99+' : '${spec.badge}',
                  style: const TextStyle(fontFeatures: AppText.tabular),
                ),
                backgroundColor: scheme.primary,
                textColor: scheme.onPrimary,
                child: Icon(
                  selected ? spec.selectedIcon : spec.icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

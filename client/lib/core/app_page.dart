import 'package:material_ui/material_ui.dart';

import '../ui/shell_layout.dart';

/// Pages that change without anyone opening them (D-411). Folding an iPhone Duo can move the app
/// to another page (the chat it opened beside the list goes back to the list when the device
/// closes untouched); that page appears, it doesn't slide in.
abstract final class PageMotion {
  static bool _snap = false;

  /// The pages pushed and popped by the navigation that follows, within the next frame, skip
  /// their transitions.
  static void snapOnce() {
    _snap = true;
    // The router rebuilds on the next frame; the flag outlives that frame and no longer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _snap = false);
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}

/// A [MaterialPage] whose route knows about the shell's panes: beside its list, the first page
/// opened from it swaps in place (as on a tablet's split view) instead of sliding over it.
class AppPage<T> extends MaterialPage<T> {
  const AppPage({required super.child, super.key, super.name, super.arguments});

  @override
  Route<T> createRoute(BuildContext context) => _AppPageRoute<T>(page: this);
}

class _AppPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _AppPageRoute({required MaterialPage<T> page}) : super(settings: page);

  MaterialPage<T> get _page => settings as MaterialPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  Route<dynamic>? _below;

  /// The shell shows this navigator beside a list right now.
  bool get _besideList =>
      navigator?.context
          .getInheritedWidgetOfExactType<ShellLayout>()
          ?.splitDetail ??
      false;

  bool get _firstInPane {
    final pages = navigator?.widget.pages ?? const <Page<dynamic>>[];
    final at = pages.indexWhere(
      (p) => identical(p, settings) || p.canUpdate(_page),
    );
    return at == 0 || (at == 1 && pages.first is ListRootPage);
  }

  @override
  Duration get transitionDuration =>
      PageMotion._snap || (_besideList && _firstInPane)
      ? Duration.zero
      : super.transitionDuration;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _below = previousRoute;
  }

  @override
  bool didPop(T? result) {
    // Durations are read once, when the route is installed; leaving has to be decided now.
    final below = _below;
    final first =
        below == null || (below.isFirst && below.settings is ListRootPage);
    if (PageMotion._snap || (_besideList && first)) {
      controller?.reverseDuration = Duration.zero;
    }
    return super.didPop(result);
  }
}

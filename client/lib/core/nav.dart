import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Every page the user opened with [GoRouter.push], bottom to top, as its location.
List<Uri> _pushedLocations(List<RouteMatchBase> matches, [List<Uri>? out]) {
  final found = out ?? <Uri>[];
  for (final m in matches) {
    if (m is ImperativeRouteMatch) found.add(m.matches.uri);
    if (m is ShellRouteMatch) _pushedLocations(m.matches, found);
  }
  return found;
}

extension GoRouterPushOnce on GoRouter {
  /// [push] that never opens a page twice. If [location] is already on top, nothing happens; if
  /// it is further down, the pages above it close and the user is back on it. Without this a
  /// link to the page you're on (a notice in Updates that links to Updates) stacked a copy per
  /// tap, and a loop (a chat, its bot's profile, a watcher's chat, the profile again…) nested
  /// forever. The app's redirects are synchronous, so the top page is the new one as soon as
  /// [push] returns, which also covers a quick second tap. Returns null when nothing is pushed.
  Future<T?> pushOnce<T extends Object?>(String location, {Object? extra}) {
    final config = routerDelegate.currentConfiguration;
    if (config.isEmpty) return push<T>(location, extra: extra);
    final target = Uri.parse(location);
    if (state.uri == target) return Future<T?>.value();
    final pushed = _pushedLocations(config.matches);
    final at = config.uri == target ? -1 : pushed.lastIndexOf(target);
    if (at == -1 && config.uri != target) return push<T>(location, extra: extra);
    // Close the pages above it. A sheet or dialog on top closes first without changing the
    // stack, hence the slack in the bound.
    for (var left = pushed.length - at - 1 + 4; left > 0 && state.uri != target && canPop(); left--) {
      pop<Object?>();
    }
    return Future<T?>.value();
  }
}

extension GoRouterSwapTo on GoRouter {
  /// Opens [location] in place of the top page (D-327: a call screen and the live view swap
  /// places); when it's already further down, the pages above it close instead.
  void swapTo(String location) {
    final config = routerDelegate.currentConfiguration;
    final target = Uri.parse(location);
    if (config.isEmpty || !canPop()) {
      unawaited(push<Object?>(location));
      return;
    }
    if (state.uri == target) return;
    if (_pushedLocations(config.matches).contains(target)) {
      unawaited(pushOnce<Object?>(location));
      return;
    }
    unawaited(pushReplacement<Object?>(location));
  }
}

extension BuildContextPushOnce on BuildContext {
  /// [GoRouterPushOnce.pushOnce] on this context's router.
  Future<T?> pushOnce<T extends Object?>(String location, {Object? extra}) =>
      GoRouter.of(this).pushOnce<T>(location, extra: extra);
}

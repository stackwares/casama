import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_browser_channel.dart';

/// The native web area (PROTOCOL.md §3): a platform view of type `casama/app_browser_view` with no
/// creation params. Native keeps one web area for the app's life; this only shows it.
class AppBrowserWebArea extends StatelessWidget {
  const AppBrowserWebArea({super.key});

  // The page takes every touch inside it (scrolls, pinches, taps), not the screen around it.
  static final _gestures = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => UiKitView(
      viewType: MethodAppBrowserChannel.viewType,
      gestureRecognizers: _gestures,
    ),
    TargetPlatform.android => AndroidView(
      viewType: MethodAppBrowserChannel.viewType,
      gestureRecognizers: _gestures,
    ),
    _ => const SizedBox.shrink(),
  };
}

/// Builds the web area; tests put a plain box in (platform views don't draw in widget tests).
final appBrowserWebAreaProvider = Provider<WidgetBuilder>(
  (ref) =>
      (_) => const AppBrowserWebArea(),
);

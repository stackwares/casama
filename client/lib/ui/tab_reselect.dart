import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Scroll controllers for the three tab pages (Chats, Inbox, Tasks), so tapping the tab you're already
/// on scrolls its list back to the top, as on iOS and Android. Each tab page wraps its Scaffold in a
/// PrimaryScrollController with its controller here: on phones whichever list the page shows picks it
/// up by itself, and the iOS status-bar tap keeps working. They live as long as the app, like the tab
/// bar, so they are never disposed.
abstract final class TabReselect {
  static final ScrollController chats = ScrollController();
  static final ScrollController inbox = ScrollController();
  static final ScrollController tasks = ScrollController();
  static final ScrollController library = ScrollController();

  /// The controller of the tab at [index] in HomeShell's places: 0 Chats, 1 Library, 2 Tasks.
  static ScrollController of(int index) => switch (index) {
    0 => chats,
    1 => library,
    _ => tasks,
  };

  /// Scrolls the tab at [index] back to the top. Does nothing when its list isn't on screen.
  static void scrollToTop(BuildContext context, int index) {
    final scroller = of(index);
    if (!scroller.hasClients) return;
    final duration = AppMotion.of(context, const Duration(milliseconds: 300));
    // Reduced motion: jump instead (a scroll animation can't be zero-length).
    if (duration == Duration.zero) {
      scroller.jumpTo(0);
    } else {
      scroller.animateTo(0, duration: duration, curve: Curves.easeOutCubic);
    }
  }
}

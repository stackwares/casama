import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// The app shell's four layouts (D-176, D-411). Phone: one page and a tab bar. Tablet: a rail and
/// one page. Split: the tab's list beside the page opened from it (the iPhone Duo's inner screen,
/// Android foldables, upright tablets, mid-width windows). Desktop: a sidebar with the chats, the
/// chat, and the bot's computer beside it.
enum LayoutSize { phone, tablet, split, desktop }

LayoutSize layoutFor(double width) => width >= AppBreakpoints.expanded
    ? LayoutSize.desktop
    : width >= AppBreakpoints.split
    ? LayoutSize.split
    : width >= AppBreakpoints.medium
    ? LayoutSize.tablet
    : LayoutSize.phone;

/// Where the three places (Chats, Library, Tasks) are on screen.
enum NavKind {
  /// The floating tab bar over the page.
  tabBar,

  /// The side strip of an iPhone Duo (ui/side_strip.dart).
  strip,

  /// The navigation rail.
  rail,

  /// The desktop sidebar.
  sidebar,
}

/// What a screen is in the shell right now.
enum PaneRole {
  /// The only page on screen.
  single,

  /// The tab's list, with the page opened from it beside it.
  list,

  /// The page beside the list.
  detail,
}

/// What the shell looks like around a screen. Screens ask this instead of the window's width,
/// because inside a pane the width they see is the pane's.
class ShellLayout extends InheritedWidget {
  const ShellLayout({
    super.key,
    required this.size,
    required this.nav,
    required this.pane,
    required this.location,
    this.listHidden = false,
    this.canToggleList = false,
    required super.child,
  });

  final LayoutSize size;
  final NavKind nav;
  final PaneRole pane;

  /// The router's current path.
  final String location;

  /// Two panes are available here, and the person has hidden the list for now.
  final bool listHidden;

  /// The page beside the list offers the button that hides and shows the list. Not while a fold
  /// divides the window: each half keeps its pane then.
  final bool canToggleList;

  /// The shell shows the tab's list itself, so the tab's own page has nothing to draw.
  bool get listInShell => pane == PaneRole.detail;

  /// The page beside (or in place of) the list in a two-pane layout: its first page has no Back,
  /// and offers the list's show and hide button instead.
  bool get splitDetail =>
      size == LayoutSize.split && (pane == PaneRole.detail || listHidden);

  /// The places (and Settings behind the avatar) are reached from the page itself: its header
  /// carries the avatar and search, as on a phone.
  bool get navInPage => nav == NavKind.tabBar || nav == NavKind.strip;

  static ShellLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellLayout>();

  @override
  bool updateShouldNotify(ShellLayout old) =>
      old.size != size ||
      old.nav != nav ||
      old.pane != pane ||
      old.location != location ||
      old.listHidden != listHidden ||
      old.canToggleList != canToggleList;
}

/// A page that is a list other pages open from (a tab, Settings): in a two-pane layout the shell
/// shows it on the left, and the first page opened from it has nothing of its own to go back to.
abstract interface class ListRootPage {}

/// Whether the page around [context] is the first one opened from a list (or stands alone): in a
/// two-pane layout it sits beside its list, so it has no Back.
bool isDetailRoot(BuildContext context) {
  final route = ModalRoute.of(context);
  final navigator = Navigator.maybeOf(context);
  final page = route?.settings;
  if (navigator == null || page is! Page) return false;
  final pages = navigator.widget.pages;
  final at = pages.indexWhere((p) => identical(p, page) || p.canUpdate(page));
  return at == 0 || (at == 1 && pages.first is ListRootPage);
}

/// An on/off choice kept while the app runs.
class Flag extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
  void toggle() => state = !state;
}

/// Two panes: the list is hidden so the open page has the whole window.
final splitExpandedProvider = NotifierProvider<Flag, bool>(Flag.new);

/// Two panes: the bot's computer sits in the left pane instead of the list.
final splitComputerProvider = NotifierProvider<Flag, bool>(Flag.new);

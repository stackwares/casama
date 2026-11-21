import '../selfhost/setup_screen.dart';
import '../notifications/newsletter.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice/call_bubble.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_page.dart';
import '../../core/fold/fold.dart';
import '../../core/media_cache.dart';
import '../../ui/shell_layout.dart';
import '../../ui/side_strip.dart';
import '../library/library_screen.dart';
import '../../core/backend.dart';
import '../search/search_view.dart';
import '../referrals/invite_friends.dart' show referralProvider;
import '../notifications/email_tips.dart' show emailTipsProvider;
import '../link/link_screen.dart' show remoteAccessAvailableProvider;
import '../groups/group_chats.dart';
import '../../core/providers.dart';
import '../../ui/motion.dart';
import '../../ui/bot_activity.dart';
import '../settings/me_avatar.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/route_focus.dart';
import '../../ui/floating_tab_chrome.dart';
import '../../ui/tab_reselect.dart';
import '../../ui/glass.dart';
import '../../ui/casama_mark.dart';
import '../../core/billing.dart';
import '../../core/mac_bridge.dart';
import '../../core/updater.dart';
import '../../theme/presets.dart';
import '../../ui/advanced_section.dart';
import '../admin/admin_screen.dart';
import '../bots/bots_screen.dart';
import '../chat/chat_detail.dart';
import 'last_chat.dart';
import '../computer/computer_screen.dart';
import '../notifications/checkins_sheet.dart';
import '../notifications/quiet_hours.dart';
import '../settings/about_you_screen.dart';
import '../inbox/for_you.dart';
import '../settings/profile_photo.dart';
import '../../ui/glow_button.dart';
import '../workspaces/spaces.dart';
import '../inbox/in_app_alert.dart';
import '../voice/phone_calls.dart';
import '../voice/wake_word.dart';
import '../../ui/mascot.dart';
import '../../core/review_prompt.dart';

export '../../ui/shell_layout.dart' show LayoutSize, layoutFor;

/// Whether the computer panel is open beside the chat on wide windows.
class ComputerPanelOpen extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final computerPanelProvider = NotifierProvider<ComputerPanelOpen, bool>(
  ComputerPanelOpen.new,
);

/// From this content width a settings page opens beside the settings list.
const double _settingsSplitWidth = 1000;
const double _settingsListWidth = 360;

/// The computer panel's width on wide screens: dragged by its edge, kept on this device.
class ComputerPanelWidth extends Notifier<double> {
  static const defaultWidth = 420.0;
  static const min = 360.0;
  static const _key = 'layout.computerPanelWidth';

  @override
  double build() {
    SharedPreferences.getInstance()
        .then((p) {
          final v = p.getDouble(_key);
          if (v != null) state = v;
        })
        .catchError((_) {});
    return defaultWidth;
  }

  void set(double width) => state = width;

  Future<void> save() async {
    try {
      await (await SharedPreferences.getInstance()).setDouble(_key, state);
    } catch (_) {}
  }
}

final computerPanelWidthProvider = NotifierProvider<ComputerPanelWidth, double>(
  ComputerPanelWidth.new,
);

/// True while the panel's edge is being dragged, so the open/close animation doesn't lag the drag.
class _PanelDragging extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final _panelDraggingProvider = NotifierProvider<_PanelDragging, bool>(
  _PanelDragging.new,
);

class _Dest {
  const _Dest(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A chat the shell opened by itself beside the list (D-411), and whether the person has touched
/// it. Closing the device untouched goes back to the list they were on.
class SplitRest extends Notifier<({String? opened, bool touched})> {
  @override
  ({String? opened, bool touched}) build() => (opened: null, touched: false);

  void opened(String location) => state = (opened: location, touched: false);

  void touch() {
    if (state.opened != null && !state.touched) state = (opened: state.opened, touched: true);
  }

  void clear() {
    if (state.opened != null) state = (opened: null, touched: false);
  }
}

final splitRestProvider = NotifierProvider<SplitRest, ({String? opened, bool touched})>(SplitRest.new);

/// The chats list keeps its place when it moves between being the tab's page (phone) and the left
/// pane (two panes): one element, wherever it is shown.
final chatsListKey = GlobalKey(debugLabel: 'chats list');

/// Without a fold or a strip to line up with, the list pane is this wide.
const double _listPaneWidth = 360;

/// Whether the strip has room for the round button under the tabs and still three of a page's
/// own buttons above them. Standing on its side (tent) it doesn't, and the button goes.
bool stripFitsAction(MediaQueryData media, FoldInfo fold, int tabs) {
  final free = fold.stripBottom - fold.stripTop;
  return free - StripTabs.heightFor(tabs, action: true) - 12 >= 3 * 44;
}

/// The zone of the strip a page's header buttons go in: under what iOS draws at its top, above
/// the tabs (when they show), and above the keyboard.
Rect stripSlot(MediaQueryData media, FoldInfo fold, double tabsHeight) {
  // Off the screen's outer edge by the margin iOS keeps there, so the buttons line up with the
  // clock above them.
  final onRight = fold.strip == StripSide.right;
  final left = onRight ? media.size.width - fold.stripWidth : FoldInfo.stripOuterMargin;
  final width = fold.stripWidth - FoldInfo.stripOuterMargin;
  final floor = math.max(
    media.viewInsets.bottom,
    media.size.height - fold.stripBottom + (tabsHeight > 0 ? tabsHeight + 12 : 0),
  );
  final bottom = math.max(media.size.height - floor, fold.stripTop);
  return Rect.fromLTRB(left, fold.stripTop, left + width, bottom);
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child, this.uri});
  final String location;

  /// The whole address, for the lists the shell shows itself (the Library's filters).
  final Uri? uri;
  final Widget child;

  /// The selected place, or -1 on screens outside them (settings, search, the computer).
  int get _index {
    if (location.startsWith('/tasks') || location.startsWith('/projects')) {
      return 2;
    }
    // The Library (D-274): everything bots made, between Chats and Tasks.
    if (location.startsWith('/library')) return 1;
    if (location == '/' ||
        location.startsWith('/inbox') ||
        location.startsWith('/approvals') ||
        location.startsWith('/bots') ||
        location.startsWith('/groups') ||
        location.startsWith('/quick-ask')) {
      return 0;
    }
    return -1;
  }

  String? get _botId =>
      RegExp(r'^/bots/([^/]+)').firstMatch(location)?.group(1);

  bool get _inChat => _botId != null && location.contains('/chat');

  /// The tab screens themselves. Only these show the tab bar on phones; everything opened from
  /// them (a chat, settings, the computer, search, password managers…) takes the whole screen,
  /// with a back button.
  static const _tabRoots = {'/', '/bots', '/library', '/tasks'};

  bool get _isDetail => !_tabRoots.contains(location);

  /// The lists themselves, with nothing opened from them yet.
  bool get _listRoot => location == '/' || location == '/bots' || location == '/library' || location == '/settings';

  /// Where two panes fit, these places show their list beside what is opened from it. A call is
  /// laid out across the whole window instead, and Tasks has no pages of its own to open.
  bool get _twoPane =>
      (_index == 0 && !RegExp(r'^/bots/[^/]+/call').hasMatch(location)) || _index == 1 || location.startsWith('/settings');

  /// Pages that lay themselves out around a fold (the board's columns, the live view, a call).
  /// Every other page keeps to one half while the fold divides the window.
  bool get _foldAware =>
      location == '/tasks' ||
      location.startsWith('/computer/live') ||
      location.startsWith('/calls/') ||
      RegExp(r'^/bots/[^/]+/call').hasMatch(location);

  List<_Dest> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Dest(
        '/bots',
        LucideIcons.messagesSquare,
        LucideIcons.messagesSquare,
        l10n.navChats,
      ),
      _Dest(
        '/library',
        LucideIcons.library,
        LucideIcons.library,
        l10n.navLibrary,
      ),
      _Dest(
        '/tasks',
        LucideIcons.listTodo,
        LucideIcons.listTodo,
        l10n.navTasks,
      ),
    ];
  }

  /// A chat the shell opened beside the list goes back to the list when the window stops having
  /// room for both (the device closed) and nobody touched it.
  void _settleRest(BuildContext context, WidgetRef ref, LayoutSize size) {
    final opened = ref.read(splitRestProvider).opened;
    if (opened == null) return;
    final here = Uri.parse(opened).path == location;
    if (size == LayoutSize.split && here) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final now = ref.read(splitRestProvider);
      if (now.opened != opened) return;
      ref.read(splitRestProvider.notifier).clear();
      if (here && !now.touched && size == LayoutSize.phone) {
        PageMotion.snapOnce();
        context.go('/bots');
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Approvals and takeovers reload when the app comes back to the front.
    ref.watch(waitingRefreshProvider);
    // A day of use, for the rating prompt's rules (D-305).
    ref.read(reviewPromptProvider).recordUseOnce();
    ref.listen(aboutYouProvider, (_, _) {});
    // Last launch's photo, decoded while the splash fades, so the avatar opens with it.
    ref.listen(savedMeProvider, (_, next) {
      final id = next.value?.photoId;
      if (id != null) unawaited(precacheImage(cachedNetworkImage(ref.read(backendProvider).photoUrl(id)), context, onError: (_, _) {}));
    });
    ref.listen(quietHoursProvider, (_, _) {});
    ref.listen(authMethodsProvider, (_, _) {});
    ref.listen(usageMonthProvider, (_, _) {});
    ref.listen(billingProvider, (_, _) {});
    ref.listen(adminOverviewProvider, (_, _) {});
    ref.listen(computersProvider, (_, _) {});
    ref.listen(credentialsProvider, (_, _) {});
    ref.listen(savedThemesProvider, (_, _) {});
    ref.listen(advancedOpenProvider, (_, _) {});
    ref.listen(showBotStepsProvider, (_, _) {});
    ref.listen(showReplyUsageProvider, (_, _) {});
    ref.listen(computerPanelWidthProvider, (_, _) {});
    ref.listen(launchAtLoginProvider, (_, _) {});
    ref.listen(autoUpdateChecksProvider, (_, _) {});
    ref.listen(appVersionProvider, (_, _) {});
    // Settings rows that appear only when these say so: loaded now, so the page opens complete
    // instead of rows popping in and pushing the others down.
    ref.listen(referralProvider, (_, _) {});
    ref.listen(emailTipsProvider, (_, _) {});
    ref.listen(remoteAccessAvailableProvider, (_, _) {});
    if (_botId case final botId?) {
      ref.listen(botQuietProvider(botId), (_, _) {});
      ref.listen(botCheckinsProvider(botId), (_, _) {});
    }
    // The chat a wide window opens with next time (D-383).
    LastChat.remember(ref.watch(currentOrgIdProvider), location);
    final fold = FoldInfo.of(context);
    final width = MediaQuery.sizeOf(context).width;
    var size = layoutFor(width);
    // A fold down the middle makes two panes of a narrower window too (Android foldables).
    if ((size == LayoutSize.phone || size == LayoutSize.tablet) && fold.splitX != null && width >= 600) {
      size = LayoutSize.split;
    }
    _settleRest(context, ref, size);
    final badge = ref.watch(inboxBadgeProvider);
    // Always the same wrapper, so the page under it keeps its state when the banner comes or goes.
    final inner = _SuspendedBanner(suspended: ref.watch(currentOrgProvider)?.suspended == true, child: this.child);
    final child = IncomingCallBanner(child: InAppAlertBanner(location: location, child: inner));
    // The wake word listens while the app is open (D-144).
    if (wakeWordSupported) ref.watch(wakeWordProvider);
    final dests = _destinations(context);
    void go(int i) {
      // The tab you're already on: back to the top of its list, as on iOS and Android.
      if (location == dests[i].path) {
        TabReselect.scrollToTop(context, i);
        return;
      }
      context.go(dests[i].path);
    }

    final shell = _buildShell(context, ref, size, fold, badge, child, dests, go);
    if (size == LayoutSize.phone) return shell;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            showWorkspaceSearch(context),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showWorkspaceSearch(context),
      },
      child: Focus(autofocus: true, skipTraversal: true, child: shell),
    );
  }

  Widget _buildShell(
    BuildContext context,
    WidgetRef ref,
    LayoutSize size,
    FoldInfo fold,
    int badge,
    Widget child,
    List<_Dest> dests,
    void Function(int) go,
  ) {
    final media = MediaQuery.of(context);
    final tabs = [
      for (final d in dests)
        FloatingTabDestination(
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          label: d.label,
          badge: d.path == '/bots' ? badge : 0,
        ),
    ];
    // Connecting more apps (and MCP servers) sits beside the tabs; search sits in
    // the Chats header next to "+" (Cmd/Ctrl+K on larger windows, D-103).
    final apps = FloatingTabAction(
      key: const Key('tabApps'),
      icon: LucideIcons.puzzle,
      label: context.l10n.connectAppsTitle,
      onPressed: () => context.pushOnce('/settings/integrations'),
    );
    // What a screen needs to know about the shell around it (ui/shell_layout.dart).
    Widget scope(Widget child, {required NavKind nav, PaneRole pane = PaneRole.single, Rect? slot}) => ShellLayout(
      size: size,
      nav: nav,
      pane: pane,
      location: location,
      child: StripSlot(rect: slot, child: child),
    );

    if (size == LayoutSize.phone) {
      final showBar = !_isDetail;
      // An iPhone Duo's outer screen: the page keeps clear of the strip, its buttons and the tabs
      // go in it (D-411).
      if (fold.hasStrip) {
        final onRight = fold.strip == StripSide.right;
        final pane = Rect.fromLTRB(
          onRight ? 0 : fold.stripWidth,
          0,
          media.size.width - (onRight ? fold.stripWidth : 0),
          media.size.height,
        );
        final action = stripFitsAction(media, fold, tabs.length);
        final tabsHeight = showBar ? StripTabs.heightFor(tabs.length, action: action) : 0.0;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fromRect(
                rect: pane,
                child: MediaQuery(
                  data: paneMedia(media, pane),
                  child: scope(child, nav: NavKind.strip, slot: stripSlot(media, fold, tabsHeight)),
                ),
              ),
              _StripChrome(
                fold: fold,
                tabs: showBar
                    ? StripTabs(destinations: tabs, currentIndex: _index, onSelected: go, action: action ? apps : null)
                    : null,
              ),
            ],
          ),
        );
      }
      return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              // Tab screens scroll under the floating bar; their lists end above it.
              child: MediaQuery(
                data: showBar
                    ? media.copyWith(
                        padding: media.padding.copyWith(
                          bottom: FloatingTabChrome.bottomInset(context),
                        ),
                      )
                    : media,
                child: scope(child, nav: NavKind.tabBar),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !showBar,
                child: AnimatedSlide(
                  offset: showBar ? Offset.zero : const Offset(0, 1.4),
                  duration: AppMotion.of(
                    context,
                    const Duration(milliseconds: 280),
                  ),
                  curve: AppMotion.curve,
                  child: FloatingTabChrome(
                    currentIndex: _index,
                    onDestinationSelected: go,
                    destinations: tabs,
                    action: apps,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Screens inside the shell have their own Scaffolds and make room for the keyboard
    // themselves; resizing here too would take the keyboard's height off twice.
    if (size == LayoutSize.tablet) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Row(
          children: [
            _NavSurface(
              child: _Rail(
                dests: dests,
                index: _index,
                badge: badge,
                onSelected: go,
                settingsOpen: location.startsWith('/settings'),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                child: scope(child, nav: NavKind.rail),
              ),
            ),
          ],
        ),
      );
    }

    if (size == LayoutSize.split) {
      return _SplitShell(
        shell: this,
        fold: fold,
        badge: badge,
        dests: dests,
        tabs: tabs,
        apps: apps,
        go: go,
        child: child,
      );
    }

    final panelOpen = ref.watch(computerPanelProvider);
    final Widget content;
    // Only the bare Bots page asks to pick a bot; group chats and Pages live under the same tab.
    if (_index == 0 &&
        _botId == null &&
        (location == '/bots' || location == '/')) {
      content = _SelectBotPlaceholder(
        onCreate: () => showCreateBot(context, ref),
      );
    } else if (location.startsWith('/settings/') &&
        MediaQuery.sizeOf(context).width - _Sidebar.width >=
            _settingsSplitWidth) {
      // Wide windows: a settings page opens beside the settings list (like System Settings), so
      // moving between pages is one click and the page doesn't float in a sea of empty space.
      content = Row(
        children: [
          SizedBox(
            width: _settingsListWidth,
            child: SettingsScreen(
              key: const Key('settingsPane'),
              pane: true,
              current: location,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: context.appColors.hairline,
          ),
          Expanded(child: child),
        ],
      );
    } else {
      content = child;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          _NavSurface(
            child: _Sidebar(
              dests: dests,
              index: _index,
              badge: badge,
              selectedBotId: _botId,
              onSelected: go,
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              // The sidebar lists the chats, so the Chats tab has no page of its own here.
              child: scope(content, nav: NavKind.sidebar, pane: _index == 0 ? PaneRole.detail : PaneRole.single),
            ),
          ),
          if (_inChat)
            AnimatedSize(
              duration: ref.watch(_panelDraggingProvider)
                  ? Duration.zero
                  : AppMotion.of(context, const Duration(milliseconds: 260)),
              curve: AppMotion.curve,
              alignment: Alignment.centerLeft,
              child: panelOpen
                  // Frosted, so the computer reads as its own pane over the chat's wallpaper.
                  ? _ResizablePanel(
                      // Below the status bar: on an iPad on its side the clock and battery sat
                      // on top of the computer's card.
                      child: SafeArea(
                        left: false,
                        child: ComputerScreen(botId: _botId, embedded: true),
                      ),
                    )
                  : const SizedBox(width: 0, height: double.infinity),
            ),
        ],
      ),
    );
  }
}

/// What the shell draws in the strip itself: the tabs at its bottom. The top belongs to iOS (the
/// camera, the clock, the battery) and the middle to the page's header (ui/side_strip.dart).
class _StripChrome extends StatelessWidget {
  const _StripChrome({required this.fold, required this.tabs});
  final FoldInfo fold;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final onRight = fold.strip == StripSide.right;
    return Positioned(
      left: onRight ? null : FoldInfo.stripOuterMargin,
      right: onRight ? FoldInfo.stripOuterMargin : null,
      width: fold.stripWidth - FoldInfo.stripOuterMargin,
      top: fold.stripTop,
      bottom: media.size.height - fold.stripBottom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, const Duration(milliseconds: 220)),
          switchInCurve: AppMotion.curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: tabs ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Two panes (D-411): the tab's list on the left, what is opened from it on the right. On a
/// folding phone they meet on the fold, and while the fold divides the window the band between
/// them stays empty. Without a fold the list takes a fixed width beside the rail.
class _SplitShell extends ConsumerWidget {
  const _SplitShell({
    required this.shell,
    required this.fold,
    required this.badge,
    required this.dests,
    required this.tabs,
    required this.apps,
    required this.go,
    required this.child,
  });
  final HomeShell shell;
  final FoldInfo fold;
  final int badge;
  final List<_Dest> dests;
  final List<FloatingTabDestination> tabs;
  final FloatingTabAction apps;
  final void Function(int) go;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final location = shell.location;
    final strip = fold.hasStrip;
    // The strip where there is one, a rail where there is room for it, else the floating bar.
    final nav = strip ? NavKind.strip : (width >= AppBreakpoints.split ? NavKind.rail : NavKind.tabBar);
    final stripLeft = strip && fold.strip == StripSide.left ? fold.stripWidth : 0.0;
    final stripRight = strip && fold.strip == StripSide.right ? fold.stripWidth : 0.0;
    // The band to keep empty, while a fold running top to bottom divides the window.
    final gap = fold.foldVertical ? fold.gap : null;
    // While the fold divides the window, a page that wasn't made for it keeps to the right half
    // and the chats take the left one.
    final twoPane = shell._twoPane || (gap != null && !shell._foldAware);
    final hidden = twoPane && !shell._listRoot && gap == null && ref.watch(splitExpandedProvider);
    final onTab = !shell._isDetail;
    final action = !strip || stripFitsAction(media, fold, tabs.length);
    final tabsHeight = StripTabs.heightFor(tabs.length, action: action);

    ({bool fits, double leftEnd, double rightStart, double meet}) geometry(double contentLeft, double contentRight) {
      final meet = fold.splitX ?? (strip ? width / 2 : contentLeft + _listPaneWidth);
      final leftEnd = gap?.left ?? meet;
      final rightStart = gap?.right ?? meet;
      final fits = twoPane && leftEnd - contentLeft >= 280 && contentRight - rightStart >= 300;
      return (fits: fits, leftEnd: leftEnd, rightStart: rightStart, meet: meet);
    }

    Widget panes(double contentLeft, double contentRight) {
      final g = geometry(contentLeft, contentRight);
      final showList = g.fits && !hidden;
      // With two panes' worth of room the tabs stay in the strip on every page, as a rail would.
      final slot = strip ? stripSlot(media, fold, tabsHeight) : null;
      final left = Rect.fromLTRB(contentLeft, 0, g.leftEnd, height);
      final right = Rect.fromLTRB(showList ? g.rightStart : contentLeft, 0, contentRight, height);
      // The floating bar (no strip, no room for a rail) sits under the list, or under the page's
      // leading half while a fold divides it.
      final bar = nav == NavKind.tabBar && (showList || onTab);
      final barWidth = showList ? left.width : (gap != null ? gap.left - contentLeft : right.width);

      Widget pane(Rect at, Widget content, {required PaneRole role, Rect? slot, bool underBar = false, Key? key}) {
        var data = paneMedia(media, at);
        if (underBar) data = data.copyWith(padding: data.padding.copyWith(bottom: FloatingTabChrome.bottomInset(context)));
        return Positioned(
          key: key,
          left: at.left - contentLeft,
          width: at.width,
          top: 0,
          bottom: 0,
          child: MediaQuery(
            data: data,
            child: FoldPane(
              rect: at,
              child: ShellLayout(
                size: LayoutSize.split,
                nav: nav,
                pane: role,
                location: location,
                listHidden: hidden,
                canToggleList: g.fits && gap == null && !shell._listRoot,
                child: StripSlot(rect: slot, child: content),
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          if (showList)
            pane(left, _PaneReveal(child: _ListPane(shell: shell)), role: PaneRole.list, underBar: bar, key: const ValueKey('listPane')),
          if (showList && gap == null)
            Positioned(
              left: g.meet - contentLeft,
              top: 0,
              bottom: 0,
              child: VerticalDivider(width: 1, thickness: 1, color: context.appColors.hairline),
            ),
          pane(
            right,
            // A touch here makes a chat the shell opened by itself the person's own (see SplitRest).
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => ref.read(splitRestProvider.notifier).touch(),
              child: child,
            ),
            role: showList ? PaneRole.detail : PaneRole.single,
            slot: slot,
            underBar: bar && !showList && onTab,
            key: const ValueKey('detailPane'),
          ),
          if (bar)
            Positioned(
              left: 0,
              width: barWidth,
              bottom: 0,
              child: FloatingTabChrome(
                currentIndex: shell._index,
                onDestinationSelected: go,
                destinations: tabs,
                action: apps,
              ),
            ),
        ],
      );
    }

    final Widget body;
    if (nav == NavKind.rail) {
      body = Row(
        children: [
          _NavSurface(
            child: _Rail(
              dests: dests,
              index: shell._index,
              badge: badge,
              onSelected: go,
              settingsOpen: location.startsWith('/settings'),
            ),
          ),
          // The rail's own width decides where the panes start.
          Expanded(child: LayoutBuilder(builder: (context, box) => panes(width - box.maxWidth, width))),
        ],
      );
    } else {
      body = Stack(
        children: [
          Positioned.fill(left: stripLeft, right: stripRight, child: panes(stripLeft, width - stripRight)),
          if (strip)
            _StripChrome(
              fold: fold,
              tabs: StripTabs(destinations: tabs, currentIndex: shell._index, onSelected: go, action: action ? apps : null),
            ),
        ],
      );
    }
    return Scaffold(resizeToAvoidBottomInset: false, body: body);
  }
}

/// The list pane arrives from the fold when two panes open (the device opened, or the list was
/// shown again): a short slide and fade, or none with reduced motion. With [hingeMotionProvider]
/// on, for the first moments it comes in as far as the hinge is open instead.
class _PaneReveal extends ConsumerStatefulWidget {
  const _PaneReveal({required this.child});
  final Widget child;

  @override
  ConsumerState<_PaneReveal> createState() => _PaneRevealState();
}

class _PaneRevealState extends ConsumerState<_PaneReveal> {
  /// Following the hinge, for a moment after arriving. Then the pane is simply there, however
  /// the device is held.
  var _following = false;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    if (ref.read(hingeMotionProvider)) {
      _following = true;
      _settle = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _following = false);
      });
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var shown = 1.0;
    if (_following && !MediaQuery.disableAnimationsOf(context)) {
      final angle = ref.watch(nativeFoldProvider.select((n) => n.hinge == HingeStatus.partlyOpen ? n.angle : null));
      // From a right angle to nearly flat.
      if (angle != null) shown = ((angle - 90) / 70).clamp(0.0, 1.0);
    }
    final fromRight = Directionality.of(context) == TextDirection.ltr;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: shown),
      duration: AppMotion.of(context, const Duration(milliseconds: 260)),
      curve: AppMotion.curve,
      child: widget.child,
      builder: (context, t, child) => t >= 1
          ? child!
          : Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset((1 - t) * (fromRight ? 28 : -28), 0), child: child),
            ),
    );
  }
}

/// The left pane: the list of the place you are in. The chats, the Library as last filtered, the
/// settings list, or the bot's computer when its chat asks for it.
class _ListPane extends ConsumerStatefulWidget {
  const _ListPane({required this.shell});
  final HomeShell shell;

  @override
  ConsumerState<_ListPane> createState() => _ListPaneState();
}

class _ListPaneState extends ConsumerState<_ListPane> {
  /// The Library's address with its filters, kept while one of its items is open beside it.
  Uri? _library;

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final location = shell.location;
    if (location.startsWith('/settings')) {
      return SettingsScreen(key: const Key('settingsPane'), pane: true, current: location);
    }
    if (shell._index == 1) {
      if (location == '/library' && shell.uri != null) _library = shell.uri;
      final q = _library?.queryParameters ?? const <String, String>{};
      return LibraryScreen(
        key: ValueKey('libraryPane?${_library?.query ?? ''}'),
        kind: CreationKind.values.where((k) => k.value == q['kind']).firstOrNull,
        botId: q['bot'],
        projectId: q['project'],
        query: q['q'] ?? '',
      );
    }
    // The bot's computer in place of the list, with its chat still beside it.
    if (shell._inChat && ref.watch(splitComputerProvider)) {
      return SafeArea(
        right: false,
        child: ComputerScreen(key: ValueKey('computerPane-${shell._botId}'), botId: shell._botId, embedded: true),
      );
    }
    return BotsScreen(key: chatsListKey, selectedBotId: shell._botId);
  }
}

/// The Chats tab's page. On a phone and a tablet it is the list. Where the shell shows the list
/// itself (two panes, the desktop sidebar) there is nothing to draw here: with two panes it opens
/// the chat last open on this device beside the list (D-383), as a wide window does.
class ChatsTabPage extends ConsumerWidget {
  const ChatsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = ShellLayout.maybeOf(context);
    if (shell == null || !shell.listInShell) return BotsScreen(key: chatsListKey);
    // Only while this is the page on screen: under a chat, or fading out behind another place,
    // it must not open anything.
    if (shell.size != LayoutSize.split || (shell.location != '/bots' && shell.location != '/')) return const SizedBox.shrink();
    return _SelectBotPlaceholder(
      onCreate: () => showCreateBot(context, ref),
      onOpened: ref.read(splitRestProvider.notifier).opened,
      quiet: true,
    );
  }
}

/// The Library tab's page: the Library, or nothing where the shell shows it in the left pane.
class LibraryTabPage extends StatelessWidget {
  const LibraryTabPage({super.key, required this.uri});
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final shell = ShellLayout.maybeOf(context);
    if (shell != null && shell.listInShell) {
      return PanePlaceholder(icon: LucideIcons.library, message: context.l10n.panePickLibrary);
    }
    final q = uri.queryParameters;
    return LibraryScreen(
      key: ValueKey(uri.query),
      kind: CreationKind.values.where((k) => k.value == q['kind']).firstOrNull,
      botId: q['bot'],
      projectId: q['project'],
      query: q['q'] ?? '',
    );
  }
}

/// The Settings page: the list of settings, or nothing where the shell shows that list in the
/// left pane and a settings page opens beside it.
class SettingsRootPage extends StatelessWidget {
  const SettingsRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellLayout.maybeOf(context);
    if (shell != null && shell.size == LayoutSize.split && shell.listInShell) {
      return PanePlaceholder(icon: LucideIcons.settings, message: context.l10n.panePickSetting);
    }
    return const SettingsScreen();
  }
}

/// The right pane before anything is opened in it.
class PanePlaceholder extends StatelessWidget {
  const PanePlaceholder({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpace.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline-edged column the rail and sidebar sit on.
class _NavSurface extends StatelessWidget {
  const _NavSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Glass(
    opacity: context.isDark ? 0.72 : 0.78,
    border: Border(right: BorderSide(color: context.appColors.hairline)),
    child: child,
  );
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.dests,
    required this.index,
    required this.badge,
    required this.onSelected,
    required this.settingsOpen,
  });
  final List<_Dest> dests;
  final int index;
  final int badge;
  final ValueChanged<int> onSelected;
  final bool settingsOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    // A phone on its side is too short for labelled places plus the switcher, search and avatar:
    // the rail overflowed by about 20 px. There the places show as icons only.
    final short = MediaQuery.sizeOf(context).height < 560;
    return NavigationRail(
      backgroundColor: Colors.transparent,
      selectedIndex: index < 0 ? null : index,
      onDestinationSelected: onSelected,
      labelType: short ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: tt.labelMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: tt.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      leading: const Padding(
        padding: EdgeInsets.only(top: 12, bottom: 20),
        child: WorkspaceSwitcher(compact: true),
      ),
      // Search under the places; the person's avatar (Settings) at the bottom, as in the sidebar.
      trailingAtBottom: true,
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('railSearch'),
              tooltip: '${context.l10n.search} (⌘K)',
              icon: Icon(LucideIcons.search, color: scheme.onSurfaceVariant),
              onPressed: () => showWorkspaceSearch(context),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: settingsOpen ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  key: const Key('railMe'),
                  customBorder: const CircleBorder(),
                  onTap: () => context.go('/settings'),
                  child: Tooltip(
                    message: context.l10n.settings,
                    child: const MeAvatar(size: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      destinations: [
        for (final d in dests)
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: d.path == '/bots' && badge > 0,
              label: Text(
                '$badge',
                style: const TextStyle(fontFeatures: AppText.tabular),
              ),
              child: Icon(d.icon),
            ),
            selectedIcon: Badge(
              isLabelVisible: d.path == '/bots' && badge > 0,
              label: Text(
                '$badge',
                style: const TextStyle(fontFeatures: AppText.tabular),
              ),
              child: Icon(d.selectedIcon),
            ),
            label: Text(d.label),
          ),
      ],
    );
  }
}

/// Wide windows: the mark and workspace, the main sections, the bots, and who is signed in.
class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.dests,
    required this.index,
    required this.badge,
    required this.selectedBotId,
    required this.onSelected,
  });
  final List<_Dest> dests;
  final int index;
  final int badge;
  final String? selectedBotId;
  final ValueChanged<int> onSelected;

  static const double width = 272;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final folders = ref.watch(botFoldersProvider).value ?? const <BotFolder>[];
    final groups =
        ref.watch(groupChatsProvider).value ?? const <Conversation>[];
    final routeUri = routerStateOf(context)?.uri;
    final location = routeUri?.path ?? '';
    final scheme = context.colorScheme;
    return SafeArea(
      right: false,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                children: [
                  const CasamaMark(size: 34),
                  const SizedBox(width: 8),
                  // The current workspace; tap to switch, create or join one (D-099).
                  const Expanded(child: WorkspaceSwitcher()),
                ],
              ),
            ),
            // Chats first: the bot list fills the sidebar; places and settings sit at the bottom.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.bots,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('openSearch'),
                    tooltip: '${l10n.search} (⌘K)',
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    icon: const Icon(LucideIcons.search),
                    onPressed: () => showWorkspaceSearch(context),
                  ),
                  IconButton(
                    key: const Key('createMenu'),
                    tooltip: l10n.newBot,
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    icon: const Icon(LucideIcons.plus),
                    onPressed: () => showCreateBot(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                primary: false,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  // What the Inbox held (D-253): decisions waiting across bots, then Updates
                  // (workspace notices and pages that no chat shows).
                  _SidebarItem(
                    key: const Key('sidebar-needs-you'),
                    leading: Icon(
                      LucideIcons.circleAlert,
                      size: 21,
                      color: scheme.onSurfaceVariant,
                    ),
                    label: l10n.inboxNeedsYou,
                    selected: location == '/inbox' && routeUri?.queryParameters['tab'] == '0',
                    trailing: switch (ref.watch(needsYouCountProvider)) {
                      0 => null,
                      final n => CountPill(n),
                    },
                    onTap: () => context.go('/inbox?tab=0'),
                  ),
                  _SidebarItem(
                    key: const Key('sidebar-updates'),
                    leading: Icon(LucideIcons.bell, size: 21, color: scheme.onSurfaceVariant),
                    label: l10n.updatesRow,
                    selected: location == '/inbox' && routeUri?.queryParameters['tab'] != '0',
                    trailing: switch (ref.watch(unreadUpdatesProvider)) {
                      0 => null,
                      final n => CountPill(n),
                    },
                    onTap: () => context.go('/inbox'),
                  ),
                  // Bots outside folders first, then each folder in order (D-100).
                  for (final (folder, group) in groupBotsByFolder(
                    bots,
                    folders,
                  )) ...[
                    if (folder != null)
                      Padding(
                        key: Key('sidebar-folder-${folder.id}'),
                        padding: const EdgeInsets.fromLTRB(24, 10, 12, 2),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.folder,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                folder.name,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final b in group)
                      _SidebarItem(
                        key: Key('sidebar-bot-${b.id}'),
                        height: 48,
                        leading: BotAvatar(
                          name: b.name,
                          avatar: b.avatarUrl,
                          size: 30,
                          status: b.status,
                          ringColor: scheme.surfaceContainerLow,
                        ),
                        label: b.name,
                        // What it's doing when that matters, else its last message.
                        subtitle: b.status == BotStatusEnum.idle
                            ? lastMessagePreview(context, b)
                            : botStatusLabel(context, b.status),
                        selected: b.id == selectedBotId,
                        trailing: BotActivity(
                          count: ref.watch(botBadgeProvider(b.id)),
                          working: b.status == BotStatusEnum.working,
                        ),
                        onTap: () => context.go('/bots/${b.id}/chat'),
                      ),
                  ],
                  // Group chats (D-118): their own section under the bots, with stacked faces.
                  _SectionHeader(
                    title: l10n.groupChats,
                    action: IconButton(
                      key: const Key('newGroupChat'),
                      tooltip: l10n.newGroupChat,
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      icon: const Icon(LucideIcons.plus),
                      onPressed: () => showNewGroupChat(context, ref),
                    ),
                  ),
                  for (final g in groups)
                    Builder(
                      builder: (context) {
                        final members = [
                          for (final id in g.botIds)
                            ?bots.where((b) => b.id == id).firstOrNull,
                        ];
                        return _SidebarItem(
                          key: Key('sidebar-group-${g.id}'),
                          height: 48,
                          leading: GroupAvatar(
                            bots: members,
                            ringColor: scheme.surfaceContainerLow,
                          ),
                          label: groupTitle(g, bots),
                          subtitle: l10n.groupBotCount(g.botIds.length),
                          selected: location == '/groups/${g.id}',
                          trailing: BotActivity(
                            count: 0,
                            working: groupBusy(g, members),
                          ),
                          onTap: () => context.go('/groups/${g.id}'),
                        );
                      },
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appColors.hairline),
            const SizedBox(height: 6),
            // A server this computer runs: what its setup still has left (D-309).
            const FinishSetupCard(),
            // Casama's monthly email (D-408): asked once, where the server sends it.
            const NewsletterCard(),
            // A minimised call docks here on wide windows (D-327).
            const CallSidebarCard(),
            // The other two places, then the person: their avatar opens Settings.
            for (var i = 0; i < dests.length; i++)
              if (dests[i].path != '/bots')
                _SidebarItem(
                  key: Key('sidebar-nav-${dests[i].path}'),
                  leading: Icon(
                    i == index ? dests[i].selectedIcon : dests[i].icon,
                    size: 21,
                    color: i == index
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  label: dests[i].label,
                  selected: i == index,
                  trailing: dests[i].path == '/inbox' && badge > 0
                      ? CountPill(badge)
                      : null,
                  onTap: () => onSelected(i),
                ),
            _SidebarItem(
              key: const Key('sidebarMe'),
              height: 52,
              leading: const MeAvatar(size: 30),
              label: meLabel(ref),
              subtitle: l10n.settings,
              selected: location.startsWith('/settings'),
              onTap: () => context.go('/settings'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    super.key,
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.subtitle,
    this.height = 44,
  });

  final Widget leading;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final radius = AppRadius.rowAll;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyLarge?.copyWith(
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurface,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sidebar section title with an optional action (like "+" for a new group chat).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 14, 12, 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// The bare Chats page on a wide window (D-383). With bots, it isn't a page of its own: it opens
/// the chat last open on this device, or the most recent bot. Only a workspace without bots stays
/// here, with the way to make the first one.
class _SelectBotPlaceholder extends ConsumerStatefulWidget {
  const _SelectBotPlaceholder({required this.onCreate, this.onOpened, this.quiet = false});
  final VoidCallback onCreate;

  /// Told which chat this opened by itself.
  final void Function(String location)? onOpened;

  /// Beside a list that already says there are no bots: stay empty instead of saying it twice.
  final bool quiet;

  @override
  ConsumerState<_SelectBotPlaceholder> createState() => _SelectBotPlaceholderState();
}

class _SelectBotPlaceholderState extends ConsumerState<_SelectBotPlaceholder> {
  String? _openingFor;

  void _openChat(String orgId) {
    if (_openingFor == orgId) return;
    _openingFor = orgId;
    Future(() async {
      final saved = await LastChat.saved(orgId);
      var groups = const <Conversation>[];
      if (saved != null && saved.startsWith('/groups/')) {
        try {
          groups = await ref.read(groupChatsProvider.future);
        } catch (_) {}
      }
      if (!mounted || ref.read(currentOrgIdProvider) != orgId) return;
      final bots = [
        for (final b in ref.read(botsProvider).value ?? const <Bot>[])
          if (b.orgId == orgId) b,
      ];
      final target = chatToOpen(saved: saved, bots: bots, groups: groups);
      if (target == null) {
        _openingFor = null;
        return;
      }
      // In place of this page, not after it: Back in a browser doesn't land here and bounce.
      Router.neglect(context, () => context.go(target));
      widget.onOpened?.call(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider);
    final orgId = ref.watch(currentOrgIdProvider);
    // Still loading (or another workspace's bots, about to be replaced): a spinner, not "No bots
    // yet" with a New bot button.
    if ((!bots.hasValue && !bots.hasError) || bots.isReloading) return const Center(child: CircularProgressIndicator());
    final hasBots = orgId != null && (bots.value ?? const <Bot>[]).any((b) => b.orgId == orgId);
    if (hasBots) {
      _openChat(orgId);
      return const SizedBox.expand();
    }
    if (widget.quiet) return const SizedBox.expand();
    return EmptyState(
      icon: LucideIcons.messagesSquare,
      illustration: const BlankBotImage(size: 132),
      title: l10n.noBots,
      message: l10n.noBotsHelp,
      action: GlowButton.icon(
        onPressed: widget.onCreate,
        icon: const Icon(LucideIcons.plus),
        label: Text(l10n.newBot),
      ),
    );
  }
}

/// The computer panel with a drag handle on its left edge. Double-click the handle to reset.
/// The chat keeps at least 420 px, and the panel stays between 360 px and 60% of the window.
class _ResizablePanel extends ConsumerStatefulWidget {
  const _ResizablePanel({required this.child});
  final Widget child;

  @override
  ConsumerState<_ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends ConsumerState<_ResizablePanel> {
  var _hover = false;
  var _dragging = false;

  // The edge follows the pointer exactly: width at grab time minus how far the pointer has moved
  // since, so no movement is lost between frames. Raw pointer events start at once (no drag slop).
  double _startX = 0;
  double _startWidth = 0;
  var _moved = false;
  // When the last click (a press and release without dragging) ended, for double clicks.
  DateTime? _lastClick;

  double _max(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.6).clamp(
      ComputerPanelWidth.min,
      (w - 280 - 420).clamp(ComputerPanelWidth.min, double.infinity),
    );
  }

  void _down(PointerDownEvent e, double width) {
    // A double click on the edge (two clicks, no dragging) puts the default width back.
    if (_lastClick != null &&
        DateTime.now().difference(_lastClick!) < kDoubleTapTimeout) {
      _lastClick = null;
      ref.read(computerPanelWidthProvider.notifier)
        ..set(ComputerPanelWidth.defaultWidth)
        ..save();
      return;
    }
    _moved = false;
    _startX = e.position.dx;
    _startWidth = width;
    setState(() => _dragging = true);
    ref.read(_panelDraggingProvider.notifier).set(true);
  }

  void _move(PointerMoveEvent e, double max) {
    if (!_dragging) return;
    if ((e.position.dx - _startX).abs() > 3) _moved = true;
    ref
        .read(computerPanelWidthProvider.notifier)
        .set(
          (_startWidth - (e.position.dx - _startX)).clamp(
            ComputerPanelWidth.min,
            max,
          ),
        );
  }

  void _up() {
    if (!_dragging) return;
    _lastClick = _moved ? null : DateTime.now();
    setState(() => _dragging = false);
    ref.read(_panelDraggingProvider.notifier).set(false);
    ref.read(computerPanelWidthProvider.notifier).save();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final max = _max(context);
    final width = ref
        .watch(computerPanelWidthProvider)
        .clamp(ComputerPanelWidth.min, max);
    final active = _hover || _dragging;
    return Glass(
      border: Border(
        left: BorderSide(
          color: active
              ? scheme.primary.withValues(alpha: 0.6)
              : context.appColors.hairline,
          width: active ? 2 : 1,
        ),
      ),
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 14,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                child: Listener(
                  key: const Key('computerPanelResize'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _down(e, width),
                  onPointerMove: (e) => _move(e, max),
                  onPointerUp: (_) => _up(),
                  onPointerCancel: (_) => _up(),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: AppMotion.fast,
                      child: Container(
                        width: 4,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A suspended workspace (D-094) says so above every screen.
class _SuspendedBanner extends StatelessWidget {
  const _SuspendedBanner({required this.suspended, required this.child});
  final bool suspended;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        ShowHide(
          child: !suspended
              ? null
              : Material(
          key: const Key('suspendedBanner'),
          color: colors.negative.withValues(alpha: 0.12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.ban, size: 18, color: colors.negative),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(context.l10n.workspaceSuspendedBanner)),
                ],
              ),
            ),
          ),
        ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Bots without a folder first (folder null), then each folder in order with its bots in order.
List<(BotFolder?, List<Bot>)> groupBotsByFolder(
  List<Bot> bots,
  List<BotFolder> folders,
) {
  int byKey(Bot a, Bot b) => a.sortKey.compareTo(b.sortKey);
  final known = {for (final f in folders) f.id};
  final out = <(BotFolder?, List<Bot>)>[];
  final loose =
      bots
          .where((b) => b.folderId == null || !known.contains(b.folderId))
          .toList()
        ..sort(byKey);
  if (loose.isNotEmpty) out.add((null, loose));
  for (final f in [
    ...folders,
  ]..sort((a, b) => a.sortKey.compareTo(b.sortKey))) {
    final group = bots.where((b) => b.folderId == f.id).toList()..sort(byKey);
    if (group.isNotEmpty) out.add((f, group));
  }
  return out;
}

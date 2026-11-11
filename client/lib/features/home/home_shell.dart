import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../search/search_view.dart';
import '../groups/group_chats.dart';
import '../../core/providers.dart';
import '../../ui/bot_activity.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/floating_tab_chrome.dart';
import '../../ui/glass.dart';
import '../../ui/kasama_mark.dart';
import '../bots/bots_screen.dart';
import '../computer/computer_screen.dart';
import '../../ui/glow_button.dart';
import '../workspaces/spaces.dart';
import '../voice/phone_calls.dart';
import '../voice/wake_word.dart';

/// Phone: floating tab bar. Tablet: navigation rail. Desktop: a sidebar with the bot list, the
/// chat, and the bot's computer beside it.
enum LayoutSize { phone, tablet, desktop }

LayoutSize layoutFor(double width) => switch (AppBreakpoints.of(width)) {
  WindowSize.compact => LayoutSize.phone,
  WindowSize.medium => LayoutSize.tablet,
  WindowSize.expanded => LayoutSize.desktop,
};

/// Whether the computer panel is open beside the chat on wide windows.
class ComputerPanelOpen extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final computerPanelProvider = NotifierProvider<ComputerPanelOpen, bool>(ComputerPanelOpen.new);

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

final computerPanelWidthProvider = NotifierProvider<ComputerPanelWidth, double>(ComputerPanelWidth.new);

/// True while the panel's edge is being dragged, so the open/close animation doesn't lag the drag.
class _PanelDragging extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final _panelDraggingProvider = NotifierProvider<_PanelDragging, bool>(_PanelDragging.new);

class _Dest {
  const _Dest(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/inbox') || location.startsWith('/approvals')) return 1;
    if (location.startsWith('/tasks')) return 2;
    if (location.startsWith('/computer')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/search')) return 5;
    return 0;
  }

  String? get _botId => RegExp(r'^/bots/([^/]+)').firstMatch(location)?.group(1);

  /// Screens opened from a tab (a chat, a settings page): on phones they take the whole screen.
  bool get _isDetail => _botId != null || location.startsWith('/groups/') || location == '/pages' || location.startsWith('/computer/') || RegExp(r'^/settings/.+').hasMatch(location) || location.startsWith('/approvals/') || location.startsWith('/quick-ask');

  List<_Dest> _destinations(BuildContext context, {bool phone = false}) {
    final l10n = context.l10n;
    return [
      _Dest('/bots', LucideIcons.messagesSquare, LucideIcons.messagesSquare, l10n.navBots),
      _Dest('/inbox', LucideIcons.inbox, LucideIcons.inbox, l10n.inbox),
      _Dest('/tasks', LucideIcons.squareKanban, LucideIcons.squareKanban, l10n.navBoard),
      _Dest('/computer', LucideIcons.monitor, LucideIcons.monitor, l10n.navComputer),
      _Dest('/settings', LucideIcons.settings, LucideIcons.settings, l10n.navSettings),
      // Phones get search as a tab; larger windows use Cmd/Ctrl+K and the sidebar button (D-103).
      if (phone) _Dest('/search', LucideIcons.search, LucideIcons.search, l10n.search),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = layoutFor(MediaQuery.sizeOf(context).width);
    final badge = ref.watch(inboxBadgeProvider);
    final inner = ref.watch(currentOrgProvider)?.suspended == true ? _SuspendedBanner(child: this.child) : this.child;
    final child = IncomingCallBanner(child: inner);
    // The wake word listens while the app is open (D-144).
    if (wakeWordSupported) ref.watch(wakeWordProvider);
    final dests = _destinations(context, phone: size == LayoutSize.phone);
    void go(int i) => context.go(dests[i].path);
    final shell = _buildShell(context, ref, size, badge, child, dests, go);
    if (size == LayoutSize.phone) return shell;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () => showWorkspaceSearch(context),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => showWorkspaceSearch(context),
      },
      child: Focus(autofocus: true, skipTraversal: true, child: shell),
    );
  }

  Widget _buildShell(BuildContext context, WidgetRef ref, LayoutSize size, int badge, Widget child, List<_Dest> dests, void Function(int) go) {
    if (size == LayoutSize.phone) {
      final showBar = !_isDetail;
      final media = MediaQuery.of(context);
      return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              // Tab screens scroll under the floating bar; their lists end above it.
              child: MediaQuery(
                data: showBar ? media.copyWith(padding: media.padding.copyWith(bottom: FloatingTabChrome.bottomInset(context))) : media,
                child: child,
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
                  duration: AppMotion.of(context, const Duration(milliseconds: 280)),
                  curve: AppMotion.curve,
                  child: FloatingTabChrome(
                    currentIndex: _index,
                    onDestinationSelected: go,
                    destinations: [for (final d in dests) FloatingTabDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: d.label, badge: d.path == '/inbox' ? badge : 0)],
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
              child: _Rail(dests: dests, index: _index, badge: badge, onSelected: go),
            ),
            Expanded(
              child: MediaQuery.removePadding(context: context, removeLeft: true, child: child),
            ),
          ],
        ),
      );
    }

    final inChat = _botId != null && location.contains('/chat');
    final panelOpen = ref.watch(computerPanelProvider);
    final Widget content;
    // Only the bare Bots page asks to pick a bot; group chats and Pages live under the same tab.
    if (_index == 0 && _botId == null && (location == '/bots' || location == '/')) {
      content = _SelectBotPlaceholder(onCreate: () => showCreateBot(context, ref));
    } else if (location.startsWith('/settings/') && MediaQuery.sizeOf(context).width - _Sidebar.width >= _settingsSplitWidth) {
      // Wide windows: a settings page opens beside the settings list (like System Settings), so
      // moving between pages is one click and the page doesn't float in a sea of empty space.
      content = Row(
        children: [
          SizedBox(
            width: _settingsListWidth,
            child: SettingsScreen(key: const Key('settingsPane'), pane: true, current: location),
          ),
          VerticalDivider(width: 1, thickness: 1, color: context.appColors.hairline),
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
            child: _Sidebar(dests: dests, index: _index, badge: badge, selectedBotId: _botId, onSelected: go),
          ),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeLeft: true, child: content),
          ),
          if (inChat)
            AnimatedSize(
              duration: ref.watch(_panelDraggingProvider) ? Duration.zero : AppMotion.of(context, const Duration(milliseconds: 260)),
              curve: AppMotion.curve,
              alignment: Alignment.centerLeft,
              child: panelOpen
                  // Frosted, so the computer reads as its own pane over the chat's wallpaper.
                  ? _ResizablePanel(child: ComputerScreen(botId: _botId, embedded: true))
                  : const SizedBox(width: 0, height: double.infinity),
            ),
        ],
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
  const _Rail({required this.dests, required this.index, required this.badge, required this.onSelected});
  final List<_Dest> dests;
  final int index;
  final int badge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    return NavigationRail(
      backgroundColor: Colors.transparent,
      selectedIndex: index,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: tt.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: tt.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
      leading: const Padding(padding: EdgeInsets.only(top: 12, bottom: 20), child: WorkspaceSwitcher(compact: true)),
      destinations: [
        for (final d in dests)
          NavigationRailDestination(
            icon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge'), child: Icon(d.icon)),
            selectedIcon: Badge(isLabelVisible: d.path == '/inbox' && badge > 0, label: Text('$badge'), child: Icon(d.selectedIcon)),
            label: Text(d.label),
          ),
      ],
    );
  }
}

/// Wide windows: the mark and workspace, the main sections, the bots, and who is signed in.
class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.dests, required this.index, required this.badge, required this.selectedBotId, required this.onSelected});
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
    final groups = ref.watch(groupChatsProvider).value ?? const <Conversation>[];
    final location = GoRouter.maybeOf(context)?.state.uri.path ?? '';
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
                  const KasamaMark(size: 34),
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
                      style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.2),
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
                  IconButton(key: const Key('createMenu'), tooltip: l10n.createMenuTitle, visualDensity: VisualDensity.compact, iconSize: 20, icon: const Icon(LucideIcons.plus), onPressed: () => showCreateMenu(context, ref)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  // Bots outside folders first, then each folder in order (D-100).
                  for (final (folder, group) in groupBotsByFolder(bots, folders)) ...[
                    if (folder != null)
                      Padding(
                        key: Key('sidebar-folder-${folder.id}'),
                        padding: const EdgeInsets.fromLTRB(24, 10, 12, 2),
                        child: Row(
                          children: [
                            Icon(LucideIcons.folder, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                folder.name,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final b in group)
                      _SidebarItem(
                        key: Key('sidebar-bot-${b.id}'),
                        height: 48,
                        leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 30, status: b.status, ringColor: scheme.surfaceContainerLow),
                        label: b.name,
                        subtitle: b.status == BotStatusEnum.idle ? null : botStatusLabel(context, b.status),
                        selected: b.id == selectedBotId,
                        trailing: BotActivity(count: ref.watch(botBadgeProvider(b.id)), working: b.status == BotStatusEnum.working),
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
                        final members = [for (final id in g.botIds) ?bots.where((b) => b.id == id).firstOrNull];
                        return _SidebarItem(
                          key: Key('sidebar-group-${g.id}'),
                          height: 48,
                          leading: GroupAvatar(bots: members, ringColor: scheme.surfaceContainerLow),
                          label: groupTitle(g, bots),
                          subtitle: l10n.groupBotCount(g.botIds.length),
                          selected: location == '/groups/${g.id}',
                          trailing: BotActivity(count: 0, working: members.any((b) => b.status == BotStatusEnum.working)),
                          onTap: () => context.go('/groups/${g.id}'),
                        );
                      },
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appColors.hairline),
            const SizedBox(height: 6),
            _SidebarItem(
              key: const Key('sidebarPages'),
              leading: Icon(LucideIcons.fileText, size: 21, color: location == '/pages' ? scheme.primary : scheme.onSurfaceVariant),
              label: l10n.pages,
              selected: location == '/pages',
              onTap: () => context.go('/pages'),
            ),
            for (var i = 0; i < dests.length; i++)
              if (dests[i].path != '/bots')
                _SidebarItem(
                  key: Key('sidebar-nav-${dests[i].path}'),
                  leading: Icon(i == index ? dests[i].selectedIcon : dests[i].icon, size: 21, color: i == index ? scheme.primary : scheme.onSurfaceVariant),
                  label: dests[i].label,
                  subtitle: dests[i].path == '/settings' ? ref.watch(backendProvider).userEmail : null,
                  selected: i == index,
                  trailing: dests[i].path == '/inbox' && badge > 0 ? CountPill(badge) : null,
                  onTap: () => onSelected(i),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({super.key, required this.leading, required this.label, required this.selected, required this.onTap, this.trailing, this.subtitle, this.height = 44});

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
          decoration: BoxDecoration(color: selected ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent, borderRadius: radius),
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
                              style: tt.bodyLarge?.copyWith(color: selected ? scheme.primary : scheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, height: 1.2),
                            ),
                            if (subtitle != null) Text(subtitle!, maxLines: 1, style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.2)),
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
            style: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _SelectBotPlaceholder extends ConsumerWidget {
  const _SelectBotPlaceholder({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasBots = (ref.watch(botsProvider).value ?? const []).isNotEmpty;
    return EmptyState(
      icon: LucideIcons.messagesSquare,
      title: hasBots ? l10n.selectBot : l10n.noBots,
      message: l10n.selectBotHelp,
      action: GlowButton.icon(onPressed: onCreate, icon: const Icon(LucideIcons.plus), label: Text(l10n.newBot)),
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
    return (w * 0.6).clamp(ComputerPanelWidth.min, (w - 280 - 420).clamp(ComputerPanelWidth.min, double.infinity));
  }

  void _down(PointerDownEvent e, double width) {
    // A double click on the edge (two clicks, no dragging) puts the default width back.
    if (_lastClick != null && DateTime.now().difference(_lastClick!) < kDoubleTapTimeout) {
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
    ref.read(computerPanelWidthProvider.notifier).set((_startWidth - (e.position.dx - _startX)).clamp(ComputerPanelWidth.min, max));
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
    final width = ref.watch(computerPanelWidthProvider).clamp(ComputerPanelWidth.min, max);
    final active = _hover || _dragging;
    return Glass(
      border: Border(
        left: BorderSide(color: active ? scheme.primary.withValues(alpha: 0.6) : context.appColors.hairline, width: active ? 2 : 1),
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
                        decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2)),
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
  const _SuspendedBanner({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Material(
          key: const Key('suspendedBanner'),
          color: colors.negative.withValues(alpha: 0.12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
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
        Expanded(child: child),
      ],
    );
  }
}

/// Bots without a folder first (folder null), then each folder in order with its bots in order.
List<(BotFolder?, List<Bot>)> groupBotsByFolder(List<Bot> bots, List<BotFolder> folders) {
  int byKey(Bot a, Bot b) => a.sortKey.compareTo(b.sortKey);
  final known = {for (final f in folders) f.id};
  final out = <(BotFolder?, List<Bot>)>[];
  final loose = bots.where((b) => b.folderId == null || !known.contains(b.folderId)).toList()..sort(byKey);
  if (loose.isNotEmpty) out.add((null, loose));
  for (final f in [...folders]..sort((a, b) => a.sortKey.compareTo(b.sortKey))) {
    final group = bots.where((b) => b.folderId == f.id).toList()..sort(byKey);
    if (group.isNotEmpty) out.add((f, group));
  }
  return out;
}

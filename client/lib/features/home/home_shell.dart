import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
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
    if (location.startsWith('/inbox') || location.startsWith('/approvals') || location.startsWith('/tasks')) return 1;
    if (location.startsWith('/computer')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  String? get _botId => RegExp(r'^/bots/([^/]+)').firstMatch(location)?.group(1);

  /// Screens opened from a tab (a chat, a settings page): on phones they take the whole screen.
  bool get _isDetail =>
      _botId != null ||
      location.startsWith('/computer/') ||
      RegExp(r'^/settings/.+').hasMatch(location) ||
      location.startsWith('/approvals/') ||
      location.startsWith('/quick-ask');

  List<_Dest> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Dest('/bots', LucideIcons.messagesSquare, LucideIcons.messagesSquare, l10n.navBots),
      _Dest('/inbox', LucideIcons.inbox, LucideIcons.inbox, l10n.inbox),
      _Dest('/computer', LucideIcons.monitor, LucideIcons.monitor, l10n.navComputer),
      _Dest('/settings', LucideIcons.settings, LucideIcons.settings, l10n.navSettings),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = layoutFor(MediaQuery.sizeOf(context).width);
    final badge = ref.watch(inboxBadgeProvider);
    final dests = _destinations(context);
    void go(int i) => context.go(dests[i].path);

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
                    destinations: [
                      for (final d in dests)
                        FloatingTabDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: d.label, badge: d.path == '/inbox' ? badge : 0),
                    ],
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
    if (_index == 0 && _botId == null) {
      content = _SelectBotPlaceholder(onCreate: () => showCreateBot(context, ref));
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
              duration: AppMotion.of(context, const Duration(milliseconds: 260)),
              curve: AppMotion.curve,
              alignment: Alignment.centerLeft,
              child: panelOpen
                  // Frosted, so the computer reads as its own pane over the chat's wallpaper.
                  ? Glass(
                      border: Border(left: BorderSide(color: context.appColors.hairline)),
                      child: SizedBox(width: 420, child: ComputerScreen(botId: _botId, embedded: true)),
                    )
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
      leading: const Padding(padding: EdgeInsets.only(top: 12, bottom: 20), child: KasamaMark(size: 36)),
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
    final org = ref.watch(currentOrgProvider);
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appTitle, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                        if (org != null)
                          Text(
                            org.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
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
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final b in bots)
                    _SidebarItem(
                      key: Key('sidebar-bot-${b.id}'),
                      height: 48,
                      leading: BotAvatar(name: b.name, size: 30, status: b.status, ringColor: scheme.surfaceContainerLow),
                      label: b.name,
                      subtitle: b.status == BotStatusEnum.idle ? null : botStatusLabel(context, b.status),
                      selected: b.id == selectedBotId,
                      onTap: () => context.go('/bots/${b.id}/chat'),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appColors.hairline),
            const SizedBox(height: 6),
            for (var i = 0; i < dests.length; i++)
              if (dests[i].path != '/bots')
                _SidebarItem(
                  key: Key('sidebar-nav-${dests[i].path}'),
                  leading: Icon(i == index ? dests[i].selectedIcon : dests[i].icon, size: 21, color: i == index ? scheme.primary : scheme.onSurfaceVariant),
                  label: dests[i].label,
                  subtitle: dests[i].path == '/settings' ? ref.watch(backendProvider).userEmail : null,
                  selected: i == index,
                  trailing: dests[i].path == '/inbox' && badge > 0 ? _CountPill(badge) : null,
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
                              style: tt.bodyLarge?.copyWith(
                                color: selected ? scheme.primary : scheme.onSurface,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                height: 1.2,
                              ),
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

class _CountPill extends StatelessWidget {
  const _CountPill(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: context.colorScheme.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onPrimary, fontWeight: FontWeight.w800, fontFeatures: AppText.tabular),
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

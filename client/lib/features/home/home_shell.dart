import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../bots/bots_screen.dart';
import '../computer/computer_screen.dart';

/// Breakpoints: phone < 700 (bottom navigation), tablet < 1200 (rail), desktop (three panes).
enum LayoutSize { phone, tablet, desktop }

LayoutSize layoutFor(double width) => width < 700 ? LayoutSize.phone : (width < 1200 ? LayoutSize.tablet : LayoutSize.desktop);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/computer')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  String? get _botId => RegExp(r'^/bots/([^/]+)').firstMatch(location)?.group(1);

  void _go(BuildContext context, int i) => context.go(const ['/bots', '/computer', '/settings'][i]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final size = layoutFor(MediaQuery.sizeOf(context).width);
    final destinations = [
      (Icons.smart_toy_outlined, Icons.smart_toy, l10n.navBots),
      (Icons.computer_outlined, Icons.computer, l10n.navComputer),
      (Icons.settings_outlined, Icons.settings, l10n.navSettings),
    ];

    if (size == LayoutSize.phone) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _go(context, i),
          destinations: [for (final d in destinations) NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3)],
        ),
      );
    }

    final rail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: (i) => _go(context, i),
      labelType: NavigationRailLabelType.all,
      destinations: [for (final d in destinations) NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3))],
    );

    final inChat = _botId != null && location.contains('/chat');
    if (size == LayoutSize.desktop && _index == 0) {
      // Three panes: bots, chat, computer.
      return Scaffold(
        body: Row(children: [
          rail,
          const VerticalDivider(width: 1),
          SizedBox(
            width: 300,
            child: Column(children: [
              ListTile(
                title: Text(l10n.bots, style: Theme.of(context).textTheme.titleMedium),
                trailing: IconButton(icon: const Icon(Icons.add), tooltip: l10n.newBot, onPressed: () => showCreateBot(context, ref)),
              ),
              Expanded(child: BotsList(selectedBotId: _botId)),
            ]),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _botId == null && location == '/bots' ? Center(child: Text(l10n.selectBot)) : child),
          if (inChat) ...[
            const VerticalDivider(width: 1),
            SizedBox(width: 420, child: ComputerScreen(botId: _botId, embedded: true)),
          ],
        ]),
      );
    }

    return Scaffold(body: Row(children: [rail, const VerticalDivider(width: 1), Expanded(child: child)]));
  }
}

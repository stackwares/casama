import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'telemetry.dart';

/// Web: the browser tab names the open page ("Settings · Casama", "Memory · Ada · Casama"), so open tabs,
/// history and bookmarks can be told apart. It sits in MaterialApp's builder, above every page, and
/// rebuilds its [Title] on every navigation, pushes and pops included. Elsewhere it does nothing: the app's
/// own title stays (on Android that is the app's name in Recents).
class RouteTitle extends StatefulWidget {
  const RouteTitle({super.key, required this.router, required this.child, this.enabled = kIsWeb});

  final GoRouter router;
  final Widget child;

  /// On for the web only; tests turn it on.
  final bool enabled;

  @override
  State<RouteTitle> createState() => _RouteTitleState();
}

class _RouteTitleState extends State<RouteTitle> {
  Listenable? _listening;
  bool _rebuildQueued = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(RouteTitle old) {
    super.didUpdateWidget(old);
    if (old.router != widget.router || old.enabled != widget.enabled) _listen();
  }

  @override
  void dispose() {
    _listening?.removeListener(_routeChanged);
    super.dispose();
  }

  void _listen() {
    _listening?.removeListener(_routeChanged);
    _listening = widget.enabled ? Listenable.merge([widget.router.routerDelegate, widget.router.routeInformationProvider]) : null;
    _listening?.addListener(_routeChanged);
  }

  /// The router also notifies while a frame is being built (the app's first frame opens the first page),
  /// when marking this widget dirty is not allowed. Then the new title waits until that frame is done.
  void _routeChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }
    if (_rebuildQueued) return;
    _rebuildQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _rebuildQueued = false;
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final router = widget.router;
    // Nothing is matched before the first location opens, nor on the error page.
    final state = router.routerDelegate.currentConfiguration.isEmpty ? null : router.state;
    final botId = state?.pathParameters['botId'];
    return Consumer(
      builder: (context, ref, child) {
        final botName = botId == null ? null : ref.watch(botProvider(botId))?.name;
        return Title(
          key: const Key('routeTitle'),
          title: tabTitleFor(state?.fullPath, AppLocalizations.of(context), botName: botName),
          // Required and must be opaque. On the web it also becomes the page's theme-color (the
          // browser toolbar tint on phones), so it matches the page's surface, light or dark.
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 1),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// The tab title for the page whose route is [fullPath], a go_router template such as
/// "/bots/:botId/memory" (never the ids in the address). Pages without a name of their own say just the
/// app's name.
String tabTitleFor(String? fullPath, AppLocalizations l10n, {String? botName}) {
  final page = switch (fullPath) {
    '/sign-in' => l10n.signIn,
    '/onboarding' => l10n.createWorkspace,
    '/two-step' => l10n.twoStepPromptTitle,
    '/new-password' => l10n.newPasswordTitle,
    '/join/:token' => l10n.invitedToJoin,
    '/i/:code' => l10n.referralWelcomeTitle,
    '/join-team' => l10n.yourTeamIsHere,
    '/oauth/consent/:id' => l10n.connectAiApp,
    '/import/:token' => l10n.importBot,
    '/bots' => l10n.navChats,
    '/bots/:botId/chat' => botName ?? l10n.tabTitleChat,
    '/bots/:botId/activity' => l10n.activity,
    '/bots/:botId/runs/:runId' => l10n.timelineTitle,
    '/bots/:botId/memory' => l10n.memory,
    '/bots/:botId/settings' => l10n.botProfile,
    '/bots/:botId/sharing' => l10n.sharing,
    '/bots/:botId/replays' => l10n.replays,
    '/bots/:botId/knowledge' => l10n.knowledge,
    '/bots/:botId/chat-apps' => l10n.chatApps,
    '/bots/:botId/links' => l10n.links,
    '/bots/:botId/plugins' => l10n.plugins,
    '/bots/:botId/watchers' => l10n.watchers,
    '/bots/:botId/rules' => l10n.actionRules,
    '/bots/:botId/history' => l10n.settingsHistory,
    '/bots/:botId/call' => l10n.tabTitleCall,
    '/bots/:botId/routines' => l10n.routines,
    '/bots/:botId/integrations' => l10n.integrations,
    '/quick-ask' => l10n.quickAsk,
    '/inbox' => l10n.inbox,
    '/tasks' => l10n.navTasks,
    '/projects' => l10n.projects,
    '/projects/:id' => l10n.tabTitleProject,
    '/search' => l10n.search,
    '/teach/:id' => l10n.teachDraftTitle,
    '/password-managers' => l10n.passwordManagers,
    '/calls/:id' => l10n.outCall,
    '/pages' => l10n.pages,
    '/groups/:id' => l10n.tabTitleGroupChat,
    '/approvals/:id' => l10n.approval,
    '/computer' => l10n.computerTitle,
    '/computer/live' => l10n.liveView,
    '/settings' => l10n.settings,
    // Casama Cloud runs the models (D-188), so its keys page holds only service keys.
    '/settings/keys' => Telemetry.isCloud ? l10n.serviceKeys : l10n.modelKeys,
    '/settings/appearance' => l10n.appearance,
    '/settings/appearance/customize' => l10n.customize,
    '/settings/usage' => l10n.usage,
    '/settings/invite' => l10n.inviteFriends,
    '/settings/gallery' || '/settings/gallery/:type/:id' => l10n.gallery,
    '/settings/skills' => l10n.skills,
    '/settings/skills/catalog' => l10n.skillCatalog,
    '/settings/integrations' || '/settings/integrations/:id' => l10n.appsTitle,
    '/settings/secrets' => l10n.secrets,
    '/settings/computers' => l10n.computers,
    '/settings/companion' => l10n.useThisComputer,
    '/settings/devices' => l10n.deviceConnections,
    '/settings/admin' => l10n.adminConsole,
    '/settings/billing' => l10n.billing,
    '/settings/privacy' => l10n.privacy,
    '/settings/about-you' => l10n.aboutYou,
    '/settings/two-step' => l10n.twoStepSignIn,
    '/settings/passkeys' => l10n.passkeys,
    '/settings/account' => l10n.account,
    '/settings/workspace' => l10n.workspaceSettings,
    '/settings/people' => l10n.people,
    // /welcome, /joined/:orgId and /run-routine/:ref only pass through on the way to another page.
    _ => null,
  };
  if (page == null) return l10n.appTitle;
  // A bot's other pages name the bot too: "Memory · Ada". Its chat is already titled with the name.
  final onBotPage = fullPath != '/bots/:botId/chat' && (fullPath?.startsWith('/bots/:botId/') ?? false);
  final named = onBotPage && botName != null ? l10n.tabTitleBotPage(page, botName) : page;
  return l10n.tabTitle(named, l10n.appTitle);
}

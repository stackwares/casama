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
    '/setup' => defaultTargetPlatform == TargetPlatform.macOS ? l10n.setupTitleMac : l10n.setupTitle,
    '/onboarding' => l10n.createWorkspace,
    '/two-step' => l10n.twoStepPromptTitle,
    '/new-password' => l10n.newPasswordTitle,
    '/join/:token' => l10n.invitedToJoin,
    '/i/:code' => l10n.referralWelcomeTitle,
    '/join-team' => l10n.yourTeamIsHere,
    '/pair' => l10n.signIn,
    '/link' => l10n.linkServerTitle,
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
    '/suggestions/:id/accept' => l10n.inbox,
    '/runs/:id/stop' => l10n.islandStop,
    '/tasks' => l10n.navTasks,
    '/projects' => l10n.projects,
    '/projects/:id' => l10n.tabTitleProject,
    '/search' => l10n.search,
    '/teach/:id' => l10n.teachDraftTitle,
    '/password-managers' => l10n.passwordManagers,
    '/calls/:id' => l10n.outCall,
    '/pages' => l10n.pages,
    '/library' => l10n.library,
    '/library/:id' => l10n.library,
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
    '/settings/widgets' => l10n.widgetsTitle,
    '/settings/watch' => l10n.watchPhoneTitle,
    '/settings/invite' => l10n.inviteFriends,
    '/settings/gallery' || '/settings/gallery/:type/:id' => l10n.gallery,
    '/settings/gallery/author/:handle' => l10n.gallery,
    '/settings/gallery/requests' || '/settings/gallery/requests/new' => l10n.galleryRequestsTitle,
    '/settings/gallery/submissions' => l10n.gallerySubmissionsTitle,
    '/settings/gallery/installed' => l10n.galleryTabInstalled,
    '/settings/workspace-gallery' => l10n.galleryPolicyTitle,
    '/settings/gallery/packs' || '/settings/gallery/packs/:id' => l10n.packsInstalledTitle,
    '/settings/gallery/packs/add' || '/settings/gallery/packs/share/:token' => l10n.packsShelfTitle,
    '/settings/share-pack' => l10n.sharePackTitle,
    '/settings/skills' => l10n.skills,
    '/settings/skills/catalog' => l10n.skillCatalog,
    '/settings/integrations' || '/settings/integrations/:id' => l10n.appsTitle,
    '/settings/secrets' => l10n.secrets,
    '/settings/domains' || '/settings/domains/:id' => l10n.settingsDomains,
    '/settings/domains/connect' => l10n.domainsConnectOwn,
    '/settings/domains/find' => l10n.domainsFind,
    '/settings/domains/contact' => l10n.domainContactTitle,
    '/settings/domains/orders/:orderId' => l10n.domainOrderTitle,
    '/settings/domains/:id/records' => l10n.domainDnsRecords,
    '/settings/computers' => l10n.computers,
    '/settings/companion' => l10n.useThisComputer,
    '/settings/devices' => l10n.deviceConnections,
    '/settings/permissions' || '/permissions' => l10n.permissionsScreenTitle,
    '/settings/admin' => l10n.adminConsole,
    '/settings/billing' => l10n.billing,
    '/settings/privacy' => l10n.privacy,
    '/settings/support' => l10n.helpAndSupport,
    '/settings/blocked' => l10n.blockedPeople,
    '/settings/support/chat' => l10n.casamaHelp,
    '/settings/about-you' => l10n.aboutYou,
    '/settings/two-step' => l10n.twoStepSignIn,
    '/settings/passkeys' => l10n.passkeys,
    '/settings/app-lock' => l10n.appLock,
    '/settings/link' => l10n.casamaLink,
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

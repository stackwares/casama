import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'backend.dart' show PackFrom;
import 'widgets.dart';

import '../features/bots/bot_history_screen.dart';
import '../features/whats_new/whats_new.dart';
import '../features/bots/bot_profile_screen.dart';
import '../features/bots/bot_template.dart';
import '../features/mcp/mcp_screens.dart';
import '../features/bots/action_rules_screen.dart';
import '../features/bots/channels_screen.dart';
import '../features/bots/links_screen.dart';
import '../features/calls/outbound_call_screen.dart';
import '../features/bots/knowledge_screen.dart';
import '../features/bots/plugins_screen.dart';
import '../features/bots/replays_screen.dart';
import '../features/bots/sharing_screen.dart';
import '../features/bots/watchers_screen.dart';
import '../features/search/search_view.dart';
import '../features/groups/group_chats.dart';
import '../features/library/creation_detail.dart';
import '../features/settings/fold_screen.dart';
import '../ui/outside_shell.dart';
import '../ui/shell_layout.dart';
import 'app_page.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/selfhost/guided_setup.dart';
import '../features/selfhost/local_server.dart';
import '../features/selfhost/setup_screen.dart';
import '../features/settings/about_you_screen.dart';
import '../features/settings/password_managers_screen.dart';
import '../features/teach/teach_draft_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/routines/run_routine_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/link/link_screen.dart';
import '../features/link/link_server_screen.dart';
import '../features/link/pairing.dart';
import '../features/chat/chat_screen.dart';
import '../features/computer/computer_screen.dart';
import '../features/computer/computers_screen.dart';
import '../features/computer/live_view_screen.dart';
import '../features/home/home_shell.dart';
import '../features/inbox/accept_suggestion_screen.dart';
import '../features/island/stop_run_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/integrations/integration_detail_screen.dart';
import '../features/integrations/integrations_screen.dart';
import '../features/routines/routines_screen.dart';
import '../features/settings/secrets_screen.dart';
import '../features/sites/connect_domain_screen.dart';
import '../features/sites/domain_buying.dart';
import '../features/sites/domain_records_screen.dart';
import '../features/sites/domain_screen.dart';
import '../features/sites/find_domain_screen.dart';
import '../features/sites/domains_screen.dart';
import '../features/memory/memory_screen.dart';
import '../features/settings/model_keys_screen.dart';
import '../features/settings/gallery_screen.dart';
import '../features/packs/installed_packs_screen.dart';
import '../features/packs/pack_preview_screen.dart';
import '../features/packs/share_pack_screen.dart';
import '../features/gallery/gallery_author.dart';
import '../features/gallery/gallery_requests.dart';
import '../features/gallery/gallery_submit.dart';
import '../features/settings/appearance_screen.dart';
import '../features/settings/customize_screen.dart';
import '../features/usage/usage_screen.dart';
import '../features/skills/skill_catalog_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/moderation/report_sheet.dart';
import '../features/companion/companion_screen.dart';
import '../features/quick_ask/quick_ask_screen.dart';
import '../features/voice/call_screen.dart';
import '../features/workspaces/onboarding_screen.dart';
import '../features/auth/account_screen.dart';
import '../features/auth/passkeys_screen.dart';
import '../features/app_lock/app_lock_screen.dart';
import '../features/widgets/widgets_screen.dart';
import '../features/watch/watch_screen.dart';
import '../features/auth/two_step_screen.dart';
import '../features/board/board_screen.dart';
import '../features/workspaces/join_flow.dart';
import '../features/workspaces/people_screen.dart';
import '../features/referrals/invite_friends.dart';
import '../features/workspaces/spaces.dart';
import '../features/workspaces/gallery_policy_screen.dart';
import 'open_links.dart';
import 'providers.dart';
import '../theme/page_transitions.dart';
import 'telemetry.dart';
import '../features/devices/device_connections_screen.dart';
import '../features/permissions/permissions_screen.dart';

/// The page's screen name for analytics (PostHog's `$screen`): its route as a template, such as
/// /bots/:botId/chat, never the ids in its address. A nested route's own path is relative ("keys" for
/// /settings/keys), and [GoRouterState.fullPath] is the template of the page on top, the same for every
/// page under it, so this keeps as many of its segments as this page's own address has: on
/// `/bots/<id>/chat` the tab underneath is "/bots".
String _screenName(GoRouterState state) {
  final depth = state.matchedLocation.split('/').where((s) => s.isNotEmpty).length;
  final template = (state.fullPath ?? '').split('/').where((s) => s.isNotEmpty);
  return '/${template.take(depth).join('/')}';
}

/// Every route is a [MaterialPage], so pages move the way the theme's page transitions say for
/// each platform, over the wallpaper the app paints behind every navigator. (go_router's own
/// fallback here is a page with no transition at all.)
GoRouterPageBuilder _page(
  Widget Function(BuildContext context, GoRouterState state) build,
) =>
    (context, state) => AppPage<void>(
      key: state.pageKey,
      name: state.name ?? _screenName(state),
      arguments: state.extra,
      child: build(context, state),
    );

/// A [_page] outside the app shell (sign-in, the welcome steps, a join link): it fills the window, so
/// it keeps clear of a folding phone's side strip and fold by itself (D-411).
GoRouterPageBuilder _outside(
  Widget Function(BuildContext context, GoRouterState state) build,
) => _page((context, state) => OutsideShell(child: build(context, state)));

/// A [_page] that is a list other pages open from (Settings): with two panes the shell shows it
/// on the left and the page opened from it has nothing of its own to go back to (D-411).
GoRouterPageBuilder _listPage(
  Widget Function(BuildContext context, GoRouterState state) build,
) =>
    (context, state) => _ListPage<void>(
      key: state.pageKey,
      name: state.name ?? _screenName(state),
      arguments: state.extra,
      child: build(context, state),
    );

class _ListPage<T> extends AppPage<T> implements ListRootPage {
  const _ListPage({required super.child, super.key, super.name, super.arguments});
}

class _TabPage<T> extends CustomTransitionPage<T> implements ListRootPage {
  const _TabPage({
    required super.child,
    required super.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.transitionDuration,
    super.reverseTransitionDuration,
  });
}

/// The web and desktop are click and open: pages and tabs switch there with no transition.
bool _switchesInstantly(BuildContext context) =>
    kIsWeb || const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(Theme.of(context).platform);

/// The tab pages (Chats, Inbox, Tasks). Like every page they are see-through over the one
/// wallpaper, which stays still while tabs switch. They fade through each other: the tab you leave
/// is gone before the one you open appears, so the two lists never show on top of each other.
/// Pages opened from a tab (a chat, settings) use the theme's page transitions; the tab under them
/// moves aside the same way a page would (the theme's delegated transition).
GoRouterPageBuilder _tab(
  Widget Function(BuildContext context, GoRouterState state) build,
) => (context, state) {
  final duration = MediaQuery.disableAnimationsOf(context) || _switchesInstantly(context)
      ? Duration.zero
      : tabSwitchDuration;
  return _TabPage<void>(
    key: state.pageKey,
    name: state.name ?? _screenName(state),
    arguments: state.extra,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (_, animation, secondaryAnimation, child) => fadeThrough(animation, secondaryAnimation, child),
    child: build(context, state),
  );
};

/// Re-evaluates redirects when sign-in or workspace state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(signedInProvider, (_, _) => notifyListeners());
    ref.listen(newPasswordNeededProvider, (_, _) => notifyListeners());
    ref.listen(organizationsProvider, (_, _) => notifyListeners());
    ref.listen(joinableWorkspacesProvider, (_, _) => notifyListeners());
    ref.listen(pendingReferralProvider, (_, _) => notifyListeners());
    GuidedSetup.active.addListener(notifyListeners);
  }

  @override
  void dispose() {
    GuidedSetup.active.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Routes, including the deep links push notifications use (/bots/:id/chat, /approvals/:id).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  // The last casama.ai/open link (D-326), so one opened while signed out is where sign-in ends.
  String? lastOpened;
  final router = GoRouter(
    // A link kept through a sign-in that reloaded the web app or restarted the app (D-326).
    initialLocation: ref.read(pendingOpenLinkProvider.notifier).fresh ?? '/bots',
    observers: Telemetry.observers,
    refreshListenable: refresh,
    redirect: (context, state) {
      // casama.ai/open/<route> (D-326): the route is the rest of the path. First, since no route
      // matches /open/… itself.
      final opened = openLinkTarget(state.uri);
      if (opened != null) return lastOpened = opened;
      final signedIn = ref.read(signedInProvider);
      if (signedIn.isLoading) return null;
      final loc = state.matchedLocation;
      // Where to go once signed in: a link opened while signed out (D-326), else the bots.
      final pendingOpen = ref.read(pendingOpenLinkProvider.notifier).fresh;
      String afterSignIn() => pendingOpen ?? '/bots';
      // Invite links (D-167): the preview works signed out ("Sign in to join" keeps the invite and
      // brings people back to it after signing in).
      // A friend's invite link (D-211) works signed out the same way.
      final joining = loc.startsWith('/join/') || loc.startsWith('/invites/') || loc.startsWith('/i/');
      // A scanned sign-in code (D-296) works signed out (that is its point) and signed in.
      if (loc == '/pair') return null;
      // Guided setup of a server on this computer (D-309): signed out for its first steps, signed
      // in for the rest. While it is under way, launches open it again at the step it reached.
      final settingUp = localServerSupported && GuidedSetup.active.value;
      if (loc == '/setup' && !localServerSupported) return '/sign-in';
      if (signedIn.value != true) {
        if (loc == '/setup') return null;
        if (settingUp && !joining) return '/setup';
        // A server's link code (D-296) is approved by someone signed in: keep it through sign-in.
        if (loc == '/link') {
          final code = state.uri.queryParameters['code'];
          if (code != null && code.isNotEmpty) {
            Future.microtask(() => ref.read(pendingLinkCodeProvider.notifier).set(code));
          }
        }
        if (loc == '/sign-in' || joining) return null;
        final target = state.uri.toString();
        if (target == lastOpened && keepThroughSignIn(target)) {
          lastOpened = null;
          Future.microtask(() => ref.read(pendingOpenLinkProvider.notifier).set(target));
        }
        return '/sign-in';
      }
      final pendingJoin = ref.read(pendingJoinTokenProvider);
      if (pendingJoin != null && !loc.startsWith('/join/')) {
        return joinPath(pendingJoin);
      }
      // Two-step sign-in (D-093): the code comes before anything else.
      final codeNeeded = ref.read(backendProvider).twoStepCodeNeeded;
      if (codeNeeded) return loc == '/two-step' ? null : '/two-step';
      if (loc == '/two-step') return afterSignIn();
      // Back from a reset link or code: a new password before anything else.
      if (ref.read(backendProvider).newPasswordNeeded) {
        return loc == '/new-password' ? null : '/new-password';
      }
      if (loc == '/new-password') return afterSignIn();
      // A friend's invite code kept through sign-up (D-211): ask about it once signed in.
      final pendingReferral = ref.read(pendingReferralProvider);
      if (pendingReferral != null && !loc.startsWith('/i/')) {
        return referralPath(pendingReferral);
      }
      if (joining || loc.startsWith('/joined/')) return null;
      if (loc == '/setup') return null;
      if (settingUp) return '/setup';
      final orgs = ref.read(organizationsProvider);
      if (orgs.isLoading) return loc == '/sign-in' ? afterSignIn() : null;
      // Workspaces that couldn't load (offline with none saved) don't mean there are none: never
      // start the welcome flow, which would make a new one, over a failed request (D-158). An
      // error can carry an earlier empty list (from before sign-in finished), so look at the list.
      if (orgs.hasError && (orgs.value ?? const []).isEmpty) {
        return loc == '/sign-in' ? afterSignIn() : null;
      }
      final hasOrg = (orgs.value ?? const []).isNotEmpty;
      final bots = ref.read(botsProvider).value;
      // New people get a space and bot and land in its empty chat (D-263); the wizard stays at
      // /onboarding. Those whose team already has a workspace open to their email domain see it
      // first (D-167).
      if (!hasOrg &&
          loc != '/onboarding' &&
          loc != '/welcome' &&
          loc != '/join-team') {
        final joinable = ref.read(joinableWorkspacesProvider);
        if (joinable.isLoading) return null;
        if ((joinable.value ?? const []).isNotEmpty &&
            !ref.read(skipJoinTeamProvider)) {
          return '/join-team';
        }
        return '/welcome';
      }
      if (hasOrg && loc == '/join-team') return '/bots';
      if (hasOrg && loc == '/onboarding' && (bots?.isNotEmpty ?? false)) {
        return '/bots';
      }
      // Back to the server waiting to be linked, once there is a workspace to link it to.
      final pendingLink = ref.read(pendingLinkCodeProvider);
      if (pendingLink != null && hasOrg && loc != '/link') {
        return Uri(path: '/link', queryParameters: {'code': pendingLink}).toString();
      }
      if (loc == '/sign-in') return hasOrg ? afterSignIn() : '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        pageBuilder: _outside((_, _) => const SignInScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: _outside((_, _) => const OnboardingScreen()),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: _outside((_, _) => const SetupScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: _outside((_, _) => const WelcomeScreen()),
      ),
      GoRoute(
        path: '/two-step',
        pageBuilder: _outside((_, _) => const TwoStepPromptScreen()),
      ),
      GoRoute(
        path: '/new-password',
        pageBuilder: _outside((_, _) => const NewPasswordScreen()),
      ),
      GoRoute(
        path: '/join/:token',
        pageBuilder: _outside(
          (_, s) => JoinScreen(
            key: ValueKey(s.uri.toString()),
            invite: s.pathParameters['token']!,
            server: s.uri.queryParameters['server'],
          ),
        ),
      ),
      // Email invites sent before D-167 point at /invites/<token>.
      GoRoute(
        path: '/invites/:token',
        redirect: (_, s) => joinPath(s.pathParameters['token']!),
      ),
      GoRoute(
        path: '/i/:code',
        pageBuilder: _outside(
          (_, s) => InviteLinkScreen(
            key: ValueKey(s.pathParameters['code']),
            code: s.pathParameters['code']!,
          ),
        ),
      ),
      // A sign-in QR code read by the phone's camera (D-296): casama.ai/pair#v=1&s=…&c=…
      GoRoute(
        path: '/pair',
        pageBuilder: _outside(
          (context, s) => PairLandingScreen(
            key: ValueKey(s.uri.toString()),
            link: PairLink.fromValues({
              ...s.uri.queryParameters,
              if (s.uri.fragment.isNotEmpty) ...Uri.splitQueryString(s.uri.fragment),
            }),
            onDone: () => context.go('/bots'),
          ),
        ),
      ),
      // Where a self-hosted server sends its owner to approve its link code (D-296).
      GoRoute(
        path: '/link',
        pageBuilder: _outside(
          (_, s) => LinkServerScreen(
            key: ValueKey(s.uri.toString()),
            code: s.uri.queryParameters['code'],
          ),
        ),
      ),
      // Gallery links (D-315; casama://app/gallery/...): the requests board, a new request with its
      // title filled in, and the Installed tab, ahead of /gallery/:type/:id, which would read them as
      // an item ("requests" / "new").
      GoRoute(
        path: '/gallery/requests',
        redirect: (_, s) => '/settings/gallery/requests',
      ),
      GoRoute(
        path: '/gallery/requests/new',
        redirect: (_, s) => Uri(
          path: '/settings/gallery/requests/new',
          queryParameters: s.uri.queryParameters.isEmpty ? null : s.uri.queryParameters,
        ).toString(),
      ),
      GoRoute(
        path: '/gallery/installed',
        redirect: (_, s) => '/settings/gallery/installed',
      ),
      // Pack links (docs/PLUGINS-AND-PACKS-PLAN.md B.8, E.31): casama.ai/open/pack?url=<GitHub link>
      // and a shared pack's <app>/packs/share/<token> open the pack's preview.
      GoRoute(
        path: '/pack',
        redirect: (_, s) => Uri(
          path: '/settings/gallery/packs/add',
          queryParameters: s.uri.queryParameters.isEmpty ? null : s.uri.queryParameters,
        ).toString(),
      ),
      GoRoute(
        path: '/packs/share/:token',
        redirect: (_, s) => packShareLocation(s.pathParameters['token']!),
      ),
      // Older servers' notification links: the gallery and your submissions (no screens of their own).
      GoRoute(path: '/gallery', redirect: (_, _) => '/settings/gallery'),
      GoRoute(
        path: '/gallery/submissions',
        redirect: (_, _) => '/settings/gallery/submissions',
      ),
      GoRoute(
        path: '/gallery/:type/:id',
        redirect: (_, s) =>
            '/settings/gallery/${s.pathParameters['type']}/${s.pathParameters['id']}',
      ),
      GoRoute(
        path: '/joined/:orgId',
        pageBuilder: _outside(
          (_, s) => JoinedScreen(orgId: s.pathParameters['orgId']!),
        ),
      ),
      GoRoute(
        path: '/join-team',
        pageBuilder: _outside((_, _) => const JoinTeamScreen()),
      ),
      GoRoute(
        path: '/oauth/consent/:id',
        pageBuilder: _outside(
          (_, s) => McpConsentScreen(requestId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/import/:token',
        pageBuilder: _outside(
          (_, s) => ImportBotScreen(token: s.pathParameters['token']!),
        ),
      ),
      ShellRoute(
        observers: Telemetry.observers,
        pageBuilder: (context, state, child) => MaterialPage(
          key: state.pageKey,
          child: PasskeySuggestion(
            child: WhatsNewGate(
              child: HomeShell(location: state.uri.path, uri: state.uri, child: child),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: '/bots',
            // The list on a phone; nothing where the shell lists the chats itself (D-383, D-411).
            pageBuilder: _tab((_, _) => const ChatsTabPage()),
            routes: [
              GoRoute(
                path: ':botId/chat',
                pageBuilder: _page(
                  (_, s) => ChatScreen(
                    botId: s.pathParameters['botId']!,
                    conversationId: s.uri.queryParameters['c'],
                    focusMessageId: s.uri.queryParameters['m'],
                    draft: s.uri.queryParameters['draft'],
                  ),
                ),
              ),
              GoRoute(
                path: ':botId/activity',
                pageBuilder: _page(
                  (_, s) => ActivityScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/runs/:runId',
                pageBuilder: _page(
                  (_, s) => RunTimelineScreen(
                    botId: s.pathParameters['botId']!,
                    runId: s.pathParameters['runId']!,
                  ),
                ),
              ),
              GoRoute(
                path: ':botId/memory',
                pageBuilder: _page(
                  (_, s) => MemoryScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/settings',
                pageBuilder: _page(
                  (_, s) => BotProfileScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/sharing',
                pageBuilder: _page(
                  (_, s) => SharingScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/replays',
                pageBuilder: _page(
                  (_, s) => ReplaysScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/knowledge',
                pageBuilder: _page(
                  (_, s) => KnowledgeScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/chat-apps',
                pageBuilder: _page(
                  (_, s) => ChannelsScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/links',
                pageBuilder: _page(
                  (_, s) => LinksScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/plugins',
                pageBuilder: _page(
                  (_, s) => PluginsScreen(botId: s.pathParameters['botId']!, install: s.uri.queryParameters['install']),
                ),
              ),
              GoRoute(
                path: ':botId/watchers',
                pageBuilder: _page(
                  (_, s) => WatchersScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/rules',
                pageBuilder: _page(
                  (_, s) =>
                      ActionRulesScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/history',
                pageBuilder: _page(
                  (_, s) => BotHistoryScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/call',
                pageBuilder: _page(
                  (_, s) => CallScreen(
                    botId: s.pathParameters['botId']!,
                    conversationId: s.uri.queryParameters['c'],
                    callId: s.uri.queryParameters['call'],
                  ),
                ),
              ),
              GoRoute(
                path: ':botId/routines',
                pageBuilder: _page(
                  (_, s) => RoutinesScreen(botId: s.pathParameters['botId']!),
                ),
              ),
              GoRoute(
                path: ':botId/integrations',
                pageBuilder: _page(
                  (_, s) =>
                      BotIntegrationsScreen(botId: s.pathParameters['botId']!),
                ),
              ),
            ],
          ),
          // Back from a sign-in email, Google, Apple or SSO (casama://app/login-callback): Supabase
          // takes the session from the link; once signed in this just goes home.
          GoRoute(path: '/login-callback', redirect: (_, _) => '/bots'),
          GoRoute(
            path: '/quick-ask',
            pageBuilder: _page(
              (_, s) => QuickAskScreen(
                key: ValueKey(s.uri.toString()),
                initialText: s.uri.queryParameters['text'] ?? '',
                fromShareExtension: s.uri.queryParameters['shared'] == '1',
                initialBotId: s.uri.queryParameters['bot'],
              ),
            ),
          ),
          // "Do it" on a suggestion's notification (D-247): casama://app/suggestions/{id}/accept?bot={botId}.
          GoRoute(
            path: '/suggestions/:id/accept',
            pageBuilder: _page(
              (_, s) => AcceptSuggestionScreen(
                key: ValueKey(s.uri.toString()),
                suggestionId: s.pathParameters['id']!,
                botId: s.uri.queryParameters['bot'],
              ),
            ),
          ),
          // Stop on an iPhone Live Activity (D-324): casama://app/runs/{id}/stop stops the run and
          // lands on its chat.
          GoRoute(
            path: '/runs/:id/stop',
            pageBuilder: _page(
              (_, s) => StopRunScreen(
                key: ValueKey(s.uri.toString()),
                runId: s.pathParameters['id']!,
              ),
            ),
          ),
          // A notification from a permissions card tapped on another device (D-376):
          // ?device=<ref>&ask=<permission>&do=<action> runs the ask here when it's this device.
          GoRoute(
            path: '/permissions',
            pageBuilder: _page(
              (_, s) => DevicePermissionsScreen(
                key: ValueKey(s.uri.toString()),
                device: s.uri.queryParameters['device'],
                ask: s.uri.queryParameters['ask'],
                action: s.uri.queryParameters['do'],
              ),
            ),
          ),
          // Opened from Chats (D-253): ?tab=0 is Needs you, otherwise the Casama updates feed.
          GoRoute(
            path: '/inbox',
            pageBuilder: _page(
              (context, s) => InboxScreen(
                key: ValueKey(s.uri.toString()),
                initialFilter: InboxFilter.fromTab(
                  s.uri.queryParameters['tab'],
                ),
                title: s.uri.queryParameters['tab'] == '0'
                    ? context.l10n.inboxNeedsYou
                    : context.l10n.updatesRow,
              ),
            ),
          ),
          // The Library (D-274): everything bots made. ?kind=, ?bot= and ?q= filter it.
          GoRoute(
            path: '/library',
            pageBuilder: _tab((_, s) => LibraryTabPage(uri: s.uri)),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: _page(
                  (_, s) => CreationDetailScreen(creationId: s.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: _tab((_, _) => const BoardScreen()),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: _page((_, _) => const ProjectsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: _page(
                  (_, s) => ProjectScreen(projectId: s.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            pageBuilder: _page((_, _) => const SearchScreen()),
          ),
          GoRoute(
            path: '/teach/:id',
            pageBuilder: _page(
              (_, s) => TeachDraftScreen(sessionId: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/password-managers',
            pageBuilder: _page((_, _) => const PasswordManagersScreen()),
          ),
          GoRoute(
            path: '/calls/:id',
            pageBuilder: _page(
              (_, s) => OutboundCallScreen(callId: s.pathParameters['id']!),
            ),
          ),
          // Pages became part of the Library (LIBRARY-PLAN §5.1): old links land on its Sites filter.
          GoRoute(
            path: '/pages',
            redirect: (_, s) => Uri(
              path: '/library',
              queryParameters: {
                'kind': 'page',
                'bot': ?s.uri.queryParameters['bot'],
              },
            ).toString(),
          ),
          GoRoute(
            path: '/groups/:id',
            pageBuilder: _page(
              (_, s) =>
                  GroupChatScreen(conversationId: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/run-routine/:ref',
            pageBuilder: _page(
              (_, s) => RunRoutineScreen(reference: s.pathParameters['ref']!),
            ),
          ),
          GoRoute(
            path: '/approvals/:id',
            pageBuilder: _page(
              (_, s) => ApprovalScreen(approvalId: s.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/computer',
            // ?bot= opens that bot's computer (from its chat or profile); ?c= one computer, and
            // ?tab=manage its Manage tab (D-240).
            pageBuilder: _page(
              (_, s) => ComputerScreen(
                botId: s.uri.queryParameters['bot'],
                computerId: s.uri.queryParameters['c'],
                initialTab: s.uri.queryParameters['tab'],
                initialPath: s.uri.queryParameters['path'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'live',
                pageBuilder: _page(
                  (_, s) => LiveViewScreen(
                    computerId: s.uri.queryParameters['c'] ?? '',
                    takeoverId: s.uri.queryParameters['takeover'],
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: _listPage((_, _) => const SettingsRootPage()),
            routes: [
              GoRoute(
                path: 'keys',
                pageBuilder: _page(
                  (_, s) => ModelKeysScreen(
                    provider: s.uri.queryParameters['provider'],
                  ),
                ),
              ),
              // Everything about how the app looks is Appearance and its Customize page; the
              // older addresses for themes, colors, fonts and background still lead there.
              GoRoute(
                path: 'appearance',
                pageBuilder: _page((_, _) => const AppearanceScreen()),
                routes: [
                  GoRoute(
                    path: 'customize',
                    pageBuilder: _page(
                      (_, s) => CustomizeScreen(
                        initial: LookPart.named(s.uri.queryParameters['tab']),
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'themes',
                redirect: (_, _) => '/settings/appearance',
              ),
              GoRoute(
                path: 'theme',
                redirect: (_, _) => '/settings/appearance/customize?tab=colors',
              ),
              GoRoute(
                path: 'fonts',
                redirect: (_, _) => '/settings/appearance/customize?tab=fonts',
              ),
              GoRoute(
                path: 'background',
                redirect: (_, _) =>
                    '/settings/appearance/customize?tab=background',
              ),
              GoRoute(
                path: 'usage',
                pageBuilder: _page((_, _) => const UsageScreen()),
              ),
              GoRoute(
                path: 'gallery',
                pageBuilder: _page(
                  (_, s) =>
                      GalleryScreen(initialType: s.uri.queryParameters['type']),
                ),
                routes: [
                  // Before ':type/:id', which would read these as an item.
                  GoRoute(
                    path: 'requests',
                    pageBuilder: _page((_, _) => const GalleryRequestsScreen()),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: _page(
                          (_, s) => GalleryRequestsScreen(
                            key: ValueKey(s.uri.toString()),
                            openNew: true,
                            newTitle: s.uri.queryParameters['title'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'submissions',
                    pageBuilder: _page((_, _) => const GallerySubmissionsScreen()),
                  ),
                  GoRoute(
                    path: 'installed',
                    pageBuilder: _page((_, _) => const GalleryScreen(installed: true)),
                  ),
                  // Packs, before ':type/:id', which would read these as an item.
                  GoRoute(
                    path: 'packs',
                    pageBuilder: _page((_, _) => const InstalledPacksScreen()),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: _page(
                          (_, s) => PackPreviewScreen(
                            key: ValueKey(s.uri.toString()),
                            from: switch (s.extra) {
                              final PackFrom from => from,
                              _ => PackFrom(
                                url: s.uri.queryParameters['url'],
                                commit: s.uri.queryParameters['commit'],
                                galleryId: s.uri.queryParameters['gallery_id'],
                              ),
                            },
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'share/:token',
                        pageBuilder: _page(
                          (_, s) => PackPreviewScreen(
                            key: ValueKey(s.uri.toString()),
                            from: PackFrom(shareToken: s.pathParameters['token']),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        pageBuilder: _page((_, s) => InstalledPackScreen(id: s.pathParameters['id']!)),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'author/:handle',
                    pageBuilder: _page(
                      (_, s) => GalleryAuthorScreen(handle: s.pathParameters['handle']!),
                    ),
                  ),
                  GoRoute(
                    path: ':type/:id',
                    pageBuilder: _page(
                      (_, s) => GalleryScreen(
                        openType: s.pathParameters['type'],
                        openId: s.pathParameters['id'],
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'skills',
                pageBuilder: _page((_, _) => const SkillsScreen()),
                routes: [
                  GoRoute(
                    path: 'catalog',
                    pageBuilder: _page((_, _) => const SkillCatalogScreen()),
                  ),
                ],
              ),
              GoRoute(
                path: 'integrations',
                pageBuilder: _page((_, _) => const IntegrationsScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: _page(
                      (_, s) => IntegrationDetailScreen(
                        integrationId: s.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'secrets',
                pageBuilder: _page((_, _) => const SecretsScreen()),
              ),
              // Domains (SITES-AND-DOMAINS-PLAN §7.16); notifications link to /settings/domains/<id>.
              GoRoute(
                path: 'domains',
                pageBuilder: _page((_, _) => const DomainsScreen()),
                routes: [
                  // Before ':id', which would read it as a domain.
                  GoRoute(
                    path: 'connect',
                    pageBuilder: _page(
                      (_, s) => ConnectDomainScreen(
                        pageId: s.uri.queryParameters['page_id'],
                      ),
                    ),
                  ),
                  // Bots link to find?q=<name> with the name filled in (§7.16).
                  GoRoute(
                    path: 'find',
                    pageBuilder: _page(
                      (_, s) =>
                          FindDomainScreen(query: s.uri.queryParameters['q']),
                    ),
                  ),
                  GoRoute(
                    path: 'contact',
                    pageBuilder: _page((_, _) => const DomainContactScreen()),
                  ),
                  GoRoute(
                    path: 'orders/:orderId',
                    pageBuilder: _page(
                      (_, s) => DomainOrderScreen(
                        key: ValueKey(s.pathParameters['orderId']),
                        orderId: s.pathParameters['orderId']!,
                        paying: s.uri.queryParameters['paying'] == '1',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: _page(
                      (_, s) => DomainScreen(
                        key: ValueKey(s.pathParameters['id']),
                        domainId: s.pathParameters['id']!,
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'records',
                        pageBuilder: _page(
                          (_, s) => DomainRecordsScreen(
                            domainId: s.pathParameters['id']!,
                            domainName: s.uri.queryParameters['name'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'computers',
                pageBuilder: _page((_, _) => const ComputersScreen()),
              ),
              GoRoute(
                path: 'companion',
                pageBuilder: _page((_, _) => const CompanionScreen()),
              ),
              GoRoute(
                path: 'devices',
                pageBuilder: _page((_, _) => const DeviceConnectionsScreen()),
              ),
              // System permissions on this device (D-376).
              GoRoute(
                path: 'permissions',
                pageBuilder: _page((_, _) => const DevicePermissionsScreen()),
              ),
              // A folding phone's screens as Casama sees them (D-411).
              GoRoute(
                path: 'fold',
                pageBuilder: _page((_, _) => const FoldScreen()),
              ),
              GoRoute(
                path: 'admin',
                pageBuilder: _page((_, s) => AdminScreen(tab: s.uri.queryParameters['tab'])),
                routes: [
                  // Older servers' domain-approval notifications.
                  GoRoute(path: 'domains', redirect: (_, _) => '/settings/admin?tab=domains'),
                ],
              ),
              GoRoute(
                path: 'billing',
                pageBuilder: _page((_, _) => const BillingScreen()),
              ),
              GoRoute(
                path: 'privacy',
                pageBuilder: _page((_, _) => const PrivacyScreen()),
              ),
              GoRoute(
                path: 'blocked',
                pageBuilder: _page((_, _) => const BlockedPeopleScreen()),
              ),
              // Help & support (D-298): Casama Help, a message to the support team, support ids.
              GoRoute(
                path: 'support',
                pageBuilder: _page((_, _) => const SupportScreen()),
                routes: [
                  GoRoute(
                    path: 'chat',
                    pageBuilder: _page((_, s) => SupportChatScreen(initial: s.uri.queryParameters['q'])),
                  ),
                ],
              ),
              GoRoute(
                path: 'about-you',
                pageBuilder: _page((_, _) => const AboutYouScreen()),
              ),
              GoRoute(
                path: 'two-step',
                pageBuilder: _page((_, _) => const TwoStepSettingsScreen()),
              ),
              GoRoute(
                path: 'passkeys',
                pageBuilder: _page((_, _) => const PasskeysScreen()),
              ),
              GoRoute(
                path: 'app-lock',
                pageBuilder: _page((_, _) => const AppLockScreen()),
              ),
              GoRoute(
                path: 'widgets',
                pageBuilder: _page((_, _) => const WidgetsScreen()),
              ),
              GoRoute(
                path: 'watch',
                pageBuilder: _page((_, _) => const WatchScreen()),
              ),
              GoRoute(
                path: 'link',
                pageBuilder: _page((_, _) => const LinkScreen()),
              ),
              GoRoute(
                path: 'account',
                pageBuilder: _page((_, _) => const AccountScreen()),
              ),
              GoRoute(
                path: 'workspace',
                pageBuilder: _page((_, _) => const WorkspaceSettingsScreen()),
              ),
              GoRoute(
                path: 'share-pack',
                pageBuilder: _page((_, s) => SharePackScreen(botId: s.uri.queryParameters['bot'])),
              ),
              GoRoute(
                path: 'workspace-gallery',
                pageBuilder: _page((_, _) => const GalleryPolicyScreen()),
              ),
              GoRoute(
                path: 'people',
                pageBuilder: _page((_, _) => const PeopleScreen()),
              ),
              GoRoute(
                path: 'invite',
                pageBuilder: _page((_, _) => const InviteFriendsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  // A link kept through sign-in (D-326) is done with once the app has landed on it and the person
  // has moved on. Not sooner: until they go somewhere themselves, redirects keep running from the
  // sign-in page and must keep ending at the link.
  void landed() {
    final pending = ref.read(pendingOpenLinkProvider.notifier);
    if (ref.read(pendingOpenLinkProvider) == null) return;
    pending.landedOn(router.routerDelegate.currentConfiguration.uri.toString());
  }
  router.routerDelegate.addListener(landed);
  ref.onDispose(() => router.routerDelegate.removeListener(landed));
  return router;
});

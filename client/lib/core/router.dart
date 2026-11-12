import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../features/pages/pages_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/settings/about_you_screen.dart';
import '../features/settings/password_managers_screen.dart';
import '../features/teach/teach_draft_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/routines/run_routine_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/bots/bots_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/computer/computer_screen.dart';
import '../features/computer/computers_screen.dart';
import '../features/computer/live_view_screen.dart';
import '../features/home/home_shell.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/integrations/integration_detail_screen.dart';
import '../features/integrations/integrations_screen.dart';
import '../features/routines/routines_screen.dart';
import '../features/settings/secrets_screen.dart';
import '../features/memory/memory_screen.dart';
import '../features/settings/model_keys_screen.dart';
import '../features/settings/gallery_screen.dart';
import '../features/settings/appearance_screen.dart';
import '../features/settings/customize_screen.dart';
import '../features/usage/usage_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/skills/skill_catalog_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/companion/companion_screen.dart';
import '../features/quick_ask/quick_ask_screen.dart';
import '../features/voice/call_screen.dart';
import '../features/workspaces/onboarding_screen.dart';
import '../features/auth/account_screen.dart';
import '../features/auth/passkeys_screen.dart';
import '../features/auth/two_step_screen.dart';
import '../features/board/board_screen.dart';
import '../features/workspaces/join_flow.dart';
import '../features/workspaces/people_screen.dart';
import '../features/referrals/invite_friends.dart';
import '../features/workspaces/spaces.dart';
import 'providers.dart';
import '../theme/page_transitions.dart';
import 'telemetry.dart';
import '../features/devices/device_connections_screen.dart';

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
    (context, state) => MaterialPage<void>(
      key: state.pageKey,
      name: state.name ?? _screenName(state),
      arguments: state.extra,
      child: build(context, state),
    );

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
  return CustomTransitionPage<void>(
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
  }
}

/// Routes, including the deep links push notifications use (/bots/:id/chat, /approvals/:id).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/bots',
    observers: Telemetry.observers,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(signedInProvider);
      if (signedIn.isLoading) return null;
      final loc = state.matchedLocation;
      // Invite links (D-167): the preview works signed out ("Sign in to join" keeps the invite and
      // brings people back to it after signing in).
      // A friend's invite link (D-211) works signed out the same way.
      final joining = loc.startsWith('/join/') || loc.startsWith('/invites/') || loc.startsWith('/i/');
      if (signedIn.value != true) {
        return loc == '/sign-in' || joining ? null : '/sign-in';
      }
      final pendingJoin = ref.read(pendingJoinTokenProvider);
      if (pendingJoin != null && !loc.startsWith('/join/')) {
        return joinPath(pendingJoin);
      }
      // Two-step sign-in (D-093): the code comes before anything else.
      final codeNeeded = ref.read(backendProvider).twoStepCodeNeeded;
      if (codeNeeded) return loc == '/two-step' ? null : '/two-step';
      if (loc == '/two-step') return '/bots';
      // Back from a reset link or code: a new password before anything else.
      if (ref.read(backendProvider).newPasswordNeeded) {
        return loc == '/new-password' ? null : '/new-password';
      }
      if (loc == '/new-password') return '/bots';
      // A friend's invite code kept through sign-up (D-211): ask about it once signed in.
      final pendingReferral = ref.read(pendingReferralProvider);
      if (pendingReferral != null && !loc.startsWith('/i/')) {
        return referralPath(pendingReferral);
      }
      if (joining || loc.startsWith('/joined/')) return null;
      final orgs = ref.read(organizationsProvider);
      if (orgs.isLoading) return loc == '/sign-in' ? '/bots' : null;
      // Workspaces that couldn't load (offline with none saved) don't mean there are none: never
      // start the welcome flow, which would make a new one, over a failed request (D-158). An
      // error can carry an earlier empty list (from before sign-in finished), so look at the list.
      if (orgs.hasError && (orgs.value ?? const []).isEmpty) {
        return loc == '/sign-in' ? '/bots' : null;
      }
      final hasOrg = (orgs.value ?? const []).isNotEmpty;
      final bots = ref.read(botsProvider).value;
      // New people land in the welcome chat (D-129); the wizard stays at /onboarding. Those whose
      // team already has a workspace open to their email domain see it first (D-167).
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
      if (loc == '/sign-in') return hasOrg ? '/bots' : '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        pageBuilder: _page((_, _) => const SignInScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: _page((_, _) => const OnboardingScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: _page((_, _) => const WelcomeScreen()),
      ),
      GoRoute(
        path: '/two-step',
        pageBuilder: _page((_, _) => const TwoStepPromptScreen()),
      ),
      GoRoute(
        path: '/new-password',
        pageBuilder: _page((_, _) => const NewPasswordScreen()),
      ),
      GoRoute(
        path: '/join/:token',
        pageBuilder: _page(
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
        pageBuilder: _page(
          (_, s) => InviteLinkScreen(
            key: ValueKey(s.pathParameters['code']),
            code: s.pathParameters['code']!,
          ),
        ),
      ),
      GoRoute(
        path: '/gallery/:type/:id',
        redirect: (_, s) =>
            '/settings/gallery/${s.pathParameters['type']}/${s.pathParameters['id']}',
      ),
      GoRoute(
        path: '/joined/:orgId',
        pageBuilder: _page(
          (_, s) => JoinedScreen(orgId: s.pathParameters['orgId']!),
        ),
      ),
      GoRoute(
        path: '/join-team',
        pageBuilder: _page((_, _) => const JoinTeamScreen()),
      ),
      GoRoute(
        path: '/oauth/consent/:id',
        pageBuilder: _page(
          (_, s) => McpConsentScreen(requestId: s.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/import/:token',
        pageBuilder: _page(
          (_, s) => ImportBotScreen(token: s.pathParameters['token']!),
        ),
      ),
      ShellRoute(
        observers: Telemetry.observers,
        pageBuilder: (context, state, child) => MaterialPage(
          key: state.pageKey,
          child: PasskeySuggestion(
            child: WhatsNewGate(
              child: HomeShell(location: state.uri.path, child: child),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: '/bots',
            pageBuilder: _tab(
              (context, _) =>
                  layoutFor(MediaQuery.sizeOf(context).width) ==
                      LayoutSize.desktop
                  ? const SizedBox.shrink()
                  : const BotsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':botId/chat',
                pageBuilder: _page(
                  (_, s) => ChatScreen(
                    botId: s.pathParameters['botId']!,
                    conversationId: s.uri.queryParameters['c'],
                    focusMessageId: s.uri.queryParameters['m'],
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
          GoRoute(
            path: '/inbox',
            pageBuilder: _tab(
              (_, s) => InboxScreen(
                initialFilter: InboxFilter.fromTab(
                  s.uri.queryParameters['tab'],
                ),
              ),
            ),
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
          GoRoute(
            path: '/pages',
            pageBuilder: _page(
              (_, s) => PagesScreen(botId: s.uri.queryParameters['bot']),
            ),
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
            pageBuilder: _page((_, _) => const SettingsScreen()),
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
              GoRoute(
                path: 'admin',
                pageBuilder: _page((_, _) => const AdminScreen()),
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
                path: 'account',
                pageBuilder: _page((_, _) => const AccountScreen()),
              ),
              GoRoute(
                path: 'workspace',
                pageBuilder: _page((_, _) => const WorkspaceSettingsScreen()),
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
});

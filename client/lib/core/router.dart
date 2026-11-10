import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/bots/bot_history_screen.dart';
import '../features/bots/bot_template.dart';
import '../features/search/search_view.dart';
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
import '../features/settings/background_screen.dart';
import '../features/settings/fonts_screen.dart';
import '../features/settings/themes_screen.dart';
import '../features/usage/usage_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/theme_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/billing/billing_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/companion/companion_screen.dart';
import '../features/quick_ask/quick_ask_screen.dart';
import '../features/voice/call_screen.dart';
import '../features/workspaces/onboarding_screen.dart';
import '../features/auth/two_step_screen.dart';
import '../features/board/board_screen.dart';
import '../features/workspaces/spaces.dart';
import 'providers.dart';
import 'telemetry.dart';

/// Every route is a [MaterialPage], so pages slide or fade the way each platform expects and the
/// theme's page transitions paint the wallpaper under each one. (go_router's own fallback here is
/// a page with no transition at all.)
GoRouterPageBuilder _page(Widget Function(BuildContext context, GoRouterState state) build) =>
    (context, state) => MaterialPage<void>(key: state.pageKey, name: state.name, arguments: state.extra, child: build(context, state));

/// Re-evaluates redirects when sign-in or workspace state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(signedInProvider, (_, _) => notifyListeners());
    ref.listen(organizationsProvider, (_, _) => notifyListeners());
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
      // An invite link opened before signing in is joined right after (D-099).
      if (signedIn.value != true && loc.startsWith('/join/')) {
        ref.read(pendingJoinTokenProvider.notifier).set(state.pathParameters['token']);
        return '/sign-in';
      }
      if (signedIn.value != true) return loc == '/sign-in' ? null : '/sign-in';
      final pendingJoin = ref.read(pendingJoinTokenProvider);
      if (pendingJoin != null && !loc.startsWith('/join/')) return '/join/$pendingJoin';
      // Two-step sign-in (D-093): the code comes before anything else.
      final codeNeeded = ref.read(backendProvider).twoStepCodeNeeded;
      if (codeNeeded) return loc == '/two-step' ? null : '/two-step';
      if (loc == '/two-step') return '/bots';
      final orgs = ref.read(organizationsProvider);
      if (orgs.isLoading) return loc == '/sign-in' ? '/bots' : null;
      final hasOrg = (orgs.value ?? const []).isNotEmpty;
      final bots = ref.read(botsProvider).value;
      if (!hasOrg && loc != '/onboarding') return '/onboarding';
      if (hasOrg && loc == '/onboarding' && (bots?.isNotEmpty ?? false)) return '/bots';
      if (loc == '/sign-in') return hasOrg ? '/bots' : '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', pageBuilder: _page((_, _) => const SignInScreen())),
      GoRoute(path: '/onboarding', pageBuilder: _page((_, _) => const OnboardingScreen())),
      GoRoute(path: '/two-step', pageBuilder: _page((_, _) => const TwoStepPromptScreen())),
      GoRoute(path: '/join/:token', pageBuilder: _page((_, s) => JoinScreen(token: s.pathParameters['token']!))),
      GoRoute(path: '/import/:token', pageBuilder: _page((_, s) => ImportBotScreen(token: s.pathParameters['token']!))),
      ShellRoute(
        pageBuilder: (context, state, child) => MaterialPage(
          key: state.pageKey,
          child: HomeShell(location: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(
            path: '/bots',
            pageBuilder: _page(
              (context, _) => layoutFor(MediaQuery.sizeOf(context).width) == LayoutSize.desktop ? const SizedBox.shrink() : const BotsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':botId/chat',
                pageBuilder: _page((_, s) => ChatScreen(botId: s.pathParameters['botId']!, conversationId: s.uri.queryParameters['c'], focusMessageId: s.uri.queryParameters['m'])),
              ),
              GoRoute(
                path: ':botId/activity',
                pageBuilder: _page((_, s) => ActivityScreen(botId: s.pathParameters['botId']!)),
              ),
              GoRoute(
                path: ':botId/runs/:runId',
                pageBuilder: _page((_, s) => RunTimelineScreen(botId: s.pathParameters['botId']!, runId: s.pathParameters['runId']!)),
              ),
              GoRoute(
                path: ':botId/memory',
                pageBuilder: _page((_, s) => MemoryScreen(botId: s.pathParameters['botId']!)),
              ),
              GoRoute(
                path: ':botId/settings',
                pageBuilder: _page((_, s) => BotSettingsScreen(botId: s.pathParameters['botId']!)),
              ),
              GoRoute(
                path: ':botId/history',
                pageBuilder: _page((_, s) => BotHistoryScreen(botId: s.pathParameters['botId']!)),
              ),
              GoRoute(
                path: ':botId/call',
                pageBuilder: _page((_, s) => CallScreen(botId: s.pathParameters['botId']!, conversationId: s.uri.queryParameters['c'])),
              ),
              GoRoute(
                path: ':botId/routines',
                pageBuilder: _page((_, s) => RoutinesScreen(botId: s.pathParameters['botId']!)),
              ),
              GoRoute(
                path: ':botId/integrations',
                pageBuilder: _page((_, s) => BotIntegrationsScreen(botId: s.pathParameters['botId']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/quick-ask',
            pageBuilder: _page(
              (_, s) => QuickAskScreen(key: ValueKey(s.uri.toString()), initialText: s.uri.queryParameters['text'] ?? '', fromShareExtension: s.uri.queryParameters['shared'] == '1'),
            ),
          ),
          GoRoute(
            path: '/inbox',
            pageBuilder: _page((_, s) => InboxScreen(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0)),
          ),
          GoRoute(path: '/tasks', pageBuilder: _page((_, _) => const BoardScreen())),
          GoRoute(path: '/search', pageBuilder: _page((_, _) => const SearchScreen())),
          GoRoute(
            path: '/approvals/:id',
            pageBuilder: _page((_, s) => ApprovalScreen(approvalId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/computer',
            pageBuilder: _page((_, _) => const ComputerScreen()),
            routes: [
              GoRoute(
                path: 'live',
                pageBuilder: _page((_, s) => LiveViewScreen(computerId: s.uri.queryParameters['c'] ?? '', takeoverId: s.uri.queryParameters['takeover'])),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: _page((_, _) => const SettingsScreen()),
            routes: [
              GoRoute(path: 'keys', pageBuilder: _page((_, _) => const ModelKeysScreen())),
              GoRoute(path: 'themes', pageBuilder: _page((_, _) => const ThemesScreen())),
              GoRoute(path: 'theme', pageBuilder: _page((_, _) => const ThemeScreen())),
              GoRoute(path: 'fonts', pageBuilder: _page((_, _) => const FontsScreen())),
              GoRoute(path: 'usage', pageBuilder: _page((_, _) => const UsageScreen())),
              GoRoute(path: 'background', pageBuilder: _page((_, _) => const BackgroundScreen())),
              GoRoute(path: 'skills', pageBuilder: _page((_, _) => const SkillsScreen())),
              GoRoute(
                path: 'integrations',
                pageBuilder: _page((_, _) => const IntegrationsScreen()),
                routes: [GoRoute(path: ':id', pageBuilder: _page((_, s) => IntegrationDetailScreen(integrationId: s.pathParameters['id']!)))],
              ),
              GoRoute(path: 'secrets', pageBuilder: _page((_, _) => const SecretsScreen())),
              GoRoute(path: 'computers', pageBuilder: _page((_, _) => const ComputersScreen())),
              GoRoute(path: 'companion', pageBuilder: _page((_, _) => const CompanionScreen())),
              GoRoute(path: 'admin', pageBuilder: _page((_, _) => const AdminScreen())),
              GoRoute(path: 'billing', pageBuilder: _page((_, _) => const BillingScreen())),
              GoRoute(path: 'privacy', pageBuilder: _page((_, _) => const PrivacyScreen())),
              GoRoute(path: 'two-step', pageBuilder: _page((_, _) => const TwoStepSettingsScreen())),
              GoRoute(path: 'workspace', pageBuilder: _page((_, _) => const WorkspaceSettingsScreen())),
            ],
          ),
        ],
      ),
    ],
  );
});

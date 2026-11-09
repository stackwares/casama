import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/bots/bots_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/computer/computer_screen.dart';
import '../features/home/home_shell.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/integrations/integrations_screen.dart';
import '../features/routines/routines_screen.dart';
import '../features/settings/secrets_screen.dart';
import '../features/memory/memory_screen.dart';
import '../features/settings/model_keys_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/workspaces/onboarding_screen.dart';
import 'providers.dart';

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
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(signedInProvider);
      if (signedIn.isLoading) return null;
      final loc = state.matchedLocation;
      if (signedIn.value != true) return loc == '/sign-in' ? null : '/sign-in';
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
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/bots',
            builder: (context, _) => layoutFor(MediaQuery.sizeOf(context).width) == LayoutSize.desktop
                ? const SizedBox.shrink()
                : const BotsScreen(),
            routes: [
              GoRoute(
                path: ':botId/chat',
                builder: (_, s) => ChatScreen(botId: s.pathParameters['botId']!, conversationId: s.uri.queryParameters['c']),
              ),
              GoRoute(path: ':botId/activity', builder: (_, s) => ActivityScreen(botId: s.pathParameters['botId']!)),
              GoRoute(
                path: ':botId/runs/:runId',
                builder: (_, s) => RunTimelineScreen(botId: s.pathParameters['botId']!, runId: s.pathParameters['runId']!),
              ),
              GoRoute(path: ':botId/memory', builder: (_, s) => MemoryScreen(botId: s.pathParameters['botId']!)),
              GoRoute(path: ':botId/settings', builder: (_, s) => BotSettingsScreen(botId: s.pathParameters['botId']!)),
              GoRoute(path: ':botId/routines', builder: (_, s) => RoutinesScreen(botId: s.pathParameters['botId']!)),
              GoRoute(path: ':botId/integrations', builder: (_, s) => BotIntegrationsScreen(botId: s.pathParameters['botId']!)),
            ],
          ),
          GoRoute(path: '/inbox', builder: (_, s) => InboxScreen(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0)),
          GoRoute(path: '/tasks', builder: (_, _) => const InboxScreen(initialTab: 2)),
          GoRoute(path: '/approvals/:id', builder: (_, s) => ApprovalScreen(approvalId: s.pathParameters['id']!)),
          GoRoute(path: '/computer', builder: (_, _) => const ComputerScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'keys', builder: (_, _) => const ModelKeysScreen()),
              GoRoute(path: 'skills', builder: (_, _) => const SkillsScreen()),
              GoRoute(path: 'integrations', builder: (_, _) => const IntegrationsScreen()),
              GoRoute(path: 'secrets', builder: (_, _) => const SecretsScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

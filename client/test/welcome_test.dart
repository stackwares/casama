import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/local_actions.dart';
import 'package:casama_app/features/chat/widgets/bot_ui.dart';
import 'package:casama_app/features/welcome/welcome_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Widget routed(FakeBackend backend, GoRouter router) => ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
    );

void main() {
  testWidgets('a new person lands in their welcome chat; the wizard is behind "Set Up Manually"', (tester) async {
    await setSize(tester, const Size(900, 900));
    final backend = FakeBackend()..hasOrg = false;
    final router = GoRouter(initialLocation: '/welcome', routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const Text('wizard')),
      GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.pathParameters['id']} ${s.uri.queryParameters['c']}')),
    ]);
    await tester.pumpWidget(routed(backend, router));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(backend.welcomeCalls, 1);
    expect(find.text('chat $botId $convId'), findsOneWidget);

  });

  testWidgets('the chat stays open once the new workspace is in the list', (tester) async {
    await setSize(tester, const Size(900, 900));
    final backend = FakeBackend()..hasOrg = false;
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/welcome',
      redirect: (_, state) {
        final hasOrg = (container.read(organizationsProvider).value ?? const []).isNotEmpty;
        if (!hasOrg && state.matchedLocation != '/welcome') return '/welcome';
        return null;
      },
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        GoRoute(path: '/bots/:id/chat', builder: (_, s) => Text('chat ${s.pathParameters['id']} ${s.uri.queryParameters['c']}')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('chat $botId $convId'), findsOneWidget);
    expect(find.byKey(const Key('welcomeLoading')), findsNothing);
  });

  testWidgets('"Set Up Manually" opens the wizard', (tester) async {
    await setSize(tester, const Size(900, 900));
    final backend = _SlowWelcome()..hasOrg = false;
    final router = GoRouter(initialLocation: '/welcome', routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const Text('wizard')),
    ]);
    await tester.pumpWidget(routed(backend, router));
    await tester.pump();
    await tester.tap(find.byKey(const Key('setUpManually')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('wizard'), findsOneWidget);
  });

  testWidgets('card actions named app:* stay in the app', (tester) async {
    final backend = FakeBackend();
    late WidgetRef ref0;
    late BuildContext ctx0;
    final router = GoRouter(initialLocation: '/chat', routes: [
      GoRoute(
        path: '/chat',
        builder: (_, _) => Consumer(builder: (context, ref, _) {
          ref0 = ref;
          ctx0 = context;
          return const Scaffold(body: Text('chat'));
        }),
      ),
      GoRoute(path: '/settings/keys', builder: (_, s) => Scaffold(body: Text('keys ${s.uri.queryParameters['provider']}'))),
    ]);
    await tester.pumpWidget(routed(backend, router));
    await tester.pumpAndSettle();
    expect(await handleLocalUiAction(ctx0, ref0, const BotUiAction(surfaceId: 's', name: 'welcome.next', context: {}, sourceComponentId: 'b')), isFalse);
    expect(
      await handleLocalUiAction(ctx0, ref0, const BotUiAction(surfaceId: 's', name: 'app:route', context: {'path': '/settings/keys', 'provider': 'chatgpt'}, sourceComponentId: 'b')),
      isTrue,
    );
    await tester.pumpAndSettle();
    // Where ChatGPT sign-in can't run (no desktop loopback), it explains and opens Model keys.
    expect(find.text('keys null'), findsOneWidget);
    expect(find.textContaining('open the desktop app'), findsOneWidget);
    router.go('/chat');
    await tester.pumpAndSettle();
    // "Use a local model" opens the form on the OpenAI-compatible provider.
    await handleLocalUiAction(ctx0, ref0, const BotUiAction(surfaceId: 's', name: 'app:route', context: {'path': '/settings/keys', 'provider': 'openai_compatible'}, sourceComponentId: 'b'));
    await tester.pumpAndSettle();
    expect(find.text('keys openai_compatible'), findsOneWidget);
  });
}

class _SlowWelcome extends FakeBackend {
  @override
  Future<WelcomeChat> startWelcome({String? firstName}) => Completer<WelcomeChat>().future;
}

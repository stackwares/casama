// End to end against a running local stack (supabase start, the API and a worker with
// recorded model fixtures). See scripts/e2e-app.sh.
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';

Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 45)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').where((t) => t.isNotEmpty).take(40).join(' | ');
  var route = '?';
  try {
    route = GoRouter.of(tester.element(find.byType(Scaffold).first)).routeInformationProvider.value.uri.toString();
  } catch (_) {}
  throw TestFailure('Timed out waiting for $finder. Route: $route. On screen: $texts');
}

/// Types into the chat box through its controller (avoids IME timing issues on desktop).
Future<void> typeMessage(WidgetTester tester, String text) async {
  final field = tester.widget<TextField>(find.byKey(const Key('messageInput')));
  field.controller!.text = text;
  await tester.pump();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign up, set up a workspace, chat with streaming, and recall a memory', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    final (app, backend) = await bootstrap(AppConfig.fromEnvironment);
    // Start signed out (a previous run's session persists in app storage).
    if (backend.isSignedIn) await backend.signOut();
    await tester.pumpWidget(app);
    await waitFor(tester, find.byKey(const Key('openSignIn')));
    await tap(tester, find.byKey(const Key('openSignIn')));
    await waitFor(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('continueWithEmail')));
    await tap(tester, find.byKey(const Key('usePassword')));
    await waitFor(tester, find.byKey(const Key('email')));

    // Sign up (local Supabase has email confirmation off).
    final email = 'app-${Random().nextInt(1 << 30)}@example.com';
    await tap(tester, find.byKey(const Key('toggleMode')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), 'pw-123456');
    await tap(tester, find.byKey(const Key('submit')));

    // Onboarding: workspace, model key, bot.
    await waitFor(tester, find.byKey(const Key('workspaceName')).hitTestable());
    await tester.enterText(find.byKey(const Key('workspaceName')), 'App Test');
    await tap(tester, find.byKey(const Key('createWorkspace')));
    await waitFor(tester, find.byKey(const Key('apiKey')).hitTestable());
    await tester.enterText(find.byKey(const Key('apiKey')), 'sk-or-v1-app-integration-test');
    await tap(tester, find.byKey(const Key('addKey')));
    await waitFor(tester, find.byKey(const Key('botName')).hitTestable());
    await tester.enterText(find.byKey(const Key('botName')), 'Ada');
    await tester.enterText(find.byKey(const Key('model')), 'fixture-main');
    await tap(tester, find.byKey(const Key('createBot')));

    // Chat: the reply streams in and the tool step shows as a card.
    await waitFor(tester, find.byKey(const Key('messageInput')).hitTestable());
    await typeMessage(tester, 'Please note: my favorite color is teal.');
    await tap(tester, find.byKey(const Key('sendButton')));
    await waitFor(tester, find.textContaining("I'll remember that."));
    expect(find.text('memory.write'), findsOneWidget);
    await waitFor(tester, find.byKey(const Key('sendButton')));

    // A new conversation recalls the fact.
    await tap(tester, find.byTooltip('New chat'));
    await tester.pump();
    await typeMessage(tester, 'Quick question: what is my favorite color?');
    await tap(tester, find.byKey(const Key('sendButton')));
    await waitFor(tester, find.textContaining('Your favorite color is teal.'));

    // Reopening the chat loads history from the database in order (question above answer).
    final router = GoRouter.of(tester.element(find.byKey(const Key('messageInput'))));
    router.go('/bots');
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.text('Ada').hitTestable());
    await tap(tester, find.text('Ada').hitTestable().first);
    await waitFor(tester, find.textContaining('Your favorite color is teal.'));
    final q = tester.getTopLeft(find.text('Quick question: what is my favorite color?')).dy;
    final a = tester.getTopLeft(find.textContaining('Your favorite color is teal.')).dy;
    expect(q, lessThan(a), reason: 'messages must render oldest first');

    // Events arrived over Supabase Realtime (private run topic), not only through polling.
    expect(backend.realtimeEvents, greaterThan(0), reason: 'realtime=${backend.realtimeEvents} catchUp=${backend.catchUpEvents}');

    // Phase 4: schedule a routine in a timezone, run it now, and get its notification live in the inbox.
    final botPath = GoRouter.of(tester.element(find.byKey(const Key('messageInput')))).routeInformationProvider.value.uri.path;
    final botId = RegExp(r'^/bots/([^/]+)').firstMatch(botPath)!.group(1)!;
    router.push('/bots/$botId/routines');
    await waitFor(tester, find.byKey(const Key('newRoutine')).hitTestable());
    await tap(tester, find.byKey(const Key('newRoutine')));
    await waitFor(tester, find.byKey(const Key('routineName')).hitTestable());
    await tester.enterText(find.byKey(const Key('routineName')), 'Morning summary');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Prepare the morning summary');
    await tester.enterText(find.byKey(const Key('routineTimezone')), 'America/Chicago');
    await tester.pump();
    await tap(tester, find.byKey(const Key('createRoutine')));
    await waitFor(tester, find.textContaining('(America/Chicago)'));
    expect(find.textContaining('Next:'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.play_arrow));
    await waitFor(tester, find.text('Routine started'));

    router.go('/inbox?tab=1');
    await waitFor(tester, find.text('Ada: Morning summary'), timeout: const Duration(seconds: 60));
  });
}

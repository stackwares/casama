// Stop on an iPhone Live Activity (D-324, §8.5): casama://app/runs/{id}/stop stops the run and
// lands on its chat.
import 'package:casama/core/providers.dart';
import 'package:casama/features/island/run_tracker.dart';
import 'package:casama/features/island/stop_run_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_backend.dart';

Future<FakeBackend> _open(WidgetTester tester) async {
  final backend = FakeBackend();
  final router = GoRouter(
    initialLocation: '/runs/$runId/stop',
    routes: [
      GoRoute(
        path: '/runs/:id/stop',
        builder: (_, s) => StopRunScreen(runId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bots/:botId/chat',
        builder: (_, s) =>
            Text('chat ${s.pathParameters['botId']} ${s.uri.query}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
        islandSupportedProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('stops the run and opens its chat', (tester) async {
    final backend = await _open(tester);
    expect(backend.cancelled, isTrue);
    expect(find.text('chat $botId c=$convId'), findsOneWidget);
  });

  testWidgets('a run that already ended still opens its chat', (tester) async {
    final backend = FakeBackend()..runAlreadyFinished = true;
    final router = GoRouter(
      initialLocation: '/runs/$runId/stop',
      routes: [
        GoRoute(
          path: '/runs/:id/stop',
          builder: (_, s) => StopRunScreen(runId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/bots/:botId/chat',
          builder: (_, s) => Text('chat ${s.pathParameters['botId']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          islandSupportedProvider.overrideWithValue(false),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(backend.cancelled, isFalse);
    expect(find.text('chat $botId'), findsOneWidget);
  });
}

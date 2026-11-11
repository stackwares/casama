// The Tasks tab on phones: one list grouped by status, a project filter, and "Move to" on long press.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/board/board_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// A second ticket, in progress, that belongs to the fake backend's project p1.
Task _projectTicket() {
  final t = FakeBackend().taskList.first;
  return Task(
    id: 't2',
    title: 'Write the launch post',
    detailsMd: '',
    status: TaskStatus.inProgress,
    priority: TaskPriority.none,
    assigneeBotId: null,
    assigneeUserId: null,
    createdByBotId: null,
    createdByUserId: null,
    resultMd: null,
    dueAt: null,
    labels: const [],
    position: 1,
    reviewRequired: false,
    projectId: 'p1',
    milestoneId: null,
    parentTaskId: null,
    conversationId: null,
    comments: 0,
    updatedAt: t.updatedAt,
    createdAt: t.createdAt,
  );
}

FakeBackend _backend() => FakeBackend()..taskList.add(_projectTicket());

void main() {
  testWidgets('phones show the tickets grouped by status, not columns', (tester) async {
    await setSize(tester, const Size(390, 844));
    await tester.pumpWidget(harness(_backend(), const BoardScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.byKey(const Key('column-todo')), findsNothing);
    expect(find.byKey(const Key('ticketFilters')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('section-todo')), matching: find.text('To do  1', findRichText: true)), findsOneWidget);
    expect(find.byKey(const Key('section-in_progress')), findsOneWidget);
    // Statuses without tickets get no section.
    expect(find.byKey(const Key('section-done')), findsNothing);
    expect(find.byKey(const Key('ticket-t1')), findsOneWidget);
    expect(find.byKey(const Key('ticket-t2')), findsOneWidget);
    // In status order: to do above in progress.
    expect(tester.getTopLeft(find.byKey(const Key('ticket-t1'))).dy, lessThan(tester.getTopLeft(find.byKey(const Key('section-in_progress'))).dy));

    // A tap still opens the ticket sheet.
    await tester.tap(find.byKey(const Key('ticket-t1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheetStatus')), findsOneWidget);
  });

  testWidgets('the project filter narrows the list and links to projects', (tester) async {
    await setSize(tester, const Size(390, 844));
    final router = GoRouter(
      initialLocation: '/tasks',
      routes: [
        GoRoute(path: '/tasks', builder: (_, _) => const BoardScreen()),
        GoRoute(
          path: '/projects',
          builder: (_, _) => const Scaffold(body: Text('projects page')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(_backend()), localCacheProvider.overrideWithValue(const NoCache())],
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('projectFilter')), matching: find.text('All projects')), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('projectFilter-p1')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('projectFilter')), matching: find.text('Launch site')), findsOneWidget);
    expect(find.byKey(const Key('ticket-t1')), findsNothing);
    expect(find.byKey(const Key('ticket-t2')), findsOneWidget);
    expect(find.byKey(const Key('section-todo')), findsNothing);

    // Filters that match nothing offer to clear them.
    await tester.tap(find.byKey(const Key('filter-bots')));
    await tester.pumpAndSettle();
    expect(find.text('No matching tickets'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clearFilters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-t1')), findsOneWidget);
    expect(find.byKey(const Key('ticket-t2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openProjects')));
    await tester.pumpAndSettle();
    expect(find.text('projects page'), findsOneWidget);
  });

  testWidgets('a long press moves a ticket to another status', (tester) async {
    await setSize(tester, const Size(390, 844));
    final backend = _backend();
    await tester.pumpWidget(harness(backend, const BoardScreen()));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('ticket-t1')));
    await tester.pumpAndSettle();
    expect(find.text('Move to'), findsOneWidget);
    // The ticket's own status isn't offered.
    expect(find.byKey(const Key('moveTo-todo')), findsNothing);
    await tester.tap(find.byKey(const Key('moveTo-done')));
    await tester.pumpAndSettle();
    expect(backend.taskList.first.status, TaskStatus.done);
    expect(find.byKey(const Key('section-done')), findsOneWidget);
    expect(find.byKey(const Key('section-todo')), findsNothing);
  });

  testWidgets('wide windows keep the columns', (tester) async {
    await setSize(tester, const Size(1500, 900));
    await tester.pumpWidget(harness(_backend(), const BoardScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('column-todo')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('column-in_progress')), matching: find.byKey(const Key('ticket-t2'))), findsOneWidget);
    expect(find.byKey(const Key('section-todo')), findsNothing);
    expect(find.byKey(const Key('ticketFilters')), findsNothing);
  });
}

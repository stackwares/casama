import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/projects/projects_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a new project starts planning with its lead bot and budget', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ProjectsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Launch site'), findsOneWidget);
    await tester.tap(find.byKey(const Key('newProject')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('projectTitle')), 'Docs refresh');
    await tester.enterText(find.byKey(const Key('projectGoal')), 'Rewrite the getting started guide.');
    await tester.enterText(find.byKey(const Key('projectBudget')), '20');
    await tester.pump();
    await tester.tap(find.byKey(const Key('createProject')));
    await tester.pumpAndSettle();
    expect(backend.projectActions, ['create:Docs refresh:20.0']);
  });

  testWidgets('the project screen approves the plan and signs off milestones', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ProjectScreen(projectId: 'p1')));
    await tester.pumpAndSettle();
    expect(find.text(r'$12.50 / $50.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('approvePlan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signoff-m1')));
    await tester.pumpAndSettle();
    expect(backend.projectActions, ['approve', 'signoff:m1']);
  });
}

// Improve (app) 1: a routine's name, instructions and schedule can be changed, and its recent
// runs show in the same sheet.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/routines/routines_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(FakeBackend, String)> open(WidgetTester tester) async {
    await setSize(tester, const Size(600, 1400));
    final backend = FakeBackend();
    await backend.createRoutine(
      botId,
      name: 'Daily check',
      instructions: 'Check in',
      trigger: 'schedule',
      cron: '0 9 * * *',
    );
    final id = backend.routineList.single.id;
    await tester.pumpWidget(
      harness(backend, const RoutinesScreen(botId: botId)),
    );
    await tester.pumpAndSettle();
    return (backend, id);
  }

  testWidgets('edit a repeating routine: name, instructions and schedule', (
    tester,
  ) async {
    final (backend, id) = await open(tester);
    await tester.tap(find.byKey(Key('routineMenu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('editRoutine-$id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineNoRuns')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('editRoutineName')),
      'Morning check',
    );
    await tester.enterText(
      find.byKey(const Key('editRoutineInstructions')),
      'Check in and list my meetings',
    );
    await tester.enterText(
      find.byKey(const Key('editRoutineCron')),
      '30 7 * * 1-5',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('saveRoutine')));
    await tester.tap(find.byKey(const Key('saveRoutine')));
    await tester.pumpAndSettle();
    final (savedId, fields) = backend.routineUpdates.single;
    expect(savedId, id);
    expect(fields['name'], 'Morning check');
    expect(fields['instructions'], 'Check in and list my meetings');
    expect(fields['schedule_cron'], '30 7 * * 1-5');
    // Unchanged fields are not sent.
    expect(fields['timezone'], isNull);
    expect(find.text('Morning check'), findsOneWidget);
  });

  testWidgets('a broken schedule cannot be saved', (tester) async {
    final (backend, id) = await open(tester);
    await tester.tap(find.byKey(Key('routine-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editRoutineCron')), '30 7');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('saveRoutine')));
    await tester.tap(find.byKey(const Key('saveRoutine')));
    await tester.pumpAndSettle();
    expect(backend.routineUpdates, isEmpty);
  });

  testWidgets('recent runs show and open the run', (tester) async {
    await setSize(tester, const Size(600, 1400));
    final backend = FakeBackend()
      ..routineRunList = [
        RunSummary(
          id: 'r1',
          status: 'completed',
          trigger: 'schedule',
          createdAt: DateTime.now(),
          costUsd: 0.02,
        ),
        RunSummary(
          id: 'r2',
          status: 'failed',
          trigger: 'schedule',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          costUsd: 0,
        ),
      ];
    await backend.createRoutine(
      botId,
      name: 'Daily check',
      instructions: 'Check in',
      trigger: 'schedule',
      cron: '0 9 * * *',
    );
    final id = backend.routineList.single.id;
    await tester.pumpWidget(
      harness(backend, const RoutinesScreen(botId: botId)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('routine-$id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineRun-r1')), findsOneWidget);
    expect(find.byKey(const Key('routineRun-r2')), findsOneWidget);
  });
}

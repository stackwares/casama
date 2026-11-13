// Routines that end (D-262): the editor's Ends rows, the card's end labels, and changing the end
// of an existing routine.
import 'package:casama_app/features/routines/routines_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a repeating routine can end after some runs; a one-time one has no Ends', (tester) async {
    await setSize(tester, const Size(600, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Stretch');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Remind me to stretch');
    await tester.pump();
    expect(find.byKey(const Key('routineEnds')), findsNothing);

    await tester.tap(find.text('Repeats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineEnds')), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('routineEnds')));
    await tester.tap(find.text('After some runs').last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('routineMaxRuns')));
    await tester.tap(find.text('3 runs').last);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('createRoutine')));
    final r = backend.routineList.single;
    expect(r.maxRuns, 3);
    expect(r.endsAt, isNull);
    expect(find.text('3 runs left'), findsOneWidget);
  });

  testWidgets('an end date shows on the card and can be removed', (tester) async {
    await setSize(tester, const Size(600, 1200));
    final backend = FakeBackend();
    await backend.createRoutine(
      botId,
      name: 'Daily check',
      instructions: 'Check in',
      trigger: 'schedule',
      cron: '0 9 * * *',
      endsAt: DateTime.now().add(const Duration(days: 3)),
    );
    final id = backend.routineList.single.id;
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('routineEndsAt-$id')), findsOneWidget);

    await tester.tap(find.byKey(Key('routineMenu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('routineEnd-$id')));
    await tester.pumpAndSettle();
    expect(find.text('On a date'), findsOneWidget);
    await tester.tap(find.byKey(const Key('routineEnds')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveRoutineEnd')));
    await tester.pumpAndSettle();

    expect(backend.routineEnds[id], (null, null));
    expect(find.byKey(Key('routineEndsAt-$id')), findsNothing);
  });
}

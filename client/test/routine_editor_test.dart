// The routine editor keeps GitHub, webhooks, cron and the timezone under Advanced (D-182), and
// repeating routines are picked and shown in words.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/routines/routines_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _advanced = Key('advanced-routine.editor');

Future<void> _openEditor(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('newRoutine')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('routineName')), 'Morning summary');
  await tester.enterText(find.byKey(const Key('routineInstructions')), 'Prepare the morning summary');
  await tester.pump();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('GitHub and webhook triggers wait under Advanced until it is opened', (tester) async {
    await setSize(tester, const Size(600, 1200));
    final backend = FakeBackend();
    await _openEditor(tester, backend);
    for (final t in ['Once', 'Repeats', 'Meetings', 'Messages']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('GitHub'), findsNothing);
    expect(find.text('Webhook'), findsNothing);
    expect(find.byKey(_advanced), findsOneWidget);
    expect(find.text('GitHub and webhook triggers, cron, timezone'), findsOneWidget);

    await _tapVisible(tester, find.byKey(_advanced));
    expect(find.text('GitHub'), findsOneWidget);
    await tester.tap(find.text('Webhook'));
    await tester.pumpAndSettle();

    // Folding Advanced again doesn't hide the trigger that's picked.
    await _tapVisible(tester, find.byKey(_advanced));
    expect(find.text('Webhook'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('createRoutine')));
    expect(backend.routineList.single.trigger, RoutineTrigger.webhook);
    expect(find.text('Webhook created'), findsOneWidget);
  });

  testWidgets('an existing webhook routine still shows its trigger', (tester) async {
    await setSize(tester, const Size(600, 1000));
    final backend = FakeBackend();
    await backend.createRoutine(botId, name: 'Deploy hook', instructions: 'Check the deploy', trigger: 'webhook');
    await backend.createRoutine(botId, name: 'Pull requests', instructions: 'Review them', trigger: 'github');
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.text('Deploy hook'), findsOneWidget);
    expect(find.text('On webhook'), findsOneWidget);
    expect(find.text('On GitHub events'), findsOneWidget);
  });

  testWidgets('repeats are picked without cron and shown in words', (tester) async {
    await setSize(tester, const Size(600, 1200));
    final backend = FakeBackend();
    await _openEditor(tester, backend);
    await tester.tap(find.text('Repeats'));
    await tester.pumpAndSettle();
    // Every day at 9 by default; cron and timezone stay folded.
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('repeat-daily'))).selected, isTrue);
    expect(find.text('9:00 AM'), findsOneWidget);
    expect(find.byKey(const Key('routineCron')), findsNothing);
    expect(find.byKey(const Key('routineTimezone')), findsNothing);
    expect(find.byKey(const Key('routineTimesIn')), findsOneWidget);

    // A weekday each week.
    await tester.tap(find.byKey(const Key('repeat-weekly')));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('routineWeekday')));
    await tester.tap(find.text('Friday').last);
    await tester.pumpAndSettle();

    // The cron it wrote is under Advanced, next to the timezone.
    await _tapVisible(tester, find.byKey(_advanced));
    expect(tester.widget<TextField>(find.byKey(const Key('routineCron'))).controller!.text, '0 9 * * 5');
    await tester.enterText(find.byKey(const Key('routineTimezone')), 'Europe/Lisbon');
    await tester.pump();
    expect(find.text('Times are in Europe/Lisbon'), findsOneWidget);

    // Weekdays.
    await _tapVisible(tester, find.byKey(const Key('repeat-weekdays')));
    expect(tester.widget<TextField>(find.byKey(const Key('routineCron'))).controller!.text, '0 9 * * 1-5');

    await _tapVisible(tester, find.byKey(const Key('createRoutine')));
    final r = backend.routineList.single;
    expect(r.scheduleCron, '0 9 * * 1-5');
    expect(r.timezone, 'Europe/Lisbon');
    expect(find.text('Weekdays at 9:00 AM (Europe/Lisbon)'), findsOneWidget);
  });

  testWidgets('a typed cron moves the picker, or reads as custom and keeps Advanced open', (tester) async {
    await setSize(tester, const Size(600, 1200));
    final backend = FakeBackend();
    await _openEditor(tester, backend);
    await tester.tap(find.text('Repeats'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(_advanced));

    await tester.enterText(find.byKey(const Key('routineCron')), '30 7 * * *');
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('repeat-daily'))).selected, isTrue);
    expect(find.text('7:30 AM'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('routineCron')), '*/15 * * * *');
    await tester.pumpAndSettle();
    expect(find.text('Custom: Every 15 minutes'), findsOneWidget);
    for (final r in repeatChoices) {
      expect(tester.widget<ChoiceChip>(find.byKey(Key('repeat-$r'))).selected, isFalse, reason: r);
    }
    // Folding Advanced keeps the custom cron in view.
    await _tapVisible(tester, find.byKey(_advanced));
    expect(find.byKey(const Key('routineCron')), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('createRoutine')));
    expect(backend.routineList.single.scheduleCron, '*/15 * * * *');
    expect(find.textContaining('Every 15 minutes ('), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/routines/routines_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('a routine 15 minutes before meetings with outside guests', (tester) async {
    await setSize(tester, const Size(700, 1400));
    final backend = FakeBackend()
      ..integrationList.add(Integration(
        id: 'cal-1',
        orgId: orgId,
        kind: IntegrationKind.mcp,
        name: 'google_calendar',
        status: IntegrationStatusEnum.ok,
        error: null,
        tools: const [],
        toolsCachedAt: null,
        createdAt: DateTime(2026),
        appId: 'google_calendar',
      ));
    await tester.pumpWidget(harness(backend, const RoutinesScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineName')), 'Meeting prep');
    await tester.enterText(find.byKey(const Key('routineInstructions')), 'Brief me on who I meet');
    await tester.tap(find.text('Meetings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routineOutsideGuests')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('createRoutine')));
    await tester.pumpAndSettle();
    final c = backend.createdCalendar!;
    expect(c.integrationId, 'cal-1');
    expect(c.offsetMinutes, -15);
    expect(c.outsideGuests, isTrue);
    expect(backend.routineList.single.trigger, RoutineTrigger.calendarEvent);
  });
}

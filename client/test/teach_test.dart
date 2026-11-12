import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/live.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/computer/live_view_screen.dart';
import 'package:casama_app/features/teach/teach_draft_screen.dart';
import 'package:casama_app/features/teach/teach_recorder.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'fake_live.dart';

void main() {
  test('the recorder gathers typing into one step and flushes on clicks, keys and pauses', () async {
    final steps = <AddTeachStepRequest>[];
    final r = TeachRecorder(steps.add, idle: const Duration(milliseconds: 20));
    r.char('4');
    r.char('2');
    r.char('x');
    r.backspace();
    r.click(10, 20);
    expect(steps.map((s) => s.kind.name), ['type', 'click']);
    expect(steps.first.text, '42');
    r.char('a');
    r.key('Enter');
    expect(steps.map((s) => s.kind.name), ['type', 'click', 'type', 'key']);
    r.scroll(0, 3);
    r.scroll(0, 2);
    r.char('b');
    expect(steps[4].dy, 5);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(steps.last.text, 'b');
    r.dispose();
  });

  testWidgets('the live view records while in control, with a red banner, secrets and stop', (tester) async {
    await setSize(tester, const Size(900, 900));
    final backend = FakeBackend();
    final live = FakeLiveConnector();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend), liveConnectorProvider.overrideWithValue(live)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LiveViewScreen(computerId: computerId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Teach a task waits behind ⋯, and only while in control.
    await tester.tap(find.byKey(const Key('liveMore')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('teachStart')), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('takeControl')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('liveMore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teachStart')));
    await tester.pumpAndSettle();
    // A team computer: pick the bot that learns it.
    await tester.tap(find.byKey(const Key('teachBot-$botId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('teachRecording')), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.byKey(const Key('liveSurface')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB, character: 'b');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(backend.teachSteps.map((s) => s.kind.name), ['click', 'type', 'key']);
    expect(backend.teachSteps[1].text, 'ab');
    expect(backend.teachSteps[2].key, 'Tab');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
    await tester.tap(find.byKey(const Key('liveSurface')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('teachMarkSecret')), findsNothing); // last step is the click
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD, character: 'd');
    await tester.pump(const Duration(seconds: 2)); // a pause ends the typing
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teachMarkSecret')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('teachSecretName')), 'employee id');
    await tester.pump();
    await tester.tap(find.byKey(const Key('teachSecretSave')));
    await tester.pumpAndSettle();
    expect(backend.teachActions, contains('secret:6:EMPLOYEE_ID'));

    await tester.tap(find.byKey(const Key('teachStop')));
    await tester.pumpAndSettle();
    expect(backend.teachActions.last, 'stop');
    expect(find.byKey(const Key('teachRecording')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the draft screen waits for the draft, then saves the edited skill and tries it', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend()
      ..teachStatus = TeachSessionStatusEnum.drafting
      ..teachSteps.add(AddTeachStepRequest(kind: AddTeachStepRequestKindEnum.type, text: '42.50'));
    await tester.pumpWidget(harness(backend, const TeachDraftScreen(sessionId: 'teach-1', pollEvery: Duration(milliseconds: 50))));
    await tester.pump();
    expect(find.byKey(const Key('teachDrafting')), findsOneWidget);
    backend
      ..teachStatus = TeachSessionStatusEnum.drafted
      ..teachDraft = TeachDraft(name: 'file-expense', description: 'File an expense.', body: '1. Open the portal.', inputs: const [], checks: const ['Shows Submitted']);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(find.text('Type “42.50”'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('teachBody')), '1. Open the finance portal.');
    await tester.tap(find.byKey(const Key('teachSaveTry')));
    await tester.pumpAndSettle();
    expect(backend.savedTeach, (name: 'file-expense', description: 'File an expense.', body: '1. Open the finance portal.', tryNow: true));
  });
}

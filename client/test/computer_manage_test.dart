// Managing a computer (D-240): the Manage tab (fixes, usage, sleep timer, storage, programs,
// bots, restore points, history), the reset sheet and its progress, vitals in the header, and
// fixing a broken computer from the chat.
import 'dart:typed_data';

import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/computer/computer_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

const _gb = 1024 * 1024 * 1024;

FakeBackend _running() => FakeBackend()
  ..teamComputerState = ComputerState.running
  ..vitals = ComputerVitals(
    cpuPercent: 34,
    memoryUsedBytes: (2.5 * _gb).round(),
    memoryLimitBytes: 4 * _gb,
    diskUsedBytes: (8.5 * _gb).round(),
    diskLimitBytes: 10 * _gb,
    at: DateTime.now(),
  )
  ..storage = ComputerStorage(
    usedBytes: (8.5 * _gb).round(),
    limitBytes: 10 * _gb,
    cleanableBytes: 2 * _gb,
    categories: [
      StorageCategory(id: StorageCategoryIdEnum.files, bytes: 4 * _gb),
      StorageCategory(
        id: StorageCategoryIdEnum.apps,
        bytes: (2.5 * _gb).round(),
      ),
      StorageCategory(id: StorageCategoryIdEnum.caches, bytes: 2 * _gb),
    ],
  )
  ..processes = [
    ComputerProcess(
      pid: 90,
      name: 'python3',
      command: 'python3 scrape.py',
      cpuPercent: 28,
      memoryBytes: 300 * 1024 * 1024,
      elapsedSeconds: 2460,
      system: false,
    ),
    ComputerProcess(
      pid: 7,
      name: 'computerd',
      command: 'computerd',
      cpuPercent: 0.5,
      memoryBytes: 20 * 1024 * 1024,
      elapsedSeconds: 9000,
      system: true,
    ),
  ];

Future<void> _openManage(
  WidgetTester tester,
  FakeBackend backend, {
  Size size = const Size(500, 1800),
}) async {
  await setSize(tester, size);
  await tester.pumpWidget(
    harness(
      backend,
      const Scaffold(
        body: ComputerScreen(embedded: true, initialTab: 'manage'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'a sleeping computer: the fixes, usage and sleep timer; live parts wait for it to wake',
    (tester) async {
      final backend = FakeBackend()
        ..computerUsageData = ComputerUsage(
          monthStart: '2026-11-01',
          seconds: 14 * 3600 + 20 * 60,
          costUsd: 0.42,
          days: [
            for (var d = 1; d <= 12; d++)
              ComputerUsageDay(
                date: '2026-11-${d.toString().padLeft(2, '0')}',
                seconds: d * 600,
              ),
          ],
        );
      await _openManage(tester, backend);
      expect(find.byKey(const Key('fixIt')), findsOneWidget);
      expect(find.text('Not working right?'), findsOneWidget);
      expect(find.textContaining('14 h 20 m'), findsOneWidget);
      expect(find.textContaining(r'$0.42'), findsOneWidget);
      expect(
        find.text('Wake the computer to see what takes up space.'),
        findsOneWidget,
      );
      expect(find.text('Nothing runs while it sleeps.'), findsOneWidget);
      // No vitals in the header while it sleeps: looking never wakes it.
      expect(find.byKey(const Key('computerVitals')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('sleep-30')));
      await tester.tap(find.byKey(const Key('sleep-30')));
      await tester.pumpAndSettle();
      expect(backend.computerUpdates.last, 'sleep:30');
      expect(find.text('Sleeps after 30 min without activity'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a running computer: vitals, storage to free up and programs to stop',
    (tester) async {
      final backend = _running();
      await _openManage(tester, backend);
      expect(find.byKey(const Key('computerVitals')), findsOneWidget);
      expect(find.text('34%'), findsOneWidget);
      expect(find.text('2.5 GB / 4.0 GB'), findsOneWidget);
      expect(find.text('8.5 GB / 10.0 GB'), findsOneWidget);

      // Storage: the breakdown and Free up.
      expect(find.textContaining('Your files 4.0 GB'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('freeUpSpace')));
      expect(find.text('Free up 2.0 GB'), findsOneWidget);
      await tester.tap(find.byKey(const Key('freeUpSpace')));
      await tester.pumpAndSettle();
      expect(backend.computerActions, contains('clean'));
      expect(find.text('Freed 2.0 GB'), findsOneWidget);
      expect(find.text('No caches to clear'), findsOneWidget);

      // Programs: the computer's own parts are hidden; stopping one asks first.
      expect(find.byKey(const Key('process-90')), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.byKey(const Key('process-7')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('stop-90')));
      await tester.tap(find.byKey(const Key('stop-90')));
      await tester.pumpAndSettle();
      expect(find.text('Stop Python?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmStopProcess')));
      await tester.pumpAndSettle();
      expect(backend.computerActions, contains('stop:90'));
      expect(find.byKey(const Key('process-90')), findsNothing);
      expect(
        find.text('Nothing is running besides the computer itself.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('restart from the fixes', (tester) async {
    final backend = _running();
    await _openManage(tester, backend);
    await tester.tap(find.byKey(const Key('fixRestart')));
    await tester.pumpAndSettle();
    expect(backend.computerActions, ['restart']);
    expect(find.text('Restarted. Your files are all there.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'the reset sheet says what stays, and erasing needs the name typed',
    (tester) async {
      final backend = _running()
        ..computerBotUses = [
          ComputerBotUse(botId: 'b1', name: 'Ava', lastActiveAt: null),
        ];
      await _openManage(tester, backend);
      await tester.tap(find.byKey(const Key('fixReset')));
      await tester.pumpAndSettle();
      expect(find.text('Reset Team computer'), findsOneWidget);
      expect(find.text("Ava can't use it for about a minute."), findsOneWidget);
      expect(find.text('Your files in workspace'), findsOneWidget);

      // Erase: the files go too, and the button waits for the computer's name.
      await tester.tap(find.byKey(const Key('resetOptionErase')));
      await tester.pumpAndSettle();
      expect(find.text('Every file, workspace too'), findsOneWidget);
      expect(find.text('Your files in workspace'), findsNothing);
      final confirm = find.byKey(const Key('resetConfirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('eraseConfirmField')),
        'team computer',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(backend.computerActions, ['erase+checkpoint']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a reset in progress shows its steps; a finished one offers Undo',
    (tester) async {
      final backend = _running()
        ..computerOperation = ComputerOperation(
          kind: ComputerOperationKindEnum.resetSystem,
          step: ComputerOperationStepEnum.wiping,
          checkpointId: 'cp-before',
          error: null,
          startedAt: DateTime.now().subtract(const Duration(seconds: 20)),
          finishedAt: null,
        );
      await setSize(tester, const Size(500, 1800));
      await tester.pumpWidget(
        harness(
          backend,
          const Scaffold(
            body: ComputerScreen(embedded: true, initialTab: 'manage'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('resetProgress')), findsOneWidget);
      expect(find.text('Resetting… 2 of 3'), findsWidgets);
      expect(find.text('Removing apps and settings'), findsOneWidget);
      expect(find.byKey(const Key('fixIt')), findsNothing);
      // No sleep button and no vitals while it resets.
      expect(find.byKey(const Key('computerSleep')), findsNothing);
      await tester.pumpWidget(const SizedBox());

      backend.computerOperation = ComputerOperation(
        kind: ComputerOperationKindEnum.resetSystem,
        step: ComputerOperationStepEnum.done,
        checkpointId: 'cp-before',
        error: null,
        startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        finishedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await _openManage(tester, backend);
      expect(find.byKey(const Key('resetResult')), findsOneWidget);
      expect(find.text('Fresh system ready'), findsOneWidget);
      await tester.tap(find.byKey(const Key('resetUndo')));
      await tester.pumpAndSettle();
      expect(backend.computerActions, ['restore:cp-before']);
      expect(find.text('Put back the way it was'), findsOneWidget);
      expect(find.byKey(const Key('resetResult')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('bots, restore points, history and downloading every file', (
    tester,
  ) async {
    final backend = _running()
      ..computerBotUses = [
        ComputerBotUse(
          botId: 'b1',
          name: 'Ava',
          lastActiveAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ]
      ..restorePoints = [
        for (var i = 1; i <= 5; i++)
          Checkpoint(
            id: 'cp$i',
            computerId: 'c',
            runId: null,
            label: 'Point $i',
            size: 0,
            createdAt: DateTime.now().subtract(Duration(hours: i)),
          ),
      ]
      ..history = [
        ComputerHistoryEntry(
          id: 'h1',
          action: 'computer.reset',
          actorType: ComputerHistoryEntryActorTypeEnum.user,
          actorId: 'me',
          actorName: 'Oli',
          metadata: const {},
          createdAt: DateTime.now(),
        ),
        ComputerHistoryEntry(
          id: 'h2',
          action: 'computer.slept',
          actorType: ComputerHistoryEntryActorTypeEnum.system,
          actorId: null,
          actorName: null,
          metadata: const {'reason': 'idle'},
          createdAt: DateTime.now(),
        ),
        ComputerHistoryEntry(
          id: 'h3',
          action: 'computer.restarted',
          actorType: ComputerHistoryEntryActorTypeEnum.bot,
          actorId: 'b1',
          actorName: 'Ava',
          metadata: const {},
          createdAt: DateTime.now(),
        ),
      ]
      ..archive = Uint8List.fromList([0x50, 0x4b]);
    await _openManage(tester, backend, size: const Size(500, 2600));
    expect(find.byKey(const Key('usedBy-b1')), findsOneWidget);
    expect(find.text('Active 2 minutes ago'), findsOneWidget);

    // Three restore points, then Show all.
    expect(find.byKey(const Key('restorePoint-cp3')), findsOneWidget);
    expect(find.byKey(const Key('restorePoint-cp4')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('restorePointsAll')));
    await tester.tap(find.byKey(const Key('restorePointsAll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restorePoint-cp5')), findsOneWidget);

    // History reads as sentences: you, the bot, or nobody for the idle timer.
    expect(find.textContaining('Reset the system  ·  you'), findsOneWidget);
    expect(find.textContaining('Went to sleep (no activity)'), findsOneWidget);
    expect(find.textContaining('Restarted  ·  Ava'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('downloadAllFiles')));
    await tester.tap(find.byKey(const Key('downloadAllFiles')));
    await tester.pumpAndSettle();
    expect(backend.computerActions, contains('archive'));
    // The team computer can't be deleted from here.
    expect(find.byKey(const Key('deleteComputer')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a broken computer in the chat offers Restart and More fixes', (
    tester,
  ) async {
    var restarted = 0;
    var fixes = 0;
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        Scaffold(
          body: NoticeLine(
            entry: const NoticeEntry(kind: NoticeKind.computer, text: 'error'),
            onRestartComputer: () => restarted++,
            onFixComputer: () => fixes++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('noticeRestartComputer')));
    await tester.tap(find.byKey(const Key('noticeMoreFixes')));
    expect((restarted, fixes), (1, 1));

    // A computer that's fine shows neither.
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        Scaffold(
          body: NoticeLine(
            entry: const NoticeEntry(
              kind: NoticeKind.computer,
              text: 'running',
            ),
            onRestartComputer: () {},
            onFixComputer: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noticeRestartComputer')), findsNothing);
  });
}

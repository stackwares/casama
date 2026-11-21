// The island feed and its run tracker (D-324, Phase 0): the feed's order, whose runs each device
// follows, how runs end, sub-runs folded into their parent, and the tracker going quiet when no
// bot works. Nothing here is visible yet; the native surfaces come in later phases.
import 'dart:async';

import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/push.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/companion/companion.dart';
import 'package:casama/features/companion/desktop_shell.dart';
import 'package:casama/features/inbox/for_you.dart' show needsYouCountProvider;
import 'package:casama/features/island/island_bridge.dart';
import 'package:casama/features/island/island_feed.dart';
import 'package:casama/features/island/island_call.dart';
import 'package:casama/features/island/island_settings.dart';
import 'package:casama/features/island/run_tracker.dart';
import 'package:casama/l10n/generated/app_localizations_en.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

final l10n = AppLocalizationsEn();
final t0 = DateTime(2026, 11, 16, 9);
const helperBot = '66666666-6666-4666-8666-666666666666';

class _Org extends Notifier<String?> {
  _Org(this.initial);
  final String? initial;
  @override
  String? build() => initial;
  void set(String? id) => state = id;
}

final _orgProvider = NotifierProvider<_Org, String?>(() => _Org(orgId));

class _Bots extends BotsNotifier {
  _Bots(this.initial);
  final List<Bot> initial;
  @override
  Future<List<Bot>> build() async => initial;
  void set(List<Bot> bots) => state = AsyncData(bots);
}

ActiveRun row(
  String id, {
  String bot = botId,
  String trigger = 'chat',
  String? createdBy = 'me',
  String? routineId,
  String? parent,
  String status = 'running',
  int lastSeq = 1,
  DateTime? at,
}) => ActiveRun(
  id: id,
  botId: bot,
  status: status,
  trigger: trigger,
  createdAt: at ?? t0,
  startedAt: at ?? t0,
  createdBy: createdBy,
  routineId: routineId,
  parentRunId: parent,
  conversationId: 'conv-$id',
  lastSeq: lastSeq,
);

TrackedRun tracked(
  String id, {
  DateTime? at,
  String status = 'running',
  Set<String> subRuns = const {},
  RunEnding? ending,
  String? tool,
  Map<String, Object?> args = const {},
  bool writing = false,
}) => TrackedRun(
  runId: id,
  botId: botId,
  startedAt: at ?? t0,
  status: status,
  confirmed: true,
  subRuns: subRuns,
  ending: ending,
  endedAt: ending == null ? null : (at ?? t0).add(const Duration(minutes: 1)),
  tool: tool,
  args: args,
  writing: writing,
);

Approval approval(
  String id,
  String runId, {
  String summary = 'Delete the old backups',
  Risk risk = Risk.high,
}) => Approval(
  id: id,
  botId: botId,
  runId: runId,
  toolName: 'shell.exec',
  argsRedacted: const {'cmd': 'rm -rf /backups/old'},
  summary: summary,
  risk: risk,
  status: ApprovalStatusEnum.pending,
  decidedAt: null,
  expiresAt: t0.add(const Duration(hours: 1)),
  createdAt: t0,
);

TakeoverRequest takeover(String id, String runId) => TakeoverRequest(
  id: id,
  botId: botId,
  runId: runId,
  computerId: computerId,
  reason: 'Please sign in to the bank',
  status: TakeoverRequestStatusEnum.pending,
  note: null,
  expiresAt: t0.add(const Duration(hours: 1)),
  createdAt: t0,
);

LocalActivity localOn(String runId, {String summary = 'Opening Finder'}) => (
  activity: CompanionActivity(
    runId: runId,
    bot: 'Ada',
    tool: 'desktop.launch',
    summary: summary,
  ),
  since: t0,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
  });

  group('the feed', () {
    test('orders needs an OK, take over, working, ended; this computer first, then newest', () {
      final feed = buildIslandFeed(
        l10n: l10n,
        runs: [
          tracked('done-old', at: t0, ending: RunEnding.finished),
          tracked('working-old', at: t0),
          tracked(
            'failed-new',
            at: t0.add(const Duration(minutes: 5)),
            ending: RunEnding.problem,
          ),
          tracked('working-new', at: t0.add(const Duration(minutes: 3))),
          tracked('takeover', at: t0),
          tracked('ok', at: t0),
          tracked('working-here', at: t0.subtract(const Duration(hours: 1))),
        ],
        approvals: [approval('a1', 'ok')],
        takeovers: [takeover('t1', 'takeover')],
        botNames: {botId: 'Ada'},
        local: localOn('working-here'),
      );
      expect(feed.map((i) => i.id), [
        'ok',
        'takeover',
        'working-here',
        'working-new',
        'working-old',
        'failed-new',
        'done-old',
      ]);
      expect(feed.map((i) => i.phase), [
        IslandPhase.needsOk,
        IslandPhase.takeOver,
        IslandPhase.working,
        IslandPhase.working,
        IslandPhase.working,
        IslandPhase.problem,
        IslandPhase.finished,
      ]);
      final ok = feed.first;
      expect(ok.step, 'Delete the old backups');
      expect(ok.approvalId, 'a1');
      expect(ok.risk, 'high');
      expect(ok.link, '/approvals/a1');
      expect(feed[1].step, 'Please sign in to the bank');
      // Words anyone may read, for the Lock Screen (§10): the request's own words stay in the app.
      expect(ok.publicStep, 'Working on its computer');
      expect(feed[1].publicStep, 'Wants you to take over');
      expect(feed[3].publicStep, isNull, reason: 'a working step is general words already');
      expect(feed[2].onThisComputer, isTrue);
      expect(feed[2].step, 'Opening Finder');
      expect(feed.every((i) => i.bot == 'Ada'), isTrue);
    });

    test('says how a run ended in the words of the app', () {
      final feed = buildIslandFeed(
        l10n: l10n,
        runs: [
          tracked('a', ending: RunEnding.finished),
          tracked('b', ending: RunEnding.problem),
        ],
      );
      expect(
        {for (final i in feed) i.id: i.step},
        {'a': 'Finished', 'b': 'Stopped with a problem'},
      );
      expect(feed.first.endedAt, isNotNull);
    });

    test(
      'a working step uses the chat\'s tool words, or Writing, or Thinking',
      () {
        final feed = buildIslandFeed(
          l10n: l10n,
          runs: [
            tracked(
              'search',
              at: t0.add(const Duration(minutes: 2)),
              tool: 'web.search',
              args: const {'query': 'fern repotting'},
            ),
            tracked(
              'write',
              at: t0.add(const Duration(minutes: 1)),
              tool: 'web.search',
              writing: true,
            ),
            tracked('think', at: t0),
          ],
        );
        expect(feed[0].step, l10n.toolDoing('web_search'));
        expect(feed[0].detail, contains('fern repotting'));
        expect(feed[1].step, 'Writing a reply');
        expect(feed[2].step, 'Thinking…');
        expect(feed[2].link, '/bots/$botId/chat');
      },
    );

    test(
      'a run waiting for an OK it has not loaded yet still says it needs one',
      () {
        final feed = buildIslandFeed(
          l10n: l10n,
          runs: [
            tracked('r', status: 'waiting_approval'),
            tracked('s', status: 'waiting_takeover'),
          ],
        );
        expect(feed.map((i) => i.step), [
          'Needs your OK',
          'Wants you to take over',
        ]);
      },
    );

    test('sub-runs fold into their parent: its request and its use of this computer', () {
      final feed = buildIslandFeed(
        l10n: l10n,
        runs: [
          tracked('parent', subRuns: {'helper'}),
          tracked(
            'other',
            at: t0.add(const Duration(minutes: 1)),
            subRuns: {'helper-2'},
          ),
        ],
        approvals: [approval('a1', 'helper')],
        local: localOn('helper-2'),
      );
      expect(feed, hasLength(2));
      expect(feed.first.id, 'parent');
      expect(feed.first.phase, IslandPhase.needsOk);
      expect(feed.first.approvalId, 'a1');
      expect(feed.last.id, 'other');
      expect(feed.last.onThisComputer, isTrue);
    });

    test('runs not known to be followed here stay out; a bot on this computer always shows', () {
      final feed = buildIslandFeed(
        l10n: l10n,
        runs: [TrackedRun(runId: 'unknown', botId: botId, startedAt: t0)],
        approvals: [approval('a1', 'someone-elses')],
        local: localOn('teammates-run'),
      );
      expect(feed.single.id, 'local:teammates-run');
      expect(feed.single.onThisComputer, isTrue);
      expect(feed.single.step, 'Opening Finder');
    });

    test('a run in a group chat opens the group chat', () {
      final run = TrackedRun(runId: 'r', botId: botId, startedAt: t0, confirmed: true, conversationId: 'group-1');
      final feed = buildIslandFeed(l10n: l10n, runs: [run], groupChats: {'group-1'});
      expect(feed.single.link, '/groups/group-1');
      final solo = buildIslandFeed(l10n: l10n, runs: [run]);
      expect(solo.single.link, '/bots/$botId/chat?c=group-1');
    });

    test('the Mac also shows requests that ask the person from runs it doesn\'t follow', () {
      final asks = [approval('a1', 'teammates-routine')];
      expect(buildIslandFeed(l10n: l10n, runs: const [], approvals: asks), isEmpty);
      final mac = buildIslandFeed(l10n: l10n, runs: const [], approvals: asks, everyRequest: true);
      expect(mac.single.id, 'approval:a1');
      expect(mac.single.phase, IslandPhase.needsOk);
      expect(mac.single.approvalId, 'a1');
      expect(mac.single.link, '/approvals/a1');
      // One already on a followed run's row isn't listed twice.
      final both = buildIslandFeed(l10n: l10n, runs: [tracked('teammates-routine')], approvals: asks, everyRequest: true);
      expect(both.single.id, 'teammates-routine');
    });

    test('the channel gets plain values, times in seconds', () {
      final item = buildIslandFeed(
        l10n: l10n,
        runs: [tracked('r')],
        approvals: [approval('a1', 'r')],
      ).single;
      final json = item.toJson();
      expect(json['phase'], 'needsOk');
      expect(json['run_id'], 'r');
      expect(json['approval_id'], 'a1');
      expect(json['started_at'], t0.millisecondsSinceEpoch / 1000);
      expect(json.containsKey('detail'), isFalse);
      expect(json['here'], isFalse);
    });
  });

  group('the run tracker', () {
    ({ProviderContainer c, FakeBackend backend, _Bots bots, RunTracker tracker})
    setUpTracker({
      bool mac = false,
      BotStatusEnum status = BotStatusEnum.working,
    }) {
      final backend = FakeBackend()..pendingApprovals = [];
      final bots = _Bots([
        backend.bot(status: status),
        backend.bot(id: helperBot, name: 'Helper'),
      ]);
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          islandSupportedProvider.overrideWithValue(true),
          islandFollowsAutomationProvider.overrideWithValue(mac),
          currentOrgIdProvider.overrideWithValue(orgId),
          botsProvider.overrideWith(() => bots),
          islandLocalActivityProvider.overrideWithBuild(
            (ref, notifier) => null,
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(runTrackerProvider, (_, _) {});
      return (
        c: c,
        backend: backend,
        bots: bots,
        tracker: c.read(runTrackerProvider.notifier),
      );
    }

    Future<void> settle(ProviderContainer c) async {
      await c.read(botsProvider.future);
      await Future<void>.delayed(Duration.zero);
    }

    final whose = [
      row('mine-chat'),
      row('mine-voice', trigger: 'voice'),
      row('mine-routine', trigger: 'schedule', routineId: 'routine-1'),
      row('nobodys-webhook', trigger: 'webhook', createdBy: null),
      row('teammate-chat', createdBy: 'teammate'),
      row(
        'teammate-routine',
        trigger: 'schedule',
        routineId: 'routine-2',
        createdBy: 'teammate',
      ),
      row('helper', trigger: 'subagent', parent: 'mine-chat'),
    ];

    test('a phone follows only runs the person started', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = whose;
      await settle(s.c);
      await s.tracker.check();
      expect(
        s.c.read(runTrackerProvider).map((r) => r.runId),
        unorderedEquals(['mine-chat', 'mine-voice']),
      );
      expect(s.backend.activeRunsCalls.last, [botId, helperBot]);
    });

    test('counts steps, and says once it has heard from the server', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('r')];
      expect(s.c.read(islandSyncedProvider), isFalse);
      await settle(s.c);
      await s.tracker.check();
      expect(s.c.read(islandSyncedProvider), isTrue);
      s.tracker.chatStarted('r', botId: botId, sentHere: true);
      s.tracker.chatStep('r', 'web.search', {'query': 'ferns'});
      s.tracker.chatStep('r', 'web.search', {'query': 'ferns'});
      expect(s.c.read(runTrackerProvider).single.steps, 1, reason: 'the same step twice is one');
      s.tracker.chatStep('r', 'web.search', {'query': 'fern shops'});
      s.tracker.chatWriting('r');
      expect(s.c.read(runTrackerProvider).single.steps, 2);
    });

    test('the Mac also follows routines and runs nobody started, not a teammate\'s', () async {
      final s = setUpTracker(mac: true);
      s.backend.activeRunsValue = whose;
      await settle(s.c);
      await s.tracker.check();
      expect(
        s.c.read(runTrackerProvider).map((r) => r.runId),
        unorderedEquals([
          'mine-chat',
          'mine-voice',
          'mine-routine',
          'nobodys-webhook',
        ]),
      );
    });

    test('sub-runs fold into their top-level parent, at any depth', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [
        row('parent'),
        row('child', trigger: 'subagent', parent: 'parent'),
        row('grandchild', trigger: 'delegation', parent: 'child'),
        row('orphan', trigger: 'subagent', parent: 'gone'),
      ];
      await settle(s.c);
      await s.tracker.check();
      final runs = s.c.read(runTrackerProvider);
      expect(runs.single.runId, 'parent');
      expect(runs.single.subRuns, {'child', 'grandchild'});
    });

    test('reads the newest step of a run no chat reports, and only when it moved on', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('r', lastSeq: 57)];
      s.backend.runEventsAfterValue['r'] = [
        ev(55, 'tool.started', {
          'call_id': 'c1',
          'tool': 'web.search',
          'args_redacted': {'query': 'ferns'},
        }),
      ];
      await settle(s.c);
      await s.tracker.check();
      final run = s.c.read(runTrackerProvider).single;
      expect(run.tool, 'web.search');
      expect(run.args, {'query': 'ferns'});
      expect(run.lastSeq, 57);
      expect(s.backend.runEventsAfterCalls.last, ('r', 17));
      final calls = s.backend.runEventsAfterCalls.length;
      await s.tracker.check();
      expect(s.backend.runEventsAfterCalls, hasLength(calls));
    });

    test('a run that leaves the list ended: Finished, Stopped with a problem, or gone when stopped', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [
        row('done'),
        row('failed'),
        row('stopped'),
        row('later'),
      ];
      await settle(s.c);
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider), hasLength(4));
      s.backend.runStatuses
        ..['done'] = RunStatus.completed
        ..['failed'] = RunStatus.failed
        ..['stopped'] = RunStatus.cancelled
        ..['later'] = RunStatus.running;
      s.backend.activeRunsValue = [];
      await s.tracker.check();
      final byId = {for (final r in s.c.read(runTrackerProvider)) r.runId: r};
      expect(byId.keys, unorderedEquals(['done', 'failed', 'later']));
      expect(byId['done']!.ending, RunEnding.finished);
      expect(byId['failed']!.ending, RunEnding.problem);
      // Still running by its own record (the list was read before it started): kept, and
      // followed from that record.
      expect(byId['later']!.ended, isFalse);
      expect(byId['later']!.unreadableSince, isNull);
    });

    test('a run out of the list but still going follows its own record', () async {
      // Older than the list's window while it waited for an OK, or its bot archived mid-run.
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('old', status: 'waiting_approval', lastSeq: 0)];
      await settle(s.c);
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider).single.status, 'waiting_approval');
      s.backend.activeRunsValue = [];
      s.backend.runStatuses['old'] = RunStatus.running;
      s.backend.runEventsAfterValue['old'] = [
        ev(1, 'tool.started', {'call_id': 'c1', 'tool': 'web.search', 'args_redacted': {'query': 'ferns'}}),
      ];
      await s.tracker.check();
      final run = s.c.read(runTrackerProvider).single;
      expect(run.status, 'running');
      expect(run.costUsd, 0.01);
      expect(run.tool, 'web.search');
      expect(run.unreadableSince, isNull);
      final feed = s.c.read(islandFeedProvider);
      expect(feed.single.phase, IslandPhase.working);
    });

    test('a run whose record cannot be read is let go only after 45 s of failed reads', () async {
      // A server restart: the list answers again before single runs read.
      final s = setUpTracker();
      var now = t0;
      s.tracker.clock = () => now;
      s.backend.activeRunsValue = [row('r1')];
      await settle(s.c);
      await s.tracker.check();
      s.backend.activeRunsValue = [];
      s.backend.runReadError = Exception('502');
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider).single.unreadableSince, t0);
      for (final secs in [3, 6, 9, 30, 44]) {
        now = t0.add(Duration(seconds: secs));
        await s.tracker.check();
        expect(s.c.read(runTrackerProvider), hasLength(1), reason: 'kept at $secs s');
      }

      // One good read starts the count over.
      s.backend.runReadError = null;
      s.backend.runStatuses['r1'] = RunStatus.running;
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider).single.unreadableSince, isNull);
      s.backend.runReadError = Exception('502');
      now = t0.add(const Duration(seconds: 50));
      await s.tracker.check();
      now = t0.add(const Duration(seconds: 94));
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider), hasLength(1));
      now = t0.add(const Duration(seconds: 95));
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider), isEmpty);
    });

    test('an answer for the last workspace is dropped', () async {
      final org = _Org(orgId);
      final backend = FakeBackend()..pendingApprovals = [];
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          islandSupportedProvider.overrideWithValue(true),
          currentOrgIdProvider.overrideWith((ref) => ref.watch(_orgProvider)),
          _orgProvider.overrideWith(() => org),
          botsProvider.overrideWith(() => _Bots([backend.bot(status: BotStatusEnum.working)])),
          islandLocalActivityProvider.overrideWithBuild((ref, notifier) => null),
        ],
      );
      addTearDown(c.dispose);
      c.listen(runTrackerProvider, (_, _) {});
      await c.read(botsProvider.future);
      await Future<void>.delayed(Duration.zero);
      backend.activeRunsValue = [row('r', lastSeq: 9)];
      backend.runEventsAfterGate = Completer<void>();
      final checking = c.read(runTrackerProvider.notifier).check();
      await Future<void>.delayed(Duration.zero);
      org.set('another-workspace');
      backend.runEventsAfterGate!.complete();
      await checking;
      expect(c.read(runTrackerProvider), isEmpty);
    });

    testWidgets('a hung request gives up, so the next check can run', (tester) async {
      final s = setUpTracker();
      await tester.runAsync(() => settle(s.c));
      s.backend.activeRunsGate = Completer<void>();
      final calls = s.backend.activeRunsCalls.length;
      final checking = s.tracker.check();
      await tester.pump(RunTracker.requestTimeout + const Duration(seconds: 1));
      await checking;
      s.backend.activeRunsGate = null;
      await s.tracker.check();
      expect(s.backend.activeRunsCalls.length, greaterThan(calls + 1));
      s.c.dispose();
    });

    test('asks at a quiet pace while bots work but nothing followed does', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('teammates', createdBy: 'teammate')];
      await settle(s.c);
      await s.tracker.check();
      expect(s.tracker.polling, isTrue);
      expect(s.tracker.pace, RunTracker.quietEvery);
      s.backend.activeRunsValue = [row('mine')];
      await s.tracker.check();
      expect(s.tracker.pace, RunTracker.every);
    });

    test('a slow answer from the list doesn\'t undo a status the chat just reported', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('r', status: 'waiting_approval')];
      await settle(s.c);
      s.tracker.chatStarted('r', botId: botId, sentHere: true);
      s.tracker.chatStatus('r', 'waiting_approval');
      s.tracker.chatStatus('r', 'running');
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider).single.status, 'running');
    });

    test('a chat that moves to another conversation hands its run to the tracker', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row(runId, lastSeq: 1)];
      s.backend.runStatuses[runId] = RunStatus.running;
      await settle(s.c);
      s.c.listen(chatControllerProvider(botId), (_, _) {});
      final chat = s.c.read(chatControllerProvider(botId).notifier);
      await chat.open(convId);
      await chat.send('Find me a fern');
      expect(s.c.read(runTrackerProvider).single.fromChat, isTrue);
      await chat.open('another-conversation');
      expect(s.c.read(runTrackerProvider).single.fromChat, isFalse);
      s.backend.activeRunsValue = [row(runId, lastSeq: 12)];
      s.backend.runEventsAfterValue[runId] = [
        ev(12, 'tool.started', {'call_id': 'c1', 'tool': 'web.search', 'args_redacted': {'query': 'ferns'}}),
      ];
      await s.tracker.check();
      expect(s.backend.runEventsAfterCalls.map((c) => c.$1), contains(runId));
      expect(s.c.read(runTrackerProvider).single.tool, 'web.search');
    });

    test('New chat hands the run over too', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row(runId)];
      s.backend.runStatuses[runId] = RunStatus.running;
      await settle(s.c);
      s.c.listen(chatControllerProvider(botId), (_, _) {});
      final chat = s.c.read(chatControllerProvider(botId).notifier);
      await chat.open(convId);
      await chat.send('Find me a fern');
      await chat.newChat();
      expect(s.c.read(runTrackerProvider).single.fromChat, isFalse);
    });

    testWidgets(
      'an ended run leaves after a few seconds and doesn\'t come back',
      (tester) async {
        final s = setUpTracker();
        await tester.runAsync(() => settle(s.c));
        s.tracker.chatStarted('r', botId: botId, sentHere: true);
        s.tracker.chatEnded('r', RunStatus.completed);
        expect(s.c.read(runTrackerProvider).single.ending, RunEnding.finished);
        await tester.pump(RunTracker.lingers);
        expect(s.c.read(runTrackerProvider), isEmpty);
        s.tracker.chatStarted('r', botId: botId, sentHere: true);
        expect(s.c.read(runTrackerProvider), isEmpty);
        s.c.dispose();
      },
    );

    test('a run the person stopped from the chat leaves at once, with no Finished line', () async {
      final s = setUpTracker();
      await settle(s.c);
      s.tracker.chatStarted('r', botId: botId, sentHere: true);
      expect(s.c.read(runTrackerProvider).single.confirmed, isTrue);
      s.tracker.chatEnded('r', RunStatus.cancelled);
      expect(s.c.read(runTrackerProvider), isEmpty);
    });

    test(
      'a run a chat only opened shows once the server says it is followed here',
      () async {
        final s = setUpTracker();
        await settle(s.c);
        s.backend.activeRunsValue = [
          row('routine-run', trigger: 'schedule', routineId: 'x'),
        ];
        s.tracker.chatStarted('routine-run', botId: botId);
        expect(s.c.read(runTrackerProvider).single.confirmed, isFalse);
        await s.tracker.check();
        // A routine's run on a phone: not followed.
        expect(s.c.read(runTrackerProvider), isEmpty);
      },
    );

    test(
      'stops asking when no bot works, and starts again when one does',
      () async {
        final s = setUpTracker(status: BotStatusEnum.idle);
        await settle(s.c);
        expect(s.tracker.polling, isFalse);
        expect(s.backend.activeRunsCalls, isEmpty);

        s.backend.activeRunsValue = [row('r')];
        s.bots.set([s.backend.bot(status: BotStatusEnum.working)]);
        await Future<void>.delayed(Duration.zero);
        expect(s.tracker.polling, isTrue);
        expect(s.backend.activeRunsCalls, hasLength(1));
        expect(s.c.read(runTrackerProvider).single.runId, 'r');

        // The bot is done and the run is gone: the tracker says how it ended, then goes quiet.
        s.backend.activeRunsValue = [];
        s.backend.runStatuses['r'] = RunStatus.completed;
        s.bots.set([s.backend.bot(status: BotStatusEnum.idle)]);
        await Future<void>.delayed(Duration.zero);
        await s.tracker.check();
        expect(s.c.read(runTrackerProvider).single.ending, RunEnding.finished);
        expect(s.tracker.polling, isFalse);
      },
    );

    test('a check that can\'t reach the server keeps what is shown', () async {
      final s = setUpTracker();
      s.backend.activeRunsValue = [row('r')];
      await settle(s.c);
      await s.tracker.check();
      s.backend.activeRunsError = Exception('offline');
      await s.tracker.check();
      expect(s.c.read(runTrackerProvider).single.ended, isFalse);
    });

    test('does nothing where there is no island', () async {
      // Tests run as Android, which has one now (Phase 5), as do Windows and Linux (Phase 6).
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final backend = FakeBackend();
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          currentOrgIdProvider.overrideWithValue(orgId),
        ],
      );
      addTearDown(c.dispose);
      final tracker = c.read(runTrackerProvider.notifier);
      tracker.chatStarted('r', botId: botId, sentHere: true);
      await tracker.check();
      expect(c.read(runTrackerProvider), isEmpty);
      expect(c.read(islandFeedProvider), isEmpty);
      expect(backend.activeRunsCalls, isEmpty);
    });

    test(
      'the chat reports its run with the bot and the tool\'s arguments',
      () async {
        final s = setUpTracker();
        await settle(s.c);
        s.c.listen(chatControllerProvider(botId), (_, _) {});
        final chat = s.c.read(chatControllerProvider(botId).notifier);
        await chat.open(convId);
        await chat.send('Find me a fern');
        final runId = s.c.read(chatControllerProvider(botId)).activeRunId!;
        var run = s.c
            .read(runTrackerProvider)
            .firstWhere((r) => r.runId == runId);
        expect(run.botId, botId);
        expect(run.confirmed, isTrue);
        expect(run.fromChat, isTrue);

        chat.apply(
          ev(2, 'tool.started', {
            'call_id': 'c1',
            'tool': 'web.search',
            'args_redacted': {'query': 'ferns'},
          }),
        );
        run = s.c.read(runTrackerProvider).firstWhere((r) => r.runId == runId);
        expect(run.tool, 'web.search');
        expect(run.args, {'query': 'ferns'});

        chat.apply(
          ev(3, 'approval.requested', {
            'approval_id': 'a1',
            'tool': 'shell.exec',
            'args_redacted': <String, Object?>{},
            'risk': 'high',
            'expires_at': '2026-11-16T10:00:00.000Z',
          }),
        );
        expect(
          s.c
              .read(runTrackerProvider)
              .firstWhere((r) => r.runId == runId)
              .status,
          'waiting_approval',
        );

        chat.apply(ev(4, 'run.completed', {'final_message_id': 'm1'}));
        expect(
          s.c
              .read(runTrackerProvider)
              .firstWhere((r) => r.runId == runId)
              .ending,
          RunEnding.finished,
        );
        final feed = s.c.read(islandFeedProvider);
        expect(feed.single.step, 'Finished');
        expect(feed.single.bot, 'Ada');
      },
    );
  });

  group('the bridge', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel(islandChannelName);

    ({ProviderContainer c, FakeBackend backend, List<MethodCall> calls})
    setUpBridge({Risk risk = Risk.high}) {
      final backend = FakeBackend()..pendingApprovals = [approval('a1', 'r', risk: risk)];
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(backend),
          pushProvider.overrideWithValue(_TokenPush(backend, 'fcm-1')),
          // The real shell makes a tray icon through GTK, which aborts the test process on a
          // Linux machine with no display (CI).
          desktopShellProvider.overrideWith(_QuietShell.new),
          islandSupportedProvider.overrideWithValue(true),
          currentOrgIdProvider.overrideWithValue(orgId),
          botsProvider.overrideWith(() => _Bots([backend.bot()])),
          islandLocalActivityProvider.overrideWithBuild(
            (ref, notifier) => null,
          ),
        ],
      );
      addTearDown(c.dispose);
      return (c: c, backend: backend, calls: calls);
    }

    test('sends the feed, the bots and the labels to native code', () async {
      final s = setUpBridge();
      s.backend.activeRunsValue = [row('r')];
      s.c.listen(islandBridgeProvider, (_, _) {});
      await s.c.read(botsProvider.future);
      s.c
          .read(runTrackerProvider.notifier)
          .chatStarted('r', botId: botId, sentHere: true);
      await Future<void>.delayed(Duration.zero);
      await s.c.read(approvalsProvider.future);
      await Future<void>.delayed(Duration.zero);
      final state =
          s.calls.lastWhere((c) => c.method == 'state').arguments as Map;
      final items = state['items'] as List;
      expect((items.single as Map)['phase'], 'needsOk');
      expect((items.single as Map)['approval_id'], 'a1');
      expect(state['bots'], [
        {'id': botId, 'name': 'Ada'},
      ]);
      expect((state['labels'] as Map)['stop'], 'Stop');
      expect((state['labels'] as Map)['finished'], 'Finished');
    });

    test('Allow and Deny are refused on phones and for requests the feed doesn\'t show', () async {
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      await s.c.read(approvalsProvider.future);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'a1'})), isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'not-shown'})), isFalse);
      expect(s.backend.decisions, isEmpty);
    });

    test('a phone answers in place only once unlocked, and never a high-risk request', () async {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final s = setUpBridge();
        s.backend.pendingApprovals = [approval('a1', 'r'), approval('a2', 'r2', risk: Risk.medium)];
        s.backend.activeRunsValue = [row('r'), row('r2')];
        await s.c.read(botsProvider.future);
        // Phones list only runs they follow, with their requests.
        s.c.read(runTrackerProvider.notifier)
          ..chatStarted('r', botId: botId, sentHere: true)
          ..chatStarted('r2', botId: botId, sentHere: true);
        final bridge = s.c.read(islandBridgeProvider)!;
        await s.c.read(approvalsProvider.future);
        await pumpEventQueue();
        Future<bool> act(String kind, String id, {bool unlocked = true}) async =>
            await bridge.handle(MethodCall('action', {'kind': kind, 'approval_id': id, 'unlocked': unlocked})) == true;
        expect(await act('allow', 'a2', unlocked: false), isFalse, reason: '$platform: still locked');
        expect(await act('allow', 'a1'), isFalse, reason: '$platform: high risk is reviewed in the app');
        expect(s.backend.decisions, isEmpty);
        expect(await act('deny', 'a2'), isTrue, reason: '$platform');
        expect(s.backend.decisions['a2'], 'denied');
      }
    });

    test('carries out Stop, Allow, Deny and push tokens; refuses links out of the app', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge(risk: Risk.medium);
      final bridge = s.c.read(islandBridgeProvider)!;
      await s.c.read(approvalsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(
        await bridge.handle(
          const MethodCall('action', {'kind': 'stop', 'run_id': 'r'}),
        ),
        isTrue,
      );
      expect(s.backend.cancelled, isTrue);
      expect(
        await bridge.handle(
          const MethodCall('action', {'kind': 'allow', 'approval_id': 'a1'}),
        ),
        isTrue,
      );
      expect(s.backend.decisions['a1'], 'approved');
      expect(
        await bridge.handle(
          const MethodCall('action', {'kind': 'deny', 'approval_id': 'a1'}),
        ),
        isTrue,
      );
      expect(s.backend.decisions['a1'], 'denied');
      expect(
        await bridge.handle(
          const MethodCall('token', {'run_id': 'r', 'token': 'abc'}),
        ),
        isTrue,
      );
      expect(s.backend.liveTokens.single.$1, 'r');
      expect(s.backend.liveTokens.single.$3, 'abc');
      expect(
        await bridge.handle(
          const MethodCall('action', {
            'kind': 'open',
            'link': '//evil.example',
          }),
        ),
        isFalse,
      );
      expect(
        await bridge.handle(
          const MethodCall('action', {
            'kind': 'open',
            'link': 'https://evil.example',
          }),
        ),
        isFalse,
      );
      expect(
        await bridge.handle(const MethodCall('action', {'kind': 'unknown'})),
        isFalse,
      );
    });

    test('a computer opens a high-risk request in the app, where Allow asks to unlock again (D-375)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      await s.c.read(approvalsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'a1'})), isFalse);
      expect(s.backend.decisions, isEmpty);
      // Deny needs no check.
      expect(await bridge.handle(const MethodCall('action', {'kind': 'deny', 'approval_id': 'a1'})), isTrue);
      expect(s.backend.decisions['a1'], 'denied');
    });

    test('while the app lock is up, the notch and tray send and answer nothing (D-375)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge(risk: Risk.medium);
      await s.c.read(appLockSettingsProvider.notifier).save(const AppLockSettings(enabled: true, userId: 'me'));
      s.c.read(appLockProvider.notifier).lock();
      expect(s.c.read(appLockProvider).locked, isTrue);
      final bridge = s.c.read(islandBridgeProvider)!;
      await s.c.read(approvalsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'a1'})), isFalse);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'deny', 'approval_id': 'a1'})), isFalse);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'ask', 'bot_id': botId, 'text': 'hi'})), isFalse);
      expect(s.backend.decisions, isEmpty);
      expect(s.backend.sent, isEmpty);
      // Stop always works.
      expect(await bridge.handle(const MethodCall('action', {'kind': 'stop', 'run_id': 'r'})), isTrue);
      expect(s.backend.cancelled, isTrue);
    });

    test('the tray on Windows and Linux answers requests in place, as the notch does', () async {
      for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final s = setUpBridge(risk: Risk.medium);
        final bridge = s.c.read(islandBridgeProvider)!;
        await s.c.read(approvalsProvider.future);
        await Future<void>.delayed(Duration.zero);
        expect(await bridge.handle(const MethodCall('action', {'kind': 'allow', 'approval_id': 'a1'})), isTrue);
        expect(s.backend.decisions['a1'], 'approved');
        expect(s.c.read(islandFollowsAutomationProvider), isTrue, reason: 'a computer follows routines too');
      }
    });

    test('counts the list and the menu bar panel being opened; tells the window when the notch is on screen', () async {
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      expect(await bridge.handle(const MethodCall('action', {'kind': 'seen', 'what': 'notch'})), isTrue);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'seen', 'what': 'menu_bar'})), isTrue);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'seen', 'what': 'other'})), isFalse);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => call.method == 'state');
      await bridge.send(const {'items': [], 'inbox': 7});
      expect(s.c.read(islandOnScreenProvider), isTrue);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => false);
      await bridge.send(const {'items': [], 'inbox': 8});
      expect(s.c.read(islandOnScreenProvider), isFalse);
    });

    test('asks from the notch without opening the window; the run shows at once', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      s.backend.activeRunsValue = [row(runId)];
      final bridge = s.c.read(islandBridgeProvider)!;
      await s.c.read(botsProvider.future);
      expect(
        await bridge.handle(const MethodCall('action', {'kind': 'ask', 'bot_id': botId, 'text': '  Find a fern shop  '})),
        isTrue,
      );
      expect(s.backend.sent.single, 'Find a fern shop');
      final run = s.c.read(runTrackerProvider).single;
      expect(run.runId, runId);
      expect(run.conversationId, convId);
      expect(run.confirmed, isTrue);
      expect(run.fromChat, isFalse, reason: 'no chat reports it: it follows its own record');
      expect(s.c.read(islandAskBotProvider), botId, reason: 'the next ask goes to the same bot');
      expect(s.c.read(islandFeedProvider).map((i) => i.runId), contains(runId));
    });

    test('"Needs you" in the notch and menu bar counts what the sidebar does, not unread updates', () async {
      final s = setUpBridge();
      s.backend.storedNotifications = [
        NotificationView(id: 'u1', kind: 'routine_result', title: 'Done', body: 'The report', createdAt: DateTime(2027)),
      ];
      s.c.listen(signedInProvider, (_, _) {});
      await s.c.read(signedInProvider.future);
      await s.c.read(notificationsProvider.future);
      await s.c.read(approvalsProvider.future);
      expect(s.c.read(inboxBadgeProvider), greaterThan(s.c.read(needsYouCountProvider)));
      expect(s.c.read(islandStateProvider)['inbox'], s.c.read(needsYouCountProvider));
    });

    test('sends the switches and the bot the ask field goes to', () async {
      final s = setUpBridge();
      await s.c.read(botsProvider.future);
      var state = s.c.read(islandStateProvider);
      expect(state['notch'], isTrue);
      expect(state['hover'], isTrue);
      expect(state['ask_bot'], botId, reason: 'nothing asked yet: the first bot');
      await s.c.read(islandNotchOnProvider.notifier).set(false);
      await s.c.read(islandHoverOpensProvider.notifier).set(false);
      await s.c.read(islandAskBotProvider.notifier).set('a-bot-that-was-deleted');
      state = s.c.read(islandStateProvider);
      expect(state['notch'], isFalse);
      expect(state['hover'], isFalse);
      expect(state['ask_bot'], botId, reason: 'a bot that is gone falls back to the first');
      expect((state['labels'] as Map)['ask_hint'], 'Ask a bot…');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('island.notch'), isFalse);
      expect(prefs.getBool('island.hover'), isFalse);
    });

    test('an iPhone gets only runs, cut down for the Lock Screen', () async {
      final long = 'Looking through ${'a very long list of fern shops ' * 5}';
      final item = forLockScreen({
        'id': 'r',
        'run_id': 'r',
        'step': long,
        'detail': 'x' * 200,
        'cost_usd': 0.5,
        'here': false,
        'phase': 'working',
      });
      expect((item['step'] as String).length, lessThanOrEqualTo(lockScreenStep));
      expect(item['step'], endsWith('…'));
      // What it's about stays in the app: the Lock Screen is read without unlocking (§10).
      expect(item.containsKey('detail'), isFalse);
      expect(item.containsKey('cost_usd'), isFalse);
      expect(item['phase'], 'working');
      expect(forLockScreen({'step': 'Short', 'run_id': 'r'})['step'], 'Short');
      // An approval's own summary stays in the app too; the tool's general words show instead.
      final ask = forLockScreen({
        'run_id': 'r',
        'phase': 'needsOk',
        'step': 'Delete the old backups',
        'public_step': 'Working on its computer',
      });
      expect(ask['step'], 'Working on its computer');
      expect(ask.containsKey('public_step'), isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final b = setUpBridge();
      b.backend.activeRunsValue = [row(runId)];
      await b.c.read(botsProvider.future);
      b.c.read(runTrackerProvider.notifier).chatStarted(runId, botId: botId, sentHere: true);
      await Future<void>.delayed(Duration.zero);
      final state = b.c.read(islandStateProvider);
      expect([for (final i in state['items'] as List) (i as Map)['run_id']], [runId]);
      expect(state.containsKey('synced'), isTrue);
    });

    test('an Android phone gets only runs, for the lock screen, and registers each once', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      s.backend.activeRunsValue = [row(runId)];
      await s.c.read(botsProvider.future);
      s.c.read(runTrackerProvider.notifier).chatStarted(runId, botId: botId, sentHere: true);
      await Future<void>.delayed(Duration.zero);
      final items = s.c.read(islandStateProvider)['items'] as List;
      expect([for (final i in items) (i as Map)['run_id']], [runId]);
      expect((items.single as Map).keys, isNot(contains('detail')), reason: 'the lock screen shows it (§10)');
      final bridge = s.c.read(islandBridgeProvider)!;
      await pumpEventQueue();
      expect(s.backend.liveTokens, [(runId, 'android', 'fcm-1')], reason: "the phone's token, for its run");
      s.backend.liveTokens.clear();
      await bridge.send({
        'items': [
          {'run_id': 'r1'},
          {'run_id': 'r2', 'ended_at': 1.0},
        ],
      });
      await pumpEventQueue();
      expect(s.backend.liveTokens, [('r1', 'android', 'fcm-1')], reason: 'an ended run needs no updates');
      await bridge.send({
        'items': [
          {'run_id': 'r1'},
          {'run_id': 'r3'},
        ],
      });
      await pumpEventQueue();
      expect(s.backend.liveTokens, [('r1', 'android', 'fcm-1'), ('r3', 'android', 'fcm-1')]);

      // No token yet (Firebase not ready): nothing registered, and the next state tries again.
      final push = s.c.read(pushProvider) as _TokenPush;
      push.token = null;
      await bridge.send({
        'items': [
          {'run_id': 'r4'},
        ],
      });
      await pumpEventQueue();
      expect(s.backend.liveTokens.map((t) => t.$1), isNot(contains('r4')));
      push.token = 'fcm-1';
      await bridge.send({
        'items': [
          {'run_id': 'r4'},
          {'run_id': 'r5', 'ended_at': 2.0},
        ],
      });
      await pumpEventQueue();
      expect(s.backend.liveTokens.last, ('r4', 'android', 'fcm-1'));
      expect((s.c.read(islandStateProvider)['labels'] as Map)['steps_other'], '%d steps');
      expect((s.c.read(islandStateProvider)['labels'] as Map)['steps_one'], '1 step');
    });

    test('push-to-start: an Android phone offers its token, and keeps it switched off when told', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      await bridge.syncStartToken();
      expect(s.backend.startTokens, {'fcm-1': ('android', null, true)});
      // Nothing changed: nothing sent again.
      s.backend.startTokens.clear();
      await bridge.syncStartToken();
      expect(s.backend.startTokens, isEmpty);
      // Off keeps the row, switched off, so a shared phone doesn't fall back to an earlier account.
      await s.c.read(islandStartElsewhereProvider.notifier).set(false);
      await pumpEventQueue();
      expect(s.backend.startTokens, {'fcm-1': ('android', null, false)}, reason: 'Bots you start elsewhere is off');
      await s.c.read(islandStartElsewhereProvider.notifier).set(true);
      await pumpEventQueue();
      expect(s.backend.startTokens, {'fcm-1': ('android', null, true)});
      // Firebase gave the phone a new token: the new one is registered.
      (s.c.read(pushProvider) as _TokenPush).token = 'fcm-2';
      await bridge.syncStartToken();
      expect(s.backend.startTokens['fcm-2'], ('android', null, true));
    });

    test('push-to-start: syncs run in order, so the last switch wins', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      final first = bridge.syncStartToken();
      await s.c.read(islandStartElsewhereProvider.notifier).set(false);
      await first;
      await pumpEventQueue();
      expect(s.backend.startTokens['fcm-1']?.$3, isFalse);
    });

    test("push-to-start: an iPhone registers ActivityKit's token with its Firebase token", () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      final bridge = s.c.read(islandBridgeProvider)!;
      await bridge.syncStartToken();
      expect(s.backend.startTokens, isEmpty, reason: 'no token from ActivityKit yet');
      expect(await bridge.handle(const MethodCall('start_token', {'token': ''})), isFalse);
      expect(await bridge.handle(const MethodCall('start_token', {'token': 'apns-start'})), isTrue);
      expect(s.backend.startTokens, {'apns-start': ('ios', 'fcm-1', true)});
    });

    test('push-to-start: computers never register', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      await s.c.read(islandBridgeProvider)!.syncStartToken();
      expect(s.backend.startTokens, isEmpty);
    });

    test("a voice call goes to the Mac's notch with its level; Mute and End reach the call", () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      s.c.listen(islandBridgeProvider, (_, _) {});
      await s.c.read(botsProvider.future);
      final bridge = s.c.read(islandBridgeProvider)!;
      expect(s.c.read(islandStateProvider).containsKey('call'), isFalse);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'call_mute'})), isFalse, reason: 'no call');
      final controls = _Controls();
      final started = DateTime.utc(2026, 11, 16, 9);
      s.c.read(islandCallProvider.notifier).live(IslandCall(botId: botId, startedAt: started), controls);
      final call = s.c.read(islandStateProvider)['call'] as Map;
      expect(call['bot_id'], botId);
      expect(call['bot'], isNotEmpty);
      expect(call['started_at'], started.millisecondsSinceEpoch / 1000);
      expect(call['muted'], isFalse);
      expect((s.c.read(islandStateProvider)['labels'] as Map)['hang_up'], 'Hang up');
      controls.level = 0.42;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(s.calls.where((m) => m.method == 'level').map((m) => m.arguments), contains(0.4));
      expect(await bridge.handle(const MethodCall('action', {'kind': 'call_mute'})), isTrue);
      expect(await bridge.handle(const MethodCall('action', {'kind': 'call_end'})), isTrue);
      expect(controls.done, ['mute', 'end']);
      s.c.read(islandCallProvider.notifier).ended(controls);
      expect(s.c.read(islandStateProvider).containsKey('call'), isFalse);
      final sent = s.calls.where((m) => m.method == 'level').length;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(s.calls.where((m) => m.method == 'level').length, sent, reason: 'the meter stops with the call');
    });

    test('a call is not sent to phones', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final s = setUpBridge();
      s.c.read(islandCallProvider.notifier).live(IslandCall(botId: botId, startedAt: DateTime.now()), _Controls());
      expect(s.c.read(islandStateProvider).containsKey('call'), isFalse);
    });

    test('stops sending when no native side listens', () async {
      final s = setUpBridge();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      final bridge = s.c.read(islandBridgeProvider)!;
      await bridge.send(const {'items': []});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            s.calls.add(call);
            return null;
          });
      await bridge.send(const {'items': [], 'inbox': 1});
      expect(s.calls, isEmpty);
    });
  });
}

/// Push that hands out a fixed Firebase token without asking for permission.
/// A desktop shell with no tray, shortcut or window behind it.
class _QuietShell extends DesktopShell {
  _QuietShell(super.ref);

  @override
  void showWindow() {}

  @override
  void openQuickAsk() {}
}

class _TokenPush extends PushRegistrar {
  _TokenPush(Backend backend, this.token) : super(backend, (_) {});
  String? token;

  @override
  Future<String?> silentToken() async => token;
}

class _Controls implements IslandCallControls {
  final done = <String>[];
  @override
  double level = 0;
  @override
  void toggleMute() => done.add('mute');
  @override
  void hangUp() => done.add('end');
}

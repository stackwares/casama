import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';

/// The run tracker behind the island (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §8.2): which runs
/// are going, what each is doing, and how each ended. The island feed (island_feed.dart) turns
/// it into rows; the bridge (island_bridge.dart) hands those to the native surfaces.

/// Platforms with an island: the Mac's notch and menu bar panel (Phase 1), the iPhone's Live
/// Activities (Phase 3), Android's live notifications (Phase 5), and the tray menu on Windows and
/// Linux (Phase 6, island_tray.dart). Tests turn it on with an override of [islandSupportedProvider].
const islandPlatforms = <TargetPlatform>{
  TargetPlatform.macOS,
  TargetPlatform.iOS,
  TargetPlatform.android,
  TargetPlatform.windows,
  TargetPlatform.linux,
};

/// Computers, which sit open all day: they follow routines too and answer requests in place.
const islandDesktops = <TargetPlatform>{TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux};

/// Whether the tracker has heard from the server since the app started: until then a run it
/// doesn't list may still be going (an iPhone's Live Activity from before isn't ended for it).
class IslandSynced extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final islandSyncedProvider = NotifierProvider<IslandSynced, bool>(IslandSynced.new);

/// Whether this device has an island to feed.
final islandSupportedProvider = Provider<bool>(
  (ref) => !kIsWeb && islandPlatforms.contains(defaultTargetPlatform),
);

/// Whether runs nobody started by hand (a routine, a webhook, a watcher) are followed too. A
/// computer shows them, since it sits open all day; a phone follows only what its owner started
/// (decision 6).
final islandFollowsAutomationProvider = Provider<bool>(
  (ref) => !kIsWeb && islandDesktops.contains(defaultTargetPlatform),
);

/// Triggers that mean a person started the run: a message, an @mention in a group chat, a voice
/// call, a replay or a Teach session. The server treats the first three the same way (run.ts).
const handTriggers = {'chat', 'mention', 'voice', 'replay', 'teach'};

/// Whether this device follows [run] (decision 6): runs [me] started by hand on any device, and
/// on the Mac also automation that is [me]'s (a routine keeps its owner as the run's creator) or
/// nobody's. Sub-runs are never followed on their own: they fold into their parent.
bool followsRun(
  ActiveRun run, {
  required String? me,
  required bool automation,
}) {
  if (run.parentRunId != null) return false;
  if (run.routineId == null && handTriggers.contains(run.trigger)) {
    return me != null && run.createdBy == me;
  }
  return automation && (run.createdBy == null || run.createdBy == me);
}

/// How a followed run ended, for the line it leaves behind for a short while. A run the person
/// stopped has none: it leaves at once.
enum RunEnding { finished, problem }

/// One run the tracker follows.
@immutable
class TrackedRun {
  const TrackedRun({
    required this.runId,
    required this.botId,
    required this.startedAt,
    this.conversationId,
    this.status = 'running',
    this.tool,
    this.args = const {},
    this.writing = false,
    this.costUsd = 0,
    this.lastSeq = 0,
    this.fromChat = false,
    this.confirmed = false,
    this.subRuns = const {},
    this.ending,
    this.endedAt,
    this.unreadableSince,
    this.steps = 0,
  });

  final String runId;
  final String botId;
  final DateTime startedAt;
  final String? conversationId;

  /// queued, running, waiting_approval or waiting_takeover.
  final String status;

  /// The tool it started last, with its redacted arguments; null while it has only thought.
  final String? tool;
  final Map<String, Object?> args;

  /// Its newest events are the words of its reply.
  final bool writing;
  final double costUsd;

  /// The newest event read for it; the server's `last_seq` moving past this means it moved on.
  final int lastSeq;

  /// An open chat reports this run's steps as they happen, so the tracker reads no events for it.
  final bool fromChat;

  /// Known to be a run this device follows ([followsRun]). A run sent from this device's chat is
  /// known at once; one a chat merely opened waits for the server's answer. The feed shows only
  /// confirmed runs.
  final bool confirmed;

  /// Its unfinished sub-runs (helpers it asked), at any depth: their approvals, takeovers and use
  /// of this computer show on this run's row.
  final Set<String> subRuns;

  /// Set once it ended: it stays [RunTracker.lingers], then leaves.
  final RunEnding? ending;
  final DateTime? endedAt;

  /// Since when checks in a row have found it unlisted but couldn't say how it ended (the server
  /// restarting, say); null while it reads fine.
  final DateTime? unreadableSince;

  /// Steps (tools started) seen so far, for the Lock Screen's "steps so far".
  final int steps;

  bool get ended => ending != null;

  TrackedRun copyWith({
    String? botId,
    DateTime? startedAt,
    String? conversationId,
    String? status,
    String? tool,
    Map<String, Object?>? args,
    bool? writing,
    double? costUsd,
    int? lastSeq,
    bool? fromChat,
    bool? confirmed,
    Set<String>? subRuns,
    RunEnding? ending,
    DateTime? endedAt,
    DateTime? unreadableSince,
    bool readable = false,
    int? steps,
  }) => TrackedRun(
    runId: runId,
    botId: botId ?? this.botId,
    startedAt: startedAt ?? this.startedAt,
    conversationId: conversationId ?? this.conversationId,
    status: status ?? this.status,
    tool: tool ?? this.tool,
    args: args ?? this.args,
    writing: writing ?? this.writing,
    costUsd: costUsd ?? this.costUsd,
    lastSeq: lastSeq ?? this.lastSeq,
    fromChat: fromChat ?? this.fromChat,
    confirmed: confirmed ?? this.confirmed,
    subRuns: subRuns ?? this.subRuns,
    ending: ending ?? this.ending,
    endedAt: endedAt ?? this.endedAt,
    unreadableSince: readable ? null : unreadableSince ?? this.unreadableSince,
    steps: steps ?? this.steps,
  );
}

/// What a run's newest events say it is doing.
typedef _Step = ({
  String? tool,
  Map<String, Object?> args,
  bool writing,
  int lastSeq,
});

/// Follows the runs worth showing. An open chat reports its own run's steps (the chat_* calls).
/// Every other run is found by **asking**: while any bot is working or waiting, one small query
/// every [every] lists the workspace's unfinished runs, and a run that moved on gets its newest
/// [eventsBack] events read for its step. It asks rather than listens because a second listener
/// on a run's live topic would knock the chat's own listener off it. While a check finds nothing
/// followed (a teammate's bot waiting all day, say) it asks only every [quietEvery]. With no bot
/// working and nothing followed, the timer stops; bot status arrives live, and that starts it
/// again.
class RunTracker extends Notifier<List<TrackedRun>> {
  /// How often the server is asked while a followed run goes.
  static const every = Duration(seconds: 3);

  /// How often while bots work but nothing followed does.
  static const quietEvery = Duration(seconds: 20);

  /// How long one request may take before the check gives up (a request hung across sleep).
  static const requestTimeout = Duration(seconds: 10);

  /// How many ended runs are remembered so a late answer can't bring them back.
  static const goneKept = 500;

  /// How long an ended run stays as Finished or Stopped with a problem (decision 9, the notch's
  /// 8 seconds; a phone's Live Activity keeps its own longer dismissal).
  static const lingers = Duration(seconds: 8);

  /// How many of a run's newest events are read for its step.
  static const eventsBack = 40;

  /// An unlisted run whose ending can't be read is let go once reads have failed this long in a
  /// row: long enough to ride out a server restart.
  static const unreadableFor = Duration(seconds: 45);

  /// The clock for [unreadableFor]; swapped in tests.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  Timer? _timer;
  bool _checking = false;
  bool _on = false;

  /// The last check found no followed run going: ask at the quiet pace.
  bool _quiet = false;
  final _leaving = <String, Timer>{};

  /// Runs that ended and left: a late answer from the server must not bring them back.
  final _gone = <String>{};

  /// Whether the tracker is asking the server on a timer (for tests and the bridge).
  bool get polling => _timer != null;

  /// The pace it asks at now.
  Duration get pace => _quiet ? quietEvery : every;

  @override
  List<TrackedRun> build() {
    _on = ref.watch(islandSupportedProvider);
    // Another workspace: nothing of the last one stays.
    final orgId = ref.watch(currentOrgIdProvider);
    ref.onDispose(_stop);
    if (!_on || orgId == null) return const [];
    // A bot starting or stopping work is the cue to look.
    ref.listen(botsProvider, (_, _) => _wake());
    scheduleMicrotask(_wake);
    return const [];
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    for (final t in _leaving.values) {
      t.cancel();
    }
    _leaving.clear();
    _gone.clear();
  }

  TrackedRun? _find(String runId) {
    for (final r in state) {
      if (r.runId == runId) return r;
    }
    return null;
  }

  void _put(TrackedRun run) {
    final at = state.indexWhere((r) => r.runId == run.runId);
    final before = at < 0 ? null : state[at];
    // A new tool started: one more step.
    if (run.tool != null && (before?.tool != run.tool || !mapEquals(before?.args, run.args))) {
      run = run.copyWith(steps: (before?.steps ?? 0) + 1);
    }
    state = at < 0 ? [...state, run] : ([...state]..[at] = run);
    // A run that starts waiting on the person: load the request now, so its row can say what it
    // asks and offer Allow and Deny, instead of waiting for the notification to arrive.
    if (before?.status != run.status && run.confirmed && !run.ended) {
      if (run.status == 'waiting_approval') ref.invalidate(approvalsProvider);
      if (run.status == 'waiting_takeover') ref.invalidate(takeoversProvider);
    }
  }

  void _remove(String runId) {
    if (_find(runId) != null) {
      state = [
        for (final r in state)
          if (r.runId != runId) r,
      ];
    }
  }

  void _drop(String runId) {
    _leaving.remove(runId)?.cancel();
    _gone.add(runId);
    if (_gone.length > goneKept) _gone.remove(_gone.first);
    _remove(runId);
  }

  /// [runId] ended: a short Finished or Stopped with a problem, or gone at once when the person
  /// stopped it ([ending] null).
  void _end(String runId, RunEnding? ending) {
    final run = _find(runId);
    if (run == null || run.ended) return;
    // An ended run's requests are closed on the server: drop them from the counts too.
    if (run.status == 'waiting_approval') ref.invalidate(approvalsProvider);
    if (run.status == 'waiting_takeover') ref.invalidate(takeoversProvider);
    if (ending == null) return _drop(runId);
    _put(
      run.copyWith(ending: ending, endedAt: DateTime.now(), fromChat: false),
    );
    _leaving[runId]?.cancel();
    _leaving[runId] = Timer(lingers, () {
      if (ref.mounted) _drop(runId);
    });
  }

  // The chat controller's reports. An open chat is the fastest source for its own run.

  /// A chat started following [runId]. [sentHere]: this device's chat started it, so it is the
  /// person's own and shows at once; a run a chat merely opened waits for the server's answer.
  void chatStarted(
    String runId, {
    required String botId,
    String? conversationId,
    bool sentHere = false,
  }) {
    if (!_on || _gone.contains(runId)) return;
    final known = _find(runId);
    if (known != null && known.ended) return;
    _put(
      known == null
          ? TrackedRun(
              runId: runId,
              botId: botId,
              conversationId: conversationId,
              startedAt: DateTime.now(),
              fromChat: true,
              confirmed: sentHere,
            )
          : known.copyWith(
              botId: botId,
              conversationId: conversationId,
              fromChat: true,
              confirmed: known.confirmed || sentHere,
            ),
    );
    _wake();
  }

  /// A run this device started without a chat open on it (asked from the notch): followed from
  /// its own record, as the tracker follows a routine.
  void startedHere(String runId, {required String botId, String? conversationId}) {
    if (!_on || _gone.contains(runId) || _find(runId) != null) return;
    _put(
      TrackedRun(
        runId: runId,
        botId: botId,
        conversationId: conversationId,
        startedAt: DateTime.now(),
        confirmed: true,
      ),
    );
    _wake();
  }

  TrackedRun? _live(String runId) {
    final run = _on && ref.mounted ? _find(runId) : null;
    return run == null || run.ended ? null : run;
  }

  /// The chat saw [runId] start [tool] with [args] (already redacted by the server).
  void chatStep(String runId, String tool, Map<String, Object?> args) {
    final run = _live(runId);
    if (run != null) {
      _put(
        run.copyWith(tool: tool, args: args, writing: false, fromChat: true),
      );
    }
  }

  /// The chat saw [runId] write words of its reply.
  void chatWriting(String runId) {
    final run = _live(runId);
    if (run != null && !run.writing) {
      _put(run.copyWith(writing: true, fromChat: true));
    }
  }

  /// The chat saw [runId] ask for an OK or a takeover, or get back to work.
  void chatStatus(String runId, String status) {
    final run = _live(runId);
    if (run != null && run.status != status) _put(run.copyWith(status: status));
  }

  /// The chat saw [runId] end with [status]: completed, failed or cancelled.
  void chatEnded(String runId, RunStatus status) =>
      _end(runId, switch (status) {
        RunStatus.failed => RunEnding.problem,
        RunStatus.cancelled => null,
        _ => RunEnding.finished,
      });

  /// The chat stopped following [runId] before it ended (closed, or moved to another run): the
  /// tracker reads its steps itself from now on.
  void chatReleased(String runId) {
    final run = _live(runId);
    if (run != null && run.fromChat) {
      _put(run.copyWith(fromChat: false));
      _wake();
    }
  }

  bool get _somethingRuns {
    if (state.any((r) => !r.ended)) return true;
    final bots = ref.read(botsProvider).value ?? const <Bot>[];
    return bots.any(
      (b) =>
          b.status == BotStatusEnum.working ||
          b.status == BotStatusEnum.waiting,
    );
  }

  void _wake() {
    if (!_on || !ref.mounted) return;
    if (!_somethingRuns) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer(pace, () => unawaited(check()));
    unawaited(check());
  }

  /// The next check, at [pace], or none when nothing runs.
  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!ref.mounted || !_somethingRuns) return;
    _timer = Timer(pace, () => unawaited(check()));
  }

  /// The workspace changed (or the tracker went away) while a request was out: drop the answer.
  bool _stale(String orgId) => !ref.mounted || ref.read(currentOrgIdProvider) != orgId;

  /// Asks the server what runs now and brings the list in line. Public for tests.
  Future<void> check() async {
    if (!_on || _checking || !ref.mounted) return;
    final orgId = ref.read(currentOrgIdProvider);
    final bots = ref.read(botsProvider).value ?? const <Bot>[];
    if (orgId == null) return;
    _checking = true;
    try {
      final backend = ref.read(backendProvider);
      final List<ActiveRun> rows;
      try {
        rows = await backend
            .activeRuns(orgId, [for (final b in bots) b.id])
            .timeout(requestTimeout);
      } catch (_) {
        // Offline: what's shown stays; the next check tries again.
        return;
      }
      if (_stale(orgId)) return;
      if (!ref.read(islandSyncedProvider)) ref.read(islandSyncedProvider.notifier).set(true);
      final me = backend.userId;
      final automation = ref.read(islandFollowsAutomationProvider);
      final subRuns = _foldSubRuns(rows);
      final top = [
        for (final r in rows)
          if (r.parentRunId == null) r,
      ];

      // Runs nobody reports that moved on: their newest events say what they do now.
      final steps = <String, _Step>{};
      for (final r in top) {
        final known = _find(r.id);
        if (!followsRun(r, me: me, automation: automation) ||
            _gone.contains(r.id)) {
          continue;
        }
        if (known != null &&
            (known.ended || known.fromChat || known.lastSeq == r.lastSeq)) {
          continue;
        }
        final step = await _newestStep(backend, r.id, r.lastSeq);
        if (_stale(orgId)) return;
        if (step != null) steps[r.id] = step;
      }

      final listed = <String>{};
      for (final r in top) {
        listed.add(r.id);
        final known = _find(r.id);
        if (_gone.contains(r.id) || (known != null && known.ended)) continue;
        if (!followsRun(r, me: me, automation: automation)) {
          // A run a chat opened that isn't followed here (a routine's, on a phone).
          if (known != null) _remove(r.id);
          continue;
        }
        final startedAt = r.startedAt ?? r.createdAt;
        var next =
            (known ??
                    TrackedRun(
                      runId: r.id,
                      botId: r.botId,
                      startedAt: startedAt,
                    ))
                .copyWith(
                  botId: r.botId,
                  startedAt: startedAt,
                  conversationId: r.conversationId,
                  // An open chat reports approvals and takeovers as they happen; a slower answer
                  // from the list mustn't put back a status the chat just moved past.
                  status: known != null && known.fromChat ? known.status : r.status,
                  costUsd: r.costUsd,
                  confirmed: true,
                  subRuns: subRuns[r.id] ?? const {},
                  readable: true,
                );
        final step = steps[r.id];
        if (step != null && !next.fromChat) {
          next = next.copyWith(
            tool: step.tool,
            args: step.tool == null ? null : step.args,
            writing: step.writing,
            lastSeq: step.lastSeq,
          );
        }
        _put(next);
      }

      // Runs the server no longer lists have ended: one read of each says how.
      for (final r in [...state]) {
        if (r.ended || listed.contains(r.runId)) continue;
        if (!r.confirmed) {
          _remove(r.runId);
          continue;
        }
        Run? read;
        try {
          read = await backend.run(r.runId).timeout(requestTimeout);
        } catch (_) {}
        if (_stale(orgId)) return;
        final now = _find(r.runId);
        if (now == null || now.ended) continue;
        switch (read?.status) {
          case RunStatus.completed:
            _end(r.runId, RunEnding.finished);
          case RunStatus.failed:
            _end(r.runId, RunEnding.problem);
          case RunStatus.cancelled:
            _end(r.runId, null);
          case final RunStatus status?:
            // Still going but out of the list (started after it was read, older than its window,
            // its bot archived mid-run): followed from its own record, like a listed run.
            var next = now.copyWith(
              status: now.fromChat ? now.status : status.value,
              costUsd: read!.costUsd.toDouble(),
              readable: true,
            );
            if (!now.fromChat && read.lastSeq != now.lastSeq) {
              final step = await _newestStep(backend, r.runId, read.lastSeq);
              if (_stale(orgId)) return;
              final latest = _find(r.runId);
              if (latest == null || latest.ended) continue;
              next = latest.copyWith(status: next.status, costUsd: next.costUsd, readable: true);
              if (step != null && !latest.fromChat) {
                next = next.copyWith(
                  tool: step.tool,
                  args: step.tool == null ? null : step.args,
                  writing: step.writing,
                  lastSeq: step.lastSeq,
                );
              }
            }
            _put(next);
          case null:
            // Unreadable: look again next time, and let it go once that has lasted [unreadableFor].
            final since = now.unreadableSince;
            if (since == null) {
              _put(now.copyWith(unreadableSince: clock()));
            } else if (clock().difference(since) >= unreadableFor) {
              _drop(r.runId);
            }
        }
      }
      _quiet = !state.any((r) => !r.ended);
    } finally {
      _checking = false;
      _schedule();
    }
  }

  /// Each top-level run's unfinished sub-runs, at any depth. A sub-run whose parent isn't listed
  /// (its parent just ended) belongs to nobody and is left out.
  static Map<String, Set<String>> _foldSubRuns(List<ActiveRun> rows) {
    final byId = {for (final r in rows) r.id: r};
    final folded = <String, Set<String>>{};
    for (final r in rows) {
      if (r.parentRunId == null) continue;
      var at = r;
      final seen = <String>{r.id};
      String? root;
      while (true) {
        final parent = byId[at.parentRunId];
        if (parent == null || !seen.add(parent.id)) break;
        if (parent.parentRunId == null) {
          root = parent.id;
          break;
        }
        at = parent;
      }
      if (root != null) folded.putIfAbsent(root, () => {}).add(r.id);
    }
    return folded;
  }

  /// What [runId]'s newest events (up to [lastSeq]) say it is doing; null when they can't be read.
  Future<_Step?> _newestStep(Backend backend, String runId, int lastSeq) async {
    try {
      final from = lastSeq > eventsBack ? lastSeq - eventsBack : 0;
      final events = await backend
          .runEventsAfter(runId, from, limit: eventsBack)
          .timeout(requestTimeout);
      String? tool;
      Map<String, Object?> args = const {};
      var writing = false;
      for (final e in events) {
        switch (e) {
          case ToolStartedItem(:final event) when event.payload.tool.isNotEmpty:
            tool = event.payload.tool;
            args = event.payload.argsRedacted;
            writing = false;
          case MessageDeltaItem():
            writing = true;
          default:
        }
      }
      return (tool: tool, args: args, writing: writing, lastSeq: lastSeq);
    } catch (_) {
      return null;
    }
  }
}

final runTrackerProvider = NotifierProvider<RunTracker, List<TrackedRun>>(
  RunTracker.new,
);

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/tool_words.dart';
import '../companion/companion.dart';
import '../groups/group_chats.dart' show groupChatsProvider;
import 'run_tracker.dart';

/// The island feed (D-324, docs/ISLAND-AND-MENU-BAR-PLAN.md §6 A): one list of what bots are
/// doing and what waits for the person, built once here and drawn by every surface (the Mac
/// notch and menu bar panel, the iPhone Live Activity, the Android live notification). Native
/// code draws; it never decides what a run is doing.

/// The words the island uses, in the device's language (it has no BuildContext).
final islandL10nProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  ),
);

/// What a row is about. The order is the feed's order: needs an OK, take over, working, ended.
enum IslandPhase {
  needsOk,
  takeOver,
  working,
  finished,
  problem;

  /// Finished and Stopped with a problem share the last group.
  int get group => this == problem ? finished.index : index;
}

/// One row of the island.
@immutable
class IslandItem {
  const IslandItem({
    required this.id,
    required this.phase,
    required this.botId,
    required this.bot,
    required this.step,
    required this.link,
    required this.startedAt,
    this.detail,
    this.runId,
    this.approvalId,
    this.risk,
    this.costUsd = 0,
    this.onThisComputer = false,
    this.endedAt,
    this.steps = 0,
    this.publicStep,
  });

  /// The step in words anyone may read (a phone's Lock Screen, §10), when [step] says more: an
  /// approval's own summary or a takeover's reason stay in the app.
  final String? publicStep;

  /// Steps taken so far.
  final int steps;

  /// The run's id, or `local:<run id>` for a bot on this computer whose run isn't followed.
  final String id;
  final IslandPhase phase;
  final String botId;

  /// The bot's name.
  final String bot;

  /// What it is doing or asking, in everyday words.
  final String step;

  /// What the step is about (a site, a file name), when there's something friendly to say.
  final String? detail;
  final String? runId;
  final String? approvalId;

  /// low, medium or high, for a request that needs an OK.
  final String? risk;
  final DateTime startedAt;
  final double costUsd;

  /// The bot is working on this very computer (D-066).
  final bool onThisComputer;

  /// When it ended, for Finished and Stopped with a problem.
  final DateTime? endedAt;

  /// Where a tap goes in the app.
  final String link;

  /// As the native side reads it (the casama/island channel, §8.3). Times are plain seconds.
  Map<String, Object?> toJson() => {
    'id': id,
    'phase': phase.name,
    'bot_id': botId,
    'bot': bot,
    'step': step,
    'public_step': ?publicStep,
    'detail': ?detail,
    'run_id': ?runId,
    'approval_id': ?approvalId,
    'risk': ?risk,
    'started_at': startedAt.millisecondsSinceEpoch / 1000,
    if (endedAt != null) 'ended_at': endedAt!.millisecondsSinceEpoch / 1000,
    'cost_usd': costUsd,
    'here': onThisComputer,
    'link': link,
    'steps': steps,
  };

  @override
  bool operator ==(Object other) =>
      other is IslandItem &&
      other.id == id &&
      other.phase == phase &&
      other.botId == botId &&
      other.bot == bot &&
      other.step == step &&
      other.publicStep == publicStep &&
      other.detail == detail &&
      other.runId == runId &&
      other.approvalId == approvalId &&
      other.risk == risk &&
      other.startedAt == startedAt &&
      other.costUsd == costUsd &&
      other.onThisComputer == onThisComputer &&
      other.endedAt == endedAt &&
      other.link == link &&
      other.steps == steps;

  @override
  int get hashCode => Object.hash(
    id,
    phase,
    botId,
    bot,
    step,
    detail,
    runId,
    approvalId,
    risk,
    startedAt,
    costUsd,
    onThisComputer,
    endedAt,
    link,
    steps,
    publicStep,
  );

  @override
  String toString() => 'IslandItem($id, ${phase.name}, $bot: $step)';
}

/// A bot acting on this computer, as the companion reports it, and since when.
typedef LocalActivity = ({CompanionActivity activity, DateTime since});

/// The companion's current activity, keeping the time it was first seen for the same run.
class LocalActivityNotifier extends Notifier<LocalActivity?> {
  @override
  LocalActivity? build() {
    if (!ref.watch(islandSupportedProvider)) return null;
    final listenable = ref.watch(companionProvider).activity;
    void changed() {
      final a = listenable.value;
      final was = state;
      state = a == null
          ? null
          : (
              activity: a,
              since: was != null && was.activity.runId == a.runId
                  ? was.since
                  : DateTime.now(),
            );
    }

    listenable.addListener(changed);
    ref.onDispose(() => listenable.removeListener(changed));
    final a = listenable.value;
    return a == null ? null : (activity: a, since: DateTime.now());
  }
}

final islandLocalActivityProvider =
    NotifierProvider<LocalActivityNotifier, LocalActivity?>(
      LocalActivityNotifier.new,
    );

/// Where a run's row opens: its group chat (D-118) when it runs in one, else the bot's chat.
String _chatLink(String botId, String? conversationId, Set<String> groups) => conversationId == null
    ? '/bots/$botId/chat'
    : groups.contains(conversationId)
    ? '/groups/$conversationId'
    : '/bots/$botId/chat?c=$conversationId';

/// Builds the feed from what the tracker follows, the open requests and this computer's
/// activity, most pressing first. [everyRequest]: also every approval that asks the person
/// whose run isn't followed here (a teammate's routine asking them); the Mac shows those, phones
/// don't. Pure, for tests.
List<IslandItem> buildIslandFeed({
  required AppLocalizations l10n,
  required List<TrackedRun> runs,
  List<Approval> approvals = const [],
  List<TakeoverRequest> takeovers = const [],
  Map<String, String> botNames = const {},
  LocalActivity? local,
  bool everyRequest = false,
  Set<String> groupChats = const {},
}) {
  String name(String botId) => botNames[botId] ?? l10n.islandBot;
  final items = <IslandItem>[];
  final here = local?.activity;
  final shownApprovals = <String>{};
  for (final r in runs) {
    // Only runs known to be followed here (whose runs, decision 6).
    if (!r.confirmed) continue;
    bool ours(String runId) => runId == r.runId || r.subRuns.contains(runId);
    final onThisComputer = here != null && ours(here.runId);
    if (r.ended) {
      final finished = r.ending == RunEnding.finished;
      items.add(
        IslandItem(
          id: r.runId,
          phase: finished ? IslandPhase.finished : IslandPhase.problem,
          botId: r.botId,
          bot: name(r.botId),
          step: finished ? l10n.islandFinished : l10n.islandStoppedProblem,
          runId: r.runId,
          startedAt: r.startedAt,
          endedAt: r.endedAt,
          costUsd: r.costUsd,
          steps: r.steps,
          link: _chatLink(r.botId, r.conversationId, groupChats),
        ),
      );
      continue;
    }
    final approval = approvals
        .where((a) => a.status == ApprovalStatusEnum.pending && ours(a.runId))
        .firstOrNull;
    final takeover = takeovers
        .where(
          (t) => t.status == TakeoverRequestStatusEnum.pending && ours(t.runId),
        )
        .firstOrNull;
    final IslandPhase phase;
    final String step;
    String? detail;
    String? publicStep;
    var link = _chatLink(r.botId, r.conversationId, groupChats);
    if (approval != null) shownApprovals.add(approval.id);
    if (approval != null || r.status == 'waiting_approval') {
      phase = IslandPhase.needsOk;
      if (approval == null) {
        step = l10n.islandNeedsOk;
      } else {
        link = '/approvals/${approval.id}';
        final words = toolWords(l10n, approval.toolName, approval.argsRedacted);
        step = approval.summary.isNotEmpty ? approval.summary : words.doing;
        if (approval.summary.isEmpty) detail = words.detail;
        publicStep = words.doing;
      }
    } else if (takeover != null || r.status == 'waiting_takeover') {
      phase = IslandPhase.takeOver;
      step = takeover == null || takeover.reason.isEmpty
          ? l10n.islandTakeOver
          : takeover.reason;
      publicStep = l10n.islandTakeOver;
    } else {
      phase = IslandPhase.working;
      if (onThisComputer && here.summary.isNotEmpty) {
        step = here.summary;
      } else if (r.writing) {
        step = l10n.islandWriting;
      } else if (r.tool != null) {
        final words = toolWords(l10n, r.tool!, r.args);
        step = words.doing;
        detail = words.detail;
      } else {
        step = l10n.thinking;
      }
    }
    items.add(
      IslandItem(
        id: r.runId,
        phase: phase,
        botId: r.botId,
        bot: name(r.botId),
        step: step,
        publicStep: publicStep == step ? null : publicStep,
        detail: detail,
        runId: r.runId,
        approvalId: approval?.id,
        risk: approval?.risk.value,
        startedAt: r.startedAt,
        costUsd: r.costUsd,
        onThisComputer: onThisComputer,
        steps: r.steps,
        link: link,
      ),
    );
  }
  if (everyRequest) {
    for (final a in approvals) {
      if (a.status != ApprovalStatusEnum.pending || shownApprovals.contains(a.id)) continue;
      final words = toolWords(l10n, a.toolName, a.argsRedacted);
      items.add(
        IslandItem(
          id: 'approval:${a.id}',
          phase: IslandPhase.needsOk,
          botId: a.botId,
          bot: name(a.botId),
          step: a.summary.isNotEmpty ? a.summary : words.doing,
          publicStep: a.summary.isNotEmpty ? words.doing : null,
          detail: a.summary.isEmpty ? words.detail : null,
          runId: a.runId,
          approvalId: a.id,
          risk: a.risk.value,
          startedAt: a.createdAt,
          onThisComputer: here != null && here.runId == a.runId,
          link: '/approvals/${a.id}',
        ),
      );
    }
  }
  // A bot on this computer always shows, with Stop (D-066), even when its run isn't one this
  // device follows (a teammate's bot using it) or the tracker hasn't seen it yet.
  if (local != null && here != null && !items.any((i) => i.onThisComputer)) {
    items.add(
      IslandItem(
        id: 'local:${here.runId}',
        phase: IslandPhase.working,
        botId: '',
        bot: here.bot.isEmpty ? l10n.islandBot : here.bot,
        step: here.summary.isNotEmpty
            ? here.summary
            : toolWords(l10n, here.tool).doing,
        runId: here.runId,
        startedAt: local.since,
        onThisComputer: true,
        link: '/settings/companion',
      ),
    );
  }
  // Most pressing first; within a group, this computer first, then the newest.
  items.sort((a, b) {
    final byGroup = a.phase.group.compareTo(b.phase.group);
    if (byGroup != 0) return byGroup;
    if (a.onThisComputer != b.onThisComputer) return a.onThisComputer ? -1 : 1;
    return (b.endedAt ?? b.startedAt).compareTo(a.endedAt ?? a.startedAt);
  });
  return items;
}

/// Everything the island shows, most pressing first. Empty where there is no island.
final islandFeedProvider = Provider<List<IslandItem>>((ref) {
  if (!ref.watch(islandSupportedProvider)) return const [];
  return buildIslandFeed(
    l10n: ref.watch(islandL10nProvider),
    runs: ref.watch(runTrackerProvider),
    approvals: ref.watch(approvalsProvider).value ?? const [],
    takeovers: ref.watch(takeoversProvider).value ?? const [],
    botNames: {
      for (final b in ref.watch(botsProvider).value ?? const <Bot>[])
        b.id: b.name,
    },
    local: ref.watch(islandLocalActivityProvider),
    everyRequest: ref.watch(islandFollowsAutomationProvider),
    groupChats: {for (final g in ref.watch(groupChatsProvider).value ?? const <Conversation>[]) g.id},
  );
});

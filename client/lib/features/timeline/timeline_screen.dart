import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../chat/chat_screen.dart';

/// A bot's recent runs.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final runs = ref.watch(runsProvider(botId));
    return SubPage(
      title: l10n.activity,
      subtitle: ref.watch(botProvider(botId))?.name,
      actions: [HeaderIconButton(icon: LucideIcons.rotateCw, tooltip: l10n.refresh, onPressed: () => ref.invalidate(runsProvider(botId)))],
      body: AsyncView(
        value: runs,
        onRetry: () => ref.invalidate(runsProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.activity, title: l10n.noRuns, message: l10n.noRunsHelp)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(runsProvider(botId)),
                child: PageListView(
                  itemCount: items.length,
                  itemBuilder: (context, i) => _RunCard(run: items[i], onTap: () => context.push('/bots/$botId/runs/${items[i].id}')).appListItemEntrance(i),
                ),
              ),
      ),
    );
  }
}

(String, Color, IconData) runStatusStyle(BuildContext context, String status) {
  final colors = context.appColors;
  final l10n = context.l10n;
  return switch (status) {
    'completed' => (l10n.runCompleted, colors.positive, LucideIcons.check),
    'failed' => (l10n.runStatusFailed, colors.negative, LucideIcons.circleAlert),
    'cancelled' => (l10n.runStatusStopped, context.colorScheme.onSurfaceVariant, LucideIcons.square),
    'paused' || 'waiting' => (l10n.runWaiting, colors.waiting, LucideIcons.pause),
    _ => (l10n.runWorking, colors.working, LucideIcons.ellipsis),
  };
}

String _triggerLabel(BuildContext context, String trigger) => switch (trigger) {
  'chat' => context.l10n.triggerChat,
  'routine' || 'schedule' || 'cron' => context.l10n.triggerRoutine,
  'webhook' => context.l10n.triggerWebhook,
  _ => trigger.isEmpty ? trigger : trigger[0].toUpperCase() + trigger.substring(1),
};

class _RunCard extends StatelessWidget {
  const _RunCard({required this.run, required this.onTap});
  final RunSummary run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (label, color, icon) = runStatusStyle(context, run.status);
    final triggerIcon = switch (run.trigger) {
      'chat' => LucideIcons.messageCircle,
      'webhook' => LucideIcons.webhook,
      _ => LucideIcons.clock,
    };
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 12, AppSpace.sm, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.icon + 2),
            ),
            alignment: Alignment.center,
            child: Icon(triggerIcon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _triggerLabel(context, run.trigger),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    StatusLabel(text: label, color: color, pill: true, icon: icon),
                  ],
                ),
                const SizedBox(height: 3),
                Text(relativeTime(run.createdAt, context), style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            formatUsd(run.costUsd),
            style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular, color: scheme.onSurfaceVariant),
          ),
          Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

enum EventFilter { all, tools, messages, system }

bool matchesFilter(EventFilter f, String type) => switch (f) {
  EventFilter.all => true,
  EventFilter.tools => type.startsWith('tool.') || type.startsWith('checkpoint.'),
  EventFilter.messages => type.startsWith('message.'),
  EventFilter.system => !type.startsWith('tool.') && !type.startsWith('message.'),
};

/// Every event of one run, with filters; checkpoints can be restored from here.
class RunTimelineScreen extends ConsumerStatefulWidget {
  const RunTimelineScreen({super.key, required this.botId, required this.runId});
  final String botId;
  final String runId;

  @override
  ConsumerState<RunTimelineScreen> createState() => _RunTimelineScreenState();
}

class _RunTimelineScreenState extends ConsumerState<RunTimelineScreen> {
  var _filter = EventFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(runEventsProvider(widget.runId));
    final computer = computerForBot(ref.watch(computersProvider).value ?? const [], widget.botId);
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.timelineTitle,
        subtitle: ref.watch(botProvider(widget.botId))?.name,
        actions: [HeaderIconButton(icon: LucideIcons.rotateCw, tooltip: l10n.refresh, onPressed: () => ref.invalidate(runEventsProvider(widget.runId)))],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: kPageMaxWidth);
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.sm),
                child: AppSegmentedControl<EventFilter>(
                  values: EventFilter.values,
                  labels: {
                    EventFilter.all: l10n.allEvents,
                    EventFilter.tools: l10n.filterTools,
                    EventFilter.messages: l10n.filterMessages,
                    EventFilter.system: l10n.filterSystem,
                  },
                  groupValue: _filter,
                  onValueChanged: (f) => setState(() => _filter = f),
                ),
              ),
              Expanded(
                child: AsyncView(
                  value: events,
                  onRetry: () => ref.invalidate(runEventsProvider(widget.runId)),
                  data: (items) {
                    final shown = items
                        .where(
                          (e) => matchesFilter(_filter, e.type) && e.type != 'message.delta' || (_filter == EventFilter.messages && e.type == 'message.delta'),
                        )
                        .toList();
                    if (shown.isEmpty) return EmptyState(icon: LucideIcons.funnelX, message: l10n.noEventsForFilter);
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => TimelineTile(
                        item: shown[i],
                        first: i == 0,
                        last: i == shown.length - 1,
                        onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One event in the timeline: a tinted dot on a rail, the event type, its time and a summary.
class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.item, this.onRestore, this.first = false, this.last = false});
  final RunEventItem item;
  final void Function(String checkpointId)? onRestore;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final payload = item.envelope.payload;
    final time = item.envelope.ts.toLocal();
    final hh = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    final summary = switch (item) {
      ToolStartedItem(:final event) => '${event.payload.tool} ${jsonEncode(event.payload.argsRedacted)}',
      ToolCompletedItem(:final event) => '${event.payload.resultPreview} (${event.payload.durationMs} ms)',
      ToolFailedItem(:final event) => '${event.payload.errorCode}: ${event.payload.message}',
      ToolOutputItem(:final event) => event.payload.chunk.trim(),
      MessageDeltaItem(:final event) => event.payload.text,
      UsageItem(:final event) => '${formatUsd(event.payload.costUsd)} · ${event.payload.tokensIn + event.payload.tokensOut} tokens',
      RunFailedItem(:final event) => event.payload.message,
      CheckpointCreatedItem(:final event) => event.payload.label,
      ComputerStateItem(:final event) => event.payload.state.value,
      SkillLoadedItem(:final event) => event.payload.name,
      _ => payload.isEmpty ? '' : jsonEncode(payload),
    };
    final t = item.type;
    final (icon, color) = switch (t) {
      'tool.started' => (LucideIcons.play, colors.info),
      'tool.completed' => (LucideIcons.check, colors.positive),
      'tool.failed' || 'run.failed' => (LucideIcons.circleAlert, colors.negative),
      'tool.output' => (LucideIcons.squareTerminal, scheme.onSurfaceVariant),
      'run.started' => (LucideIcons.flag, scheme.primary),
      'run.completed' => (LucideIcons.checkCheck, colors.positive),
      'usage' => (LucideIcons.banknote, colors.positive),
      _ when t.startsWith('message.') => (LucideIcons.messageCircle, scheme.primary),
      _ when t.startsWith('checkpoint.') => (LucideIcons.bookmark, colors.warning),
      _ when t.startsWith('computer.') => (LucideIcons.monitor, colors.working),
      _ when t.startsWith('skill.') => (LucideIcons.bookOpen, colors.info),
      _ when t.startsWith('approval.') || t.startsWith('takeover.') => (LucideIcons.hand, colors.waiting),
      _ => (LucideIcons.circle, scheme.onSurfaceVariant),
    };
    final rail = colors.hairline;
    final checkpoint = item is CheckpointCreatedItem && onRestore != null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(width: 2, height: 10, color: first ? Colors.transparent : rail),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: context.isDark ? 0.22 : 0.13),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: icon == LucideIcons.circle ? 8 : 15, color: color),
                ),
                Expanded(child: Container(width: 2, color: last ? Colors.transparent : rail)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t,
                          style: AppText.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                      ),
                      Text(
                        '#${item.seq}  $hh',
                        style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                      ),
                    ],
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                  if (checkpoint) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => onRestore!((item as CheckpointCreatedItem).event.payload.checkpointId),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12)),
                      icon: const Icon(LucideIcons.rotateCcw, size: 16),
                      label: Text(context.l10n.restore),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

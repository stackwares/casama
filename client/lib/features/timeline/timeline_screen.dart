import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../chat/chat_screen.dart';

/// A bot's recent runs.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final runs = ref.watch(runsProvider(botId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.activity)),
      body: AsyncView(
        value: runs,
        onRetry: () => ref.invalidate(runsProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.timeline, message: l10n.noRuns)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(runsProvider(botId)),
                child: ListView(children: [
                  for (final r in items)
                    ListTile(
                      leading: Icon(switch (r.status) {
                        'completed' => Icons.check_circle_outline,
                        'failed' => Icons.error_outline,
                        'cancelled' => Icons.stop_circle_outlined,
                        _ => Icons.pending_outlined,
                      }),
                      title: Text('${r.trigger} · ${r.status}'),
                      subtitle: Text('${relativeTime(r.createdAt, context)} · ${formatUsd(r.costUsd)}'),
                      onTap: () => context.push('/bots/$botId/runs/${r.id}'),
                    ),
                ]),
              ),
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
      appBar: AppBar(
        title: Text(l10n.timelineTitle),
        actions: [IconButton(onPressed: () => ref.invalidate(runEventsProvider(widget.runId)), icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<EventFilter>(
            segments: [
              ButtonSegment(value: EventFilter.all, label: Text(l10n.allEvents)),
              ButtonSegment(value: EventFilter.tools, label: Text(l10n.filterTools)),
              ButtonSegment(value: EventFilter.messages, label: Text(l10n.filterMessages)),
              ButtonSegment(value: EventFilter.system, label: Text(l10n.filterSystem)),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        Expanded(
          child: AsyncView(
            value: events,
            onRetry: () => ref.invalidate(runEventsProvider(widget.runId)),
            data: (items) {
              final shown = items.where((e) => matchesFilter(_filter, e.type) && e.type != 'message.delta' || (_filter == EventFilter.messages && e.type == 'message.delta')).toList();
              return ListView.builder(
                itemCount: shown.length,
                itemBuilder: (context, i) => TimelineTile(
                  item: shown[i],
                  onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// One event in the timeline.
class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.item, this.onRestore});
  final RunEventItem item;
  final void Function(String checkpointId)? onRestore;

  @override
  Widget build(BuildContext context) {
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
    return ListTile(
      dense: true,
      leading: Text('#${item.seq}', style: monoStyle),
      title: Text(item.type, style: monoStyle.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(summary, maxLines: 4, overflow: TextOverflow.ellipsis),
      trailing: item is CheckpointCreatedItem && onRestore != null
          ? TextButton(
              onPressed: () => onRestore!((item as CheckpointCreatedItem).event.payload.checkpointId),
              child: Text(context.l10n.restore),
            )
          : Text(hh, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

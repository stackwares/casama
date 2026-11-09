import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Approvals waiting for you, notifications, and the shared task board.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(approvalsProvider).value?.length ?? 0;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.inbox),
          bottom: TabBar(tabs: [
            Tab(text: pending == 0 ? l10n.approvals : l10n.approvalsCount(pending)),
            Tab(text: l10n.notifications),
            Tab(text: l10n.taskBoard),
          ]),
        ),
        body: const TabBarView(children: [ApprovalsList(), NotificationsList(), TaskBoard()]),
      ),
    );
  }
}

class ApprovalsList extends ConsumerWidget {
  const ApprovalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncView(
      value: ref.watch(approvalsProvider),
      onRetry: () => ref.invalidate(approvalsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(icon: Icons.verified_user_outlined, message: l10n.noApprovals)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(approvalsProvider),
              child: ListView(padding: const EdgeInsets.all(12), children: [for (final a in items) ApprovalCard(approval: a)]),
            ),
    );
  }
}

/// One approval request with approve, deny and "always allow".
class ApprovalCard extends ConsumerStatefulWidget {
  const ApprovalCard({super.key, required this.approval, this.onDecided});
  final Approval approval;
  final VoidCallback? onDecided;

  @override
  ConsumerState<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<ApprovalCard> {
  var _busy = false;

  Future<void> _decide(bool approve, {bool always = false}) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).decideApproval(widget.approval.id, approve: approve, alwaysAllow: always);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(approvalsProvider);
      showMessage(context, approve ? l10n.approved : l10n.denied);
      widget.onDecided?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final a = widget.approval;
    final bot = ref.watch(botProvider(a.botId));
    final riskColor = switch (a.risk) {
      Risk.high => theme.colorScheme.error,
      Risk.medium => theme.colorScheme.tertiary,
      Risk.low => theme.colorScheme.primary,
    };
    final args = const JsonEncoder.withIndent('  ').convert(a.argsRedacted);
    return Card(
      key: Key('approval-${a.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(l10n.botWantsTo(bot?.name ?? l10n.aBot, a.summary), style: theme.textTheme.titleMedium)),
            Chip(
              label: Text(switch (a.risk) { Risk.high => l10n.riskHigh, Risk.medium => l10n.riskMedium, Risk.low => l10n.riskLow }),
              side: BorderSide(color: riskColor),
              labelStyle: TextStyle(color: riskColor),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${a.toolName} · ${l10n.requestedAgo(relativeTime(a.createdAt, context))}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(args, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
          ),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
            TextButton(onPressed: () => context.go('/bots/${a.botId}/runs/${a.runId}'), child: Text(l10n.viewRun)),
            OutlinedButton(key: const Key('deny'), onPressed: _busy ? null : () => _decide(false), child: Text(l10n.deny)),
            OutlinedButton(
              key: const Key('alwaysAllow'),
              onPressed: _busy ? null : () => _decide(true, always: true),
              child: Text(l10n.alwaysAllow),
            ),
            FilledButton(key: const Key('approve'), onPressed: _busy ? null : () => _decide(true), child: Text(l10n.approve)),
          ]),
        ]),
      ),
    );
  }
}

/// Deep link target for /approvals/:id (push notifications open this).
class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key, required this.approvalId});
  final String approvalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.approval)),
      body: AsyncView(
        value: ref.watch(approvalsProvider),
        onRetry: () => ref.invalidate(approvalsProvider),
        data: (items) {
          final match = items.where((a) => a.id == approvalId);
          if (match.isEmpty) {
            return EmptyState(
              icon: Icons.task_alt,
              message: l10n.approvalAlreadyDecided,
              action: OutlinedButton(onPressed: () => context.go('/inbox'), child: Text(l10n.openInbox)),
            );
          }
          return ListView(padding: const EdgeInsets.all(12), children: [ApprovalCard(approval: match.first)]);
        },
      ),
    );
  }
}

class NotificationsList extends ConsumerWidget {
  const NotificationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(notificationsProvider);
    final hasUnread = (value.value ?? const <NotificationView>[]).any((n) => n.readAt == null);
    return AsyncView(
      value: value,
      onRetry: () => ref.invalidate(notificationsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(icon: Icons.notifications_none, message: l10n.noNotifications)
          : Column(children: [
              if (hasUnread)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => runGuarded(context, ref.read(notificationsProvider.notifier).markAllRead),
                    child: Text(l10n.markAllRead),
                  ),
                ),
              Expanded(
                child: ListView(children: [
                  for (final n in items)
                    ListTile(
                      key: Key('notification-${n.id}'),
                      leading: Icon(
                        switch (n.kind) {
                          'approval' => Icons.verified_user_outlined,
                          'routine' || 'routine_result' => Icons.schedule,
                          'budget' => Icons.payments_outlined,
                          _ => Icons.notifications_outlined,
                        },
                        color: n.readAt == null ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: Text(n.title, style: n.readAt == null ? const TextStyle(fontWeight: FontWeight.w600) : null),
                      subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(relativeTime(n.createdAt, context), style: Theme.of(context).textTheme.bodySmall),
                      onTap: n.link == null || !n.link!.startsWith('/') ? null : () => context.go(n.link!),
                    ),
                ]),
              ),
            ]),
    );
  }
}

/// The shared task board bots and people use to hand work around.
class TaskBoard extends ConsumerWidget {
  const TaskBoard({super.key});

  static const statuses = ['todo', 'doing', 'blocked', 'done'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    String label(String s) => switch (s) {
          'todo' => l10n.taskTodo,
          'doing' => l10n.taskDoing,
          'blocked' => l10n.taskBlocked,
          _ => l10n.taskDone,
        };
    return AsyncView(
      value: ref.watch(tasksProvider),
      onRetry: () => ref.invalidate(tasksProvider),
      data: (items) => items.isEmpty
          ? EmptyState(icon: Icons.view_kanban_outlined, message: l10n.noTasks)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(tasksProvider),
              child: ListView(children: [
                for (final s in statuses)
                  if (items.any((t) => t.status.value == s)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(label(s), style: Theme.of(context).textTheme.titleSmall),
                    ),
                    for (final t in items.where((t) => t.status.value == s))
                      ListTile(
                        key: Key('task-${t.id}'),
                        title: Text(t.title),
                        subtitle: Text([
                          if (t.assigneeBotId != null) ref.watch(botProvider(t.assigneeBotId!))?.name ?? l10n.aBot,
                          relativeTime(t.updatedAt, context),
                        ].join(' · ')),
                        trailing: PopupMenuButton<String>(
                          key: Key('taskStatus-${t.id}'),
                          tooltip: l10n.changeStatus,
                          initialValue: t.status.value,
                          onSelected: (v) async {
                            await runGuarded(context, () => ref.read(backendProvider).setTaskStatus(t.id, v));
                            ref.invalidate(tasksProvider);
                          },
                          itemBuilder: (_) => [for (final s in statuses) PopupMenuItem(value: s, child: Text(label(s)))],
                          child: Chip(label: Text(label(t.status.value))),
                        ),
                      ),
                  ],
              ]),
            ),
    );
  }
}

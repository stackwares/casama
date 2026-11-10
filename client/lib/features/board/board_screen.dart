import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// The ticket board (D-098): one column per status, drag to move, filters, and a ticket sheet.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  static const statuses = [TaskStatus.todo, TaskStatus.inProgress, TaskStatus.inReview, TaskStatus.blocked, TaskStatus.done];

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

enum _Owner { all, mine, bots }

String statusLabel(BuildContext context, TaskStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    TaskStatus.todo => l10n.taskTodo,
    TaskStatus.inProgress => l10n.taskDoing,
    TaskStatus.inReview => l10n.taskInReview,
    TaskStatus.blocked => l10n.taskBlocked,
    TaskStatus.done => l10n.taskDone,
  };
}

String priorityLabel(BuildContext context, TaskPriority p) {
  final l10n = context.l10n;
  return switch (p) {
    TaskPriority.urgent => l10n.priorityUrgent,
    TaskPriority.high => l10n.priorityHigh,
    TaskPriority.medium => l10n.priorityMedium,
    TaskPriority.low => l10n.priorityLow,
    TaskPriority.none => l10n.priorityNone,
  };
}

Color _statusColor(BuildContext context, TaskStatus s) {
  final colors = context.appColors;
  return switch (s) {
    TaskStatus.todo => context.colorScheme.onSurfaceVariant,
    TaskStatus.inProgress => colors.working,
    TaskStatus.inReview => colors.waiting,
    TaskStatus.blocked => colors.negative,
    TaskStatus.done => colors.positive,
  };
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  var _owner = _Owner.all;
  TaskPriority? _priority;

  bool _keep(Task t, String? me) {
    if (_owner == _Owner.mine && t.assigneeUserId != me) return false;
    if (_owner == _Owner.bots && t.assigneeBotId == null) return false;
    if (_priority != null && t.priority != _priority) return false;
    return true;
  }

  Future<void> _move(Task t, TaskStatus to, List<Task> column) async {
    if (t.status == to) return;
    // New arrivals go to the bottom of the column.
    final position = column.isEmpty ? 1.0 : column.map((x) => x.position.toDouble()).reduce((a, b) => a > b ? a : b) + 1;
    await runGuarded(context, () => ref.read(backendProvider).updateTask(t.id, status: to.value, position: position));
    ref.invalidate(tasksProvider);
  }

  Future<void> _newTicket() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final created = await showAdaptiveSheet<bool>(context: context, builder: (_) => _TicketForm(orgId: org.id));
    if (created == true) ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(backendProvider).userId;
    return SubPage(
      title: l10n.board,
      actions: [
        IconButton(key: const Key('openProjects'), tooltip: l10n.projects, icon: const Icon(LucideIcons.target), onPressed: () => context.push('/projects')),
        IconButton(key: const Key('newTicket'), tooltip: l10n.newTicket, icon: const Icon(LucideIcons.plus), onPressed: _newTicket),
      ],
      maxWidth: double.infinity,
      body: AsyncView(
        value: ref.watch(tasksProvider),
        onRetry: () => ref.invalidate(tasksProvider),
        data: (items) {
          final shown = items.where((t) => _keep(t, me)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final (o, label) in [(_Owner.all, l10n.filterAll), (_Owner.mine, l10n.filterMine), (_Owner.bots, l10n.filterBots)])
                      ChoiceChip(key: Key('filter-${o.name}'), label: Text(label), selected: _owner == o, onSelected: (_) => setState(() => _owner = o)),
                    DropdownButton<TaskPriority?>(
                      key: const Key('filterPriority'),
                      value: _priority,
                      hint: Text(l10n.priority),
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<TaskPriority?>(value: null, child: Text(l10n.priority)),
                        for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p))),
                      ],
                      onChanged: (p) => setState(() => _priority = p),
                    ),
                  ],
                ),
              ),
              if (items.isEmpty)
                Expanded(child: EmptyState(icon: LucideIcons.squareKanban, title: l10n.noTickets, message: l10n.noTicketsHelp))
              else
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    children: [
                      for (final s in BoardScreen.statuses)
                        _Column(
                          status: s,
                          tasks: (shown.where((t) => t.status == s).toList()..sort((a, b) => a.position.compareTo(b.position))),
                          onDrop: (t) => _move(t, s, shown.where((x) => x.status == s).toList()),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({required this.status, required this.tasks, required this.onDrop});
  final TaskStatus status;
  final List<Task> tasks;
  final void Function(Task) onDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(context, status);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Container(
        key: Key('column-${status.value}'),
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? color.withValues(alpha: 0.10) : context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xs, AppSpace.xs, AppSpace.sm),
              child: Row(
                children: [
                  Icon(LucideIcons.circleDot, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(statusLabel(context, status), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  Text('${tasks.length}', style: context.textTheme.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final t in tasks)
                    LongPressDraggable<Task>(
                      data: t,
                      delay: const Duration(milliseconds: 150),
                      feedback: Material(color: Colors.transparent, child: SizedBox(width: 260, child: _Card(task: t))),
                      childWhenDragging: Opacity(opacity: 0.35, child: _Card(task: t)),
                      child: _Card(task: t),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bot = task.assigneeBotId == null ? null : ref.watch(botProvider(task.assigneeBotId!));
    final me = ref.watch(backendProvider).userId;
    return Card(
      key: Key('ticket-${task.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => TicketSheet(taskId: task.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(task.title, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (task.priority != TaskPriority.none)
                    StatusLabel(text: priorityLabel(context, task.priority), color: task.priority == TaskPriority.urgent ? context.appColors.negative : context.colorScheme.primary, pill: true),
                  if (bot != null) StatusLabel(text: bot.name, color: context.appColors.working, pill: true),
                  if (task.assigneeUserId != null && task.assigneeUserId == me) StatusLabel(text: l10n.assignToMe, color: context.colorScheme.secondary, pill: true),
                  if (task.comments > 0) Text('💬 ${task.comments}', style: context.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketForm extends ConsumerStatefulWidget {
  const _TicketForm({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends ConsumerState<_TicketForm> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  var _priority = TaskPriority.none;
  String? _bot;
  var _review = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return FormSheet(
      icon: LucideIcons.squareKanban,
      title: l10n.newTicket,
      submitLabel: l10n.newTicket,
      submitKey: const Key('createTicket'),
      onSubmit: () async {
        if (_title.text.trim().isEmpty) return;
        final ok = await runGuarded(
          context,
          () => ref.read(backendProvider).createTask(
                widget.orgId,
                title: _title.text.trim(),
                details: _details.text.trim(),
                priority: _priority.value,
                assigneeBotId: _bot,
                reviewRequired: _review,
              ),
        );
        if (ok != null && context.mounted) Navigator.pop(context, true);
      },
      children: [
        TextField(key: const Key('ticketTitle'), controller: _title, decoration: InputDecoration(labelText: l10n.ticketTitle)),
        TextField(key: const Key('ticketDetails'), controller: _details, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.ticketDetails)),
        DropdownButtonFormField<TaskPriority>(
          initialValue: _priority,
          decoration: InputDecoration(labelText: l10n.priority),
          items: [for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p)))],
          onChanged: (p) => setState(() => _priority = p ?? _priority),
        ),
        DropdownButtonFormField<String?>(
          key: const Key('ticketBot'),
          initialValue: _bot,
          decoration: InputDecoration(labelText: l10n.assignee),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.unassigned)),
            for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => setState(() => _bot = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reviewRequired),
          subtitle: Text(l10n.reviewRequiredHelp),
          value: _review,
          onChanged: (v) => setState(() => _review = v),
        ),
      ],
    );
  }
}

final _commentsProvider = FutureProvider.family<List<TaskComment>, String>((ref, id) => ref.watch(backendProvider).taskComments(id));

/// One ticket: status, priority, assignment, comments and the bot's thread.
class TicketSheet extends ConsumerStatefulWidget {
  const TicketSheet({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<TicketSheet> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _update({String? status, String? priority, String? bot, bool? review, String? user}) async {
    await runGuarded(
      context,
      () => ref.read(backendProvider).updateTask(widget.taskId, status: status, priority: priority, assigneeBotId: bot, reviewRequired: review, assigneeUserId: user),
    );
    ref.invalidate(tasksProvider);
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final ok = await runGuarded(context, () => ref.read(backendProvider).addTaskComment(widget.taskId, text));
    if (ok == null) return;
    _comment.clear();
    ref.invalidate(_commentsProvider(widget.taskId));
    ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = ref.watch(tasksProvider).value?.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final comments = ref.watch(_commentsProvider(widget.taskId)).value ?? const <TaskComment>[];
    final me = ref.watch(backendProvider).userId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(task.title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (task.detailsMd.isNotEmpty) Text(task.detailsMd),
          if (task.resultMd != null) AppCard(child: Text(task.resultMd!)),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TaskStatus>(
                  key: const Key('sheetStatus'),
                  isExpanded: true,
                  initialValue: task.status,
                  decoration: InputDecoration(labelText: l10n.ticketStatus),
                  items: [for (final s in BoardScreen.statuses) DropdownMenuItem(value: s, child: Text(statusLabel(context, s)))],
                  onChanged: (s) => s == null ? null : _update(status: s.value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TaskPriority>(
                  isExpanded: true,
                  initialValue: task.priority,
                  decoration: InputDecoration(labelText: l10n.priority),
                  items: [for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p)))],
                  onChanged: (p) => p == null ? null : _update(priority: p.value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  key: const Key('sheetBot'),
                  isExpanded: true,
                  initialValue: task.assigneeBotId,
                  decoration: InputDecoration(labelText: l10n.assignee),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.unassigned)),
                    for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ],
                  onChanged: (v) => v == null ? null : _update(bot: v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (me != null && task.assigneeUserId != me)
                TextButton.icon(onPressed: () => _update(user: me), icon: const Icon(LucideIcons.user, size: 18), label: Text(l10n.assignToMe)),
              const Spacer(),
              if (task.assigneeBotId != null && task.conversationId != null)
                TextButton.icon(
                  key: const Key('openThread'),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                    context.go('/bots/${task.assigneeBotId}/chat');
                  },
                  icon: const Icon(LucideIcons.messageCircle, size: 18),
                  label: Text(l10n.openThread),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reviewRequired),
            value: task.reviewRequired,
            onChanged: (v) => _update(review: v),
          ),
          SectionHeader(title: l10n.comments),
          for (final c in comments)
            ListTile(
              key: Key('comment-${c.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(c.authorType == TaskCommentAuthorTypeEnum.bot ? LucideIcons.bot : LucideIcons.user, size: 20),
              title: Text(c.bodyMd),
              subtitle: Text(
                c.authorType == TaskCommentAuthorTypeEnum.bot
                    ? (bots.where((b) => b.id == c.authorBotId).firstOrNull?.name ?? l10n.aBot)
                    : (c.authorUserId == me ? l10n.assignToMe : ''),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('commentField'),
                  controller: _comment,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: l10n.addComment),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(key: const Key('sendComment'), tooltip: l10n.sendComment, icon: const Icon(LucideIcons.send), onPressed: _send),
            ],
          ),
          TextButton.icon(
            key: const Key('deleteTicket'),
            style: TextButton.styleFrom(foregroundColor: context.appColors.negative),
            onPressed: () async {
              final ok = await showConfirm(context: context, title: l10n.deleteTicket, confirmLabel: l10n.deleteTicket, destructive: true);
              if (!ok || !context.mounted) return;
              await runGuarded(context, () => ref.read(backendProvider).deleteTask(widget.taskId));
              ref.invalidate(tasksProvider);
              if (context.mounted) Navigator.of(context).maybePop();
            },
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text(l10n.deleteTicket),
          ),
        ],
      ),
    );
  }
}

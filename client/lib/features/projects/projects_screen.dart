import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../chat/widgets/chat_markdown.dart';

/// Projects (D-113): a goal the lead bot plans and works in sessions until it's met.

final projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).projects(org.id);
});
final projectProvider = FutureProvider.autoDispose.family<ProjectDetail, String>((ref, id) => ref.watch(backendProvider).project(id));
final projectTasksProvider = FutureProvider.autoDispose.family<List<Task>, String>((ref, id) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).tasks(org.id, projectId: id);
});

String projectStatusLabel(BuildContext context, ProjectStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    ProjectStatus.planning => l10n.projectPlanning,
    ProjectStatus.active => l10n.projectActive,
    ProjectStatus.paused => l10n.projectPaused,
    ProjectStatus.blocked => l10n.projectBlocked,
    ProjectStatus.done => l10n.projectDone,
    ProjectStatus.cancelled => l10n.projectCancelled,
  };
}

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.projects,
      actions: [IconButton(key: const Key('newProject'), tooltip: l10n.newProject, icon: const Icon(LucideIcons.plus), onPressed: () => showNewProject(context, ref))],
      body: AsyncView(
        value: ref.watch(projectsProvider),
        onRetry: () => ref.invalidate(projectsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.target,
                title: l10n.noProjects,
                message: l10n.projectsHelp,
                action: GlowButton.icon(onPressed: () => showNewProject(context, ref), icon: const Icon(LucideIcons.plus, size: 18), label: Text(l10n.newProject)),
              )
            : PageColumn(
                children: [
                  GroupedCard(
                    children: [
                      for (final p in items)
                        GroupedTile(
                          key: Key('project-${p.id}'),
                          icon: LucideIcons.target,
                          title: p.title,
                          subtitle: [
                            projectStatusLabel(context, p.status),
                            if (p.budgetUsd != null) '${formatUsd(p.spentUsd)} / ${formatUsd(p.budgetUsd!)}' else formatUsd(p.spentUsd),
                          ].join(' · '),
                          onTap: () => context.push('/projects/${p.id}'),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

Future<void> showNewProject(BuildContext context, WidgetRef ref) async {
  final id = await showAdaptiveSheet<String>(context: context, dialogMaxWidth: 640, builder: (_) => const _NewProject());
  ref.invalidate(projectsProvider);
  if (id != null && context.mounted) GoRouter.maybeOf(context)?.push('/projects/$id');
}

class _NewProject extends ConsumerStatefulWidget {
  const _NewProject();

  @override
  ConsumerState<_NewProject> createState() => _NewProjectState();
}

class _NewProjectState extends ConsumerState<_NewProject> {
  final _title = TextEditingController();
  final _goal = TextEditingController();
  final _done = TextEditingController();
  final _budget = TextEditingController();
  String? _lead;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _done.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    _lead ??= bots.firstOrNull?.id;
    final valid = _title.text.trim().isNotEmpty && _goal.text.trim().isNotEmpty && _lead != null;
    return FormSheet(
      icon: LucideIcons.target,
      title: l10n.newProject,
      subtitle: l10n.newProjectHelp,
      submitLabel: l10n.startPlanning,
      submitKey: const Key('createProject'),
      onSubmit: !valid || _busy
          ? null
          : () async {
              final org = ref.read(currentOrgProvider);
              if (org == null) return;
              setState(() => _busy = true);
              final p = await runGuarded(
                context,
                () => ref.read(backendProvider).createProject(
                      org.id,
                      title: _title.text.trim(),
                      goal: _goal.text.trim(),
                      doneCriteria: _done.text.trim(),
                      leadBotId: _lead!,
                      budgetUsd: double.tryParse(_budget.text.trim()),
                    ),
              );
              if (!context.mounted) return;
              setState(() => _busy = false);
              if (p != null) Navigator.pop(context, p.id);
            },
      children: [
        TextField(key: const Key('projectTitle'), controller: _title, autofocus: true, decoration: InputDecoration(labelText: l10n.projectTitle), onChanged: (_) => setState(() {})),
        TextField(key: const Key('projectGoal'), controller: _goal, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.projectGoal), onChanged: (_) => setState(() {})),
        TextField(key: const Key('projectDone'), controller: _done, minLines: 1, maxLines: 4, decoration: InputDecoration(labelText: l10n.projectDoneWhen)),
        DropdownButtonFormField<String>(
          key: const Key('projectLead'),
          initialValue: _lead,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.projectLead),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: (v) => setState(() => _lead = v),
        ),
        TextField(
          key: const Key('projectBudget'),
          controller: _budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.projectBudget, prefixText: r'$ '),
        ),
      ],
    );
  }
}

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});
  final String projectId;

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() f) async {
    await runGuarded(context, f);
    ref
      ..invalidate(projectProvider(projectId))
      ..invalidate(projectsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final backend = ref.read(backendProvider);
    return AsyncView(
      value: ref.watch(projectProvider(projectId)),
      onRetry: () => ref.invalidate(projectProvider(projectId)),
      data: (p) {
        final tickets = ref.watch(projectTasksProvider(projectId)).value ?? const <Task>[];
        final budget = p.budgetUsd;
        return SubPage(
          title: p.title,
          subtitle: projectStatusLabel(context, p.status),
          actions: [
            if (p.conversationId != null)
              IconButton(
                key: const Key('projectThread'),
                tooltip: l10n.projectThread,
                icon: const Icon(LucideIcons.messagesSquare),
                onPressed: () => context.push('/bots/${p.leadBotId}/chat?c=${p.conversationId}'),
              ),
          ],
          children: [
            if (p.statusReason != null) FormNote(p.statusReason!, icon: LucideIcons.info),
            if (p.planStatus == ProjectDetailPlanStatusEnum.proposed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: GlowButton.icon(
                  key: const Key('approvePlan'),
                  onPressed: () => _act(context, ref, () => backend.approveProjectPlan(projectId)),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: Text(l10n.approvePlan),
                ),
              ),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                if (p.status == ProjectStatus.active)
                  OutlinedButton.icon(
                    key: const Key('pauseProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'paused')),
                    icon: const Icon(LucideIcons.pause, size: 18),
                    label: Text(l10n.pause),
                  ),
                if ((p.status == ProjectStatus.paused || p.status == ProjectStatus.blocked) && p.planStatus == ProjectDetailPlanStatusEnum.approved)
                  OutlinedButton.icon(
                    key: const Key('resumeProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'active')),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: Text(l10n.resume),
                  ),
              ],
            ),
            SectionHeader(title: l10n.projectGoal),
            AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.goalMd)),
            if (budget != null) ...[
              SectionHeader(title: l10n.projectBudget),
              LinearProgressIndicator(key: const Key('projectSpend'), value: (p.spentUsd / budget).clamp(0, 1).toDouble()),
              const SizedBox(height: AppSpace.xs),
              Text('${formatUsd(p.spentUsd)} / ${formatUsd(budget)}'),
            ],
            SectionHeader(title: l10n.milestones),
            GroupedCard(
              children: [
                for (final m in p.milestones)
                  GroupedTile(
                    key: Key('milestone-${m.id}'),
                    icon: m.status == ProjectMilestoneStatusEnum.done ? LucideIcons.circleCheck : LucideIcons.flag,
                    iconColor: m.status == ProjectMilestoneStatusEnum.done ? colors.positive : null,
                    title: m.name,
                    subtitle: '${m.ticketsDone}/${m.ticketsTotal}${m.requiresSignoff ? ' · ${l10n.needsSignoff}' : ''}',
                    trailing: m.status == ProjectMilestoneStatusEnum.awaitingSignoff
                        ? TextButton(
                            key: Key('signoff-${m.id}'),
                            onPressed: () => _act(context, ref, () => backend.signOffMilestone(projectId, m.id)),
                            child: Text(l10n.signOff),
                          )
                        : null,
                  ),
              ],
            ),
            if (p.planMd.isNotEmpty) ...[
              SectionHeader(title: l10n.projectPlan),
              AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.planMd)),
            ],
            SectionHeader(title: l10n.tickets),
            GroupedCard(
              children: [
                for (final t in tickets)
                  GroupedTile(
                    icon: t.status == TaskStatus.done ? LucideIcons.circleCheck : LucideIcons.circle,
                    title: t.title,
                    subtitle: t.status.value,
                    onTap: () => context.push('/tasks'),
                  ),
              ],
            ),
            SectionHeader(title: l10n.projectTimeline),
            GroupedCard(
              children: [
                for (final r in p.runs)
                  GroupedTile(
                    icon: LucideIcons.activity,
                    title: '${r.trigger} · ${r.status}',
                    subtitle: '${formatUsd(r.costUsd)} · ${relativeTime(r.createdAt, context)}',
                    onTap: () => context.push('/bots/${r.botId}/runs/${r.id}'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

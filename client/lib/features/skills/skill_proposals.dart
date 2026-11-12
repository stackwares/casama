import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../chat/widgets/chat_markdown.dart';

/// Self-improving skills (D-126): skills and edits bots proposed, waiting for the owner.
final skillProposalsProvider = FutureProvider.autoDispose<List<SkillProposal>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).skillProposals(org.id);
});

/// Uses, success rate and history of one skill; held here so the sheet does not refetch on every rebuild.
final skillStatsProvider = FutureProvider.autoDispose.family<SkillStats, String>((ref, skillId) => ref.watch(backendProvider).skillStats(skillId));

/// A line diff: unchanged lines, removed ("-") and added ("+"), by longest common subsequence.
List<(String, String)> lineDiff(String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      dp[i][j] = a[i] == b[j] ? dp[i + 1][j + 1] + 1 : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final out = <(String, String)>[];
  var i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      out.add((' ', a[i]));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.add(('-', a[i++]));
    } else {
      out.add(('+', b[j++]));
    }
  }
  while (i < a.length) {
    out.add(('-', a[i++]));
  }
  while (j < b.length) {
    out.add(('+', b[j++]));
  }
  return out;
}

class SkillProposalCard extends ConsumerWidget {
  const SkillProposalCard({super.key, required this.proposal, required this.botName});
  final SkillProposal proposal;
  final String botName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = proposal;
    final backend = ref.read(backendProvider);
    final isEdit = p.kind == SkillProposalKindEnum.edit;
    final mono = TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: context.colorScheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        key: Key('proposal-${p.id}'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.sm,
          children: [
            Row(children: [
              Icon(isEdit ? LucideIcons.filePen : LucideIcons.sparkles, size: 18, color: context.colorScheme.primary),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(isEdit ? l10n.skillEditFrom(botName, p.name) : l10n.skillIdeaFrom(botName, p.name), style: context.textTheme.titleSmall)),
            ]),
            Text(p.description),
            if (p.reason.isNotEmpty) Text(p.reason, style: context.textTheme.bodySmall),
            if (isEdit && p.previousBodyMd != null)
              Container(
                key: Key('diff-${p.id}'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.sm),
                decoration: BoxDecoration(color: context.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.row)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (op, line) in lineDiff(p.previousBodyMd!, p.bodyMd))
                      Container(
                        color: switch (op) {
                          '-' => context.colorScheme.error.withValues(alpha: 0.12),
                          '+' => context.appColors.positive.withValues(alpha: 0.14),
                          _ => null,
                        },
                        child: Text('$op $line', style: mono),
                      ),
                  ],
                ),
              )
            else ...[
              ChatMarkdown(data: p.bodyMd),
              if (p.tools.isNotEmpty) Text(l10n.skillUsesTools(p.tools.join(', ')), style: context.textTheme.bodySmall),
            ],
            Row(children: [
              FilledButton(
                key: Key('acceptProposal-${p.id}'),
                onPressed: () async {
                  await runGuarded(context, () => backend.acceptSkillProposal(p.id));
                  ref.invalidate(skillProposalsProvider);
                  if (context.mounted) showSuccess(context, isEdit ? l10n.skillUpdated(p.name) : l10n.skillSaved(p.name));
                },
                child: Text(isEdit ? l10n.applyEdit : l10n.saveSkill),
              ),
              const SizedBox(width: AppSpace.sm),
              TextButton(
                key: Key('dismissProposal-${p.id}'),
                onPressed: () async {
                  await runGuarded(context, () => backend.dismissSkillProposal(p.id));
                  ref.invalidate(skillProposalsProvider);
                },
                child: Text(l10n.dismiss),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Uses, success rate, last failure and history of one skill.
class SkillStatsSheet extends ConsumerWidget {
  const SkillStatsSheet({super.key, required this.skillId, required this.name});
  final String skillId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(skillStatsProvider(skillId));
    return Builder(
      builder: (context) {
        final s = stats.value;
        return FormSheet(
          icon: LucideIcons.chartColumn,
          title: name,
          submitLabel: l10n.close,
          onSubmit: () async => Navigator.pop(context),
          children: [
            if (s == null)
              AsyncView<SkillStats>(value: stats, onRetry: () => ref.invalidate(skillStatsProvider(skillId)), data: (_) => const SizedBox.shrink())
            else ...[
              Text(
                key: const Key('skillStatsLine'),
                s.uses == 0 ? l10n.skillNotUsedYet : l10n.skillStatsLine(s.uses, ((s.successRate ?? 0) * 100).round(), s.failures, s.corrections),
              ),
              if (s.lastFailureAt != null) Text(l10n.skillLastFailure(s.lastFailureAt!.toLocal().formattedDate(context))),
              if (s.revisions.isNotEmpty) Text(l10n.skillHistory, style: context.textTheme.labelLarge),
              for (final r in s.revisions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(r.byBot ? LucideIcons.bot : LucideIcons.user, size: 18),
                  title: Text(r.createdAt.toLocal().formattedDate(context)),
                  subtitle: Text(r.bodyMd, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
            ],
          ],
        );
      },
    );
  }
}

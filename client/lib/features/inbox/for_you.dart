import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../chat/widgets/chat_markdown.dart';

/// The "For you" feed (D-114): the latest morning briefs, pending suggestions and approvals.
final forYouProvider = FutureProvider.autoDispose<ForYou>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return ForYou(briefs: const [], suggestions: const [], approvals: const []);
  return ref.watch(backendProvider).forYou(org.id);
});

class ForYouList extends ConsumerWidget {
  const ForYouList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    Bot? bot(String id) => bots.where((b) => b.id == id).firstOrNull;
    return AsyncView(
      value: ref.watch(forYouProvider),
      onRetry: () => ref.invalidate(forYouProvider),
      data: (f) {
        if (f.briefs.isEmpty && f.suggestions.isEmpty && f.approvals.isEmpty) {
          return EmptyState(icon: LucideIcons.sun, title: l10n.forYouEmpty, message: l10n.forYouEmptyHelp);
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            for (final b in f.briefs)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: AppCard(
                  key: Key('brief-${b.botId}'),
                  onTap: () => context.go('/bots/${b.botId}/chat?c=${b.conversationId}'),
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpace.sm,
                    children: [
                      Row(children: [
                        BotAvatar(name: bot(b.botId)?.name ?? '', avatar: bot(b.botId)?.avatarUrl, size: 28),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(child: Text(l10n.morningBriefFrom(bot(b.botId)?.name ?? ''), style: context.textTheme.titleSmall)),
                        Text(relativeTime(b.createdAt, context), style: context.textTheme.labelSmall),
                      ]),
                      ChatMarkdown(data: b.text),
                    ],
                  ),
                ),
              ),
            if (f.suggestions.isNotEmpty) SectionHeader(title: l10n.suggestions),
            for (final s in f.suggestions) _SuggestionCard(s: s, botName: bot(s.botId)?.name ?? ''),
            if (f.approvals.isNotEmpty) SectionHeader(title: l10n.approvals),
            for (final a in f.approvals)
              ListTile(
                key: Key('forYouApproval-${a.id}'),
                leading: const Icon(LucideIcons.shieldAlert),
                title: Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.push('/approvals/${a.id}'),
              ),
          ],
        );
      },
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.s, required this.botName});
  final Suggestion s;
  final String botName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        key: Key('suggestion-${s.id}'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.xs,
          children: [
            Row(children: [
              Icon(s.urgency == SuggestionUrgencyEnum.urgent ? LucideIcons.zap : LucideIcons.lightbulb, size: 18, color: s.urgency == SuggestionUrgencyEnum.urgent ? colors.warning : null),
              const SizedBox(width: AppSpace.xs),
              Expanded(child: Text(s.title, style: context.textTheme.titleSmall)),
            ]),
            if (s.bodyMd.isNotEmpty) Text(s.bodyMd),
            Text(l10n.suggestedBy(botName), style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: Key('dismiss-${s.id}'),
                  onPressed: () async {
                    final never = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: Text(l10n.dismissSuggestion),
                        actions: [
                          TextButton(key: const Key('dismissOnce'), onPressed: () => Navigator.pop(d, false), child: Text(l10n.justThisOnce)),
                          TextButton(key: const Key('dismissNever'), onPressed: () => Navigator.pop(d, true), child: Text(l10n.dontSuggestAgain)),
                        ],
                      ),
                    );
                    if (never == null || !context.mounted) return;
                    await runGuarded(context, () => ref.read(backendProvider).dismissSuggestion(s.id, dontSuggestAgain: never));
                    ref.invalidate(forYouProvider);
                  },
                  child: Text(l10n.dismiss),
                ),
                FilledButton.tonal(
                  key: Key('accept-${s.id}'),
                  onPressed: () async {
                    final r = await runGuarded(context, () => ref.read(backendProvider).acceptSuggestion(s.id));
                    ref.invalidate(forYouProvider);
                    if (r != null && context.mounted) GoRouter.maybeOf(context)?.go('/bots/${s.botId}/chat?c=${r.conversationId}');
                  },
                  child: Text(l10n.doIt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../chat/widgets/chat_markdown.dart';

/// The "For you" feed (D-114): the latest morning briefs, pending suggestions and approvals,
/// shown in the Inbox.
// Kept when the Inbox closes, so it opens with what it showed; the Inbox refreshes it as it opens.
final forYouProvider = FutureProvider<ForYou>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return ForYou(briefs: const [], suggestions: const [], approvals: const []);
  return ref.watch(backendProvider).forYou(org.id);
});

/// A morning brief (D-114): opens the conversation it was posted in.
class BriefCard extends ConsumerWidget {
  const BriefCard({super.key, required this.brief});
  final ForYouBrief brief;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final b = brief;
    final bot = (ref.watch(botsProvider).value ?? const <Bot>[]).where((x) => x.id == b.botId).firstOrNull;
    return AppCard(
      key: Key('brief-${b.botId}'),
      onTap: () => context.push('/bots/${b.botId}/chat?c=${b.conversationId}'),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.sm,
        children: [
          Row(children: [
            BotAvatar(name: bot?.name ?? '', avatar: bot?.avatarUrl, size: 28),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(l10n.morningBriefFrom(bot?.name ?? ''), style: context.textTheme.titleSmall)),
            Text(relativeTime(b.createdAt, context), style: context.textTheme.labelSmall),
          ]),
          ChatMarkdown(data: b.text),
        ],
      ),
    );
  }
}

/// A suggestion from a bot (D-114): do it, or dismiss it once or for good.
class SuggestionCard extends ConsumerWidget {
  const SuggestionCard({super.key, required this.s, required this.botName});
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
                    if (r != null && context.mounted) GoRouter.maybeOf(context)?.push('/bots/${s.botId}/chat?c=${r.conversationId}');
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

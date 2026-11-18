import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/haptics.dart';
import '../../../core/number_format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/adaptive_modal.dart';
import '../chat_controller.dart';

/// What one finished run cost (D-307). A finished run's usage doesn't change, so it is kept; one
/// still going is asked again next time.
final runUsageProvider = FutureProvider.autoDispose.family<RunUsage, String>((
  ref,
  runId,
) async {
  final usage = await ref.watch(backendProvider).runUsage(runId);
  if (const {
    RunStatus.completed,
    RunStatus.failed,
    RunStatus.cancelled,
  }.contains(usage.status)) {
    ref.keepAlive();
  }
  return usage;
});

/// The small line under a run's last reply when "Show usage on replies" is on (D-307):
/// `$0.04 · 18k tokens · 32s`. It counts up while the run goes; tap it for the breakdown.
class ReplyUsageLine extends ConsumerWidget {
  const ReplyUsageLine({super.key, required this.runId, required this.botId});
  final String runId;
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.l10n.localeName;
    // While this run goes, the chat's usage events are the live numbers.
    final live = ref.watch(
      chatControllerProvider(botId)
          .select((s) => s.activeRunId == runId ? (s.costUsd, s.tokens) : null),
    );
    final String? text;
    if (live != null) {
      text = [
        context.l10n.replyUsageSoFar(formatUsd(live.$1, locale)),
        if (live.$2 > 0)
          context.l10n.replyUsageTokens(live.$2.humanizedCompact(locale)),
      ].join(' · ');
    } else {
      text = switch (ref.watch(runUsageProvider(runId))) {
        AsyncData(:final value) => replyUsageSummary(context, value),
        _ => null,
      };
    }
    if (text == null) return const SizedBox(height: 18);
    final scheme = context.colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: context.l10n.replyUsageTooltip,
        child: InkWell(
          key: Key('replyUsage-$runId'),
          borderRadius: BorderRadius.circular(AppRadius.icon),
          onTap: () {
            HapticsHelper.light();
            showAdaptiveSheet<void>(
              context: context,
              builder: (_) => ReplyUsageSheet(runId: runId, botId: botId),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xs,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(
                  LucideIcons.gauge,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: AppText.tabular,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-line summary: what came out of credits (or what your own keys spent), tokens, time.
String replyUsageSummary(BuildContext context, RunUsage u) {
  final l10n = context.l10n;
  final locale = l10n.localeName;
  final ownKeys = u.costUsd.toDouble() - u.chargedUsd.toDouble();
  final onPlan =
      u.items.isNotEmpty &&
      u.items.every(
        (i) => i.source_ == RunUsageItemsInnerSource_Enum.chatgptPlan,
      );
  final tokens = u.tokensIn + u.tokensOut;
  return [
    // Credits first: that's what Casama charges. Own keys are shown when that's all there was.
    if (u.chargedUsd > 0 || (ownKeys <= 0 && !onPlan))
      formatUsd(u.chargedUsd, locale),
    if (ownKeys > 0) l10n.replyUsageOnYourKeys(formatUsd(ownKeys, locale)),
    if (onPlan) l10n.replyUsageOnPlan,
    if (tokens > 0) l10n.replyUsageTokens(tokens.humanizedCompact(locale)),
    if (u.durationMs case final ms? when ms > 0)
      formatRunDuration(Duration(milliseconds: ms)),
  ].join(' · ');
}

/// 850 ms → "0.9s", 32 s → "32s", 2 min 5 s → "2m 5s", over an hour → "1h 4m".
String formatRunDuration(Duration d) {
  if (d.inSeconds < 10) {
    return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  if (d.inHours < 1) {
    return d.inSeconds % 60 == 0
        ? '${d.inMinutes}m'
        : '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
  return '${d.inHours}h ${d.inMinutes % 60}m';
}

/// The breakdown of one reply's cost (D-307): totals, then each thing that was metered.
class ReplyUsageSheet extends ConsumerWidget {
  const ReplyUsageSheet({super.key, required this.runId, required this.botId});
  final String runId;
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final usage = ref.watch(runUsageProvider(runId));
    final Widget body = switch (usage) {
      AsyncData(:final value) => _Breakdown(usage: value),
      AsyncError() => Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Text(
          l10n.replyUsageLoadFailed,
          key: const Key('replyUsageError'),
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpace.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
    return SingleChildScrollView(
      key: const Key('replyUsageSheet'),
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(
            l10n.replyUsageTitle,
            subtitle: switch (usage) {
              AsyncData(:final value) when value.subruns > 0 =>
                l10n.replyUsageHelpers(value.subruns),
              _ => null,
            },
          ),
          body,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.replyUsageCreditsNote,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                TextButton(
                  key: const Key('replyUsageOpenRun'),
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.pushOnce('/bots/$botId/runs/$runId');
                  },
                  child: Text(l10n.replyUsageOpenRun),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.usage});
  final RunUsage usage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final scheme = context.colorScheme;
    final u = usage;
    final ownKeys = u.costUsd.toDouble() - u.chargedUsd.toDouble();
    final tokens = u.tokensIn + u.tokensOut;
    Widget stat(String label, String value, {Key? key}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            key: key,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: AppText.tabular,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Row(
            children: [
              stat(
                l10n.replyUsageFromCredits,
                formatUsd(u.chargedUsd, locale),
                key: const Key('replyUsageCharged'),
              ),
              if (ownKeys > 0)
                stat(l10n.replyUsageYourKeys, formatUsd(ownKeys, locale)),
              if (tokens > 0)
                stat(
                  l10n.replyUsageTokensLabel,
                  tokens.humanizedCompact(locale),
                ),
              if (u.durationMs case final ms? when ms > 0)
                stat(
                  l10n.replyUsageTime,
                  formatRunDuration(Duration(milliseconds: ms)),
                ),
              if (u.toolCalls > 0)
                stat(l10n.replyUsageSteps, u.toolCalls.humanizedCount(locale)),
            ],
          ),
          // The server's own cost, only ever sent to whoever runs the server (D-395).
          if (u.upstreamCostUsd case final cost?)
            Row(
              key: const Key('replyUsageAdmin'),
              children: [
                stat(
                  l10n.replyUsageOurCost,
                  formatUsd(cost, locale),
                  key: const Key('replyUsageOurCost'),
                ),
                stat(
                  l10n.replyUsageMargin,
                  formatUsd(u.chargedUsd - cost, locale),
                  key: const Key('replyUsageMargin'),
                ),
                const Spacer(),
              ],
            ),
          if (u.items.isEmpty)
            Text(
              l10n.replyUsageNothing,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: AppRadius.tileAll,
              ),
              child: Column(
                children: [for (final i in u.items) _ItemRow(item: i)],
              ),
            ),
          if (u.upstreamCostUsd != null)
            Text(
              l10n.replyUsageAdminNote,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final RunUsageItemsInner item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final scheme = context.colorScheme;
    final i = item;
    final quantity = usageQuantity(context, i.kind, i.quantity);
    final detail = [
      ?i.model,
      ?quantity,
      if (i.source_ == RunUsageItemsInnerSource_Enum.chatgptPlan)
        l10n.replyUsageOnPlan
      else if (!i.billable)
        l10n.replyUsageYourKeys,
      if (i.upstreamCostUsd case final cost?)
        l10n.replyUsageItemCost(formatUsd(cost, locale)),
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: Icon(
        usageKindIcon(i.kind),
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(usageKindLabel(context, i.kind)),
      subtitle: detail.isEmpty
          ? null
          : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatUsd(i.costUsd, locale),
        style: context.textTheme.labelLarge?.copyWith(
          fontFeatures: AppText.tabular,
        ),
      ),
    );
  }
}

IconData usageKindIcon(String kind) => switch (kind) {
  'tokens_in' => LucideIcons.arrowDownToLine,
  'tokens_out' => LucideIcons.arrowUpFromLine,
  'computer_seconds' => LucideIcons.monitor,
  'stream_seconds' => LucideIcons.monitorPlay,
  'tts_chars' => LucideIcons.audioLines,
  'stt_seconds' => LucideIcons.mic,
  'voice_seconds' => LucideIcons.phone,
  'media_images' => LucideIcons.image,
  'media_video_seconds' => LucideIcons.video,
  'search_queries' => LucideIcons.search,
  'data_calls' => LucideIcons.database,
  'phone_minutes' => LucideIcons.phoneCall,
  'app_calls' => LucideIcons.puzzle,
  _ => LucideIcons.gauge,
};

String usageKindLabel(BuildContext context, String kind) {
  final l10n = context.l10n;
  return switch (kind) {
    'tokens_in' => l10n.kindTokensIn,
    'tokens_out' => l10n.kindTokensOut,
    'computer_seconds' => l10n.kindComputer,
    'stream_seconds' => l10n.kindStream,
    'tts_chars' => l10n.kindTts,
    'stt_seconds' => l10n.kindSpeechToText,
    'voice_seconds' => l10n.kindVoice,
    'media_images' => l10n.kindImages,
    'media_video_seconds' => l10n.kindVideo,
    'search_queries' => l10n.kindSearch,
    'data_calls' => l10n.kindData,
    'phone_minutes' => l10n.kindPhone,
    'app_calls' => l10n.kindApps,
    _ => kind,
  };
}

/// How much of [kind] was used, in the unit people know; null when the label says it all.
String? usageQuantity(BuildContext context, String kind, num q) {
  final locale = context.l10n.localeName;
  if (q <= 0) return null;
  return switch (kind) {
    'tokens_in' ||
    'tokens_out' => context.l10n.replyUsageTokens(q.humanizedCompact(locale)),
    'computer_seconds' ||
    'stream_seconds' ||
    'stt_seconds' ||
    'voice_seconds' ||
    'media_video_seconds' => formatRunDuration(
      Duration(milliseconds: (q * 1000).round()),
    ),
    'phone_minutes' => formatRunDuration(
      Duration(milliseconds: (q * 60000).round()),
    ),
    _ => q.humanizedCount(locale),
  };
}

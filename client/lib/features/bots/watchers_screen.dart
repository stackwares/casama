import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// A bot's watchers (D-116): what it's watching for, with pause, resume and delete. Bots create
/// them in chat ("tell me when…").
final watchersProvider = FutureProvider.autoDispose.family<List<Watcher>, String>((ref, botId) => ref.watch(backendProvider).watchers(botId));

class WatchersScreen extends ConsumerWidget {
  const WatchersScreen({super.key, required this.botId});
  final String botId;

  IconData _icon(WatcherKindEnum k) => switch (k) {
        WatcherKindEnum.pageChange => LucideIcons.globe,
        WatcherKindEnum.reply => LucideIcons.messageSquareReply,
        WatcherKindEnum.query => LucideIcons.database,
        _ => LucideIcons.alarmClock,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    Future<void> act(Future<void> Function() f) async {
      await runGuarded(context, f);
      ref.invalidate(watchersProvider(botId));
    }

    return SubPage(
      title: l10n.watchers,
      subtitle: ref.watch(botProvider(botId))?.name,
      body: AsyncView(
        value: ref.watch(watchersProvider(botId)),
        onRetry: () => ref.invalidate(watchersProvider(botId)),
        loading: const _WatchersSkeleton(),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.eye, title: l10n.noWatchers, message: l10n.watchersHelp)
            : PageColumn(
                children: [
                  FormNote(l10n.watchersHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final w in items)
                        GroupedTile(
                          key: Key('watcher-${w.id}'),
                          icon: _icon(w.kind),
                          title: w.name,
                          subtitle: [
                            switch (w.status) {
                              WatcherStatusEnum.active => l10n.watcherActive,
                              WatcherStatusEnum.paused => l10n.watcherPaused,
                              WatcherStatusEnum.done => l10n.watcherDone,
                              _ => l10n.watcherExpired,
                            },
                            l10n.firedTimes(w.firedCount),
                            if (w.lastError != null) w.lastError!,
                          ].join(' · '),
                          onTap: w.conversationId == null ? null : () => context.push('/bots/$botId/chat?c=${w.conversationId}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (w.status == WatcherStatusEnum.active || w.status == WatcherStatusEnum.paused)
                                IconButton(
                                  key: Key('toggle-${w.id}'),
                                  tooltip: w.status == WatcherStatusEnum.active ? l10n.pause : l10n.resume,
                                  icon: Icon(w.status == WatcherStatusEnum.active ? LucideIcons.pause : LucideIcons.play, size: 18),
                                  onPressed: () => act(() => backend.setWatcherPaused(w.id, w.status == WatcherStatusEnum.active)),
                                ),
                              IconButton(
                                key: Key('delete-${w.id}'),
                                tooltip: l10n.delete,
                                icon: const Icon(LucideIcons.trash2, size: 18),
                                onPressed: () => act(() => backend.deleteWatcher(w.id)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// The page while watchers load: the help note over a card of watcher rows, each with its pause
/// and delete buttons, in the real rows' sizes.
class _WatchersSkeleton extends StatelessWidget {
  const _WatchersSkeleton();

  static const _titles = [0.42, 0.56, 0.36, 0.5];
  static const _subtitles = [0.78, 0.64, 0.86, 0.7];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // One IconButton's tap target.
    const button = SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 18, height: 18, radius: 4)));
    return SkeletonPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 1), child: SkeletonBone(width: 16, height: 16, radius: 4)),
            const SizedBox(width: 6),
            Expanded(child: SkeletonText(style: text.bodySmall?.copyWith(height: 1.35), lines: 2, widthFactor: 0.8)),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SkeletonGroupedCard(
          rows: [
            for (var i = 0; i < _titles.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SkeletonRow(trailing: SkeletonTrailing.none, padding: EdgeInsets.zero, titleWidth: _titles[i], subtitleWidth: _subtitles[i]),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    button, button,
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

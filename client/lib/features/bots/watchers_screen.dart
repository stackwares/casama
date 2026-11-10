import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
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
                          onTap: w.conversationId == null ? null : () => context.go('/bots/$botId/chat?c=${w.conversationId}'),
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

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';

/// Step replay (D-127): recorded steps a bot runs without thinking through each one.
final replaysProvider = FutureProvider.autoDispose.family<List<Replay>, String>((ref, botId) => ref.watch(backendProvider).replays(botId));

class ReplaysScreen extends ConsumerWidget {
  const ReplaysScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    return SubPage(
      title: l10n.replays,
      subtitle: ref.watch(botProvider(botId))?.name,
      body: AsyncView(
        value: ref.watch(replaysProvider(botId)),
        onRetry: () => ref.invalidate(replaysProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.listVideo, title: l10n.noReplays, message: l10n.replaysHelp)
            : PageColumn(
                children: [
                  FormNote(l10n.replaysHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final r in items)
                        GroupedTile(
                          key: Key('replay-${r.id}'),
                          icon: LucideIcons.listVideo,
                          title: r.name,
                          subtitle: [
                            if (r.description.isNotEmpty) r.description,
                            l10n.replaySteps(r.steps.length),
                            if (r.runs > 0) l10n.replayRuns(r.runs, r.failures),
                            if (r.lastFailure != null) r.lastFailure!,
                          ].join(' · '),
                          onTap: () async {
                            final params = await showAdaptiveSheet<Map<String, String>>(context: context, builder: (_) => _RunReplay(replay: r));
                            if (params == null || !context.mounted) return;
                            final started = await runGuarded(context, () => backend.runReplay(r.id, params));
                            if (started != null && context.mounted) GoRouter.maybeOf(context)?.push('/bots/$botId/chat?c=${started.conversationId}');
                          },
                          trailing: IconButton(
                            key: Key('deleteReplay-${r.id}'),
                            tooltip: l10n.delete,
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            onPressed: () async {
                              await runGuarded(context, () => backend.deleteReplay(r.id));
                              ref.invalidate(replaysProvider(botId));
                            },
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

class _RunReplay extends StatefulWidget {
  const _RunReplay({required this.replay});
  final Replay replay;

  @override
  State<_RunReplay> createState() => _RunReplayState();
}

class _RunReplayState extends State<_RunReplay> {
  late final _fields = {for (final p in widget.replay.params) p.name: TextEditingController(text: p.default_ ?? '')};

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.play,
      title: l10n.runReplay(widget.replay.name),
      subtitle: l10n.runReplayHelp,
      submitLabel: l10n.run,
      submitKey: const Key('runReplay'),
      onSubmit: () async => Navigator.pop(context, {for (final e in _fields.entries) e.key: e.value.text}),
      children: [
        for (final p in widget.replay.params)
          Revealable(builder: (context, hidden, toggle) => TextField(
            key: Key('replayParam-${p.name}'),
            controller: _fields[p.name],
            obscureText: hidden && (p.secret ?? false),
            decoration: InputDecoration(labelText: p.name, helperText: p.description, suffixIcon: (p.secret ?? false) ? toggle : null),
          )),
      ],
    );
  }
}

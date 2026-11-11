import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';

/// A bot's settings history (D-100): every change, who made it (a person or a bot), and a way to
/// put the earlier settings back.
final botRevisionsProvider = FutureProvider.autoDispose.family<List<BotRevision>, String>(
  (ref, botId) => ref.watch(backendProvider).botRevisions(botId),
);

String fieldLabel(BuildContext context, String field) {
  final l10n = context.l10n;
  return switch (field) {
    'name' => l10n.fieldName,
    'persona_md' => l10n.fieldInstructions,
    'model_policy' => l10n.fieldModel,
    'autonomy' => l10n.fieldAutonomy,
    'budget' => l10n.fieldBudget,
    'default_computer_id' => l10n.fieldComputer,
    'archived_at' => l10n.fieldArchived,
    _ => field,
  };
}

class BotHistoryScreen extends ConsumerWidget {
  const BotHistoryScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(botId));
    final revisions = ref.watch(botRevisionsProvider(botId));
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return SubPage(
      title: l10n.settingsHistory,
      subtitle: bot?.name,
      children: [
        revisions.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpace.lg), child: Text(errorText(context, e))),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Center(child: Text(l10n.noHistory, style: TextStyle(color: context.colorScheme.onSurfaceVariant))),
                )
              : Column(
                  spacing: AppSpace.xs,
                  children: [
                    for (final r in items)
                      _RevisionCard(
                        key: Key('revision-${r.id}'),
                        revision: r,
                        actor: r.changedByBot == null ? null : bots.where((b) => b.id == r.changedByBot).firstOrNull,
                        onRestore: () => _restore(context, ref, r),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, BotRevision r) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.restoreSettings,
      message: l10n.restoreSettingsBody(r.changedFields.map((f) => fieldLabel(context, f)).join(', ')),
      confirmLabel: l10n.restore,
      icon: LucideIcons.history,
      confirmKey: const Key('confirmRestore'),
    );
    if (!ok || !context.mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).restoreBotRevision(botId, r);
      return true;
    });
    if (done != true || !context.mounted) return;
    ref
      ..invalidate(botsProvider)
      ..invalidate(archivedBotsProvider)
      ..invalidate(botRevisionsProvider(botId));
    showSuccess(context, l10n.saved);
  }
}

class _RevisionCard extends StatelessWidget {
  const _RevisionCard({super.key, required this.revision, required this.actor, required this.onRestore});
  final BotRevision revision;
  final Bot? actor;
  final VoidCallback onRestore;

  String _value(Object? v) {
    if (v == null) return kMissingValue;
    if (v is String) return v.orPlaceholder();
    if (v is Map && v['primary'] is Map) return ((v['primary'] as Map)['model']?.toString()).orPlaceholder();
    return jsonEncode(v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final who = actor != null
        ? l10n.changedByBot(actor!.name)
        : revision.changedByBot != null
            ? l10n.changedByBot('a bot')
            : revision.changedByUser != null
                ? l10n.changedByPerson
                : l10n.changedBySystem;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Row(
            children: [
              if (actor != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                  child: BotAvatar(name: actor!.name, avatar: actor!.avatarUrl, size: 28),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                  child: Icon(revision.changedByUser != null ? LucideIcons.user : LucideIcons.settings, size: 20, color: scheme.onSurfaceVariant),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      revision.changedFields.map((f) => fieldLabel(context, f)).join(', '),
                      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text('$who · ${relativeTime(revision.createdAt, context)}', style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              TextButton.icon(
                key: Key('restore-${revision.id}'),
                onPressed: onRestore,
                icon: const Icon(LucideIcons.history, size: 18),
                label: Text(l10n.restore),
              ),
            ],
          ),
          for (final f in revision.changedFields)
            Text(
              '${fieldLabel(context, f)}: ${_value(revision.snapshot[f])}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
            ),
          Divider(height: 1, color: context.appColors.hairline),
        ],
      ),
    );
  }
}

/// Archived bots, each with a way to bring it back.
Future<void> showArchivedBots(BuildContext context) => showAdaptiveSheet<void>(
      context: context,
      builder: (_) => const _ArchivedBots(),
    );

class _ArchivedBots extends ConsumerWidget {
  const _ArchivedBots();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedBotsProvider);
    final items = archived.value ?? const <Bot>[];
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Text(l10n.archivedBots, style: context.textTheme.titleLarge),
          for (final b in items)
            ListTile(
              key: Key('archived-${b.id}'),
              contentPadding: EdgeInsets.zero,
              leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 36),
              title: Text(b.name),
              trailing: TextButton(
                key: Key('unarchive-${b.id}'),
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).setBotArchived(b.id, false));
                  ref
                    ..invalidate(botsProvider)
                    ..invalidate(archivedBotsProvider);
                },
                child: Text(l10n.unarchive),
              ),
            ),
          if (archived.hasError)
            InlineError(error: archived.error!, onRetry: () => ref.invalidate(archivedBotsProvider))
          else if (archived.isLoading && !archived.hasValue)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            Text(l10n.noBots),
        ],
      ),
    );
  }
}

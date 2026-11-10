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
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../settings/model_keys_screen.dart';
import 'model_picker.dart';
import 'template_picker.dart';

import '../../ui/glow_button.dart';
String botStatusLabel(BuildContext context, BotStatusEnum s) => switch (s) {
  BotStatusEnum.working => context.l10n.botStatusWorking,
  BotStatusEnum.waiting => context.l10n.botStatusWaiting,
  BotStatusEnum.disabled => context.l10n.botStatusDisabled,
  _ => context.l10n.botStatusIdle,
};

/// The list of bots with status, today's cost and a new-bot button.
class BotsList extends ConsumerWidget {
  const BotsList({super.key, this.selectedBotId});
  final String? selectedBotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider);
    final usage = ref.watch(usageTodayProvider).value;
    double costFor(String botId) => (usage?.byBot.where((b) => b.botId == botId).fold<num>(0, (n, b) => n + b.costUsd) ?? 0).toDouble();

    return AsyncView(
      value: bots,
      onRetry: () => ref.invalidate(botsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: LucideIcons.bot,
              title: l10n.noBots,
              message: l10n.noBotsHelp,
              action: GlowButton.icon(onPressed: () => showCreateBot(context, ref), icon: const Icon(LucideIcons.plus), label: Text(l10n.newBot)),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(botsProvider);
                ref.invalidate(usageTodayProvider);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = pageSide(constraints.maxWidth);
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xs),
                    itemBuilder: (context, i) => _BotCard(
                      key: Key('bot-${items[i].id}'),
                      bot: items[i],
                      cost: costFor(items[i].id),
                      selected: items[i].id == selectedBotId,
                    ).appListItemEntrance(i),
                  );
                },
              ),
            ),
    );
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({super.key, required this.bot, required this.cost, required this.selected});
  final Bot bot;
  final double cost;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final statusColor = switch (bot.status) {
      BotStatusEnum.working => colors.working,
      BotStatusEnum.waiting => colors.waiting,
      BotStatusEnum.disabled => colors.negative,
      _ => scheme.onSurfaceVariant,
    };
    return AppCard(
      onTap: () => context.go('/bots/${bot.id}/chat'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
      borderColor: selected ? scheme.primary.withValues(alpha: 0.5) : null,
      child: Row(
        children: [
          BotAvatar(name: bot.name, size: 46, status: bot.status, ringColor: scheme.surfaceContainerLow),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    StatusLabel(text: botStatusLabel(context, bot.status), color: statusColor, pill: bot.status != BotStatusEnum.idle),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        l10n.costToday(formatUsd(cost)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(currentOrgProvider);
    return Scaffold(
      appBar: ShellHeader(
        title: context.l10n.bots,
        subtitle: org?.name,
        actions: [HeaderIconButton(icon: LucideIcons.plus, tooltip: context.l10n.newBot, onPressed: () => showCreateBot(context, ref))],
      ),
      body: const BotsList(),
    );
  }
}

Future<void> showCreateBot(BuildContext context, WidgetRef ref) async {
  await showAdaptiveSheet<void>(context: context, builder: (_) => const CreateBotSheet());
}

class CreateBotSheet extends ConsumerStatefulWidget {
  const CreateBotSheet({super.key, this.embedded = false});

  /// Shown inside a page (onboarding) instead of a sheet: no header, nothing to close.
  final bool embedded;

  @override
  ConsumerState<CreateBotSheet> createState() => _CreateBotSheetState();
}

class _CreateBotSheetState extends ConsumerState<CreateBotSheet> {
  final _name = TextEditingController();
  final _persona = TextEditingController();
  String _model = '';
  var _modelPicked = false;
  String? _autoName;
  String? _credentialId;
  String? _templateId;
  var _busy = false;

  /// Keys that run chat models; search, image and voice keys can't drive a bot.
  static const _chatProviders = {
    ProviderId.openrouter,
    ProviderId.openai,
    ProviderId.anthropic,
    ProviderId.google,
    ProviderId.xai,
    ProviderId.openaiCompatible,
  };

  @override
  void dispose() {
    _name.dispose();
    _persona.dispose();
    super.dispose();
  }

  /// A template fills in its name until the user types their own; a blank bot starts empty and is
  /// named Chief (shown as the placeholder) if the field is left empty.
  void _setAutoName(String? name) {
    if (_name.text.trim().isEmpty || _name.text == _autoName) _name.text = name ?? '';
    _autoName = name;
  }

  String _finalName(BuildContext context) => _name.text.trim().isEmpty ? context.l10n.defaultBotName : _name.text.trim();

  /// Suggests the server's default model for the chosen key until the user picks one.
  void _fillDefaultModel(List<Credential> keys) {
    if (_modelPicked) return;
    for (final k in keys) {
      if (k.id == _credentialId) _model = ref.read(backendProvider).defaultModelFor(k.provider.value) ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keysAsync = ref.watch(credentialsProvider);
    final keys = (keysAsync.value ?? const <Credential>[]).where((k) => _chatProviders.contains(k.provider)).toList();
    if (_credentialId == null || !keys.any((k) => k.id == _credentialId)) {
      _credentialId = keys.isEmpty ? null : keys.first.id;
      _fillDefaultModel(keys);
    }
    return SingleChildScrollView(
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded)
            Row(
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: BotAvatar(key: ValueKey(_finalName(context)), name: _finalName(context), size: 52),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.newBot, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      Text(l10n.newBotSubtitle, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          if (!widget.embedded) const SizedBox(height: AppSpace.lg),
          TemplatePicker(
            selected: _templateId,
            onChanged: (t) => setState(() {
              _templateId = t?.id;
              _setAutoName(t?.name);
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.botName, hintText: l10n.defaultBotName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (keysAsync.hasValue && keys.isEmpty) ...[
            Text(l10n.addModelKeyFirst, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
          ] else ...[
            DropdownButtonFormField<String>(
              key: ValueKey('key-$_credentialId-${keys.length}'),
              initialValue: _credentialId,
              decoration: InputDecoration(labelText: l10n.modelKey),
              items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text('${k.label} · ${providerLabel(k.provider)}'))],
              onChanged: (v) => setState(() {
                _credentialId = v;
                _modelPicked = false;
                _fillDefaultModel(keys);
              }),
            ),
            const SizedBox(height: 8),
            ModelPickerField(
              credentialId: _credentialId,
              value: _model,
              onChanged: (m) => setState(() {
                _model = m;
                _modelPicked = true;
              }),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _persona,
            decoration: InputDecoration(labelText: l10n.persona, hintText: l10n.personaHint),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: AppSpace.xs),
          GlowButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _busy || _credentialId == null || _model.isEmpty
                ? null
                : () async {
                    setState(() => _busy = true);
                    final org = ref.read(currentOrgProvider)!;
                    final bot = await runGuarded(
                      context,
                      () => ref
                          .read(backendProvider)
                          .createBot(
                            org.id,
                            name: _finalName(context),
                            credentialId: _credentialId!,
                            model: _model,
                            persona: _persona.text.trim(),
                            templateId: _templateId,
                          ),
                    );
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (bot != null) {
                      ref.invalidate(botsProvider);
                      final router = GoRouter.of(context);
                      if (!widget.embedded) Navigator.of(context).pop();
                      router.go('/bots/${bot.id}/chat');
                    }
                  },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}

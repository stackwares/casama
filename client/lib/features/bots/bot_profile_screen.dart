import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/mascot.dart';
import '../../ui/motion.dart';
import '../../ui/page.dart';
import '../chat/delete_chat.dart';
import '../notifications/checkins_sheet.dart';
import '../notifications/quiet_hours.dart';
import '../settings/model_keys_screen.dart';
import '../settings/settings_screen.dart' show VoiceSettingsDialog;
import 'a2a_sheet.dart';
import 'bot_template.dart';
import 'bots_screen.dart' show botStatusLabel;
import 'model_picker.dart';
import 'template_picker.dart';

/// One bot's profile: who it is up top, its computer, memory, routines and apps one tap away,
/// then its settings in a few short sections, with the expert ones folded under Advanced (D-182)
/// and Archive alone at the very end.
class BotProfileScreen extends ConsumerStatefulWidget {
  const BotProfileScreen({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<BotProfileScreen> createState() => _BotProfileScreenState();
}

class _BotProfileScreenState extends ConsumerState<BotProfileScreen> {
  TextEditingController? _name;
  TextEditingController? _persona;
  String? _autonomy;
  String? _credentialId;
  String? _model;
  String? _avatar;
  var _avatarLoaded = false;
  var _busy = false;

  @override
  void dispose() {
    _name?.dispose();
    _persona?.dispose();
    super.dispose();
  }

  /// Casama's key on Casama Cloud keeps Casama's model. Anywhere else, the field's value.
  String _chosenModel({required bool listen}) =>
      casamaLockedModel(ref, _credentialId, listen: listen) ?? _model ?? '';

  bool _dirty(Bot bot) =>
      _name!.text.trim() != bot.name ||
      _persona!.text != bot.personaMd ||
      _autonomy != bot.autonomy.value ||
      _credentialId != bot.modelPolicy.primary?.credentialId ||
      _chosenModel(listen: true) != bot.modelPolicy.primary?.model ||
      _avatar != bot.avatarUrl;

  Future<void> _save(Bot bot) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final model = _chosenModel(listen: false);
    final modelChanged =
        _credentialId != bot.modelPolicy.primary?.credentialId ||
        model != bot.modelPolicy.primary?.model;
    final policy = modelChanged && _credentialId != null && model.isNotEmpty
        ? {
            ...bot.modelPolicy.toJson(),
            'primary': {'credential_id': _credentialId, 'model': model},
          }
        : null;
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .updateBot(
            bot.id,
            name: _name!.text.trim(),
            persona: _persona!.text,
            autonomy: _autonomy,
            modelPolicy: policy,
            avatarUrl: _avatar == bot.avatarUrl ? null : (_avatar ?? ''),
          );
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(botsProvider);
      showSuccess(context, l10n.saved);
    }
  }

  /// The model's display name ("Claude Sonnet 4.5"), falling back to its id.
  String _modelLabel(Bot bot) {
    final choice = bot.modelPolicy.primary;
    if (choice == null) return '';
    final options =
        ref.watch(modelOptionsProvider(choice.credentialId)).value?.items ??
        const <ModelOption>[];
    for (final o in options) {
      if (o.id == choice.model) {
        return o.name.contains(': ') ? o.name.split(': ').last : o.name;
      }
    }
    return choice.model.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(widget.botId));
    if (bot == null) return SubPage(title: l10n.botProfile, body: const _BotProfileSkeleton());
    _name ??= TextEditingController(text: bot.name);
    _persona ??= TextEditingController(text: bot.personaMd);
    _autonomy ??= bot.autonomy.value;
    _credentialId ??= bot.modelPolicy.primary?.credentialId;
    _model ??= bot.modelPolicy.primary?.model;
    if (!_avatarLoaded) {
      _avatar = bot.avatarUrl;
      _avatarLoaded = true;
    }
    final keys = (ref.watch(credentialsProvider).value ?? const <Credential>[])
        .where(
          (k) => const {
            ProviderId.openrouter,
            ProviderId.openai,
            ProviderId.anthropic,
            ProviderId.google,
            ProviderId.xai,
            ProviderId.openaiCompatible,
          }.contains(k.provider),
        )
        .toList();
    final computers = ref.watch(computersProvider).value ?? const <Computer>[];
    final usable = computers
        .where(
          (c) =>
              c.kind == ComputerKindEnum.team ||
              c.kind == ComputerKindEnum.local ||
              c.ownerBotId == bot.id,
        )
        .toList();
    final dirty = _dirty(bot);
    final name = _name!.text.trim().isEmpty ? bot.name : _name!.text.trim();
    // Casama Cloud chooses the model (D-188), so its name isn't shown there.
    final model = casamaModelFixed(ref) ? '' : _modelLabel(bot);
    final levels = [
      (
        'ask_always',
        LucideIcons.hand,
        l10n.autonomyAskAlways,
        l10n.autonomyAskAlwaysHelp,
      ),
      (
        'ask_risky',
        LucideIcons.shield,
        l10n.autonomyAskRisky,
        l10n.autonomyAskRiskyHelp,
      ),
      (
        'autonomous',
        LucideIcons.zap,
        l10n.autonomyAutonomous,
        l10n.autonomyAutonomousHelp,
      ),
    ];
    final label = context.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SubPage(
      title: l10n.botProfile,
      actions: [
        if (dirty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GlowButton(
              onPressed: _busy ? null : () => _save(bot),
              child: Text(l10n.save),
            ),
          ),
      ],
      children: [
        // Who it is.
        _BotHero(
          name: name,
          avatar: _avatar,
          status: bot.status,
          model: model,
        ),
        _BotTiles(
          tiles: [
            _BotTile(
              key: const Key('botTile-computer'),
              accent: _Accent.sky,
              icon: LucideIcons.monitor,
              label: l10n.botComputer,
              onTap: () => context.push('/computer?bot=${bot.id}'),
            ),
            _BotTile(
              key: const Key('botTile-memory'),
              accent: _Accent.pink,
              icon: LucideIcons.brain,
              label: l10n.memory,
              onTap: () => context.push('/bots/${bot.id}/memory'),
            ),
            _BotTile(
              key: const Key('botTile-routines'),
              accent: _Accent.amber,
              icon: LucideIcons.clock,
              label: l10n.routines,
              onTap: () => context.push('/bots/${bot.id}/routines'),
            ),
            _BotTile(
              key: const Key('botTile-apps'),
              accent: _Accent.green,
              icon: LucideIcons.puzzle,
              label: l10n.appsTitle,
              onTap: () => context.push('/bots/${bot.id}/integrations'),
            ),
            // What it made (the Library, D-274), in place of the old Pages row.
            _BotTile(
              key: const Key('botTile-library'),
              accent: _Accent.violet,
              icon: LucideIcons.library,
              label: l10n.libraryTile,
              onTap: () => context.go('/library?bot=${bot.id}'),
            ),
          ],
        ),

        // Profile: name, icon, instructions, folder, who it's shared with.
        SectionHeader(title: l10n.botProfileSection),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.botName),
                onChanged: (_) => setState(() {}),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.sm,
                children: [
                  Text(l10n.botIcon, style: label),
                  MascotPicker(
                    value: _avatar,
                    initials: botInitials(name),
                    initialsLabel: l10n.botIconInitials,
                    onChanged: (v) => setState(() => _avatar = v),
                  ),
                ],
              ),
              TextField(
                controller: _persona,
                decoration: InputDecoration(
                  labelText: l10n.persona,
                  hintText: l10n.personaHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 12,
                minLines: 4,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('loadPersona'),
                  icon: const Icon(LucideIcons.swatchBook, size: 18),
                  label: Text(l10n.loadPersona),
                  onPressed: () async {
                    final choice = await showPersonaGallery(
                      context,
                      allowBlank: false,
                    );
                    final t = choice?.template;
                    if (t == null || !context.mounted) return;
                    if (_persona!.text.trim().isNotEmpty) {
                      final ok = await showConfirm(
                        context: context,
                        title: l10n.replaceInstructionsTitle,
                        message: l10n.replaceInstructionsBody(t.name),
                        confirmLabel: l10n.replace,
                      );
                      if (!ok) return;
                    }
                    setState(() => _persona!.text = t.persona ?? '');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        GroupedCard(
          children: [
            _FolderTile(bot: bot),
            GroupedTile(
              key: const Key('botSharing'),
              icon: LucideIcons.users,
              title: l10n.sharing,
              subtitle: l10n.sharingRow,
              onTap: () => context.push('/bots/${bot.id}/sharing'),
            ),
          ],
        ),

        // Brain: the model and how much it does on its own.
        SectionHeader(title: l10n.botBrain),
        // Casama Cloud chooses the key and the model (D-188): nothing to show.
        if (!casamaModelFixed(ref))
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('botKey-${keys.length}'),
                initialValue: keys.any((k) => k.id == _credentialId)
                    ? _credentialId
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.modelKey,
                  prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
                ),
                items: [
                  for (final k in keys)
                    DropdownMenuItem(
                      value: k.id,
                      child: Text(
                        '${k.label} · ${providerLabel(k.provider)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: hapticOnChanged(
                  (v) => setState(() {
                    _credentialId = v;
                    for (final k in keys) {
                      if (k.id == v) {
                        _model =
                            ref
                                .read(backendProvider)
                                .defaultModelFor(k.provider.value) ??
                            _model;
                      }
                    }
                  }),
                  haptic: HapticsHelper.selection,
                ),
              ),
              ModelPickerField(
                credentialId: _credentialId,
                value: _chosenModel(listen: true),
                onChanged: (m) => setState(() => _model = m),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxs,
            AppSpace.md,
            AppSpace.xxs,
            AppSpace.xs,
          ),
          child: Text(l10n.autonomy, style: label),
        ),
        RadioGroup<String>(
          groupValue: _autonomy,
          onChanged: (v) => setState(() => _autonomy = v),
          child: Column(
            spacing: AppSpace.xs,
            children: [
              for (final (value, icon, title, help) in levels)
                AppCard(
                  key: Key('autonomy-$value'),
                  onTap: () => setState(() => _autonomy = value),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md,
                    14,
                    AppSpace.sm,
                    14,
                  ),
                  borderColor: _autonomy == value ? scheme.primary : null,
                  borderWidth: _autonomy == value ? 1.5 : 1,
                  color: _autonomy == value
                      ? Color.alphaBlend(
                          scheme.primary.withValues(alpha: 0.06),
                          scheme.surfaceContainerLow,
                        )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: _autonomy == value
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              help,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(value: value),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Abilities: where it works and what it knows.
        SectionHeader(title: l10n.botAbilities),
        GroupedCard(
          children: [
            Builder(
              builder: (context) {
                final current = usable
                    .where((c) => c.id == bot.defaultComputerId)
                    .firstOrNull;
                return GroupedTile(
                  key: const Key('botComputer'),
                  icon: LucideIcons.monitor,
                  title: l10n.botComputer,
                  subtitle: current?.name ?? l10n.botComputerAuto,
                  trailing: Icon(
                    LucideIcons.chevronsUpDown,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () async {
                    final picked = await showChoiceSheet<String?>(
                      context,
                      title: l10n.botComputer,
                      subtitle: l10n.botComputerHelp,
                      icon: LucideIcons.monitor,
                      selected: current?.id,
                      choices: [
                        Choice(
                          value: null,
                          label: l10n.botComputerAuto,
                          subtitle: l10n.botComputerDefault,
                          icon: LucideIcons.wandSparkles,
                        ),
                        for (final c in usable)
                          Choice(
                            value: c.id,
                            label: c.name,
                            subtitle: [
                              if ((c.kind == ComputerKindEnum.team
                                      ? l10n.teamComputer
                                      : l10n.privateComputer) !=
                                  c.name)
                                c.kind == ComputerKindEnum.team
                                    ? l10n.teamComputer
                                    : l10n.privateComputer,
                              c.profile == ComputerProfileEnum.desktop
                                  ? l10n.profileDesktop
                                  : l10n.profileHeadless,
                            ].join(' · '),
                            icon: c.profile == ComputerProfileEnum.desktop
                                ? LucideIcons.monitor
                                : LucideIcons.squareTerminal,
                          ),
                      ],
                    );
                    if (picked == null || !context.mounted) return;
                    await runGuarded(
                      context,
                      () => ref
                          .read(backendProvider)
                          .setBotComputer(bot.id, picked.value),
                    );
                    ref.invalidate(botsProvider);
                  },
                );
              },
            ),
            GroupedTile(
              key: const Key('botVoice'),
              icon: LucideIcons.speech,
              title: l10n.voiceSettings,
              subtitle: l10n.voiceSettingsHelp,
              onTap: () => showAdaptiveSheet<void>(
                context: context,
                builder: (_) => VoiceSettingsDialog(botId: bot.id),
              ),
            ),
            GroupedTile(
              key: const Key('botKnowledge'),
              icon: LucideIcons.library,
              title: l10n.knowledge,
              subtitle: l10n.knowledgeRow,
              onTap: () => context.push('/bots/${bot.id}/knowledge'),
            ),
          ],
        ),

        // Schedule: when it checks in and when it may notify.
        SectionHeader(title: l10n.botSchedule),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('botCheckins'),
              icon: LucideIcons.sun,
              title: l10n.checkins,
              subtitle:
                  ref.watch(botCheckinsProvider(bot.id)).value?.enabled == true
                  ? l10n.on
                  : l10n.off,
              onTap: () => showCheckins(context, ref, bot.id),
            ),
            GroupedTile(
              key: const Key('botQuiet'),
              icon: LucideIcons.bellRing,
              title: l10n.botNotifications,
              subtitle: switch (ref
                  .watch(botQuietProvider(bot.id))
                  .value
                  ?.mode) {
                'always' => l10n.quietAlways,
                'custom' => l10n.quietCustom,
                _ => l10n.quietDefault,
              },
              onTap: () => showBotQuiet(context, ref, bot.id),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.lg),
        GlowButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _busy || !dirty ? null : () => _save(bot),
          icon: const Icon(LucideIcons.check, size: 20),
          label: Text(l10n.saveChanges),
        ),

        // Advanced (D-182): technical setup and rarely used extras, folded until asked for.
        AdvancedSection(
          id: 'bot.advanced',
          summary: l10n.botAdvancedSummary,
          children: [
            GroupedCard(
              key: const Key('botAdvancedRows'),
              children: [
                GroupedTile(
                  key: const Key('botRules'),
                  icon: LucideIcons.shieldCheck,
                  title: l10n.actionRules,
                  subtitle: l10n.actionRulesRow,
                  onTap: () => context.push('/bots/${bot.id}/rules'),
                ),
                GroupedTile(
                  key: const Key('botWatchers'),
                  icon: LucideIcons.eye,
                  title: l10n.watchers,
                  subtitle: l10n.watchersRow,
                  onTap: () => context.push('/bots/${bot.id}/watchers'),
                ),
                GroupedTile(
                  key: const Key('botPlugins'),
                  icon: LucideIcons.blocks,
                  title: l10n.plugins,
                  subtitle: l10n.pluginsRow,
                  onTap: () => context.push('/bots/${bot.id}/plugins'),
                ),
                GroupedTile(
                  key: const Key('botChatApps'),
                  icon: LucideIcons.messagesSquare,
                  title: l10n.chatApps,
                  subtitle: l10n.chatAppsRow,
                  onTap: () => context.push('/bots/${bot.id}/chat-apps'),
                ),
                GroupedTile(
                  key: const Key('botLinks'),
                  icon: LucideIcons.link,
                  title: l10n.links,
                  subtitle: l10n.linksRow,
                  onTap: () => context.push('/bots/${bot.id}/links'),
                ),
                GroupedTile(
                  key: const Key('botA2a'),
                  icon: LucideIcons.bot,
                  title: l10n.a2aPublish,
                  subtitle: l10n.a2aPublishHelp,
                  onTap: () => showAdaptiveSheet<void>(
                    context: context,
                    builder: (_) => BotA2aSheet(botId: bot.id),
                  ),
                ),
                GroupedTile(
                  key: const Key('shareBot'),
                  icon: LucideIcons.share2,
                  title: l10n.shareAsTemplate,
                  subtitle: l10n.shareAsTemplateRow,
                  onTap: () => showShareBot(context, bot),
                ),
                GroupedTile(
                  key: const Key('botActivity'),
                  icon: LucideIcons.activity,
                  title: l10n.activity,
                  subtitle: l10n.botActivityRow,
                  onTap: () => context.push('/bots/${bot.id}/activity'),
                ),
                GroupedTile(
                  key: const Key('botReplays'),
                  icon: LucideIcons.listVideo,
                  title: l10n.replays,
                  subtitle: l10n.replaysRow,
                  onTap: () => context.push('/bots/${bot.id}/replays'),
                ),
                GroupedTile(
                  key: const Key('botHistory'),
                  icon: LucideIcons.history,
                  title: l10n.settingsHistory,
                  subtitle: l10n.settingsHistoryHelp,
                  onTap: () => context.push('/bots/${bot.id}/history'),
                ),
                GroupedTile(
                  key: const Key('rerunSetup'),
                  icon: LucideIcons.sparkles,
                  title: l10n.rerunSetup,
                  subtitle: l10n.rerunSetupHelp,
                  onTap: () async {
                    final conv = await runGuarded(
                      context,
                      () => ref.read(backendProvider).startBotSetup(bot.id),
                    );
                    if (conv == null || !context.mounted) return;
                    ref.invalidate(botsProvider);
                    GoRouter.maybeOf(context)
                        ?.go('/bots/${bot.id}/chat?c=$conv');
                  },
                ),
              ],
            ),
          ],
        ),

        // Archive: always in sight, alone at the very end.
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('deleteAllChats'),
              icon: LucideIcons.trash2,
              title: l10n.deleteAllChats,
              subtitle: l10n.deleteAllChatsRow,
              destructive: true,
              showChevron: false,
              onTap: () => confirmDeleteAllChats(context, ref, botId: bot.id, botName: bot.name),
            ),
            GroupedTile(
              key: const Key('archiveBot'),
              icon: LucideIcons.archive,
              title: l10n.archiveBot,
              destructive: true,
              showChevron: false,
              onTap: () async {
                final ok = await showConfirm(
                  context: context,
                  title: l10n.archiveBotTitle(bot.name),
                  message: l10n.archiveBotBody,
                  confirmLabel: l10n.archive,
                  destructive: true,
                  icon: LucideIcons.archive,
                  confirmKey: const Key('confirmArchive'),
                );
                if (!ok || !context.mounted) return;
                final done = await runGuarded(context, () async {
                  await ref.read(backendProvider).setBotArchived(bot.id, true);
                  return true;
                });
                if (done != true || !context.mounted) return;
                ref
                  ..invalidate(botsProvider)
                  ..invalidate(archivedBotsProvider);
                showSuccess(context, l10n.botArchived(bot.name));
                GoRouter.maybeOf(context)?.go('/bots');
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Four big shortcuts: one row when there's room, two by two on phones.
/// The top of the profile: the bot on a soft glow in its own color, its name, and a pill saying what
/// it's up to, with its model beside it when the model is the user's choice.
class _BotHero extends StatelessWidget {
  const _BotHero({
    required this.name,
    required this.avatar,
    required this.status,
    required this.model,
  });
  final String name;
  final String? avatar;
  final BotStatusEnum status;
  final String model;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final glow = botPalette(name).first;
    final dot = switch (status) {
      BotStatusEnum.working => colors.working,
      BotStatusEnum.waiting => colors.waiting,
      BotStatusEnum.disabled => scheme.outline,
      _ => scheme.onSurfaceVariant,
    };
    final chipStyle = context.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    Widget chip({Key? key, required Widget lead, required String text}) =>
        Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              lead,
              Flexible(
                child: Text(
                  text,
                  key: key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: chipStyle,
                ),
              ),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        AppSpace.xl,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 176,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(
                    width: 176,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          glow.withValues(alpha: context.isDark ? 0.32 : 0.2),
                          glow.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                BotAvatar(
                  name: name,
                  avatar: avatar,
                  size: 112,
                  ringColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            name,
            key: const Key('botProfileName'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              chip(
                key: const Key('botProfileStatus'),
                lead: _StatusDot(
                  color: dot,
                  pulse: status == BotStatusEnum.working,
                ),
                text: botStatusLabel(context, status),
              ),
              if (model.isNotEmpty)
                chip(
                  key: const Key('botProfileModel'),
                  lead: Icon(
                    LucideIcons.sparkles,
                    size: 13,
                    color: scheme.primary,
                  ),
                  text: model,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    );
    return pulse ? Pulse(child: dot) : dot;
  }
}

/// A shortcut's hue, so each of the four reads at a glance.
enum _Accent {
  sky(Color(0xFF38BDF8), Color(0xFF0284C7)),
  pink(Color(0xFFF472B6), Color(0xFFDB2777)),
  amber(Color(0xFFFBBF24), Color(0xFFD97706)),
  green(Color(0xFF34D399), Color(0xFF059669)),
  violet(Color(0xFFA78BFA), Color(0xFF7C3AED));

  const _Accent(this.dark, this.light);
  final Color dark;
  final Color light;
  Color of(BuildContext context) => context.isDark ? dark : light;
}

class _BotTiles extends StatelessWidget {
  const _BotTiles({required this.tiles});
  final List<Widget> tiles;

  /// The narrowest a tile gets in a single row before the tiles wrap to two by two.
  static const _minTileWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.xs;
        final oneRow =
            constraints.maxWidth >=
            tiles.length * _minTileWidth + (tiles.length - 1) * gap;
        Widget row(List<Widget> items) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [for (final t in items) Expanded(child: t)],
        );
        if (oneRow) return row(tiles);
        return Column(
          spacing: gap,
          children: [
            for (var i = 0; i < tiles.length; i += 2)
              row(tiles.sublist(i, (i + 2).clamp(0, tiles.length))),
          ],
        );
      },
    );
  }
}

class _BotTile extends StatelessWidget {
  const _BotTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final _Accent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxs,
        AppSpace.sm,
        AppSpace.xxs,
        AppSpace.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: context.isDark ? 0.3 : 0.18),
                  color.withValues(alpha: context.isDark ? 0.14 : 0.08),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Which folder the bot sits in on the bots list; a new folder can be made right here.
class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.bot});
  final Bot bot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final folders = ref.watch(botFoldersProvider).value ?? const <BotFolder>[];
    final current = folders.where((f) => f.id == bot.folderId).firstOrNull;
    return GroupedTile(
      key: const Key('botFolder'),
      icon: LucideIcons.folder,
      title: l10n.botFolder,
      subtitle: current?.name ?? l10n.noFolder,
      trailing: Icon(
        LucideIcons.chevronsUpDown,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () async {
        const fresh = '\u0000new';
        final picked = await showChoiceSheet<String?>(
          context,
          title: l10n.botFolder,
          icon: LucideIcons.folder,
          selected: current?.name,
          choices: [
            Choice(
              value: null,
              label: l10n.noFolder,
              icon: LucideIcons.folderMinus,
            ),
            for (final f in folders)
              Choice(value: f.name, label: f.name, icon: LucideIcons.folder),
            Choice(
              value: fresh,
              label: l10n.newFolder,
              icon: LucideIcons.folderPlus,
            ),
          ],
        );
        if (picked == null || !context.mounted) return;
        var name = picked.value;
        if (name == fresh) {
          name = (await showTextPrompt(
            context,
            title: l10n.newFolder,
            label: l10n.folderName,
            submitLabel: l10n.save,
            fieldKey: const Key('folderName'),
          ))?.trim();
          if (name == null || name.isEmpty || !context.mounted) return;
        }
        final org = ref.read(currentOrgProvider);
        if (org == null) return;
        await runGuarded(
          context,
          () => ref.read(backendProvider).setBotFolder(org.id, bot.id, name),
        );
        ref
          ..invalidate(botsProvider)
          ..invalidate(botFoldersProvider);
      },
    );
  }
}

/// The profile while the bot loads: the hero (avatar on its glow, name, status pill), the four
/// shortcut tiles and the Profile section's card, in the real sizes.
class _BotProfileSkeleton extends StatelessWidget {
  const _BotProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final tile = SkeletonCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.sm, AppSpace.xxs, AppSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBone(width: 40, height: 40, radius: 20),
          const SizedBox(height: AppSpace.xs),
          SkeletonText(style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600), widthFactor: 0.6, center: true),
        ],
      ),
    );
    // A text field's outline.
    Widget field(double height) => SkeletonBone(height: height, radius: AppRadius.tile);
    return SkeletonPage(
      children: [
        // _BotHero.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.xl),
          child: Column(
            children: [
              const SizedBox(width: 176, height: 150, child: Center(child: SkeletonBone(width: 112, height: 112, radius: 56))),
              const SizedBox(height: AppSpace.xs),
              SkeletonText(style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4), width: 160, center: true),
              const SizedBox(height: AppSpace.sm),
              const SkeletonBone(width: 92, height: 28, radius: AppRadius.pill),
            ],
          ),
        ),
        // _BotTiles: one row when there's room, two by two otherwise.
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpace.xs;
            Widget row() => Row(spacing: gap, children: [Expanded(child: tile), Expanded(child: tile)]);
            if (constraints.maxWidth >= 4 * _BotTiles._minTileWidth + 3 * gap) {
              return Row(spacing: gap, children: [for (var i = 0; i < 4; i++) Expanded(child: tile)]);
            }
            return Column(spacing: gap, children: [row(), row()]);
          },
        ),
        const SkeletonSectionHeader(width: 72),
        SkeletonCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              field(56),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.sm,
                children: [
                  SkeletonText(style: text.labelLarge, width: 64),
                  // The mascot picker's row of faces.
                  SizedBox(
                    height: 60,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < ((constraints.maxWidth + 8) / 60).floor(); i++)
                            const SkeletonBone(width: 52, height: 52, radius: 26),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              field(128),
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(height: 40, child: Center(child: SkeletonBone(width: 120, height: 14))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'bot_history_screen.dart';
import 'agent_import.dart';
import 'bot_template.dart';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/plain_text.dart';
import '../../core/date_format.dart';
import '../groups/group_chats.dart';
import '../../ui/bot_activity.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/mascot.dart';
import '../../ui/page.dart';
import '../../ui/tab_reselect.dart';
import '../../ui/shell_header.dart';
import '../settings/me_avatar.dart';
import '../settings/model_keys_screen.dart';
import 'model_picker.dart';
import 'template_picker.dart';
import '../../ui/glow_button.dart';
import '../search/search_view.dart';
import '../workspaces/spaces.dart';
import '../../ui/celebration.dart';
import '../../core/analytics.dart';

String botStatusLabel(BuildContext context, BotStatusEnum s) => switch (s) {
  BotStatusEnum.working => context.l10n.botStatusWorking,
  BotStatusEnum.waiting => context.l10n.botStatusWaiting,
  BotStatusEnum.disabled => context.l10n.botStatusDisabled,
  _ => context.l10n.botStatusIdle,
};

/// The preview for a chat list row: the bot's last message as plain words ("You: …" when it was
/// yours), or a word for a lone attachment. Null when the bot has no messages yet.
String? lastMessagePreview(BuildContext context, Bot bot) {
  final m = bot.lastMessage;
  if (m == null) return null;
  final l10n = context.l10n;
  final mime = m.fileMime ?? '';
  final text = m.text.isNotEmpty
      ? plainPreview(m.text)
      : mime.startsWith('image/')
      ? l10n.chatPreviewPhoto
      : mime.startsWith('video/')
      ? l10n.chatPreviewVideo
      : mime.startsWith('audio/')
      ? l10n.chatPreviewVoice
      : m.fileName ?? '';
  if (text.isEmpty) return null;
  return m.from == BotLastMessageFromEnum.you ? l10n.chatPreviewYou(text) : text;
}

/// How many lines a bot's preview gets on the chats list, given how many chats (bots and group
/// chats) it shows: three while there is just one, two for a few, then one so more fit.
int chatPreviewLines(int chats) => chats <= 1
    ? 3
    : chats <= 3
    ? 2
    : 1;

/// When a chat list row last had a message: the time today, "Yesterday", the weekday this
/// week, then the date.
String chatListTime(BuildContext context, DateTime at) {
  final t = at.toLocal();
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  if (days <= 0) return t.formattedTime(context);
  if (days == 1) return context.l10n.chatTimeYesterday;
  if (days < 7) {
    return DateFormat.E(Localizations.localeOf(context).toString()).format(t);
  }
  return t.formattedDate(context);
}

/// Bots with the most recent chat first; bots never talked to keep their order after them.
List<Bot> byRecentChat(List<Bot> bots) {
  final order = {for (final (i, b) in bots.indexed) b.id: i};
  return [...bots]..sort((a, b) {
    final at = a.lastMessage?.at, bt = b.lastMessage?.at;
    if (at != null && bt != null) return bt.compareTo(at);
    if (at != null) return -1;
    if (bt != null) return 1;
    return order[a.id]!.compareTo(order[b.id]!);
  });
}

/// The list of bots: each one's last message and what it's doing, most recent first.
class BotsList extends ConsumerWidget {
  const BotsList({super.key, this.selectedBotId});
  final String? selectedBotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider);
    final archived = ref.watch(archivedBotsProvider).value ?? const <Bot>[];
    final groups = ref.watch(groupChatsProvider).value ?? const <Conversation>[];

    return AsyncView(
      value: bots,
      onRetry: () => ref.invalidate(botsProvider),
      loading: const _BotsListSkeleton(),
      data: (all) {
        final items = byRecentChat(all);
        final previewLines = chatPreviewLines(items.length + groups.length);
        return items.isEmpty
          ? EmptyState(
              illustration: const BlankBotImage(size: 132),
              title: l10n.noBots,
              message: l10n.noBotsHelp,
              action: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.sm,
                children: [
                  GlowButton.icon(
                    onPressed: () => showCreateBot(context, ref),
                    icon: const Icon(LucideIcons.plus),
                    label: Text(l10n.newBot),
                  ),
                  if (archived.isNotEmpty)
                    TextButton.icon(
                      key: const Key('archivedBots'),
                      icon: const Icon(LucideIcons.archive, size: 18),
                      label: Text('${l10n.archivedBots} (${archived.length})'),
                      onPressed: () => showArchivedBots(context),
                    ),
                  AdvancedSection(
                    id: 'chats.empty',
                    compact: true,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpace.xs,
                        children: [
                          TextButton.icon(
                            key: const Key('importBotFile'),
                            icon: const Icon(LucideIcons.fileDown, size: 18),
                            label: Text(l10n.importBot),
                            onPressed: () => importBotFromFile(context),
                          ),
                          TextButton.icon(
                            key: const Key('importAgent'),
                            icon: const Icon(LucideIcons.folderInput, size: 18),
                            label: Text(l10n.importAgent),
                            onPressed: () => importAgentFolder(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                HapticsHelper.medium();
                ref.invalidate(botsProvider);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = pageSide(constraints.maxWidth);
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      AppSpace.xs,
                      side,
                      AppSpace.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: items.length + 1 + (archived.isNotEmpty ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.xs),
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        return _GroupChatsSection(bots: items);
                      }
                      if (i > items.length) {
                        return TextButton.icon(
                          key: const Key('archivedBots'),
                          icon: const Icon(LucideIcons.archive, size: 18),
                          label: Text(
                            '${l10n.archivedBots} (${archived.length})',
                          ),
                          onPressed: () => showArchivedBots(context),
                        );
                      }
                      return _BotCard(
                        key: Key('bot-${items[i].id}'),
                        bot: items[i],
                        selected: items[i].id == selectedBotId,
                        previewLines: previewLines,
                      ).appListItemEntrance(i);
                    },
                  );
                },
              ),
            );
      },
    );
  }
}

class _BotCard extends StatelessWidget {
  const _BotCard({
    super.key,
    required this.bot,
    required this.selected,
    this.previewLines = 1,
  });
  final Bot bot;
  final bool selected;

  /// Lines the last-message preview may take (see [chatPreviewLines]).
  final int previewLines;

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
    final preview = lastMessagePreview(context, bot);
    return AppCard(
      onTap: () => context.go('/bots/${bot.id}/chat'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
      borderColor: selected ? scheme.primary.withValues(alpha: 0.5) : null,
      child: Row(
        // A longer preview grows the row downwards; the avatar stays by the name.
        crossAxisAlignment: previewLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          BotAvatar(
            name: bot.name,
            avatar: bot.avatarUrl,
            size: 46,
            animate: true,
            status: bot.status,
            ringColor: scheme.surfaceContainerLow,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (bot.lastMessage case final m?) ...[
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        chatListTime(context, m.at),
                        key: Key('bot-time-${bot.id}'),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                // What it's doing when that matters, then its last message, which wraps
                // under the pill.
                Text.rich(
                  TextSpan(
                    children: [
                      if (bot.status != BotStatusEnum.idle)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpace.xs),
                            child: StatusLabel(
                              text: botStatusLabel(context, bot.status),
                              color: statusColor,
                              pill: true,
                            ),
                          ),
                        ),
                      TextSpan(text: preview ?? l10n.chatPreviewNone),
                    ],
                  ),
                  key: Key('bot-preview-${bot.id}'),
                  maxLines: previewLines,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: preview == null ? 0.7 : 1,
                    ),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          // What's waiting from this bot, or that it is working; otherwise the chevron.
          // Centred on the avatar, however tall the preview makes the row.
          SizedBox(
            height: 46,
            child: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final count = ref.watch(botBadgeProvider(bot.id));
                  final working = bot.status == BotStatusEnum.working;
                  if (count == 0 && !working) {
                    return Icon(
                      LucideIcons.chevronRight,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: BotActivity(count: count, working: working),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chats list while bots load: cards shaped like [_BotCard] (avatar, name and time, a line
/// of the last message, the chevron), with the list's gaps.
class _BotsListSkeleton extends StatelessWidget {
  const _BotsListSkeleton();

  static const _names = [0.42, 0.3, 0.5, 0.36, 0.46, 0.34];
  static const _previews = [0.86, 0.7, 0.78, 0.92, 0.64, 0.8];

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonPage(
      children: [
        for (var i = 0; i < _names.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.xs),
          SkeletonCard(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
            child: Row(
              children: [
                // BotAvatar's rounded square (radius is 0.32 of its size).
                const SkeletonBone(width: 46, height: 46, radius: 46 * 0.32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonText(
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              widthFactor: _names[i],
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          SizedBox(width: 34, child: SkeletonText(style: text.labelSmall, widthFactor: 1)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      SkeletonText(style: text.bodyMedium?.copyWith(height: 1.25), widthFactor: _previews[i]),
                    ],
                  ),
                ),
                // The chevron, centred on the avatar.
                const SizedBox(
                  width: 24,
                  height: 46,
                  child: Center(child: SkeletonBone(width: 8, height: 12, radius: 3)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Group chats (D-118) under the bots on phones: stacked faces, and a way to start one.
class _GroupChatsSection extends ConsumerWidget {
  const _GroupChatsSection({required this.bots});
  final List<Bot> bots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final groups =
        ref.watch(groupChatsProvider).value ?? const <Conversation>[];
    if (groups.isEmpty && bots.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.groupChats,
          trailing: IconButton(
            key: const Key('newGroupChatList'),
            tooltip: l10n.newGroupChat,
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(LucideIcons.plus),
            onPressed: () => showNewGroupChat(context, ref),
          ),
        ),
        if (groups.isNotEmpty)
          GroupedCard(
            children: [
              for (final g in groups)
                Builder(
                  builder: (context) {
                    final members = [
                      for (final id in g.botIds)
                        ?bots.where((b) => b.id == id).firstOrNull,
                    ];
                    return GroupedTile(
                      key: Key('group-${g.id}'),
                      icon: LucideIcons.users,
                      leading: GroupAvatar(
                        bots: members,
                        size: 36,
                        ringColor: scheme.surfaceContainerLow,
                      ),
                      title: groupTitle(g, bots),
                      subtitle: l10n.groupBotCount(g.botIds.length),
                      trailing:
                          members.any((b) => b.status == BotStatusEnum.working)
                          ? const BotActivity(count: 0, working: true)
                          : null,
                      onTap: () => context.go('/groups/${g.id}'),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(currentOrgProvider);
    // Phones: the person's avatar (Settings) on the left, the workspace under the title (tap to
    // switch), and "+" on the right. Tablets have both in the rail already (D-176).
    final phone =
        AppBreakpoints.of(MediaQuery.sizeOf(context).width) ==
        WindowSize.compact;
    // Tapping Chats again scrolls this list to the top (TabReselect); so does the iOS status bar.
    return PrimaryScrollController(
      controller: TabReselect.chats,
      child: Scaffold(
        appBar: ShellHeader(
          title: context.l10n.navChats,
          subtitle: org?.name,
          leading: phone
              ? const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Center(child: MeButton()),
                )
              : null,
          titleTrailing: org == null
              ? null
              : Icon(
                  LucideIcons.chevronsUpDown,
                  size: 16,
                  color: context.colorScheme.onSurfaceVariant,
                ),
          onTitleTap: () => showSpacesSheet(context, ref),
          actions: [
            // Phones: search lives here, beside "+" (tablets and desktop have it in the sidebar).
            if (phone)
              HeaderIconButton(
                key: const Key('tabSearch'),
                icon: LucideIcons.search,
                tooltip: context.l10n.search,
                onPressed: () => showWorkspaceSearch(context),
              ),
            HeaderIconButton(
              key: const Key('createMenu'),
              icon: LucideIcons.plus,
              tooltip: context.l10n.newBot,
              onPressed: () => showCreateBot(context, ref),
            ),
          ],
        ),
        // About you (D-169): the one-time name card for people who joined before it was asked.
        body: const BotsList(),
      ),
    );
  }
}

Future<void> showCreateBot(BuildContext context, WidgetRef ref) async {
  await showAdaptiveSheet<void>(
    context: context,
    contentPadsBottom: true,
    builder: (_) => const CreateBotSheet(),
  );
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
  String? _autoPersona;

  /// New bots start as a random cloud bot; the picker can change it or go back to initials.
  String? _avatar = Mascot.random().avatarValue;
  var _busy = false;

  /// The key and model sit under Advanced (D-182) because one is picked for you. When the key it
  /// picks has no default model, choosing one is a required step, so they stay in sight instead.
  var _modelInSight = false;

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
    if (_name.text.trim().isEmpty || _name.text == _autoName) {
      _name.text = name ?? '';
    }
    _autoName = name;
  }

  String _finalName(BuildContext context) => _name.text.trim().isEmpty
      ? context.l10n.defaultBotName
      : _name.text.trim();

  /// Suggests the server's default model for the chosen key until the user picks one.
  void _fillDefaultModel(List<Credential> keys) {
    if (_modelPicked) return;
    for (final k in keys) {
      if (k.id == _credentialId) {
        _model =
            ref.read(backendProvider).defaultModelFor(k.provider.value) ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keysAsync = ref.watch(credentialsProvider);
    final keys = (keysAsync.value ?? const <Credential>[])
        .where((k) => _chatProviders.contains(k.provider))
        .toList();
    if (_credentialId == null || !keys.any((k) => k.id == _credentialId)) {
      _credentialId = preferredKeyId(ref, keys);
      _fillDefaultModel(keys);
      if (_credentialId != null && _model.isEmpty) _modelInSight = true;
    }
    final needsKey = keysAsync.hasValue && keys.isEmpty;
    // Casama Cloud picks the key and the model (D-188): neither is shown.
    final fixedModel = casamaModelFixed(ref);
    final keyFields = [
      DropdownButtonFormField<String>(
        isExpanded: true,
        key: ValueKey('key-$_credentialId-${keys.length}'),
        initialValue: _credentialId,
        decoration: InputDecoration(labelText: l10n.modelKey),
        items: [
          for (final k in keys)
            DropdownMenuItem(
              value: k.id,
              child: Text('${k.label} · ${providerLabel(k.provider)}'),
            ),
        ],
        onChanged: hapticOnChanged(
          (v) => setState(() {
            _credentialId = v;
            _modelPicked = false;
            _fillDefaultModel(keys);
          }),
          haptic: HapticsHelper.selection,
        ),
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
    ];
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: widget.embedded
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              BottomPadding.of(context, minimum: AppSpace.md),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) ...[
            Text(
              l10n.newBot,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.newBotSubtitle,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          // 1. What it does: a persona fills in the instructions, name and icon below.
          TemplatePicker(
            selected: _templateId,
            onChanged: (t) => setState(() {
              _templateId = t?.id;
              _setAutoName(t?.name);
              // The persona's instructions and mascot fill in, unless the user wrote their own.
              if (_persona.text.trim().isEmpty || _persona.text == _autoPersona) {
                _persona.text = t?.persona ?? '';
              }
              _autoPersona = t?.persona;
              if (t?.mascot != null) _avatar = 'mascot:${t!.mascot}';
            }),
            instructions: _InstructionsField(controller: _persona),
          ),
          const SizedBox(height: AppSpace.lg),
          // 2. Who it is: name and icon, with a live preview.
          _FormLabel(l10n.botIdentity),
          const SizedBox(height: AppSpace.xs),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            color: context.isDark
                ? context.colorScheme.surfaceContainer
                : context.colorScheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.fast),
                      child: BotAvatar(
                        key: ValueKey('${_finalName(context)}|$_avatar'),
                        name: _finalName(context),
                        avatar: _avatar,
                        size: 52,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.botName,
                          hintText: l10n.defaultBotName,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                MascotPicker(
                  value: _avatar,
                  scrollable: true,
                  initials: botInitials(_finalName(context)),
                  initialsLabel: l10n.botIconInitials,
                  onChanged: (v) => setState(() => _avatar = v),
                ),
              ],
            ),
          ),
          // A missing key is a required step, so it's asked for in plain sight.
          if (needsKey) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              l10n.addModelKeyFirst,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
          ] else if (_modelInSight && !fixedModel) ...[
            const SizedBox(height: AppSpace.lg),
            ...keyFields,
          ],
          // The key and model already picked for you, folded until asked for (D-182). Casama
          // Cloud has none to show (D-188).
          if (!needsKey && !_modelInSight && !fixedModel) ...[
            const SizedBox(height: AppSpace.xs),
            AdvancedSection(
              id: 'bot.create',
              summary: l10n.createBotAdvancedSummary,
              children: [
                const SizedBox(height: AppSpace.xs),
                ...keyFields,
              ],
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          GlowButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _busy ||
                    _credentialId == null ||
                    (_model.isEmpty && !fixedModel)
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
                            model:
                                casamaLockedModel(ref, _credentialId, listen: false) ??
                                _model,
                            persona: _persona.text.trim(),
                            templateId: _templateId,
                            avatarUrl: _avatar,
                          ),
                    );
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (bot != null) {
                      ref.invalidate(botsProvider);
                      // The manual wizard ends with the first bot (the Welcome chat reports its own end).
                      if (widget.embedded) Analytics.log('onboarding_complete', {'path': 'manual'});
                      // The new bot itself pops up to say hi.
                      showCelebration(context, l10n.celebrateNewBot(bot.name), mascot: Mascot.fromAvatar(bot.avatarUrl));
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

/// A small heading over a part of the new-bot form.
class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.xxs),
    child: Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// The bot's instructions, written inside the persona card: a plain text area under a small
/// heading, with no box of its own.
class _InstructionsField extends StatelessWidget {
  const _InstructionsField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(LucideIcons.scrollText, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.xxs + 2),
            Text(
              context.l10n.persona,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        TextField(
          key: const Key('botInstructions'),
          controller: controller,
          minLines: 3,
          maxLines: 8,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
          decoration: InputDecoration(
            hintText: context.l10n.personaHint,
            hintMaxLines: 3,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          ),
        ),
      ],
    );
  }
}

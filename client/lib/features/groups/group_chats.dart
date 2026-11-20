import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart' show MessageAppMention;
import '../../core/display_text.dart';
import '../../core/local_cache.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/wallpaper.dart';
import '../../ui/motion.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/mascot.dart';
import '../../ui/shell_header.dart';
import '../chat/chat_screen.dart';
import '../chat/widgets/mentions.dart' show AppMentionInfo;
import '../integrations/app_logo.dart';
import '../integrations/connect_app_sheet.dart';
import '../integrations/integrations_screen.dart' show HubApp, hubAppsProvider;

/// Group chats (D-118): 2 to 10 bots in one conversation, woken by @Name or @everyone.
/// Group chats, shown from the offline cache first at launch and refreshed in the background,
/// like bots (D-112), so the chats list has its final shape on its first frame.
class GroupChatsNotifier extends AsyncNotifier<List<Conversation>> {
  var _launched = false;
  var _generation = 0;

  @override
  Future<List<Conversation>> build() async {
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId == null) {
      // Workspaces still loading: stay loading, as the bots do.
      await ref.watch(organizationsProvider.future);
      return const [];
    }
    final backend = ref.watch(backendProvider);
    final cache = ref.watch(localCacheProvider);
    final key = 'groups:$orgId';
    final gen = ++_generation;
    // A group's dots follow its own runs (its status), not its members' (a member busy in its own
    // chat isn't busy here). Bots update live, so a bot starting or stopping work refreshes the list.
    ref.listen(botsProvider.select((a) => _busyIds(a.value)), (prev, next) {
      if (prev != null && !setEquals(prev, next)) unawaited(_refetch(orgId, key));
    });
    final fresh = backend.groupChats(orgId).then((v) {
      unawaited(cacheWrite(cache, key, [for (final c in v) c.toJson()]));
      return v;
    });
    fresh.ignore();
    // Only at launch: after a change (an invalidate) the server's list is awaited.
    if (!_launched) {
      _launched = true;
      final cached = await cacheRead(cache, key);
      if (cached is List) {
        try {
          final list = [for (final j in cached) Conversation.fromJson(Map<String, dynamic>.from(j as Map))];
          unawaited(
            fresh
                .then((v) {
                  if (ref.mounted && gen == _generation) state = AsyncData(v);
                })
                .catchError((_) {}),
          );
          return list;
        } catch (_) {}
      }
    }
    return fresh;
  }

  static Set<String> _busyIds(List<Bot>? bots) => {
    for (final b in bots ?? const <Bot>[])
      if (b.status != BotStatusEnum.idle) b.id,
  };

  Future<void> _refetch(String orgId, String key) async {
    final gen = _generation;
    try {
      final v = await ref.read(backendProvider).groupChats(orgId);
      if (!ref.mounted || gen != _generation) return;
      state = AsyncData(v);
      unawaited(cacheWrite(ref.read(localCacheProvider), key, [for (final c in v) c.toJson()]));
    } catch (_) {
      // Offline: the next change tries again.
    }
  }
}

/// Whether a group chat has a run going in it (or one waiting on the person). Its members must
/// still be busy too, so a status the list hasn't refreshed yet doesn't leave the dots running.
bool groupBusy(Conversation g, List<Bot?> members) =>
    g.status != null && members.any((b) => b != null && b.status != BotStatusEnum.idle);

final groupChatsProvider = AsyncNotifierProvider<GroupChatsNotifier, List<Conversation>>(GroupChatsNotifier.new);

/// A group chat's title, or its bots' names.
String groupTitle(Conversation c, List<Bot> bots) => c.title.isUsable
    ? c.title!
    : c.botIds
          .map((id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');

class GroupChatScreen extends ConsumerWidget {
  const GroupChatScreen({super.key, required this.conversationId, this.draft});
  final String conversationId;

  /// Text to start the composer with (a group chat started by naming a bot in a direct chat).
  final String? draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupChatsProvider).value;
    final g = groups?.where((c) => c.id == conversationId).firstOrNull;
    if (g == null) return const _GroupChatSkeleton();
    return ChatScreen(botId: g.botId, conversationId: g.id, group: true, draft: draft);
  }
}

/// A bot's chat by link (`/bots/{bot}/chat?c={conversation}`). When the conversation is a group
/// chat (a reply or an approval there linked to the bot that spoke, D-413), the group opens as
/// the group; the bot's own chat screen showed its thread under one bot's name.
class BotChatScreen extends ConsumerWidget {
  const BotChatScreen({super.key, required this.botId, this.conversationId, this.focusMessageId, this.draft});
  final String botId;
  final String? conversationId;
  final String? focusMessageId;
  final String? draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = conversationId;
    final group = c == null
        ? null
        : ref.watch(groupChatsProvider.select((groups) => groups.value?.where((g) => g.id == c).firstOrNull));
    if (group != null) return ChatScreen(botId: group.botId, conversationId: group.id, focusMessageId: focusMessageId, group: true);
    return ChatScreen(botId: botId, conversationId: c, focusMessageId: focusMessageId, draft: draft);
  }
}

/// A group chat while the list of groups loads: the chat's header, the thread's placeholder
/// bubbles and the composer's outline, where [ChatScreen] puts them.
class _GroupChatSkeleton extends StatelessWidget {
  const _GroupChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wallpaper(
      force: true,
      child: Scaffold(
        appBar: const ShellHeader(title: ''),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth);
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.md, side, 0),
                    child: const ChatThreadSkeleton(),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xxs, side, AppSpace.xs),
                    // The composer.
                    child: const SkeletonScope(child: SkeletonBone(height: 54, radius: 26)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> showNewGroupChat(BuildContext context, WidgetRef ref) async {
  final id = await showAdaptiveSheet<String>(
    context: context,
    builder: (_) => const _NewGroup(),
  );
  ref.invalidate(groupChatsProvider);
  if (id != null && context.mounted) {
    GoRouter.maybeOf(context)?.go('/groups/$id');
  }
}

class _NewGroup extends ConsumerStatefulWidget {
  const _NewGroup();

  @override
  ConsumerState<_NewGroup> createState() => _NewGroupState();
}

/// The most bots a group chat can hold (the server's rule, D-118).
const _maxGroupBots = 10;

/// New group chat: who's in it (the lead first) at the top, then a name, then the bots to pick.
class _NewGroupState extends ConsumerState<_NewGroup> {
  final _picked = <String>[];
  final _title = TextEditingController();
  final _search = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_picked.remove(id)) return;
      if (_picked.length >= _maxGroupBots) return;
      _picked.add(id);
    });
    HapticsHelper.soft();
  }

  void _makeLead(String id) {
    if (_picked.firstOrNull == id) return;
    setState(() => _picked
      ..remove(id)
      ..insert(0, id));
    HapticsHelper.selection();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final title = _title.text.trim();
    final c = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .createGroupChat(
            _picked.first,
            _picked.skip(1).toList(),
            title: title.isEmpty ? null : title,
          ),
    );
    if (!mounted) return;
    if (c == null) return setState(() => _busy = false);
    HapticsHelper.success();
    Navigator.pop(context, c.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bots = (ref.watch(botsProvider).value ?? const <Bot>[])
        .where((b) => b.archivedAt == null)
        .toList();
    final byId = {for (final b in bots) b.id: b};
    final picked = [
      for (final id in _picked)
        if (byId[id] != null) byId[id]!,
    ];
    final valid = picked.length >= 2 && picked.length <= _maxGroupBots;
    final full = picked.length >= _maxGroupBots;
    final q = _search.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? bots
        : bots.where((b) => b.name.toLowerCase().contains(q)).toList();
    final note = bots.length < 2
        ? l10n.groupNeedTwoBots
        : picked.length < 2
        ? l10n.groupPickMore(2 - picked.length)
        : full
        ? l10n.groupFull
        : l10n.groupLeadHint;
    return FormSheet(
      icon: LucideIcons.users,
      hero: const MascotHero([Mascot.winky, Mascot.giggly, Mascot.wow]),
      title: l10n.newGroupChat,
      subtitle: l10n.newGroupChatHelp,
      submitLabel: l10n.groupCreate,
      submitIcon: LucideIcons.messagesSquare,
      submitKey: const Key('createGroup'),
      busy: _busy,
      onSubmit: valid ? _create : null,
      footer: FormNote(
        note,
        key: const Key('groupNote'),
        icon: picked.length < 2 ? LucideIcons.info : LucideIcons.crown,
      ),
      children: [
        _Crew(bots: picked, onRemove: _toggle, onMakeLead: _makeLead),
        TextField(
          key: const Key('groupTitle'),
          controller: _title,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.groupTitle,
            // Unnamed groups go by their bots' names, so show that.
            hintText: picked.isEmpty
                ? null
                : picked.map((b) => b.name).join(', '),
            floatingLabelBehavior: picked.isEmpty
                ? null
                : FloatingLabelBehavior.always,
            prefixIcon: const Icon(LucideIcons.tag, size: 18),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.groupPickBots,
                style: context.textTheme.labelLarge,
              ),
            ),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                '${picked.length} / $_maxGroupBots',
                key: ValueKey(picked.length),
                style: context.textTheme.labelMedium?.copyWith(
                  color: full ? scheme.primary : scheme.onSurfaceVariant,
                  fontFeatures: AppText.tabular,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (bots.length > 6)
          TextField(
            key: const Key('groupSearch'),
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.groupSearchBots,
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: _search.clear,
                    ),
              isDense: true,
            ),
          ),
        if (shown.isEmpty && bots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Text(
              l10n.groupNoMatch,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        if (shown.isNotEmpty)
          GroupedCard(
            dividerIndent: 64,
            children: [
              for (final b in shown)
                _BotPickRow(
                  bot: b,
                  order: _picked.indexOf(b.id),
                  enabled: !full || _picked.contains(b.id),
                  onTap: () => _toggle(b.id),
                ),
            ],
          ),
      ],
    );
  }
}

/// The group so far: the lead first with a crown, then the others in the order they were picked.
/// Tapping another bot makes it the lead; the small x takes a bot out.
class _Crew extends StatelessWidget {
  const _Crew({
    required this.bots,
    required this.onRemove,
    required this.onMakeLead,
  });
  final List<Bot> bots;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onMakeLead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return AnimatedSize(
      duration: AppMotion.duration,
      curve: AppMotion.curve,
      alignment: Alignment.topCenter,
      child: Container(
        key: const Key('groupCrew'),
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: context.isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.appColors.hairline),
        ),
        child: bots.isEmpty
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        l10n.groupCrewEmpty,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, b) in bots.indexed)
                      _CrewMember(
                        key: ValueKey('crew-${b.id}'),
                        bot: b,
                        lead: i == 0,
                        onRemove: () => onRemove(b.id),
                        onMakeLead: i == 0 ? null : () => onMakeLead(b.id),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CrewMember extends StatelessWidget {
  const _CrewMember({
    super.key,
    required this.bot,
    required this.lead,
    required this.onRemove,
    this.onMakeLead,
  });
  final Bot bot;
  final bool lead;
  final VoidCallback onRemove;
  final VoidCallback? onMakeLead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final face = SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: lead ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: BotAvatar(
                  name: bot.name,
                  avatar: bot.avatarUrl,
                  size: 44,
                ),
              ),
              if (lead)
                Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      child: Icon(
                        LucideIcons.crown,
                        size: 10,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -4,
                bottom: -2,
                child: Semantics(
                  button: true,
                  label: l10n.groupRemoveBot(bot.name),
                  child: InkResponse(
                    key: Key('crewRemove-${bot.id}'),
                    onTap: onRemove,
                    radius: 16,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            bot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: lead ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            lead ? l10n.groupLeadShort : l10n.groupMakeLead,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: lead
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: onMakeLead == null
          ? face
          : Tooltip(
              message: l10n.groupMakeLead,
              child: InkWell(
                key: Key('crewLead-${bot.id}'),
                borderRadius: BorderRadius.circular(AppRadius.tile),
                onTap: onMakeLead,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: face,
                ),
              ),
            ),
    );
    if (onMakeLead == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: tile,
      );
    }
    if (reduce) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppMotion.duration,
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: tile,
    );
  }
}

/// One bot in the list: its face, name and what it's doing, and a check that shows the order it
/// joins in. Once the group is full, the rest dim.
class _BotPickRow extends StatelessWidget {
  const _BotPickRow({
    required this.bot,
    required this.order,
    required this.enabled,
    required this.onTap,
  });
  final Bot bot;

  /// -1 when not picked; 0 is the lead.
  final int order;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final picked = order >= 0;
    final status = switch (bot.status) {
      BotStatusEnum.working => l10n.botStatusWorking,
      BotStatusEnum.waiting => l10n.botStatusWaiting,
      BotStatusEnum.disabled => l10n.botStatusDisabled,
      BotStatusEnum.idle => null,
    };
    final subtitle = order == 0 ? l10n.groupLead : status;
    return Semantics(
      checked: picked,
      enabled: enabled,
      child: Material(
        color: picked
            ? scheme.primary.withValues(alpha: context.isDark ? 0.12 : 0.06)
            : Colors.transparent,
        child: InkWell(
          key: Key('pick-${bot.id}'),
          onTap: enabled ? onTap : null,
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Row(
                children: [
                  BotAvatar(
                    name: bot.name,
                    avatar: bot.avatarUrl,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: order == 0
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: order == 0 ? FontWeight.w600 : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: picked ? scheme.primary : Colors.transparent,
                      border: Border.all(
                        color: picked ? scheme.primary : scheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: !picked
                          ? const SizedBox.shrink()
                          : order == 0
                          ? Icon(
                              LucideIcons.crown,
                              key: const ValueKey('lead'),
                              size: 13,
                              color: scheme.onPrimary,
                            )
                          : Text(
                              '${order + 1}',
                              key: ValueKey(order),
                              style: context.textTheme.labelMedium?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppText.tabular,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Max distinct apps a single message can mention (D-434).
const kMaxMentionedApps = 3;

/// One selectable item in the unified `@` mention picker (D-118, D-434).
sealed class MentionOption {
  const MentionOption();
  String get keyId;
}

class BotMentionOption extends MentionOption {
  const BotMentionOption({required this.token, required this.label, this.bot});
  final String token;
  final String label;

  /// Null for `@everyone`.
  final Bot? bot;

  @override
  String get keyId => 'mention-$token';
}

class AppMentionOption extends MentionOption {
  const AppMentionOption(this.app);
  final AppMentionInfo app;

  @override
  String get keyId =>
      'mention-app-${app.integrationId}${app.toolkit != null ? ':${app.toolkit}' : ''}';
}

class AddAppMentionOption extends MentionOption {
  const AddAppMentionOption(this.app);
  final AppMentionInfo app;

  @override
  String get keyId =>
      'mention-add-${app.integrationId}${app.toolkit != null ? ':${app.toolkit}' : ''}';
}

/// Another of your bots, offered in a direct chat: picking it opens a group chat with both.
class GroupBotMentionOption extends MentionOption {
  const GroupBotMentionOption(this.bot);
  final Bot bot;

  @override
  String get keyId => 'mention-group-${bot.id}';
}

class ConnectAppMentionOption extends MentionOption {
  const ConnectAppMentionOption(this.app);
  final CatalogApp app;

  @override
  String get keyId => 'mention-connect-${app.id}';
}

/// Builds the mentionable apps connected to [attachedIds] and (when [includeAddable]) the
/// workspace apps not yet attached to this bot (D-434).
({List<AppMentionInfo> connected, List<AppMentionInfo> addable})
buildMentionableApps({
  required List<Integration> integrations,
  required Set<String> attachedIds,
  required List<HubApp> hubApps,
  AppCatalog? catalog,
  bool includeAddable = false,
}) {
  final catalogById = <String, CatalogApp>{
    for (final a in catalog?.apps ?? const <CatalogApp>[]) a.id: a,
  };
  final hubAppsByIntegration = <String, List<HubApp>>{};
  for (final h in hubApps) {
    if (h.status != ProviderAccountStatusEnum.connected) continue;
    hubAppsByIntegration.putIfAbsent(h.hub.id, () => []).add(h);
  }

  List<AppMentionInfo> expand(Integration i) {
    final isHub =
        i.kind == IntegrationKind.composio ||
        i.kind == IntegrationKind.pipedream;
    if (isHub) {
      final apps = hubAppsByIntegration[i.id] ?? const <HubApp>[];
      return [
        for (final h in apps)
          AppMentionInfo(
            integrationId: i.id,
            label: h.name,
            toolkit: h.slug,
            appId: h.app?.id ?? h.slug,
            color: h.app?.color ?? catalogById[h.app?.id ?? h.slug]?.color,
            kind: i.kind,
          ),
      ];
    }
    // A catalog app connected under its id ("linear", "zoho_apps") goes by its proper name, as the
    // server labels it; a connection the person named themselves keeps that name.
    final app = i.appId != null ? catalogById[i.appId!] : null;
    final lowerName = i.name.toLowerCase();
    final named = app != null &&
        (lowerName == app.id.toLowerCase() ||
            lowerName.replaceAll('-', '_') == app.id.toLowerCase() ||
            lowerName == app.name.toLowerCase());
    return [
      AppMentionInfo(
        integrationId: i.id,
        label: named ? app.name : i.name,
        appId: i.appId,
        color: app?.color,
        kind: i.kind,
      ),
    ];
  }

  final connected = <AppMentionInfo>[];
  final connectedKeys = <String>{};
  final addable = <AppMentionInfo>[];
  final addableKeys = <String>{};

  for (final i in integrations) {
    if (i.status == IntegrationStatusEnum.error) continue;
    final expanded = expand(i);
    if (attachedIds.contains(i.id)) {
      for (final a in expanded) {
        final k = '${a.integrationId}:${a.toolkit ?? ''}';
        if (connectedKeys.add(k)) connected.add(a);
      }
    } else if (includeAddable) {
      for (final a in expanded) {
        final k = '${a.integrationId}:${a.toolkit ?? ''}';
        if (!connectedKeys.contains(k) && addableKeys.add(k)) addable.add(a);
      }
    }
  }

  return (connected: connected, addable: addable);
}

/// Typing `@` in any chat lists its bots (in group chats) and apps (D-118, D-434): what matches
/// what's typed after "@", which one is highlighted, keyboard navigation (Tab/Enter, arrows, Esc),
/// and the apps explicitly picked for the current draft message.
class MentionController extends ChangeNotifier {
  MentionController(this.input) {
    input.addListener(_update);
  }

  final TextEditingController input;
  bool _group = true;
  List<Bot> _bots = const [];
  List<Bot> _otherBots = const [];
  List<AppMentionInfo> _apps = const [];
  List<AppMentionInfo> _addableApps = const [];
  List<CatalogApp> _catalogApps = const [];
  final List<MessageAppMention> _pickedApps = [];

  List<MentionOption> options = const [];
  int index = 0;
  RegExpMatch? _match;
  String? _dismissedFor;

  /// Optional async handler for Add-to-bot and Connect rows (wired by [MentionPicker]).
  void Function(MentionOption option)? onActionOption;

  /// Fires when the user tries to pick a 4th app in one message.
  VoidCallback? onMaxAppsReached;

  /// Apps explicitly picked from the `@` menu that are still present in [input.text].
  List<MessageAppMention> get pickedApps => List.unmodifiable(_pickedApps);

  set group(bool v) {
    if (_group == v) return;
    _group = v;
    _update();
  }

  set bots(List<Bot> v) {
    if (listEquals(
      v.map((b) => b.id).toList(),
      _bots.map((b) => b.id).toList(),
    )) {
      return;
    }
    _bots = v;
    _update();
  }

  /// Direct chats: your other bots, each a way into a group chat with this one.
  set otherBots(List<Bot> v) {
    if (listEquals(
      v.map((b) => '${b.id}|${b.name}').toList(),
      _otherBots.map((b) => '${b.id}|${b.name}').toList(),
    )) {
      return;
    }
    _otherBots = v;
    _update();
  }

  set apps(List<AppMentionInfo> v) {
    if (_sameAppInfoList(v, _apps)) return;
    _apps = v;
    _update();
  }

  set addableApps(List<AppMentionInfo> v) {
    if (_sameAppInfoList(v, _addableApps)) return;
    _addableApps = v;
    _update();
  }

  set catalogApps(List<CatalogApp> v) {
    if (listEquals(
      v.map((a) => a.id).toList(),
      _catalogApps.map((a) => a.id).toList(),
    )) {
      return;
    }
    _catalogApps = v;
    _update();
  }

  static bool _sameAppInfoList(List<AppMentionInfo> a, List<AppMentionInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].integrationId != b[i].integrationId ||
          a[i].toolkit != b[i].toolkit ||
          a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }

  bool get active => options.isNotEmpty;

  static final _trigger = RegExp(r'(^|\s)@([\w .\-]{0,30})$');

  /// The most Connect rows in one list, and the length popular apps fill a list up to.
  static const _maxConnectRows = 5;
  static const _shortList = 6;

  void _update() {
    final text = input.text;
    // Prune any picked app whose @Label was deleted from the draft text.
    if (_pickedApps.isNotEmpty) {
      final lowerText = text.toLowerCase();
      _pickedApps.removeWhere((p) => !lowerText.contains('@${p.label.toLowerCase()}'));
    }

    final m = _trigger.firstMatch(text);
    _match = m;
    final rawQ = m?.group(2);
    final q = rawQ?.toLowerCase() ?? '';
    final List<MentionOption> next;
    if (m == null || _dismissedFor == text) {
      next = const [];
    } else {
      final items = <MentionOption>[];

      // 1. Bots (group chats only — preserves exact order: everyone, then bots).
      if (_group && _bots.isNotEmpty) {
        if ('everyone'.startsWith(q)) {
          items.add(const BotMentionOption(token: 'everyone', label: 'everyone'));
        }
        for (final b in _bots) {
          if (b.name.toLowerCase().startsWith(q)) {
            items.add(BotMentionOption(token: b.name, label: b.name, bot: b));
          }
        }
      }

      // 2. Apps connected to this bot (or any bot in this group).
      final matchingApps = _filterApps(_apps, q);
      for (final a in matchingApps.take(8)) {
        items.add(AppMentionOption(a));
      }

      // 3. Workspace apps not yet attached to this bot (direct chat only).
      if (!_group && _addableApps.isNotEmpty) {
        final matchingAddable = _filterApps(_addableApps, q);
        for (final a in matchingAddable.take(5)) {
          items.add(AddAppMentionOption(a));
        }
      }

      // 4. Direct chats: your other bots. A direct chat has one bot, so naming another one
      // starts a group chat with both.
      if (!_group) {
        final prefix = _otherBots.where((b) => b.name.toLowerCase().startsWith(q));
        final contains = q.isEmpty
            ? const <Bot>[]
            : _otherBots.where(
                (b) => !b.name.toLowerCase().startsWith(q) && b.name.toLowerCase().contains(q),
              );
        for (final b in [...prefix, ...contains].take(q.isEmpty ? 3 : 5)) {
          items.add(GroupBotMentionOption(b));
        }
      }

      // 5. Apps not connected yet. From 2 typed letters, any catalog app that matches. Before
      // that, popular ones fill a short list, so a bare "@" always opens something to pick.
      if (_catalogApps.isNotEmpty) {
        final alreadyIds = <String>{
          for (final a in _apps) ...[?a.appId?.toLowerCase(), ?a.toolkit?.toLowerCase()],
          for (final a in _addableApps) ...[?a.appId?.toLowerCase(), ?a.toolkit?.toLowerCase()],
        };
        final Iterable<CatalogApp> suggested;
        if (q.length >= 2) {
          suggested = _filterCatalog(_catalogApps, q, alreadyIds).take(_maxConnectRows);
        } else {
          final room = (_shortList - items.length).clamp(0, _maxConnectRows);
          suggested = _catalogApps
              .where((c) =>
                  c.popular &&
                  !alreadyIds.contains(c.id.toLowerCase()) &&
                  (c.name.toLowerCase().startsWith(q) || c.id.toLowerCase().startsWith(q)))
              .take(room);
        }
        for (final c in suggested) {
          items.add(ConnectAppMentionOption(c));
        }
      }

      next = items;
    }
    if (next.length != options.length || index >= next.length) index = 0;
    options = next;
    notifyListeners();
  }

  static List<AppMentionInfo> _filterApps(List<AppMentionInfo> list, String q) {
    if (q.isEmpty) return list;
    final prefix = <AppMentionInfo>[];
    final contains = <AppMentionInfo>[];
    for (final a in list) {
      final terms = [
        a.label.toLowerCase(),
        if (a.toolkit != null) a.toolkit!.toLowerCase(),
        if (a.appId != null) a.appId!.toLowerCase(),
      ];
      if (terms.any((t) => t.startsWith(q))) {
        prefix.add(a);
      } else if (terms.any((t) => t.contains(q))) {
        contains.add(a);
      }
    }
    return [...prefix, ...contains];
  }

  static List<CatalogApp> _filterCatalog(
    List<CatalogApp> list,
    String q,
    Set<String> excludeIds,
  ) {
    final prefix = <CatalogApp>[];
    final contains = <CatalogApp>[];
    for (final c in list) {
      final idLower = c.id.toLowerCase();
      if (excludeIds.contains(idLower)) continue;
      final nameLower = c.name.toLowerCase();
      if (nameLower.startsWith(q) || idLower.startsWith(q)) {
        prefix.add(c);
      } else if (nameLower.contains(q) || idLower.contains(q)) {
        contains.add(c);
      }
    }
    return [...prefix, ...contains];
  }

  /// The draft with `@[label] ` in place of what was typed after `@`, or appended if `@` moved.
  String withMention(String label) {
    final text = input.text;
    final m = _trigger.firstMatch(text);
    if (m != null) {
      final start = text.length - m.group(2)!.length;
      return '${text.substring(0, start)}$label ';
    }
    final sep = text.isEmpty || text.endsWith(' ') ? '' : ' ';
    return '$text$sep@$label ';
  }

  /// Inserts `@[label] ` in place of what was typed after `@`, or appends it if `@` moved.
  void insertMention(String label) {
    final value = withMention(label);
    input.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  /// Records a picked app (respecting the 3-app cap) and inserts `@[app.label] `.
  /// Returns false if the 3-app limit was hit.
  bool pickApp(AppMentionInfo app) {
    final already = _pickedApps.any(
      (p) => p.integrationId == app.integrationId && p.toolkit == app.toolkit,
    );
    if (!already && _pickedApps.length >= kMaxMentionedApps) {
      _dismissedFor = input.text;
      _update();
      onMaxAppsReached?.call();
      return false;
    }
    if (!already) {
      _pickedApps.add(
        MessageAppMention(
          integrationId: app.integrationId,
          label: app.label,
          toolkit: app.toolkit,
          appId: app.appId,
          source: 'picker',
        ),
      );
    }
    insertMention(app.label);
    return true;
  }

  /// Clears picked apps (e.g. after sending a message).
  void clearPickedApps() {
    if (_pickedApps.isEmpty) return;
    _pickedApps.clear();
    notifyListeners();
  }

  /// Restores picked apps (e.g. if sending failed before the bubble showed).
  void restorePickedApps(List<MessageAppMention> apps) {
    for (final a in apps) {
      final exists = _pickedApps.any(
        (p) => p.integrationId == a.integrationId && p.toolkit == a.toolkit,
      );
      if (!exists && _pickedApps.length < kMaxMentionedApps) {
        _pickedApps.add(a);
      }
    }
    notifyListeners();
  }

  /// Picks option [i]: bots & connected apps complete synchronously; Add, Connect and starting a
  /// group chat delegate to [onActionOption].
  void pick(int i) {
    if (_match == null || i < 0 || i >= options.length) return;
    final option = options[i];
    switch (option) {
      case BotMentionOption(:final token):
        insertMention(token);
      case AppMentionOption(:final app):
        pickApp(app);
      case AddAppMentionOption():
      case ConnectAppMentionOption():
      case GroupBotMentionOption():
        final handler = onActionOption;
        if (handler != null) {
          handler(option);
        }
    }
  }

  /// The composer asks first: Tab or Enter picks the highlighted row, arrows move, Esc closes.
  KeyEventResult handleKey(KeyEvent e) {
    if (!active || e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.tab ||
        k == LogicalKeyboardKey.enter ||
        k == LogicalKeyboardKey.numpadEnter) {
      pick(index);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      index =
          (index + (k == LogicalKeyboardKey.arrowDown ? 1 : -1)) %
          options.length;
      notifyListeners();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _dismissedFor = input.text;
      _update();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    input.removeListener(_update);
    super.dispose();
  }
}

class MentionPicker extends ConsumerWidget {
  const MentionPicker({
    super.key,
    required this.botIds,
    required this.controller,
    this.group,
    this.lastSpeakerId,
  });

  final List<String> botIds;
  final MentionController controller;

  /// True in group chats (shows Bots + WhoAnswers); defaults to `botIds.length > 1`.
  final bool? group;

  /// The bot that spoke last; with no mention, it answers (else the lead, the first of [botIds]).
  final String? lastSpeakerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = group ?? botIds.length > 1;
    final bots = (ref.watch(botsProvider).value ?? const <Bot>[])
        .where((b) => botIds.contains(b.id))
        .toList();
    final integrations = ref.watch(integrationsProvider).value ?? const <Integration>[];
    final catalog = ref.watch(appCatalogProvider).value;
    final hubApps = ref.watch(hubAppsProvider).value ?? const <HubApp>[];
    final attachedIds = <String>{
      for (final id in botIds)
        ...(ref.watch(botIntegrationIdsProvider(id)).value ?? const <String>{}),
    };
    final org = ref.watch(currentOrgProvider);
    final canManageBot = org == null || org.role != OrgRole.member;
    final built = buildMentionableApps(
      integrations: integrations,
      attachedIds: attachedIds,
      hubApps: hubApps,
      catalog: catalog,
      includeAddable: canManageBot && !isGroup && botIds.length == 1,
    );

    final allBots = ref.watch(botsProvider).value ?? const <Bot>[];
    controller
      ..group = isGroup
      ..bots = isGroup ? bots : const []
      ..otherBots = isGroup
          ? const []
          : [
              for (final b in allBots)
                if (b.archivedAt == null && !botIds.contains(b.id)) b,
            ]
      ..apps = built.connected
      ..addableApps = built.addable
      ..catalogApps = catalog?.apps ?? const []
      ..onMaxAppsReached = () {
        if (context.mounted) showFailure(context, context.l10n.mentionMaxApps);
      }
      ..onActionOption = (option) => _handleActionOption(
        context,
        ref,
        option,
        isGroup: isGroup,
        bots: bots,
      );

    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final options = controller.options;
        if (options.isEmpty) {
          if (!isGroup) return const SizedBox.shrink();
          return _WhoAnswers(
            bots: bots,
            text: controller.input.text,
            lastSpeakerId: lastSpeakerId,
            leadId: botIds.firstOrNull,
          );
        }

        final botOptions = <(int, BotMentionOption)>[];
        final appOptions = <(int, AppMentionOption)>[];
        final addOptions = <(int, AddAppMentionOption)>[];
        final connectOptions = <(int, ConnectAppMentionOption)>[];
        final groupOptions = <(int, GroupBotMentionOption)>[];
        for (final (i, o) in options.indexed) {
          switch (o) {
            case BotMentionOption():
              botOptions.add((i, o));
            case AppMentionOption():
              appOptions.add((i, o));
            case AddAppMentionOption():
              addOptions.add((i, o));
            case ConnectAppMentionOption():
              connectOptions.add((i, o));
            case GroupBotMentionOption():
              groupOptions.add((i, o));
          }
        }

        // One list for bots and apps alike. Detect bot-vs-app name collisions in group chats so rows get clear "Bot"/"App" badges.
        final botNamesLower = {for (final b in bots) b.name.toLowerCase()};
        final appNamesLower = {
          for (final (_, a) in appOptions) a.app.label.toLowerCase(),
        };
        final showSections =
            [
              botOptions.isNotEmpty,
              appOptions.isNotEmpty,
              addOptions.isNotEmpty,
              connectOptions.isNotEmpty,
            ].where((x) => x).length >
            1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Material(
              key: const Key('mentionPicker'),
              color: scheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (botOptions.isNotEmpty) ...[
                      if (showSections)
                        _MentionSectionLabel(l10n.mentionSectionBots),
                      for (final (i, o) in botOptions)
                        _MentionRow(
                          key: Key(o.keyId),
                          selected: i == controller.index,
                          leading: o.bot == null
                              ? GroupAvatar(bots: bots, size: 22)
                              : BotAvatar(
                                  name: o.bot!.name,
                                  avatar: o.bot!.avatarUrl,
                                  size: 22,
                                ),
                          title: o.bot == null ? l10n.mentionEveryone : o.label,
                          badge:
                              o.bot != null &&
                                  appNamesLower.contains(
                                    o.bot!.name.toLowerCase(),
                                  )
                              ? l10n.mentionBadgeBot
                              : null,
                          onTap: () => controller.pick(i),
                        ),
                    ],
                    if (appOptions.isNotEmpty) ...[
                      if (showSections)
                        _MentionSectionLabel(l10n.mentionSectionApps),
                      for (final (i, o) in appOptions)
                        _MentionRow(
                          key: Key(o.keyId),
                          selected: i == controller.index,
                          leading: AppLogo(
                            appId:
                                o.app.appId ??
                                (o.app.kind == IntegrationKind.mcp
                                    ? 'mcp'
                                    : null),
                            name: o.app.label,
                            color: o.app.color,
                            icon: o.app.appId != null
                                ? null
                                : _iconForIntegrationKind(o.app.kind),
                            size: 22,
                          ),
                          title: o.app.label,
                          badge:
                              isGroup &&
                                  botNamesLower.contains(
                                    o.app.label.toLowerCase(),
                                  )
                              ? l10n.mentionBadgeApp
                              : null,
                          onTap: () => controller.pick(i),
                        ),
                    ],
                    if (addOptions.isNotEmpty) ...[
                      _MentionSectionLabel(l10n.mentionSectionAddToBot),
                      for (final (i, o) in addOptions)
                        _MentionRow(
                          key: Key(o.keyId),
                          selected: i == controller.index,
                          leading: AppLogo(
                            appId:
                                o.app.appId ??
                                (o.app.kind == IntegrationKind.mcp
                                    ? 'mcp'
                                    : null),
                            name: o.app.label,
                            color: o.app.color,
                            icon: o.app.appId != null
                                ? null
                                : _iconForIntegrationKind(o.app.kind),
                            size: 22,
                          ),
                          title: o.app.label,
                          trailingAction: l10n.mentionAddAction,
                          onTap: () => controller.pick(i),
                        ),
                    ],
                    if (groupOptions.isNotEmpty) ...[
                      _MentionSectionLabel(l10n.mentionSectionStartGroup),
                      for (final (i, o) in groupOptions)
                        _MentionRow(
                          key: Key(o.keyId),
                          selected: i == controller.index,
                          leading: BotAvatar(
                            name: o.bot.name,
                            avatar: o.bot.avatarUrl,
                            size: 22,
                          ),
                          title: o.bot.name,
                          onTap: () => controller.pick(i),
                        ),
                    ],
                    if (connectOptions.isNotEmpty) ...[
                      _MentionSectionLabel(l10n.mentionSectionConnect),
                      for (final (i, o) in connectOptions)
                        _MentionRow(
                          key: Key(o.keyId),
                          selected: i == controller.index,
                          leading: AppLogo(
                            appId: o.app.id,
                            name: o.app.name,
                            color: o.app.color,
                            size: 22,
                          ),
                          title: o.app.name,
                          trailingAction: l10n.mentionConnectAction,
                          onTap: () => controller.pick(i),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleActionOption(
    BuildContext context,
    WidgetRef ref,
    MentionOption option, {
    required bool isGroup,
    required List<Bot> bots,
  }) async {
    switch (option) {
      case AddAppMentionOption(:final app):
        final botId = botIds.firstOrNull;
        if (botId == null) return;
        final ok = await runGuarded(context, () async {
          await ref
              .read(backendProvider)
              .setBotIntegration(botId, app.integrationId, true);
          return true;
        });
        if (ok != true) return;
        ref
          ..invalidate(botIntegrationIdsProvider(botId))
          ..invalidate(integrationsProvider);
        controller.pickApp(app);
        if (context.mounted) {
          final botName = bots.firstOrNull?.name ?? '';
          if (botName.isNotEmpty) {
            showSuccess(context, context.l10n.appAddedToBot(app.label, botName));
          }
        }
      case ConnectAppMentionOption(:final app):
        Analytics.log('app_mention_connect_started', {'app_id': app.id});
        final created = await showConnectApp(context, app);
        if (created == null) return;
        // The new connection goes to the bot that will answer: this chat's bot, or in a group the
        // bots the message goes to (@everyone: the lead, who plans first). Else the run would only
        // say it doesn't have the app.
        final answerers = !isGroup
            ? [?botIds.firstOrNull]
            : [
                for (final b in groupAnswerers(
                      bots,
                      controller.input.text,
                      lastSpeakerId: lastSpeakerId,
                      leadId: botIds.firstOrNull,
                    ) ??
                    [?bots.where((b) => b.id == botIds.firstOrNull).firstOrNull])
                  b.id,
              ];
        if (answerers.isNotEmpty && context.mounted) {
          await runGuarded(context, () async {
            for (final id in answerers) {
              await ref.read(backendProvider).setBotIntegration(id, created.id, true);
            }
            return true;
          });
        }
        ref
          ..invalidate(integrationsProvider)
          ..invalidate(hubAppsProvider);
        for (final id in botIds) {
          ref.invalidate(botIntegrationIdsProvider(id));
        }
        controller.pickApp(
          AppMentionInfo(
            integrationId: created.id,
            // A hub connection (Composio, Pipedream) holds many apps: name the one picked, or
            // the server can't match the reference to the hub's toolkit.
            toolkit: switch (created.kind) {
              IntegrationKind.composio => app.composio ?? app.id,
              IntegrationKind.pipedream => app.id,
              _ => null,
            },
            label: app.name,
            appId: app.id,
            color: app.color,
            kind: created.kind,
          ),
        );
      case GroupBotMentionOption(:final bot):
        final botId = botIds.firstOrNull;
        if (botId == null) return;
        // The draft goes along, naming the bot that was picked, so it is the one that answers.
        final draft = controller.withMention(bot.name);
        final group = await runGuarded(context, () async {
          final pair = {botId, bot.id};
          final groups = await ref.read(groupChatsProvider.future);
          final existing = groups
              .where((g) => g.botIds.length == 2 && g.botIds.toSet().containsAll(pair))
              .firstOrNull;
          return existing ?? await ref.read(backendProvider).createGroupChat(botId, [bot.id]);
        });
        if (group == null || !context.mounted) return;
        Analytics.log('group_chat_from_mention');
        ref.invalidate(groupChatsProvider);
        controller.input.clear();
        GoRouter.maybeOf(context)?.go(
          Uri(path: '/groups/${group.id}', queryParameters: {'draft': draft}).toString(),
        );
      case BotMentionOption():
      case AppMentionOption():
        break;
    }
  }

  static IconData? _iconForIntegrationKind(IntegrationKind? kind) =>
      switch (kind) {
        IntegrationKind.mcp => null,
        IntegrationKind.openapi => LucideIcons.braces,
        IntegrationKind.composio => LucideIcons.blocks,
        IntegrationKind.pipedream => LucideIcons.cable,
        IntegrationKind.localMcp => LucideIcons.laptop,
        IntegrationKind.a2a => LucideIcons.bot,
        null => LucideIcons.plug,
      };
}

class _MentionSectionLabel extends StatelessWidget {
  const _MentionSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MentionRow extends StatelessWidget {
  const _MentionRow({
    super.key,
    required this.selected,
    required this.leading,
    required this.title,
    this.badge,
    this.trailingAction,
    required this.onTap,
  });

  final bool selected;
  final Widget leading;
  final String title;
  final String? badge;
  final String? trailingAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.6) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (trailingAction != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingAction!,
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A group chat's icon: its first two bots' avatars, overlapping, in the space of one avatar.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.bots,
    this.size = 30,
    this.ringColor,
  });
  final List<Bot> bots;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final ring = ringColor ?? context.colorScheme.surface;
    if (bots.isEmpty) {
      return SizedBox.square(
        dimension: size,
        child: Icon(
          LucideIcons.users,
          size: size * 0.66,
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (bots.length == 1) {
      return BotAvatar(
        name: bots.first.name,
        avatar: bots.first.avatarUrl,
        size: size,
      );
    }
    final small = size * 0.7;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: BotAvatar(
              name: bots[0].name,
              avatar: bots[0].avatarUrl,
              size: small,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              // A ring in the background color separates the two faces.
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
              child: BotAvatar(
                name: bots[1].name,
                avatar: bots[1].avatarUrl,
                size: small - 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether [lower] (lowercased message text) @mentions [bot] by name.
bool mentionsBot(String lower, Bot bot) =>
    RegExp('(^|[^\\w@])@${RegExp.escape(bot.name.toLowerCase())}(?!\\w)').hasMatch(lower);

/// Who a group message goes to (D-118): the bots it @mentions, or with no mention the last bot that
/// spoke (else the lead); null for @everyone. Matches the server's rule.
List<Bot>? groupAnswerers(List<Bot> bots, String text, {String? lastSpeakerId, String? leadId}) {
  if (bots.isEmpty) return const [];
  final lower = text.toLowerCase();
  final everyone = RegExp(
    r'(^|[^\w@])@(everyone|all|team)\b',
    caseSensitive: false,
  ).hasMatch(text);
  if (everyone) return null;
  final named = [
    for (final b in [...bots]..sort((a, b) => b.name.length - a.name.length))
      if (mentionsBot(lower, b)) b,
  ];
  if (named.isNotEmpty) return named;
  return [
    bots.where((b) => b.id == lastSpeakerId).firstOrNull ??
        bots.where((b) => b.id == leadId).firstOrNull ??
        bots.first,
  ];
}

/// Who a group message goes to (D-118), shown above the composer: the bots it @mentions, everyone,
/// or with no mention the last bot that spoke (else the lead). Matches the server's rule.
class _WhoAnswers extends StatelessWidget {
  const _WhoAnswers({
    required this.bots,
    required this.text,
    required this.lastSpeakerId,
    required this.leadId,
  });
  final List<Bot> bots;
  final String text;
  final String? lastSpeakerId;
  final String? leadId;

  // The group's bots load after the chat: the line slides in over the composer, not a jump.
  @override
  Widget build(BuildContext context) => ShowHide(child: bots.length < 2 ? null : _line(context));

  Widget _line(BuildContext context) {
    final l10n = context.l10n;
    final who = groupAnswerers(bots, text, lastSpeakerId: lastSpeakerId, leadId: leadId);
    // Nobody named: the answer goes to the fallback bot, and the line hints at @.
    final noneNamed = who != null && !mentionsBot(text.toLowerCase(), who.first);
    final label = who == null
        ? l10n.groupEveryoneAnswers
        : l10n.groupWhoAnswers(who.map((b) => b.name).join(', '));
    final scheme = context.colorScheme;
    return Padding(
      key: const Key('groupWhoAnswers'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        children: [
          who == null
              ? GroupAvatar(bots: bots, size: 18)
              : (who.length == 1
                    ? BotAvatar(
                        name: who.first.name,
                        avatar: who.first.avatarUrl,
                        size: 18,
                      )
                    : GroupAvatar(bots: who, size: 18)),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (noneNamed)
                    TextSpan(text: ' · ${l10n.groupMentionHint}'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

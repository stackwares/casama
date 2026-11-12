import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/wallpaper.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/shell_header.dart';
import '../chat/chat_screen.dart';

/// Group chats (D-118): 2 to 10 bots in one conversation, woken by @Name or @everyone.
final groupChatsProvider = FutureProvider<List<Conversation>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).groupChats(org.id);
});

/// A group chat's title, or its bots' names.
String groupTitle(Conversation c, List<Bot> bots) => c.title.isUsable
    ? c.title!
    : c.botIds
          .map((id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');

class GroupChatScreen extends ConsumerWidget {
  const GroupChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupChatsProvider).value;
    final g = groups?.where((c) => c.id == conversationId).firstOrNull;
    if (g == null) return const _GroupChatSkeleton();
    return ChatScreen(botId: g.botId, conversationId: g.id, group: true);
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

/// Typing @ in a group chat lists its bots; picking one finishes the mention.
/// The @-mention suggestions of a group chat's composer (D-118): what matches what's typed after
/// "@", which one is highlighted, and the keys that pick one (Tab or Enter, arrows, Esc).
class MentionController extends ChangeNotifier {
  MentionController(this.input) {
    input.addListener(_update);
  }
  final TextEditingController input;
  List<Bot> _bots = const [];
  List<(String, String, Bot?)> options = const [];
  int index = 0;
  RegExpMatch? _match;
  String? _dismissedFor;

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

  bool get active => options.isNotEmpty;

  void _update() {
    final text = input.text;
    final m = RegExp(r'(^|\s)@([\w ]{0,30})$').firstMatch(text);
    _match = m;
    final q = m?.group(2)?.toLowerCase();
    final next = m == null || _dismissedFor == text
        ? const <(String, String, Bot?)>[]
        : [
            ('everyone', 'everyone', null),
            for (final b in _bots)
              if (b.name.toLowerCase().startsWith(q!)) (b.name, b.name, b),
          ].where((o) => o.$1.toLowerCase().startsWith(q!)).toList();
    if (next.length != options.length || index >= next.length) index = 0;
    options = next;
    notifyListeners();
  }

  /// Puts the chosen name in place of what was typed after "@".
  void pick(int i) {
    final m = _match;
    if (m == null || i < 0 || i >= options.length) return;
    final text = input.text;
    final start = text.length - m.group(2)!.length;
    final value = '${text.substring(0, start)}${options[i].$1} ';
    input.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  /// The composer asks first: Tab or Enter picks the highlighted name, arrows move, Esc closes.
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
    this.lastSpeakerId,
  });
  final List<String> botIds;
  final MentionController controller;

  /// The bot that spoke last; with no mention, it answers (else the lead, the first of [botIds]).
  final String? lastSpeakerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = (ref.watch(botsProvider).value ?? const <Bot>[])
        .where((b) => botIds.contains(b.id))
        .toList();
    controller.bots = bots;
    final scheme = context.colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final options = controller.options;
        if (options.isEmpty) {
          return _WhoAnswers(
            bots: bots,
            text: controller.input.text,
            lastSpeakerId: lastSpeakerId,
            leadId: botIds.firstOrNull,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(
            key: const Key('mentionPicker'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, o) in options.indexed)
                ActionChip(
                  key: Key('mention-${o.$1}'),
                  // The highlighted one is what Tab or Enter picks.
                  backgroundColor: i == controller.index
                      ? scheme.primaryContainer
                      : null,
                  side: BorderSide(
                    color: i == controller.index
                        ? scheme.primary.withValues(alpha: 0.5)
                        : scheme.outlineVariant,
                  ),
                  avatar: o.$3 == null
                      ? GroupAvatar(bots: bots, size: 20)
                      : BotAvatar(
                          name: o.$3!.name,
                          avatar: o.$3!.avatarUrl,
                          size: 20,
                        ),
                  label: Text(
                    o.$3 == null ? context.l10n.mentionEveryone : o.$2,
                  ),
                  onPressed: () => controller.pick(i),
                ),
            ],
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    if (bots.length < 2) return const SizedBox.shrink();
    final l10n = context.l10n;
    final lower = text.toLowerCase();
    final everyone = RegExp(
      r'(^|[^\w@])@(everyone|all|team)\b',
      caseSensitive: false,
    ).hasMatch(text);
    final named = [
      for (final b in [...bots]..sort((a, b) => b.name.length - a.name.length))
        if (RegExp('(^|[^\\w@])@${RegExp.escape(b.name.toLowerCase())}(?!\\w)')
            .hasMatch(lower))
          b,
    ];
    final fallback =
        bots.where((b) => b.id == lastSpeakerId).firstOrNull ??
        bots.where((b) => b.id == leadId).firstOrNull ??
        bots.first;
    final who = everyone ? null : (named.isEmpty ? [fallback] : named);
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
                  if (named.isEmpty && !everyone)
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

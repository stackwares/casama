import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as ep;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/backend.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/adaptive_modal.dart';
import '../../../ui/bot_avatar.dart';
import '../../../ui/bottom_padding.dart';
import '../../../ui/person_avatar.dart';
import '../../../core/remote_content.dart';

/// Where a reaction was made, for analytics (D-331).
enum ReactionSurface { menu, hover, doubleTap, chip, picker }

extension ReactionSurfaceName on ReactionSurface {
  String get analyticsName => switch (this) {
    ReactionSurface.menu => 'menu',
    ReactionSurface.hover => 'hover',
    ReactionSurface.doubleTap => 'double_tap',
    ReactionSurface.chip => 'chip',
    ReactionSurface.picker => 'picker',
  };
}

/// Sets your reaction to [emoji], or takes it back when [emoji] is null.
typedef ReactCallback = void Function(String? emoji, ReactionSurface surface);

/// The six quick reactions and a + for the full picker, in one row (D-331). Your current one
/// is circled; picking it again takes it back.
class QuickReactionStrip extends StatelessWidget {
  const QuickReactionStrip({
    super.key,
    this.mine,
    required this.onPick,
    required this.onMore,
  });
  final String? mine;
  final ValueChanged<String> onPick;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Row(
      key: const Key('quickReactions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final emoji in remoteQuickReactions(quickReactions))
          Semantics(
            button: true,
            selected: emoji == mine,
            label: emoji == mine
                ? l10n.reactionRemove(emoji)
                : l10n.reactionQuick(emoji),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: InkResponse(
                key: Key('quickReaction-$emoji'),
                radius: 22,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPick(emoji);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: emoji == mine
                        ? scheme.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24, height: 1),
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          key: const Key('moreReactions'),
          tooltip: l10n.moreReactions,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: scheme.onSurfaceVariant,
          onPressed: onMore,
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }
}

/// The quick strip as the first entry of a popup menu: picking pops the menu with
/// `react:<emoji>`, the + with `react:+`.
class ReactionStripMenuEntry extends PopupMenuEntry<String> {
  const ReactionStripMenuEntry({super.key, this.mine});
  final String? mine;

  static const pickedPrefix = 'react:';
  static const more = 'react:+';

  @override
  double get height => 52;

  @override
  bool represents(String? value) => false;

  @override
  State<ReactionStripMenuEntry> createState() => _ReactionStripMenuEntryState();
}

class _ReactionStripMenuEntryState extends State<ReactionStripMenuEntry> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpace.xs,
      vertical: AppSpace.xxs,
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: QuickReactionStrip(
        mine: widget.mine,
        onPick: (e) =>
            Navigator.of(context)
                .pop('${ReactionStripMenuEntry.pickedPrefix}$e'),
        onMore: () => Navigator.of(context).pop(ReactionStripMenuEntry.more),
      ),
    ),
  );
}

/// Opens the quick strip on its own at [at] (the hover bar's smile, right-click "React").
/// Returns the picked emoji, `+` for the full picker, or null.
Future<String?> showReactionStrip(
  BuildContext context,
  Offset at, {
  String? mine,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final picked = await showMenu<String>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
    ),
    position: RelativeRect.fromRect(
      at & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [ReactionStripMenuEntry(mine: mine)],
  );
  if (picked == null ||
      !picked.startsWith(ReactionStripMenuEntry.pickedPrefix)) {
    return null;
  }
  return picked == ReactionStripMenuEntry.more
      ? '+'
      : picked.substring(ReactionStripMenuEntry.pickedPrefix.length);
}

/// What a strip pick means: the full picker for `+`, your current emoji takes it back, anything
/// else sets it. Calls [onReact] unless nothing was chosen.
Future<void> applyStripPick(
  BuildContext context,
  String? picked,
  String? mine,
  ReactCallback onReact,
  ReactionSurface surface,
) async {
  if (picked == null) return;
  if (picked == '+') {
    final emoji = await pickReactionEmoji(context);
    if (emoji != null && emoji != mine) onReact(emoji, ReactionSurface.picker);
    return;
  }
  onReact(picked == mine ? null : picked, surface);
}

/// The full emoji picker in a sheet (D-331): search, categories, recents and skin tones.
Future<String?> pickReactionEmoji(BuildContext context) {
  return showAdaptiveSheet<String>(
    context: context,
    heightFactor: 0.6,
    contentPadsBottom: true,
    builder: (sheet) {
      final scheme = sheet.colorScheme;
      final l10n = sheet.l10n;
      final background = scheme.surfaceContainerLow;
      return Padding(
        padding: EdgeInsets.only(
          bottom: BottomPadding.of(sheet, minimum: AppSpace.md),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => ep.EmojiPicker(
            key: const Key('emojiPicker'),
            onEmojiSelected: (_, emoji) => Navigator.of(sheet).pop(emoji.emoji),
            config: ep.Config(
              height: constraints.maxHeight,
              locale: Localizations.localeOf(context),
              emojiViewConfig: ep.EmojiViewConfig(
                columns: (constraints.maxWidth / 48).floor().clamp(6, 12),
                emojiSizeMax: 28,
                backgroundColor: background,
                noRecents: const SizedBox.shrink(),
              ),
              categoryViewConfig: ep.CategoryViewConfig(
                backgroundColor: background,
                indicatorColor: scheme.primary,
                iconColor: scheme.onSurfaceVariant,
                iconColorSelected: scheme.primary,
                backspaceColor: scheme.primary,
                dividerColor: context.appColors.hairline,
              ),
              bottomActionBarConfig: ep.BottomActionBarConfig(
                showBackspaceButton: false,
                backgroundColor: background,
                buttonColor: background,
                buttonIconColor: scheme.onSurfaceVariant,
              ),
              searchViewConfig: ep.SearchViewConfig(
                backgroundColor: background,
                buttonIconColor: scheme.onSurfaceVariant,
                hintText: l10n.searchEmoji,
              ),
              skinToneConfig: ep.SkinToneConfig(
                dialogBackgroundColor: scheme.surfaceContainerHighest,
                indicatorColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The reactions under a message (D-331): one chip per emoji with its count, yours outlined.
/// Tapping a chip adds that reaction or takes yours back; holding it (or right-clicking) shows
/// who reacted.
class ReactionChips extends StatelessWidget {
  const ReactionChips({
    super.key,
    required this.groups,
    this.onReact,
    this.onShowPeople,
    this.alignEnd = false,
  });
  final List<ReactionGroup> groups;
  final ReactCallback? onReact;
  final ValueChanged<String>? onShowPeople;

  /// Under your own messages, on the right.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: alignEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Wrap(
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        spacing: AppSpace.xxs,
        runSpacing: AppSpace.xxs,
        children: [
          for (final g in groups)
            _ReactionChip(
              group: g,
              onReact: onReact,
              onShowPeople: onShowPeople,
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.group, this.onReact, this.onShowPeople});
  final ReactionGroup group;
  final ReactCallback? onReact;
  final ValueChanged<String>? onShowPeople;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final mine = group.mine;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      side: BorderSide(
        color: mine ? scheme.primary : context.appColors.hairline,
        width: mine ? 1.5 : 1,
      ),
    );
    final react = onReact;
    final people = onShowPeople;
    return Semantics(
      button: react != null,
      selected: mine,
      label: mine
          ? l10n.reactionChipMine(group.emoji, group.count)
          : l10n.reactionChip(group.emoji, group.count),
      onLongPressHint: people == null ? null : l10n.reactionsTitle,
      excludeSemantics: true,
      child: Material(
        key: Key('reactionChip-${group.emoji}'),
        color: mine
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.surfaceContainerHigh,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onSecondaryTap: people == null ? null : () => people(group.emoji),
          child: InkWell(
            onTap: react == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    react(mine ? null : group.emoji, ReactionSurface.chip);
                  },
            onLongPress: people == null ? null : () => people(group.emoji),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28, minWidth: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.xxs,
                  children: [
                    Text(
                      group.emoji,
                      style: const TextStyle(fontSize: 15, height: 1.1),
                    ),
                    if (group.count > 1 || mine)
                      Text(
                        '${group.count}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: mine
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Who reacted to a message (D-331): a tab for all of them and one per emoji. Your own row
/// takes your reaction back when tapped.
Future<void> showReactionPeople(
  BuildContext context, {
  required List<ReactionGroup> groups,
  required Future<List<ReactionPerson>> Function() load,
  String? me,
  String? initialEmoji,
  VoidCallback? onRemoveMine,
}) {
  return showAdaptiveSheet<void>(
    context: context,
    heightFactor: 0.6,
    contentPadsBottom: true,
    builder: (sheet) => _ReactionPeople(
      groups: groups,
      load: load,
      me: me,
      initialEmoji: initialEmoji,
      onRemoveMine: onRemoveMine,
    ),
  );
}

class _ReactionPeople extends StatefulWidget {
  const _ReactionPeople({
    required this.groups,
    required this.load,
    this.me,
    this.initialEmoji,
    this.onRemoveMine,
  });
  final List<ReactionGroup> groups;
  final Future<List<ReactionPerson>> Function() load;
  final String? me;
  final String? initialEmoji;
  final VoidCallback? onRemoveMine;

  @override
  State<_ReactionPeople> createState() => _ReactionPeopleState();
}

class _ReactionPeopleState extends State<_ReactionPeople> {
  late final Future<List<ReactionPerson>> _people = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final emojis = [for (final g in widget.groups) g.emoji];
    final total = widget.groups.fold<int>(0, (n, g) => n + g.count);
    final start = widget.initialEmoji == null
        ? 0
        : emojis.indexOf(widget.initialEmoji!) + 1;
    return DefaultTabController(
      length: emojis.length + 1,
      initialIndex: start.clamp(0, emojis.length),
      child: Column(
        key: const Key('reactionPeople'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Text(
              l10n.reactionsTitle,
              style: context.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            tabs: [
              Tab(
                key: const Key('reactionTab-all'),
                text: '${l10n.reactionsAll} $total',
              ),
              for (final g in widget.groups)
                Tab(
                  key: Key('reactionTab-${g.emoji}'),
                  text: '${g.emoji} ${g.count}',
                ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<ReactionPerson>>(
              future: _people,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(l10n.reactionsLoadFailed));
                }
                final people = snap.data;
                if (people == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return TabBarView(
                  children: [
                    _list(context, people),
                    for (final e in emojis)
                      _list(context, [
                        for (final p in people)
                          if (p.emoji == e) p,
                      ]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<ReactionPerson> people) {
    final l10n = context.l10n;
    if (people.isEmpty) return Center(child: Text(l10n.reactionsNone));
    return ListView.builder(
      padding: EdgeInsets.only(
        top: AppSpace.xs,
        bottom: BottomPadding.of(context, minimum: AppSpace.lg),
      ),
      itemCount: people.length,
      itemBuilder: (context, i) {
        final p = people[i];
        final you = widget.me != null && p.userId == widget.me;
        final remove = widget.onRemoveMine;
        return ListTile(
          key: Key('reactionPerson-$i'),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          leading: p.botId != null
              ? BotAvatar(name: p.name, avatar: p.avatarUrl, size: 36)
              : PersonAvatar(label: p.name, photoUrl: p.avatarUrl),
          title: Text(
            you ? l10n.reactionsYou : p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: you && remove != null
              ? Text(l10n.reactionsTapToRemove)
              : null,
          trailing: Text(p.emoji, style: const TextStyle(fontSize: 22)),
          onTap: you && remove != null
              ? () {
                  Navigator.of(context).pop();
                  remove();
                }
              : null,
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
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
import '../../ui/adaptive_modal.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
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
    if (g == null) return const Scaffold(body: SkeletonMessages());
    return ChatScreen(botId: g.botId, conversationId: g.id, group: true);
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

class _NewGroupState extends ConsumerState<_NewGroup> {
  final _picked = <String>[];
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final valid = _picked.length >= 2 && _picked.length <= 10;
    return FormSheet(
      icon: LucideIcons.users,
      title: l10n.newGroupChat,
      subtitle: l10n.newGroupChatHelp,
      submitLabel: l10n.create,
      submitKey: const Key('createGroup'),
      onSubmit: !valid
          ? null
          : () async {
              final c = await runGuarded(
                context,
                () => ref
                    .read(backendProvider)
                    .createGroupChat(
                      _picked.first,
                      _picked.skip(1).toList(),
                      title: _title.text.trim().isEmpty
                          ? null
                          : _title.text.trim(),
                    ),
              );
              if (c != null && context.mounted) Navigator.pop(context, c.id);
            },
      children: [
        TextField(
          key: const Key('groupTitle'),
          controller: _title,
          decoration: InputDecoration(labelText: l10n.groupTitle),
        ),
        Text(l10n.groupPickBots, style: Theme.of(context).textTheme.labelLarge),
        for (final b in bots)
          CheckboxListTile(
            key: Key('pick-${b.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(b.name),
            subtitle: _picked.isNotEmpty && _picked.first == b.id
                ? Text(l10n.groupLead)
                : null,
            value: _picked.contains(b.id),
            onChanged: hapticOnChanged(
              (v) => setState(
                () => v == true ? _picked.add(b.id) : _picked.remove(b.id),
              ),
              haptic: HapticsHelper.soft,
            ),
          ),
      ],
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

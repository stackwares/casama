import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../chat/chat_screen.dart';

/// Group chats (D-118): 2 to 10 bots in one conversation, woken by @Name or @everyone.
final groupChatsProvider = FutureProvider<List<Conversation>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).groupChats(org.id);
});

/// A group chat's title, or its bots' names.
String groupTitle(Conversation c, List<Bot> bots) =>
    (c.title?.isNotEmpty ?? false) ? c.title! : c.botIds.map((id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '').where((n) => n.isNotEmpty).join(', ');

class GroupChatScreen extends ConsumerWidget {
  const GroupChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupChatsProvider).value;
    final g = groups?.where((c) => c.id == conversationId).firstOrNull;
    if (g == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ChatScreen(botId: g.botId, conversationId: g.id, group: true);
  }
}

Future<void> showNewGroupChat(BuildContext context, WidgetRef ref) async {
  final id = await showAdaptiveSheet<String>(context: context, builder: (_) => const _NewGroup());
  ref.invalidate(groupChatsProvider);
  if (id != null && context.mounted) GoRouter.maybeOf(context)?.go('/groups/$id');
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
                () => ref.read(backendProvider).createGroupChat(_picked.first, _picked.skip(1).toList(), title: _title.text.trim().isEmpty ? null : _title.text.trim()),
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
            subtitle: _picked.isNotEmpty && _picked.first == b.id ? Text(l10n.groupLead) : null,
            value: _picked.contains(b.id),
            onChanged: (v) => setState(() => v == true ? _picked.add(b.id) : _picked.remove(b.id)),
          ),
      ],
    );
  }
}

/// Typing @ in a group chat lists its bots; picking one finishes the mention.
class MentionPicker extends ConsumerWidget {
  const MentionPicker({super.key, required this.botIds, required this.input});
  final List<String> botIds;
  final TextEditingController input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = (ref.watch(botsProvider).value ?? const <Bot>[]).where((b) => botIds.contains(b.id)).toList();
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: input,
      builder: (context, value, _) {
        final m = RegExp(r'(^|\s)@([\w ]{0,30})$').firstMatch(value.text);
        if (m == null) return const SizedBox.shrink();
        final q = m.group(2)!.toLowerCase();
        final options = [
          ('everyone', context.l10n.mentionEveryone),
          for (final b in bots)
            if (b.name.toLowerCase().startsWith(q)) (b.name, b.name),
        ].where((o) => o.$1.toLowerCase().startsWith(q)).toList();
        if (options.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(
            key: const Key('mentionPicker'),
            spacing: 6,
            children: [
              for (final o in options)
                ActionChip(
                  key: Key('mention-${o.$1}'),
                  avatar: const Icon(LucideIcons.atSign, size: 16),
                  label: Text(o.$2),
                  onPressed: () {
                    final start = value.text.length - m.group(2)!.length;
                    final text = '${value.text.substring(0, start)}${o.$1} ';
                    input.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

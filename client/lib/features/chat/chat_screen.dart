import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'chat_controller.dart';
import 'widgets/chat_widgets.dart';

/// The computer a bot uses: its private computer, else the team computer.
Computer? computerForBot(List<Computer> computers, String botId) {
  for (final c in computers) {
    if (c.ownerBotId == botId) return c;
  }
  for (final c in computers) {
    if (c.kind == ComputerKindEnum.team) return c;
  }
  return computers.isEmpty ? null : computers.first;
}

Future<void> confirmRestore(BuildContext context, WidgetRef ref, String computerId, String checkpointId) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(l10n.restoreConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.restore)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final done = await runGuarded(context, () async {
    await ref.read(backendProvider).restoreCheckpoint(computerId, checkpointId);
    return true;
  });
  if (done == true && context.mounted) showMessage(context, l10n.restored);
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.botId, this.conversationId});
  final String botId;
  final String? conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (old.botId != widget.botId || old.conversationId != widget.conversationId) {
      Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).send(text));
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(widget.botId));
    final chat = ref.watch(chatControllerProvider(widget.botId));
    final controller = ref.read(chatControllerProvider(widget.botId).notifier);
    final computer = computerForBot(ref.watch(computersProvider).value ?? const [], widget.botId);
    ref.listen(chatControllerProvider(widget.botId), (_, _) => _scrollToEnd());
    final name = bot?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: l10n.newChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: chat.running ? null : controller.newChat,
          ),
          _ConversationsMenu(botId: widget.botId),
          IconButton(
            tooltip: l10n.activity,
            icon: const Icon(Icons.timeline),
            onPressed: () => context.push('/bots/${widget.botId}/activity'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => context.push('/bots/${widget.botId}/$v'),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'memory', child: Text(l10n.memory)),
              PopupMenuItem(value: 'routines', child: Text(l10n.routines)),
              PopupMenuItem(value: 'integrations', child: Text(l10n.botIntegrations)),
              PopupMenuItem(value: 'settings', child: Text(l10n.botSettings)),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: chat.loading
              ? const Center(child: CircularProgressIndicator())
              : chat.entries.isEmpty
                  ? EmptyState(icon: Icons.chat_bubble_outline, message: l10n.emptyChat(name))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.entries.length,
                      itemBuilder: (context, i) => switch (chat.entries[i]) {
                        final MessageEntry m => MessageBubble(key: ValueKey(m.id), entry: m),
                        final ToolEntry t => ToolCard(key: ValueKey(t.callId), entry: t),
                        final ApprovalEntry a => ApprovalPrompt(key: ValueKey(a.approvalId), entry: a, botName: name),
                        final NoticeEntry n => NoticeLine(
                            entry: n,
                            onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp),
                          ),
                      },
                    ),
        ),
        if (chat.running || chat.tokens > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              if (chat.running) const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text(l10n.runCost(formatUsd(chat.costUsd), chat.tokens), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: CallbackShortcuts(
                  bindings: {const SingleActivator(LogicalKeyboardKey.enter): _send},
                  child: TextField(
                    key: const Key('messageInput'),
                    controller: _input,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(hintText: l10n.messageHint(name)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (chat.running)
                IconButton.filledTonal(
                  key: const Key('stopButton'),
                  tooltip: l10n.stop,
                  icon: const Icon(Icons.stop),
                  onPressed: () => runGuarded(context, controller.cancel),
                )
              else
                IconButton.filled(key: const Key('sendButton'), tooltip: l10n.send, icon: const Icon(Icons.send), onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ConversationsMenu extends ConsumerWidget {
  const _ConversationsMenu({required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(conversationsProvider(botId)).value ?? const <Conversation>[];
    return PopupMenuButton<String>(
      tooltip: context.l10n.conversations,
      icon: const Icon(Icons.forum_outlined),
      onOpened: () => ref.invalidate(conversationsProvider(botId)),
      onSelected: (id) => context.go('/bots/$botId/chat?c=$id'),
      itemBuilder: (_) => [
        for (final c in convos.take(30))
          PopupMenuItem(
            value: c.id,
            child: ListTile(
              dense: true,
              title: Text(c.title ?? '…', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(relativeTime(c.lastMessageAt ?? c.createdAt, context)),
            ),
          ),
      ],
    );
  }
}

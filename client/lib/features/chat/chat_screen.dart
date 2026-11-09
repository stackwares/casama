import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/shell_header.dart';
import '../home/home_shell.dart';
import 'chat_controller.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/composer.dart';

/// The computer a bot uses: its private computer, else the team computer.
Computer? computerForBot(List<Computer> computers, String botId, {String? defaultComputerId}) {
  for (final c in computers) {
    if (defaultComputerId != null && c.id == defaultComputerId) return c;
  }
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
  final ok = await showConfirm(context: context, title: l10n.restore, message: l10n.restoreConfirm, confirmLabel: l10n.restore);
  if (!ok || !context.mounted) return;
  final done = await runGuarded(context, () async {
    await ref.read(backendProvider).restoreCheckpoint(computerId, checkpointId);
    return true;
  });
  if (done == true && context.mounted) showMessage(context, l10n.restored);
}

/// Phones close the keyboard after sending so the reply has the screen.
bool get _touchFirst => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// Starter requests: the emoji is decoration; tapping sends the sentence.
List<(String, String)> _suggestions(BuildContext context) {
  final l10n = context.l10n;
  return [
    ('🔎', l10n.suggestResearch),
    ('🗂️', l10n.suggestFiles),
    ('🌐', l10n.suggestWebsite),
    ('🧰', l10n.suggestCapabilities),
  ];
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
  final _showJump = ValueNotifier(false);
  var _recording = false;
  var _transcribing = false;
  var _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (old.botId != widget.botId || old.conversationId != widget.conversationId) {
      _stickToBottom = true;
      Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    _showJump.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final distance = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    _stickToBottom = distance < 120;
    _showJump.value = distance > 400;
  }

  void _followIfAtBottom({bool force = false}) {
    if (!force && !_stickToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent, duration: AppMotion.of(context, const Duration(milliseconds: 380)), curve: AppMotion.curve);
  }

  Future<void> _send([String? text]) async {
    final message = text ?? _input.text;
    if (message.trim().isEmpty) return;
    if (text == null) _input.clear();
    _stickToBottom = true;
    if (_touchFirst) FocusManager.instance.primaryFocus?.unfocus();
    await runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).send(message));
    if (!_touchFirst && mounted) _focus.requestFocus();
  }

  /// Dictation: tap to record, tap again to transcribe into the message box.
  Future<void> _toggleDictation() async {
    final dictation = ref.read(dictationProvider);
    if (!_recording) {
      final ok = await dictation.start();
      if (!mounted) return;
      if (!ok) {
        showMessage(context, context.l10n.micPermissionNeeded);
        return;
      }
      setState(() => _recording = true);
      return;
    }
    setState(() {
      _recording = false;
      _transcribing = true;
    });
    final clip = await dictation.stop();
    if (clip != null && mounted) {
      final text = await runGuarded(context, () => ref.read(backendProvider).transcribe(widget.botId, clip.$1, clip.$2));
      if (text != null && text.isNotEmpty) {
        _input.text = _input.text.isEmpty ? text : '${_input.text} $text';
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
      }
    }
    if (mounted) setState(() => _transcribing = false);
  }

  Future<void> _speak(String messageId) async {
    final audio = await runGuarded(context, () => ref.read(backendProvider).speech(messageId));
    if (audio != null) await ref.read(speechPlayerProvider).play(audio);
  }

  String _modelLabel(Bot? bot) {
    final choice = bot?.modelPolicy.primary;
    if (choice == null) return '';
    final options = ref.watch(modelOptionsProvider(choice.credentialId)).value?.items ?? const <ModelOption>[];
    for (final o in options) {
      if (o.id == choice.model) return o.name.contains(': ') ? o.name.split(': ').last : o.name;
    }
    return choice.model.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(widget.botId));
    final chat = ref.watch(chatControllerProvider(widget.botId));
    final controller = ref.read(chatControllerProvider(widget.botId).notifier);
    final computer = computerForBot(ref.watch(computersProvider).value ?? const [], widget.botId, defaultComputerId: bot?.defaultComputerId);
    ref.listen(chatControllerProvider(widget.botId), (prev, next) {
      final opened = (prev?.loading ?? false) && !next.loading;
      _followIfAtBottom(force: opened || (next.entries.length > (prev?.entries.length ?? 0) && next.entries.lastOrNull is MessageEntry && (next.entries.last as MessageEntry).role == 'user'));
    });
    final name = bot?.name ?? '';
    final layout = layoutFor(MediaQuery.sizeOf(context).width);
    final status = chat.running ? l10n.botStatusWorking : (bot?.status == BotStatusEnum.waiting ? l10n.botStatusWaiting : _modelLabel(bot));

    return Scaffold(
      appBar: ShellHeader(
        title: name,
        subtitle: status,
        showBack: layout == LayoutSize.phone ? true : null,
        leading: layout == LayoutSize.phone
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/bots'),
                  ),
                ),
              )
            : null,
        titleLeading: BotAvatar(name: name.isEmpty ? '?' : name, size: 36, status: chat.running ? BotStatusEnum.working : bot?.status),
        onTitleTap: () => context.push('/bots/${widget.botId}/settings'),
        actions: [
          // Phones keep the header light: new chat lives in the conversations sheet there.
          if (layout != LayoutSize.phone)
            HeaderIconButton(
              icon: Icons.edit_square,
              tooltip: l10n.newChat,
              onPressed: chat.running || chat.entries.isEmpty ? null : controller.newChat,
            ),
          HeaderIconButton(
            icon: Icons.history_rounded,
            tooltip: l10n.conversations,
            onPressed: () => _showConversations(context, chat.conversationId),
          ),
          HeaderIconButton(
            key: const Key('callButton'),
            icon: Icons.call_outlined,
            tooltip: l10n.startCall,
            onPressed: () => context.push('/bots/${widget.botId}/call${chat.conversationId == null ? '' : '?c=${chat.conversationId}'}'),
          ),
          if (layout == LayoutSize.desktop)
            HeaderIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: ref.watch(computerPanelProvider) ? l10n.hideComputer : l10n.showComputer,
              selected: ref.watch(computerPanelProvider),
              onPressed: ref.read(computerPanelProvider.notifier).toggle,
            ),
          _MoreMenu(botId: widget.botId, showComputer: layout != LayoutSize.desktop),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth);
        final background = Theme.of(context).scaffoldBackgroundColor;
        final Widget thread;
        if (chat.loading) {
          thread = const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)));
        } else if (chat.entries.isEmpty) {
          thread = _EmptyThread(name: name, side: side, onAsk: _send);
        } else {
          final rows = _buildRows(context, chat, name, computer);
          thread = ListView.builder(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(side, AppSpace.md, side, AppSpace.xl),
            itemCount: rows.length,
            itemBuilder: (context, i) => Padding(
              key: rows[i].key,
              padding: EdgeInsets.only(top: i == 0 ? 0 : rows[i].gap),
              child: rows[i].fresh ? rows[i].build().appMessageEntrance() : rows[i].build(),
            ),
          );
        }
        return Column(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: thread),
              // The thread fades out above the composer instead of being cut.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: AppSpace.md,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [background.withValues(alpha: 0), background]),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: AppSpace.sm,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showJump,
                    builder: (context, show, _) => IgnorePointer(
                      ignoring: !show,
                      child: AnimatedSlide(
                        offset: show ? Offset.zero : const Offset(0, 0.4),
                        duration: AppMotion.of(context, AppMotion.fast),
                        curve: AppMotion.curve,
                        child: AnimatedOpacity(
                          opacity: show ? 1 : 0,
                          duration: AppMotion.of(context, AppMotion.fast),
                          child: IconButton.filledTonal(
                            tooltip: l10n.jumpToLatest,
                            onPressed: _jumpToLatest,
                            icon: const Icon(Icons.arrow_downward_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: context.colorScheme.surfaceContainerHigh,
                              foregroundColor: context.colorScheme.onSurface,
                              side: BorderSide(color: context.appColors.hairline),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, AppSpace.xxs, side, AppSpace.xs),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ChatComposer(
                  controller: _input,
                  focusNode: _focus,
                  hint: l10n.messageHint(name),
                  running: chat.running,
                  onSend: _send,
                  onStop: () => runGuarded(context, controller.cancel),
                  recording: _recording,
                  transcribing: _transcribing,
                  onDictate: _toggleDictation,
                ),
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: chat.tokens > 0
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.runCost(formatUsd(chat.costUsd), chat.tokens),
                            style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  /// Turns the chat into rows: one bot header per turn, consecutive tool steps grouped in a card,
  /// and a working indicator while the bot thinks between steps.
  List<_Row> _buildRows(BuildContext context, ChatState chat, String name, Computer? computer) {
    final rows = <_Row>[];
    final entries = chat.entries;
    var lastSide = '';
    final freshFrom = entries.length - 1;

    void botSide(String key) {
      if (lastSide != 'bot') {
        rows.add(_Row(ValueKey('hdr-$key'), lastSide.isEmpty ? 0 : AppSpace.xl, () => BotTurnHeader(name: name), header: true));
      }
      lastSide = 'bot';
    }

    String? workingStatus() {
      for (final e in entries.reversed) {
        if (e is ToolEntry && e.status == ToolStatus.running) return '${toolLabel(context.l10n, e.tool).$1}…';
        if (e is MessageEntry) break;
      }
      return null;
    }

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final fresh = i >= freshFrom && chat.running;
      switch (e) {
        case MessageEntry(role: 'user'):
          rows.add(_Row(ValueKey(e.id), lastSide.isEmpty ? 0 : AppSpace.xl, () => UserBubble(text: e.text), fresh: fresh));
          lastSide = 'user';
        case final MessageEntry m:
          botSide(m.id);
          rows.add(_Row(
            ValueKey(m.id),
            rows.last.header ? 0 : AppSpace.sm,
            () => AssistantMessage(entry: m, status: workingStatus(), onSpeak: !m.streaming ? () => _speak(m.id) : null),
          ));
        case ToolEntry():
          final group = <ToolEntry>[e];
          // Consecutive steps share one card; the computer starting up in between doesn't split it.
          while (i + 1 < entries.length) {
            final next = entries[i + 1];
            if (next is ToolEntry) {
              group.add(next);
              i++;
            } else if (next is NoticeEntry && next.kind == NoticeKind.computer && i + 2 < entries.length && entries[i + 2] is ToolEntry) {
              i++;
            } else {
              break;
            }
          }
          botSide(e.callId);
          rows.add(_Row(
            ValueKey('tools-${e.callId}'),
            rows.last.header ? 0 : AppSpace.sm,
            () => ToolGroupCard(steps: group),
          ));
        case final ApprovalEntry a:
          botSide(a.approvalId);
          rows.add(_Row(ValueKey(a.approvalId), AppSpace.sm, () => ApprovalPrompt(entry: a, botName: name), fresh: fresh));
        case final TakeoverEntry t:
          botSide('takeover-$i');
          rows.add(_Row(
            ValueKey('takeover-$i'),
            AppSpace.sm,
            () => TakeoverPrompt(entry: t, botName: name, onOpen: () => context.push('/computer/live?c=${t.computerId}')),
            fresh: fresh,
          ));
        case final NoticeEntry n:
          final last = i == entries.length - 1;
          rows.add(_Row(ValueKey('notice-$i'), AppSpace.sm, () {
            final line = NoticeLine(entry: n, onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp));
            if (!(last && n.kind == NoticeKind.failed && chat.lastUserText != null && !chat.running)) return line;
            return Column(children: [
              line,
              const SizedBox(height: AppSpace.xs),
              TextButton.icon(
                onPressed: () => runGuarded(context, ref.read(chatControllerProvider(widget.botId).notifier).retry),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.l10n.retry),
              ),
            ]);
          }));
      }
    }

    // Thinking between steps, or before the first word of the reply.
    final last = entries.lastOrNull;
    final waitingOnPerson = last is ApprovalEntry && last.decision == null;
    final replying = last is MessageEntry && last.role == 'assistant' && last.streaming;
    final toolRunning = last is ToolEntry && last.status == ToolStatus.running;
    if (chat.running && !waitingOnPerson && !replying && !toolRunning) {
      botSide('working');
      rows.add(_Row(
        const ValueKey('working'),
        rows.last.header ? 0 : AppSpace.md,
        () => WorkingIndicator(status: workingStatus() ?? context.l10n.thinking),
      ));
    }
    return rows;
  }

  Future<void> _showConversations(BuildContext context, String? currentId) async {
    ref.invalidate(conversationsProvider(widget.botId));
    await showAdaptiveSheet<void>(
      context: context,
      heightFactor: 0.7,
      builder: (sheetContext) => _ConversationsSheet(
        botId: widget.botId,
        currentId: currentId,
        onNew: () {
          Navigator.of(sheetContext).pop();
          ref.read(chatControllerProvider(widget.botId).notifier).newChat();
        },
        onOpen: (id) {
          Navigator.of(sheetContext).pop();
          context.go('/bots/${widget.botId}/chat?c=$id');
        },
      ),
    );
  }
}

class _Row {
  _Row(this.key, this.gap, this.build, {this.fresh = false, this.header = false});
  final Key key;
  final double gap;
  final Widget Function() build;

  /// The bot's name above its turn; the first row after it needs no gap.
  final bool header;

  /// Animates in (the newest entries while a run streams).
  final bool fresh;
}

/// The first open: the bot's mark and one line of what it can do, centered above starter requests
/// parked by the composer.
class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.name, required this.side, required this.onAsk});
  final String name;
  final double side;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final suggestions = _suggestions(context);
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(side, AppSpace.lg, side, AppSpace.md),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Column(mainAxisSize: MainAxisSize.min, children: [
                _HeroMark(name: name).appCardEntrance(),
                const SizedBox(height: AppSpace.lg),
                Text(
                  l10n.emptyChat(name),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ).appCardEntrance(delay: const Duration(milliseconds: 60)),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.chatEmptySubtitle(name),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                ).appCardEntrance(delay: const Duration(milliseconds: 100)),
              ]),
              const Spacer(),
              for (var i = 0; i < suggestions.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs),
                  child: AppCard(
                    key: Key('suggestion-$i'),
                    onTap: () => onAsk(suggestions[i].$2),
                    radius: AppRadius.tile,
                    padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
                    child: Row(children: [
                      ExcludeSemantics(child: SizedBox(width: 24, child: Text(suggestions[i].$1, style: const TextStyle(fontSize: 17, height: 1)))),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(suggestions[i].$2, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35)),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Icon(Icons.arrow_upward_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ]),
                  ).appListItemEntrance(i + 2),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    const size = 88.0;
    return SizedBox(
      width: size + 14,
      height: size + 10,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        BotAvatar(name: name.isEmpty ? '?' : name, size: size),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome_rounded, size: 17, color: scheme.onPrimary),
          ),
        ),
      ]),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.botId, required this.showComputer});
  final String botId;
  final bool showComputer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    MenuItemButton item(IconData icon, String label, VoidCallback onPressed) =>
        MenuItemButton(leadingIcon: Icon(icon, size: 20), onPressed: onPressed, child: Padding(padding: const EdgeInsets.only(right: 24), child: Text(label)));
    return MenuAnchor(
      alignmentOffset: const Offset(-140, 6),
      menuChildren: [
        item(Icons.timeline_rounded, l10n.activity, () => context.push('/bots/$botId/activity')),
        if (showComputer) item(Icons.desktop_windows_outlined, l10n.navComputer, () => context.go('/computer')),
        item(Icons.psychology_outlined, l10n.memory, () => context.push('/bots/$botId/memory')),
        item(Icons.schedule_rounded, l10n.routines, () => context.push('/bots/$botId/routines')),
        item(Icons.extension_outlined, l10n.botIntegrations, () => context.push('/bots/$botId/integrations')),
        const Divider(),
        item(Icons.tune_rounded, l10n.botSettings, () => context.push('/bots/$botId/settings')),
      ],
      builder: (context, controller, _) => HeaderIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: l10n.moreActions,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _ConversationsSheet extends ConsumerWidget {
  const _ConversationsSheet({required this.botId, required this.currentId, required this.onNew, required this.onOpen});
  final String botId;
  final String? currentId;
  final VoidCallback onNew;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final convos = ref.watch(conversationsProvider(botId));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SheetTitle(
        l10n.conversations,
        trailing: FilledButton.tonalIcon(onPressed: onNew, icon: const Icon(Icons.edit_square, size: 18), label: Text(l10n.newChat)),
      ),
      Expanded(
        child: AsyncView(
          value: convos,
          onRetry: () => ref.invalidate(conversationsProvider(botId)),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.forum_outlined, message: l10n.noConversations)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final current = c.id == currentId;
                    return ListTile(
                      selected: current,
                      leading: Icon(current ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded, size: 20),
                      title: Text(
                        c.title ?? l10n.untitledChat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: current ? FontWeight.w700 : FontWeight.w500),
                      ),
                      trailing: Text(
                        relativeTime(c.lastMessageAt ?? c.createdAt, context),
                        style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      onTap: () => onOpen(c.id),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

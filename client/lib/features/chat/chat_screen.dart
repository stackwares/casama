import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/glow_button.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/shell_header.dart';
import '../files/file_preview.dart';
import '../home/home_shell.dart';
import 'chat_controller.dart';
import 'widgets/bot_ui.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/composer.dart';
import 'widgets/error_details.dart';

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
  return [('🔎', l10n.suggestResearch), ('🗂️', l10n.suggestFiles), ('🌐', l10n.suggestWebsite), ('🧰', l10n.suggestCapabilities)];
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.botId, this.conversationId, this.focusMessageId});
  final String botId;
  final String? conversationId;

  /// A message to scroll to and highlight once the conversation loads (from search; D-103).
  final String? focusMessageId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  /// Interactive UIs bots show in this chat (D-086); what the person does goes back as a message.
  late final _botUi = BotUiHost(onAction: _onUiAction);
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _showJump = ValueNotifier(false);
  var _recording = false;
  var _transcribing = false;
  var _stickToBottom = true;
  late String? _focusPending = widget.focusMessageId;
  String? _highlight;
  final _focusKey = GlobalKey();
  final _pending = <_Pending>[];
  /// Skills picked with / for the next message (D-104).
  final _pickedSkills = <String>[];
  var _dragging = false;

  static const _maxFileBytes = 25 * 1024 * 1024;

  bool get _uploading => _pending.any((p) => p.ref == null && !p.failed);

  String? _computerId() {
    final bot = ref.read(botProvider(widget.botId));
    return computerForBot(ref.read(computersProvider).value ?? const [], widget.botId, defaultComputerId: bot?.defaultComputerId)?.id;
  }

  /// Uploads each file to the bot's computer right away (workspace/uploads), so Send only waits
  /// for what is still in flight.
  Future<void> _addFiles(List<(String, Uint8List, String?)> files) async {
    final computerId = _computerId();
    if (computerId == null) {
      showMessage(context, context.l10n.noComputerForFiles);
      return;
    }
    for (final (name, bytes, mime) in files) {
      if (bytes.length > _maxFileBytes) {
        showMessage(context, context.l10n.fileTooLarge(name));
        continue;
      }
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
      final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
      final item = _Pending(name: name, bytes: bytes, mime: (mime == null || mime.isEmpty) ? mimeFor(name) : mime, apiPath: 'uploads/$stamp-$safe');
      setState(() => _pending.add(item));
      try {
        await ref.read(backendProvider).uploadFile(computerId, item.apiPath, bytes);
        if (!mounted) return;
        setState(() => item.ref = AttachmentRef(path: 'workspace/${item.apiPath}', name: name, mimeType: item.mime, size: bytes.length));
      } catch (_) {
        if (!mounted) return;
        setState(() => item.failed = true);
        showMessage(context, context.l10n.uploadFailed(name));
      }
    }
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    await _addFiles([for (final f in picked) (f.name, await f.readAsBytes(), null)]);
  }

  Future<void> _pickPhotos() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 90, maxWidth: 2560);
    if (images.isEmpty) return;
    await _addFiles([for (final x in images) (x.name, await x.readAsBytes(), x.mimeType)]);
  }

  Future<void> _takePhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90, maxWidth: 2560);
    if (x == null) return;
    await _addFiles([(x.name, await x.readAsBytes(), x.mimeType)]);
  }

  Future<void> _dropped(DropDoneDetails detail) async {
    setState(() => _dragging = false);
    await _addFiles([for (final f in detail.files) (f.name, await f.readAsBytes(), f.mimeType)]);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (old.botId != widget.botId || old.conversationId != widget.conversationId || old.focusMessageId != widget.focusMessageId) {
      _stickToBottom = true;
      _focusPending = widget.focusMessageId;
      Future.microtask(() => ref.read(chatControllerProvider(widget.botId).notifier).open(widget.conversationId));
    }
  }

  void _onUiAction(BotUiAction action) {
    final chat = ref.read(chatControllerProvider(widget.botId));
    if (chat.running || chat.answeredUi.contains(action.surfaceId)) return;
    runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).send(uiActionSummary(action), uiAction: action.toJson()));
  }

  @override
  void dispose() {
    _botUi.dispose();
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

  /// Scrolls to the searched message: exactly when its row is built, else a rough jump first so
  /// the lazy list builds it, then exactly. It stays highlighted for a moment.
  void _scrollToFocus(String id, int index, int count) {
    _focusPending = null;
    _highlight = id;
    void exact([int tries = 3]) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _focusKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.3);
        } else if (tries > 0 && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent * (count <= 1 ? 0 : index / (count - 1)));
          exact(tries - 1);
        }
      });
    }

    _stickToBottom = false;
    exact();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _highlight == id) setState(() => _highlight = null);
    });
  }

  void _followIfAtBottom({bool force = false}) {
    if (_focusPending != null) return;
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
    final attachments = text == null
        ? [
            for (final p in _pending)
              if (p.ref != null) p.ref!,
          ]
        : const <AttachmentRef>[];
    if (message.trim().isEmpty && attachments.isEmpty) return;
    if (_uploading && text == null) return;
    final skills = text == null ? [..._pickedSkills] : const <String>[];
    if (text == null) {
      _input.clear();
      setState(() {
        _pending.clear();
        _pickedSkills.clear();
      });
    }
    _stickToBottom = true;
    if (_touchFirst) FocusManager.instance.primaryFocus?.unfocus();
    await runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).send(message, attachments: attachments, skills: skills));
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
      _followIfAtBottom(
        force:
            opened ||
            (next.entries.length > (prev?.entries.length ?? 0) &&
                next.entries.lastOrNull is MessageEntry &&
                (next.entries.last as MessageEntry).role == 'user'),
      );
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
                    icon: LucideIcons.arrowLeft,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/bots'),
                  ),
                ),
              )
            : null,
        titleLeading: BotAvatar(name: name.isEmpty ? '?' : name, avatar: bot?.avatarUrl, size: 36, status: chat.running ? BotStatusEnum.working : bot?.status),
        onTitleTap: () => context.push('/bots/${widget.botId}/settings'),
        actions: [
          // Phones keep the header light: new chat lives in the conversations sheet there.
          if (layout != LayoutSize.phone)
            HeaderIconButton(icon: LucideIcons.squarePen, tooltip: l10n.newChat, onPressed: chat.running || chat.entries.isEmpty ? null : controller.newChat),
          HeaderIconButton(icon: LucideIcons.history, tooltip: l10n.conversations, onPressed: () => _showConversations(context, chat.conversationId)),
          HeaderIconButton(
            key: const Key('callButton'),
            icon: LucideIcons.phone,
            tooltip: l10n.startCall,
            onPressed: () => context.push('/bots/${widget.botId}/call${chat.conversationId == null ? '' : '?c=${chat.conversationId}'}'),
          ),
          _MoreMenu(botId: widget.botId, showComputer: layout != LayoutSize.desktop),
          // Far right, next to the panel it opens and closes.
          if (layout == LayoutSize.desktop)
            HeaderIconButton(
              key: const Key('computerPanelToggle'),
              icon: LucideIcons.panelRight,
              tooltip: ref.watch(computerPanelProvider) ? l10n.hideComputer : l10n.showComputer,
              selected: ref.watch(computerPanelProvider),
              onPressed: ref.read(computerPanelProvider.notifier).toggle,
            ),
        ],
      ),
      body: _wrapFiles(
        computer,
        LayoutBuilder(
          builder: (context, constraints) {
            final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth);
            final background = Theme.of(context).scaffoldBackgroundColor;
            final Widget thread;
            if (chat.loading) {
              thread = const Center(
                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)),
              );
            } else if (chat.entries.isEmpty && bot?.setupStatus == BotSetupStatusEnum.pending) {
              thread = _SetupCard(bot: bot!, side: side);
            } else if (chat.entries.isEmpty) {
              thread = _EmptyThread(name: name, avatar: bot?.avatarUrl, side: side, onAsk: _send);
            } else {
              final rows = _buildRows(context, chat, name, computer, bot?.avatarUrl);
              final focusId = _focusPending ?? _highlight;
              final focusIndex = focusId == null ? -1 : rows.indexWhere((r) => r.key == ValueKey(focusId));
              if (_focusPending != null && focusIndex >= 0) _scrollToFocus(_focusPending!, focusIndex, rows.length);
              thread = ListView.builder(
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(side, AppSpace.md, side, AppSpace.xl),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final child = rows[i].fresh ? rows[i].build().appMessageEntrance() : rows[i].build();
                  final focused = i == focusIndex;
                  return Padding(
                    key: focused ? _focusKey : rows[i].key,
                    padding: EdgeInsets.only(top: i == 0 ? 0 : rows[i].gap),
                    child: !focused
                        ? child
                        : AnimatedContainer(
                            key: const Key('focusedMessage'),
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              color: _highlight == focusId ? context.colorScheme.primary.withValues(alpha: 0.10) : Colors.transparent,
                              borderRadius: AppRadius.cardAll,
                            ),
                            child: child,
                          ),
                  );
                },
              );
            }
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
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
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [background.withValues(alpha: 0), background],
                              ),
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
                                    icon: const Icon(LucideIcons.arrowDown),
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
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xxs, side, AppSpace.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SkillPicker(
                          botId: widget.botId,
                          input: _input,
                          picked: _pickedSkills,
                          onPick: (name) => setState(() {
                            if (!_pickedSkills.contains(name) && _pickedSkills.length < 5) _pickedSkills.add(name);
                            _input.clear();
                          }),
                          onRemove: (name) => setState(() => _pickedSkills.remove(name)),
                        ),
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
                          attachButton: _AttachButton(onFiles: _pickFiles, onPhotos: _pickPhotos, onCamera: _takePhoto),
                          hasAttachments: _pending.any((p) => p.ref != null),
                          uploading: _uploading,
                          attachments: _pending.isEmpty
                              ? null
                              : SizedBox(
                                  height: 64,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _pending.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                                    itemBuilder: (context, i) => _PendingChip(item: _pending[i], onRemove: () => setState(() => _pending.removeAt(i))),
                                  ),
                                ),
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// File links and attachments open from the bot's computer; on desktop and the web, files
  /// dropped anywhere on the chat are attached.
  Widget _wrapFiles(Computer? computer, Widget child) {
    Widget body = FileLinkScope(
      computerId: computer?.id,
      open: (path) {
        if (computer == null) {
          showMessage(context, context.l10n.noComputerForFiles);
          return;
        }
        showComputerFile(context, computerId: computer.id, path: path);
      },
      child: child,
    );
    if (_touchFirst) return body;
    body = DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _dropped,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _dragging ? 1 : 0,
                duration: AppMotion.of(context, AppMotion.fast),
                child: Container(
                  margin: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.cardAll,
                    border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.6), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.fileUp, size: 40, color: context.colorScheme.primary),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        context.l10n.dropToAttach,
                        style: context.textTheme.titleMedium?.copyWith(color: context.colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return body;
  }

  /// Turns the chat into rows: one bot header per turn, consecutive tool steps grouped in a card,
  /// and a working indicator while the bot thinks between steps.
  List<_Row> _buildRows(BuildContext context, ChatState chat, String name, Computer? computer, String? avatar) {
    final rows = <_Row>[];
    final entries = chat.entries;
    var lastSide = '';
    final freshFrom = entries.length - 1;

    void botSide(String key) {
      if (lastSide != 'bot') {
        rows.add(_Row(ValueKey('hdr-$key'), lastSide.isEmpty ? 0 : AppSpace.xl, () => BotTurnHeader(name: name, avatar: avatar), header: true));
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
          rows.add(
            _Row(
              ValueKey(e.id),
              lastSide.isEmpty ? 0 : AppSpace.xl,
              () => UserBubble(text: e.text, attachments: e.attachments),
              fresh: fresh,
            ),
          );
          lastSide = 'user';
        case final MessageEntry m:
          botSide(m.id);
          rows.add(
            _Row(
              ValueKey(m.id),
              rows.last.header ? 0 : AppSpace.sm,
              () => AssistantMessage(entry: m, status: workingStatus(), onSpeak: !m.streaming ? () => _speak(m.id) : null),
            ),
          );
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
          rows.add(_Row(ValueKey('tools-${e.callId}'), rows.last.header ? 0 : AppSpace.sm, () => ToolGroupCard(steps: group)));
        case final ApprovalEntry a:
          botSide(a.approvalId);
          rows.add(
            _Row(
              ValueKey(a.approvalId),
              AppSpace.sm,
              () => ApprovalPrompt(entry: a, botName: name),
              fresh: fresh,
            ),
          );
        case final TakeoverEntry t:
          botSide('takeover-$i');
          rows.add(
            _Row(
              ValueKey('takeover-$i'),
              AppSpace.sm,
              () => TakeoverPrompt(entry: t, botName: name, onOpen: () => context.push('/computer/live?c=${t.computerId}')),
              fresh: fresh,
            ),
          );
        case final SecretEntry k:
          botSide('secret-${k.requestId}');
          rows.add(_Row(ValueKey('secret-${k.requestId}'), AppSpace.sm, () => SecretPrompt(entry: k, botName: name), fresh: fresh));
        case final UiEntry u:
          botSide(u.surfaceId);
          rows.add(
            _Row(
              ValueKey('ui-${u.surfaceId}'),
              AppSpace.sm,
              () => BotUiCard(host: _botUi, surfaceId: u.surfaceId, messages: u.messages, answered: chat.answeredUi.contains(u.surfaceId)),
              fresh: fresh,
            ),
          );
        case final NoticeEntry n:
          final last = i == entries.length - 1;
          rows.add(
            _Row(ValueKey('notice-$i'), AppSpace.sm, () {
              final line = NoticeLine(
                entry: n,
                onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp),
                onDetails: () => showErrorDetails(context, entry: n, botId: widget.botId),
              );
              if (!(last && n.kind == NoticeKind.failed && chat.lastUserText != null && !chat.running)) return line;
              return Column(
                children: [
                  line,
                  const SizedBox(height: AppSpace.xs),
                  TextButton.icon(
                    onPressed: () => runGuarded(context, ref.read(chatControllerProvider(widget.botId).notifier).retry),
                    icon: const Icon(LucideIcons.rotateCw, size: 18),
                    label: Text(context.l10n.retry),
                  ),
                ],
              );
            }),
          );
      }
    }

    // Thinking between steps, or before the first word of the reply.
    final last = entries.lastOrNull;
    // Waiting on a person (an approval or a takeover): no "thinking" shimmer.
    final waitingOnPerson = (last is ApprovalEntry && last.decision == null) ||
        (last is TakeoverEntry && last.outcome == null) ||
        (last is SecretEntry && last.outcome == null) ||
        (last is UiEntry && !chat.answeredUi.contains(last.surfaceId));
    final replying = last is MessageEntry && last.role == 'assistant' && last.streaming;
    final toolRunning = last is ToolEntry && last.status == ToolStatus.running;
    if (chat.running && !waitingOnPerson && !replying && !toolRunning) {
      botSide('working');
      rows.add(_Row(const ValueKey('working'), rows.last.header ? 0 : AppSpace.md, () => WorkingIndicator(status: workingStatus() ?? context.l10n.thinking)));
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

/// A file chosen for the next message: uploading until [ref] is set.
class _Pending {
  _Pending({required this.name, required this.bytes, required this.mime, required this.apiPath});
  final String name;
  final Uint8List bytes;
  final String mime;
  final String apiPath;
  AttachmentRef? ref;
  var failed = false;
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.item, required this.onRemove});
  final _Pending item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final image = item.mime.startsWith('image/') && item.mime != 'image/heic';
    final uploading = item.ref == null && !item.failed;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: Key('pending-${item.name}'),
          width: image ? 64 : 180,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.row),
            border: Border.all(color: item.failed ? scheme.error : context.appColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: image
              ? Image.memory(item.bytes, fit: BoxFit.cover, gaplessPlayback: true)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(fileIconFor(item.name), color: scheme.primary, size: 22),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(formatBytes(item.bytes.length), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (uploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.row)),
              alignment: Alignment.center,
              child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round)),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: scheme.onSurface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Tooltip(
                message: context.l10n.removeAttachment,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(LucideIcons.x, size: 14, color: scheme.surface),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "+" in the composer: files everywhere, the photo library and camera where the device has them.
class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onFiles, required this.onPhotos, required this.onCamera});
  final VoidCallback onFiles;
  final VoidCallback onPhotos;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    final photos = mobile || (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);
    MenuItemButton item(Key key, IconData icon, String label, VoidCallback onPressed) => MenuItemButton(
      key: key,
      leadingIcon: Icon(icon, size: 20),
      onPressed: onPressed,
      child: Padding(padding: const EdgeInsets.only(right: 16), child: Text(label)),
    );
    return MenuAnchor(
      alignmentOffset: const Offset(0, -8),
      menuChildren: [
        if (photos) item(const Key('attachPhotos'), LucideIcons.images, l10n.attachPhotos, onPhotos),
        if (mobile) item(const Key('attachCamera'), LucideIcons.camera, l10n.attachCamera, onCamera),
        item(const Key('attachFiles'), LucideIcons.paperclip, l10n.attachFiles, onFiles),
      ],
      builder: (context, controller, _) => IconButton(
        key: const Key('attachButton'),
        tooltip: l10n.attach,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(LucideIcons.plus, size: 24, color: context.colorScheme.onSurfaceVariant),
        style: IconButton.styleFrom(fixedSize: const Size.square(40), minimumSize: const Size.square(40), padding: EdgeInsets.zero),
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
  const _EmptyThread({required this.name, this.avatar, required this.side, required this.onAsk});
  final String name;
  final String? avatar;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeroMark(name: name, avatar: avatar).appCardEntrance(),
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
                  ],
                ),
                const Spacer(),
                for (var i = 0; i < suggestions.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs),
                    child: AppCard(
                      key: Key('suggestion-$i'),
                      onTap: () => onAsk(suggestions[i].$2),
                      radius: AppRadius.tile,
                      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: SizedBox(width: 24, child: Text(suggestions[i].$1, style: const TextStyle(fontSize: 17, height: 1))),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(suggestions[i].$2, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35)),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Icon(LucideIcons.arrowUp, size: 18, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ).appListItemEntrance(i + 2),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.name, this.avatar});
  final String name;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    const size = 88.0;
    return SizedBox(
      width: size + 14,
      height: size + 10,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          BotAvatar(name: name.isEmpty ? '?' : name, avatar: avatar, size: size),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.colorScheme.surface, width: 3),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.sparkles, size: 17, color: scheme.onPrimary),
            ),
          ),
        ],
      ),
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
    MenuItemButton item(IconData icon, String label, VoidCallback onPressed) => MenuItemButton(
      leadingIcon: Icon(icon, size: 20),
      onPressed: onPressed,
      child: Padding(padding: const EdgeInsets.only(right: 24), child: Text(label)),
    );
    // A fixed width lets the menu's right edge line up with the button (42 wide with its padding).
    const menuWidth = 260.0;
    return MenuAnchor(
      alignmentOffset: const Offset(-(menuWidth - 42), 6),
      style: const MenuStyle(minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)), maximumSize: WidgetStatePropertyAll(Size(menuWidth, double.infinity))),
      menuChildren: [
        item(LucideIcons.activity, l10n.activity, () => context.push('/bots/$botId/activity')),
        if (showComputer) item(LucideIcons.monitor, l10n.navComputer, () => context.go('/computer')),
        item(LucideIcons.brain, l10n.memory, () => context.push('/bots/$botId/memory')),
        item(LucideIcons.clock, l10n.routines, () => context.push('/bots/$botId/routines')),
        item(LucideIcons.puzzle, l10n.botIntegrations, () => context.push('/bots/$botId/integrations')),
        const Divider(),
        item(LucideIcons.slidersHorizontal, l10n.botSettings, () => context.push('/bots/$botId/settings')),
      ],
      builder: (context, controller, _) =>
          HeaderIconButton(icon: LucideIcons.ellipsis, tooltip: l10n.moreActions, onPressed: () => controller.isOpen ? controller.close() : controller.open()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          l10n.conversations,
          trailing: FilledButton.tonalIcon(onPressed: onNew, icon: const Icon(LucideIcons.squarePen, size: 18), label: Text(l10n.newChat)),
        ),
        Expanded(
          child: AsyncView(
            value: convos,
            onRetry: () => ref.invalidate(conversationsProvider(botId)),
            data: (items) => items.isEmpty
                ? EmptyState(icon: LucideIcons.messagesSquare, message: l10n.noConversations)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.md),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 2),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final current = c.id == currentId;
                      return ListTile(
                        selected: current,
                        leading: Icon(current ? LucideIcons.messageCircle : LucideIcons.messageCircle, size: 20),
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
      ],
    );
  }
}

/// The / picker (D-104): typing / lists the bot's skills; picking one attaches it to the next
/// message so the run loads it up front. Picked skills show as chips above the composer.
class _SkillPicker extends ConsumerWidget {
  const _SkillPicker({required this.botId, required this.input, required this.picked, required this.onPick, required this.onRemove});
  final String botId;
  final TextEditingController input;
  final List<String> picked;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: input,
      builder: (context, value, _) {
        final m = RegExp(r'^/([a-z0-9_-]*)$').firstMatch(value.text);
        final skills = m == null
            ? const <SkillView>[]
            : (ref.watch(skillsProvider).value ?? const <SkillView>[])
                .where((s) => s.enabled && (s.botId == null || s.botId == botId) && s.name.startsWith(m.group(1)!))
                .take(8)
                .toList();
        if (skills.isEmpty && picked.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (skills.isNotEmpty)
                Material(
                  key: const Key('skillPicker'),
                  color: scheme.surfaceContainerHigh,
                  borderRadius: AppRadius.cardAll,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, 0),
                        child: Align(alignment: AlignmentDirectional.centerStart, child: Text(l10n.attachSkill, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant))),
                      ),
                      for (final s in skills)
                        ListTile(
                          key: Key('pickSkill-${s.name}'),
                          dense: true,
                          leading: const Icon(LucideIcons.bookOpen, size: 18),
                          title: Text('/${s.name}'),
                          subtitle: Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => onPick(s.name),
                        ),
                    ],
                  ),
                ),
              if (picked.isNotEmpty)
                Wrap(
                  spacing: AppSpace.xs,
                  children: [
                    for (final name in picked)
                      InputChip(
                        key: Key('pickedSkill-$name'),
                        avatar: const Icon(LucideIcons.bookOpen, size: 16),
                        label: Text('/$name'),
                        onDeleted: () => onRemove(name),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A new bot offers its setup interview (D-105): a few questions, then a proposal to approve.
class _SetupCard extends ConsumerWidget {
  const _SetupCard({required this.bot, required this.side});
  final Bot bot;
  final double side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: side, vertical: AppSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            key: const Key('setupCard'),
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.md,
            children: [
              BotAvatar(name: bot.name, avatar: bot.avatarUrl, size: 72),
              Text(l10n.setupTitle(bot.name), style: context.textTheme.titleLarge, textAlign: TextAlign.center),
              Text(l10n.setupBody, textAlign: TextAlign.center, style: TextStyle(color: context.colorScheme.onSurfaceVariant)),
              GlowButton.icon(
                key: const Key('startSetup'),
                onPressed: () async {
                  final conv = await runGuarded(context, () => ref.read(backendProvider).startBotSetup(bot.id));
                  if (conv == null || !context.mounted) return;
                  ref.invalidate(botsProvider);
                  GoRouter.maybeOf(context)?.go('/bots/${bot.id}/chat?c=$conv');
                },
                icon: const Icon(LucideIcons.sparkles, size: 18),
                label: Text(l10n.startSetup),
              ),
              TextButton(
                key: const Key('skipSetup'),
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).skipBotSetup(bot.id));
                  ref.invalidate(botsProvider);
                },
                child: Text(l10n.skipSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

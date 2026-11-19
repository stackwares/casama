import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice/active_call.dart';
import '../voice/call_bubble.dart';
import '../voice/call_recap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:dio/dio.dart' show DioException, DioExceptionType;

import '../../core/backend.dart';
import '../../core/chat_focus.dart';
import '../../core/device_dictation.dart';
import '../../core/display_text.dart';
import '../../core/haptics.dart';
import '../../core/local_cache.dart';
import '../../core/media_cache.dart';
import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/wallpaper.dart';
import '../../ui/bottom_padding.dart';
import '../groups/empty_group.dart';
import 'delete_chat.dart';
import '../groups/group_chats.dart';
import '../island/run_tracker.dart';
import '../billing/out_of_credits.dart';
import '../billing/paywall.dart';
import '../../ui/edge_fade.dart';
import '../../ui/form_sheet.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/cover_image.dart';
import '../../ui/motion.dart';
import '../../ui/shell_header.dart';
import '../files/file_preview.dart';
import '../home/home_shell.dart';
import '../../core/dropped_files.dart';
import '../../ui/shell_layout.dart';
import '../projects/make_project.dart';
import 'chat_controller.dart';
import 'chat_detail.dart';
import 'local_actions.dart';
import 'photo_editor.dart';
import 'widgets/chat_time.dart';
import 'widgets/bot_ui.dart';
import 'widgets/app_tiles.dart';
import 'widgets/gallery_cards.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/mentions.dart';
import 'read_aloud.dart';
import 'widgets/composer.dart';
import 'widgets/error_details.dart';
import 'widgets/reply_usage.dart';
import 'widgets/screen_held_actions.dart';
import 'widgets/reactions.dart';
import 'widgets/shared_files.dart';
import '../../core/analytics.dart';
import '../permissions/permissions_card.dart';

/// The computer a bot uses, picked as the server picks it (`Computers.forBot`): its default
/// computer when it has one (and nothing else then), else its private computer, else the team
/// computer. Never some other computer in the workspace, so a file never lands on a computer the
/// bot can't see (Fix 17).
Computer? computerForBot(List<Computer> computers, String botId, {String? defaultComputerId}) {
  if (defaultComputerId != null) {
    for (final c in computers) {
      if (c.id == defaultComputerId) return c;
    }
    return null;
  }
  for (final c in computers) {
    if (c.ownerBotId == botId) return c;
  }
  for (final c in computers) {
    if (c.kind == ComputerKindEnum.team) return c;
  }
  return null;
}

Future<void> confirmRestore(BuildContext context, WidgetRef ref, String computerId, String checkpointId) async {
  final l10n = context.l10n;
  final ok = await showConfirm(context: context, title: l10n.restore, message: l10n.restoreConfirm, confirmLabel: l10n.restore);
  if (!ok || !context.mounted) return;
  final done = await runGuarded(context, () async {
    await ref.read(backendProvider).restoreCheckpoint(computerId, checkpointId);
    return true;
  });
  if (done == true && context.mounted) showSuccess(context, l10n.restored);
}

/// Phones close the keyboard after sending so the reply has the screen.
bool get _touchFirst => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// A computer with a keyboard, in the app or a browser (a phone's or tablet's browser reports its
/// own platform): a chat opens with the cursor in the message box (D-383).
bool get _keyboardFirst =>
    defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux;

/// Whether the app is in front: a window that isn't focused, or a hidden browser tab, isn't.
bool get _appInFront => switch (WidgetsBinding.instance.lifecycleState) {
  null || AppLifecycleState.resumed => true,
  _ => false,
};

/// The app's own starter requests, for when the server can't give personal ones (D-338): everyday
/// help anyone can use. The emoji is decoration; tapping sends the sentence.
List<(String, String)> _suggestions(BuildContext context) {
  final l10n = context.l10n;
  return [('☀️', l10n.suggestPlanDay), ('✍️', l10n.suggestWriteMessage), ('🔎', l10n.suggestExplain), ('💡', l10n.suggestCapabilities)];
}

/// The thread while it opens: your message on the right and the bot's turns (its avatar and name
/// over a reply bubble) on the left, in the real bubbles' shapes, insets, line heights and gaps.
class ChatThreadSkeleton extends StatelessWidget {
  const ChatThreadSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final dark = context.isDark;
    Widget header() => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          const SkeletonBone(width: 24, height: 24, radius: 12),
          const SizedBox(width: AppSpace.xs),
          SizedBox(width: 72, child: SkeletonText(style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700), widthFactor: 1)),
        ],
      ),
    );
    // AssistantMessage's bubble.
    Widget reply(double widthFactor, int lines) => LayoutBuilder(
      builder: (context, c) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          width: c.maxWidth * widthFactor,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(6),
              topEnd: Radius.circular(20),
              bottomStart: Radius.circular(20),
              bottomEnd: Radius.circular(20),
            ),
            border: Border.all(color: context.appColors.hairline),
          ),
          child: SkeletonText(style: text.bodyLarge?.copyWith(height: 1.55), lines: lines, widthFactor: 0.9),
        ),
      ),
    );
    // UserBubble's bubble.
    Widget mine(double widthFactor) => LayoutBuilder(
      builder: (context, c) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          width: (c.maxWidth * 0.85).clamp(0.0, 560.0) * widthFactor,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 11),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: dark ? 0.3 : 0.16),
              dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
            ),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(20),
              topEnd: Radius.circular(20),
              bottomStart: Radius.circular(20),
              bottomEnd: Radius.circular(6),
            ),
          ),
          child: SkeletonText(style: text.bodyLarge?.copyWith(height: 1.4), widthFactor: 0.8),
        ),
      ),
    );
    return SkeletonScope(
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mine(0.6),
              const SizedBox(height: AppSpace.xl),
              header(),
              reply(0.9, 3),
              const SizedBox(height: AppSpace.xl),
              mine(0.42),
              const SizedBox(height: AppSpace.xl),
              header(),
              reply(0.72, 2),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  /// Pause before dictation's automatic second try. Tests set it to zero.
  @visibleForTesting
  static Duration dictationRetryDelay = const Duration(milliseconds: 700);

  const ChatScreen({super.key, required this.botId, this.conversationId, this.focusMessageId, this.group = false, this.draft});

  /// A group chat (D-118): replies show which bot wrote them.
  final bool group;
  final String botId;
  final String? conversationId;

  /// A message to scroll to and highlight once the conversation loads (from search; D-103).
  final String? focusMessageId;

  /// Text to put in the composer, not sent (Change it from the Library: "About “Space Dodger”: ").
  final String? draft;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final ChatFocusReporter _chatFocus;
  String? _focusedConversation;
  final _input = TextEditingController();

  /// What the person was typing stays on the device per chat, so leaving and coming back (or a
  /// restart) keeps it. Bound to [_draftConversation] once the chat has opened.
  late final LocalCache _cache = ref.read(localCacheProvider);
  String? _draftKey;
  String? _draftConversation;
  Timer? _draftSave;

  static String _draftKeyFor(String botId, String? conversationId) => 'draft:$botId:${conversationId ?? 'new'}';

  void _saveDraftSoon() {
    if (_draftKey == null) return;
    _draftSave?.cancel();
    _draftSave = Timer(const Duration(milliseconds: 400), _saveDraft);
  }

  void _saveDraft() {
    _draftSave?.cancel();
    final key = _draftKey;
    if (key == null) return;
    final text = _input.text;
    unawaited(cacheWrite(_cache, key, text.trim().isEmpty ? null : text));
  }

  /// Points the draft at [conversationId]: the old chat's text is saved and the new chat's comes
  /// back. A new chat that just got its id on the first send keeps what is in the box.
  Future<void> _bindDraft(String? conversationId) async {
    final key = _draftKeyFor(widget.botId, conversationId);
    if (key == _draftKey) return;
    final wasBound = _draftKey != null;
    final becameReal = wasBound && _draftConversation == null && conversationId != null && _draftKey == _draftKeyFor(widget.botId, null);
    if (becameReal) {
      unawaited(cacheWrite(_cache, _draftKey!, null));
      _draftKey = key;
      _draftConversation = conversationId;
      _saveDraft();
      return;
    }
    if (wasBound) _saveDraft();
    _draftKey = key;
    _draftConversation = conversationId;
    final saved = await cacheRead(_cache, key);
    if (!mounted || _draftKey != key) return;
    final text = saved is String ? saved : '';
    // On first open, what was typed while the chat loaded wins over an older draft.
    if (!wasBound && _input.text.isNotEmpty) return;
    if (_input.text == text) return;
    _input.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  // Group chats: @-mention suggestions for what's typed in [_input].
  late final _mentions = MentionController(_input);

  /// Read aloud (the player above the composer); a reply read from this chat stops when it closes.
  late final ReadAloudController _readAloud;

  /// Interactive UIs bots show in this chat (D-086); what the person does goes back as a message.
  late final _botUi = BotUiHost(onAction: _onUiAction);
  final _scroll = ScrollController();
  final _focus = FocusNode();

  /// Marks the chat's notifications read when the app comes back to the front (D-383).
  late final AppLifecycleListener _lifecycle;
  final _showJump = ValueNotifier(false);
  var _recording = false;
  var _transcribing = false;
  /// The device's own recognizer is listening (words are typed live), not the recorder.
  DeviceDictation? _listening;

  /// Bumped when a device dictation starts or is cut short by Send: words from an older one are
  /// dropped, so the recognizer can't write a sent message back into the emptied box.
  var _dictationRun = 0;

  /// Bumped each time Send empties the box, so a dictation re-apply still pending (the keyboard
  /// echo workaround in [_applyInput]) never writes a sent message back.
  var _sentEpoch = 0;
  Dictation? _recorder;
  var _stickToBottom = true;
  var _opening = true;
  late String? _focusPending = widget.focusMessageId;
  String? _highlight;

  /// Find in this chat (Add 11): the bar above the thread.
  var _findOpen = false;

  void _openFind() => setState(() => _findOpen = true);

  /// Scrolls to a found message and highlights it, as a search result does.
  void _jumpToMessage(String id) => setState(() {
    _highlight = null;
    _focusPending = id;
  });
  final _focusKey = GlobalKey();
  final _pending = <_Pending>[];
  /// Skills picked with / for the next message (D-104).
  final _pickedSkills = <String>[];
  var _dragging = false;

  static const _maxFileBytes = 25 * 1024 * 1024;

  /// File links found in each reply (by entry: a changed reply is a new entry).
  final _sharedFiles = Expando<List<AttachmentRef>>();

  /// Rows built for the thread, with their inputs: while a reply streams, only its own row is
  /// built again on each word (see [_Row.inputs]).
  final _rowCache = <Key, (Object, Widget)>{};

  Widget _rowWidget(_Row row) {
    final inputs = row.inputs;
    if (inputs == null) return row.build();
    final hit = _rowCache[row.key];
    if (hit != null && hit.$1 == inputs) return hit.$2;
    final built = row.build();
    _rowCache[row.key] = (inputs, built);
    return built;
  }

  String? _computerId() {
    final bot = ref.read(botProvider(widget.botId));
    return computerForBot(ref.read(computersProvider).value ?? const [], widget.botId, defaultComputerId: bot?.defaultComputerId)?.id;
  }

  /// Uploads each file to the bot's computer right away (workspace/uploads), so Send only waits
  /// for what is still in flight.
  Future<void> _addFiles(List<(String, Uint8List, String?)> files) async {
    final computerId = _computerId();
    if (computerId == null) {
      showWarning(context, context.l10n.noComputerForFiles);
      return;
    }
    for (final (name, bytes, mime) in files) {
      if (bytes.length > _maxFileBytes) {
        showWarning(context, context.l10n.fileTooLarge(name));
        continue;
      }
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
      final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
      final item = _Pending(name: name, bytes: bytes, mime: (mime == null || mime.isEmpty) ? mimeFor(name) : mime, apiPath: 'uploads/$stamp-$safe', computerId: computerId);
      setState(() => _pending.add(item));
      _upload(item);
    }
  }

  /// Uploads [item] in the background; [_Pending.upload] says how it went. Starting again (a
  /// retry, or an edited photo under a new name) makes any earlier try not count.
  void _upload(_Pending item) {
    final try_ = ++item.attempt;
    item
      ..failed = false
      ..ref = null;
    // The chat shows the picture from the device right away, and never downloads it back.
    unawaited(MediaCache.write(MediaCache.keyFor(item.computerId, item.apiPath), item.bytes));
    final backend = ref.read(backendProvider);
    item.upload = () async {
      try {
        await backend.uploadFile(item.computerId, item.apiPath, item.bytes);
        if (try_ != item.attempt) return false;
        item.ref = item.plannedRef;
        if (mounted) setState(() {});
        return true;
      } catch (_) {
        if (try_ != item.attempt) return false;
        item.failed = true;
        if (mounted) {
          setState(() {});
          showFailure(context, context.l10n.uploadFailed(item.name));
        }
        return false;
      }
    }();
  }

  /// Crop, rotate or draw on a photo before sending; the edited one replaces it.
  Future<void> _editPending(_Pending item) async {
    final edited = await editPhoto(context, item.bytes);
    if (edited == null || !mounted || !_pending.contains(item)) return;
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
    final base = item.name.contains('.') ? item.name.substring(0, item.name.lastIndexOf('.')) : item.name;
    final name = '$base.jpg';
    setState(() {
      item
        ..name = name
        ..bytes = edited
        ..mime = 'image/jpeg'
        ..apiPath = 'uploads/$stamp-${name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}';
    });
    _upload(item);
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    await _addFiles([for (final f in picked) (f.name, await f.readAsBytes(), null)]);
  }

  Future<void> _pickPhotos() async {
    // 2048 px is more than vision models look at, and keeps a phone photo well under 1 MB.
    final images = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2048, maxHeight: 2048);
    if (images.isEmpty) return;
    await _addFiles([for (final x in images) (x.name, await x.readAsBytes(), x.mimeType)]);
  }

  Future<void> _takePhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2048, maxHeight: 2048);
    if (x == null) return;
    await _addFiles([(x.name, await x.readAsBytes(), x.mimeType)]);
  }

  Future<void> _dropped(DropDoneDetails detail) async {
    setState(() => _dragging = false);
    await _addFiles([for (final f in detail.files) (f.name, await f.readAsBytes(), f.mimeType)]);
  }

  /// Dragged in from the app beside this one (D-411, Split View): text goes where the cursor is,
  /// files are attached.
  void _droppedFromApp(List<String> files, String text) {
    if (!mounted) return;
    if (text.isNotEmpty) {
      final at = _input.selection.isValid ? _input.selection.end : _input.text.length;
      _input.value = TextEditingValue(
        text: _input.text.replaceRange(at, at, text),
        selection: TextSelection.collapsed(offset: at + text.length),
      );
    }
    if (files.isEmpty) return;
    unawaited(() async {
      final read = [for (final path in files) (path.split('/').last, await XFile(path).readAsBytes(), null as String?)];
      if (mounted) await _addFiles(read);
    }());
  }

  @override
  void initState() {
    super.initState();
    _readAloud = ref.read(readAloudProvider.notifier);
    _chatFocus = ref.read(chatFocusProvider);
    _scroll.addListener(_onScroll);
    // Change it (the Library): the request starts typed in, cursor at the end, ready to finish.
    final draft = widget.draft;
    if (draft != null && draft.isNotEmpty) {
      _input.value = TextEditingValue(text: draft, selection: TextSelection.collapsed(offset: draft.length));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    if (widget.focusMessageId == null) _focusComposerSoon();
    DroppedFiles.take(_droppedFromApp);
    _lifecycle = AppLifecycleListener(onResume: _markShownRead);
    _input.addListener(_saveDraftSoon);
    _listenToBot();
    // What this chat shows (a routine's result, a reply) is read once the chat is open, including
    // notifications that arrive while it is.
    ref.listenManual(notificationsProvider, (_, next) {
      final botId = widget.botId;
      // A run in the chat on screen asks for the person while another run is being followed.
      final open = ref.read(chatControllerProvider(botId)).conversationId;
      for (final n in next.value ?? const <NotificationView>[]) {
        if (n.isRequest && n.readAt == null && open != null && n.conversationId == open && n.runId != null) {
          final run = n.runId!;
          Future.microtask(() => ref.read(chatControllerProvider(botId).notifier).followWaiting(open, run));
        }
      }
      final fresh = [
        for (final n in next.value ?? const <NotificationView>[])
          if (n.readAt == null && !n.isRequest && n.botId == botId && (n.link?.startsWith('/bots/$botId/chat') ?? false)) n,
      ];
      if (fresh.isEmpty) return;
      // A routine just posted in the chat on screen (D-155): show its reply here.
      final controller = ref.read(chatControllerProvider(botId).notifier);
      final chat = ref.read(chatControllerProvider(botId));
      final conv = chat.conversationId;
      if (conv != null && !chat.running && fresh.any((n) => n.link!.contains('c=$conv'))) {
        Future.microtask(() => controller.open(conv));
      }
      // Read means seen: not while the window is behind others or the tab is hidden (D-383).
      // Coming back to the front marks them.
      if (_appInFront) Future.microtask(() => ref.read(notificationsProvider.notifier).markBotChatRead(botId, conversationId: ref.read(chatControllerProvider(botId)).conversationId));
    }, fireImmediately: true);
    Future.microtask(() async {
      final c = ref.read(chatControllerProvider(widget.botId).notifier)..group = widget.group;
      try {
        await c.open(widget.conversationId, around: widget.focusMessageId);
      } finally {
        if (mounted && _opening) setState(() => _opening = false);
        if (mounted) unawaited(_bindDraft(ref.read(chatControllerProvider(widget.botId)).conversationId));
      }
    });
  }

  final _botListeners = <ProviderSubscription<String?>>[];

  /// Follows which conversation the bot on screen has open. The router keeps this screen when
  /// the person goes from one bot to another (the sidebar on a computer), so these are bound again
  /// for the new bot (D-413): they used to stay on the first bot, whose chat was then reported as
  /// "on screen" for good, and its replies stopped notifying on every device.
  void _listenToBot() {
    for (final s in _botListeners) {
      s.close();
    }
    _botListeners
      ..clear()
      // The chat's id changes without a reopen when the first send creates it or New chat clears it.
      ..add(
        ref.listenManual(chatControllerProvider(widget.botId).select((s) => s.conversationId), (_, next) {
          if (!_opening && _draftKey != null) _bindDraft(next);
        }),
      )
      // Replies to the chat on screen don't push to any of the person's devices (D-325).
      ..add(
        ref.listenManual(chatControllerProvider(widget.botId).select((s) => s.conversationId), (_, next) {
          _focusedConversation = next;
          _chatFocus.open(next);
          // Its notifications are read once it is the one showing.
          if (next != null && _appInFront) Future.microtask(_markShownRead);
        }, fireImmediately: true),
      );
  }

  /// On a computer, a chat opens ready to type in (D-383). Not over a dialog or sheet, which
  /// keeps the keyboard.
  void _focusComposerSoon() {
    if (!_keyboardFirst) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _focus.requestFocus();
    });
  }

  void _markShownRead() {
    if (mounted) {
      unawaited(
        ref
            .read(notificationsProvider.notifier)
            .markBotChatRead(widget.botId, conversationId: ref.read(chatControllerProvider(widget.botId)).conversationId)
            .catchError((_) {}),
      );
    }
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (old.botId != widget.botId) _listenToBot();
    if (old.botId != widget.botId || old.conversationId != widget.conversationId || old.focusMessageId != widget.focusMessageId || old.group != widget.group) {
      if (old.botId != widget.botId && widget.focusMessageId == null) _focusComposerSoon();
      // Keep what was typed in the chat being left before the next one opens.
      _saveDraft();
      _rowCache.clear();
      _stickToBottom = true;
      _opening = true;
      _focusPending = widget.focusMessageId;
      Future.microtask(() async {
        final c = ref.read(chatControllerProvider(widget.botId).notifier)..group = widget.group;
        try {
          await c.open(widget.conversationId, around: widget.focusMessageId);
        } finally {
          if (mounted && _opening) setState(() => _opening = false);
          if (mounted) unawaited(_bindDraft(ref.read(chatControllerProvider(widget.botId)).conversationId));
        }
      });
    }
  }

  Future<void> _onUiAction(BotUiAction action) async {
    // Some card actions are the app's own: open a connection, a screen, an invite (D-129). A
    // connection made from a welcome card reports back here (D-204).
    if (await handleLocalUiAction(context, ref, action, send: _onUiAction)) return;
    if (!mounted) return;
    final chat = ref.read(chatControllerProvider(widget.botId));
    if (chat.running || chat.answeredUi.contains(action.surfaceId)) return;
    runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).send(uiActionSummary(action), uiAction: action.toJson()));
  }

  @override
  void dispose() {
    DroppedFiles.release(_droppedFromApp);
    _chatFocus.close(_focusedConversation);
    _lifecycle.dispose();
    unawaited(_readAloud.stop(chatKey: widget.botId));
    _listening?.cancel();
    if (_recording) _recorder?.cancel();
    _saveDraft();
    _botUi.dispose();
    _mentions.dispose();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    _showJump.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final distance = _scroll.position.pixels;
    _stickToBottom = distance < 120;
    _showJump.value = distance > 400;
    // Near the top of what is loaded (the far end of the bottom-anchored list): fetch the page
    // before it. The list keeps its place, since new rows are added beyond the far end.
    if (_scroll.position.extentAfter < 600) {
      unawaited(ref.read(chatControllerProvider(widget.botId).notifier).loadEarlier().catchError((_) {}));
    }
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
          _scroll.jumpTo(_scroll.position.maxScrollExtent * (count <= 1 ? 0 : (count - 1 - index) / (count - 1)));
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
    _toEnd();
  }

  /// Jumps to the end of the thread (offset 0 in the bottom-anchored list).
  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final p = _scroll.position;
      if (p.pixels != 0) p.jumpTo(0);
    });
  }

  double? _viewport;

  /// The thread got shorter (the keyboard opened, or the composer grew): keep what was at its
  /// bottom in view instead of leaving it under the composer. Following the latest message stays
  /// pinned to the end; otherwise the list moves up by as much as it shrank.
  bool _onThreadMetrics(ScrollMetricsNotification n) {
    if (n.depth != 0) return false;
    final viewport = n.metrics.viewportDimension;
    final before = _viewport;
    _viewport = viewport;
    if (before == null || viewport >= before || _focusPending != null) return false;
    if (_stickToBottom) {
      _toEnd();
      return false;
    }
    return false;
  }

  /// Whether this chat exists on the server and this person may delete it (started it, or
  /// manages the bot).
  /// The open chat's row from the bot's list, once that has loaded.
  Conversation? _currentConversation(String? id) {
    if (id == null || widget.group) return null;
    return ref.watch(conversationsProvider(widget.botId)).value?.where((c) => c.id == id).firstOrNull;
  }

  /// A topic (never General) that isn't a project's chat yet can become one (D-295).
  bool _canMakeProject(String? id) {
    final c = _currentConversation(id);
    return c != null && c.isMain != true && c.parentConversationId != null && c.projectId == null;
  }

  Future<void> _makeProject(String id) => makeProjectFromTopic(
    context,
    ref,
    botId: widget.botId,
    conversationId: id,
    title: _currentConversation(id)?.title ?? '',
  );

  bool _canDeleteCurrent(String? id) {
    if (id == null) return false;
    final list = widget.group ? ref.watch(groupChatsProvider).value : ref.watch(conversationsProvider(widget.botId)).value;
    return list?.where((c) => c.id == id).firstOrNull?.canDelete == true;
  }

  Future<void> _deleteCurrent(String id, String botName) async {
    final deleted = await confirmDeleteChat(context, ref, conversationId: id, botId: widget.botId, botName: botName);
    if (!deleted || !mounted) return;
    // A group chat is gone from the sidebar too; a direct chat starts fresh with the same bot.
    if (widget.group) {
      context.go('/bots');
    } else {
      ref.read(chatControllerProvider(widget.botId).notifier).newChat();
    }
  }

  /// Starts the message to one group member (or everyone) from the empty group chat.
  /// Calls the bot in this chat, or goes back to its call when one is going on, whichever chat
  /// it's in (D-327).
  void _callBack(String? conversationId) {
    final live = ref.read(activeCallProvider).live;
    unawaited(
      context.pushOnce(
        live != null && live.botId == widget.botId
            ? callScreenPath(live)
            : '/bots/${widget.botId}/call${conversationId == null ? '' : '?c=$conversationId'}',
      ),
    );
  }

  void _startMention(String name) {
    final text = _input.text.trim();
    final value = '${text.isEmpty ? '' : '$text '}@$name ';
    _input.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
    _focus.requestFocus();
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: AppMotion.of(context, const Duration(milliseconds: 380)), curve: AppMotion.curve);
  }

  Future<void> _send([String? text]) async {
    final message = text ?? _input.text;
    // Files that failed stay out until retried; the rest go with the message, finished or not.
    final items = text == null ? [for (final p in _pending) if (!p.failed) p] : const <_Pending>[];
    final attachments = [for (final p in items) p.plannedRef];
    if (message.trim().isEmpty && attachments.isEmpty) return;
    final inFlight = [for (final p in items) if (p.ref == null) p];
    // The message shows at once and is delivered when its files are up (no waiting at Send).
    final uploads = inFlight.isEmpty ? null : Future.wait([for (final p in inFlight) p.upload!]).then((r) => r.every((ok) => ok));
    final skills = text == null ? [..._pickedSkills] : const <String>[];
    if (text == null) {
      _sentEpoch++;
      _input.clear();
      setState(() {
        _pending.removeWhere(items.contains);
        _pickedSkills.clear();
      });
    }
    _stickToBottom = true;
    if (_touchFirst) FocusManager.instance.primaryFocus?.unfocus();
    var notSent = false;
    final ok = await runGuarded(context, () async {
      try {
        await ref.read(chatControllerProvider(widget.botId).notifier).send(message, attachments: attachments, skills: skills, uploads: uploads);
      } on UploadsFailed {
        notSent = true;
      }
      return true;
    });
    // Failed before its bubble showed (the chat itself couldn't be created): back to the box.
    if (ok == null && mounted && text == null) {
      final kept = ref.read(chatControllerProvider(widget.botId)).entries.any((e) => e is MessageEntry && e.failed && e.text == message.trim());
      if (!kept) {
        setState(() {
          if (_input.text.trim().isEmpty) _input.text = message;
          _pending.insertAll(0, [for (final p in items) if (!_pending.contains(p)) p]);
          _pickedSkills.addAll([for (final s in skills) if (!_pickedSkills.contains(s)) s]);
        });
      }
      return;
    }
    if (notSent) {
      // Nothing is lost: the words and files come back to the box, failed ones marked to retry.
      if (!mounted) return;
      setState(() {
        if (_input.text.trim().isEmpty) _input.text = message;
        _pending.insertAll(0, [for (final p in items) if (!_pending.contains(p)) p]);
        _pickedSkills.addAll([for (final s in skills) if (!_pickedSkills.contains(s)) s]);
      });
      showFailure(context, context.l10n.messageNotSent);
      return;
    }
    if (!_touchFirst && mounted) _focus.requestFocus();
  }

  ChatController controllerOf() => ref.read(chatControllerProvider(widget.botId).notifier);

  /// A message the server has (a uuid), so it can carry reactions (D-331).
  static final _savedMessageId = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
  static bool _reactable(MessageEntry e) => !e.failed && !e.uploading && _savedMessageId.hasMatch(e.id);

  /// Regenerate (Add 11): the reply is asked for again; the old one stays as another version.
  Future<void> _regenerate(String replyId) async {
    _stickToBottom = true;
    await runGuarded(context, () => controllerOf().regenerate(replyId));
  }

  /// Your reaction to a message (D-331): [emoji] sets or replaces it, null takes it back.
  Future<void> _react(String messageId, String? emoji, ReactionSurface surface, {required bool onBot}) async {
    final props = {'on': onBot ? 'bot' : 'person', 'surface': surface.analyticsName};
    if (emoji == null) {
      Analytics.log('message_reaction_removed', props);
    } else {
      Analytics.log('message_reacted', {...props, 'emoji': emoji, 'conversation_kind': widget.group ? 'group' : 'direct'});
      Analytics.feature('reactions');
    }
    await runGuarded(context, () => controllerOf().react(messageId, emoji));
  }

  /// Who reacted to a message, a tab per emoji (D-331).
  void _showReactionPeople(String messageId, String emoji) {
    final chat = ref.read(chatControllerProvider(widget.botId));
    final id = chat.conversationId;
    final groups = chat.reactions[messageId] ?? const <ReactionGroup>[];
    if (id == null || groups.isEmpty) return;
    final backend = ref.read(backendProvider);
    final mine = ReactionGroup.mineOf(groups);
    final onBot = chat.entries.any((e) => e is MessageEntry && e.id == messageId && e.role != 'user');
    showReactionPeople(
      context,
      groups: groups,
      load: () => backend.reactionPeople(id, messageId),
      me: backend.userId,
      initialEmoji: emoji,
      onRemoveMine: mine == null ? null : () => _react(messageId, null, ReactionSurface.chip, onBot: onBot),
    );
  }

  /// The chips row under a message, when it has reactions.
  void _reactionRow(List<_Row> rows, String messageId, List<ReactionGroup>? groups, {required bool onBot}) {
    if (groups == null || groups.isEmpty) return;
    rows.add(
      _Row(
        ValueKey('rx-$messageId'),
        AppSpace.xxs,
        () => ReactionChips(
          key: Key('reactions-$messageId'),
          groups: groups,
          alignEnd: !onBot,
          onReact: (emoji, surface) => _react(messageId, emoji, surface, onBot: onBot),
          onShowPeople: (emoji) => _showReactionPeople(messageId, emoji),
        ),
        inputs: groups,
      ),
    );
  }

  /// Delete one message (Add 11), after asking.
  Future<void> _deleteMessage(String messageId) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.deleteMessageTitle,
      message: l10n.deleteMessageBody,
      confirmLabel: l10n.delete,
      destructive: true,
      icon: LucideIcons.trash2,
      confirmKey: const Key('confirmDeleteMessage'),
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () async {
      await controllerOf().deleteMessage(messageId);
      return true;
    });
    if (done == true && mounted) showSuccess(context, l10n.messageDeleted);
  }

  /// A picture pasted into the composer (Add 11): PNG unless its bytes say JPEG.
  Future<void> _pasteImage(Uint8List bytes) async {
    if (!mounted) return;
    final jpeg = bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _addFiles([(jpeg ? 'pasted-$stamp.jpg' : 'pasted-$stamp.png', bytes, jpeg ? 'image/jpeg' : 'image/png')]);
  }

  /// Edit and resend (D-108): the conversation forks at this message and reruns from it.
  Future<void> _editMessage(MessageEntry e) async {
    final text = await showAdaptiveSheet<String>(context: context, builder: (_) => _EditSheet(initial: e.text));
    if (text == null || text.trim().isEmpty || text.trim() == e.text.trim() || !mounted) return;
    _stickToBottom = true;
    Analytics.feature('edit_resend');
    await runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).edit(e.id, text));
  }

  /// Dictation: tap to start, tap again to stop. The recording goes to the server (Whisper, which
  /// copes with mixed languages); if that fails, the clip is tried once more, and after that the
  /// mic uses the device's own recognizer for a while, typing words as the person speaks.
  Future<void> _toggleDictation() async {
    Analytics.feature('dictation');
    final device = _listening;
    if (device != null) {
      await device.stop(); // onEnd finishes up.
      return;
    }
    if (_recording) return _stopRecording();
    final route = ref.read(dictationRouteProvider);
    final deviceDictation = ref.read(deviceDictationProvider);
    if (route.preferDevice && deviceDictation.supported) {
      if (await _startDevice(deviceDictation)) return;
      // Denied or missing: the server it is, and say nothing; the recorder may still work.
      route.useServer();
      if (!mounted) return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final dictation = ref.read(dictationProvider);
    try {
      final ok = await dictation.start();
      if (!mounted) return;
      if (!ok) {
        showWarning(context, context.l10n.micPermissionNeeded);
        return;
      }
      _recorder = dictation;
      setState(() => _recording = true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<bool> _startDevice(DeviceDictation device) async {
    final before = _input.text.trimRight();
    String join(String words) => before.isEmpty ? words : '$before $words';
    var latest = '';
    final run = ++_dictationRun;
    final started = await device.start(
      onWords: (words) {
        if (!mounted || run != _dictationRun) return;
        latest = words;
        final next = join(words);
        _input.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
      },
      onEnd: (end) {
        if (!mounted || run != _dictationRun) return;
        setState(() {
          _listening = null;
          _recording = false;
        });
        switch (end) {
          case DeviceDictationEnd.done:
            HapticsHelper.success();
            _applyInput(join(latest));
          case DeviceDictationEnd.nothingHeard:
            showWarning(context, context.l10n.dictationEmpty);
          case DeviceDictationEnd.failed:
            ref.read(dictationRouteProvider).useServer();
            showFailure(context, context.l10n.dictationDeviceFailed);
        }
      },
    );
    if (!started || !mounted) return false;
    setState(() {
      _listening = device;
      _recording = true;
    });
    return true;
  }

  /// Send from the composer. While dictating, it finishes first: the device's words are already
  /// in the box (and its recognizer is cut off so nothing comes back after), a recording is
  /// transcribed into the box, and then everything goes as one message.
  Future<void> _sendFromComposer() async {
    final device = _listening;
    if (device != null) {
      _dictationRun++;
      setState(() {
        _listening = null;
        _recording = false;
      });
      unawaited(device.cancel());
    } else if (_recording) {
      await _stopRecording();
      if (!mounted) return;
    }
    await _send();
  }

  Future<void> _stopRecording() async {
    final Dictation dictation = _recorder ?? ref.read(dictationProvider);
    setState(() {
      _recording = false;
      _transcribing = true;
    });
    try {
      final clip = await dictation.stop();
      if (!mounted) return;
      if (clip == null) {
        showWarning(context, context.l10n.dictationEmpty);
        return;
      }
      await _transcribe(clip);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  /// Sends [clip] to the server, once more on a failure that might pass, then falls back.
  Future<void> _transcribe((Uint8List, String) clip, {bool retried = false}) async {
    try {
      final text = await ref.read(backendProvider).transcribe(widget.botId, clip.$1, clip.$2);
      if (!mounted) return;
      final spoken = text.trim();
      if (spoken.isEmpty) {
        showWarning(context, context.l10n.dictationEmpty);
        return;
      }
      _typeDictation(spoken);
    } catch (e) {
      if (!mounted) return;
      final status = e is DioException ? e.response?.statusCode : null;
      final paywall = onPaymentRequired;
      if (status == 402 && paywall != null) {
        await paywall(context, errorText(context, e));
        return;
      }
      final code = problemOf(e)?.code;
      final device = ref.read(deviceDictationProvider);
      final route = ref.read(dictationRouteProvider);
      if (code == 'dictation_unavailable') {
        // No service (or a key that was refused): nothing to retry. The device, if it can.
        if (device.supported) {
          route.useDevice(forSession: true);
          _offerDevice(context.l10n.dictationNoServiceUseDevice);
        } else {
          showError(context, e);
        }
        return;
      }
      if (!_mightPass(e, status, code)) {
        showError(context, e);
        return;
      }
      if (!retried) {
        await Future<void>.delayed(ChatScreen.dictationRetryDelay);
        if (mounted) await _transcribe(clip, retried: true);
        return;
      }
      if (device.supported) {
        route.useDevice();
        _offerDevice(context.l10n.dictationFailedUseDevice);
        return;
      }
      HapticsHelper.error();
      showToast(
        context,
        context.l10n.dictationFailed,
        kind: ToastKind.error,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(label: context.l10n.dictationRetry, onPressed: () => _retryTranscribe(clip)),
      );
    }
  }

  /// Says why the server's dictation didn't work, with a button that starts the device listening
  /// right away. The snackbar floats over the composer, so "tap the mic" would mean reaching under it.
  void _offerDevice(String message) {
    HapticsHelper.warning();
    showToast(
      context,
      message,
      kind: ToastKind.warning,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(label: context.l10n.dictationSayAgain, onPressed: _listenOnDevice),
    );
  }

  Future<void> _listenOnDevice() async {
    if (!mounted || _recording || _transcribing) return;
    if (await _startDevice(ref.read(deviceDictationProvider)) || !mounted) return;
    // Speech permission denied, or no recognizer after all: the mic goes back to the server.
    ref.read(dictationRouteProvider).useServer();
    showWarning(context, context.l10n.dictationDevicePermission);
  }

  Future<void> _retryTranscribe((Uint8List, String) clip) async {
    if (!mounted || _transcribing) return;
    setState(() => _transcribing = true);
    try {
      await _transcribe(clip, retried: true);
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  /// A failure another try (or the device) could get past: the service choked on the clip, the
  /// server had a moment, or the connection dropped. Not a plan limit or a bad request.
  bool _mightPass(Object e, int? status, String? code) {
    if (code == 'transcription_failed') return true;
    if (e is! DioException) return false;
    if (status == null) {
      return const {
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.unknown,
      }.contains(e.type);
    }
    return status >= 500 || status == 429 || status == 408;
  }

  /// Puts [spoken] in the message box. iOS and Android's keyboard writes the previous value back
  /// over a programmatic edit, so the transcript is applied again after that echo.
  void _typeDictation(String spoken) => _applyInput(_input.text.isEmpty ? spoken : '${_input.text} $spoken');

  void _applyInput(String next) {
    final value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    final epoch = _sentEpoch;
    void apply() {
      if (!mounted || epoch != _sentEpoch || _input.text.contains(next)) return;
      _input.value = value;
    }

    _input.value = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    });
    Future<void>.delayed(const Duration(milliseconds: 150), apply);
  }

  /// In a group chat, the messages' @mentions of its bots show as pills that open their profiles.
  Widget _withMentions(Widget thread) {
    if (!widget.group) return thread;
    final ids = ref.watch(groupChatsProvider).value?.where((g) => g.id == widget.conversationId).firstOrNull?.botIds ?? const <String>[];
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return MentionScope(
      bots: [for (final b in bots) if (ids.contains(b.id)) b],
      onOpen: (bot) => context.pushOnce('/bots/${bot.id}/settings'),
      child: thread,
    );
  }

  /// Reads [m] aloud in its bot's voice, or stops when it's the one being read.
  Future<void> _speak(MessageEntry m) async {
    if (ref.read(readAloudProvider)?.messageId == m.id) return _readAloud.stop();
    Analytics.feature('read_aloud');
    final bots = ref.read(botsProvider).value ?? const <Bot>[];
    final speaker = bots.where((b) => b.id == (m.botId ?? widget.botId)).firstOrNull ?? bots.where((b) => b.id == widget.botId).firstOrNull;
    final backend = ref.read(backendProvider);
    await runGuarded(
      context,
      () => _readAloud.toggle(
        chatKey: widget.botId,
        messageId: m.id,
        name: speaker?.name ?? '',
        avatar: speaker?.avatarUrl,
        text: m.text,
        fetch: () => backend.speech(m.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(widget.botId));
    // Only what the screen around the thread shows. A streamed word changes none of it, so it
    // rebuilds the thread alone (the Consumer below), not the header and the composer.
    final chat = ref.watch(chatControllerProvider(widget.botId).select((c) => _chatFrame(c, group: widget.group)));
    final controller = ref.read(chatControllerProvider(widget.botId).notifier);
    final computer = computerForBot(ref.watch(computersProvider).value ?? const [], widget.botId, defaultComputerId: bot?.defaultComputerId);
    // A topic that finishes, or starts needing the person, while another one is on screen: its
    // chip follows (D-413). The chips used to keep "working" until this chat itself changed.
    ref.listen(botProvider(widget.botId).select((b) => b?.status), (prev, next) {
      if (prev != next) ref.invalidate(conversationsProvider(widget.botId));
    });
    ref.listen(
      runTrackerProvider.select(
        (runs) => [
          for (final r in runs)
            if (r.botId == widget.botId) '${r.runId}:${r.status}:${r.ended}',
        ].join(','),
      ),
      (prev, next) {
        if (prev != next) ref.invalidate(conversationsProvider(widget.botId));
      },
    );
    ref.listen(chatControllerProvider(widget.botId), (prev, next) {
      // General and topics (D-253): the chips and statuses follow what happens here.
      if (prev?.conversationId != next.conversationId || (prev?.running ?? false) != next.running) {
        ref.invalidate(conversationsProvider(widget.botId));
      }
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
    // Simple chats by default: what the bot is doing in a few words, not each step (D-162).
    final showSteps = ref.watch(showBotStepsProvider);
    // Power users can see what each reply cost under it (D-307).
    final showUsage = ref.watch(showReplyUsageProvider);
    final layout = layoutFor(MediaQuery.sizeOf(context).width);
    final shell = ShellLayout.maybeOf(context);
    // The chat list is on screen beside this chat.
    final besideList = shell != null && shell.size == LayoutSize.split && shell.pane == PaneRole.detail;
    // Only what it's doing right now; an idle bot needs no subtitle (its model lives in its profile).
    final status = chat.running ? l10n.botStatusWorking : (bot?.status == BotStatusEnum.waiting ? l10n.botStatusWaiting : null);
    // The bot is working on its computer: this run has used it, or the computer is waking for it.
    final computerInUse = ref.watch(chatControllerProvider(widget.botId).select(_computerInUse));
    final computerLive = computerInUse || (chat.running && const {ComputerState.provisioning, ComputerState.starting}.contains(computer?.state));
    // A group chat is headed by the group, not its lead: its name and its bots' faces.
    final group = widget.group ? ref.watch(groupChatsProvider).value?.where((c) => c.id == widget.conversationId).firstOrNull : null;
    final groupBots = ref.watch(botsProvider).value ?? const <Bot>[];

    return Wallpaper(
      force: true,
      // The iOS status-bar tap scrolls this list back to its start; reversed, that's the latest
      // message. Nothing else inherits it, so lists inside messages keep their own scrolling.
      child: PrimaryScrollController(
        controller: _scroll,
        automaticallyInheritForPlatforms: const <TargetPlatform>{},
        // Cmd/Ctrl+F finds in this chat (Add 11).
        child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _openFind,
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): _openFind,
        },
        child: Scaffold(
        appBar: ShellHeader(
        title: group == null ? name : groupTitle(group, groupBots),
        subtitle: status,
        subtitleShimmer: chat.running,
        showBack: layout == LayoutSize.phone ? true : null,
        leading: layout == LayoutSize.phone
            ? HeaderIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.canPop() ? context.pop() : context.go('/bots'),
              )
            : null,
        titleLeading: group != null
            ? GroupAvatar(bots: [for (final id in group.botIds) ?groupBots.where((b) => b.id == id).firstOrNull], size: 36)
            : BotAvatar(name: name.isEmpty ? '?' : name, avatar: bot?.avatarUrl, size: 36, status: chat.running ? BotStatusEnum.working : bot?.status),
        onTitleTap: widget.group ? null : () => context.pushOnce('/bots/${widget.botId}/settings'),
        actions: [
          // Two panes (D-411): the bot's computer takes the list's place beside this chat, and back.
          if (besideList && !widget.group)
            _LiveDot(
              live: computerLive,
              child: HeaderIconButton(
                key: const Key('computerPaneToggle'),
                icon: LucideIcons.monitor,
                tooltip: ref.watch(splitComputerProvider) ? l10n.hideComputer : l10n.showComputer,
                selected: ref.watch(splitComputerProvider),
                onPressed: ref.read(splitComputerProvider.notifier).toggle,
              ),
            )
          // Phones and tablets: a live way into the computer while the bot works on it.
          else if (layout != LayoutSize.desktop && computerLive)
            _LiveDot(
              live: true,
              child: HeaderIconButton(icon: LucideIcons.monitor, tooltip: l10n.chatComputerLive, onPressed: () => context.pushOnce('/computer?bot=${widget.botId}')),
            ),
          // A call is with one bot; in a group only the lead would hear you, so group chats have none.
          if (!widget.group)
          HeaderIconButton(
            key: const Key('callButton'),
            icon: LucideIcons.phone,
            tooltip: l10n.startCall,
            onPressed: () => _callBack(chat.conversationId),
          ),
          // Topics are a bot's own chats (D-253); a new one from a group would leave the group.
          if (!widget.group)
            HeaderIconButton(
              key: const Key('newChatButton'),
              icon: LucideIcons.squarePen,
              tooltip: l10n.newTopic,
              onPressed: chat.running || chat.empty ? null : controller.newChat,
            ),
          _MoreMenu(
            botId: widget.botId,
            showComputer: layout != LayoutSize.desktop,
            onConversations: widget.group ? null : () => _showConversations(context, chat.conversationId),
            projectId: _currentConversation(chat.conversationId)?.projectId,
            onMakeProject: _canMakeProject(chat.conversationId) ? () => _makeProject(chat.conversationId!) : null,
            onFind: chat.empty ? null : _openFind,
            onDelete: chat.running || !_canDeleteCurrent(chat.conversationId) ? null : () => _deleteCurrent(chat.conversationId!, name),
            onMembers: widget.group ? () => _showMembers(context) : null,
          ),
          // Far right, next to the panel it opens and closes; the live dot shows while the bot works on its computer.
          // Group chats have no computer panel (the shell shows it only beside a bot's own chat).
          if (layout == LayoutSize.desktop && !widget.group)
            _LiveDot(
              live: computerLive,
              child: HeaderIconButton(
                key: const Key('computerPanelToggle'),
                icon: LucideIcons.panelRight,
                tooltip: ref.watch(computerPanelProvider) ? l10n.hideComputer : l10n.showComputer,
                selected: ref.watch(computerPanelProvider),
                onPressed: ref.read(computerPanelProvider.notifier).toggle,
              ),
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
            if (chat.loadFailed) {
              thread = EmptyState(
                key: const Key('chatLoadError'),
                icon: LucideIcons.cloudOff,
                isError: true,
                title: l10n.chatLoadFailedTitle,
                message: l10n.chatLoadFailedBody,
                action: FilledButton.tonalIcon(
                  key: const Key('chatLoadRetry'),
                  onPressed: () => controller.open(widget.conversationId ?? chat.conversationId),
                  icon: const Icon(LucideIcons.rotateCw, size: 18),
                  label: Text(l10n.retry),
                ),
              );
            } else if (chat.loading || (_opening && chat.empty)) {
              // Placeholder bubbles where the thread will be, so opening a chat never flashes the
              // starter cards or a spinner.
              thread = Padding(
                padding: EdgeInsets.fromLTRB(side, AppSpace.md, side, 0),
                child: const ChatThreadSkeleton(),
              );
            } else if (chat.empty && widget.group) {
              final g = ref.watch(groupChatsProvider).value?.where((c) => c.id == widget.conversationId).firstOrNull;
              final bots = ref.watch(botsProvider).value ?? const <Bot>[];
              final members = [for (final id in g?.botIds ?? const <String>[]) ?bots.where((b) => b.id == id).firstOrNull];
              thread = EmptyGroupThread(
                title: g == null ? name : groupTitle(g, bots),
                members: members,
                side: side,
                onMention: _startMention,
              );
            } else if (chat.empty) {
              // A new bot goes straight to chat; the setup interview (D-105) is optional, from bot
              // settings (Run Setup Again).
              thread = _EmptyThread(botId: widget.botId, name: name, avatar: bot?.avatarUrl, side: side, width: constraints.maxWidth, onAsk: _send);
            } else {
              thread = Consumer(
                builder: (context, ref, _) {
                  final chat = ref.watch(chatControllerProvider(widget.botId));
                  final rows = _buildRows(context, chat, name, computer, bot?.avatarUrl, showSteps: showSteps, showUsage: showUsage);
                  final keys = {for (final r in rows) r.key};
                  _rowCache.removeWhere((k, _) => !keys.contains(k));
                  final focusId = _focusPending ?? _highlight;
                  final focusIndex = focusId == null ? -1 : rows.indexWhere((r) => r.key == ValueKey(focusId));
                  if (_focusPending != null && focusIndex >= 0) _scrollToFocus(_focusPending!, focusIndex, rows.length);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      shrinkWrap: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(side, AppSpace.md, side, AppSpace.xl),
                      itemCount: rows.length,
                      itemBuilder: (context, revIndex) {
                        final i = rows.length - 1 - revIndex;
                        final row = _rowWidget(rows[i]);
                        final child = rows[i].fresh ? row.appMessageEntrance() : row;
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
                    ),
                  );
                },
              );
            }
            return Column(
              children: [
                // This chat's call, minimised (D-327): tap to go back to it.
                if (!widget.group) CallReturnBar(botId: widget.botId, conversationId: chat.conversationId),
                if (_findOpen)
                  _FindBar(
                    key: const Key('findBar'),
                    botId: widget.botId,
                    onJump: _jumpToMessage,
                    onClose: () => setState(() => _findOpen = false),
                  ),
                ShowHide(
                  child: !chat.offline
                      ? null
                      : Padding(
                    key: const Key('offlineNote'),
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, 0),
                    child: Row(
                      children: [
                        Icon(LucideIcons.wifiOff, size: 16, color: context.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text(l10n.offlineSaved, style: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.onSurfaceVariant))),
                        TextButton(onPressed: () => runGuarded(context, () => controller.open(chat.conversationId)), child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                ),
                // General and topics (D-253): what's going on in other topics, or the way back to General.
                // Always in the tree, so coming and going (topics load late, go idle) slides.
                if (!widget.group)
                  _TopicsBar(
                    hidden: chat.loading || chat.loadFailed || (_opening && chat.empty),
                    botId: widget.botId,
                    currentId: chat.conversationId,
                    side: side,
                    onOpen: _openConversation,
                    onAll: () => _showConversations(context, chat.conversationId),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NotificationListener<ScrollMetricsNotification>(onNotification: _onThreadMetrics, child: _withMentions(thread)),
                      ),
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
                        ReadAloudBar(chatKey: widget.botId, onShowMessage: (id) => setState(() => _focusPending = id)),
                        if (widget.group)
                          MentionPicker(
                            botIds: ref.watch(groupChatsProvider).value?.where((g) => g.id == widget.conversationId).firstOrNull?.botIds.toList() ?? const [],
                            controller: _mentions,
                            lastSpeakerId: chat.lastSpeakerId,
                          ),
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
                          keyHandler: widget.group ? _mentions.handleKey : null,
                          allowSendWhileRunning: !widget.group,
                          // A group's line above says which bot answers; the hint names the group, like the header.
                          hint: l10n.messageHint(group == null ? name : groupTitle(group, groupBots)),
                          running: chat.running,
                          onSend: _sendFromComposer,
                          onStop: () => runGuarded(context, controller.cancel),
                          recording: _recording,
                          transcribing: _transcribing,
                          onDevice: _listening != null || ref.read(dictationRouteProvider).preferDevice,
                          onDictate: _toggleDictation,
                          attachButton: _AttachButton(onFiles: _pickFiles, onPhotos: _pickPhotos, onCamera: _takePhoto),
                          onPasteImage: _pasteImage,
                          hasAttachments: _pending.any((p) => !p.failed),
                          attachments: _pending.isEmpty
                              ? null
                              : SizedBox(
                                  height: 64,
                                  child: EdgeFade(child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _pending.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                                    itemBuilder: (context, i) {
                                      final item = _pending[i];
                                      return _PendingChip(
                                        item: item,
                                        onRemove: () => setState(() => _pending.remove(item)),
                                        onEdit: item.isEditablePhoto ? () => _editPending(item) : null,
                                        onRetry: item.failed ? () => setState(() => _upload(item)) : null,
                                      );
                                    },
                                  )),
                                ),
                        ),
                        // Spend per run lives in the run timeline and Usage, not under the composer.
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
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
          showWarning(context, context.l10n.noComputerForFiles);
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
  List<_Row> _buildRows(BuildContext context, ChatState chat, String name, Computer? computer, String? avatar, {bool showSteps = false, bool showUsage = false}) {
    final rows = <_Row>[];
    // A shown card is its own row; its ui.show step would only repeat it (the timeline keeps it).
    final entries = [for (final e in chat.entries) if (!(e is ToolEntry && e.tool == 'ui.show')) e];
    var lastSide = '';
    var lastHeader = -1;
    final freshFrom = entries.length - 1;
    // The usage line goes under each run's last reply that shows (D-307).
    final lastOfRun = <String, String>{
      if (showUsage)
        for (final e in entries)
          if (e is MessageEntry && e.role == 'assistant' && e.runId != null && (e.text.trim().isNotEmpty || e.attachments.isNotEmpty)) e.runId!: e.id,
    };

    // A bot that publishes the same page several times in one turn (fix, check, fix again) gets
    // one Show in Library button, after its last publish, not one after each.
    final lastPublish = <String>{};
    String? pending;
    for (final e in entries) {
      if (e is MessageEntry && e.role == 'user') {
        if (pending != null) lastPublish.add(pending);
        pending = null;
      } else if (e is ToolEntry && e.tool == 'pages.publish' && e.status == ToolStatus.done) {
        pending = e.callId;
      }
    }
    if (pending != null) lastPublish.add(pending);

    // Older messages exist (Fix 10): scrolling here loads them; the button is the same thing by hand.
    if (chat.hasEarlier) {
      rows.add(
        _Row(
          const ValueKey('earlier'),
          0,
          () => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Center(
              child: chat.loadingEarlier
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpace.sm),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton.icon(
                      key: const Key('loadEarlier'),
                      onPressed: () => runGuarded(context, ref.read(chatControllerProvider(widget.botId).notifier).loadEarlier),
                      icon: const Icon(LucideIcons.arrowUp, size: 16),
                      label: Text(context.l10n.loadEarlierMessages),
                    ),
            ),
          ),
          inputs: chat.loadingEarlier,
        ),
      );
    }

    final allBots = ref.read(botsProvider).value ?? const <Bot>[];
    // Between turns: close with one bot (D-256); group chats leave room for each bot's name.
    final turnGap = widget.group ? AppSpace.xl : AppSpace.md;
    void botSide(String key, [String? fromBot]) {
      // In a group chat each bot's turn gets its own header (D-118).
      final speaker = widget.group && fromBot != null ? allBots.where((b) => b.id == fromBot).firstOrNull : null;
      final side = speaker == null ? 'bot' : 'bot:${speaker.id}';
      if (lastSide != side) {
        lastHeader = rows.length;
        rows.add(
          _Row(
            ValueKey('hdr-$key'),
            lastSide.isEmpty ? 0 : turnGap,
            // One bot (D-256): no name over each turn, only the space between turns. Group chats
            // keep the header, so you can tell the bots apart.
            widget.group ? () => BotTurnHeader(name: speaker?.name ?? name, avatar: speaker?.avatarUrl ?? avatar) : () => const SizedBox.shrink(),
            header: true,
            inputs: (speaker?.name ?? name, speaker?.avatarUrl ?? avatar),
          ),
        );
      }
      lastSide = side;
    }

    /// Who the working line shows: the bot whose turn is running.
    (String, String?) workingBot() {
      final b = widget.group ? allBots.where((x) => x.id == chat.activeBotId).firstOrNull : null;
      return (b?.name ?? name, b?.avatarUrl ?? avatar);
    }

    /// The newest "a person is in control" notice, while no "bot is back" notice came after it: it
    /// carries Hand Back (the buttons themselves check who holds the screen now).
    final heldNotice = () {
      for (var j = entries.length - 1; j >= 0; j--) {
        final e = entries[j];
        if (e is NoticeEntry && e.kind == NoticeKind.botControl) return -1;
        if (e is NoticeEntry && e.kind == NoticeKind.userControl) return e.refId == null ? -1 : j;
      }
      return -1;
    }();
    void openLive(String computerId) => context.pushOnce('/computer/live?c=$computerId');

    /// The running step in everyday words, or that the bot waits for the person while they have
    /// its screen: the newest of the control notices (or an unanswered takeover request) decides.
    String? workingStatus() {
      bool? paused;
      String? doing;
      for (final e in entries.reversed) {
        if (paused == null && e is NoticeEntry) {
          if (e.kind == NoticeKind.userControl) paused = true;
          if (e.kind == NoticeKind.botControl || e.kind == NoticeKind.info) paused = false;
        }
        if (paused == null && e is TakeoverEntry) paused = e.outcome == null;
        if (doing == null && e is ToolEntry && e.status == ToolStatus.running) doing = toolActivity(context.l10n, e.tool);
        if (e is MessageEntry) break;
      }
      return paused == true ? context.l10n.activityWaitingForScreen : doing;
    }

    // When messages were sent (D-387): a quiet label where the day changes or after a pause of an
    // hour or more. It starts a new turn, so the next bot's header shows again in a group chat.
    final now = DateTime.now();
    DateTime? lastAt;
    void timeBreak(DateTime? at, String key) {
      if (at == null) return;
      final kind = chatTimeBreak(lastAt, at);
      lastAt = at;
      if (kind == null) return;
      final label = chatTimeLabel(context, kind, at, now: now);
      rows.add(_Row(ValueKey('time-$key'), rows.any((r) => r.key != const ValueKey('earlier')) ? turnGap : 0, () => ChatTimeDivider(label: label), inputs: label));
      lastSide = '';
    }

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final fresh = i >= freshFrom && chat.running;
      switch (e) {
        case MessageEntry(role: 'user'):
          timeBreak(e.at, e.id);
          rows.add(
            _Row(
              ValueKey(e.id),
              lastSide.isEmpty ? 0 : turnGap,
              () => UserBubble(
                text: e.text,
                sentAt: e.at,
                attachments: e.attachments,
                uploading: e.uploading,
                onResend: e.failed ? () => runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).resend(e.id)) : null,
                onDiscard: e.failed ? () => ref.read(chatControllerProvider(widget.botId).notifier).discardUnsent(e.id) : null,
                siblingIndex: e.siblingIndex,
                siblingCount: e.siblingCount,
                onEdit: chat.running || e.id.startsWith('local-') ? null : () => _editMessage(e),
                onDelete: chat.running || e.id.startsWith('local-') ? null : () => _deleteMessage(e.id),
                onBranch: chat.running ? null : (d) { Analytics.feature('branch_switch'); runGuarded(context, () => ref.read(chatControllerProvider(widget.botId).notifier).switchBranch(e.id, d)); },
                // Saved messages only: one still sending or failed has no server id yet (D-331).
                onReact: _reactable(e) ? (emoji, surface) => _react(e.id, emoji, surface, onBot: false) : null,
                myReaction: ReactionGroup.mineOf(chat.reactions[e.id] ?? const []),
              ),
              fresh: fresh,
              inputs: (e, chat.running, ReactionGroup.mineOf(chat.reactions[e.id] ?? const [])),
            ),
          );
          _reactionRow(rows, e.id, chat.reactions[e.id], onBot: false);
          lastSide = 'user';
        case final MessageEntry m:
          // Files the reply links to (a report, a chart) show under it: images inline, others as cards.
          final shared = m.streaming ? const <AttachmentRef>[] : (_sharedFiles[m] ??= sharedFilesIn(m.text, alreadyShown: m.attachments));
          // A finished reply with no words and nothing to show (only a card or a tool step came of it)
          // gets no row, so no empty bubble or gap.
          // A reply still empty with something after it (a step that went to a tool, or crashed and
          // was re-run) gets no row either: only the newest entry may say Thinking, or they stack.
          final blank = (!m.streaming && m.attachments.isEmpty && textWithoutSharedLinks(m.text, alreadyShown: m.attachments).trim().isEmpty) ||
              (m.streaming && m.attachments.isEmpty && m.text.trim().isEmpty && i != entries.length - 1);
          if (blank && shared.isEmpty) continue;
          timeBreak(m.at, m.id);
          botSide(m.id, m.botId ?? (m.streaming ? chat.activeBotId : null));
          if (!blank) {
            rows.add(
              _Row(
                ValueKey(m.id),
                rows.last.header ? 0 : AppSpace.sm,
                () => AssistantMessage(
                  entry: m,
                  status: workingStatus(),
                  botName: workingBot().$1,
                  botAvatar: workingBot().$2,
                  // The turn's header above already shows the bot, wiggling while it works.
                  workingIcon: !widget.group,
                  onSpeak: !m.streaming ? () => _speak(m) : null,
                  onRegenerate: chat.running || m.streaming || widget.group || controllerOf().questionFor(m.id) == null ? null : () => _regenerate(m.id),
                  onDelete: chat.running || m.streaming || m.id.startsWith('local-') ? null : () => _deleteMessage(m.id),
                  onReact: !m.streaming && _reactable(m) ? (emoji, surface) => _react(m.id, emoji, surface, onBot: true) : null,
                  myReaction: ReactionGroup.mineOf(chat.reactions[m.id] ?? const []),
                ),
                // The status only shows while the reply is still empty; Regenerate and Delete hide while
                // the bot works.
                inputs: (m, m.text.isEmpty && m.streaming ? workingStatus() : null, chat.running, ReactionGroup.mineOf(chat.reactions[m.id] ?? const [])),
              ),
            );
            _reactionRow(rows, m.id, chat.reactions[m.id], onBot: true);
          }
          if (shared.isNotEmpty) rows.add(_Row(ValueKey('files-${m.id}'), AppSpace.xs, () => SharedFiles(files: shared), inputs: shared));
          if (m.runId case final run? when lastOfRun[run] == m.id) {
            rows.add(_Row(ValueKey('usage-$run'), AppSpace.xxs, () => ReplyUsageLine(runId: run, botId: widget.botId), inputs: run));
          }
        case ToolEntry():
          final group = <ToolEntry>[e];
          // Consecutive steps share one card; the computer starting up in between doesn't split it.
          while (i + 1 < entries.length) {
            final next = entries[i + 1];
            if (next is ToolEntry) {
              group.add(next);
              i++;
            } else if (next is NoticeEntry && next.kind == NoticeKind.computer && next.text != 'error' && i + 2 < entries.length && entries[i + 2] is ToolEntry) {
              i++;
            } else {
              break;
            }
          }
          final published = group.any((t) => lastPublish.contains(t.callId));
          // Simple chats leave the steps out; the working line says what's happening (D-162).
          if (showSteps || published) botSide(e.callId, e.botId);
          if (showSteps) {
            rows.add(_Row(ValueKey('tools-${e.callId}'), rows.last.header ? 0 : AppSpace.sm, () => ToolGroupCard(steps: group), inputs: _Same(group)));
          }
          // A published page is in the Library (D-274); the reply's page card opens it in the browser.
          if (published) {
            rows.add(
              _Row(
                ValueKey('pages-${e.callId}'),
                AppSpace.xs,
                () => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    key: Key('openPages-${e.callId}'),
                    icon: const Icon(LucideIcons.library, size: 16),
                    label: Text(context.l10n.showInLibrary),
                    onPressed: () => context.pushOnce('/library?kind=page&bot=${e.botId ?? widget.botId}'),
                  ),
                ),
              ),
            );
          }
        case final ApprovalEntry a:
          botSide(a.approvalId, a.botId);
          // In a group chat, the bot that's asking, not the one that leads the chat (D-118).
          final asking = (widget.group ? allBots.where((b) => b.id == a.botId).firstOrNull?.name : null) ?? name;
          rows.add(
            _Row(
              ValueKey(a.approvalId),
              AppSpace.sm,
              () => ApprovalPrompt(entry: a, botName: asking),
              fresh: fresh,
              inputs: (a, asking),
            ),
          );
        case final TakeoverEntry t:
          botSide('takeover-$i');
          rows.add(
            _Row(
              ValueKey('takeover-$i'),
              AppSpace.sm,
              () => TakeoverPrompt(entry: t, botName: name, onOpen: () => context.pushOnce('/computer/live?c=${t.computerId}')),
              fresh: fresh,
              inputs: (t, name),
            ),
          );
        case final SecretEntry k:
          botSide('secret-${k.requestId}');
          rows.add(_Row(ValueKey('secret-${k.requestId}'), AppSpace.sm, () => SecretPrompt(entry: k, botName: name), fresh: fresh, inputs: (k, name)));
        case final McpSignInEntry m:
          botSide('mcp-sign-in-${m.integrationId}');
          rows.add(_Row(ValueKey('mcp-sign-in-${m.integrationId}'), AppSpace.sm, () => McpSignInPrompt(entry: m), fresh: fresh, inputs: m));
        case final McpQuestionEntry q:
          botSide('mcp-question-${q.questionId}');
          rows.add(_Row(ValueKey('mcp-question-${q.questionId}'), AppSpace.sm, () => McpQuestionPrompt(entry: q), fresh: fresh, inputs: q));
        case final SuggestionEntry e:
          botSide('suggestion-${e.suggestion.id}');
          rows.add(
            _Row(
              ValueKey('suggestion-${e.suggestion.id}'),
              AppSpace.sm,
              () => SuggestionPrompt(entry: e, botId: widget.botId, botName: name, onOpenTopic: _openConversation),
              fresh: fresh,
              inputs: (e, name),
            ),
          );
        case final SuggestionListEntry e:
          botSide('suggestions-${e.messageId}');
          rows.add(
            _Row(
              ValueKey('suggestions-${e.messageId}'),
              AppSpace.sm,
              () => SuggestionListPrompt(entry: e, botId: widget.botId, onOpenTopic: _openConversation),
              fresh: fresh,
              inputs: e,
            ),
          );
        case final TopicLinkEntry e:
          botSide('topic-${e.messageId}');
          rows.add(
            _Row(
              ValueKey('topic-${e.messageId}'),
              AppSpace.xs,
              () => TopicLinkLine(entry: e, onOpen: () => _openConversation(e.topic.conversationId)),
              fresh: fresh,
              inputs: e,
            ),
          );
        case final CallRecapEntry e:
          // Keyed by the call, so its live card becomes the finished one in place (call card plan).
          botSide('call-${e.key}');
          rows.add(
            _Row(
              ValueKey('call-${e.key}'),
              AppSpace.sm,
              () => CallCard(
                key: Key('callCard-${e.key}'),
                entry: e,
                botId: widget.botId,
                botName: name,
                conversationId: chat.conversationId,
                onOpenRun: (runId) => context.pushOnce('/bots/${widget.botId}/runs/$runId'),
                onOpenPath: (path) => context.pushOnce(path),
                onStep: (call, step, {dismiss = false}) =>
                    ref.read(chatControllerProvider(widget.botId).notifier).callStep(call, step, dismiss: dismiss),
                onDelete: (call) => ref.read(chatControllerProvider(widget.botId).notifier).deleteCall(call),
                onCallBack: () => _callBack(chat.conversationId),
              ),
              fresh: fresh,
              inputs: (e, name, chat.conversationId),
            ),
          );
        case final DeviceAccessEntry d:
          botSide('device-${d.kind.value}-$i');
          rows.add(_Row(ValueKey('device-${d.kind.value}-$i'), AppSpace.sm, () => DeviceAccessPrompt(entry: d, botName: name), fresh: fresh, inputs: (d, name)));
        case final PermissionsEntry p:
          // System permissions on a device (D-376); Continue answers as the person.
          final key = 'perms-${p.request.deviceRef}-${p.request.permissions.join(',')}-$i';
          botSide(key);
          rows.add(
            _Row(
              ValueKey(key),
              AppSpace.sm,
              () => PermissionsCard(request: p.request, onContinue: (text) => ref.read(chatControllerProvider(widget.botId).notifier).send(text)),
              fresh: fresh,
              inputs: p,
            ),
          );
        case final GalleryCardEntry g:
          botSide('gallery-${g.messageId}-${g.part.key}');
          rows.add(
            _Row(
              ValueKey('gallery-${g.messageId}-${g.part.key}'),
              AppSpace.sm,
              () => GalleryChatCard(part: g.part, conversationId: chat.conversationId),
              fresh: fresh,
              inputs: (g, chat.conversationId),
            ),
          );
        case final UiEntry u:
          botSide(u.surfaceId);
          rows.add(
            _Row(
              ValueKey('ui-${u.surfaceId}'),
              AppSpace.sm,
              () => BotUiCard(host: _botUi, surfaceId: u.surfaceId, messages: u.messages, answered: chat.answeredUi.contains(u.surfaceId)),
              fresh: fresh,
              inputs: (u, chat.answeredUi.contains(u.surfaceId)),
            ),
          );
        case final NoticeEntry n:
          final last = i == entries.length - 1;
          // Skills, checkpoints and model switches are details of how it works.
          if (!showSteps && (n.kind == NoticeKind.skill || n.kind == NoticeKind.checkpoint || n.kind == NoticeKind.modelFallback)) continue;
          // "Remembered something" says the same thing each time: one line for a run of them, not a
          // stack of identical chips under a reply.
          final prev = i > 0 ? entries[i - 1] : null;
          if (n.kind == NoticeKind.memory && prev is NoticeEntry && prev.kind == NoticeKind.memory) continue;
          // A routine's run starts a new stretch of the chat, often hours after the last message.
          if (n.kind == NoticeKind.routine) timeBreak(n.at?.toLocal(), 'notice-$i');
          rows.add(
            _Row(ValueKey('notice-$i'), AppSpace.sm, () {
              final line = NoticeLine(
                plain: !showSteps,
                entry: n,
                // "Remembered something" opens what was remembered, to check, fix or delete it; a
                // run of several opens the whole list.
                onOpenMemory: n.kind != NoticeKind.memory
                    ? null
                    : () {
                        final next = i + 1 < entries.length ? entries[i + 1] : null;
                        final many = next is NoticeEntry && next.kind == NoticeKind.memory;
                        final id = n.refId;
                        context.pushOnce('/bots/${n.botId ?? widget.botId}/memory${many || id == null ? '' : '?focus=$id'}');
                      },
                onRestore: computer == null ? null : (cp) => confirmRestore(context, ref, computer.id, cp),
                // A broken computer (D-240): restart it from the chat, or open its fixes.
                onRestartComputer: computer == null || n.kind != NoticeKind.computer
                    ? null
                    : () async {
                        final l10n = context.l10n;
                        HapticsHelper.medium();
                        final done = await runGuarded(context, () => ref.read(backendProvider).restartComputer(computer.id));
                        if (done != null && context.mounted) {
                          ref.invalidate(computersProvider);
                          showSuccess(context, l10n.computerRestarted);
                        }
                      },
                onFixComputer: computer == null || n.kind != NoticeKind.computer ? null : () => context.pushOnce('/computer?c=${computer.id}&tab=manage'),
                onUndo: (factId) async {
                  final l10n = context.l10n;
                  final ok = await runGuarded(context, () async {
                    await ref.read(backendProvider).deleteUserFact(factId);
                    return true;
                  });
                  if (ok == true && context.mounted) showSuccess(context, l10n.removedFromProfile);
                },
                onDetails: () => showErrorDetails(context, entry: n, botId: widget.botId),
              );
              if (i == heldNotice) {
                final c = n.refId!;
                return Column(children: [line, ScreenHeldActions(computerId: c, onOpenLive: () => openLive(c))]);
              }
              if (!(last && n.kind == NoticeKind.failed && !chat.running)) return line;
              final fix = errorFix(context, ref, n, widget.botId);
              final canRetry = chat.canRetry;
              if (fix == null && !canRetry) return line;
              return Column(
                children: [
                  line,
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpace.xs,
                    children: [
                      if (fix != null)
                        FilledButton.tonalIcon(
                          key: const Key('noticeFix'),
                          onPressed: () {
                            // Out of credits: packs for a paying workspace, the paywall for a free
                            // one (D-248); the paywall funnel's start (F6).
                            if (fix.route == '/settings/billing') {
                              openOutOfCredits(context);
                              return;
                            }
                            if (fix.route == '/settings/plans') {
                              openPaywall(context, source: 'limit');
                              return;
                            }
                            context.pushOnce(fix.route);
                          },
                          icon: Icon(fix.route.startsWith('/settings/billing') || fix.route == '/settings/plans' ? LucideIcons.gem : LucideIcons.keyRound, size: 18),
                          label: Text(fix.label),
                        ),
                      if (canRetry)
                        TextButton.icon(
                          onPressed: () => runGuarded(context, ref.read(chatControllerProvider(widget.botId).notifier).retry),
                          icon: const Icon(LucideIcons.rotateCw, size: 18),
                          label: Text(context.l10n.retry),
                        ),
                    ],
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
        (last is McpQuestionEntry && last.outcome == null) ||
        (last is UiEntry && !chat.answeredUi.contains(last.surfaceId));
    final replying = last is MessageEntry && last.role == 'assistant' && last.streaming;
    final toolRunning = last is ToolEntry && last.status == ToolStatus.running;
    // With the steps hidden, the working line also shows while a step runs.
    // A group chat waits to know which bot took the turn, so the line never shows a stand-in name
    // and face that then change (D-118).
    final speakerKnown = !widget.group || chat.activeBotId != null;
    if ((chat.running || chat.sending) && speakerKnown && !waitingOnPerson && !replying && (!toolRunning || !showSteps)) {
      botSide('working', chat.activeBotId);
      final (who, face) = workingBot();
      final status = workingStatus() ?? (chat.rechecking ? context.l10n.checkingItsWork : context.l10n.thinking);
      // Right after a finished reply the run usually just wraps up (usage, memory): wait a moment
      // before saying Thinking, so it doesn't flash under the answer and vanish.
      final afterReply = last is MessageEntry && last.role == 'assistant' && !last.streaming;
      final gap = rows.last.header ? 0.0 : AppSpace.md;
      rows.add(
        _Row(
          const ValueKey('working'),
          // While it waits, not even its gap shows, so the reply above doesn't move.
          afterReply ? 0 : gap,
          () => ShowAfter(
            delay: afterReply ? const Duration(milliseconds: 1200) : Duration.zero,
            child: Padding(
              padding: EdgeInsets.only(top: afterReply ? gap : 0),
              // Waiting for the screen: tapping the line hands it back, like the button on the notice.
              child: status == context.l10n.activityWaitingForScreen && heldNotice >= 0
                  ? GestureDetector(
                      key: const Key('workingHandBack'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final c = (entries[heldNotice] as NoticeEntry).refId!;
                        handBackScreen(context, ref, c, onOpenLive: () => openLive(c));
                      },
                      child: WorkingIndicator(status: status, botName: who, botAvatar: face, showIcon: !widget.group),
                    )
                  : WorkingIndicator(status: status, botName: who, botAvatar: face, showIcon: !widget.group),
            ),
          ),
          inputs: (status, who, face, afterReply, heldNotice),
        ),
      );
    }
    // The bot whose turn is running wiggles its avatar while it thinks.
    if (widget.group && chat.running && lastSide.startsWith('bot') && lastHeader >= 0) {
      final h = rows[lastHeader];
      final (who, face) = h.inputs! as (String, String?);
      rows[lastHeader] = _Row(h.key, h.gap, () => BotTurnHeader(name: who, avatar: face, working: true), header: true, inputs: (who, face, true));
    }
    return rows;
  }

  /// Opens General or a topic (D-253) in this chat screen.
  void _openConversation(String id) {
    ref.invalidate(conversationsProvider(widget.botId));
    // The address can already name this conversation while the screen shows another one: New
    // topic and a new chat's first message don't change the address. Going to the same address
    // does nothing, so the person was stuck in the new topic (D-413); open it here instead.
    if (widget.conversationId == id && ref.read(chatControllerProvider(widget.botId)).conversationId != id) {
      _saveDraft();
      _rowCache.clear();
      _stickToBottom = true;
      setState(() => _opening = true);
      Future.microtask(() async {
        final c = ref.read(chatControllerProvider(widget.botId).notifier)..group = widget.group;
        try {
          await c.open(id);
        } finally {
          if (mounted && _opening) setState(() => _opening = false);
          if (mounted) unawaited(_bindDraft(ref.read(chatControllerProvider(widget.botId)).conversationId));
        }
      });
      return;
    }
    context.go('/bots/${widget.botId}/chat?c=$id');
  }

  /// The bots in this group chat, the lead first; one opens its profile.
  Future<void> _showMembers(BuildContext context) async {
    final g = ref.read(groupChatsProvider).value?.where((c) => c.id == widget.conversationId).firstOrNull;
    final bots = ref.read(botsProvider).value ?? const <Bot>[];
    final members = [for (final id in g?.botIds ?? const <String>[]) ?bots.where((b) => b.id == id).firstOrNull];
    await showAdaptiveSheet<void>(
      context: context,
      contentPadsBottom: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(l10n.groupMembers, subtitle: l10n.groupMembersHelp),
            for (final (i, b) in members.indexed)
              ListTile(
                key: Key('groupMember-${b.id}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 36),
                title: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: i == 0 ? Text(l10n.groupLead) : null,
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.pushOnce('/bots/${b.id}/settings');
                },
              ),
            const SizedBox(height: AppSpace.sm),
          ],
        );
      },
    );
  }

  Future<void> _showConversations(BuildContext context, String? currentId) async {
    ref.invalidate(conversationsProvider(widget.botId));
    await showAdaptiveSheet<void>(
      context: context,
      heightFactor: 0.7,
      contentPadsBottom: true,
      builder: (sheetContext) => _ConversationsSheet(
        botId: widget.botId,
        currentId: currentId,
        onNew: () {
          Navigator.of(sheetContext).pop();
          ref.read(chatControllerProvider(widget.botId).notifier).newChat();
        },
        onOpen: (id) {
          Navigator.of(sheetContext).pop();
          _openConversation(id);
        },
        onDelete: (c) async {
          final name = ref.read(botProvider(widget.botId))?.name ?? '';
          final deleted = await confirmDeleteChat(sheetContext, ref, conversationId: c.id, botId: widget.botId, botName: name);
          // The open chat was the one deleted: start fresh behind the sheet.
          if (deleted && c.id == ref.read(chatControllerProvider(widget.botId)).conversationId) {
            ref.read(chatControllerProvider(widget.botId).notifier).newChat();
          }
        },
      ),
    );
  }
}

/// A file chosen for the next message: uploading until [ref] is set.
class _Pending {
  _Pending({required this.name, required this.bytes, required this.mime, required this.apiPath, required this.computerId});
  String name;
  Uint8List bytes;
  String mime;
  String apiPath;
  final String computerId;

  /// Set once the upload finished.
  AttachmentRef? ref;
  var failed = false;

  /// The current upload: true when it is on the computer.
  Future<bool>? upload;
  var attempt = 0;

  /// What the message will point at, known before the upload ends.
  AttachmentRef get plannedRef => AttachmentRef(path: 'workspace/$apiPath', name: name, mimeType: mime, size: bytes.length);

  bool get isEditablePhoto => mime.startsWith('image/') && mime != 'image/heic' && mime != 'image/gif' && mime != 'image/svg+xml';
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.item, required this.onRemove, this.onEdit, this.onRetry});
  final _Pending item;
  final VoidCallback onRemove;

  /// Opens the photo editor (photos only).
  final VoidCallback? onEdit;

  /// Uploads a failed file again.
  final VoidCallback? onRetry;

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
              ? GestureDetector(
                  onTap: onEdit,
                  child: Image(image: CoverMemoryImage.sized(item.bytes, const Size.square(64), MediaQuery.devicePixelRatioOf(context)), fit: BoxFit.cover, gaplessPlayback: true),
                )
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
                            Text(formatBytes(item.bytes.length, context.l10n.localeName), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        // Uploading shows as a small ring in the corner, not a veil: the photo can still be
        // edited and the message sent meanwhile.
        if (uploading)
          const Positioned(
            left: 6,
            top: 6,
            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round)),
          ),
        if (onRetry != null)
          Positioned.fill(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.row),
              child: InkWell(
                key: Key('retry-${item.name}'),
                borderRadius: BorderRadius.circular(AppRadius.row),
                onTap: onRetry,
                child: Tooltip(
                  message: context.l10n.retryUpload,
                  child: Icon(LucideIcons.rotateCw, size: 20, color: scheme.error),
                ),
              ),
            ),
          )
        else if (onEdit != null)
          Positioned(
            right: 4,
            bottom: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                key: Key('edit-${item.name}'),
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Tooltip(
                  message: context.l10n.editPhoto,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(LucideIcons.pencil, size: 12, color: Colors.white),
                  ),
                ),
              ),
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

/// The parts of [ChatState] the chat screen shows outside the thread (a record: equal by value).
typedef _ChatFrame = ({bool loading, bool loadFailed, bool offline, bool running, bool empty, String? conversationId, String? lastSpeakerId});

_ChatFrame _chatFrame(ChatState c, {required bool group}) => (
  loading: c.loading,
  loadFailed: c.loadFailed && c.entries.isEmpty,
  offline: c.offline,
  running: c.running,
  empty: c.entries.isEmpty,
  conversationId: c.conversationId,
  // Group chats suggest @-mentions starting with whoever spoke last.
  lastSpeakerId: group ? c.entries.whereType<MessageEntry>().where((m) => m.role == 'assistant' && m.botId != null).lastOrNull?.botId : null,
);

class _Row {
  _Row(this.key, this.gap, this.build, {this.fresh = false, this.header = false, this.inputs});
  final Key key;
  final double gap;
  final Widget Function() build;

  /// Everything [build] reads, compared with `==` (entries by identity, since an entry that
  /// changes is replaced). A row whose inputs are unchanged gets back the widget built last time,
  /// which Flutter skips entirely; null means always build.
  final Object? inputs;

  /// The bot's name above its turn; the first row after it needs no gap.
  final bool header;

  /// Animates in (the newest entries while a run streams).
  final bool fresh;
}

/// A list compared by its elements' identity: a tool card's steps.
class _Same {
  const _Same(this.items);
  final List<Object> items;

  @override
  bool operator ==(Object other) {
    if (other is! _Same || other.items.length != items.length) return false;
    for (var i = 0; i < items.length; i++) {
      if (!identical(other.items[i], items[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items.map(identityHashCode));
}

/// The first open: the bot's mark and one line of what it can do, centered above starter requests
/// parked by the composer.
class _EmptyThread extends ConsumerWidget {
  const _EmptyThread({required this.botId, required this.name, this.avatar, required this.side, required this.width, required this.onAsk});
  final String botId;
  final String name;
  final String? avatar;
  final double side;

  /// The chat pane's width; less [side] on both edges it is what the app tiles get.
  final double width;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    // Written for this person by the server (D-338); the app's own while it first loads (hidden, so
    // nothing jumps) or when the server can't give them.
    final personal = ref.watch(botStartersProvider(botId));
    final served = personal.value;
    final waiting = served == null && personal.isLoading;
    final suggestions = served != null && served.items.isNotEmpty
        ? [for (final s in served.items) (s.emoji, s.text)]
        : _suggestions(context);
    final source = served == null || served.items.isEmpty ? 'app' : served.source_.value;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          // Same bottom room as the message list, so the last starter clears the composer.
          padding: EdgeInsets.fromLTRB(side, AppSpace.lg, side, AppSpace.xl),
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
                // Apps to connect first, until two are connected (D-204).
                ConnectAppTiles(botId: botId, botName: name, width: width - 2 * side),
                const SizedBox(height: AppSpace.md),
                AnimatedOpacity(
                  opacity: waiting ? 0 : 1,
                  duration: AppMotion.duration,
                  child: AnimatedSwitcher(
                    duration: AppMotion.duration,
                    // A new list (the personal one arriving) fades over the old one.
                    child: Column(
                      key: ValueKey(suggestions.map((s) => s.$2).join('|')),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < suggestions.length; i++)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs),
                            child: AppCard(
                              key: Key('suggestion-$i'),
                              onTap: waiting
                                  ? null
                                  : () {
                                      Analytics.log('starter_tapped', {'source': source, 'position': i});
                                      onAsk(suggestions[i].$2);
                                    },
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

/// The chat's … menu: its conversations, the computer (phones and tablets) and the bot's profile,
/// where its memory, routines and apps live (and its activity, under Advanced).
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.botId, required this.showComputer, required this.onConversations, this.projectId, this.onMakeProject, this.onFind, this.onDelete, this.onMembers});
  final String botId;

  /// Group chats (D-118): the bots in it, each opening its own profile, in place of one bot's.
  final VoidCallback? onMembers;
  final bool showComputer;
  final VoidCallback? onConversations;

  /// The project this chat belongs to (D-295), when it has one.
  final String? projectId;

  /// Set in a topic of the person's own that isn't a project yet.
  final VoidCallback? onMakeProject;

  /// Find in this chat (Add 11); null while the chat is empty.
  final VoidCallback? onFind;

  /// Set when this chat may be deleted now (it exists, it's yours or you manage the bot, and the
  /// bot isn't working in it).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    MenuItemButton item(IconData icon, String label, VoidCallback onPressed, {Key? key}) => MenuItemButton(
      key: key,
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
        if (onConversations != null) item(LucideIcons.messagesSquare, l10n.topics, onConversations!, key: const Key('openConversations')),
        if (onFind != null) item(LucideIcons.textSearch, l10n.findInChat, onFind!, key: const Key('findInChat')),
        if (projectId != null)
          item(LucideIcons.folderKanban, l10n.openProject, () => context.pushOnce('/projects/$projectId'), key: const Key('openProject'))
        else if (onMakeProject != null)
          item(LucideIcons.folderPlus, l10n.makeProject, onMakeProject!, key: const Key('makeProject')),
        if (showComputer) item(LucideIcons.monitor, l10n.navComputer, () => context.pushOnce('/computer?bot=$botId'), key: const Key('openComputer')),
        const Divider(),
        if (onMembers != null)
          item(LucideIcons.users, l10n.groupMembers, onMembers!, key: const Key('openGroupMembers'))
        else
          item(LucideIcons.circleUser, l10n.botProfile, () => context.pushOnce('/bots/$botId/settings'), key: const Key('openBotProfile')),
        if (onDelete != null) ...[
          const Divider(),
          MenuItemButton(
            key: const Key('deleteChat'),
            leadingIcon: Icon(LucideIcons.trash2, size: 20, color: context.colorScheme.error),
            onPressed: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(l10n.deleteChat, style: TextStyle(color: context.colorScheme.error)),
            ),
          ),
        ],
      ],
      builder: (context, controller, _) => HeaderIconButton(
        key: const Key('chatMoreMenu'),
        icon: LucideIcons.ellipsis,
        tooltip: l10n.moreActions,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// A small green dot that gently pulses on a header button while the bot works on its computer
/// (still when the system asks to reduce motion).
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.live, required this.child});
  final bool live;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (live)
          Positioned(
            top: 2,
            right: 5,
            child: IgnorePointer(
              child: Pulse(
                key: const Key('chatComputerLive'),
                from: 0.8,
                to: 1.1,
                fadeFrom: 0.55,
                duration: const Duration(milliseconds: 1100),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: context.appColors.positive,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Whether the run in progress has used the bot's computer since the person's last message: a
/// computer step (terminal, desktop, browser, files) or the computer waking, unless it went back
/// to sleep after.
bool _computerInUse(ChatState c) {
  if (!c.running) return false;
  for (var i = c.entries.length - 1; i >= 0; i--) {
    final e = c.entries[i];
    if (e is MessageEntry && e.role == 'user') return false;
    if (e is ToolEntry && const ['shell', 'desktop', 'computer', 'checkpoint', 'browser', 'files'].any(e.tool.startsWith)) return true;
    if (e is NoticeEntry && e.kind == NoticeKind.computer) return !const {'sleeping', 'stopped', 'error'}.contains(e.text);
  }
  return false;
}

/// The chats list while it loads: rows shaped like its chat tiles (icon, title, time), with the
/// list's insets and gaps. Doesn't scroll; what runs past the sheet is clipped.
class _ConversationsSkeleton extends StatelessWidget {
  const _ConversationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final title = context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        children: [
          for (final (i, w) in const [0.52, 0.4, 0.6, 0.34, 0.48, 0.44].indexed) ...[
            if (i > 0) const SizedBox(height: 2),
            SizedBox(
              // A one-line ListTile.
              height: 56,
              child: SkeletonRow(
                leadingSize: 20,
                trailing: SkeletonTrailing.meta,
                subtitle: false,
                padding: const EdgeInsetsDirectional.only(start: 16, end: 24),
                gap: 16,
                titleStyle: title,
                titleWidth: w,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationsSheet extends ConsumerWidget {
  const _ConversationsSheet({required this.botId, required this.currentId, required this.onNew, required this.onOpen, required this.onDelete});
  final String botId;
  final String? currentId;
  final VoidCallback onNew;
  final ValueChanged<String> onOpen;

  /// Deletes a chat after asking (rows the person may delete: theirs, or all if they manage the bot).
  final ValueChanged<Conversation> onDelete;

  /// Renames a topic (Improve app 2); an empty name goes back to the automatic one.
  Future<void> _rename(BuildContext context, WidgetRef ref, Conversation c) async {
    final title = await showAdaptiveSheet<String>(context: context, builder: (_) => _RenameTopicSheet(initial: c.title ?? ''));
    if (title == null || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).updateConversation(c.id, title: title.trim()));
    ref.invalidate(conversationsProvider(botId));
  }

  /// Pins a topic so it stays near the top of the list and among the chips (Improve app 2).
  Future<void> _pin(BuildContext context, WidgetRef ref, Conversation c) async {
    await runGuarded(context, () => ref.read(backendProvider).updateConversation(c.id, pinned: c.pinned != true));
    ref.invalidate(conversationsProvider(botId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final convos = ref.watch(conversationsProvider(botId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          l10n.topics,
          trailing: FilledButton.tonalIcon(onPressed: onNew, icon: const Icon(LucideIcons.squarePen, size: 18), label: Text(l10n.newTopic)),
        ),
        Expanded(
          child: AsyncView(
            value: convos,
            onRetry: () => ref.invalidate(conversationsProvider(botId)),
            loading: const _ConversationsSkeleton(),
            data: (all) {
              // General first, then live topics, then those idle a week under Older (D-253).
              final split = splitTopics(all);
              final items = [...split.active, ...split.older];
              return items.isEmpty
                ? EmptyState(icon: LucideIcons.messagesSquare, message: l10n.noConversations)
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, BottomPadding.of(context, minimum: AppSpace.md)),
                    itemCount: items.length,
                    separatorBuilder: (_, i) => split.older.isNotEmpty && i == split.active.length - 1
                        ? Padding(
                            key: const Key('olderTopics'),
                            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xs),
                            child: Text(l10n.olderTopics, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                          )
                        : const SizedBox(height: 2),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final current = c.id == currentId;
                      return ListTile(
                        key: Key('topicRow-${c.id}'),
                        selected: current,
                        leading: Icon(
                          c.isMain == true
                              ? LucideIcons.house
                              : c.status == ConversationStatusEnum.needsYou
                              ? LucideIcons.circleAlert
                              : c.pinned == true
                              ? LucideIcons.pin
                              : LucideIcons.messagesSquare,
                          size: 20,
                        ),
                        title: Text(
                          c.isMain == true ? l10n.generalChat : c.title.orPlaceholder(l10n.untitledChat),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(fontWeight: current ? FontWeight.w700 : FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              relativeTime(c.lastMessageAt ?? c.createdAt, context),
                              style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (c.canDelete == true)
                              MenuAnchor(
                                alignmentOffset: const Offset(-140, 0),
                                menuChildren: [
                                  if (c.isMain != true) ...[
                                    MenuItemButton(
                                      key: Key('renameConversation-${c.id}'),
                                      leadingIcon: const Icon(LucideIcons.pencil, size: 20),
                                      onPressed: () => _rename(context, ref, c),
                                      child: Text(l10n.renameTopic),
                                    ),
                                    MenuItemButton(
                                      key: Key('pinConversation-${c.id}'),
                                      leadingIcon: Icon(c.pinned == true ? LucideIcons.pinOff : LucideIcons.pin, size: 20),
                                      onPressed: () => _pin(context, ref, c),
                                      child: Text(c.pinned == true ? l10n.unpinTopic : l10n.pinTopic),
                                    ),
                                  ],
                                  MenuItemButton(
                                    key: Key('deleteConversation-${c.id}'),
                                    leadingIcon: Icon(LucideIcons.trash2, size: 20, color: scheme.error),
                                    onPressed: () => onDelete(c),
                                    child: Text(l10n.deleteChat, style: TextStyle(color: scheme.error)),
                                  ),
                                ],
                                builder: (context, controller, _) => IconButton(
                                  key: Key('topicMenu-${c.id}'),
                                  tooltip: l10n.moreActions,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(LucideIcons.ellipsis, size: 18, color: scheme.onSurfaceVariant),
                                  onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => onOpen(c.id),
                        onLongPress: c.canDelete == true ? () => onDelete(c) : null,
                      );
                    },
                  );
            },
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

/// Find in this chat (Add 11): matches the messages loaded so far, newest first; the arrows step
/// through them and each one scrolls into view, highlighted. Enter goes to the next older match,
/// Shift+Enter back, Esc closes.
class _FindBar extends ConsumerStatefulWidget {
  const _FindBar({super.key, required this.botId, required this.onJump, required this.onClose});
  final String botId;
  final ValueChanged<String> onJump;
  final VoidCallback onClose;

  @override
  ConsumerState<_FindBar> createState() => _FindBarState();
}

/// The ids of messages in [entries] containing every word of [query], newest first.
List<String> findInEntries(List<ChatEntry> entries, String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  return [
    for (final e in entries.reversed)
      if (e is MessageEntry && !e.streaming && words.every(e.text.toLowerCase().contains)) e.id,
  ];
}

class _FindBarState extends ConsumerState<_FindBar> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  var _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> get _matches => findInEntries(ref.read(chatControllerProvider(widget.botId)).entries, _text.text);

  void _go(int index) {
    final matches = _matches;
    if (matches.isEmpty) return setState(() => _index = 0);
    final i = index % matches.length;
    setState(() => _index = i < 0 ? i + matches.length : i);
    widget.onJump(matches[_index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    ref.watch(chatControllerProvider(widget.botId).select((c) => c.entries.length));
    final matches = _matches;
    final query = _text.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
                const SingleActivator(LogicalKeyboardKey.enter, shift: true): () => _go(_index - 1),
              },
              child: Row(
                children: [
                  const SizedBox(width: AppSpace.sm),
                  Icon(LucideIcons.search, size: 18, color: scheme.onSurfaceVariant),
                  Expanded(
                    child: TextField(
                      key: const Key('findInChatField'),
                      controller: _text,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.findInChatHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
                      ),
                      onChanged: (_) => _go(0),
                      onSubmitted: (_) {
                        _go(_index + 1);
                        _focus.requestFocus();
                      },
                    ),
                  ),
                  if (query.isNotEmpty)
                    Text(
                      matches.isEmpty ? l10n.findInChatNone : l10n.findInChatCount(_index + 1, matches.length),
                      key: const Key('findCount'),
                      style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                    ),
                  IconButton(
                    key: const Key('findOlder'),
                    tooltip: l10n.findPrevious,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.chevronUp, size: 18),
                    onPressed: matches.length < 2 ? null : () => _go(_index + 1),
                  ),
                  IconButton(
                    key: const Key('findNewer'),
                    tooltip: l10n.findNext,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.chevronDown, size: 18),
                    onPressed: matches.length < 2 ? null : () => _go(_index - 1),
                  ),
                  IconButton(
                    key: const Key('closeFind'),
                    tooltip: l10n.closeFind,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: widget.onClose,
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

class _RenameTopicSheet extends StatefulWidget {
  const _RenameTopicSheet({required this.initial});
  final String initial;

  @override
  State<_RenameTopicSheet> createState() => _RenameTopicSheetState();
}

class _RenameTopicSheetState extends State<_RenameTopicSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.pencil,
      title: l10n.renameTopic,
      submitLabel: l10n.save,
      submitKey: const Key('saveTopicName'),
      onSubmit: () => Navigator.pop(context, _text.text),
      children: [
        TextField(
          key: const Key('topicNameField'),
          controller: _text,
          autofocus: true,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.routineName, hintText: l10n.untitledChat),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ],
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.initial});
  final String initial;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.pencil,
      title: l10n.editMessage,
      subtitle: l10n.editMessageHelp,
      submitLabel: l10n.send,
      submitKey: const Key('sendEdit'),
      onSubmit: () => Navigator.pop(context, _text.text),
      children: [TextField(key: const Key('editField'), controller: _text, autofocus: true, minLines: 2, maxLines: 10)],
    );
  }
}


/// General and topics (D-253): General first, then pinned topics and topics with something going
/// on or a message in the last week (needs you, then pinned, then working, then newest), then the rest as Older. Chats that aren't
/// topics (a chat app's thread, a ticket, a watcher) are only listed under Older.
({List<Conversation> active, List<Conversation> older}) splitTopics(List<Conversation> all, {DateTime? now}) {
  final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 7));
  int rank(Conversation c) => c.isMain == true
      ? 0
      : c.status == ConversationStatusEnum.needsYou
      ? 1
      : c.pinned == true
      ? 2
      : c.status == ConversationStatusEnum.working
      ? 3
      : 4;
  // Pinned chats (Improve app 2) never move to Older.
  bool live(Conversation c) =>
      c.isMain == true ||
      c.pinned == true ||
      (c.parentConversationId != null && (c.status != null || (c.lastMessageAt ?? c.createdAt).isAfter(cutoff)));
  final active = all.where(live).toList()
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt);
    });
  return (active: active, older: all.where((c) => !live(c)).toList());
}

/// Above the thread (D-253). In General: chips for the topics going on (needs you first), and All
/// topics. In a topic: the way back to General.
class _TopicsBar extends ConsumerWidget {
  const _TopicsBar({required this.botId, required this.currentId, required this.side, required this.onOpen, required this.onAll, this.hidden = false});
  final bool hidden;
  final String botId;
  final String? currentId;
  final double side;
  final ValueChanged<String> onOpen;
  final VoidCallback onAll;

  static const _maxChips = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ShowHide(child: hidden ? null : _bar(context, ref));

  Widget? _bar(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final all = ref.watch(conversationsProvider(botId)).value ?? const <Conversation>[];
    final main = all.where((c) => c.isMain == true).firstOrNull;
    if (main == null) return null;
    final inGeneral = currentId == main.id;
    final List<Widget> chips;
    if (inGeneral) {
      final topics = splitTopics(all).active.where((c) => c.isMain != true).toList();
      if (topics.isEmpty) return null;
      chips = [
        for (final c in topics.take(_maxChips))
          ActionChip(
            key: Key('topicChip-${c.id}'),
            avatar: switch (c.status) {
              ConversationStatusEnum.needsYou => Icon(LucideIcons.circleAlert, size: 16, color: colors.waiting),
              ConversationStatusEnum.working => SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colors.working)),
              _ => Icon(LucideIcons.messagesSquare, size: 16, color: scheme.onSurfaceVariant),
            },
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(c.title.orPlaceholder(l10n.untitledChat), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            onPressed: () => onOpen(c.id),
          ),
        ActionChip(
          key: const Key('allTopics'),
          label: Text(l10n.allTopics),
          onPressed: onAll,
        ),
      ];
    } else {
      final here = all.where((c) => c.id == currentId).firstOrNull;
      chips = [
        ActionChip(
          key: const Key('backToGeneral'),
          avatar: Icon(LucideIcons.arrowLeft, size: 16, color: scheme.primary),
          label: Text(l10n.generalChat),
          onPressed: () => onOpen(main.id),
        ),
        // A topic that is a project's chat leads to the project (D-295).
        if (here?.projectId != null)
          ActionChip(
            key: const Key('topicProject'),
            avatar: Icon(LucideIcons.folderKanban, size: 16, color: scheme.onSurfaceVariant),
            label: Text(l10n.creationProjectLabel),
            onPressed: () => context.pushOnce('/projects/${here!.projectId}'),
          ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.xxs),
          // Capped, so a long title ends in "…" instead of running off the edge of the bar; and an
          // untitled topic keeps the name it had before the first message ("New topic").
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
            currentId == null ? l10n.newTopic : here?.title.orPlaceholder(l10n.newTopic) ?? '',
            key: const Key('topicTitle'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          ),
        ),
      ];
    }
    return SizedBox(
      key: const Key('topicsBar'),
      height: 56,
      child: EdgeFade(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // A gap below the chips too, so they don't sit on the first message.
          padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xs),
          child: Row(spacing: AppSpace.xs, children: chips),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../../core/backend.dart';
import '../../core/mobile_extras.dart';
import '../../core/local_cache.dart';
import '../../core/providers.dart';

enum ToolStatus { running, done, failed }

/// One entry in the chat: a message, a tool step, or a short notice.
sealed class ChatEntry {
  const ChatEntry();
}

class MessageEntry extends ChatEntry {
  const MessageEntry({
    required this.id,
    required this.role,
    required this.text,
    this.streaming = false,
    this.attachments = const [],
    this.siblingIndex = 1,
    this.siblingCount = 1,
    this.botId,
    this.uploading = false,
    this.failed = false,
  });
  final String id;

  /// Yours, and it didn't reach the server: shown with Try Again instead of being lost.
  final bool failed;

  /// Sent before its files finished uploading: shown at once, delivered when they are up.
  final bool uploading;

  /// The bot that wrote it, in group chats (D-118).
  final String? botId;
  final String role;
  final String text;
  final bool streaming;
  final List<AttachmentRef> attachments;

  /// Edited versions of a message are siblings; arrows switch between them (D-108).
  final int siblingIndex;
  final int siblingCount;
  MessageEntry copyWith({String? id, String? text, bool? streaming, List<AttachmentRef>? attachments, bool? uploading, bool? failed}) => MessageEntry(
        id: id ?? this.id,
        role: role,
        text: text ?? this.text,
        streaming: streaming ?? this.streaming,
        attachments: attachments ?? this.attachments,
        siblingIndex: siblingIndex,
        siblingCount: siblingCount,
        botId: botId,
        uploading: uploading ?? this.uploading,
        failed: failed ?? this.failed,
      );
}

/// A message's files did not upload, so it was not sent.
class UploadsFailed implements Exception {
  const UploadsFailed();
}

class ToolEntry extends ChatEntry {
  const ToolEntry({
    required this.callId,
    required this.tool,
    required this.args,
    this.output = '',
    this.status = ToolStatus.running,
    this.preview,
    this.durationMs,
    this.error,
    this.artifactPath,
  });
  final String callId;
  final String tool;
  final Map<String, Object?> args;
  final String output;
  final ToolStatus status;
  final String? preview;
  final int? durationMs;
  final String? error;
  final String? artifactPath;

  ToolEntry copyWith({String? output, ToolStatus? status, String? preview, int? durationMs, String? error, String? artifactPath}) => ToolEntry(
    callId: callId,
    tool: tool,
    args: args,
    output: output ?? this.output,
    status: status ?? this.status,
    preview: preview ?? this.preview,
    durationMs: durationMs ?? this.durationMs,
    error: error ?? this.error,
    artifactPath: artifactPath ?? this.artifactPath,
  );
}

/// A tool call waiting for someone's decision; [decision] is set once resolved.
class ApprovalEntry extends ChatEntry {
  const ApprovalEntry({required this.approvalId, required this.tool, required this.args, required this.risk, this.decision});
  final String approvalId;
  final String tool;
  final Map<String, Object?> args;
  final String risk;
  final String? decision;
}

/// A bot asking a person to take over its screen; [outcome] is set once resolved.
class TakeoverEntry extends ChatEntry {
  const TakeoverEntry({required this.computerId, required this.reason, this.outcome, this.note});
  final String computerId;
  final String reason;
  final String? outcome;
  final String? note;
}

/// A bot asking for a secret (D-101); the value is typed into the card and never kept here.
class SecretEntry extends ChatEntry {
  const SecretEntry({required this.requestId, required this.name, required this.service, required this.hosts, required this.reason, this.totp = false, this.outcome});
  final String requestId;
  final bool totp;
  final String name;
  final String service;
  final List<String> hosts;
  final String reason;
  final String? outcome;
}

/// A bot asking for one kind of the person's device data (D-149): a one-tap card.
class DeviceAccessEntry extends ChatEntry {
  const DeviceAccessEntry({required this.kind, required this.reason, required this.botId});
  final DeviceKind kind;
  final String reason;
  final String botId;
}

/// A suggestion the bot posted in General (D-253): Do it opens a topic, Not now dismisses it.
class SuggestionEntry extends ChatEntry {
  const SuggestionEntry({required this.messageId, required this.suggestion});
  final String messageId;
  final MessageSuggestion suggestion;
}

/// Several suggestions in one card (D-257): a Do it on each, one Not now for the rest.
class SuggestionListEntry extends ChatEntry {
  const SuggestionListEntry({required this.messageId, required this.items});
  final String messageId;
  final List<MessageSuggestion> items;
}

/// A topic's result posted back to General (D-253): a link into the topic.
class TopicLinkEntry extends ChatEntry {
  const TopicLinkEntry({required this.messageId, required this.topic});
  final String messageId;
  final MessageTopic topic;
}

/// An interactive UI the bot showed (D-086), rendered from A2UI messages.
class UiEntry extends ChatEntry {
  const UiEntry({required this.surfaceId, required this.messages});
  final String surfaceId;
  final List<Object?> messages;
}

enum NoticeKind { memory, profileSaved, skill, checkpoint, computer, failed, cancelled, userControl, botControl, modelFallback, info, routine }

class NoticeEntry extends ChatEntry {
  const NoticeEntry({required this.kind, required this.text, this.refId, this.errorCode, this.at});
  final NoticeKind kind;
  final String text;

  /// The checkpoint (checkpoint notices) or the run (failures).
  final String? refId;
  final String? errorCode;
  final DateTime? at;
}

/// What a message was sent with: Retry after a failed run sends exactly this again (Fix 12).
typedef SentMessage = ({String text, List<AttachmentRef> attachments, List<String> skills, Map<String, Object?>? uiAction});

class ChatState {
  const ChatState({
    this.conversationId,
    this.entries = const [],
    this.loading = false,
    this.activeRunId,
    this.lastRunId,
    this.costUsd = 0,
    this.tokens = 0,
    this.lastSent,
    this.answeredUi = const {},
    this.offline = false,
    this.activeBotId,
    this.loadFailed = false,
    this.hasEarlier = false,
    this.loadingEarlier = false,
  });

  /// The thread has messages older than the ones loaded (Fix 10); [loadingEarlier] while the next
  /// page up is on its way.
  final bool hasEarlier;
  final bool loadingEarlier;
  final String? conversationId;

  /// The chat couldn't be loaded and nothing is saved on the device: the screen says so and
  /// offers Try Again, instead of placeholders that never end.
  final bool loadFailed;

  /// In a group chat, the bot whose run is on screen: it heads "thinking" and the streaming reply.
  final String? activeBotId;

  /// Showing saved messages because the server couldn't be reached (D-112).
  final bool offline;
  final List<ChatEntry> entries;
  final bool loading;
  final String? activeRunId;
  final String? lastRunId;
  final double costUsd;
  final int tokens;
  final SentMessage? lastSent;

  /// The last message sent from here can be sent again (words, files, or both).
  bool get canRetry => lastSent != null;

  /// Bot UIs the person has already answered; they stay visible but can't be used again.
  final Set<String> answeredUi;

  bool get running => activeRunId != null;

  ChatState copyWith({
    String? conversationId,
    List<ChatEntry>? entries,
    bool? loading,
    String? activeRunId,
    bool clearActiveRun = false,
    String? lastRunId,
    double? costUsd,
    int? tokens,
    SentMessage? lastSent,
    Set<String>? answeredUi,
    bool? offline,
    String? activeBotId,
    bool? loadFailed,
    bool? hasEarlier,
    bool? loadingEarlier,
  }) => ChatState(
    hasEarlier: hasEarlier ?? this.hasEarlier,
    loadingEarlier: loadingEarlier ?? this.loadingEarlier,
    loadFailed: loadFailed ?? this.loadFailed,
    conversationId: conversationId ?? this.conversationId,
    entries: entries ?? this.entries,
    loading: loading ?? this.loading,
    activeRunId: clearActiveRun ? null : (activeRunId ?? this.activeRunId),
    lastRunId: lastRunId ?? this.lastRunId,
    costUsd: costUsd ?? this.costUsd,
    tokens: tokens ?? this.tokens,
    lastSent: lastSent ?? this.lastSent,
    answeredUi: answeredUi ?? this.answeredUi,
    offline: offline ?? this.offline,
    activeBotId: clearActiveRun ? null : (activeBotId ?? this.activeBotId),
  );
}

/// Chat with one bot: loads a conversation, sends messages and applies live run events.
class ChatController extends Notifier<ChatState> {
  ChatController(this.botId);
  final String botId;
  StreamSubscription<RunEventItem>? _sub;

  /// The open conversation's activity from other devices and triggers (D-224).
  StreamSubscription<String?>? _watch;
  String? _watching;

  Backend get _backend => ref.read(backendProvider);

  @override
  ChatState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _watch?.cancel();
    });
    return const ChatState();
  }

  /// Follows runs that start in [id] from anywhere else (another phone, a routine, a group
  /// @mention): the thread reloads and the new run streams in, as if it had started here.
  void _follow(String id) {
    if (_watching == id) return;
    _watch?.cancel();
    _watching = id;
    _watch = _backend.watchConversation(id).listen((runId) async {
      // A message sent here attaches its own run; a moment's wait keeps this from racing it.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (state.conversationId != id || state.running) return;
      // Already following it, or a reconnect while nothing changed: open() checks anyway.
      if (runId != null && state.lastRunId == runId) return;
      await open(id);
    });
  }

  void _unfollow() {
    _watch?.cancel();
    _watch = null;
    _watching = null;
  }

  /// Opens a conversation (or the most recent one when null).
  ChatState _fromMessages(
    String id,
    List<ChatMessageView> messages, {
    bool offline = false,
    bool hasEarlier = false,
  }) {
    return ChatState(
      conversationId: id,
      offline: offline,
      hasEarlier: hasEarlier,
      lastSent: state.conversationId == id ? state.lastSent : null,
      loadingEarlier: state.conversationId == id && state.loadingEarlier,
      entries: [..._entriesOf(id, messages), ..._notDelivered(id)],
      answeredUi: {for (final m in messages) ?m.uiActionSurface},
    );
  }

  /// Messages the server doesn't have yet, so a reload can't bring them back (Fix 11): ones that
  /// failed to send (kept for Try Again) and ones still waiting for their files.
  static bool _local(ChatEntry e) => e is MessageEntry && (e.failed || e.uploading);

  List<ChatEntry> _notDelivered(String id) =>
      state.conversationId == id ? [for (final e in state.entries) if (_local(e)) e] : (_parked[id] ?? const []);

  /// The same, for chats this controller has moved away from: they come back with the chat.
  final _parked = <String, List<ChatEntry>>{};

  void _park() {
    final id = state.conversationId;
    if (id == null) return;
    final mine = [for (final e in state.entries) if (_local(e)) e];
    if (mine.isEmpty) {
      _parked.remove(id);
    } else {
      _parked[id] = mine;
    }
  }

  /// The chat's entries for [messages]; a message that hasn't changed keeps its entry, so its row
  /// isn't built again.
  List<ChatEntry> _entriesOf(String id, List<ChatMessageView> messages) {
    final prevMessages = state.conversationId == id
        ? <String, MessageEntry>{
            for (final e in state.entries)
              if (e is MessageEntry) e.id: e,
          }
        : const <String, MessageEntry>{};
    return [
        for (final m in messages) ...[
          // A routine's run starts with its instructions; the chat shows that it ran instead.
          if (m.routineName != null)
            NoticeEntry(
              kind: NoticeKind.routine,
              text: m.routineName!,
              at: m.createdAt,
            )
          else if (m.text.isNotEmpty || m.attachments.isNotEmpty || m.ui.isEmpty)
            switch (prevMessages[m.id]) {
              final prev?
                  when prev.role == m.role &&
                      prev.text == m.text &&
                      !prev.streaming &&
                      prev.botId == m.botId &&
                      prev.siblingIndex == m.siblingIndex &&
                      prev.siblingCount == m.siblingCount &&
                      _sameAttachments(prev.attachments, m.attachments) =>
                prev,
              _ => MessageEntry(
                id: m.id,
                role: m.role,
                text: m.text,
                attachments: m.attachments,
                siblingIndex: m.siblingIndex,
                siblingCount: m.siblingCount,
                botId: m.botId,
              ),
            },
          if (m.suggestion case final s?) SuggestionEntry(messageId: m.id, suggestion: s),
          if (m.suggestionList.isNotEmpty) SuggestionListEntry(messageId: m.id, items: m.suggestionList),
          if (m.topic case final t?) TopicLinkEntry(messageId: m.id, topic: t),
          for (final u in m.ui)
            UiEntry(surfaceId: u.surfaceId, messages: u.messages),
        ],
    ];
  }

  static bool _sameAttachments(List<AttachmentRef> a, List<AttachmentRef> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path ||
          a[i].name != b[i].name ||
          a[i].mimeType != b[i].mimeType ||
          a[i].size != b[i].size) {
        return false;
      }
    }
    return true;
  }

  static bool _sameEntries(List<ChatEntry> a, List<ChatEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  void _setIfChanged(ChatState next) {
    if (state.conversationId == next.conversationId &&
        state.loading == next.loading &&
        state.loadFailed == next.loadFailed &&
        state.hasEarlier == next.hasEarlier &&
        state.loadingEarlier == next.loadingEarlier &&
        state.offline == next.offline &&
        state.activeRunId == next.activeRunId &&
        _sameEntries(state.entries, next.entries) &&
        _sameSet(state.answeredUi, next.answeredUi)) {
      return;
    }
    state = next;
  }

  /// Opens a conversation: saved messages show at once (D-112), then the server's replace them.
  /// Offline, the saved ones stay with a note.
  /// A group chat (D-118): several bots answer one message, so after each run the thread reloads
  /// and follows the next bot still working.
  bool group = false;

  /// How many messages a chat opens with, and how many each step up the thread adds (Fix 10).
  static const pageSize = 60;

  /// The window of the thread that is loaded: for which chat, how many messages, the oldest one,
  /// and the thread's very first message once a page up has reached it.
  String? _loadedFor;
  var _loadedCount = 0;
  String? _oldestId;
  String? _firstId;

  /// Loads the page of messages before the oldest one showing (scrolling to the top asks for it).
  Future<void> loadEarlier() async {
    final id = state.conversationId;
    final before = _oldestId;
    if (id == null || before == null || _loadedFor != id || !state.hasEarlier || state.loadingEarlier) return;
    state = state.copyWith(loadingEarlier: true);
    try {
      final older = await _backend.messages(id, limit: pageSize, before: before);
      // The chat changed, or reloaded onto another branch, while this was on its way.
      if (state.conversationId != id || _oldestId != before) return;
      _loadedCount += older.length;
      if (older.isNotEmpty) _oldestId = older.first.id;
      if (older.length < pageSize) _firstId = _oldestId;
      state = state.copyWith(
        entries: [..._entriesOf(id, older), ...state.entries],
        answeredUi: {...state.answeredUi, for (final m in older) ?m.uiActionSurface},
        hasEarlier: older.length >= pageSize,
        loadingEarlier: false,
      );
    } finally {
      if (state.conversationId == id && state.loadingEarlier) state = state.copyWith(loadingEarlier: false);
    }
  }

  /// [around]: a message to have loaded even when it is older than the first page (a search hit).
  Future<void> open(String? conversationId, {String? around}) async {
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    final keepCurrent =
        state.entries.isNotEmpty &&
        (conversationId == null || conversationId == state.conversationId);
    _park();
    if (!keepCurrent) {
      state = const ChatState(loading: true);
    }
    final cache = ref.read(localCacheProvider);
    var id = conversationId;
    var showingCached = keepCurrent;

    Future<void> loadCached(String targetId) async {
      final cached = await cacheRead(cache, 'msgs:$targetId');
      if (cached is List && cached.isNotEmpty) {
        try {
          _setIfChanged(
            _fromMessages(targetId, [
              for (final j in cached)
                ChatMessageView.fromJson(Map<String, dynamic>.from(j as Map)),
            ]),
          );
          showingCached = true;
        } catch (_) {}
      }
    }

    if (id == null) {
      final saved =
          state.conversationId ?? await cacheRead(cache, 'lastconv:$botId');
      if (saved is String && !showingCached) {
        await loadCached(saved);
      }
      try {
        final list = await _backend.conversations(botId);
        id = list.isEmpty ? null : list.first.id;
        unawaited(cacheWrite(cache, 'lastconv:$botId', id));
      } catch (_) {
        if (saved is! String) {
          state = const ChatState(loadFailed: true);
          return;
        }
        id = saved;
      }
    }
    if (id == null) {
      state = const ChatState();
      return;
    }
    final key = 'msgs:$id';
    if (!showingCached || state.conversationId != id) {
      await loadCached(id);
    }
    final List<ChatMessageView> messages;
    // A reload keeps what the person has already scrolled back through.
    final want = _loadedFor == id && _loadedCount > pageSize ? _loadedCount : pageSize;
    try {
      messages = await _backend.messages(id, limit: want, around: around);
    } catch (_) {
      if (showingCached && state.conversationId == id) {
        state = state.copyWith(offline: true);
        return;
      }
      // Nothing to show (no saved copy, as on the web): say so, with a way to try again.
      state = ChatState(conversationId: conversationId == null ? null : id, loadFailed: true);
      return;
    }
    unawaited(
      cacheWrite(cache, key, [
        for (final m
            in messages.length > 100
                ? messages.sublist(messages.length - 100)
                : messages)
          m.toJson(),
      ]),
    );
    if (_loadedFor != id) _firstId = null;
    _loadedFor = id;
    _loadedCount = messages.length;
    _oldestId = messages.firstOrNull?.id;
    _setIfChanged(_fromMessages(id, messages, hasEarlier: messages.length >= want && _oldestId != _firstId));
    _follow(id);
    final active = await _backend.activeRun(id);
    if (active != null) _attach(active);
  }

  /// Edits a sent message and reruns from there; the old branch stays (D-108).
  Future<void> edit(String messageId, String text) async {
    final id = state.conversationId;
    if (id == null || state.running || text.trim().isEmpty) return;
    await _backend.editMessage(id, messageId, text.trim());
    await open(id);
  }

  /// Shows the previous or next edited version of a message, with its own replies.
  Future<void> switchBranch(String messageId, int delta) async {
    final id = state.conversationId;
    if (id == null || state.running) return;
    final siblings = await _backend.messageSiblings(id, messageId);
    final i = siblings.indexOf(messageId);
    final next = i + delta;
    if (i < 0 || next < 0 || next >= siblings.length) return;
    await _backend.switchBranch(id, siblings[next]);
    await open(id);
  }

  Future<void> newChat() async {
    await _sub?.cancel();
    _unfollow();
    _park();
    state = const ChatState();
  }

  /// Messages go out in the order they were sent: each waits until the one before it has started
  /// sending (which may mean waiting for that one's files).
  Future<void> _sendQueue = Future.value();

  /// Sends a message. [uploads], when given, completes once the [attachments] are on the
  /// computer (true) or one of them failed (false): the message shows right away and is delivered
  /// when they are up; if they fail it is taken back and [UploadsFailed] is thrown.
  Future<void> send(String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction, List<String> skills = const [], Future<bool>? uploads}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty && uiAction == null) return;
    // While the bot works, a plain message joins its run (it decides what to do with it); group
    // chats and card answers wait for the run to end.
    if (state.running && (group || uiAction != null)) return;
    final turn = Completer<void>();
    final before = _sendQueue;
    _sendQueue = turn.future;
    final SendMessageResponse sent;
    MessageEntry? optimistic;
    try {
      var conversationId = state.conversationId;
      if (conversationId == null) {
        await before;
        conversationId = state.conversationId ?? (await _backend.createConversation(botId)).id;
        state = state.copyWith(conversationId: conversationId);
        _follow(conversationId);
        ref.invalidate(conversationsProvider(botId));
      }
      final local = MessageEntry(id: 'local-${DateTime.now().microsecondsSinceEpoch}', role: 'user', text: trimmed, attachments: attachments, uploading: uploads != null);
      optimistic = local;
      state = state.copyWith(
        entries: [...state.entries, local],
        lastSent: (text: trimmed, attachments: attachments, skills: skills, uiAction: uiAction),
        answeredUi: uiAction == null ? null : {...state.answeredUi, '${uiAction['surface_id']}'},
      );
      await before;
      if (uploads != null) {
        final ready = await uploads;
        final i = state.entries.indexWhere((x) => x is MessageEntry && x.id == local.id);
        if (!ready) {
          if (i >= 0) state = state.copyWith(entries: [...state.entries]..removeAt(i));
          optimistic = null;
          throw const UploadsFailed();
        }
        if (i >= 0) state = state.copyWith(entries: [...state.entries]..[i] = local.copyWith(uploading: false));
      }
      final sending = _backend.send(conversationId, trimmed, attachments: attachments, uiAction: uiAction, skills: skills);
      // The request is on its way; the next message may go.
      turn.complete();
      sent = await sending;
    } catch (_) {
      // It didn't reach the server: the bubble stays, marked, with what Try Again needs.
      final o = optimistic;
      final i = o == null ? -1 : state.entries.indexWhere((x) => x is MessageEntry && x.id == o.id);
      if (o != null && i >= 0) {
        state = state.copyWith(entries: [...state.entries]..[i] = o.copyWith(failed: true, uploading: false));
        _unsent[o.id] = (skills: skills, uiAction: uiAction);
      }
      rethrow;
    } finally {
      if (!turn.isCompleted) turn.complete();
    }
    // The bubble takes the id the server gave the message, so it can be edited right away (Fix 13)
    // and a reload finds it unchanged. A reload that already brought the message wins.
    final shown = optimistic;
    final at = state.entries.indexWhere((x) => x is MessageEntry && x.id == shown.id);
    if (at >= 0) {
      final known = state.entries.any((x) => x is MessageEntry && x.id == sent.messageId);
      state = state.copyWith(
        entries: known ? ([...state.entries]..removeAt(at)) : ([...state.entries]..[at] = (state.entries[at] as MessageEntry).copyWith(id: sent.messageId)),
      );
    }
    // Joined the run already on screen: keep following it.
    if (sent.joined == true && state.activeRunId == sent.runId) return;
    unawaited(ref.read(runActivitiesProvider).started(sent.runId, ref.read(botProvider(botId))?.name ?? ''));
    _attach(sent.runId);
  }

  /// What failed messages were sent with, so Try Again sends exactly the same thing.
  final _unsent = <String, ({List<String> skills, Map<String, Object?>? uiAction})>{};

  /// Sends a message that didn't reach the server again, in place of its failed bubble.
  Future<void> resend(String id) async {
    final i = state.entries.indexWhere((x) => x is MessageEntry && x.id == id && x.failed);
    if (i < 0) return;
    final m = state.entries[i] as MessageEntry;
    final extra = _unsent.remove(id);
    state = state.copyWith(entries: [...state.entries]..removeAt(i));
    await send(m.text, attachments: m.attachments, skills: extra?.skills ?? const [], uiAction: extra?.uiAction);
  }

  /// Drops a message that didn't reach the server.
  void discardUnsent(String id) {
    _unsent.remove(id);
    state = state.copyWith(entries: [for (final e in state.entries) if (!(e is MessageEntry && e.id == id && e.failed)) e]);
  }

  /// Sends the last message again after its run failed: the words, the files, the skills picked
  /// for it and a card's answer, as they were.
  Future<void> retry() async {
    final last = state.lastSent;
    if (last == null) return;
    await send(last.text, attachments: last.attachments, skills: last.skills, uiAction: last.uiAction);
  }

  Future<void> cancel() async {
    final run = state.activeRunId;
    if (run == null) return;
    try {
      await _backend.cancelRun(run);
    } on RunAlreadyFinished {
      // It had already ended and this chat missed it: let it go and show how it ended, instead
      // of a Stop button that does nothing.
      _sub?.cancel();
      if (state.activeRunId == run) state = state.copyWith(clearActiveRun: true);
      ref.invalidate(botsProvider);
      final conv = state.conversationId;
      if (conv != null) await open(conv);
    }
  }

  void _attach(String runId) {
    _sub?.cancel();
    state = state.copyWith(activeRunId: runId, lastRunId: runId, costUsd: 0, tokens: 0);
    // Group chats (D-118): the run may belong to any member (an @mention, the last speaker).
    if (group) {
      unawaited(
        _backend.run(runId).then((r) {
          if (state.activeRunId == runId) state = state.copyWith(activeBotId: r.botId);
        }).catchError((_) {}),
      );
    }
    _sub = _backend
        .watchRun(runId)
        .listen(
          apply,
          onDone: () {
            if (state.activeRunId == runId) state = state.copyWith(clearActiveRun: true);
            ref.invalidate(botsProvider);
            ref.invalidate(usageTodayProvider);
            final conv = state.conversationId;
            if (group && conv != null) unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () => open(conv)));
            // A message sent too late for that run gets a follow-up run; follow it too.
            if (!group && conv != null) {
              unawaited(
                _backend.activeRun(conv).then((next) {
                  if (next != null && next != runId && state.activeRunId == null && state.conversationId == conv) _attach(next);
                }).catchError((_) {}),
              );
            }
          },
        );
  }

  NoticeEntry _failure(RunFailedEvent event) => NoticeEntry(
    kind: NoticeKind.failed,
    text: event.payload.message,
    refId: event.runId,
    errorCode: event.payload.errorCode,
    at: event.ts,
  );

  /// Applies one run event to the chat (public for tests).
  void apply(RunEventItem e) {
    final entries = [...state.entries];
    int indexWhere(bool Function(ChatEntry) test) => entries.lastIndexWhere(test);

    switch (e) {
      case MessageDeltaItem(:final event):
        final id = event.payload.messageId;
        final i = indexWhere((x) => x is MessageEntry && x.id == id);
        if (i < 0) {
          entries.add(MessageEntry(id: id, role: 'assistant', text: event.payload.text, streaming: true, botId: state.activeBotId));
        } else {
          final m = entries[i] as MessageEntry;
          entries[i] = m.copyWith(text: m.text + event.payload.text);
        }
      case MessageCompletedItem(:final event):
        final id = event.payload.messageId;
        final text = event.payload.content.where((p) => p['type'] == 'text').map((p) => '${p['text'] ?? ''}').join();
        // Media the reply made (a generated image or video) comes with the finished message.
        final files = attachmentsOf(event.payload.content);
        final i = indexWhere((x) => x is MessageEntry && x.id == id);
        if (i < 0) {
          // A reply that is only an interactive UI has no text bubble.
          if (text.isNotEmpty || files.isNotEmpty) entries.add(MessageEntry(id: id, role: 'assistant', text: text, attachments: files, botId: state.activeBotId));
        } else if (text.isEmpty && files.isEmpty) {
          entries.removeAt(i);
        } else {
          entries[i] = (entries[i] as MessageEntry).copyWith(text: text, streaming: false, attachments: files);
        }
        // Scripted replies (the welcome chat) carry their cards only in the finished message.
        for (final u in uiPartsOf(event.payload.content)) {
          if (indexWhere((x) => x is UiEntry && x.surfaceId == u.surfaceId) < 0) {
            entries.add(UiEntry(surfaceId: u.surfaceId, messages: u.messages));
          }
        }
      case UiShownItem(:final event):
        if (indexWhere((x) => x is UiEntry && x.surfaceId == event.payload.surfaceId) < 0) {
          entries.add(UiEntry(surfaceId: event.payload.surfaceId, messages: event.payload.messages));
        }
      case ToolStartedItem(:final event) when state.activeRunId != null && event.payload.tool.isNotEmpty:
        unawaited(ref.read(runActivitiesProvider).step(state.activeRunId!, event.payload.tool));
        entries.add(ToolEntry(callId: event.payload.callId, tool: event.payload.tool, args: event.payload.argsRedacted));
      case ToolStartedItem(:final event):
        entries.add(ToolEntry(callId: event.payload.callId, tool: event.payload.tool, args: event.payload.argsRedacted));
      case ToolOutputItem(:final event):
        final i = indexWhere((x) => x is ToolEntry && x.callId == event.payload.callId);
        if (i >= 0) {
          final t = entries[i] as ToolEntry;
          final out = t.output + event.payload.chunk;
          entries[i] = t.copyWith(output: out.length > 20000 ? out.substring(out.length - 20000) : out);
        }
      case ToolCompletedItem(:final event):
        final i = indexWhere((x) => x is ToolEntry && x.callId == event.payload.callId);
        if (i >= 0) {
          entries[i] = (entries[i] as ToolEntry).copyWith(
            status: ToolStatus.done,
            preview: event.payload.resultPreview,
            durationMs: event.payload.durationMs,
            artifactPath: event.payload.artifactPath,
          );
        }
      case ToolFailedItem(:final event):
        final i = indexWhere((x) => x is ToolEntry && x.callId == event.payload.callId);
        if (i >= 0) {
          entries[i] = (entries[i] as ToolEntry).copyWith(status: ToolStatus.failed, error: event.payload.message);
        }
      case ApprovalRequestedItem(:final event):
        entries.add(
          ApprovalEntry(approvalId: event.payload.approvalId, tool: event.payload.tool, args: event.payload.argsRedacted, risk: event.payload.risk.value),
        );
      case ApprovalResolvedItem(:final event):
        final i = indexWhere((x) => x is ApprovalEntry && x.approvalId == event.payload.approvalId);
        if (i >= 0) {
          final a = entries[i] as ApprovalEntry;
          entries[i] = ApprovalEntry(approvalId: a.approvalId, tool: a.tool, args: a.args, risk: a.risk, decision: event.payload.decision.value);
        }
        ref.invalidate(approvalsProvider);
      case SecretRequestedItem(:final event):
        final p = event.payload;
        entries.add(SecretEntry(requestId: p.requestId, name: p.name, service: p.service, hosts: p.allowedHosts.toList(), reason: p.reason, totp: p.kind.value == 'totp'));
      case DeviceAccessRequestedItem(:final event):
        final p = event.payload;
        final kind = DeviceKind.values.where((k) => k.value == p.kind.value).firstOrNull;
        if (kind != null) entries.add(DeviceAccessEntry(kind: kind, reason: p.reason, botId: p.botId));
      case SecretResolvedItem(:final event):
        final i = indexWhere((x) => x is SecretEntry && x.requestId == event.payload.requestId);
        if (i >= 0) {
          final e = entries[i] as SecretEntry;
          entries[i] = SecretEntry(requestId: e.requestId, name: e.name, service: e.service, hosts: e.hosts, reason: e.reason, totp: e.totp, outcome: event.payload.outcome.value);
        }
      case TakeoverRequestedItem(:final event):
        entries.add(TakeoverEntry(computerId: event.payload.computerId, reason: event.payload.reason));
        ref.invalidate(takeoversProvider);
      case TakeoverResolvedItem(:final event):
        final i = indexWhere((x) => x is TakeoverEntry && x.computerId == event.payload.computerId && x.outcome == null);
        if (i >= 0) {
          final t = entries[i] as TakeoverEntry;
          entries[i] = TakeoverEntry(computerId: t.computerId, reason: t.reason, outcome: event.payload.outcome.value, note: event.payload.note);
        }
        ref.invalidate(takeoversProvider);
      case LeaseChangedItem(:final event):
        entries.add(
          NoticeEntry(
            kind: event.payload.holderType.value == 'user' ? NoticeKind.userControl : NoticeKind.botControl,
            text: '',
            refId: event.payload.computerId,
          ),
        );
      // About you (D-169): a fact about the person went to their own profile; it can be undone.
      case MemoryWrittenItem(:final event) when event.payload.scope == MemoryWrittenEventPayloadScopeEnum.profile:
        entries.add(NoticeEntry(kind: NoticeKind.profileSaved, text: '', refId: event.payload.memoryId));
      case MemoryWrittenItem():
        entries.add(const NoticeEntry(kind: NoticeKind.memory, text: ''));
      case SkillLoadedItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.skill, text: event.payload.name));
      case ModelFallbackItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.modelFallback, text: event.payload.message));
      // Things the person should know, e.g. a bot @mention that wasn't delivered (D-133).
      case NoticeItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.info, text: event.payload.message));
      case CheckpointCreatedItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.checkpoint, text: event.payload.label, refId: event.payload.checkpointId));
      case ComputerStateItem(:final event):
        final last = entries.isEmpty ? null : entries.last;
        final text = event.payload.state.value;
        if (last is NoticeEntry && last.kind == NoticeKind.computer) {
          entries[entries.length - 1] = NoticeEntry(kind: NoticeKind.computer, text: text);
        } else {
          entries.add(NoticeEntry(kind: NoticeKind.computer, text: text));
        }
      case UsageItem(:final event):
        state = state.copyWith(costUsd: event.payload.costUsd.toDouble(), tokens: (event.payload.tokensIn + event.payload.tokensOut).toInt());
        return;
      case RunFailedItem(:final event) when state.activeRunId != null:
        unawaited(ref.read(runActivitiesProvider).ended(state.activeRunId!));
        entries.add(_failure(event));
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunFailedItem(:final event):
        entries.add(_failure(event));
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunCancelledItem():
        entries.add(const NoticeEntry(kind: NoticeKind.cancelled, text: ''));
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunCompletedItem() when state.activeRunId != null:
        unawaited(ref.read(runActivitiesProvider).ended(state.activeRunId!));
        entries.removeWhere((x) => x is MessageEntry && x.streaming);
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunCompletedItem():
        // Partial text from a model step that crashed and was re-run never completes; drop it.
        entries.removeWhere((x) => x is MessageEntry && x.streaming);
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      default:
        return;
    }
    state = state.copyWith(entries: entries);
  }

  void _finishStreaming(List<ChatEntry> entries) {
    for (var i = 0; i < entries.length; i++) {
      final x = entries[i];
      if (x is MessageEntry && x.streaming) entries[i] = x.copyWith(streaming: false);
      if (x is ToolEntry && x.status == ToolStatus.running) entries[i] = x.copyWith(status: ToolStatus.failed);
    }
  }
}

final chatControllerProvider = NotifierProvider.family<ChatController, ChatState, String>(ChatController.new);

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../../core/backend.dart';
import '../../core/local_cache.dart';
import '../../core/providers.dart';
import '../../core/review_prompt.dart';
import '../../core/telemetry.dart';
import '../island/run_tracker.dart';
import '../permissions/permissions_request.dart';

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
    this.runId,
    this.at,
  });
  final String id;

  /// When it was sent, in local time (D-387): the chat's day and pause labels and the message
  /// menu read it. Set to now for a message still sending or a reply still streaming.
  final DateTime? at;

  /// The run that wrote it (D-307): the last reply of a run shows that run's usage line.
  final String? runId;

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
  MessageEntry copyWith({String? id, String? text, bool? streaming, List<AttachmentRef>? attachments, bool? uploading, bool? failed, String? botId}) => MessageEntry(
        id: id ?? this.id,
        role: role,
        text: text ?? this.text,
        streaming: streaming ?? this.streaming,
        attachments: attachments ?? this.attachments,
        siblingIndex: siblingIndex,
        siblingCount: siblingCount,
        botId: botId ?? this.botId,
        uploading: uploading ?? this.uploading,
        failed: failed ?? this.failed,
        runId: runId,
        at: at,
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
    this.botId,
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

  /// In a group chat, the bot whose step this is (D-118).
  final String? botId;

  ToolEntry copyWith({String? output, ToolStatus? status, String? preview, int? durationMs, String? error, String? artifactPath, String? botId}) => ToolEntry(
    callId: callId,
    tool: tool,
    args: args,
    output: output ?? this.output,
    status: status ?? this.status,
    preview: preview ?? this.preview,
    durationMs: durationMs ?? this.durationMs,
    error: error ?? this.error,
    artifactPath: artifactPath ?? this.artifactPath,
    botId: botId ?? this.botId,
  );
}

/// A tool call waiting for someone's decision; [decision] is set once resolved.
class ApprovalEntry extends ChatEntry {
  const ApprovalEntry({required this.approvalId, required this.tool, required this.args, required this.risk, this.decision, this.botId});
  final String approvalId;
  final String tool;
  final Map<String, Object?> args;
  final String risk;
  final String? decision;

  /// In a group chat, the bot that's asking (D-118).
  final String? botId;
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

/// A local MCP server needs its owner to sign in again on that computer (D-363).
class McpSignInEntry extends ChatEntry {
  const McpSignInEntry({required this.integrationId, required this.deviceId, required this.server, required this.label});
  final String integrationId;
  final String deviceId;
  final String server;
  final String label;
}

/// A connected MCP server asking the person something mid-call (MCP elicitation, D-363).
class McpQuestionEntry extends ChatEntry {
  const McpQuestionEntry({required this.questionId, required this.connection, required this.message, required this.schema, this.outcome});
  final String questionId;
  final String connection;
  final String message;
  final Map<String, Object?> schema;

  /// accepted | declined | cancelled | expired once it's over.
  final String? outcome;
}

/// A bot asking for one kind of the person's device data (D-149): a one-tap card.
/// It comes as a run event and is not saved with the messages, so the controller keeps it by
/// [runId] and puts it back under that run's messages whenever the thread reloads.
class DeviceAccessEntry extends ChatEntry {
  const DeviceAccessEntry({required this.kind, required this.reason, required this.botId, this.runId});
  final DeviceKind kind;
  final String reason;
  final String botId;
  final String? runId;
}

/// System permissions a device is missing (D-376): a row and a button per permission. Kept by run
/// like [DeviceAccessEntry].
class PermissionsEntry extends ChatEntry {
  const PermissionsEntry({required this.request, this.runId});
  final PermissionsRequest request;
  final String? runId;
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

/// A call's recap (D-327 §8): how long it was and what was started on it, with links to the runs.
class CallRecapEntry extends ChatEntry {
  const CallRecapEntry({required this.messageId, required this.call});
  final String messageId;
  final MessageCall call;
}

/// A gallery card in a bot's reply (D-315): an item it suggests, or a skill it drafted.
class GalleryCardEntry extends ChatEntry {
  const GalleryCardEntry({required this.messageId, required this.part});
  final String messageId;
  final GalleryChatPart part;
}

/// An interactive UI the bot showed (D-086), rendered from A2UI messages.
class UiEntry extends ChatEntry {
  const UiEntry({required this.surfaceId, required this.messages});
  final String surfaceId;
  final List<Object?> messages;
}

enum NoticeKind { memory, profileSaved, skill, checkpoint, computer, failed, cancelled, userControl, botControl, modelFallback, info, routine }

class NoticeEntry extends ChatEntry {
  const NoticeEntry({required this.kind, required this.text, this.refId, this.errorCode, this.at, this.botId});
  final NoticeKind kind;
  final String text;

  /// The checkpoint (checkpoint notices), the run (failures) or the memory ("Remembered something").
  final String? refId;

  /// The bot whose memory it went to, in a group chat (D-118); otherwise the chat's bot.
  final String? botId;
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
    this.sending = false,
    this.rerunId,
    this.reactions = const {},
    this.rechecking = false,
  });

  /// The bot's finished reply was taken back for a second look (a check before it reaches you):
  /// the working line says so until the bot does something else, instead of the reply vanishing.
  final bool rechecking;

  /// Reactions by message id (D-331); messages without any are left out.
  final Map<String, List<ReactionGroup>> reactions;

  /// Your last message, when its run failed before it could start (found on opening the chat, so
  /// [lastSent] doesn't know it). Try again reruns it as it was sent, with anything the app
  /// doesn't show (such as a suggestion's action).
  final String? rerunId;

  /// A message is on its way and its run hasn't started yet: the chat already shows the bot
  /// thinking, so a slow send doesn't look like nothing happened.
  final bool sending;

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
  bool get canRetry => lastSent != null || rerunId != null;

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
    bool? sending,
    String? rerunId,
    Map<String, List<ReactionGroup>>? reactions,
    bool? rechecking,
  }) => ChatState(
    rechecking: clearActiveRun ? false : (rechecking ?? this.rechecking),
    reactions: reactions ?? this.reactions,
    rerunId: rerunId ?? this.rerunId,
    sending: sending ?? this.sending,
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

  /// The newest event this chat applied for the run it follows. The watchdog compares it with the
  /// server's, so a chat that stopped hearing its run (a dropped stream, a reload that failed
  /// half-way) catches up instead of saying Thinking forever.
  int _appliedSeq = 0;
  Timer? _watchdog;

  /// Watchdog ticks since the last event (or the last check that found the chat up to date).
  int _silentTicks = 0;
  bool _checkingRun = false;
  int _quietChecks = 0;
  bool _opening = false;
  static const _watchdogTick = Duration(seconds: 10);

  /// Ticks of silence before the server is asked: 20 s, then 40 s, 80 s and at most 160 s while
  /// the run is only quiet (a long step, waiting on a person).
  static const _stallTicks = 2;

  /// The open conversation's activity from other devices and triggers (D-224).
  StreamSubscription<ConversationActivity>? _watch;
  String? _watching;

  /// Allow cards by the run that asked (D-328). Run events are not part of the saved messages, so
  /// without this a reload (the thread changed, the chat reopened) dropped the card.
  final _deviceCards = <String, List<ChatEntry>>{};

  /// Runs whose events were already read for Allow cards after a reload.
  final _deviceCardsRead = <String>{};

  /// [entries] with every kept Allow card after the last entry of the run that asked; a card of
  /// the run still going with nothing saved yet goes last.
  List<ChatEntry> _placeDeviceCards(List<ChatEntry> entries) {
    final out = [for (final e in entries) if (e is! DeviceAccessEntry && e is! PermissionsEntry) e];
    if (_deviceCards.isEmpty) return out;
    for (final MapEntry(key: run, value: cards) in _deviceCards.entries) {
      final at = out.lastIndexWhere((e) => e is MessageEntry && e.runId == run);
      if (at >= 0) {
        out.insertAll(at + 1, cards);
      } else if (run == state.activeRunId) {
        out.addAll(cards);
      }
    }
    return out;
  }

  /// After a reload: the latest run's Allow cards, read from its events when this controller
  /// never saw them live (the app was closed, another device started it).
  Future<void> _recoverDeviceCards(String id, List<ChatMessageView> messages) async {
    final run = messages.reversed.map((m) => m.runId).nonNulls.firstOrNull;
    if (run == null || _deviceCards.containsKey(run) || !_deviceCardsRead.add(run)) return;
    final List<RunEventItem> events;
    try {
      events = await _backend.runEvents(run);
    } catch (_) {
      _deviceCardsRead.remove(run);
      return;
    }
    for (final e in events) {
      final card = _deviceCardOf(e);
      if (card != null) _keepDeviceCard(card);
    }
    if (!_deviceCards.containsKey(run) || state.conversationId != id) return;
    state = state.copyWith(entries: _placeDeviceCards(state.entries));
  }

  static ChatEntry? _deviceCardOf(RunEventItem e) {
    // System permissions on a device (D-376): their own card, kept and recovered the same way.
    if (e case DevicePermissionNeededItem(:final event)) {
      final p = event.payload;
      if (event.runId.isEmpty || p.permissions.isEmpty) return null;
      return PermissionsEntry(
        runId: event.runId,
        request: PermissionsRequest(deviceRef: p.deviceRef, deviceName: p.deviceName, platform: p.platform, permissions: p.permissions.toList(), reason: p.reason, botId: p.botId),
      );
    }
    final (String run, String kindValue, String reason, String bot) = switch (e) {
      DeviceAccessRequestedItem(:final event) => (event.runId, event.payload.kind.value, event.payload.reason, event.payload.botId),
      // Casama for Chrome's kinds come as their own event (D-323): the same one-tap card.
      DeviceBrowserAccessRequestedItem(:final event) => (event.runId, event.payload.kind.value, event.payload.reason, event.payload.botId),
      _ => ('', '', '', ''),
    };
    final kind = DeviceKind.values.where((k) => k.value == kindValue).firstOrNull;
    if (run.isEmpty || kind == null) return null;
    return DeviceAccessEntry(kind: kind, reason: reason, botId: bot, runId: run);
  }

  /// Keeps [card] for its run; false when that run already has a card for the kind (a replay).
  bool _keepDeviceCard(ChatEntry card) {
    final run = switch (card) {
      DeviceAccessEntry(:final runId) || PermissionsEntry(:final runId) => runId,
      _ => null,
    };
    if (run == null) return false;
    final cards = _deviceCards.putIfAbsent(run, () => []);
    final dup = switch (card) {
      DeviceAccessEntry(:final kind, :final botId) => cards.any((c) => c is DeviceAccessEntry && c.kind == kind && c.botId == botId),
      PermissionsEntry(:final request) => cards.any(
        (c) => c is PermissionsEntry && c.request.deviceRef == request.deviceRef && c.request.botId == request.botId && c.request.permissions.toSet().containsAll(request.permissions),
      ),
      _ => true,
    };
    if (dup) return false;
    cards.add(card);
    return true;
  }

  Backend get _backend => ref.read(backendProvider);

  /// The island's run tracker (D-324): this chat reports its run's steps to it, so the tracker
  /// reads no events for a run that is open here. Kept, since ref can't be read while disposing.
  RunTracker? _tracker;

  /// The run this chat last followed, for handing it back to the tracker when the chat closes
  /// (state can't be read while disposing). The tracker ignores it if it has ended.
  String? _followedRun;
  RunTracker get _runs {
    final known = _tracker;
    if (known != null) return known;
    final tracker = ref.read(runTrackerProvider.notifier);
    _tracker = tracker;
    return tracker;
  }

  @override
  ChatState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _watch?.cancel();
      _watchdog?.cancel();
      final run = _followedRun;
      final tracker = _tracker;
      // No provider may change while this one is disposed: hand the run back right after.
      if (run != null && tracker != null) scheduleMicrotask(() => tracker.chatReleased(run));
    });
    return const ChatState();
  }

  /// Follows runs that start in [id] from anywhere else (another phone, a routine, a group
  /// @mention): the thread reloads and the new run streams in, as if it had started here.
  void _follow(String id) {
    if (_watching == id) return;
    _watch?.cancel();
    _watching = id;
    _watch = _backend.watchConversation(id).listen((activity) async {
      // Someone's reaction (D-331): only that message's reactions are read again.
      if (activity.reactionMessageId case final message?) {
        if (state.conversationId == id) await _loadReactions(id, [message]);
        return;
      }
      // A person's message (D-413): from this device it is on screen already; from another one
      // it is put in, also while the bot works (it joined that run, so nothing else will say).
      if (activity.messageId case final message?) {
        if (state.conversationId == id && !_shows(message)) await _catchUp(id);
        return;
      }
      final runId = activity.runId;
      // A message sent here attaches its own run; a moment's wait keeps this from racing it.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (state.conversationId != id) return;
      // A run is on screen: the thread isn't reloaded under it (its steps would go), but what
      // was added meanwhile is put in. The new run is followed when this one ends.
      if (state.running) {
        if (runId != null && runId != state.activeRunId) await _catchUp(id);
        return;
      }
      // Already following it, or a reconnect while nothing changed: open() checks anyway.
      if (runId != null && state.lastRunId == runId) return;
      // A background refresh: when the server is briefly unreachable, the next change tries again
      // (an error here had nothing to catch it).
      try {
        await open(id);
      } catch (e) {
        debugPrint('chat refresh failed: $e');
      }
    });
  }

  void _unfollow() {
    _watch?.cancel();
    _watch = null;
    _watching = null;
  }

  /// Whether the message with this id is on screen, or is one this device is sending right now.
  bool _shows(String messageId) =>
      _sending.containsValue(messageId) || state.entries.any((e) => e is MessageEntry && e.id == messageId);

  bool _catchingUp = false;
  bool _catchUpAgain = false;

  /// Puts in the messages of the thread that this screen doesn't show yet, without reloading it
  /// (D-413): a message from the person's other device, a routine's or another run's reply. A
  /// reload would do it too, but it drops the steps of the run on screen. Each goes after the
  /// message before it in the thread. The words of the run being followed come on its own stream.
  Future<void> _catchUp(String id) async {
    if (_catchingUp) {
      _catchUpAgain = true;
      return;
    }
    _catchingUp = true;
    try {
      do {
        _catchUpAgain = false;
        final List<ChatMessageView> messages;
        try {
          messages = await _backend.messages(id, limit: pageSize);
        } catch (e) {
          // A background read: the next change, or the next open, tries again.
          debugPrint('chat catch-up failed: $e');
          return;
        }
        if (state.conversationId != id) return;
        final entries = [...state.entries];
        var changed = false;
        String? previous;
        for (final m in messages) {
          if (entries.any((e) => e is MessageEntry && e.id == m.id)) {
            previous = m.id;
            continue;
          }
          if (_sending.containsValue(m.id)) continue;
          if (m.role != 'user' && m.runId != null && m.runId == state.activeRunId) continue;
          final built = _entriesOf(id, [m]);
          // Only messages that show as a bubble: the rest have no id on screen to tell them by.
          if (!built.any((e) => e is MessageEntry && e.id == m.id)) continue;
          final after = previous == null ? -1 : entries.lastIndexWhere((e) => e is MessageEntry && e.id == previous);
          // Nothing before it is on screen: it is older than what is loaded, or the first message.
          if (after < 0 && entries.isNotEmpty) {
            if (previous != null) continue;
            entries.insertAll(0, built);
          } else {
            entries.insertAll(after + 1, built);
          }
          previous = m.id;
          changed = true;
        }
        if (changed) {
          state = state.copyWith(entries: entries);
          unawaited(_loadReactions(id, [for (final m in messages) m.id]));
        }
      } while (_catchUpAgain && state.conversationId == id);
    } finally {
      _catchingUp = false;
    }
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
      entries: [
        ..._placeDeviceCards([..._entriesOf(id, messages), ..._keptFailure(id, messages)]),
        // A message on its way that this load already brought shows once, as the saved one.
        for (final e in _notDelivered(id))
          if (!(e is MessageEntry && messages.any((m) => m.id == _sending[e.id]))) e,
      ],
      answeredUi: {for (final m in messages) ?m.uiActionSurface},
      reactions: state.conversationId == id ? state.reactions : const {},
    );
  }

  static final _savedMessage = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  /// Reads the reactions on [messageIds] (D-331) and replaces what the chat shows for them.
  Future<void> _loadReactions(String id, Iterable<String> messageIds) async {
    final ids = [for (final m in messageIds) if (_savedMessage.hasMatch(m)) m];
    if (ids.isEmpty) return;
    final Map<String, List<ReactionGroup>> got;
    try {
      got = await _backend.reactions(id, ids);
    } catch (e) {
      // A background read: the next change or reload tries again.
      debugPrint('reactions failed: $e');
      return;
    }
    if (state.conversationId != id) return;
    final next = {...state.reactions};
    for (final m in ids) {
      final g = got[m];
      if (g == null || g.isEmpty) {
        next.remove(m);
      } else {
        next[m] = g;
      }
    }
    state = state.copyWith(reactions: next);
  }

  void _putReactions(String messageId, List<ReactionGroup> groups) {
    final next = {...state.reactions};
    if (groups.isEmpty) {
      next.remove(messageId);
    } else {
      next[messageId] = groups;
    }
    state = state.copyWith(reactions: next);
  }

  /// Your reaction to a message (D-331): [emoji] sets or replaces it, null takes it back. Shown at
  /// once; put back as it was when the server refuses.
  Future<void> react(String messageId, String? emoji) async {
    final id = state.conversationId;
    if (id == null || !_savedMessage.hasMatch(messageId)) return;
    final before = state.reactions[messageId] ?? const <ReactionGroup>[];
    if (ReactionGroup.mineOf(before) == emoji) return;
    _putReactions(messageId, ReactionGroup.withMine(before, emoji, me: _backend.userId));
    try {
      final after = emoji == null ? await _backend.removeReaction(id, messageId) : await _backend.setReaction(id, messageId, emoji);
      if (state.conversationId == id) _putReactions(messageId, after);
    } catch (_) {
      if (state.conversationId == id) _putReactions(messageId, before);
      rethrow;
    }
  }

  /// A run that just failed (a limit reached) leaves its notice under your message; a reload
  /// that still ends on that message keeps it, instead of dropping it and bringing it back.
  List<ChatEntry> _keptFailure(String id, List<ChatMessageView> messages) {
    if (state.conversationId != id || messages.lastOrNull?.role != 'user') return const [];
    final last = state.entries.where((e) => !_local(e)).lastOrNull;
    return last is NoticeEntry && last.kind == NoticeKind.failed ? [last] : const [];
  }

  /// Messages the server doesn't have yet, so a reload can't bring them back (Fix 11): ones that
  /// failed to send (kept for Try Again), ones still waiting for their files, and ones on their
  /// way (a reload that came before the server had the message used to drop its bubble).
  bool _local(ChatEntry e) => e is MessageEntry && (e.failed || e.uploading || _sending.containsKey(e.id));

  /// Messages being sent right now: the bubble's id, and the id the server will give the message
  /// (the send's idempotency key). A reload that already brings the message replaces the bubble.
  final _sending = <String, String>{};

  List<ChatEntry> _notDelivered(String id) =>
      state.conversationId == id ? [for (final e in state.entries) if (_local(e)) e] : (_parked[id] ?? const []);

  /// Changes a message this device is still sending ([change] returning null removes it), in the
  /// chat on screen or, once the person has moved to another chat, among the ones kept for when
  /// they come back. Returns whether it was found.
  bool _updateLocal(String conversationId, String localId, MessageEntry? Function(MessageEntry) change) {
    bool mine(ChatEntry x) => x is MessageEntry && x.id == localId;
    if (state.conversationId == conversationId) {
      final i = state.entries.indexWhere(mine);
      if (i < 0) return false;
      final next = change(state.entries[i] as MessageEntry);
      state = state.copyWith(entries: next == null ? ([...state.entries]..removeAt(i)) : ([...state.entries]..[i] = next));
      return true;
    }
    final parked = _parked[conversationId];
    final i = parked?.indexWhere(mine) ?? -1;
    if (parked == null || i < 0) return false;
    final next = change(parked[i] as MessageEntry);
    final list = next == null ? ([...parked]..removeAt(i)) : ([...parked]..[i] = next);
    if (list.isEmpty) {
      _parked.remove(conversationId);
    } else {
      _parked[conversationId] = list;
    }
    return true;
  }

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
          // A message that is only a card (a suggestion, a topic's link) gets no text entry: it
          // would show as an empty bubble over the card.
          // A call's recap is a card; its text is for apps without the card.
          else if ((m.call == null && m.text.trim().isNotEmpty) ||
              m.attachments.isNotEmpty ||
              (m.ui.isEmpty && m.suggestion == null && m.suggestionList.isEmpty && m.topic == null && m.gallery.isEmpty && m.call == null))
            switch (prevMessages[m.id]) {
              final prev?
                  when prev.role == m.role &&
                      prev.text == m.text &&
                      !prev.streaming &&
                      prev.botId == m.botId &&
                      prev.siblingIndex == m.siblingIndex &&
                      prev.siblingCount == m.siblingCount &&
                      prev.runId == m.runId &&
                      prev.at == m.createdAt.toLocal() &&
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
                runId: m.runId,
                at: m.createdAt.toLocal(),
              ),
            },
          if (m.suggestion case final s?) SuggestionEntry(messageId: m.id, suggestion: s),
          if (m.suggestionList.isNotEmpty) SuggestionListEntry(messageId: m.id, items: m.suggestionList),
          if (m.topic case final t?) TopicLinkEntry(messageId: m.id, topic: t),
          if (m.call case final c?) CallRecapEntry(messageId: m.id, call: c),
          for (final u in m.ui)
            UiEntry(surfaceId: u.surfaceId, messages: u.messages),
          for (final g in m.gallery) GalleryCardEntry(messageId: m.id, part: g),
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
      unawaited(_loadReactions(id, [for (final m in older) m.id]));
    } finally {
      if (state.conversationId == id && state.loadingEarlier) state = state.copyWith(loadingEarlier: false);
    }
  }

  /// Every open of a chat gets a number. An open that is no longer the newest stops where it is:
  /// tapping one topic and then another used to let the slower first load put its thread, and
  /// its working run, over the chat opened after it (D-413).
  int _openGen = 0;

  /// The open in flight, for a message sent while its chat is still loading.
  Future<void>? _openDone;

  /// [around]: a message to have loaded even when it is older than the first page (a search hit).
  Future<void> open(String? conversationId, {String? around}) {
    final gen = ++_openGen;
    _opening = true;
    final done = () async {
      try {
        await _open(gen, conversationId, around: around);
      } finally {
        if (gen == _openGen) _opening = false;
      }
    }();
    _openDone = done;
    return done;
  }

  Future<void> _open(int gen, String? conversationId, {String? around}) async {
    bool stale() => gen != _openGen;
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    _releaseRun();
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
      if (stale()) return;
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
      if (stale()) return;
      if (saved is String && !showingCached) {
        await loadCached(saved);
        if (stale()) return;
      }
      try {
        final list = await _backend.conversations(botId);
        if (stale()) return;
        id = list.isEmpty ? null : list.first.id;
        unawaited(cacheWrite(cache, 'lastconv:$botId', id));
      } catch (_) {
        if (stale()) return;
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
      if (stale()) return;
    }
    final List<ChatMessageView> messages;
    // A reload keeps what the person has already scrolled back through.
    final want = _loadedFor == id && _loadedCount > pageSize ? _loadedCount : pageSize;
    try {
      messages = await _backend.messages(id, limit: want, around: around);
    } catch (_) {
      if (stale()) return;
      if (showingCached && state.conversationId == id) {
        state = state.copyWith(offline: true);
        return;
      }
      // Nothing to show (no saved copy, as on the web): say so, with a way to try again.
      state = ChatState(conversationId: conversationId == null ? null : id, loadFailed: true);
      return;
    }
    if (stale()) return;
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
    // The thread now shows saved messages only: a run followed from here starts from its first event.
    _appliedSeq = 0;
    _follow(id);
    unawaited(_loadReactions(id, [for (final m in messages) m.id]));
    unawaited(_recoverDeviceCards(id, messages));
    final active = await _backend.activeRun(id);
    // Another chat was opened meanwhile: this one's run must not start streaming into it.
    if (stale()) return;
    if (active != null) {
      _attach(active);
    } else {
      await _showFailedStart(id, messages);
    }
  }

  /// A chat whose last word is yours and whose run failed (a limit reached, the bot archived) says
  /// why when it opens, with the fix and Try again, instead of a message with no reply.
  Future<void> _showFailedStart(String id, List<ChatMessageView> messages) async {
    final last = messages.lastOrNull;
    if (last == null || last.role != 'user') return;
    final Run run;
    try {
      // Group chats (D-118): the message has no run id; the run it started points back at it.
      final runId = last.runId ?? (group ? await _backend.runForMessage(last.id) : null);
      if (runId == null) return;
      run = await _backend.run(runId);
    } catch (_) {
      return;
    }
    final error = run.error;
    if (run.status != RunStatus.failed || error == null) return;
    if (state.conversationId != id || state.running) return;
    if (state.entries.any((e) => e is NoticeEntry && e.kind == NoticeKind.failed && e.refId == run.id)) return;
    state = state.copyWith(
      entries: [
        ...state.entries,
        NoticeEntry(kind: NoticeKind.failed, text: error.message, refId: run.id, errorCode: error.code, at: run.endedAt),
      ],
      rerunId: last.id,
    );
  }

  /// Edits a sent message and reruns from there; the old branch stays (D-108).
  Future<void> edit(String messageId, String text) async {
    final id = state.conversationId;
    if (id == null || state.running || text.trim().isEmpty) return;
    await _backend.editMessage(id, messageId, text.trim());
    await open(id);
  }

  /// The message of yours that [replyId] answered, when it can be asked again (sent, with text).
  MessageEntry? questionFor(String replyId) {
    final entries = state.entries;
    final i = entries.indexWhere((e) => e is MessageEntry && e.id == replyId);
    for (var j = i - 1; j >= 0; j--) {
      final e = entries[j];
      if (e is MessageEntry && e.role == 'user') {
        return e.id.startsWith('local-') || e.failed || e.text.trim().isEmpty ? null : e;
      }
    }
    return null;
  }

  /// Asks for a reply again (Add 11): the message it answered reruns as a new version, so the
  /// old reply stays one arrow away (the same fork an edit makes, D-108).
  Future<void> regenerate(String replyId) async {
    final id = state.conversationId;
    final asked = questionFor(replyId);
    if (id == null || state.running || asked == null) return;
    await _backend.editMessage(id, asked.id, asked.text.trim());
    await open(id);
  }

  /// Deletes one message (Add 11) and reloads the thread.
  Future<void> deleteMessage(String messageId) async {
    final id = state.conversationId;
    if (id == null || state.running) return;
    await _backend.deleteMessage(id, messageId);
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
    // A chat still loading must not land on top of the new one.
    _openGen++;
    _opening = false;
    await _sub?.cancel();
    _releaseRun();
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
  ///
  /// A send that finds no server (a restart, a dropped connection) tries again by itself for
  /// about 30 s ([sendRetryDelays]) while the bubble shows it sending; every try carries the same
  /// [idempotencyKey], so the server posts the message once. Try Again passes the key back.
  Future<void> send(String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction, List<String> skills = const [], Future<bool>? uploads, String? idempotencyKey}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty && uiAction == null) return;
    // While the bot works, a plain message joins its run (it decides what to do with it); group
    // chats and card answers wait for the run to end.
    if (state.running && (group || uiAction != null)) return;
    final key = idempotencyKey ?? newIdempotencyKey();
    final turn = Completer<void>();
    final before = _sendQueue;
    _sendQueue = turn.future;
    final SendMessageResponse sent;
    MessageEntry? optimistic;
    // The chat this message belongs to. The person may open another one before the send comes
    // back; what the send does afterwards goes to this chat, never to the one on screen (D-413).
    String? to;
    try {
      // Sent while the chat is still loading (no saved copy, as on the web): wait for it, instead
      // of starting a new conversation because no id is known yet.
      if (state.conversationId == null && _opening) {
        try {
          await _openDone;
        } catch (_) {}
      }
      var conversationId = state.conversationId;
      if (conversationId == null) {
        final gen = _openGen;
        await before;
        conversationId = state.conversationId ?? (await _backend.createConversation(botId)).id;
        if (gen == _openGen && state.conversationId == null) {
          state = state.copyWith(conversationId: conversationId);
          _follow(conversationId);
        }
        ref.invalidate(conversationsProvider(botId));
      }
      to = conversationId;
      final local = MessageEntry(id: 'local-${DateTime.now().microsecondsSinceEpoch}', role: 'user', text: trimmed, attachments: attachments, uploading: uploads != null, at: DateTime.now());
      optimistic = local;
      _sending[local.id] = key;
      if (state.conversationId == to) {
        state = state.copyWith(
          entries: [...state.entries, local],
          lastSent: (text: trimmed, attachments: attachments, skills: skills, uiAction: uiAction),
          sending: true,
          answeredUi: uiAction == null ? null : {...state.answeredUi, '${uiAction['surface_id']}'},
        );
      }
      await before;
      if (uploads != null) {
        final ready = await uploads;
        if (!ready) {
          _sending.remove(local.id);
          _updateLocal(to, local.id, (_) => null);
          optimistic = null;
          throw const UploadsFailed();
        }
        _updateLocal(to, local.id, (m) => m.copyWith(uploading: false));
      }
      final target = to;
      sent = await _deliver(
        () => _backend.send(target, trimmed, attachments: attachments, uiAction: uiAction, skills: skills, idempotencyKey: key),
        // The request is on its way; the next message may go.
        onWay: () {
          if (!turn.isCompleted) turn.complete();
        },
      );
    } catch (_) {
      // It didn't reach the server: the bubble stays, marked, with what Try Again needs. In a chat
      // the person has left meanwhile, it is there when they come back.
      final o = optimistic;
      final chat = to;
      if (o != null && chat != null) {
        _sending.remove(o.id);
        if (_updateLocal(chat, o.id, (m) => m.copyWith(failed: true, uploading: false))) {
          _unsent[o.id] = (skills: skills, uiAction: uiAction, key: key);
        }
      }
      if (chat == null || state.conversationId == chat) state = state.copyWith(sending: false);
      rethrow;
    } finally {
      if (!turn.isCompleted) turn.complete();
    }
    final shown = optimistic;
    _sending.remove(shown.id);
    if (state.conversationId != to) {
      // Another chat is on screen now. The message is sent; its run belongs to the chat it was
      // sent in, so it isn't followed here (it used to stream into whatever chat was open, with
      // a Stop button that stopped the other chat's run). The island and notifications follow it.
      _updateLocal(to, shown.id, (_) => null);
      _runs.startedHere(sent.runId, botId: botId, conversationId: to);
      return;
    }
    // The bubble takes the id the server gave the message, so it can be edited right away (Fix 13)
    // and a reload finds it unchanged. A reload that already brought the message wins.
    final at = state.entries.indexWhere((x) => x is MessageEntry && x.id == shown.id);
    if (at >= 0) {
      final known = state.entries.any((x) => x is MessageEntry && x.id == sent.messageId);
      state = state.copyWith(
        entries: known ? ([...state.entries]..removeAt(at)) : ([...state.entries]..[at] = (state.entries[at] as MessageEntry).copyWith(id: sent.messageId)),
      );
    }
    state = state.copyWith(sending: false);
    // The run already on screen (the message joined it, or a reload attached it first): keep
    // following it. Attaching again replayed its steps onto the ones already shown.
    if (state.activeRunId == sent.runId) {
      _runs.chatStarted(sent.runId, botId: botId, conversationId: to, sentHere: true);
      return;
    }
    _attach(sent.runId, sentHere: true);
  }

  /// What failed messages were sent with, so Try Again sends exactly the same thing, with the
  /// same idempotency key (an answer that was lost may mean the server has it already).
  final _unsent = <String, ({List<String> skills, Map<String, Object?>? uiAction, String key})>{};

  /// Runs [attempt] until it reaches the server: a connection failure tries again after each of
  /// [sendRetryDelays]; any other error, or the last failure, is thrown. [onWay] runs once the
  /// first request is out.
  Future<SendMessageResponse> _deliver(Future<SendMessageResponse> Function() attempt, {required void Function() onWay}) async {
    for (var tries = 0; ; tries++) {
      final sending = attempt();
      onWay();
      try {
        return await sending;
      } catch (e) {
        if (tries >= sendRetryDelays.length || !isConnectionFailure(e) || !ref.mounted) rethrow;
        await Future<void>.delayed(sendRetryDelays[tries]);
        if (!ref.mounted) rethrow;
      }
    }
  }

  /// Sends a message that didn't reach the server again, in place of its failed bubble.
  Future<void> resend(String id) async {
    final i = state.entries.indexWhere((x) => x is MessageEntry && x.id == id && x.failed);
    if (i < 0) return;
    final m = state.entries[i] as MessageEntry;
    final extra = _unsent.remove(id);
    state = state.copyWith(entries: [...state.entries]..removeAt(i));
    await send(m.text, attachments: m.attachments, skills: extra?.skills ?? const [], uiAction: extra?.uiAction, idempotencyKey: extra?.key);
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
    if (last != null) {
      await send(last.text, attachments: last.attachments, skills: last.skills, uiAction: last.uiAction);
      return;
    }
    final rerun = state.rerunId;
    final sent = state.entries.whereType<MessageEntry>().where((e) => e.id == rerun).firstOrNull;
    if (rerun == null || sent == null) return;
    // The same words again: the server keeps the message's other parts and starts a new run.
    await edit(rerun, sent.text);
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
      _releaseRun();
      ref.invalidate(botsProvider);
      final conv = state.conversationId;
      if (conv != null) await open(conv);
    }
  }

  /// This chat stopped following its run (another conversation, New chat, a lost stream): the
  /// tracker reads that run's steps itself from now on. Ended runs ignore it.
  void _releaseRun() {
    final run = _followedRun;
    _followedRun = null;
    if (run != null) _runs.chatReleased(run);
  }

  /// Follows [runId]'s events. [sentHere]: this chat just started it.
  /// [afterSeq]: picks up after the events already on screen (the watchdog reconnecting).
  void _attach(String runId, {bool sentHere = false, int afterSeq = 0}) {
    _sub?.cancel();
    if (_followedRun != runId) _releaseRun();
    final fresh = afterSeq == 0;
    state = state.copyWith(activeRunId: runId, lastRunId: runId, costUsd: fresh ? 0 : null, tokens: fresh ? 0 : null);
    _appliedSeq = afterSeq;
    _silentTicks = 0;
    _quietChecks = 0;
    _startWatchdog(runId);
    _followedRun = runId;
    _runs.chatStarted(runId, botId: botId, conversationId: state.conversationId, sentHere: sentHere);
    // Group chats (D-118): the run may belong to any member (an @mention, the last speaker).
    if (group) {
      unawaited(
        _backend.run(runId).then((r) {
          if (state.activeRunId != runId) return;
          _runs.chatStarted(runId, botId: r.botId, conversationId: state.conversationId);
          // Words that streamed in before we knew the bot go under its name too, not "Assistant".
          state = state.copyWith(
            activeBotId: r.botId,
            entries: [
              for (final e in state.entries)
                if (e is MessageEntry && e.role == 'assistant' && e.runId == runId && e.botId == null)
                  e.copyWith(botId: r.botId)
                // Steps and approvals that arrived before we knew the bot go under its name too.
                else if (e is ToolEntry && e.botId == null)
                  e.copyWith(botId: r.botId)
                else if (e is ApprovalEntry && e.botId == null)
                  ApprovalEntry(approvalId: e.approvalId, tool: e.tool, args: e.args, risk: e.risk, decision: e.decision, botId: r.botId)
                else
                  e,
            ],
          );
        }).catchError((_) {}),
      );
    }
    _sub = _backend
        .watchRun(runId, afterSeq: afterSeq)
        .listen(
          (e) {
            if (e.seq > _appliedSeq) _appliedSeq = e.seq;
            _silentTicks = 0;
            _quietChecks = 0;
            try {
              apply(e);
            } catch (error, stack) {
              unawaited(Telemetry.captureException(error, stack, context: {
                'run_event': {'type': e.type, 'seq': '${e.seq}'},
              }));
            }
          },
          onDone: () {
            // The stream closed and no ending was shown (the server ended the run without
            // saying how, or the run is gone): nothing more will come, so nothing stays "Thinking".
            final unsaid = state.activeRunId == runId;
            if (unsaid) {
              final entries = [...state.entries]..removeWhere((x) => x is MessageEntry && x.streaming && x.text.trim().isEmpty);
              _finishStreaming(entries);
              state = state.copyWith(entries: entries, clearActiveRun: true);
            }
            // Ended runs already told the tracker; one this chat lost track of is its to follow.
            if (_followedRun == runId) _releaseRun();
            ref.invalidate(botsProvider);
            ref.invalidate(usageTodayProvider);
            // Settings shows this month's spend; without this it keeps the figure from app start.
            ref.invalidate(usageMonthProvider);
            final conv = state.conversationId;
            if (group && conv != null) unawaited(Future<void>.delayed(const Duration(milliseconds: 300), () => open(conv)));
            if (!group && conv != null) {
              // No ending shown: the saved thread says how it ended (a failure gets its notice).
              if (unsaid) {
                unawaited(open(conv).catchError((Object e) => debugPrint('chat refresh failed: $e')));
                return;
              }
              // A message sent too late for that run gets a follow-up run; follow it too.
              unawaited(
                _backend.activeRun(conv).then((next) {
                  if (next != null && next != runId && state.activeRunId == null && state.conversationId == conv) _attach(next);
                }).catchError((_) {}),
              );
              // What was added to the chat while the run was on screen (D-413).
              unawaited(_catchUp(conv));
            }
          },
        );
  }

  void _startWatchdog(String runId) {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogTick, (_) => unawaited(_checkRun(runId)));
  }

  /// The safety net under the live stream: while a run is on screen and nothing has come in for a
  /// while, ask the server how far the run is. Behind it (or nothing follows the run any more):
  /// follow it again from the last event shown. Whatever stopped the stream, the chat catches up.
  Future<void> _checkRun(String runId) async {
    if (state.activeRunId != runId) {
      _watchdog?.cancel();
      _watchdog = null;
      return;
    }
    if (_opening || _checkingRun) return;
    final lost = _sub == null;
    _silentTicks++;
    // A run that is just quiet is asked less and less often.
    if (!lost && _silentTicks < _stallTicks * (1 << _quietChecks.clamp(0, 3))) return;
    _checkingRun = true;
    try {
      final run = await _backend.run(runId);
      if (state.activeRunId != runId || _opening) return;
      if (!lost && run.lastSeq <= _appliedSeq) {
        _quietChecks++;
        _silentTicks = 0;
        return;
      }
      unawaited(Telemetry.captureException(StateError('chat stopped hearing its run'), null, warning: true, context: {
        'run_stream': {'stage': lost ? 'unfollowed' : 'stalled', 'behind': run.lastSeq - _appliedSeq},
      }));
      _attach(runId, afterSeq: _appliedSeq);
    } catch (_) {
      // The server couldn't be reached: the next tick tries again.
    } finally {
      _checkingRun = false;
    }
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
    // Back from checking its work: the bot is writing or doing something again.
    if (state.rechecking && e is! UsageItem && e is! MessageCompletedItem) state = state.copyWith(rechecking: false);

    switch (e) {
      case MessageDeltaItem(:final event):
        final run = state.activeRunId;
        if (run != null) _runs.chatWriting(run);
        final id = event.payload.messageId;
        final i = indexWhere((x) => x is MessageEntry && x.id == id);
        if (i < 0) {
          entries.add(MessageEntry(id: id, role: 'assistant', text: event.payload.text, streaming: true, botId: state.activeBotId, runId: event.runId, at: event.ts.toLocal()));
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
          if (text.isNotEmpty || files.isNotEmpty) entries.add(MessageEntry(id: id, role: 'assistant', text: text, attachments: files, botId: state.activeBotId, runId: event.runId, at: event.ts.toLocal()));
        } else if (text.isEmpty && files.isEmpty) {
          // A reply taken back for a second look (D-231, D-269): say the bot is checking its work.
          final shown = entries[i] as MessageEntry;
          entries.removeAt(i);
          if (shown.text.trim().isNotEmpty && state.running) {
            state = state.copyWith(rechecking: true);
          }
        } else {
          entries[i] = (entries[i] as MessageEntry).copyWith(text: text, streaming: false, attachments: files);
        }
        // Scripted replies (the welcome chat) carry their cards only in the finished message.
        for (final u in uiPartsOf(event.payload.content)) {
          if (indexWhere((x) => x is UiEntry && x.surfaceId == u.surfaceId) < 0) {
            entries.add(UiEntry(surfaceId: u.surfaceId, messages: u.messages));
          }
        }
        // Gallery cards (D-315) come with the finished message too.
        for (final g in galleryPartsOf(event.payload.content)) {
          if (indexWhere((x) => x is GalleryCardEntry && x.part.key == g.key) < 0) {
            entries.add(GalleryCardEntry(messageId: id, part: g));
          }
        }
      case UiShownItem(:final event):
        if (indexWhere((x) => x is UiEntry && x.surfaceId == event.payload.surfaceId) < 0) {
          entries.add(UiEntry(surfaceId: event.payload.surfaceId, messages: event.payload.messages));
        }
      case ToolStartedItem(:final event) when state.activeRunId != null && event.payload.tool.isNotEmpty:
        _runs.chatStep(state.activeRunId!, event.payload.tool, event.payload.argsRedacted);
        entries.add(ToolEntry(callId: event.payload.callId, tool: event.payload.tool, args: event.payload.argsRedacted, botId: state.activeBotId));
      case ToolStartedItem(:final event):
        entries.add(ToolEntry(callId: event.payload.callId, tool: event.payload.tool, args: event.payload.argsRedacted, botId: state.activeBotId));
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
        final run = state.activeRunId;
        if (run != null) _runs.chatStatus(run, 'waiting_approval');
        entries.add(
          ApprovalEntry(approvalId: event.payload.approvalId, tool: event.payload.tool, args: event.payload.argsRedacted, risk: event.payload.risk.value, botId: state.activeBotId),
        );
      case ApprovalResolvedItem(:final event):
        final i = indexWhere((x) => x is ApprovalEntry && x.approvalId == event.payload.approvalId);
        if (i >= 0) {
          final a = entries[i] as ApprovalEntry;
          entries[i] = ApprovalEntry(approvalId: a.approvalId, tool: a.tool, args: a.args, risk: a.risk, decision: event.payload.decision.value, botId: a.botId);
        }
        final run = state.activeRunId;
        if (run != null) _runs.chatStatus(run, 'running');
        ref.invalidate(approvalsProvider);
      case SecretRequestedItem(:final event):
        final p = event.payload;
        entries.add(SecretEntry(requestId: p.requestId, name: p.name, service: p.service, hosts: p.allowedHosts.toList(), reason: p.reason, totp: p.kind.value == 'totp'));
      case DeviceAccessRequestedItem() || DeviceBrowserAccessRequestedItem() || DevicePermissionNeededItem():
        // Kept by run so a reload puts it back; a replayed event (following the run again) adds nothing.
        final card = _deviceCardOf(e);
        if (card != null && _keepDeviceCard(card)) entries.add(card);
      case LocalMcpSignInNeededItem(:final event):
        final p = event.payload;
        if (!entries.any((x) => x is McpSignInEntry && x.integrationId == p.integrationId)) {
          entries.add(McpSignInEntry(integrationId: p.integrationId, deviceId: p.deviceId, server: p.server, label: p.label));
        }
      case McpQuestionItem(:final event):
        final p = event.payload;
        entries.add(McpQuestionEntry(questionId: p.questionId, connection: p.connection, message: p.message, schema: Map<String, Object?>.from(p.schema)));
      case McpQuestionResolvedItem(:final event):
        final i = indexWhere((x) => x is McpQuestionEntry && x.questionId == event.payload.questionId);
        if (i >= 0) {
          final q = entries[i] as McpQuestionEntry;
          entries[i] = McpQuestionEntry(questionId: q.questionId, connection: q.connection, message: q.message, schema: q.schema, outcome: event.payload.outcome.value);
        }
      case SecretResolvedItem(:final event):
        final i = indexWhere((x) => x is SecretEntry && x.requestId == event.payload.requestId);
        if (i >= 0) {
          final e = entries[i] as SecretEntry;
          entries[i] = SecretEntry(requestId: e.requestId, name: e.name, service: e.service, hosts: e.hosts, reason: e.reason, totp: e.totp, outcome: event.payload.outcome.value);
        }
      case TakeoverRequestedItem(:final event):
        final run = state.activeRunId;
        if (run != null) _runs.chatStatus(run, 'waiting_takeover');
        entries.add(TakeoverEntry(computerId: event.payload.computerId, reason: event.payload.reason));
        ref.invalidate(takeoversProvider);
      case TakeoverResolvedItem(:final event):
        final i = indexWhere((x) => x is TakeoverEntry && x.computerId == event.payload.computerId && x.outcome == null);
        if (i >= 0) {
          final t = entries[i] as TakeoverEntry;
          entries[i] = TakeoverEntry(computerId: t.computerId, reason: t.reason, outcome: event.payload.outcome.value, note: event.payload.note);
        }
        final run = state.activeRunId;
        if (run != null) _runs.chatStatus(run, 'running');
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
      case MemoryWrittenItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.memory, text: '', refId: event.payload.memoryId, botId: state.activeBotId));
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
        _runs.chatEnded(state.activeRunId!, RunStatus.failed);
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
        final run = state.activeRunId;
        if (run != null) _runs.chatEnded(run, RunStatus.cancelled);
        entries.add(const NoticeEntry(kind: NoticeKind.cancelled, text: ''));
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunCompletedItem() when state.activeRunId != null:
        _runs.chatEnded(state.activeRunId!, RunStatus.completed);
        // A reply the person asked for finished: the 10th and every 40th after can ask for a rating (D-305).
        unawaited(ref.read(reviewPromptProvider).moment(ReviewMoment.replyFinished));
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
      // A gallery card shown during the run (D-315); the finished reply carries it too.
      case UnknownRunEventItem(:final envelope) when envelope.type == 'gallery.shown':
        for (final g in galleryPartsOf([envelope.payload])) {
          if (indexWhere((x) => x is GalleryCardEntry && x.part.key == g.key) < 0) {
            entries.add(GalleryCardEntry(messageId: 'run-${envelope.runId}', part: g));
          }
        }
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

/// The waits between tries of a message send that found no server: about 30 s in all, enough
/// for a server restart.
@visibleForTesting
List<Duration> sendRetryDelays = const [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 15),
];

/// Whether [e] means the request never got an answer from the server (no connection, a timeout,
/// or a gateway with no server behind it), so trying again may work.
bool isConnectionFailure(Object e) {
  if (e is! DioException) return false;
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    case DioExceptionType.unknown:
      return e.response == null;
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      return status == 502 || status == 503 || status == 504;
    case DioExceptionType.transformTimeout:
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
      return false;
  }
}

/// A random version 4 UUID, for the Idempotency-Key of a message send.
String newIdempotencyKey() {
  final r = Random.secure();
  final b = [for (var i = 0; i < 16; i++) r.nextInt(256)];
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

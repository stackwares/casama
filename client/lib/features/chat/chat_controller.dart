import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';

enum ToolStatus { running, done, failed }

/// One entry in the chat: a message, a tool step, or a short notice.
sealed class ChatEntry {
  const ChatEntry();
}

class MessageEntry extends ChatEntry {
  const MessageEntry({required this.id, required this.role, required this.text, this.streaming = false});
  final String id;
  final String role;
  final String text;
  final bool streaming;
  MessageEntry copyWith({String? text, bool? streaming}) =>
      MessageEntry(id: id, role: role, text: text ?? this.text, streaming: streaming ?? this.streaming);
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

enum NoticeKind { memory, skill, checkpoint, computer, failed, cancelled }

class NoticeEntry extends ChatEntry {
  const NoticeEntry({required this.kind, required this.text, this.refId});
  final NoticeKind kind;
  final String text;
  final String? refId;
}

class ChatState {
  const ChatState({
    this.conversationId,
    this.entries = const [],
    this.loading = false,
    this.activeRunId,
    this.lastRunId,
    this.costUsd = 0,
    this.tokens = 0,
    this.lastUserText,
  });
  final String? conversationId;
  final List<ChatEntry> entries;
  final bool loading;
  final String? activeRunId;
  final String? lastRunId;
  final double costUsd;
  final int tokens;
  final String? lastUserText;

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
    String? lastUserText,
  }) =>
      ChatState(
        conversationId: conversationId ?? this.conversationId,
        entries: entries ?? this.entries,
        loading: loading ?? this.loading,
        activeRunId: clearActiveRun ? null : (activeRunId ?? this.activeRunId),
        lastRunId: lastRunId ?? this.lastRunId,
        costUsd: costUsd ?? this.costUsd,
        tokens: tokens ?? this.tokens,
        lastUserText: lastUserText ?? this.lastUserText,
      );
}

/// Chat with one bot: loads a conversation, sends messages and applies live run events.
class ChatController extends Notifier<ChatState> {
  ChatController(this.botId);
  final String botId;
  StreamSubscription<RunEventItem>? _sub;

  Backend get _backend => ref.read(backendProvider);

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ChatState();
  }

  /// Opens a conversation (or the most recent one when null).
  Future<void> open(String? conversationId) async {
    await _sub?.cancel();
    state = const ChatState(loading: true);
    var id = conversationId;
    if (id == null) {
      final list = await _backend.conversations(botId);
      id = list.isEmpty ? null : list.first.id;
    }
    if (id == null) {
      state = const ChatState();
      return;
    }
    final messages = await _backend.messages(id);
    state = ChatState(
      conversationId: id,
      entries: [for (final m in messages) MessageEntry(id: m.id, role: m.role, text: m.text)],
    );
    final active = await _backend.activeRun(id);
    if (active != null) _attach(active);
  }

  Future<void> newChat() async {
    await _sub?.cancel();
    state = const ChatState();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.running) return;
    var conversationId = state.conversationId;
    if (conversationId == null) {
      conversationId = (await _backend.createConversation(botId)).id;
      state = state.copyWith(conversationId: conversationId);
      ref.invalidate(conversationsProvider(botId));
    }
    final optimistic = MessageEntry(id: 'local-${DateTime.now().microsecondsSinceEpoch}', role: 'user', text: trimmed);
    state = state.copyWith(entries: [...state.entries, optimistic], lastUserText: trimmed);
    final sent = await _backend.send(conversationId, trimmed);
    _attach(sent.runId);
  }

  Future<void> retry() async {
    final text = state.lastUserText;
    if (text != null) await send(text);
  }

  Future<void> cancel() async {
    final run = state.activeRunId;
    if (run != null) await _backend.cancelRun(run);
  }

  void _attach(String runId) {
    _sub?.cancel();
    state = state.copyWith(activeRunId: runId, lastRunId: runId, costUsd: 0, tokens: 0);
    _sub = _backend.watchRun(runId).listen(apply, onDone: () {
      if (state.activeRunId == runId) state = state.copyWith(clearActiveRun: true);
      ref.invalidate(botsProvider);
      ref.invalidate(usageTodayProvider);
    });
  }

  /// Applies one run event to the chat (public for tests).
  void apply(RunEventItem e) {
    final entries = [...state.entries];
    int indexWhere(bool Function(ChatEntry) test) => entries.lastIndexWhere(test);

    switch (e) {
      case MessageDeltaItem(:final event):
        final id = event.payload.messageId;
        final i = indexWhere((x) => x is MessageEntry && x.id == id);
        if (i < 0) {
          entries.add(MessageEntry(id: id, role: 'assistant', text: event.payload.text, streaming: true));
        } else {
          final m = entries[i] as MessageEntry;
          entries[i] = m.copyWith(text: m.text + event.payload.text);
        }
      case MessageCompletedItem(:final event):
        final id = event.payload.messageId;
        final text = event.payload.content.where((p) => p['type'] == 'text').map((p) => '${p['text'] ?? ''}').join();
        final i = indexWhere((x) => x is MessageEntry && x.id == id);
        if (i < 0) {
          entries.add(MessageEntry(id: id, role: 'assistant', text: text));
        } else {
          entries[i] = (entries[i] as MessageEntry).copyWith(text: text, streaming: false);
        }
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
      case MemoryWrittenItem():
        entries.add(const NoticeEntry(kind: NoticeKind.memory, text: ''));
      case SkillLoadedItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.skill, text: event.payload.name));
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
        state = state.copyWith(
          costUsd: event.payload.costUsd.toDouble(),
          tokens: (event.payload.tokensIn + event.payload.tokensOut).toInt(),
        );
        return;
      case RunFailedItem(:final event):
        entries.add(NoticeEntry(kind: NoticeKind.failed, text: event.payload.message));
        _finishStreaming(entries);
        state = state.copyWith(entries: entries, clearActiveRun: true);
        return;
      case RunCancelledItem():
        entries.add(const NoticeEntry(kind: NoticeKind.cancelled, text: ''));
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

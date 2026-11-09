import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';

/// A live voice call with a bot (/bots/:id/call?c=conversation).
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.botId, this.conversationId});
  final String botId;
  final String? conversationId;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  VoiceCall? _call;
  String? _conversationId;
  Object? _error;
  var _muted = false;
  var _ending = false;
  final _started = DateTime.now();
  StreamSubscription<CallToolRequest>? _toolSub;
  final _activeTools = <String>[];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    unawaited(_toolSub?.cancel());
    if (!_ending) unawaited(_call?.hangUp());
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      final backend = ref.read(backendProvider);
      final session = await backend.voiceSession(widget.botId, conversationId: widget.conversationId);
      _conversationId = session.conversationId;
      final call = await ref.read(voiceCallConnectorProvider).connect(session);
      if (!mounted) {
        await call.hangUp();
        return;
      }
      call.state.addListener(_refresh);
      call.transcript.addListener(_refresh);
      call.replyLatencyMs.addListener(_refresh);
      // Tool calls run as agent runs with the bot's approvals, then go back to the model.
      _toolSub = call.toolCalls.listen((t) async {
        setState(() => _activeTools.add(t.name));
        try {
          final r = await backend.voiceTool(widget.botId, session.conversationId, t.callId, t.name, t.arguments);
          call.sendToolResult(t.callId, r.output);
        } catch (e) {
          call.sendToolResult(t.callId, 'The tool could not run.');
        } finally {
          if (mounted) setState(() => _activeTools.remove(t.name));
        }
      });
      setState(() => _call = call);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _hangUp() async {
    final call = _call;
    _ending = true;
    if (call != null) {
      final turns = [for (final t in call.transcript.value) (t.role, t.text)];
      await call.hangUp();
      final conv = _conversationId;
      if (!mounted) return;
      if (conv != null && (turns.isNotEmpty || DateTime.now().difference(_started).inSeconds > 0)) {
        await runGuarded(
          context,
          () => ref.read(backendProvider).saveVoiceTranscript(conv, turns, DateTime.now().difference(_started).inSeconds),
        );
      }
    }
    if (!mounted) return;
    final conv = _conversationId;
    ref.invalidate(conversationsProvider(widget.botId));
    if (conv != null) {
      context.go('/bots/${widget.botId}/chat?c=$conv');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bot = ref.watch(botProvider(widget.botId));
    final call = _call;
    final state = _error != null ? CallState.failed : (call?.state.value ?? CallState.connecting);
    final latency = call?.replyLatencyMs.value;
    final turns = call?.transcript.value ?? const <CallTurn>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.callWith(bot?.name ?? ''))),
      body: Column(children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 48,
          backgroundColor: state == CallState.live ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          child: Icon(state == CallState.failed ? Icons.phone_disabled : Icons.graphic_eq, size: 48),
        ),
        const SizedBox(height: 12),
        Text(
          switch (state) {
            CallState.connecting => l10n.callConnecting,
            CallState.live => l10n.callLive,
            CallState.ended => l10n.callEnded,
            CallState.failed => _error == null ? l10n.callFailed : errorText(context, _error!),
          },
          key: const Key('callStatus'),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (latency != null) Text(l10n.replyLatency(latency), key: const Key('replyLatency'), style: theme.textTheme.bodySmall),
        if (_activeTools.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(avatar: const Icon(Icons.build_outlined, size: 16), label: Text(_activeTools.join(', '))),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final t in turns)
              Align(
                alignment: t.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.role == 'user' ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(t.text),
                ),
              ),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.filledTonal(
                key: const Key('muteButton'),
                iconSize: 32,
                tooltip: _muted ? l10n.unmute : l10n.mute,
                icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                onPressed: call == null
                    ? null
                    : () {
                        setState(() => _muted = !_muted);
                        call.setMuted(_muted);
                      },
              ),
              const SizedBox(width: 32),
              IconButton.filled(
                key: const Key('hangUpButton'),
                iconSize: 32,
                style: IconButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
                tooltip: l10n.hangUp,
                icon: const Icon(Icons.call_end),
                onPressed: _hangUp,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'talking_avatar.dart';

/// A live voice call with a bot (/bots/:id/call?c=conversation).
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.botId, this.conversationId, this.callId, this.idleLimit = const Duration(minutes: 2)});
  final String botId;
  final String? conversationId;

  /// An answered phone call (D-135).
  final String? callId;

  /// A call with no speech from either side for this long hangs up, so a forgotten call doesn't
  /// keep streaming (and costing).
  final Duration idleLimit;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  VoiceCall? _call;
  String? _conversationId;
  String? _provider;
  Object? _error;
  var _muted = false;
  var _ending = false;
  final _started = DateTime.now();
  var _avatar = false;
  StreamSubscription<CallToolRequest>? _toolSub;
  final _activeTools = <String>[];
  Timer? _idleTimer;
  Duration _idleTick = const Duration(seconds: 10);
  var _quietTicks = 0;

  void _activity() => _quietTicks = 0;

  void _checkIdle() {
    final call = _call;
    if (call == null || _ending || call.state.value != CallState.live) return;
    if (call.speaking.value || _activeTools.isNotEmpty) {
      _activity();
      return;
    }
    _quietTicks++;
    if (_idleTick * _quietTicks >= widget.idleLimit) {
      showMessage(context, context.l10n.callEndedIdle);
      unawaited(_hangUp());
    }
  }

  @override
  void initState() {
    super.initState();
    _connect();
    unawaited(
      SharedPreferences.getInstance()
          .then((p) {
            if (mounted && (p.getBool('voice.avatar') ?? false)) setState(() => _avatar = true);
          })
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _call?.transcript.removeListener(_activity);
    _call?.speaking.removeListener(_activity);
    unawaited(_toolSub?.cancel());
    // Stop listening first: hanging up changes the call's state while this widget is going away.
    _call?.state.removeListener(_refresh);
    _call?.transcript.removeListener(_refresh);
    _call?.replyLatencyMs.removeListener(_refresh);
    if (!_ending) unawaited(_call?.hangUp());
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      final backend = ref.read(backendProvider);
      final session = await backend.voiceSession(widget.botId, conversationId: widget.conversationId, callId: widget.callId);
      _conversationId = session.conversationId;
      _provider = session.provider.value;
      final call = await ref.read(voiceCallConnectorProvider).connect(session);
      if (!mounted) {
        await call.hangUp();
        return;
      }
      call.state.addListener(_refresh);
      call.transcript.addListener(_refresh);
      call.replyLatencyMs.addListener(_refresh);
      // Speech either way keeps the call going; long silence ends it.
      call.transcript.addListener(_activity);
      call.speaking.addListener(_activity);
      _activity();
      _idleTick = widget.idleLimit < const Duration(seconds: 50) ? widget.idleLimit ~/ 5 : const Duration(seconds: 10);
      _idleTimer = Timer.periodic(_idleTick, (_) => _checkIdle());
      // Tool calls run as agent runs with the bot's approvals, then go back to the model.
      _toolSub = call.toolCalls.listen((t) async {
        setState(() => _activeTools.add(t.name));
        try {
          final r = await backend.voiceTool(widget.botId, session.conversationId, t.callId, t.name, t.arguments);
          call.sendToolResult(t.callId, r.output);
        } catch (e) {
          // Intentionally not translated: this goes to the voice model, not the user.
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
    _idleTimer?.cancel();
    if (call != null) {
      final turns = [for (final t in call.transcript.value) (t.role, t.text)];
      final usage = call.usage;
      await call.hangUp();
      final conv = _conversationId;
      if (!mounted) return;
      if (conv != null && (turns.isNotEmpty || DateTime.now().difference(_started).inSeconds > 0)) {
        await runGuarded(context, () => ref.read(backendProvider).saveVoiceTranscript(conv, turns, DateTime.now().difference(_started).inSeconds, provider: _provider, usage: usage));
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
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(widget.botId));
    final call = _call;
    final state = _error != null ? CallState.failed : (call?.state.value ?? CallState.connecting);
    final latency = call?.replyLatencyMs.value;
    final turns = call?.transcript.value ?? const <CallTurn>[];
    final tint = switch (state) {
      CallState.live => scheme.primary,
      CallState.failed => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    final name = bot?.name ?? '';
    return Scaffold(
      appBar: ShellHeader(title: l10n.callWith(name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = pageSide(constraints.maxWidth);
          return Column(
            children: [
              const SizedBox(height: AppSpace.lg),
              // Soft rings that brighten when the call is live.
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.duration),
                curve: AppMotion.curve,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: state == CallState.live ? 0.08 : 0.04),
                ),
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.duration),
                  curve: AppMotion.curve,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tint.withValues(alpha: state == CallState.live ? 0.14 : 0.07),
                  ),
                  child: state == CallState.failed
                      ? Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.errorContainer),
                          child: Icon(LucideIcons.phoneOff, size: 40, color: scheme.error),
                        )
                      : _avatar && call != null
                      ? TalkingAvatar(name: name.isEmpty ? '?' : name, avatar: bot?.avatarUrl, speaking: call.speaking, color: tint)
                      : BotAvatar(name: name.isEmpty ? '?' : name, avatar: bot?.avatarUrl, size: 96),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(name, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state == CallState.live) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: context.appColors.positive, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        switch (state) {
                          CallState.connecting => l10n.callConnecting,
                          CallState.live => l10n.callLive,
                          CallState.ended => l10n.callEnded,
                          CallState.failed => _error == null ? l10n.callFailed : errorText(context, _error!),
                        },
                        key: const Key('callStatus'),
                        style: context.textTheme.bodyLarge?.copyWith(color: state == CallState.failed ? scheme.error : scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              if (latency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.replyLatency(latency),
                    key: const Key('replyLatency'),
                    style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                  ),
                ),
              if (_activeTools.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: StatusLabel(text: _activeTools.join(', '), color: context.appColors.working, pill: true, icon: LucideIcons.wrench),
                ),
              const SizedBox(height: AppSpace.md),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.md),
                  children: [
                    for (final t in turns)
                      Align(
                        alignment: t.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: (constraints.maxWidth - side * 2) * 0.82),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: t.role == 'user' ? scheme.primary.withValues(alpha: context.isDark ? 0.24 : 0.12) : scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(t.text, style: context.textTheme.bodyLarge?.copyWith(height: 1.4)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CallButton(
                        buttonKey: const Key('muteButton'),
                        icon: _muted ? LucideIcons.micOff : LucideIcons.mic,
                        label: _muted ? l10n.unmute : l10n.mute,
                        selected: _muted,
                        onPressed: call == null
                            ? null
                            : () {
                                setState(() => _muted = !_muted);
                                call.setMuted(_muted);
                              },
                      ),
                      const SizedBox(width: 24),
                      // The optional animated avatar (D-144), remembered on this device.
                      _CallButton(
                        buttonKey: const Key('avatarButton'),
                        icon: LucideIcons.smile,
                        label: l10n.callAvatar,
                        selected: _avatar,
                        onPressed: () {
                          setState(() => _avatar = !_avatar);
                          unawaited(SharedPreferences.getInstance().then((p) => p.setBool('voice.avatar', _avatar)).catchError((_) => false));
                        },
                      ),
                      const SizedBox(width: 24),
                      _CallButton(buttonKey: const Key('hangUpButton'), icon: LucideIcons.phoneOff, label: l10n.hangUp, destructive: true, onPressed: _hangUp),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A round call control with its label underneath.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.buttonKey, required this.icon, required this.label, required this.onPressed, this.selected = false, this.destructive = false});
  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg = destructive ? scheme.error : (selected ? scheme.onSurface : scheme.surfaceContainerHigh);
    final fg = destructive ? scheme.onError : (selected ? scheme.surface : scheme.onSurface);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: buttonKey,
          tooltip: label,
          onPressed: onPressed,
          iconSize: 30,
          style: IconButton.styleFrom(backgroundColor: bg, foregroundColor: fg, fixedSize: const Size(72, 72)),
          icon: Icon(icon),
        ),
        const SizedBox(height: 6),
        Text(label, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

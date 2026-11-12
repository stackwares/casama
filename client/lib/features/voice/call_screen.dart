import 'dart:async';

import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart'
    show VoiceToolResultStatusEnum, problemOf;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../../ui/spring_sheet.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/mascot.dart';
import '../../core/call_audio.dart';
import 'call_activity.dart';
import 'call_mascot.dart';
import 'call_motion.dart';
import '../../core/analytics.dart';

/// A live voice call with a bot (/bots/:id/call?c=conversation).
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({
    super.key,
    required this.botId,
    this.conversationId,
    this.callId,
    this.idleLimit = const Duration(minutes: 2),
  });
  final String botId;
  final String? conversationId;

  /// An answered phone call (D-135).
  final String? callId;

  /// A call with no speech from either side for this long hangs up, so a forgotten call doesn't
  /// keep streaming (and costing).
  final Duration idleLimit;

  /// Off in widget tests: the orb holds still instead of animating every frame.
  @visibleForTesting
  static bool motion = true;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with SingleTickerProviderStateMixin {
  VoiceCall? _call;
  String? _conversationId;
  String? _provider;
  Object? _error;
  var _muted = false;
  var _ending = false;
  final _started = DateTime.now();

  /// Live captions of the last few turns under the orb; remembered on this device.
  var _captions = true;
  final _motion = OrbMotion();
  late final _orb = OrbDriver(this, _motion, _readOrb);
  StreamSubscription<CallToolRequest>? _toolSub;

  /// Tools the bot ran on this call, newest last; finished ones fold away after a moment.
  final _runs = <ToolRun>[];
  final _fades = <Timer>{};

  bool get _toolsBusy => _runs.any((r) => !r.settled);

  /// Shows a finished tool for a moment, then folds it away.
  void _settle(ToolRun run, ToolRunState state) {
    if (!mounted) return;
    setState(() => run.state = state);
    toolHaptic(state);
    if (!run.settled) return;
    final linger = switch (state) {
      ToolRunState.failed ||
      ToolRunState.background => const Duration(seconds: 5),
      _ => const Duration(milliseconds: 2600),
    };
    late final Timer t;
    t = Timer(linger, () {
      _fades.remove(t);
      if (mounted) setState(() => _runs.remove(run));
    });
    _fades.add(t);
  }

  /// Allow or Not now, from the card: decides the approval and tells the bot, which carries on.
  Future<void> _decide(ToolRun run, bool allow) async {
    final id = run.approvalId;
    final call = _call;
    if (id == null) return;
    setState(() => run.deciding = true);
    try {
      await ref.read(backendProvider).decideApproval(id, approve: allow);
      // Intentionally not translated: this goes to the voice model, not the user.
      call?.tellModel(
        allow
            ? '(The user approved ${run.key} in the app. It is running now; the result will appear in the chat. Tell them briefly and carry on.)'
            : '(The user declined ${run.key} in the app. Acknowledge it briefly and carry on.)',
      );
      _settle(run, allow ? ToolRunState.approved : ToolRunState.declined);
    } catch (e) {
      if (mounted) {
        setState(() => run.deciding = false);
        showError(context, e);
      }
    }
  }

  Timer? _idleTimer;
  Duration _idleTick = const Duration(seconds: 10);
  var _quietTicks = 0;

  void _activity() => _quietTicks = 0;

  void _checkIdle() {
    final call = _call;
    if (call == null || _ending || call.state.value != CallState.live) return;
    if (call.speaking.value || _toolsBusy) {
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
            if (mounted && p.getBool('voice.captions') == false) {
              setState(() => _captions = false);
            }
          })
          .catchError((_) {}),
    );
  }

  OrbPhase get _phase {
    final call = _call;
    if (_error != null || call?.state.value == CallState.failed) {
      return OrbPhase.failed;
    }
    if (call == null || call.state.value == CallState.connecting) {
      return OrbPhase.connecting;
    }
    if (_muted) return OrbPhase.muted;
    if (_toolsBusy) return OrbPhase.thinking;
    if (call.speaking.value) return OrbPhase.speaking;
    return OrbPhase.listening;
  }

  /// Each frame: how loud each side is and what the call is doing. Calls that can't measure their
  /// audio pulse the orb while the bot speaks.
  (double, double, OrbPhase) _readOrb() {
    final call = _call;
    final levels = call?.levels;
    final speaking = call?.speaking.value ?? false;
    final output =
        levels?.output ??
        (speaking ? 0.45 + (math.sin(_motion.time * 9)).abs() * 0.3 : 0.0);
    return (levels?.input ?? 0, output, _phase);
  }

  /// Reduced motion (and tests) get the mascot's still pose.
  bool get _animateOrb =>
      CallScreen.motion && !MediaQuery.disableAnimationsOf(context);

  void _syncOrb() {
    final state = _call?.state.value;
    _orb.animate =
        _animateOrb &&
        _error == null &&
        state != CallState.ended &&
        state != CallState.failed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncOrb();
  }

  @override
  void dispose() {
    for (final t in _fades) {
      t.cancel();
    }
    _orb.dispose();
    _motion.dispose();
    _idleTimer?.cancel();
    _call?.transcript.removeListener(_activity);
    _call?.speaking.removeListener(_activity);
    unawaited(_toolSub?.cancel());
    // Stop listening first: hanging up changes the call's state while this widget is going away.
    _call?.state.removeListener(_refresh);
    _call?.speaking.removeListener(_refresh);
    _call?.transcript.removeListener(_refresh);
    _call?.replyLatencyMs.removeListener(_refresh);
    if (!_ending) unawaited(_call?.hangUp());
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      final backend = ref.read(backendProvider);
      final session = await backend.voiceSession(
        widget.botId,
        conversationId: widget.conversationId,
        callId: widget.callId,
      );
      _conversationId = session.conversationId;
      _provider = session.provider.value;
      final call = await ref.read(voiceCallConnectorProvider).connect(session);
      if (!mounted) {
        await call.hangUp();
        return;
      }
      call.state.addListener(_refresh);
      call.speaking.addListener(_refresh);
      call.transcript.addListener(_refresh);
      call.replyLatencyMs.addListener(_refresh);
      // Speech either way keeps the call going; long silence ends it.
      call.transcript.addListener(_activity);
      call.speaking.addListener(_activity);
      _activity();
      _idleTick = widget.idleLimit < const Duration(seconds: 50)
          ? widget.idleLimit ~/ 5
          : const Duration(seconds: 10);
      _idleTimer = Timer.periodic(_idleTick, (_) => _checkIdle());
      // Tool calls run as agent runs with the bot's approvals, then go back to the model.
      _toolSub = call.toolCalls.listen((t) async {
        final run = ToolRun(id: t.callId, name: t.name, arguments: t.arguments);
        setState(() => _runs.add(run));
        try {
          final r = await backend.voiceTool(
            widget.botId,
            session.conversationId,
            t.callId,
            t.name,
            t.arguments,
          );
          call.sendToolResult(t.callId, r.output);
          run.approvalId = r.approvalId;
          _settle(run, switch (r.status) {
            VoiceToolResultStatusEnum.completed => ToolRunState.done,
            VoiceToolResultStatusEnum.failed => ToolRunState.failed,
            VoiceToolResultStatusEnum.waitingApproval =>
              ToolRunState.needsApproval,
            _ => ToolRunState.background,
          });
        } catch (e) {
          // Intentionally not translated: this goes to the voice model, not the user.
          call.sendToolResult(t.callId, 'The tool could not run.');
          _settle(run, ToolRunState.failed);
        }
      });
      setState(() => _call = call);
      Analytics.log('call_started', {'provider': _provider, 'kind': 'in_app', 'result': 'connected'});
      Analytics.feature('voice_call');
      unawaited(_loadRoute());
    } catch (e) {
      Analytics.log('call_started', {'provider': _provider, 'kind': 'in_app', 'result': 'failed'});
      if (mounted) {
        setState(() => _error = e);
        _syncOrb();
      }
    }
  }

  /// Where the call plays now (speaker by default), for the audio button.
  CallRoute? _route;

  Future<void> _loadRoute() async {
    final routes = _call?.routes;
    if (routes == null) return;
    try {
      final r = await routes.current();
      if (mounted) {
        setState(() => _route = r ?? const CallRoute(CallRouteKind.speaker));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _route = const CallRoute(CallRouteKind.speaker));
      }
    }
  }

  /// Speaker and earpiece only: a toggle. With a headset connected: a list to pick from.
  Future<void> _chooseRoute() async {
    final routes = _call?.routes;
    if (routes == null) return;
    final l10n = context.l10n;
    List<CallRoute> available;
    try {
      available = await routes.available();
    } catch (_) {
      available = const [
        CallRoute(CallRouteKind.speaker),
        CallRoute(CallRouteKind.earpiece),
      ];
    }
    if (!mounted) return;
    CallRoute? pick;
    final onlyBuiltIn = available.every(
      (r) =>
          r.kind == CallRouteKind.speaker || r.kind == CallRouteKind.earpiece,
    );
    if (onlyBuiltIn) {
      pick = _route?.kind == CallRouteKind.speaker
          ? const CallRoute(CallRouteKind.earpiece)
          : const CallRoute(CallRouteKind.speaker);
    } else {
      pick = await showSpringBottomSheet<CallRoute>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  0,
                  AppSpace.lg,
                  AppSpace.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.callAudioOutput,
                    style: context.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final r in available)
                ListTile(
                  key: Key('callRoute-${r.kind.name}-${r.id}'),
                  leading: Icon(_routeIcon(r.kind)),
                  title: Text(_routeName(context, r)),
                  trailing: r == _route ? const Icon(LucideIcons.check) : null,
                  onTap: () => Navigator.pop(context, r),
                ),
            ],
          ),
        ),
      );
    }
    if (pick == null || !mounted) return;
    setState(() => _route = pick);
    try {
      await routes.select(pick);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  static IconData _routeIcon(CallRouteKind k) => switch (k) {
    CallRouteKind.speaker => LucideIcons.volume2,
    CallRouteKind.earpiece => LucideIcons.ear,
    CallRouteKind.bluetooth => LucideIcons.bluetooth,
    CallRouteKind.headphones => LucideIcons.headphones,
  };

  static String _routeName(BuildContext context, CallRoute r) =>
      switch (r.kind) {
        CallRouteKind.speaker => context.l10n.callSpeaker,
        CallRouteKind.earpiece => context.l10n.callEarpiece,
        CallRouteKind.bluetooth =>
          r.name.isEmpty ? context.l10n.callBluetooth : r.name,
        CallRouteKind.headphones =>
          r.name.isEmpty ? context.l10n.callHeadphones : r.name,
      };

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    _syncOrb();
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
      if (conv != null &&
          (turns.isNotEmpty ||
              DateTime.now().difference(_started).inSeconds > 0)) {
        await runGuarded(
          context,
          () => ref
              .read(backendProvider)
              .saveVoiceTranscript(
                conv,
                turns,
                DateTime.now().difference(_started).inSeconds,
                provider: _provider,
                usage: usage,
              ),
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
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(widget.botId));
    final call = _call;
    final state = _error != null
        ? CallState.failed
        : (call?.state.value ?? CallState.connecting);
    final latency = call?.replyLatencyMs.value;
    final turns = call?.transcript.value ?? const <CallTurn>[];
    final name = bot?.name ?? '';
    final needsKey =
        _error != null && problemOf(_error!)?.code == 'voice_key_missing';
    final phase = _phase;
    final phaseLabel = switch (phase) {
      OrbPhase.speaking => l10n.callSpeaking,
      OrbPhase.thinking => l10n.callWorking,
      OrbPhase.muted => l10n.callMutedState,
      _ => l10n.callListening,
    };
    final stage = _CallStage(
      phase: phase,
      phaseLabel: phaseLabel,
      mascot: Mascot.fromAvatar(bot?.avatarUrl),
      motion: _motion,
      animate: _animateOrb,
      runs: needsKey ? const [] : _runs,
      onDecide: _decide,
      captions: needsKey ? false : _captions,
      turns: turns,
    );
    return Scaffold(
      appBar: ShellHeader(title: l10n.callWith(name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = pageSide(constraints.maxWidth);
          final controls = <Widget>[
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
            _CallButton(
              buttonKey: const Key('captionsButton'),
              icon: LucideIcons.captions,
              label: l10n.callCaptions,
              selected: _captions,
              onPressed: () {
                setState(() => _captions = !_captions);
                unawaited(
                  SharedPreferences.getInstance()
                      .then((p) => p.setBool('voice.captions', _captions))
                      .catchError((_) => false),
                );
              },
            ),
            if (call?.routes != null)
              _CallButton(
                buttonKey: const Key('audioRouteButton'),
                icon: _routeIcon(_route?.kind ?? CallRouteKind.speaker),
                label: _routeName(
                  context,
                  _route ?? const CallRoute(CallRouteKind.speaker),
                ),
                selected:
                    (_route?.kind ?? CallRouteKind.speaker) ==
                    CallRouteKind.speaker,
                onPressed: _chooseRoute,
              ),
            _CallButton(
              buttonKey: const Key('hangUpButton'),
              icon: LucideIcons.phoneOff,
              label: l10n.hangUp,
              destructive: true,
              onPressed: _hangUp,
            ),
          ];
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSpace.sm,
                    side,
                    AppSpace.xs,
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (state == CallState.live) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.appColors.positive,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              switch (state) {
                                CallState.connecting => l10n.callConnecting,
                                CallState.live => l10n.callLive,
                                CallState.ended => l10n.callEnded,
                                CallState.failed =>
                                  needsKey
                                      ? l10n.callNeedsKeyTitle
                                      : (_error == null
                                            ? l10n.callFailed
                                            : errorText(context, _error!)),
                              },
                              key: const Key('callStatus'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: state == CallState.failed
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (state == CallState.live)
                            const SizedBox(width: 14),
                        ],
                      ),
                      if (latency != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.replyLatency(latency),
                            key: const Key('replyLatency'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFeatures: AppText.tabular,
                            ),
                          ),
                        ),
                      Expanded(
                        child: needsKey
                            ? Column(
                                children: [
                                  Expanded(child: stage),
                                  Flexible(
                                    child: SingleChildScrollView(
                                      primary: false,
                                      child: _NeedsKeyCard(
                                        onAddKey: () => context.push(
                                          '/settings/keys?provider=google',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : stage,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.md,
                    AppSpace.md,
                  ),
                  child: Row(
                    children: [
                      for (final control in controls) Expanded(child: control),
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

/// The mascot, tool cards and captions, sharing whatever height is left after the name and
/// the controls. The mascot shrinks first. Cards scroll. Captions keep the newest line and
/// clip older ones instead of spilling out of the column.
class _CallStage extends StatelessWidget {
  const _CallStage({
    required this.phase,
    required this.phaseLabel,
    required this.mascot,
    required this.motion,
    required this.animate,
    required this.runs,
    required this.onDecide,
    required this.captions,
    required this.turns,
  });

  final OrbPhase phase;
  final String phaseLabel;
  final Mascot? mascot;
  final OrbMotion motion;
  final bool animate;
  final List<ToolRun> runs;
  final void Function(ToolRun run, bool allow) onDecide;
  final bool captions;
  final List<CallTurn> turns;

  @override
  Widget build(BuildContext context) {
    final mascotSlot = Expanded(
      flex: runs.isNotEmpty || captions ? 5 : 1,
      child: LayoutBuilder(
        builder: (context, box) {
          // The art grows a little with the voice, so it stays smaller than the slot.
          final orb = math.min(
            300.0,
            math.min(box.maxWidth, box.maxHeight) * 0.94,
          );
          if (box.maxHeight < 56 || orb < 56) return const SizedBox.shrink();
          return Center(
            child: Semantics(
              label: phaseLabel,
              child: KeyedSubtree(
                key: Key('callMascot-${phase.name}'),
                child: CallMascot(
                  mascot: mascot,
                  motion: motion,
                  size: orb,
                  animate: animate,
                ),
              ),
            ),
          );
        },
      ),
    );
    return Column(
      children: [
        mascotSlot,
        if (runs.isNotEmpty)
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: CallActivity(
                    runs: runs,
                    motion: motion,
                    onDecide: onDecide,
                    animate: animate,
                  ),
                ),
              ),
            ),
          ),
        if (captions) Expanded(flex: 3, child: _Captions(turns: turns)),
      ],
    );
  }
}

/// The last few turns as captions: the newest large and clear, older ones fading above it.
/// When the space is short, older lines clip off the top instead of overflowing.
class _Captions extends StatelessWidget {
  const _Captions({required this.turns});
  final List<CallTurn> turns;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final recent = turns.length > 3 ? turns.sublist(turns.length - 3) : turns;
    return ClipRect(
      child: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black],
          stops: [0, 0.3, 1],
        ).createShader(r),
        blendMode: BlendMode.dstIn,
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, t) in recent.indexed)
                AnimatedOpacity(
                  duration: AppMotion.of(context, AppMotion.duration),
                  opacity: i == recent.length - 1 ? 1 : 0.45,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      t.text,
                      textAlign: TextAlign.center,
                      maxLines: i == recent.length - 1 ? 4 : 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (i == recent.length - 1
                                  ? context.textTheme.titleMedium
                                  : context.textTheme.bodyMedium)
                              ?.copyWith(
                                height: 1.35,
                                fontWeight: t.role == 'user'
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: t.role == 'user'
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live calls need a Google AI (or OpenAI) key: where to get one free and where to add it.
class _NeedsKeyCard extends StatelessWidget {
  const _NeedsKeyCard({required this.onAddKey});
  final VoidCallback onAddKey;

  static final _studio = Uri.parse('https://aistudio.google.com/apikey');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      key: const Key('callNeedsKey'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.callNeedsKeyBody,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(
            key: const Key('callAddKey'),
            onPressed: onAddKey,
            child: _KeyButtonLabel(
              icon: LucideIcons.keyRound,
              label: l10n.callAddKey,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            key: const Key('callGetKey'),
            onPressed: () =>
                launchUrl(_studio, mode: LaunchMode.externalApplication),
            child: _KeyButtonLabel(
              icon: LucideIcons.externalLink,
              label: l10n.callGetFreeKey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon and label for the "needs a key" buttons, trimmed when the phone is narrow.
class _KeyButtonLabel extends StatelessWidget {
  const _KeyButtonLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// A round call control with its label underneath. The row gives each control an equal slice,
/// and the disc shrinks to fit that slice.
class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
  });
  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg = destructive
        ? scheme.error
        : (selected ? scheme.onSurface : scheme.surfaceContainerHigh);
    final fg = destructive
        ? scheme.onError
        : (selected ? scheme.surface : scheme.onSurface);
    return LayoutBuilder(
      builder: (context, constraints) {
        final d = math.min(64.0, math.max(40.0, constraints.maxWidth - 8));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: buttonKey,
              tooltip: label,
              onPressed: onPressed,
              iconSize: d * 0.42,
              style: IconButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                fixedSize: Size(d, d),
                minimumSize: Size(d, d),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              icon: Icon(icon),
            ),
            const SizedBox(height: 4),
            // Headset names can be long ("Oliver's AirPods Pro"): one line, trimmed.
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

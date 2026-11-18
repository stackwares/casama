import 'dart:async';

import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart'
    show problemOf;
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
import '../../ui/fold_split.dart';
import '../../ui/shell_header.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/mascot.dart';
import '../../core/call_audio.dart';
import '../../core/screen_awake.dart';
import '../chat/chat_screen.dart' show computerForBot;
import 'active_call.dart';
import 'call_activity.dart';
import 'call_live_tile.dart';
import 'call_mascot.dart';
import 'call_motion.dart';
import '../../core/remote_content.dart';

/// A live voice call with a bot (/bots/:id/call?c=conversation). The call itself belongs to the
/// app (D-327, [ActiveCall]): this screen is one view of it, next to the bubble and the sidebar
/// card. Leaving the screen minimises the call; only hanging up ends it.
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ActiveCall _active;
  CallController? _c;

  /// Another bot's call is going on: asking whether to end it first (D-327 §5).
  var _asking = false;

  /// The call ended and this screen already moved on.
  var _left = false;

  /// Live captions of the last few turns under the orb; remembered on this device.
  var _captions = true;
  final _motion = OrbMotion();
  late final _orb = OrbDriver(this, _motion, _readOrb);

  @override
  void initState() {
    super.initState();
    _active = ref.read(activeCallProvider);
    _active.addView();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ScreenAwake.set(true));
    _attach();
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

  /// Starts the call, or shows the one going on with this bot; another bot's call asks first.
  void _attach() {
    final c = _active.begin(
      widget.botId,
      conversationId: widget.conversationId,
      phoneCallId: widget.callId,
      idleLimit: widget.idleLimit,
    );
    if (c == null) {
      _asking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_askSwitch());
      });
      return;
    }
    _c = c;
    c.addListener(_onCall);
    if (c.over) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onCall());
    }
  }

  /// "End call with Ava and call Max?": End and call ends the first call (saved as usual), then
  /// starts this one; Cancel goes back.
  Future<void> _askSwitch() async {
    final other = _active.live;
    if (other == null) {
      setState(() => _asking = false);
      _attach();
      return;
    }
    final l10n = context.l10n;
    final from = ref.read(botProvider(other.botId))?.name ?? '';
    final to = ref.read(botProvider(widget.botId))?.name ?? '';
    final ok = await showConfirm(
      context: context,
      icon: LucideIcons.phoneForwarded,
      title: l10n.callSwitchTitle(from, to),
      message: l10n.callSwitchBody,
      confirmLabel: l10n.callSwitchConfirm,
      confirmKey: const Key('callSwitchConfirm'),
    );
    if (!mounted) return;
    if (!ok) {
      _leave();
      return;
    }
    await _active.end(CallEnd.replaced);
    if (!mounted) return;
    setState(() => _asking = false);
    _attach();
  }

  /// Back where the person came from; the call carries on in the bubble or the sidebar card.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/bots/${widget.botId}/chat');
    }
  }

  void _onCall() {
    if (!mounted) return;
    final c = _c;
    if (c == null) return;
    if (c.over) {
      if (!_left) {
        _left = true;
        _afterEnd(c);
      }
      return;
    }
    setState(() {});
    _syncOrb();
  }

  /// The call ended, however it ended: say why when it wasn't the person, then open its chat.
  void _afterEnd(CallController c) {
    final l10n = context.l10n;
    switch (c.endedBy) {
      case CallEnd.idle:
        showMessage(context, l10n.callEndedIdle);
      case CallEnd.server:
        showMessage(context, l10n.callEndedLost);
      default:
    }
    if (c.saveError case final e?) showError(context, e);
    ref.invalidate(conversationsProvider(widget.botId));
    final conv = c.conversationId;
    if (conv != null) {
      context.go('/bots/${widget.botId}/chat?c=$conv');
    } else {
      _leave();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The screen stays on while the call screen is in front, never in the background.
    unawaited(ScreenAwake.set(state == AppLifecycleState.resumed));
  }

  OrbPhase get _phase {
    final c = _c;
    final call = c?.call;
    if (c?.error != null || call?.state.value == CallState.failed) {
      return OrbPhase.failed;
    }
    if (call == null || call.state.value == CallState.connecting) {
      return OrbPhase.connecting;
    }
    if (c!.muted) return OrbPhase.muted;
    if (c.toolsWaiting) return OrbPhase.thinking;
    if (call.speaking.value) return OrbPhase.speaking;
    return OrbPhase.listening;
  }

  /// Each frame: how loud each side is and what the call is doing. Calls that can't measure their
  /// audio pulse the orb while the bot speaks.
  (double, double, OrbPhase) _readOrb() {
    final call = _c?.call;
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
    final c = _c;
    final state = c?.state;
    _orb.animate =
        _animateOrb &&
        c?.error == null &&
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
    WidgetsBinding.instance.removeObserver(this);
    _active.removeView();
    if (!_active.onScreen) unawaited(ScreenAwake.set(false));
    final c = _c;
    c?.removeListener(_onCall);
    // A call that never connected has nothing to minimise: leaving the screen ends it.
    if (c != null && !c.over && c.error != null) {
      // After this frame: ending tells the bubble and the sidebar card, which mustn't rebuild
      // while the tree is unmounting.
      final active = _active;
      scheduleMicrotask(
        () => unawaited(c.end(CallEnd.failed).then((_) => active.clearEnded())),
      );
    } else if (c != null && c.over) {
      _active.clearEnded();
    }
    _orb.dispose();
    _motion.dispose();
    super.dispose();
  }

  /// Allow or Not now, from the card: decides the approval and tells the bot, which carries on.
  Future<void> _decide(ToolRun run, bool allow) async {
    try {
      await _c?.decide(run, allow);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Speaker and earpiece only: a toggle. With a headset connected: a list to pick from.
  Future<void> _chooseRoute() async {
    final c = _c;
    final routes = c?.call?.routes;
    if (c == null || routes == null) return;
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
      pick = c.route?.kind == CallRouteKind.speaker
          ? const CallRoute(CallRouteKind.earpiece)
          : const CallRoute(CallRouteKind.speaker);
    } else {
      pick = (await showChoiceSheet<CallRoute>(
        context,
        icon: LucideIcons.volume2,
        title: l10n.callAudioOutput,
        selected: c.route,
        choices: [
          for (final r in available)
            Choice(key: Key('callRoute-${r.kind.name}-${r.id}'), value: r, icon: callRouteIcon(r.kind), label: callRouteName(context, r)),
        ],
      ))?.value;
    }
    if (pick == null || !mounted) return;
    try {
      await c.selectRoute(pick);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// The computer the call's jobs use, else the bot's own.
  String? _computerId(CallController c) =>
      c.jobComputerId ??
      computerForBot(
        ref.watch(computersProvider).value ?? const [],
        widget.botId,
        defaultComputerId: ref.watch(botProvider(widget.botId))?.defaultComputerId,
      )?.id;

  /// The tile, tapped: the desktop full screen (the live view, with takeover) in place of this
  /// screen, and the call shrinks to the bubble. Tapping the bubble swaps back.
  void _openScreen(String computerId) =>
      GoRouter.of(context).swapTo(liveViewPath(computerId));

  /// The job strip, tapped: the live view when a computer is in use, else the chat it reports to.
  void _openJob(CallController c) {
    final id = c.jobComputerId ?? (c.tileShown ? _computerId(c) : null);
    if (id != null) {
      _openScreen(id);
      return;
    }
    final conv = c.conversationId;
    context.pushOnce('/bots/${widget.botId}/chat${conv == null ? '' : '?c=$conv'}');
  }

  Future<void> _hangUp() async {
    final c = _c;
    if (c == null) {
      _leave();
      return;
    }
    await c.end(CallEnd.hungUp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(widget.botId));
    // Kept loaded for the bot's screen on the call (the tile, show_screen).
    ref.watch(computersProvider);
    final c = _c;
    final call = c?.call;
    final error = c?.error;
    final muted = c?.muted ?? false;
    final route = c?.route;
    final state = error != null
        ? CallState.failed
        : (call?.state.value ?? CallState.connecting);
    final latency = call?.replyLatencyMs.value;
    final turns = call?.transcript.value ?? const <CallTurn>[];
    final name = bot?.name ?? '';
    final needsKey =
        error != null && problemOf(error)?.code == 'voice_key_missing';
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
      runs: needsKey || c == null ? const [] : c.runs,
      onDecide: _decide,
      captions: needsKey ? false : _captions,
      turns: turns,
    );
    // A folding phone, partly folded (D-411): the bot and the captions on the half you look at, the
    // buttons on the half under the hand. The page has no header then; Minimise joins the buttons.
    final divided = FoldSplit.dividing(context);
    final minimise = IconButton(
      key: const Key('minimiseCall'),
      tooltip: l10n.callMinimize,
      icon: const Icon(LucideIcons.minimize2),
      onPressed: _asking ? null : _leave,
    );
    return Scaffold(
      appBar: divided
          ? null
          : ShellHeader(
              title: l10n.callWith(name),
              actions: [
                // Minimise: back to the app with the call still on (the bubble or the sidebar card).
                minimise,
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = pageSide(constraints.maxWidth);
          final controls = <Widget>[
            _CallButton(
              buttonKey: const Key('muteButton'),
              icon: muted ? LucideIcons.micOff : LucideIcons.mic,
              label: muted ? l10n.unmute : l10n.mute,
              selected: muted,
              onPressed: call == null ? null : () => c!.setMuted(!muted),
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
                icon: callRouteIcon(route?.kind ?? CallRouteKind.speaker),
                label: callRouteName(
                  context,
                  route ?? const CallRoute(CallRouteKind.speaker),
                ),
                selected:
                    (route?.kind ?? CallRouteKind.speaker) ==
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
          final tileComputer = c != null && c.tileShown && !needsKey
              ? _computerId(c)
              : null;
          final wide = constraints.maxWidth >= 900;
          Widget tile({required bool large}) => CallLiveTile(
            key: const ValueKey('callTile'),
            computerId: tileComputer!,
            needsYou: c!.tileNeedsYou,
            done: c.tileDone,
            large: large,
            onTap: () => _openScreen(tileComputer),
            onClose: c.hideTile,
          );
          // Who the call is with and how it is going.
          final status = Row(
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
                          : (error == null
                                ? l10n.callFailed
                                : errorText(context, error)),
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
          );
          final head = <Widget>[
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
            status,
          ];
          final progress = <Widget>[
            if (c?.activeJob case final job? when !needsKey)
              CallJobStrip(
                key: ValueKey('job-${job.runId}'),
                job: job,
                onTap: () => _openJob(c!),
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
          ];
          // The bot (and the captions), or what is missing for a call.
          final Widget show = needsKey
              ? Column(
                  children: [
                    Expanded(child: stage),
                    Flexible(
                      child: SingleChildScrollView(
                        primary: false,
                        child: _NeedsKeyCard(
                          onAddKey: () => context.pushOnce(
                            '/settings/keys?provider=google',
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : stage;

          if (divided) {
            return FoldSplit(
              whole: const SizedBox.shrink(),
              first: SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.xs),
                      child: Column(children: [...head, ...progress, Expanded(child: show)]),
                    ),
                    if (tileComputer != null)
                      Positioned.fill(
                        child: CallTileCorner(
                          insets: const EdgeInsets.all(AppSpace.sm),
                          child: tile(large: false),
                        ),
                      ),
                  ],
                ),
              ),
              second: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(padding: const EdgeInsets.all(AppSpace.xs), child: minimise),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      child: Row(children: [for (final control in controls) Expanded(child: control)]),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          }

          // Short and wide (a phone on its side, an iPhone Duo standing like a tent): the bot and
          // the captions fill the height, the buttons stack beside them in twos.
          if (tileComputer == null && constraints.maxWidth > constraints.maxHeight && constraints.maxHeight < 440) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(child: show),
                    const SizedBox(width: AppSpace.md),
                    SizedBox(
                      width: math.min(240, constraints.maxWidth * 0.42),
                      child: Column(
                        children: [
                          status,
                          ...progress,
                          const Spacer(),
                          for (var i = 0; i < controls.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpace.xs),
                              child: Row(
                                children: [
                                  Expanded(child: controls[i]),
                                  Expanded(child: i + 1 < controls.length ? controls[i + 1] : const SizedBox.shrink()),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final callColumn = Column(
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
                      ...head,
                      ...progress,
                      Expanded(child: show),
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
          if (tileComputer == null) return callColumn;
          // Wide screens: the desktop beside the call, the mascot and captions in a column.
          if (wide) {
            return Row(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: tile(large: true),
                    ),
                  ),
                ),
                SizedBox(
                  width: math.min(440, constraints.maxWidth * 0.4),
                  child: callColumn,
                ),
              ],
            );
          }
          // Phones: a small tile in a corner, clear of the name and the controls.
          return Stack(
            children: [
              callColumn,
              Positioned.fill(
                child: CallTileCorner(
                  insets: EdgeInsets.fromLTRB(
                    AppSpace.sm,
                    AppSpace.sm,
                    AppSpace.sm,
                    96 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: tile(large: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// The icon for where a call plays.
IconData callRouteIcon(CallRouteKind k) => switch (k) {
  CallRouteKind.speaker => LucideIcons.volume2,
  CallRouteKind.earpiece => LucideIcons.ear,
  CallRouteKind.bluetooth => LucideIcons.bluetooth,
  CallRouteKind.headphones => LucideIcons.headphones,
};

/// The name of where a call plays, as the audio button says it.
String callRouteName(BuildContext context, CallRoute r) => switch (r.kind) {
  CallRouteKind.speaker => context.l10n.callSpeaker,
  CallRouteKind.earpiece => context.l10n.callEarpiece,
  CallRouteKind.bluetooth => r.name.isEmpty ? context.l10n.callBluetooth : r.name,
  CallRouteKind.headphones => r.name.isEmpty ? context.l10n.callHeadphones : r.name,
};

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

  static Uri get _studio => remoteUri('gemini_keys', 'https://aistudio.google.com/apikey');

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

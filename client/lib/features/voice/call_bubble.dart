import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/fold/fold.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import 'active_call.dart';

/// Where tapping a minimised call goes: back to its call screen.
String callScreenPath(CallController c) =>
    '/bots/${c.botId}/call${c.conversationId == null ? '' : '?c=${c.conversationId}'}';

/// "3:07": how long a call has been live.
String callClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// A call's timer, ticking once a second while shown.
class CallTimerText extends StatefulWidget {
  const CallTimerText({super.key, required this.call, this.style});
  final CallController call;
  final TextStyle? style;

  @override
  State<CallTimerText> createState() => _CallTimerTextState();
}

class _CallTimerTextState extends State<CallTimerText> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    final l10n = context.l10n;
    final text = c.connectedAt == null
        ? (c.error != null ? l10n.callFailed : l10n.callConnecting)
        : c.reconnecting
        ? l10n.callReconnecting
        : c.held
        ? l10n.callOnHold
        : callClock(c.elapsed);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (widget.style ?? context.textTheme.labelSmall)?.copyWith(
        fontFeatures: AppText.tabular,
      ),
    );
  }
}

/// The minimised call over every screen on phones and narrow windows (D-327 §3): the bot's face
/// with a ring that pulses with its voice, the timer underneath. Drag it anywhere; it snaps to the
/// nearest side and remembers which. Tap to go back to the call; long press for Mute and End call.
/// It steps aside while a call screen shows the call, or where the sidebar card docks it.
class CallBubbleOverlay extends ConsumerWidget {
  const CallBubbleOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCallProvider);
    return Stack(
      children: [
        child,
        ListenableBuilder(
          listenable: active,
          builder: (context, _) {
            final c = active.live;
            return Stack(
              children: [
                // Web: a hidden tab keeps the call; its title says so (D-327 §7).
                if (kIsWeb && c != null) CallTabTitle(key: ValueKey(c), call: c),
                if (c != null && !active.onScreen && !active.docked)
                  _Bubble(key: ValueKey(c), call: c),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// "On a call · 3:12" as the browser tab's title while a call goes on, ticking once a second;
/// the app's own title comes back when it ends.
class CallTabTitle extends StatefulWidget {
  const CallTabTitle({super.key, required this.call});
  final CallController call;

  @override
  State<CallTabTitle> createState() => _CallTabTitleState();
}

class _CallTabTitleState extends State<CallTabTitle> {
  Timer? _tick;
  String? _shown;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _set());
    WidgetsBinding.instance.addPostFrameCallback((_) => _set());
  }

  void _set() {
    if (!mounted) return;
    final c = widget.call;
    final title = context.l10n.callTabTitle(
      c.connectedAt == null ? '0:00' : callClock(c.elapsed),
    );
    if (title == _shown) return;
    _shown = title;
    unawaited(
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(label: title),
      ),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(
      SystemChrome.setApplicationSwitcherDescription(
        const ApplicationSwitcherDescription(label: 'Casama'),
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Bubble extends ConsumerStatefulWidget {
  const _Bubble({super.key, required this.call});
  final CallController call;

  @override
  ConsumerState<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends ConsumerState<_Bubble>
    with SingleTickerProviderStateMixin {
  static const size = 64.0;
  static const _sideKey = 'call.bubble.side';
  static const _yKey = 'call.bubble.y';

  /// Which side it sits on (true: right), and how far down, 0 (top) to 1 (bottom).
  var _right = true;
  var _y = 0.62;

  /// Where it is while being dragged (null when resting on its side).
  Offset? _drag;
  var _wasNeedingPerson = false;
  late final Ticker _ticker;
  final _level = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final call = widget.call.call;
      final out =
          call?.levels?.output ?? ((call?.speaking.value ?? false) ? 0.6 : 0.0);
      _level.value = out;
    });
    widget.call.addListener(_changed);
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: the ring holds still.
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!animate && _ticker.isActive) {
      _ticker.stop();
      _level.value = 0;
    }
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _right = p.getBool(_sideKey) ?? true;
        _y = (p.getDouble(_yKey) ?? 0.62).clamp(0.0, 1.0);
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_sideKey, _right);
      await p.setDouble(_yKey, _y);
    } catch (_) {}
  }

  void _changed() {
    if (!mounted) return;
    final needs = widget.call.needsPerson;
    // Something needs the person (an approval): a light tap, once.
    if (needs && !_wasNeedingPerson) unawaited(HapticFeedback.lightImpact());
    _wasNeedingPerson = needs;
    setState(() {});
  }

  @override
  void dispose() {
    widget.call.removeListener(_changed);
    _ticker.dispose();
    _level.dispose();
    super.dispose();
  }

  void _open() =>
      unawaited(ref.read(routerProvider).pushOnce(callScreenPath(widget.call)));

  Future<void> _menu(Offset at) async {
    final l10n = context.l10n;
    final c = widget.call;
    // The bubble sits beside the router's navigator, not under it: the menu opens on that one.
    final nav = ref
        .read(routerProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (nav == null) return;
    final pick = await showMenu<String>(
      context: nav,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        PopupMenuItem(
          key: const Key('callBubbleMute'),
          value: 'mute',
          child: Row(
            children: [
              Icon(c.muted ? LucideIcons.mic : LucideIcons.micOff, size: 18),
              const SizedBox(width: AppSpace.sm),
              Text(c.muted ? l10n.unmute : l10n.mute),
            ],
          ),
        ),
        PopupMenuItem(
          key: const Key('callBubbleEnd'),
          value: 'end',
          child: Row(
            children: [
              Icon(
                LucideIcons.phoneOff,
                size: 18,
                color: context.colorScheme.error,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                l10n.callEndCall,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (pick) {
      case 'mute':
        c.setMuted(!c.muted);
      case 'end':
        unawaited(c.end(CallEnd.hungUp));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.call;
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(c.botId));
    final media = MediaQuery.of(context);
    final screen = media.size;
    final pad = media.padding;
    const margin = AppSpace.md;
    // Clear of the safe areas, the keyboard and the floating tab bar.
    final top = pad.top + margin;
    final bottom =
        screen.height -
        math.max(pad.bottom, media.viewInsets.bottom) -
        96 -
        size;
    final left = pad.left + margin;
    final right = screen.width - pad.right - margin - size;
    final restX = _right ? right : left;
    var restY = top + (math.max(bottom, top) - top) * _y;
    // A folding phone propped up (D-411): not on the fold, where it is hard to see and to tap.
    final fold = FoldInfo.of(context);
    if (fold.gap case final gap? when !fold.foldVertical && restY + size > gap.top && restY < gap.bottom) {
      restY = restY + size / 2 < gap.center.dy ? gap.top - size - AppSpace.xs : gap.bottom + AppSpace.xs;
    }
    final pos = _drag ?? Offset(restX, restY);
    final minutes = c.elapsed.inMinutes;
    final name = bot?.name ?? '';
    final labelTime = l10n.callMinutes(minutes);
    return AnimatedPositioned(
      duration: _drag == null
          ? AppMotion.of(context, const Duration(milliseconds: 220))
          : Duration.zero,
      curve: AppMotion.curve,
      left: pos.dx.clamp(left, math.max(left, right)),
      top: pos.dy.clamp(top, math.max(top, bottom)),
      // Over the router, outside any page: its own Material for text and ink.
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          key: const Key('callBubble'),
          button: true,
          label: l10n.callBubbleLabel(name, labelTime),
          customSemanticsActions: {
            CustomSemanticsAction(
              label: c.muted ? l10n.unmute : l10n.mute,
            ): () =>
                c.setMuted(!c.muted),
            CustomSemanticsAction(label: l10n.callEndCall): () =>
                unawaited(c.end(CallEnd.hungUp)),
          },
          child: GestureDetector(
            onTap: _open,
            onLongPressStart: (d) => unawaited(_menu(d.globalPosition)),
            onPanStart: (_) => setState(() => _drag = pos),
            onPanUpdate: (d) =>
                setState(() => _drag = (_drag ?? pos) + d.delta),
            onPanEnd: (_) {
              final at = _drag ?? pos;
              setState(() {
                _right = at.dx + size / 2 > screen.width / 2;
                _y = bottom <= top
                    ? 0
                    : ((at.dy - top) / (bottom - top)).clamp(0.0, 1.0);
                _drag = null;
              });
              unawaited(_save());
            },
            child: ExcludeSemantics(
              child: SizedBox(
                width: size,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: _level,
                      builder: (context, level, child) => Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainerHigh,
                          border: Border.all(
                            color: context.appColors.positive.withValues(
                              alpha: 0.5 + level * 0.5,
                            ),
                            width: 2 + level * 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: BotAvatar(
                              name: name,
                              avatar: bot?.avatarUrl,
                              size: size - 18,
                              animate: false,
                            ),
                          ),
                          if (c.muted)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: _Badge(
                                color: scheme.error,
                                icon: LucideIcons.micOff,
                                key: const Key('callBubbleMuted'),
                              ),
                            ),
                          if (c.needsPerson)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                key: const Key('callBubbleNeedsYou'),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: context.appColors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CallTimerText(
                        call: c,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: context.colorScheme.surface, width: 2),
    ),
    child: Icon(icon, size: 12, color: context.colorScheme.onError),
  );
}

/// The call docked at the bottom of the sidebar on wide windows (D-327 §3, decision 1): the bot,
/// its timer, Mute and End call. Clicking it opens the call. It never covers content; while it's
/// there the bubble stays away.
class CallSidebarCard extends ConsumerStatefulWidget {
  const CallSidebarCard({super.key});

  @override
  ConsumerState<CallSidebarCard> createState() => _CallSidebarCardState();
}

class _CallSidebarCardState extends ConsumerState<CallSidebarCard> {
  late final ActiveCall _active;

  @override
  void initState() {
    super.initState();
    _active = ref.read(activeCallProvider);
    _active.addDock();
  }

  @override
  void dispose() {
    _active.removeDock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return ListenableBuilder(
      listenable: _active,
      builder: (context, _) {
        final c = _active.live;
        if (c == null || _active.onScreen) return const SizedBox.shrink();
        final bot = ref.watch(botProvider(c.botId));
        final name = bot?.name ?? '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Material(
            key: const Key('callSidebarCard'),
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pushOnce(callScreenPath(c)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BotAvatar(
                          name: name,
                          avatar: bot?.avatarUrl,
                          size: 32,
                          animate: false,
                        ),
                        if (c.needsPerson)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: context.appColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.callWith(name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          CallTimerText(
                            call: c,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.appColors.positive,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('callCardMute'),
                      tooltip: c.muted ? l10n.unmute : l10n.mute,
                      visualDensity: VisualDensity.compact,
                      isSelected: c.muted,
                      icon: Icon(
                        c.muted ? LucideIcons.micOff : LucideIcons.mic,
                        size: 18,
                      ),
                      onPressed: () => c.setMuted(!c.muted),
                    ),
                    IconButton(
                      key: const Key('callCardEnd'),
                      tooltip: l10n.callEndCall,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      icon: const Icon(LucideIcons.phoneOff, size: 18),
                      onPressed: () => unawaited(c.end(CallEnd.hungUp)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A thin bar at the top of the call's chat while the call is minimised: "On a call with Ava,
/// tap to return".
class CallReturnBar extends ConsumerWidget {
  const CallReturnBar({super.key, required this.botId, this.conversationId});
  final String botId;
  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCallProvider);
    return ListenableBuilder(
      listenable: active,
      builder: (context, _) {
        final c = active.live;
        if (c == null || active.onScreen || c.botId != botId) {
          return const SizedBox.shrink();
        }
        if (conversationId != null &&
            c.conversationId != null &&
            c.conversationId != conversationId) {
          return const SizedBox.shrink();
        }
        final name = ref.watch(botProvider(botId))?.name ?? '';
        final positive = context.appColors.positive;
        return Material(
          key: const Key('callReturnBar'),
          color: positive.withValues(alpha: 0.14),
          child: InkWell(
            onTap: () => context.pushOnce(callScreenPath(c)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.phone, size: 16, color: positive),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      context.l10n.callReturnBar(name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge,
                    ),
                  ),
                  CallTimerText(
                    call: c,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: positive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

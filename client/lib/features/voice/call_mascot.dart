import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../ui/mascot.dart';
import 'call_motion.dart';

/// The bot on a call: its Casama cloud mascot as a talking Lottie (scripts/casama-call-mascots.py).
/// Each file has two loops, `listening` (a soft smile, blinks, glances and a nod) and `speaking`
/// (the mouth moving in a syllable rhythm, little bounces, the orb pulsing); this plays the one that
/// matches the call. It grows a touch with the bot's voice, fades when muted and turns grey if the
/// call drops. Bots without a mascot get the app icon's lavender cloud. With [animate] off (reduced
/// motion, tests) the mascot's still pose stands in.
class CallMascot extends StatefulWidget {
  const CallMascot({
    super.key,
    required this.mascot,
    required this.motion,
    required this.size,
    this.animate = true,
  });

  /// The bot's mascot, or null for the default cloud.
  final Mascot? mascot;
  final OrbMotion motion;
  final double size;
  final bool animate;

  @override
  State<CallMascot> createState() => _CallMascotState();
}

class _CallMascotState extends State<CallMascot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  LottieComposition? _composition;
  bool? _speaking;
  var _drained = false;
  var _failed = false;

  String get _asset =>
      'assets/mascots/${widget.mascot?.name ?? 'brand'}-call.json';

  void _follow() {
    final phase = widget.motion.phase;
    final drained = phase == OrbPhase.muted || phase == OrbPhase.failed;
    final failed = phase == OrbPhase.failed;
    if (drained != _drained || failed != _failed) {
      setState(() {
        _drained = drained;
        _failed = failed;
      });
    }
    _play(phase == OrbPhase.speaking);
  }

  /// Loops the `speaking` or `listening` part; both start and end in the same pose, so switching
  /// mid-way only cuts to that pose.
  void _play(bool speaking) {
    final c = _composition;
    if (c == null || !widget.animate || speaking == _speaking) return;
    _speaking = speaking;
    final marker = c.getMarker(speaking ? 'speaking' : 'listening');
    if (marker == null) {
      _controller.repeat();
      return;
    }
    _controller
      ..value = marker.start
      ..repeat(
        min: marker.start,
        max: marker.end,
        period: c.duration * (marker.end - marker.start),
      );
  }

  @override
  void initState() {
    super.initState();
    widget.motion.addListener(_follow);
  }

  @override
  void didUpdateWidget(CallMascot old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion) {
      old.motion.removeListener(_follow);
      widget.motion.addListener(_follow);
    }
    if (old.mascot != widget.mascot) {
      _composition = null;
      _speaking = null;
    }
  }

  @override
  void dispose() {
    widget.motion.removeListener(_follow);
    _controller.dispose();
    super.dispose();
  }

  /// Greyscale, for a dropped call.
  static const _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    Widget art = widget.animate
        ? Lottie.asset(
            _asset,
            key: ValueKey(_asset),
            controller: _controller,
            width: size,
            height: size,
            frameRate: FrameRate.max,
            filterQuality: FilterQuality.medium,
            onLoaded: (c) {
              _composition = c;
              _speaking = null;
              _play(widget.motion.phase == OrbPhase.speaking);
            },
            errorBuilder: (context, error, stack) => MascotImage(
              widget.mascot ?? Mascot.winky,
              size: size * .8,
              animate: false,
            ),
          )
        : MascotImage(
            widget.mascot ?? Mascot.winky,
            size: size * .8,
            animate: false,
          );
    art = AnimatedBuilder(
      animation: widget.motion,
      child: RepaintBoundary(child: art),
      builder: (context, child) =>
          Transform.scale(scale: 1 + widget.motion.output * 0.05, child: child),
    );
    if (_failed) art = ColorFiltered(colorFilter: _greyscale, child: art);
    return SizedBox.square(
      dimension: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _drained && !_failed ? 0.55 : 1,
        child: Center(child: art),
      ),
    );
  }
}

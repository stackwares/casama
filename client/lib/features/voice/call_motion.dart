import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// What the call is doing, as the call screen shows it.
enum OrbPhase { connecting, listening, speaking, thinking, muted, failed }

/// The live state behind the call's mascot: a clock and smoothed loudness for each
/// side of the call, updated once per frame. Widgets follow it without rebuilding the screen.
class OrbMotion extends ChangeNotifier {
  /// Seconds since the call screen opened.
  double time = 0;

  /// The person's voice, smoothed (0–1).
  double input = 0;

  /// The bot's voice, smoothed (0–1).
  double output = 0;

  /// How lively the call is overall: eases toward the phase's level so changes never jump.
  double energy = 0.2;

  /// 0–1 while tools run.
  double thinking = 0;

  /// 0–1 when muted or failed.
  double drained = 0;

  OrbPhase phase = OrbPhase.connecting;

  /// Moves the clock to [elapsed] and eases each value toward its target.
  void step(
    Duration elapsed, {
    required double rawInput,
    required double rawOutput,
    required OrbPhase phase,
  }) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - time).clamp(0.0, 0.1);
    time = now;
    this.phase = phase;
    // Rise fast, fall slower: voices read as pulses, not flicker.
    double ease(double v, double target, double up, double down) {
      final rate = target > v ? up : down;
      return v + (target - v) * (1 - math.exp(-rate * dt));
    }

    input = ease(input, rawInput, 18, 5);
    output = ease(output, rawOutput, 22, 6);
    final targetEnergy = switch (phase) {
      OrbPhase.connecting => 0.15,
      OrbPhase.listening => 0.35 + input * 0.4,
      OrbPhase.speaking => 0.55 + output * 0.45,
      OrbPhase.thinking => 0.5,
      OrbPhase.muted => 0.12,
      OrbPhase.failed => 0.0,
    };
    energy = ease(energy, targetEnergy, 4, 2);
    thinking = ease(thinking, phase == OrbPhase.thinking ? 1 : 0, 5, 3);
    drained = ease(
      drained,
      phase == OrbPhase.muted || phase == OrbPhase.failed ? 1 : 0,
      6,
      4,
    );
    notifyListeners();
  }

  /// Shows [phase] without motion (reduced motion, tests).
  void hold({
    required double rawInput,
    required double rawOutput,
    required OrbPhase phase,
  }) {
    this.phase = phase;
    input = rawInput;
    output = rawOutput;
    energy = phase == OrbPhase.speaking ? 0.6 : 0.3;
    thinking = phase == OrbPhase.thinking ? 1 : 0;
    drained = phase == OrbPhase.muted || phase == OrbPhase.failed ? 1 : 0;
    notifyListeners();
  }
}

/// Drives an [OrbMotion] from a ticker. [read] gives the raw loudness and phase each frame. With
/// [animate] off (reduced motion, tests), it settles once and holds still.
class OrbDriver {
  OrbDriver(TickerProvider vsync, this.motion, this.read) {
    _ticker = vsync.createTicker((elapsed) {
      final (i, o, p) = read();
      motion.step(elapsed, rawInput: i, rawOutput: o, phase: p);
    });
  }

  final OrbMotion motion;
  final (double, double, OrbPhase) Function() read;
  late final Ticker _ticker;

  set animate(bool on) {
    if (on && !_ticker.isActive) {
      _ticker.start();
    } else if (!on && _ticker.isActive) {
      _ticker.stop();
    }
    if (!on) {
      final (i, o, p) = read();
      motion.hold(rawInput: i, rawOutput: o, phase: p);
    }
  }

  void dispose() => _ticker.dispose();
}

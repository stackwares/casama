import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../voice/active_call.dart';

/// A live voice call on this computer, as the Mac's notch shows it (D-324, Phase 6; §6 B 13): the
/// bot, how long it has gone on and whether the microphone is muted. The level meter, Mute and End
/// go through [IslandCallControls]. The app's call (D-327's ActiveCall) feeds it through
/// [followActiveCall].
@immutable
class IslandCall {
  const IslandCall({
    required this.botId,
    required this.startedAt,
    this.muted = false,
  });

  final String botId;
  final DateTime startedAt;
  final bool muted;

  IslandCall copyWith({bool? muted}) => IslandCall(
    botId: botId,
    startedAt: startedAt,
    muted: muted ?? this.muted,
  );

  @override
  bool operator ==(Object other) =>
      other is IslandCall &&
      other.botId == botId &&
      other.startedAt == startedAt &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(botId, startedAt, muted);
}

/// What the notch can do to the call.
abstract interface class IslandCallControls {
  /// Mutes the microphone, or unmutes it.
  void toggleMute();

  /// Ends the call, as the screen's own button does (the transcript is saved).
  void hangUp();

  /// How loud the call is now, from 0 to 1: whoever is speaking.
  double get level;
}

/// The call on this computer, if any; the bridge sends it to the notch.
class IslandCallNotifier extends Notifier<IslandCall?> {
  IslandCallControls? _controls;

  IslandCallControls? get controls => _controls;

  @override
  IslandCall? build() => null;

  /// The call is live.
  void live(IslandCall call, IslandCallControls controls) {
    _controls = controls;
    state = call;
  }

  void muted(bool muted) {
    if (!ref.mounted) return;
    final call = state;
    if (call != null && call.muted != muted) {
      state = call.copyWith(muted: muted);
    }
  }

  /// The call ended. Only whoever reported it can clear it.
  void ended(IslandCallControls controls) {
    if (!ref.mounted || !identical(_controls, controls)) return;
    _controls = null;
    state = null;
  }
}

final islandCallProvider = NotifierProvider<IslandCallNotifier, IslandCall?>(
  IslandCallNotifier.new,
);

/// [IslandCallControls] for the app's live call (D-327's [CallController], which outlives the
/// call screen): Mute and Hang up are the call's own, as from the bubble or the menu bar.
class ControllerCallControls implements IslandCallControls {
  ControllerCallControls(this.call);

  final CallController call;

  @override
  void toggleMute() => call.setMuted(!call.muted);

  @override
  void hangUp() => unawaited(call.end(CallEnd.hungUp));

  @override
  double get level {
    final levels = call.call?.levels;
    if (levels == null) {
      // A call that can't measure its audio: a steady level while the bot speaks.
      return (call.call?.speaking.value ?? false) ? 0.5 : 0.0;
    }
    return math.max(call.muted ? 0.0 : levels.input, levels.output).clamp(0.0, 1.0);
  }
}

/// Keeps [islandCallProvider] on the app's live call: set while it's live, cleared when it ends.
/// Leaves alone a call reported some other way. Returns a function that stops following.
void Function() followActiveCall(ActiveCall active, IslandCallNotifier island) {
  void sync() {
    final c = active.live;
    final ours = island.controls is ControllerCallControls ? island.controls as ControllerCallControls : null;
    if (c != null && c.live) {
      final controls = ours?.call == c ? ours! : ControllerCallControls(c);
      island.live(IslandCall(botId: c.botId, startedAt: c.connectedAt ?? DateTime.now(), muted: c.muted), controls);
    } else if (ours != null) {
      island.ended(ours);
    }
  }

  active.addListener(sync);
  sync();
  return () => active.removeListener(sync);
}

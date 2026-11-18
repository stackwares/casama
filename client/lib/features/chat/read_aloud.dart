import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/voice.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bot_avatar.dart';
import 'media/media_kind.dart';

enum ReadAloudPhase { preparing, playing, paused }

/// The reply being read aloud, for the player above the composer and the bubble it lights up.
@immutable
class ReadAloudState {
  const ReadAloudState({
    required this.chatKey,
    required this.messageId,
    required this.name,
    required this.avatar,
    required this.excerpt,
    this.phase = ReadAloudPhase.preparing,
    this.position = Duration.zero,
    this.duration,
    this.speed = 1,
  });

  /// The chat it was started from: only that chat shows the player.
  final String chatKey;
  final String messageId;

  /// Whose voice it is: the bot's name and icon.
  final String name;
  final String? avatar;

  /// The reply's first words, as plain text.
  final String excerpt;
  final ReadAloudPhase phase;
  final Duration position;
  final Duration? duration;
  final double speed;

  double get progress {
    final d = duration?.inMilliseconds ?? 0;
    return d <= 0 ? 0 : (position.inMilliseconds / d).clamp(0, 1).toDouble();
  }

  ReadAloudState copyWith({
    ReadAloudPhase? phase,
    Duration? position,
    Duration? duration,
    double? speed,
  }) => ReadAloudState(
    chatKey: chatKey,
    messageId: messageId,
    name: name,
    avatar: avatar,
    excerpt: excerpt,
    phase: phase ?? this.phase,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
  );
}

/// Read aloud: one reply at a time. Starting another replaces it; reading the same one again
/// pauses or resumes it. Speech for the last few replies is kept, so playing one again starts at
/// once (and costs nothing).
class ReadAloudController extends Notifier<ReadAloudState?> {
  static const speeds = [1.0, 1.25, 1.5, 2.0];
  static const _kept = 6;

  final _audio = <String, Uint8List>{};
  StreamSubscription<SpeechPlayback>? _sub;
  var _run = 0;

  /// Kept across replies, like a podcast app.
  var _speed = 1.0;

  SpeechPlayer get _player => ref.read(speechPlayerProvider);

  @override
  ReadAloudState? build() {
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  /// Reads [messageId] aloud, or pauses/resumes it when it's the one already reading.
  /// [fetch] gets its speech; its errors are the caller's to show.
  Future<void> toggle({
    required String chatKey,
    required String messageId,
    required String name,
    String? avatar,
    required String text,
    required Future<Uint8List> Function() fetch,
  }) async {
    final s = state;
    if (s != null && s.messageId == messageId) {
      if (s.phase == ReadAloudPhase.preparing) return stop();
      return togglePause();
    }
    final run = ++_run;
    await _sub?.cancel();
    _sub = null;
    if (s != null) await _player.stop();
    HapticFeedback.selectionClick();
    state = ReadAloudState(
      chatKey: chatKey,
      messageId: messageId,
      name: name,
      avatar: avatar,
      excerpt: plainExcerpt(text),
      speed: _speed,
    );
    final Uint8List audio;
    try {
      audio = _audio.remove(messageId) ?? await fetch();
    } catch (_) {
      if (run == _run) state = null;
      rethrow;
    }
    if (run != _run) return;
    _audio[messageId] = audio;
    while (_audio.length > _kept) {
      _audio.remove(_audio.keys.first);
    }
    _sub = _player.playback.listen((p) {
      if (run != _run) return;
      if (p.completed) {
        _end();
        return;
      }
      state = state?.copyWith(
        phase: p.playing ? ReadAloudPhase.playing : ReadAloudPhase.paused,
        position: p.position,
        duration: p.duration,
      );
    });
    await _player.setSpeed(_speed);
    await _player.play(audio);
    if (run == _run) state = state?.copyWith(phase: ReadAloudPhase.playing);
  }

  Future<void> togglePause() async {
    final s = state;
    if (s == null || s.phase == ReadAloudPhase.preparing) return;
    final playing = s.phase == ReadAloudPhase.playing;
    // Said at once; the player confirms.
    state = s.copyWith(
      phase: playing ? ReadAloudPhase.paused : ReadAloudPhase.playing,
    );
    await (playing ? _player.pause() : _player.resume());
  }

  Future<void> seekTo(double fraction) async {
    final s = state;
    final d = s?.duration;
    if (s == null || d == null || d <= Duration.zero) return;
    final to = Duration(
      milliseconds: (d.inMilliseconds * fraction.clamp(0, 1)).round(),
    );
    state = s.copyWith(position: to);
    await _player.seek(to);
  }

  Future<void> cycleSpeed() async {
    final s = state;
    if (s == null) return;
    final i = speeds.indexOf(s.speed);
    _speed = speeds[(i + 1) % speeds.length];
    state = s.copyWith(speed: _speed);
    await _player.setSpeed(_speed);
  }

  /// Stops reading. With [chatKey], only when it was started from that chat (a chat closing
  /// doesn't stop one another chat started).
  Future<void> stop({String? chatKey}) async {
    final s = state;
    if (s == null || (chatKey != null && s.chatKey != chatKey)) return;
    _end();
    await _player.stop();
  }

  void _end() {
    _run++;
    unawaited(_sub?.cancel());
    _sub = null;
    state = null;
  }
}

final readAloudProvider =
    NotifierProvider<ReadAloudController, ReadAloudState?>(
      ReadAloudController.new,
    );

final _links = RegExp(r'!?\[([^\]]*)\]\([^)]*\)');
final _marks = RegExp(
  r'(^|\s)(#{1,6}|>|[-*+]|\d+\.)\s+|[*_`~]+',
  multiLine: true,
);

/// A reply's opening as one plain line (no Markdown), for the player.
@visibleForTesting
String plainExcerpt(String markdown) {
  final text = markdown
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAllMapped(_links, (m) => m[1] ?? '')
      .replaceAllMapped(_marks, (m) => m[1] ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.length <= 140 ? text : '${text.substring(0, 140).trimRight()}…';
}

/// The read-aloud player, docked above the composer while a reply from this chat is read: the
/// bot's own icon (its mascot moves while it talks), what it's reading, time left, speed,
/// pause and stop, and a scrubber along its bottom edge. Tapping the words shows the message.
class ReadAloudBar extends ConsumerWidget {
  const ReadAloudBar({super.key, required this.chatKey, this.onShowMessage});
  final String chatKey;
  final ValueChanged<String>? onShowMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(readAloudProvider);
    final shown = s != null && s.chatKey == chatKey;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.duration),
      reverseDuration: AppMotion.of(context, AppMotion.fast),
      switchInCurve: AppMotion.curve,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
      child: shown
          ? Padding(
              key: ValueKey('readAloud-${s.messageId}'),
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: _Player(state: s, onShowMessage: onShowMessage),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({required this.state, this.onShowMessage});
  final ReadAloudState state;
  final ValueChanged<String>? onShowMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final controller = ref.read(readAloudProvider.notifier);
    final s = state;
    final preparing = s.phase == ReadAloudPhase.preparing;
    final playing = s.phase == ReadAloudPhase.playing;
    // The theme's accent, the same one the bubble being read lights up in.
    final accent = scheme.primary;
    final left = s.duration == null ? null : s.duration! - s.position;
    final status = switch (s.phase) {
      ReadAloudPhase.preparing => l10n.readAloudPreparing,
      ReadAloudPhase.paused => l10n.readAloudPaused,
      ReadAloudPhase.playing => l10n.readingAloud,
    };
    final speed =
        '${s.speed.toStringAsFixed(s.speed == s.speed.roundToDouble() ? 0 : 2).replaceAll(RegExp(r'0$'), '')}×';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          key: const Key('readAloudBar'),
          color: context.isDark
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.28),
                context.appColors.hairline,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          shadowColor: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accent.withValues(alpha: context.isDark ? 0.16 : 0.09),
                  accent.withValues(alpha: 0),
                ],
                stops: const [0, 0.6],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xs, 6, 4, 9),
                  child: Row(
                    children: [
                      _SpeakingAvatar(
                        name: s.name,
                        avatar: s.avatar,
                        phase: s.phase,
                        accent: accent,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Semantics(
                          button: onShowMessage != null,
                          label: l10n.readAloudShowMessage,
                          excludeSemantics: false,
                          child: InkWell(
                            key: const Key('readAloudShowMessage'),
                            borderRadius: BorderRadius.circular(AppRadius.row),
                            onTap: onShowMessage == null
                                ? null
                                : () => onShowMessage!(s.messageId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      _Bars(playing: playing, color: accent),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          status,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onSurface,
                                              ),
                                        ),
                                      ),
                                      if (left != null && !preparing) ...[
                                        Text(
                                          '  ·  ${l10n.readAloudTimeLeft(formatClock(left.isNegative ? Duration.zero : left))}',
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontFeatures: AppText.tabular,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    s.excerpt,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: l10n.readAloudSpeed,
                        child: TextButton(
                          key: const Key('readAloudSpeed'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: scheme.onSurfaceVariant,
                            textStyle: context.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppText.tabular,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: controller.cycleSpeed,
                          child: Text(speed),
                        ),
                      ),
                      IconButton.filled(
                        key: const Key('readAloudPlayPause'),
                        tooltip: playing ? l10n.pause : l10n.playMedia,
                        style: IconButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: scheme.onPrimary,
                          disabledBackgroundColor: accent.withValues(
                            alpha: 0.35,
                          ),
                          disabledForegroundColor: scheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                          fixedSize: const Size(40, 40),
                          minimumSize: const Size(40, 40),
                        ),
                        onPressed: preparing ? null : controller.togglePause,
                        icon: AnimatedSwitcher(
                          duration: AppMotion.of(context, AppMotion.fast),
                          transitionBuilder: (child, a) =>
                              ScaleTransition(scale: a, child: child),
                          child: Icon(
                            playing || preparing
                                ? LucideIcons.pause
                                : LucideIcons.play,
                            key: ValueKey(playing || preparing),
                            size: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('readAloudStop'),
                        tooltip: l10n.stopReading,
                        color: scheme.onSurfaceVariant,
                        iconSize: 18,
                        onPressed: controller.stop,
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _Scrubber(
                    progress: s.progress,
                    color: accent,
                    preparing: preparing,
                    onSeek: s.duration == null ? null : controller.seekTo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bot's icon with a soft halo that breathes while it talks, and a ring that spins while its
/// voice is being made. A mascot plays its loop while talking and holds still when paused.
class _SpeakingAvatar extends StatefulWidget {
  const _SpeakingAvatar({
    required this.name,
    required this.avatar,
    required this.phase,
    required this.accent,
  });
  final String name;
  final String? avatar;
  final ReadAloudPhase phase;
  final Color accent;

  @override
  State<_SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<_SpeakingAvatar>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool get _moving =>
      widget.phase == ReadAloudPhase.playing &&
      !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (_moving) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SpeakingAvatar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final on = widget.phase == ReadAloudPhase.playing;
                return CustomPaint(
                  size: const Size.square(46),
                  painter: _HaloPainter(t: t, color: widget.accent, on: on),
                );
              },
            ),
          ),
          if (widget.phase == ReadAloudPhase.preparing)
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.accent,
                strokeCap: StrokeCap.round,
              ),
            ),
          BotAvatar(
            name: widget.name,
            avatar: widget.avatar,
            size: size,
            animate: widget.phase == ReadAloudPhase.playing,
          ),
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.t, required this.color, required this.on});
  final double t;
  final Color color;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    if (!on) return;
    final c = size.center(Offset.zero);
    // Two ripples, half a beat apart.
    for (final phase in [0.0, 0.5]) {
      final p = (t + phase) % 1;
      final r = 17 + p * 7;
      canvas.drawCircle(
        c,
        r,
        Paint()..color = color.withValues(alpha: 0.28 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.t != t || old.on != on || old.color != color;
}

/// Three little level bars that dance while it talks and rest when it doesn't.
class _Bars extends StatefulWidget {
  const _Bars({required this.playing, required this.color});
  final bool playing;
  final Color color;

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  void _sync() {
    if (widget.playing && !MediaQuery.disableAnimationsOf(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Bars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 3,
              height: widget.playing
                  ? 4 +
                        7 *
                            (0.5 +
                                    0.5 *
                                        math.sin(
                                          (_c.value + i * 0.27) * 2 * math.pi,
                                        ))
                                .abs()
                  : 4,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The progress line along the player's bottom edge; tap or drag it to jump. Its touch area is
/// taller than the line.
class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.progress,
    required this.color,
    required this.preparing,
    this.onSeek,
  });
  final double progress;
  final Color color;
  final bool preparing;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final line = SizedBox(
      height: 3,
      child: preparing
          ? LinearProgressIndicator(
              color: color.withValues(alpha: 0.7),
              backgroundColor: color.withValues(alpha: 0.12),
              minHeight: 3,
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: color.withValues(alpha: 0.14)),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        void at(Offset local) => onSeek?.call(local.dx / constraints.maxWidth);
        return GestureDetector(
          key: const Key('readAloudScrubber'),
          behavior: HitTestBehavior.translucent,
          onTapDown: onSeek == null ? null : (d) => at(d.localPosition),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (d) => at(d.localPosition),
          child: Padding(padding: const EdgeInsets.only(top: 9), child: line),
        );
      },
    );
  }
}

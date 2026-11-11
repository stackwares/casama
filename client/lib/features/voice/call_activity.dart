import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/tool_words.dart';
import 'call_motion.dart';

/// Where a tool the bot runs on a call stands.
enum ToolRunState {
  running,
  done,
  failed,
  needsApproval,
  approved,
  declined,
  background,
}

/// One tool the bot ran on a call, as the call screen shows it.
class ToolRun {
  ToolRun({required this.id, required this.name, required this.arguments})
    : started = DateTime.now();

  /// The model's call id.
  final String id;

  /// The wire name (`memory__search`, `start_task`, `mcp__github__create_issue`).
  final String name;
  final Map<String, Object?> arguments;
  final DateTime started;
  ToolRunState state = ToolRunState.running;
  String? approvalId;

  /// Set while Allow/Not now is being sent.
  bool deciding = false;

  bool get settled =>
      state != ToolRunState.running && state != ToolRunState.needsApproval;

  /// `memory.search` style id, used to pick words and an icon.
  String get key => name.replaceAll('__', '.');
}

/// The tools the bot is running on a call, as a short stack of cards (newest at the bottom). Each
/// card says in plain words what's happening and what it's about, spins while it runs, turns into a
/// check when done, and asks right there when an action needs the person's OK. Finished cards fold
/// away on their own (the call screen removes them).
class CallActivity extends StatelessWidget {
  const CallActivity({
    super.key,
    required this.runs,
    required this.motion,
    required this.onDecide,
    this.animate = true,
  });

  final List<ToolRun> runs;

  /// Drives the shimmer and the seconds counter (no timers of its own).
  final OrbMotion motion;
  final void Function(ToolRun run, bool allow) onDecide;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final shown = runs.length > 3 ? runs.sublist(runs.length - 3) : runs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in shown)
          _Entrance(
            key: ValueKey(r.id),
            animate: animate,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: _ToolCard(
                run: r,
                motion: motion,
                onDecide: onDecide,
                animate: animate,
              ),
            ),
          ),
      ],
    );
  }
}

/// Slides and fades a new card in.
class _Entrance extends StatelessWidget {
  const _Entrance({super.key, required this.child, required this.animate});
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        ),
      ),
      child: child,
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.run,
    required this.motion,
    required this.onDecide,
    required this.animate,
  });
  final ToolRun run;
  final OrbMotion motion;
  final void Function(ToolRun run, bool allow) onDecide;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final words = toolWords(l10n, run.name, run.arguments);
    final tint = switch (run.state) {
      ToolRunState.failed || ToolRunState.declined => scheme.error,
      ToolRunState.needsApproval => context.appColors.waiting,
      _ => toolTint(context, words.tone),
    };
    final running = run.state == ToolRunState.running;
    final title = switch (run.state) {
      ToolRunState.running ||
      ToolRunState.needsApproval ||
      ToolRunState.background => words.doing,
      ToolRunState.failed => l10n.callToolFailed,
      _ => words.done,
    };
    final detail = switch (run.state) {
      ToolRunState.approved => l10n.callToolAllowed,
      ToolRunState.declined => l10n.callToolDeclined,
      ToolRunState.background => l10n.callToolBackground,
      _ => run.key == 'start_task' ? l10n.callToolInChat : words.detail,
    };
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: context.isDark ? 0.14 : 0.07),
          scheme.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tint.withValues(
            alpha: run.state == ToolRunState.needsApproval ? 0.55 : 0.22,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Badge(
                run: run,
                icon: words.icon,
                tint: tint,
                motion: motion,
                animate: animate,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Shimmer(
                      on: running && animate,
                      motion: motion,
                      child: Text(
                        title,
                        key: Key('toolTitle-${run.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (detail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (running) _Elapsed(run: run, motion: motion),
            ],
          ),
          // Approvals right in the call: no need to leave it.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child:
                run.state == ToolRunState.needsApproval &&
                    run.approvalId != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.callToolNeedsOk,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: tint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                key: Key('toolAllow-${run.id}'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: tint,
                                  // Amber is light in dark themes: dark text reads better there.
                                  foregroundColor: context.isDark
                                      ? const Color(0xFF231400)
                                      : Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: run.deciding
                                    ? null
                                    : () => onDecide(run, true),
                                child: Text(l10n.callToolAllow),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                key: Key('toolDecline-${run.id}'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: run.deciding
                                    ? null
                                    : () => onDecide(run, false),
                                child: Text(l10n.callToolNotNow),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      label: [title, ?detail].join('. '),
      child: ExcludeSemantics(child: card),
    );
  }
}

/// The tool's icon in a soft disc: a spinning arc around it while it runs, then a check (or a cross,
/// or a shield while it waits for the person) popping in.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.run,
    required this.icon,
    required this.tint,
    required this.motion,
    required this.animate,
  });
  final ToolRun run;
  final IconData icon;
  final Color tint;
  final OrbMotion motion;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (run.state) {
      ToolRunState.done || ToolRunState.approved => LucideIcons.check,
      ToolRunState.failed || ToolRunState.declined => LucideIcons.x,
      ToolRunState.needsApproval => LucideIcons.shieldQuestion,
      ToolRunState.background => LucideIcons.messageSquareShare,
      ToolRunState.running => icon,
    };
    return SizedBox.square(
      dimension: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.16),
            ),
          ),
          if (run.state == ToolRunState.running)
            AnimatedBuilder(
              animation: motion,
              builder: (context, _) => CustomPaint(
                size: const Size.square(36),
                painter: _Arc(
                  color: tint,
                  turn: animate ? motion.time * 1.1 : 0.1,
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, a) => ScaleTransition(
              scale: a,
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Icon(glyph, key: ValueKey(glyph), size: 18, color: tint),
          ),
        ],
      ),
    );
  }
}

class _Arc extends CustomPainter {
  _Arc({required this.color, required this.turn});
  final Color color;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final start = turn * 2 * math.pi;
    canvas.drawArc(
      rect.deflate(1.5),
      start,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + math.pi * 0.9,
          colors: [color.withValues(alpha: 0), color],
          transform: GradientRotation(start),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Arc old) => old.turn != turn || old.color != color;
}

/// A soft light sweeping across the title while the tool runs.
class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.on, required this.motion, required this.child});
  final bool on;
  final OrbMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final base = context.colorScheme.onSurface;
    return AnimatedBuilder(
      animation: motion,
      child: child,
      builder: (context, child) {
        final x = (motion.time * 0.6) % 1.6 - 0.3;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            colors: [base, base.withValues(alpha: 0.45), base],
            stops: [
              (x - 0.18).clamp(0.0, 1.0),
              x.clamp(0.0, 1.0),
              (x + 0.18).clamp(0.0, 1.0),
            ],
          ).createShader(r),
          child: child,
        );
      },
    );
  }
}

/// Seconds since the tool started, once it's taking a while.
class _Elapsed extends StatelessWidget {
  const _Elapsed({required this.run, required this.motion});
  final ToolRun run;
  final OrbMotion motion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        final s = DateTime.now().difference(run.started).inSeconds;
        if (s < 3) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            context.l10n.callToolSeconds(s),
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontFeatures: AppText.tabular,
            ),
          ),
        );
      },
    );
  }
}

/// A light tick when a tool finishes; a firmer one when it needs the person.
void toolHaptic(ToolRunState state) {
  switch (state) {
    case ToolRunState.done:
    case ToolRunState.approved:
      HapticFeedback.selectionClick();
    case ToolRunState.needsApproval:
      HapticFeedback.mediumImpact();
    case ToolRunState.failed:
      HapticFeedback.lightImpact();
    default:
  }
}

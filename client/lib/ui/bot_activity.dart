import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// What a bot needs from you (a count) or, with nothing waiting, that it is working (moving dots).
class BotActivity extends StatelessWidget {
  const BotActivity({super.key, required this.count, required this.working});
  final int count;
  final bool working;

  @override
  Widget build(BuildContext context) {
    if (count > 0) return Semantics(label: context.l10n.botWaitingCount(count), child: ExcludeSemantics(child: CountPill(count)));
    if (!working) return const SizedBox.shrink();
    return const _WorkingDots();
  }
}

/// Three dots rising in turn, like someone typing.
class _WorkingDots extends StatefulWidget {
  const _WorkingDots();

  @override
  State<_WorkingDots> createState() => _WorkingDotsState();
}

class _WorkingDotsState extends State<_WorkingDots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.working;
    return SizedBox(
      key: const Key('botWorking'),
      width: 22,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  // Each dot peaks a third of the cycle after the one before.
                  final t = ((_c.value - i / 3) % 1 + 1) % 1;
                  final lift = t < 0.5 ? math.sin(t * 2 * math.pi) : 0.0;
                  return Transform.translate(
                    offset: Offset(0, -3 * lift.clamp(0, 1)),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.5 + 0.5 * lift.clamp(0, 1)), shape: BoxShape.circle),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: context.colorScheme.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onPrimary, fontWeight: FontWeight.w800, fontFeatures: AppText.tabular),
    ),
  );
}


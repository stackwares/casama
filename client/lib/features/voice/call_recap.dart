import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'call_bubble.dart' show callClock;

/// A call's recap in its chat (D-327 §8): how long it was and what was started on it, each job
/// with how it stood when the call ended and a link to what it did.
class CallRecapCard extends StatelessWidget {
  const CallRecapCard({super.key, required this.call, required this.onOpenRun});
  final MessageCall call;
  final ValueChanged<String> onOpenRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final length = callClock(Duration(seconds: call.seconds));
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.phone, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.callRecapTitle(length),
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
                if (call.tasks.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.callRecapStarted,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  for (final t in call.tasks)
                    _TaskRow(task: t, onOpen: () => onOpenRun(t.runId)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onOpen});
  final MessageCallTask task;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final (icon, tint, state) = switch (task.status) {
      'completed' => (
        LucideIcons.check,
        context.appColors.positive,
        l10n.callRecapTaskDone,
      ),
      'failed' => (LucideIcons.x, scheme.error, l10n.callRecapTaskFailed),
      'cancelled' => (
        LucideIcons.circleStop,
        scheme.onSurfaceVariant,
        l10n.callRecapTaskStopped,
      ),
      _ => (LucideIcons.loader, scheme.primary, l10n.callRecapTaskRunning),
    };
    return InkWell(
      key: Key('callRecapRun-${task.runId}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                  Text(
                    '$state · ${l10n.callRecapOpenRun}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

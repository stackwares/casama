import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/lucide_names.dart';

/// Routine ideas from the open gallery (D-241). Empty when the gallery is off or unreachable.
final routineIdeasProvider = FutureProvider<List<RoutineIdea>>((ref) async {
  try {
    return await ref.watch(backendProvider).routineIdeas();
  } catch (_) {
    return const [];
  }
});

/// A row of ideas over a new routine: a tap fills in its name, instructions and schedule, and
/// everything stays editable. Takes no room when there are none.
class RoutineIdeasStrip extends ConsumerWidget {
  const RoutineIdeasStrip({super.key, required this.onPick});
  final ValueChanged<RoutineIdea> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideas =
        ref.watch(routineIdeasProvider).value ?? const <RoutineIdea>[];
    if (ideas.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.routineIdeas, style: context.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            l10n.routineIdeasHelp,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          SingleChildScrollView(
            key: const Key('routineIdeas'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final idea in ideas)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: Tooltip(
                      message: idea.description,
                      child: ActionChip(
                        key: Key('routineIdea-${idea.id}'),
                        avatar: Icon(
                          lucideByName(idea.icon) ?? LucideIcons.repeat,
                          size: 16,
                        ),
                        label: Text(idea.name),
                        onPressed: () => onPick(idea),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

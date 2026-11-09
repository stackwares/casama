import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Starter bots (persona, skills and routines) to pick from; null means a blank bot.
class TemplatePicker extends ConsumerWidget {
  const TemplatePicker({super.key, required this.selected, required this.onChanged});
  final String? selected;
  final void Function(Template? template) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final templates = ref.watch(templatesProvider).value ?? const <Template>[];
    if (templates.isEmpty) return const SizedBox.shrink();
    Template? current;
    for (final t in templates) {
      if (t.id == selected) current = t;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.startFrom, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 4, children: [
        ChoiceChip(label: Text(l10n.blankBot), selected: selected == null, onSelected: (_) => onChanged(null)),
        for (final t in templates)
          ChoiceChip(
            key: Key('template-${t.id}'),
            label: Text(t.name),
            tooltip: t.description,
            selected: selected == t.id,
            onSelected: (_) => onChanged(t),
          ),
      ]),
      if (current != null) ...[
        const SizedBox(height: 4),
        Text(
          [
            current.description,
            if (current.routines.isNotEmpty) l10n.templateIncludesRoutines(current.routines.map((r) => r.name).join(', ')),
          ].join(' '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ]);
  }
}

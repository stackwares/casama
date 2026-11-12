import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/lucide_names.dart';

/// Reviewed plugins from the open gallery (D-241). Empty when the gallery is off or unreachable.
final pluginDirectoryProvider = FutureProvider<List<DirectoryPlugin>>((
  ref,
) async {
  try {
    return await ref.watch(backendProvider).pluginDirectory();
  } catch (_) {
    return const [];
  }
});

/// The directory above the GitHub link field: a tap previews that plugin at the commit Casama
/// reviewed. Takes no room when there are none.
class PluginDirectoryList extends ConsumerWidget {
  const PluginDirectoryList({
    super.key,
    required this.onPick,
    this.enabled = true,
  });
  final ValueChanged<DirectoryPlugin> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins =
        ref.watch(pluginDirectoryProvider).value ?? const <DirectoryPlugin>[];
    if (plugins.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    return Column(
      key: const Key('pluginDirectory'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.pluginDirectory, style: context.textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(
          l10n.pluginDirectoryHelp,
          style: context.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpace.xs),
        for (final p in plugins)
          ListTile(
            key: Key('directoryPlugin-${p.id}'),
            contentPadding: EdgeInsets.zero,
            enabled: enabled,
            leading: Icon(lucideByName(p.icon) ?? LucideIcons.puzzle),
            title: Text(p.name),
            subtitle: Text(
              [
                p.description,
                p.adds.join(' · '),
                l10n.byAuthor(p.author.name),
              ].join('\n'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: () => onPick(p),
          ),
        const SizedBox(height: AppSpace.xs),
        Text(l10n.pluginOrPaste, style: context.textTheme.labelLarge),
        const SizedBox(height: AppSpace.xs),
      ],
    );
  }
}

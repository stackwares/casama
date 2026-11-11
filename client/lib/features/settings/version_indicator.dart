import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/updater.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// "Casama 0.8.0 (8)" at the foot of Settings: the version and build, so anyone can say which one
/// they're on in a bug report. Dim on purpose; a tap copies it.
class VersionIndicator extends ConsumerWidget {
  const VersionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionLabelProvider).value;
    if (version == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final label = l10n.casamaVersion(version);
    return Tooltip(
      message: l10n.copy,
      child: InkWell(
        key: const Key('appVersion'),
        borderRadius: AppRadius.rowAll,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: label));
          if (context.mounted) showMessage(context, l10n.copied);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(fontFeatures: AppText.tabular, color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.75)),
          ),
        ),
      ),
    );
  }
}

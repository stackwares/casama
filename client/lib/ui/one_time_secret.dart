import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'action_buttons.dart';

/// A key or token that's shown only once: big Copy button, the value in a box you can tap to
/// copy, and Done to put it away. Copying is the main action, so it's the first thing you see.
class OneTimeSecretCard extends StatefulWidget {
  const OneTimeSecretCard({super.key, required this.value, required this.onDone});
  final String value;
  final VoidCallback onDone;

  @override
  State<OneTimeSecretCard> createState() => _OneTimeSecretCardState();
}

class _OneTimeSecretCardState extends State<OneTimeSecretCard> {
  var _copied = false;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
    } catch (_) {
      return;
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    showMessage(context, context.l10n.keyCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final warning = context.appColors.warning;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      borderColor: warning.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          Row(
            children: [
              Icon(LucideIcons.keyRound, size: 20, color: warning),
              const SizedBox(width: AppSpace.xs),
              Expanded(child: Text(l10n.newKeyTitle, style: context.textTheme.titleMedium)),
            ],
          ),
          Text(l10n.newKeyHelp, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          Material(
            color: context.appColors.codeBackground,
            borderRadius: BorderRadius.circular(AppRadius.row),
            child: InkWell(
              key: const Key('oneTimeSecretValue'),
              borderRadius: BorderRadius.circular(AppRadius.row),
              onTap: _copy,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.xs, AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(child: SelectableText(widget.value, style: AppText.mono.copyWith(fontSize: 13))),
                    Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 18, color: _copied ? context.appColors.positive : scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          ActionButtons(
            actions: [
              OutlinedButton(key: const Key('oneTimeSecretDone'), onPressed: widget.onDone, child: Text(l10n.doneLabel)),
              FilledButton.icon(
                key: const Key('oneTimeSecretCopy'),
                onPressed: _copy,
                icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 18),
                label: Text(_copied ? l10n.keyCopied : l10n.copyKey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

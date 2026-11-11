import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/form_sheet.dart';

/// Agent-to-agent (D-140): publish a bot as an A2A agent and share its agent card.
final botA2aProvider = FutureProvider.autoDispose.family<BotA2a, String>((ref, botId) => ref.watch(backendProvider).botA2a(botId));

class BotA2aSheet extends ConsumerWidget {
  const BotA2aSheet({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final a = ref.watch(botA2aProvider(botId)).value;
    return FormSheet(
      icon: LucideIcons.bot,
      title: l10n.a2aPublish,
      subtitle: l10n.a2aPublishHelp,
      submitLabel: l10n.close,
      onSubmit: () => Navigator.pop(context),
      children: [
        if (a == null)
          const LinearProgressIndicator()
        else ...[
          if (!a.workspaceEnabled) FormNote(l10n.a2aWorkspaceOff),
          SwitchListTile(
            key: const Key('a2aPublish'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.a2aPublish),
            value: a.published,
            onChanged: a.workspaceEnabled || a.published
                ? (v) async {
                    await runGuarded(context, () => ref.read(backendProvider).setBotA2a(botId, v));
                    ref.invalidate(botA2aProvider(botId));
                  }
                : null,
          ),
          if (a.published)
            InputDecorator(
              decoration: InputDecoration(labelText: l10n.a2aCardUrl),
              child: Row(
                children: [
                  Expanded(child: SelectableText(a.agentCardUrl, key: const Key('a2aCardUrl'))),
                  IconButton(
                    tooltip: l10n.copy,
                    icon: const Icon(LucideIcons.copy, size: 18),
                    onPressed: () => unawaited(Clipboard.setData(ClipboardData(text: a.agentCardUrl))),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/form_sheet.dart';

/// The full tool name the server uses for a connection's tool (`kind.name.tool`, at most 120
/// characters), as stored in the bot's `call_tools`.
String callToolName(Integration i, String tool) {
  final full =
      '${i.kind.value}.${i.name}.${tool.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
  return full.length > 120 ? full.substring(0, 120) : full;
}

/// Which of a bot's connected-app tools it may use live on calls. Calls already carry a small
/// conversational set and hand bigger jobs to the chat; each tool added here goes with every call,
/// so it adds a little to each call's cost.
class CallToolsSheet extends ConsumerStatefulWidget {
  const CallToolsSheet({super.key, required this.botId, required this.initial});
  final String botId;
  final List<String> initial;

  @override
  ConsumerState<CallToolsSheet> createState() => _CallToolsSheetState();
}

class _CallToolsSheetState extends ConsumerState<CallToolsSheet> {
  late final Set<String> _chosen = {...widget.initial};
  var _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).updateBotVoice(widget.botId, {
        'call_tools': _chosen.toList()..sort(),
      });
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) Navigator.pop(context, _chosen.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final integrations =
        ref.watch(integrationsProvider).value ?? const <Integration>[];
    final attached =
        ref.watch(botIntegrationIdsProvider(widget.botId)).value ??
        const <String>{};
    // Computer-only and other people's local servers can't run on a call.
    final usable = [
      for (final i in integrations)
        if (attached.contains(i.id) &&
            i.kind != IntegrationKind.localMcp &&
            i.tools.isNotEmpty)
          i,
    ];
    return FormSheet(
      icon: LucideIcons.wrench,
      title: l10n.callTools,
      subtitle: l10n.callToolsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveCallTools'),
      busy: _busy,
      onSubmit: _save,
      children: [
        if (usable.isEmpty)
          Text(
            l10n.callToolsNone,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final i in usable) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Text(
                i.name,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final t in i.tools)
              CheckboxListTile(
                key: Key('callTool-${callToolName(i, t.name)}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _chosen.contains(callToolName(i, t.name)),
                onChanged: hapticOnChanged((v) => setState(
                  () => v == true
                      ? _chosen.add(callToolName(i, t.name))
                      : _chosen.remove(callToolName(i, t.name)),
                ), haptic: HapticsHelper.soft),
                title: Text(t.name),
                subtitle: t.description.isEmpty
                    ? null
                    : Text(
                        t.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
          ],
      ],
    );
  }
}

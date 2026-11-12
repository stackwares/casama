import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/remote_config.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';

/// Admin → Services → App settings (D-241): the remote settings every installed app reads, edited
/// as JSON. The server checks them and says what's wrong; the shape is in the self-hosting docs.
class AppSettingsCard extends ConsumerWidget {
  const AppSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: GroupedCard(
        children: [
          GroupedTile(
            key: const Key('adminAppSettings'),
            icon: LucideIcons.slidersHorizontal,
            title: l10n.adminAppSettings,
            subtitle: l10n.adminAppSettingsHelp,
            onTap: () => showAdaptiveSheet<void>(
              context: context,
              heightFactor: 0.9,
              dialogMaxWidth: 720,
              builder: (_) => const _AppSettingsSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsSheet extends ConsumerStatefulWidget {
  const _AppSettingsSheet();

  @override
  ConsumerState<_AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends ConsumerState<_AppSettingsSheet> {
  final _json = TextEditingController();
  var _loaded = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _json.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await runGuarded(
      context,
      () => ref.read(backendProvider).adminAppConfig(),
    );
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (config != null) {
        _json.text = const JsonEncoder.withIndent('  ').convert(config.toJson());
      }
    });
  }

  Future<void> _save() async {
    Object? parsed;
    try {
      parsed = jsonDecode(_json.text);
    } catch (_) {
      setState(() => _error = context.l10n.adminAppSettingsBadJson);
      return;
    }
    if (parsed is! Map<String, dynamic>) {
      setState(() => _error = context.l10n.adminAppSettingsBadJson);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final saved = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .setAdminAppConfig(parsed! as Map<String, dynamic>),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved == null) return;
    // This app follows at once; others within half an hour or when they come back to the front.
    await ref.read(remoteConfigProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.slidersHorizontal,
      title: l10n.adminAppSettings,
      subtitle: l10n.adminAppSettingsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('adminAppSettingsSave'),
      busy: _busy,
      onSubmit: !_loaded || _busy ? null : _save,
      children: [
        TextField(
          key: const Key('adminAppSettingsJson'),
          controller: _json,
          enabled: _loaded,
          minLines: 12,
          maxLines: 24,
          style: context.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ],
    );
  }
}

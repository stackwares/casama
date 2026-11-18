import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';

export '../../core/backend.dart' show AdminJsonSettingKind;

/// Admin rows for the lists the owner edits as JSON without a release (D-373, D-374): the model
/// catalog, the cost tables and the browser guard's added sites. Each opens one editor with the
/// saved value and, folded below it, the built-in values to copy from.
class AdminJsonSettingTile extends StatelessWidget {
  const AdminJsonSettingTile({super.key, required this.kind});
  final AdminJsonSettingKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, help) = switch (kind) {
      AdminJsonSettingKind.modelCatalog => (
        LucideIcons.bookOpen,
        l10n.adminModelCatalog,
        l10n.adminModelCatalogHelp,
      ),
      AdminJsonSettingKind.priceTables => (
        LucideIcons.receipt,
        l10n.adminCostTables,
        l10n.adminCostTablesHelp,
      ),
      AdminJsonSettingKind.browserGuard => (
        LucideIcons.shieldCheck,
        l10n.adminGuardSites,
        l10n.adminGuardSitesHelp,
      ),
    };
    return GroupedTile(
      key: Key('adminJson-${kind.name}'),
      icon: icon,
      title: title,
      subtitle: help,
      onTap: () => showAdaptiveSheet<void>(
        context: context,
        heightFactor: 0.9,
        dialogMaxWidth: 720,
        builder: (_) =>
            _JsonSettingSheet(kind: kind, icon: icon, title: title, help: help),
      ),
    );
  }
}

class _JsonSettingSheet extends ConsumerStatefulWidget {
  const _JsonSettingSheet({
    required this.kind,
    required this.icon,
    required this.title,
    required this.help,
  });
  final AdminJsonSettingKind kind;
  final IconData icon;
  final String title;
  final String help;

  @override
  ConsumerState<_JsonSettingSheet> createState() => _JsonSettingSheetState();
}

class _JsonSettingSheetState extends ConsumerState<_JsonSettingSheet> {
  static const _pretty = JsonEncoder.withIndent('  ');
  final _json = TextEditingController();
  String _builtIn = '';
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
    final setting = await runGuarded(
      context,
      () => ref.read(backendProvider).adminJsonSetting(widget.kind),
    );
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (setting != null) _show(setting);
    });
  }

  void _show(AdminJsonSetting setting) {
    _json.text = _pretty.convert(setting.saved);
    _builtIn = _pretty.convert(setting.builtIn);
  }

  Future<void> _save() async {
    Object? parsed;
    try {
      parsed = jsonDecode(_json.text);
    } catch (_) {
      parsed = null;
    }
    if (parsed is! Map<String, dynamic>) {
      setState(() => _error = context.l10n.adminAppSettingsBadJson);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final value = parsed;
    final saved = await runGuarded(
      context,
      () => ref.read(backendProvider).saveAdminJsonSetting(widget.kind, value),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved != null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mono = context.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return FormSheet(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.help,
      submitLabel: l10n.save,
      submitKey: Key('adminJsonSave-${widget.kind.name}'),
      busy: _busy,
      onSubmit: !_loaded || _busy ? null : _save,
      children: [
        TextField(
          key: Key('adminJsonField-${widget.kind.name}'),
          controller: _json,
          enabled: _loaded,
          minLines: 10,
          maxLines: 20,
          style: mono,
          decoration: InputDecoration(errorText: _error, errorMaxLines: 3),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        if (_builtIn.isNotEmpty)
          ExpansionTile(
            key: Key('adminJsonBuiltIn-${widget.kind.name}'),
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.adminBuiltInValues),
            trailing: IconButton(
              tooltip: l10n.copy,
              icon: const Icon(LucideIcons.copy, size: 18),
              onPressed: () => Clipboard.setData(ClipboardData(text: _builtIn)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: SelectableText(_builtIn, style: mono),
              ),
            ],
          ),
      ],
    );
  }
}

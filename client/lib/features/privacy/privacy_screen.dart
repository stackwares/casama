import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

final _retentionProvider = FutureProvider<int?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? null : ref.watch(backendProvider).retentionDays(org.id);
});

/// Overridable in tests: hands the export to the platform (share sheet, save dialog, download).
final saveExportProvider = Provider<Future<void> Function(Uint8List bytes, String name)>(
  (ref) => (bytes, name) async {
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: 'application/zip')], fileNameOverrides: [name]));
  },
);

/// Privacy (Phase 8, D-072): export your data, delete your account, and workspace retention.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});
  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  var _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    await runGuarded(context, () async {
      final bytes = await ref.read(backendProvider).exportMyData();
      final name = 'kasama-export-${DateTime.now().toIso8601String().substring(0, 10)}.zip';
      await ref.read(saveExportProvider)(bytes, name);
      if (mounted) showMessage(context, l10n.exportReady((bytes.length / 1024).toStringAsFixed(0)));
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final email = ref.read(backendProvider).userEmail ?? '';
    final ok = await showDialog<bool>(context: context, builder: (_) => _ConfirmDelete(email: email));
    if (ok != true || !mounted) return;
    final r = await runGuarded(context, () => ref.read(backendProvider).deleteAccount(email));
    if (r != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l10n.accountDeleted),
          content: Text(l10n.accountDeletedBody(MaterialLocalizations.of(context).formatMediumDate(r.purgeAfter.toLocal()))),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(l10n.close))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    final isAdmin = org != null && org.role != OrgRole.member;
    final retention = ref.watch(_retentionProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacy)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(children: [
          ListTile(
            key: const Key('exportData'),
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.exportMyData),
            subtitle: Text(l10n.exportMyDataHelp),
            trailing: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _export,
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: Text(l10n.runHistoryRetention),
              subtitle: Text(l10n.runHistoryRetentionHelp),
              trailing: retention == null
                  ? null
                  : DropdownButton<int>(
                      key: const Key('retention'),
                      value: [30, 90, 180, 365, 730].contains(retention) ? retention : null,
                      hint: Text(l10n.days(retention)),
                      items: [for (final d in [30, 90, 180, 365, 730]) DropdownMenuItem(value: d, child: Text(l10n.days(d)))],
                      onChanged: (d) async {
                        if (d == null) return;
                        await runGuarded(context, () => ref.read(backendProvider).setRetentionDays(org.id, d));
                        ref.invalidate(_retentionProvider);
                      },
                    ),
            ),
          const Divider(),
          ListTile(
            key: const Key('deleteAccount'),
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: Text(l10n.deleteAccountHelp),
            onTap: _delete,
          ),
        ]),
      ),
    );
  }
}

class _ConfirmDelete extends StatefulWidget {
  const _ConfirmDelete({required this.email});
  final String email;
  @override
  State<_ConfirmDelete> createState() => _ConfirmDeleteState();
}

class _ConfirmDeleteState extends State<_ConfirmDelete> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = _c.text.trim().toLowerCase() == widget.email.toLowerCase();
    return AlertDialog(
      title: Text(l10n.deleteAccountQuestion),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.deleteAccountConfirm(widget.email)),
        const SizedBox(height: 12),
        TextField(key: const Key('confirmEmail'), controller: _c, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.email)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('confirmDelete'),
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: matches ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }
}

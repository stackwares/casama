import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Named secrets bots reference as {{secret:NAME}}; each is only sent to its allowed hosts.
class SecretsScreen extends ConsumerWidget {
  const SecretsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String, List<String>)>(context: context, builder: (_) => const _AddSecretDialog());
    if (result == null || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    await runGuarded(context, () => ref.read(backendProvider).createSecret(org.id, name: result.$1, value: result.$2, hosts: result.$3));
    ref.invalidate(secretsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.secrets)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addSecret'),
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSecret),
      ),
      body: AsyncView(
        value: ref.watch(secretsProvider),
        onRetry: () => ref.invalidate(secretsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.lock_outline, message: l10n.noSecrets)
            : ListView(children: [
                for (final s in items)
                  ListTile(
                    key: Key('secret-${s.id}'),
                    leading: const Icon(Icons.lock_outline),
                    title: Text(s.name),
                    subtitle: Text(l10n.onlySentTo(s.allowedHosts.join(', '))),
                    trailing: IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await runGuarded(context, () => ref.read(backendProvider).deleteSecret(s.id));
                        ref.invalidate(secretsProvider);
                      },
                    ),
                  ),
              ]),
      ),
    );
  }
}

class _AddSecretDialog extends StatefulWidget {
  const _AddSecretDialog();

  @override
  State<_AddSecretDialog> createState() => _AddSecretDialogState();
}

class _AddSecretDialogState extends State<_AddSecretDialog> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _hosts = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _hosts.dispose();
    super.dispose();
  }

  List<String> get _hostList => _hosts.text.split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(_name.text) && _value.text.isNotEmpty && _hostList.isNotEmpty;
    return AlertDialog(
      title: Text(l10n.addSecret),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            key: const Key('secretName'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.secretName, helperText: l10n.secretNameHelp),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const Key('secretValue'),
            controller: _value,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.secretValue),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const Key('secretHosts'),
            controller: _hosts,
            decoration: InputDecoration(labelText: l10n.allowedHosts, helperText: l10n.allowedHostsHelp),
            onChanged: (_) => setState(() {}),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('saveSecret'),
          onPressed: valid ? () => Navigator.pop(context, (_name.text, _value.text, _hostList)) : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

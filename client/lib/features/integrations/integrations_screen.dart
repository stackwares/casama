import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

String integrationKindLabel(BuildContext context, IntegrationKind kind) => switch (kind) {
      IntegrationKind.mcp => context.l10n.kindMcp,
      IntegrationKind.openapi => context.l10n.kindOpenapi,
      IntegrationKind.composio => 'Composio',
      IntegrationKind.pipedream => 'Pipedream Connect',
    };

/// Workspace integrations: MCP servers, OpenAPI sources, Composio and Pipedream Connect.
class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.integrations)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addIntegration'),
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const AddIntegrationSheet(),
          );
          if (added == true) ref.invalidate(integrationsProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addIntegration),
      ),
      body: AsyncView(
        value: ref.watch(integrationsProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.extension_outlined, message: l10n.noIntegrations)
            : ListView(children: [
                for (final i in items)
                  ListTile(
                    key: Key('integration-${i.id}'),
                    leading: Icon(
                      switch (i.status) {
                        IntegrationStatusEnum.ok => Icons.check_circle_outline,
                        IntegrationStatusEnum.error => Icons.error_outline,
                        IntegrationStatusEnum.pending => Icons.pending_outlined,
                      },
                      color: i.status == IntegrationStatusEnum.error ? Theme.of(context).colorScheme.error : null,
                    ),
                    title: Text(i.name),
                    subtitle: Text([
                      integrationKindLabel(context, i.kind),
                      if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length),
                      if (i.error != null) i.error!,
                    ].join(' · ')),
                    trailing: TextButton(
                      key: Key('testIntegration-${i.id}'),
                      onPressed: () async {
                        final r = await runGuarded(context, () => ref.read(backendProvider).testIntegration(i.id));
                        if (r == null || !context.mounted) return;
                        ref.invalidate(integrationsProvider);
                        showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error ?? ''));
                      },
                      child: Text(l10n.test),
                    ),
                  ),
              ]),
      ),
    );
  }
}

class AddIntegrationSheet extends ConsumerStatefulWidget {
  const AddIntegrationSheet({super.key});

  @override
  ConsumerState<AddIntegrationSheet> createState() => _AddIntegrationSheetState();
}

class _AddIntegrationSheetState extends ConsumerState<AddIntegrationSheet> {
  var _kind = IntegrationKind.mcp;
  final _name = TextEditingController();
  // mcp: url; openapi: spec url; composio: toolkits; pipedream: project id
  final _primary = TextEditingController();
  // openapi: base url; pipedream: client id
  final _secondary = TextEditingController();
  // pipedream: apps
  final _apps = TextEditingController();
  final _secret = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _primary, _secondary, _apps, _secret]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _list(String s) => s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, Object?> _config() => switch (_kind) {
        IntegrationKind.mcp => {'url': _primary.text.trim()},
        IntegrationKind.openapi => {
            'spec': _primary.text.trim(),
            if (_secondary.text.trim().isNotEmpty) 'base_url': _secondary.text.trim(),
            // OpenAPI auth comes from a named secret so it obeys that secret's host allowlist.
            if (_secret.text.trim().isNotEmpty) 'auth': {'type': 'bearer', 'secret': _secret.text.trim()},
          },
        IntegrationKind.composio => {'toolkits': _list(_primary.text)},
        IntegrationKind.pipedream => {
            'project_id': _primary.text.trim(),
            'client_id': _secondary.text.trim(),
            'apps': _list(_apps.text),
          },
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (primaryLabel, secondaryLabel, secretLabel) = switch (_kind) {
      IntegrationKind.mcp => (l10n.serverUrl, null, l10n.authHeaderOptional),
      IntegrationKind.openapi => (l10n.specUrl, l10n.baseUrlOptional, l10n.authSecretName),
      IntegrationKind.composio => (l10n.composioToolkits, null, l10n.apiKey),
      IntegrationKind.pipedream => (l10n.pipedreamProject, l10n.pipedreamClientId, l10n.pipedreamClientSecret),
    };
    final nameOk = RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(_name.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.addIntegration, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<IntegrationKind>(
            key: const Key('integrationKind'),
            initialValue: _kind,
            decoration: InputDecoration(labelText: l10n.integrationType),
            items: [for (final k in IntegrationKind.values) DropdownMenuItem(value: k, child: Text(integrationKindLabel(context, k)))],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('integrationName'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.integrationName, helperText: l10n.integrationNameHelp),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('integrationPrimary'),
            controller: _primary,
            decoration: InputDecoration(labelText: primaryLabel),
            onChanged: (_) => setState(() {}),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TextField(controller: _secondary, decoration: InputDecoration(labelText: secondaryLabel)),
          ],
          if (_kind == IntegrationKind.pipedream) ...[
            const SizedBox(height: 8),
            TextField(controller: _apps, decoration: InputDecoration(labelText: l10n.pipedreamApps)),
          ],
          const SizedBox(height: 8),
          TextField(
            key: const Key('integrationSecret'),
            controller: _secret,
            obscureText: _kind != IntegrationKind.openapi,
            decoration: InputDecoration(
              labelText: secretLabel,
              helperText: _kind == IntegrationKind.openapi ? l10n.authSecretNameHelp : l10n.storedEncrypted,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('saveIntegration'),
            onPressed: _busy || !nameOk || _primary.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => _busy = true);
                    final org = ref.read(currentOrgProvider)!;
                    final backend = ref.read(backendProvider);
                    final created = await runGuarded(context, () async {
                      final i = await backend.createIntegration(
                        org.id,
                        kind: _kind.value,
                        name: _name.text,
                        config: _config(),
                        secret: _secret.text.isEmpty || _kind == IntegrationKind.openapi ? null : _secret.text,
                      );
                      // Prove the connection and cache tools right away; failures show on the list.
                      try {
                        await backend.testIntegration(i.id);
                      } catch (_) {}
                      return i;
                    });
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (created != null) Navigator.of(context).pop(true);
                  },
            child: Text(l10n.save),
          ),
        ]),
      ),
    );
  }
}

/// Which integrations one bot may use.
class BotIntegrationsScreen extends ConsumerWidget {
  const BotIntegrationsScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attached = ref.watch(botIntegrationIdsProvider(botId)).value ?? const <String>{};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.botIntegrations)),
      body: AsyncView(
        value: ref.watch(integrationsProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.extension_outlined, message: l10n.noIntegrationsForBot)
            : ListView(children: [
                for (final i in items)
                  SwitchListTile(
                    key: Key('attach-${i.id}'),
                    title: Text(i.name),
                    subtitle: Text(integrationKindLabel(context, i.kind)),
                    value: attached.contains(i.id),
                    onChanged: (v) async {
                      await runGuarded(context, () => ref.read(backendProvider).setBotIntegration(botId, i.id, v));
                      ref.invalidate(botIntegrationIdsProvider(botId));
                    },
                  ),
              ]),
      ),
    );
  }
}

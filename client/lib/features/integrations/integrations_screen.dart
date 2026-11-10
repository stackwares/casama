import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';

String integrationKindLabel(BuildContext context, IntegrationKind kind) => switch (kind) {
  IntegrationKind.mcp => context.l10n.kindMcp,
  IntegrationKind.openapi => context.l10n.kindOpenapi,
  IntegrationKind.composio => 'Composio',
  IntegrationKind.pipedream => 'Pipedream Connect',
};

IconData integrationKindIcon(IntegrationKind kind) => switch (kind) {
  IntegrationKind.mcp => Icons.hub_outlined,
  IntegrationKind.openapi => Icons.api_rounded,
  IntegrationKind.composio => Icons.widgets_outlined,
  IntegrationKind.pipedream => Icons.cable_rounded,
};

/// Workspace integrations: MCP servers, OpenAPI sources, Composio and Pipedream Connect.
class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showAdaptiveSheet<bool>(context: context, builder: (_) => const AddIntegrationSheet());
    if (added == true) ref.invalidate(integrationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.integrations,
      actions: [HeaderIconButton(key: const Key('addIntegration'), icon: Icons.add_rounded, tooltip: l10n.addIntegration, onPressed: () => _add(context, ref))],
      body: AsyncView(
        value: ref.watch(integrationsProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.extension_outlined,
                title: l10n.noIntegrationsTitle,
                message: l10n.noIntegrations,
                action: FilledButton.icon(onPressed: () => _add(context, ref), icon: const Icon(Icons.add_rounded, size: 18), label: Text(l10n.addIntegration)),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.integrationsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(children: [for (final i in items) _IntegrationRow(integration: i)]),
                ],
              ),
      ),
    );
  }
}

class _IntegrationRow extends ConsumerStatefulWidget {
  const _IntegrationRow({required this.integration});
  final Integration integration;

  @override
  ConsumerState<_IntegrationRow> createState() => _IntegrationRowState();
}

class _IntegrationRowState extends ConsumerState<_IntegrationRow> {
  var _testing = false;

  Future<void> _test() async {
    final l10n = context.l10n;
    setState(() => _testing = true);
    final r = await runGuarded(context, () => ref.read(backendProvider).testIntegration(widget.integration.id));
    if (!mounted) return;
    setState(() => _testing = false);
    if (r == null) return;
    ref.invalidate(integrationsProvider);
    showMessage(context, r.ok ? l10n.integrationOk(r.tools.length) : l10n.integrationFailed(r.error ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final i = widget.integration;
    final (statusText, statusColor) = switch (i.status) {
      IntegrationStatusEnum.ok => (l10n.keyWorking, colors.positive),
      IntegrationStatusEnum.error => (l10n.keyFailing, colors.negative),
      IntegrationStatusEnum.pending => (l10n.keyUntested, context.colorScheme.onSurfaceVariant),
    };
    return GroupedTile(
      key: Key('integration-${i.id}'),
      icon: integrationKindIcon(i.kind),
      iconColor: i.status == IntegrationStatusEnum.error ? colors.negative : null,
      title: i.name,
      subtitle: [integrationKindLabel(context, i.kind), if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length), if (i.error != null) i.error!].join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusLabel(text: statusText, color: statusColor, pill: true),
          const SizedBox(width: AppSpace.xxs),
          _testing
              ? const SizedBox(
                  width: 56,
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : TextButton(key: Key('testIntegration-${i.id}'), onPressed: _test, child: Text(l10n.test)),
        ],
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
  var _showSecret = false;

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
    IntegrationKind.pipedream => {'project_id': _primary.text.trim(), 'client_id': _secondary.text.trim(), 'apps': _list(_apps.text)},
  };

  Future<void> _save(String name) async {
    setState(() => _busy = true);
    final org = ref.read(currentOrgProvider)!;
    final backend = ref.read(backendProvider);
    final created = await runGuarded(context, () async {
      final i = await backend.createIntegration(
        org.id,
        kind: _kind.value,
        name: name,
        config: _config(),
        secret: _secret.text.isEmpty || _kind == IntegrationKind.openapi ? null : _secret.text,
      );
      // Prove the connection and cache tools right away; failures show on the list.
      try {
        await backend.testIntegration(i.id);
      } catch (_) {}
      return i;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (created != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (primaryLabel, secondaryLabel, secretLabel) = switch (_kind) {
      IntegrationKind.mcp => (l10n.serverUrl, null, l10n.authHeaderOptional),
      IntegrationKind.openapi => (l10n.specUrl, l10n.baseUrlOptional, l10n.authSecretName),
      IntegrationKind.composio => (l10n.composioToolkits, null, l10n.apiKey),
      IntegrationKind.pipedream => (l10n.pipedreamProject, l10n.pipedreamClientId, l10n.pipedreamClientSecret),
    };
    final name = integrationSlug(_name.text);
    final nameOk = RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(name);
    final primary = _primary.text.trim();
    final needsUrl = _kind == IntegrationKind.mcp || _kind == IntegrationKind.openapi;
    final primaryOk = primary.isNotEmpty && (!needsUrl || RegExp(r'^https?://').hasMatch(primary));
    // Say what is missing instead of leaving a disabled button unexplained.
    final missing = !nameOk ? l10n.integrationNeedsName : (!primaryOk ? l10n.integrationNeedsField(primaryLabel) : null);
    final secretIsName = _kind == IntegrationKind.openapi;
    return FormSheet(
      icon: Icons.extension_outlined,
      title: l10n.addIntegration,
      subtitle: l10n.integrationsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveIntegration'),
      busy: _busy,
      onSubmit: missing != null ? null : () => _save(name),
      footer: missing == null || _name.text.isEmpty ? null : FormNote(missing),
      children: [
        DropdownButtonFormField<IntegrationKind>(
          key: const Key('integrationKind'),
          initialValue: _kind,
          decoration: InputDecoration(labelText: l10n.integrationType, prefixIcon: Icon(integrationKindIcon(_kind), size: 20)),
          items: [for (final k in IntegrationKind.values) DropdownMenuItem(value: k, child: Text(integrationKindLabel(context, k)))],
          onChanged: (v) => setState(() => _kind = v ?? _kind),
        ),
        TextField(
          key: const Key('integrationName'),
          controller: _name,
          decoration: InputDecoration(
            labelText: l10n.integrationName,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            helperText: _name.text.trim().isEmpty ? l10n.integrationNameHelp : (nameOk ? l10n.integrationSavedAs(name) : l10n.integrationNeedsName),
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const Key('integrationPrimary'),
          controller: _primary,
          keyboardType: needsUrl ? TextInputType.url : TextInputType.text,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: primaryLabel,
            hintText: needsUrl ? 'https://' : null,
            prefixIcon: Icon(needsUrl ? Icons.link_rounded : Icons.list_alt_rounded, size: 20),
            errorText: primary.isNotEmpty && !primaryOk ? l10n.integrationUrlInvalid : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (secondaryLabel != null)
          TextField(
            controller: _secondary,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: secondaryLabel,
              prefixIcon: Icon(_kind == IntegrationKind.openapi ? Icons.dns_outlined : Icons.badge_outlined, size: 20),
            ),
          ),
        if (_kind == IntegrationKind.pipedream)
          TextField(
            controller: _apps,
            decoration: InputDecoration(labelText: l10n.pipedreamApps, prefixIcon: const Icon(Icons.apps_rounded, size: 20)),
          ),
        TextField(
          key: const Key('integrationSecret'),
          controller: _secret,
          obscureText: !secretIsName && !_showSecret,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: secretLabel,
            prefixIcon: Icon(secretIsName ? Icons.lock_outline_rounded : Icons.password_rounded, size: 20),
            helperText: secretIsName ? l10n.authSecretNameHelp : l10n.storedEncrypted,
            suffixIcon: secretIsName
                ? null
                : IconButton(
                    tooltip: _showSecret ? l10n.hide : l10n.show,
                    icon: Icon(_showSecret ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _showSecret = !_showSecret),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Tool names are prefixed with the integration's name, so it must be a short identifier:
/// "GitHub tools" is saved as "github_tools".
String integrationSlug(String name) {
  var out = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  out = out.replaceAll(RegExp(r'^_+|_+$'), '');
  if (out.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(out)) out = 'x_$out';
  return out.length > 40 ? out.substring(0, 40).replaceAll(RegExp(r'_+$'), '') : out;
}

/// Which integrations one bot may use.
class BotIntegrationsScreen extends ConsumerWidget {
  const BotIntegrationsScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final attached = ref.watch(botIntegrationIdsProvider(botId)).value ?? const <String>{};
    final bot = ref.watch(botProvider(botId));

    Future<void> set(Integration i, bool v) async {
      await runGuarded(context, () => ref.read(backendProvider).setBotIntegration(botId, i.id, v));
      ref.invalidate(botIntegrationIdsProvider(botId));
    }

    return SubPage(
      title: l10n.integrations,
      subtitle: bot?.name,
      body: AsyncView(
        value: ref.watch(integrationsProvider),
        onRetry: () => ref.invalidate(integrationsProvider),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.extension_outlined,
                title: l10n.noIntegrationsTitle,
                message: l10n.noIntegrationsForBot,
                action: FilledButton.tonalIcon(
                  onPressed: () => context.push('/settings/integrations'),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(l10n.openSettings),
                ),
              )
            : PageColumn(
                children: [
                  FormNote(l10n.botIntegrationsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final i in items)
                        GroupedTile(
                          key: Key('attach-${i.id}'),
                          icon: integrationKindIcon(i.kind),
                          iconColor: attached.contains(i.id) ? null : context.colorScheme.onSurfaceVariant,
                          title: i.name,
                          subtitle: [integrationKindLabel(context, i.kind), if (i.tools.isNotEmpty) l10n.toolCount(i.tools.length)].join(' · '),
                          onTap: () => set(i, !attached.contains(i.id)),
                          trailing: Switch(value: attached.contains(i.id), onChanged: (v) => set(i, v)),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

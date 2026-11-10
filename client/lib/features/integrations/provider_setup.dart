import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import 'app_logo.dart';

enum ProviderKind { composio, pipedream }

extension on ProviderKind {
  String get label => this == ProviderKind.composio ? 'Composio' : 'Pipedream';
  String get keyUrl => this == ProviderKind.composio ? 'https://platform.composio.dev' : 'https://pipedream.com/settings/api';
  IconData get icon => this == ProviderKind.composio ? LucideIcons.blocks : LucideIcons.cable;
}

/// Sets up Composio or Pipedream in two steps: a key (with a link to get one free), then the apps
/// to sign in to. If one already exists, goes straight to its page.
Future<void> showProviderSetup(BuildContext context, ProviderKind kind) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final existing = (container.read(integrationsProvider).value ?? const <Integration>[])
      .where((i) => i.kind.value == kind.name)
      .firstOrNull;
  if (existing != null) {
    await context.push('/settings/integrations/${existing.id}');
    return;
  }
  final created = await showAdaptiveSheet<Integration>(context: context, builder: (_) => _ProviderKeyForm(kind: kind));
  if (created == null || !context.mounted) return;
  await context.push('/settings/integrations/${created.id}');
  if (context.mounted) await showProviderAppPicker(context, created);
}

class _ProviderKeyForm extends ConsumerStatefulWidget {
  const _ProviderKeyForm({required this.kind});
  final ProviderKind kind;

  @override
  ConsumerState<_ProviderKeyForm> createState() => _ProviderKeyFormState();
}

class _ProviderKeyFormState extends ConsumerState<_ProviderKeyForm> {
  final _key = TextEditingController();
  final _project = TextEditingController();
  final _client = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _key.dispose();
    _project.dispose();
    _client.dispose();
    super.dispose();
  }

  bool get _pipedream => widget.kind == ProviderKind.pipedream;
  bool get _valid => _key.text.trim().length >= 8 && (!_pipedream || (_project.text.trim().isNotEmpty && _client.text.trim().isNotEmpty));

  Future<void> _save() async {
    setState(() => _busy = true);
    final org = ref.read(currentOrgProvider)!;
    final backend = ref.read(backendProvider);
    final created = await runGuarded(context, () async {
      final i = await backend.createIntegration(
        org.id,
        kind: widget.kind.name,
        name: widget.kind.name,
        config: _pipedream ? {'project_id': _project.text.trim(), 'client_id': _client.text.trim(), 'apps': <String>[]} : {'toolkits': <String>[]},
        secret: _key.text.trim(),
      );
      // Checks the key works; an empty app list is fine at this point.
      try {
        await backend.testIntegration(i.id);
      } catch (_) {}
      return i;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(integrationsProvider);
    if (created != null) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final k = widget.kind;
    Widget field(TextEditingController c, String label, IconData icon, {bool secret = false, Key? key}) => TextField(
          key: key,
          controller: c,
          obscureText: secret,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: IconButton(
              tooltip: l10n.pasteLabel,
              icon: const Icon(LucideIcons.clipboardPaste, size: 18),
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                if (d?.text != null) setState(() => c.text = d!.text!.trim());
              },
            ),
          ),
          onChanged: (_) => setState(() {}),
        );
    return FormSheet(
      icon: k.icon,
      title: l10n.providerSetupTitle(k.label),
      subtitle: l10n.providerSetupHelp(k.label),
      submitLabel: l10n.connect,
      submitKey: const Key('saveProvider'),
      busy: _busy,
      onSubmit: _valid ? _save : null,
      children: [
        OutlinedButton.icon(
          key: const Key('getProviderKey'),
          onPressed: () => launchUrl(Uri.parse(k.keyUrl), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank'),
          icon: const Icon(LucideIcons.externalLink, size: 16),
          label: Text('${l10n.getFreeKey} · ${k.label}'),
        ),
        if (_pipedream) ...[
          field(_project, l10n.projectId, LucideIcons.folder),
          field(_client, l10n.pipedreamClientId, LucideIcons.idCard),
          field(_key, l10n.pipedreamClientSecret, LucideIcons.keyRound, secret: true, key: const Key('providerKey')),
        ] else
          field(_key, l10n.apiKey, LucideIcons.keyRound, secret: true, key: const Key('providerKey')),
        FormNote(l10n.storedEncrypted, icon: LucideIcons.shieldCheck),
      ],
    );
  }
}

/// Picks an app from Composio's or Pipedream's directory and opens its sign-in page.
Future<void> showProviderAppPicker(BuildContext context, Integration integration) =>
    showAdaptiveSheet<void>(context: context, heightFactor: 0.88, builder: (_) => _ProviderAppPicker(integration: integration));

class _ProviderAppPicker extends ConsumerStatefulWidget {
  const _ProviderAppPicker({required this.integration});
  final Integration integration;

  @override
  ConsumerState<_ProviderAppPicker> createState() => _ProviderAppPickerState();
}

class _ProviderAppPickerState extends ConsumerState<_ProviderAppPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  late Future<List<ProviderApp>> _apps = _load();
  String? _opening;

  Future<List<ProviderApp>> _load() => ref.read(backendProvider).providerApps(widget.integration.id, query: _search.text);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _connect(ProviderApp app) async {
    setState(() => _opening = app.slug);
    final url = await runGuarded(context, () => ref.read(backendProvider).connectProviderApp(widget.integration.id, app.slug));
    if (!mounted) return;
    setState(() => _opening = null);
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    ref.invalidate(providerAccountsProvider(widget.integration.id));
    ref.invalidate(integrationsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final label = widget.integration.kind == IntegrationKind.composio ? 'Composio' : 'Pipedream';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addAnApp, style: context.textTheme.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('providerAppSearch'),
            controller: _search,
            decoration: InputDecoration(hintText: l10n.searchProviderApps(label), prefixIcon: const Icon(LucideIcons.search, size: 20)),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _apps = _load()));
            },
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: FutureBuilder<List<ProviderApp>>(
              future: _apps,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: FormNote(errorText(context, snap.error!), icon: LucideIcons.triangleAlert));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!;
                if (items.isEmpty) return Center(child: Text(l10n.noThemesFound, style: context.textTheme.bodyMedium));
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: context.appColors.hairline),
                  itemBuilder: (_, i) {
                    final a = items[i];
                    return ListTile(
                      key: Key('providerApp-${a.slug}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                      leading: AppLogo(name: a.name, imageUrl: a.logo, size: 40),
                      title: Text(a.name),
                      subtitle: a.description.isEmpty
                          ? null
                          : Text(a.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
                      trailing: _opening == a.slug
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : FilledButton.tonal(onPressed: () => _connect(a), child: Text(l10n.connect)),
                      onTap: () => _connect(a),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final providerAccountsProvider = FutureProvider.family<List<ProviderAccount>, String>(
  (ref, integrationId) => ref.watch(backendProvider).providerAccounts(integrationId),
);

/// The apps signed in through Composio or Pipedream, and a button to add one.
class ProviderAccountsCard extends ConsumerWidget {
  const ProviderAccountsCard({super.key, required this.integration});
  final Integration integration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final accounts = ref.watch(providerAccountsProvider(integration.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        accounts.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpace.md), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => FormNote(errorText(context, e), icon: LucideIcons.triangleAlert),
          data: (items) => items.isEmpty
              ? FormNote(l10n.noProviderAccounts)
              : GroupedCard(
                  children: [
                    for (final a in items)
                      GroupedTile(
                        icon: LucideIcons.appWindow,
                        leading: AppLogo(name: a.app, size: 32),
                        title: a.app,
                        trailing: StatusLabel(
                          text: switch (a.status) {
                            ProviderAccountStatusEnum.connected => l10n.accountConnected,
                            ProviderAccountStatusEnum.pending => l10n.accountPending,
                            ProviderAccountStatusEnum.error => l10n.accountError,
                          },
                          color: switch (a.status) {
                            ProviderAccountStatusEnum.connected => colors.positive,
                            ProviderAccountStatusEnum.pending => colors.warning,
                            ProviderAccountStatusEnum.error => colors.negative,
                          },
                          pill: true,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GlowButton.icon(
            key: const Key('providerAddApp'),
            onPressed: () async {
              await showProviderAppPicker(context, integration);
              ref.invalidate(providerAccountsProvider(integration.id));
            },
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.addAnApp),
          ),
        ),
      ],
    );
  }
}

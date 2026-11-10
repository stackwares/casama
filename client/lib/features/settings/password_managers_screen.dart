import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// Password managers (D-128): 1Password or Bitwarden, for the workspace or just you, and the
/// vaults bots may use. Bots never see passwords.
final passwordManagersProvider = FutureProvider.autoDispose<List<PasswordManager>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).passwordManagers(org.id);
});

class PasswordManagersScreen extends ConsumerWidget {
  const PasswordManagersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    Future<void> add() async {
      final org = ref.read(currentOrgProvider);
      if (org == null) return;
      final pm = await showAdaptiveSheet<PasswordManager>(context: context, builder: (_) => _Connect(orgId: org.id));
      ref.invalidate(passwordManagersProvider);
      if (pm != null && context.mounted) await showAdaptiveSheet<void>(context: context, builder: (_) => _Vaults(manager: pm));
      ref.invalidate(passwordManagersProvider);
    }

    return SubPage(
      title: l10n.passwordManagers,
      actions: [IconButton(key: const Key('addPasswordManager'), tooltip: l10n.connectPasswordManager, icon: const Icon(LucideIcons.plus), onPressed: add)],
      body: AsyncView(
        value: ref.watch(passwordManagersProvider),
        onRetry: () => ref.invalidate(passwordManagersProvider),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.keyRound, title: l10n.noPasswordManagers, message: l10n.passwordManagersHelp, action: FilledButton(onPressed: add, child: Text(l10n.connectPasswordManager)))
            : PageColumn(
                children: [
                  FormNote(l10n.passwordManagersHelp, icon: LucideIcons.lock),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final m in items)
                        GroupedTile(
                          key: Key('pm-${m.id}'),
                          icon: LucideIcons.keyRound,
                          title: m.name,
                          subtitle: [
                            m.provider == PasswordManagerProviderEnum.n1password ? '1Password' : 'Bitwarden',
                            m.scope == PasswordManagerScopeEnum.workspace ? l10n.pmWorkspace : l10n.pmJustMe,
                            m.allowedVaults.isEmpty ? l10n.pmNoVaults : l10n.pmVaults(m.allowedVaults.length),
                            if (m.lastError != null) m.lastError!,
                          ].join(' · '),
                          onTap: () async {
                            await showAdaptiveSheet<void>(context: context, builder: (_) => _Vaults(manager: m));
                            ref.invalidate(passwordManagersProvider);
                          },
                          trailing: IconButton(
                            key: Key('deletePm-${m.id}'),
                            tooltip: l10n.delete,
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            onPressed: () async {
                              await runGuarded(context, () => backend.deletePasswordManager(m.id));
                              ref.invalidate(passwordManagersProvider);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _Connect extends ConsumerStatefulWidget {
  const _Connect({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_Connect> createState() => _ConnectState();
}

class _ConnectState extends ConsumerState<_Connect> {
  var _provider = CreatePasswordManagerRequestProviderEnum.n1password;
  var _workspace = false;
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _token = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = ref.watch(currentOrgProvider)?.role.value;
    final admin = role == 'owner' || role == 'admin';
    final onePw = _provider == CreatePasswordManagerRequestProviderEnum.n1password;
    final valid = _name.text.trim().isNotEmpty && Uri.tryParse(_url.text.trim())?.hasScheme == true && (!onePw || _token.text.isNotEmpty);
    return FormSheet(
      icon: LucideIcons.keyRound,
      title: l10n.connectPasswordManager,
      subtitle: onePw ? l10n.pmOnePasswordHelp : l10n.pmBitwardenHelp,
      submitLabel: l10n.connect,
      submitKey: const Key('connectPm'),
      onSubmit: !valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final pm = await runGuarded(
                context,
                () => ref.read(backendProvider).connectPasswordManager(CreatePasswordManagerRequest(
                      orgId: widget.orgId,
                      scope: _workspace ? CreatePasswordManagerRequestScopeEnum.workspace : CreatePasswordManagerRequestScopeEnum.personal,
                      provider: _provider,
                      name: _name.text.trim(),
                      url: _url.text.trim(),
                      token: _token.text,
                    )),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (pm != null) Navigator.pop(context, pm);
            },
      children: [
        SegmentedButton<CreatePasswordManagerRequestProviderEnum>(
          segments: const [
            ButtonSegment(value: CreatePasswordManagerRequestProviderEnum.n1password, label: Text('1Password')),
            ButtonSegment(value: CreatePasswordManagerRequestProviderEnum.bitwarden, label: Text('Bitwarden')),
          ],
          selected: {_provider},
          onSelectionChanged: (v) => setState(() => _provider = v.first),
        ),
        TextField(key: const Key('pmName'), controller: _name, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l10n.botNameLabel)),
        TextField(key: const Key('pmUrl'), controller: _url, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectUrl : l10n.pmBwUrl)),
        TextField(key: const Key('pmToken'), controller: _token, obscureText: true, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: onePw ? l10n.pmConnectToken : l10n.pmBwToken)),
        if (admin) SwitchListTile(key: const Key('pmWorkspace'), contentPadding: EdgeInsets.zero, title: Text(l10n.pmForWorkspace), value: _workspace, onChanged: (v) => setState(() => _workspace = v)),
      ],
    );
  }
}

class _Vaults extends ConsumerStatefulWidget {
  const _Vaults({required this.manager});
  final PasswordManager manager;

  @override
  ConsumerState<_Vaults> createState() => _VaultsState();
}

class _VaultsState extends ConsumerState<_Vaults> {
  late final Future<List<PasswordManagerVault>> _vaults = ref.read(backendProvider).passwordManagerVaults(widget.manager.id);
  late final _chosen = widget.manager.allowedVaults.toSet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<PasswordManagerVault>>(
      future: _vaults,
      builder: (context, snap) => FormSheet(
        icon: LucideIcons.vault,
        title: l10n.pmChooseVaults,
        subtitle: l10n.pmChooseVaultsHelp,
        submitLabel: l10n.save,
        submitKey: const Key('saveVaults'),
        onSubmit: () async {
          await runGuarded(context, () => ref.read(backendProvider).setPasswordManagerVaults(widget.manager.id, _chosen.toList()));
          if (context.mounted) Navigator.pop(context);
        },
        children: [
          if (snap.hasError) Text(errorText(context, snap.error!)),
          if (!snap.hasData && !snap.hasError) const Center(child: CircularProgressIndicator()),
          for (final v in snap.data ?? const <PasswordManagerVault>[])
            CheckboxListTile(
              key: Key('vault-${v.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(v.name),
              subtitle: v.logins == null ? null : Text(l10n.pmLogins(v.logins!)),
              value: _chosen.contains(v.id),
              onChanged: (on) => setState(() => on == true ? _chosen.add(v.id) : _chosen.remove(v.id)),
            ),
        ],
      ),
    );
  }
}

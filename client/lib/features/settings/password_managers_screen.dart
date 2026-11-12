import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/revealable.dart';

/// Password managers (D-128): 1Password or Bitwarden, for the workspace or just you, and the
/// vaults bots may use. Bots never see passwords.
final passwordManagersProvider =
    FutureProvider.autoDispose<List<PasswordManager>>((ref) async {
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
      final pm = await showAdaptiveSheet<PasswordManager>(
        context: context,
        builder: (_) => _Connect(orgId: org.id),
      );
      ref.invalidate(passwordManagersProvider);
      if (pm != null && context.mounted) {
        await showAdaptiveSheet<void>(
          context: context,
          builder: (_) => _Vaults(manager: pm),
        );
      }
      ref.invalidate(passwordManagersProvider);
    }

    return SubPage(
      title: l10n.passwordManagers,
      actions: [
        IconButton(
          key: const Key('addPasswordManager'),
          tooltip: l10n.connectPasswordManager,
          icon: const Icon(LucideIcons.plus),
          onPressed: add,
        ),
      ],
      body: AsyncView(
        value: ref.watch(passwordManagersProvider),
        onRetry: () => ref.invalidate(passwordManagersProvider),
        loading: const _ManagersSkeleton(),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.keyRound,
                title: l10n.noPasswordManagers,
                message: l10n.passwordManagersHelp,
                action: FilledButton(
                  onPressed: add,
                  child: Text(l10n.connectPasswordManager),
                ),
              )
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
                            m.provider == PasswordManagerProviderEnum.n1password
                                ? '1Password'
                                : 'Bitwarden',
                            m.scope == PasswordManagerScopeEnum.workspace
                                ? l10n.pmWorkspace
                                : l10n.pmJustMe,
                            m.allowedVaults.isEmpty
                                ? l10n.pmNoVaults
                                : l10n.pmVaults(m.allowedVaults.length),
                            if (m.lastError != null) m.lastError!,
                          ].join(' · '),
                          onTap: () async {
                            await showAdaptiveSheet<void>(
                              context: context,
                              builder: (_) => _Vaults(manager: m),
                            );
                            ref.invalidate(passwordManagersProvider);
                          },
                          trailing: IconButton(
                            key: Key('deletePm-${m.id}'),
                            tooltip: l10n.delete,
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            onPressed: () async {
                              await runGuarded(
                                context,
                                () => backend.deletePasswordManager(m.id),
                              );
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

/// The password managers page before it loads: the note over a card of manager rows with a delete button.
class _ManagersSkeleton extends StatelessWidget {
  const _ManagersSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 1), child: SkeletonBone(width: 16, height: 16, radius: 4)),
            const SizedBox(width: 6),
            Expanded(
              child: SkeletonText(style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35), lines: 2, widthFactor: 0.7),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SkeletonGroupedCard(
          rows: [
            for (final (t, st) in const [(0.4, 0.76), (0.32, 0.64)])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SkeletonRow(padding: EdgeInsets.zero, trailing: SkeletonTrailing.none, titleWidth: t, subtitleWidth: st),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    const SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 18, height: 18, radius: 5))),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The vault checklist before it loads: checkbox rows with a name and a count of logins.
class _VaultsSkeleton extends StatelessWidget {
  const _VaultsSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          for (final (t, st) in const [(0.44, 0.26), (0.3, 0.22), (0.52, 0.3)])
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkeletonText(style: text.bodyLarge, widthFactor: t),
                        SkeletonText(style: text.bodyMedium, widthFactor: st),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  const SkeletonBone(width: 18, height: 18, radius: 3),
                  const SizedBox(width: 11),
                ],
              ),
            ),
        ],
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
    final onePw =
        _provider == CreatePasswordManagerRequestProviderEnum.n1password;
    final valid =
        _name.text.trim().isNotEmpty &&
        Uri.tryParse(_url.text.trim())?.hasScheme == true &&
        (!onePw || _token.text.isNotEmpty);
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.keyRound,
      title: l10n.connectPasswordManager,
      subtitle: onePw ? l10n.pmOnePasswordHelp : l10n.pmBitwardenHelp,
      submitLabel: l10n.connect,
      submitKey: const Key('connectPm'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !valid || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final pm = await runGuarded(
                context,
                () => ref
                    .read(backendProvider)
                    .connectPasswordManager(
                      CreatePasswordManagerRequest(
                        orgId: widget.orgId,
                        scope: _workspace
                            ? CreatePasswordManagerRequestScopeEnum.workspace
                            : CreatePasswordManagerRequestScopeEnum.personal,
                        provider: _provider,
                        name: _name.text.trim(),
                        url: _url.text.trim(),
                        token: _token.text,
                      ),
                    ),
              );
              if (!mounted) return;
              setState(() => _busy = false);
              if (!context.mounted) return;
              if (pm != null) Navigator.pop(context, pm);
            },
      children: [
        SegmentedButton<CreatePasswordManagerRequestProviderEnum>(
          segments: const [
            ButtonSegment(
              value: CreatePasswordManagerRequestProviderEnum.n1password,
              label: Text('1Password'),
            ),
            ButtonSegment(
              value: CreatePasswordManagerRequestProviderEnum.bitwarden,
              label: Text('Bitwarden'),
            ),
          ],
          selected: {_provider},
          onSelectionChanged: (v) => setState(() => _provider = v.first),
        ),
        TextField(
          key: const Key('pmName'),
          controller: _name,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.botNameLabel),
        ),
        TextField(
          key: const Key('pmUrl'),
          controller: _url,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: onePw ? l10n.pmConnectUrl : l10n.pmBwUrl,
          ),
        ),
        Revealable(
          builder: (context, hidden, toggle) => TextField(
            key: const Key('pmToken'),
            controller: _token,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit?.call(),
            obscureText: hidden,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: onePw ? l10n.pmConnectToken : l10n.pmBwToken,
              suffixIcon: toggle,
            ),
          ),
        ),
        if (admin)
          SwitchListTile(
            key: const Key('pmWorkspace'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pmForWorkspace),
            value: _workspace,
            onChanged: hapticOnChanged((v) => setState(() => _workspace = v)),
          ),
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
  late final Future<List<PasswordManagerVault>> _vaults = ref
      .read(backendProvider)
      .passwordManagerVaults(widget.manager.id);
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
          await runGuarded(
            context,
            () => ref
                .read(backendProvider)
                .setPasswordManagerVaults(widget.manager.id, _chosen.toList()),
          );
          if (context.mounted) Navigator.pop(context);
        },
        children: [
          if (snap.hasError) Text(errorText(context, snap.error!)),
          if (!snap.hasData && !snap.hasError) const _VaultsSkeleton(),
          for (final v in snap.data ?? const <PasswordManagerVault>[])
            CheckboxListTile(
              key: Key('vault-${v.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(v.name),
              subtitle: v.logins == null
                  ? null
                  : Text(l10n.pmLogins(v.logins!)),
              value: _chosen.contains(v.id),
              onChanged: hapticOnChanged(
                (on) => setState(
                  () => on == true ? _chosen.add(v.id) : _chosen.remove(v.id),
                ),
                haptic: HapticsHelper.soft,
              ),
            ),
        ],
      ),
    );
  }
}

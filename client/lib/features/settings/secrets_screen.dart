import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../../ui/revealable.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'totp_scan.dart';

/// Named secrets bots reference as {{secret:NAME}}; each is only sent to its allowed hosts.
class SecretsScreen extends ConsumerWidget {
  const SecretsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showAdaptiveSheet<(String, String, List<String>, bool)>(context: context, builder: (_) => const _AddSecretForm());
    if (result == null || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    await runGuarded(
      context,
      () => ref.read(backendProvider).createSecret(org.id, name: result.$1, value: result.$2, hosts: result.$3, totp: result.$4),
    );
    ref.invalidate(secretsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final add = GlowButton.icon(
      key: const Key('addSecret'),
      onPressed: () => _add(context, ref),
      icon: const Icon(LucideIcons.plus, size: 18),
      label: Text(l10n.addSecret),
    );
    return SubPage(
      title: l10n.secrets,
      actions: [HeaderIconButton(icon: LucideIcons.plus, tooltip: l10n.addSecret, onPressed: () => _add(context, ref))],
      body: AsyncView(
        value: ref.watch(secretsProvider),
        onRetry: () => ref.invalidate(secretsProvider),
        loading: const _SecretsSkeleton(),
        data: (items) => items.isEmpty
            ? EmptyState(icon: LucideIcons.lock, title: l10n.noSecrets, message: l10n.secretsHelp, action: add)
            : PageColumn(
                children: [
                  FormNote(l10n.secretsHelp),
                  const SizedBox(height: AppSpace.md),
                  GroupedCard(
                    children: [
                      for (final s in items)
                        GroupedTile(
                          key: Key('secret-${s.id}'),
                          icon: s.kind == SecretKind.totp ? LucideIcons.shieldCheck : LucideIcons.keyRound,
                          iconColor: context.appColors.warning,
                          title: s.name,
                          subtitle: [
                            if (s.kind == SecretKind.totp) l10n.signInCode,
                            l10n.onlySentTo(s.allowedHosts.join(', ')),
                          ].join(' · '),
                          trailing: IconButton(
                            tooltip: l10n.delete,
                            icon: Icon(LucideIcons.trash2, color: context.colorScheme.onSurfaceVariant),
                            onPressed: () async {
                              final ok = await showConfirm(
                                context: context,
                                title: l10n.deleteSecretTitle(s.name),
                                message: l10n.deleteSecretBody,
                                confirmLabel: l10n.delete,
                                destructive: true,
                              );
                              if (!ok || !context.mounted) return;
                              await runGuarded(context, () => ref.read(backendProvider).deleteSecret(s.id));
                              ref.invalidate(secretsProvider);
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

/// The secrets page before it loads: the help note over a card of secret rows with a delete button.
class _SecretsSkeleton extends StatelessWidget {
  const _SecretsSkeleton();

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
              child: SkeletonText(style: context.textTheme.bodySmall?.copyWith(height: 1.35), lines: 2, widthFactor: 0.7),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        SkeletonGroupedCard(
          rows: [
            for (final (t, st) in const [(0.42, 0.7), (0.3, 0.84), (0.5, 0.62)])
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

class _AddSecretForm extends StatefulWidget {
  const _AddSecretForm();

  @override
  State<_AddSecretForm> createState() => _AddSecretFormState();
}

class _AddSecretFormState extends State<_AddSecretForm> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _hosts = TextEditingController();
  var _show = false;
  var _totp = false;

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
    final nameOk = RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(_name.text);
    final valid = nameOk && _value.text.isNotEmpty && _hostList.isNotEmpty;
    return FormSheet(
      icon: LucideIcons.keyRound,
      iconColor: context.appColors.warning,
      title: l10n.addSecret,
      subtitle: l10n.secretsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveSecret'),
      onSubmit: valid ? () => Navigator.pop(context, (_name.text, _value.text.trim(), _hostList, _totp)) : null,
      children: [
        SegmentedButton<bool>(
          key: const Key('secretKind'),
          segments: [
            ButtonSegment(value: false, icon: const Icon(LucideIcons.keyRound, size: 18), label: Text(l10n.secretKindValue)),
            ButtonSegment(value: true, icon: const Icon(LucideIcons.shieldCheck, size: 18), label: Text(l10n.signInCode)),
          ],
          selected: {_totp},
          onSelectionChanged: (v) => setState(() => _totp = v.first),
        ),
        TextField(
          key: const Key('secretName'),
          controller: _name,
          textInputAction: TextInputAction.next,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.secretName,
            hintText: 'GITHUB_TOKEN',
            helperText: l10n.secretNameHelp,
            prefixIcon: const Icon(LucideIcons.hash, size: 20),
            errorText: _name.text.isNotEmpty && !nameOk ? l10n.secretNameHelp : null,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            final upper = v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9_]'), '_');
            if (upper != v) {
              _name.value = TextEditingValue(
                text: upper,
                selection: TextSelection.collapsed(offset: upper.length),
              );
            }
            setState(() {});
          },
        ),
        TextField(
          key: const Key('secretValue'),
          controller: _value,
          textInputAction: TextInputAction.next,
          obscureText: !_show,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _totp ? l10n.totpSeedLabel : l10n.secretValue,
            helperText: _totp ? l10n.totpSeedHelp : null,
            prefixIcon: const Icon(LucideIcons.rectangleEllipsis, size: 20),
            suffixIcon: FieldSuffix(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_totp)
                    TotpScanButton(
                      onScanned: (link) => setState(() {
                        _value.text = link;
                        final issuer = Uri.tryParse(link)?.queryParameters['issuer'];
                        if (_name.text.isEmpty && issuer != null && issuer.isNotEmpty) {
                          _name.text = '${issuer.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_')}_2FA';
                        }
                      }),
                    ),
                  IconButton(
                    tooltip: _show ? l10n.hide : l10n.show,
                    icon: Icon(_show ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ],
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const Key('secretHosts'),
          controller: _hosts,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (valid) Navigator.pop(context, (_name.text, _value.text.trim(), _hostList, _totp));
          },
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.allowedHosts,
            hintText: 'api.github.com',
            helperText: l10n.allowedHostsHelp,
            prefixIcon: const Icon(LucideIcons.server, size: 20),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

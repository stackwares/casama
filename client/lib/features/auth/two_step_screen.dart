import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';

/// The person's authenticator apps (refreshed after changes).
final twoStepFactorsProvider = FutureProvider<List<TwoStepFactor>>((ref) => ref.watch(backendProvider).twoStepFactors());

final _requireTwoStepProvider = FutureProvider<bool?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null || org.role == OrgRole.member) return null;
  return ref.watch(backendProvider).requireTwoStep(org.id);
});

/// A 6-digit code field.
class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.onSubmit, this.fieldKey});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => TextField(
        key: fieldKey,
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        style: const TextStyle(fontSize: 22, letterSpacing: 6),
        textAlign: TextAlign.center,
        decoration: InputDecoration(labelText: context.l10n.twoStepCode),
        onSubmitted: (_) => onSubmit(),
      );
}

/// Settings → Two-step sign-in: authenticator apps, and the workspace requirement for admins.
class TwoStepSettingsScreen extends ConsumerStatefulWidget {
  const TwoStepSettingsScreen({super.key});

  @override
  ConsumerState<TwoStepSettingsScreen> createState() => _TwoStepSettingsScreenState();
}

class _TwoStepSettingsScreenState extends ConsumerState<TwoStepSettingsScreen> {
  TwoStepEnrollment? _enrolling;
  final _code = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final e = await runGuarded(context, () => ref.read(backendProvider).startTwoStep());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _enrolling = e;
      _code.clear();
    });
  }

  Future<void> _verify() async {
    final e = _enrolling;
    if (e == null || _code.text.length != 6) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).verifyTwoStep(e.factorId, _code.text);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _enrolling = null;
    });
    if (ok == true) {
      showMessage(context, context.l10n.twoStepNowOn);
      ref.invalidate(twoStepFactorsProvider);
    }
  }

  Future<void> _rename(TwoStepFactor f) async {
    final l10n = context.l10n;
    final name = await showTextPrompt(
      context,
      title: l10n.twoStepRenameTitle,
      label: l10n.twoStepNameLabel,
      hint: l10n.twoStepNameHint,
      initial: f.name.split(' · ').first,
      submitLabel: l10n.save,
      icon: LucideIcons.smartphone,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).renameTwoStep(f.id, name.trim()));
    ref.invalidate(twoStepFactorsProvider);
  }

  Future<void> _remove(TwoStepFactor f) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.twoStepRemove,
      message: l10n.twoStepRemoveConfirm,
      confirmLabel: l10n.twoStepRemove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).removeTwoStep(f.id));
    ref.invalidate(twoStepFactorsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final factors = ref.watch(twoStepFactorsProvider);
    final require = ref.watch(_requireTwoStepProvider).value;
    final org = ref.watch(currentOrgProvider);
    final enrolling = _enrolling;
    return SubPage(
      title: l10n.twoStepSignIn,
      children: [
        FormNote(l10n.twoStepHelp, icon: LucideIcons.shieldCheck),
        SectionHeader(title: l10n.twoStepAuthenticators),
        AsyncView(
          value: factors,
          onRetry: () => ref.invalidate(twoStepFactorsProvider),
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              if (items.isNotEmpty)
                GroupedCard(
                  children: [
                    for (final f in items)
                      GroupedTile(
                        icon: LucideIcons.smartphone,
                        title: f.name.split(' · ').first,
                        onTap: () => _rename(f),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('renameFactor-${f.id}'),
                              tooltip: l10n.twoStepRename,
                              icon: const Icon(LucideIcons.pencil, size: 18),
                              onPressed: () => _rename(f),
                            ),
                            TextButton(
                              key: Key('removeFactor-${f.id}'),
                              onPressed: () => _remove(f),
                              child: Text(l10n.twoStepRemove),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (enrolling == null)
                OutlinedButton.icon(
                  key: const Key('startTwoStep'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _start,
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(items.isEmpty ? l10n.twoStepSetUp : l10n.twoStepAddAnother),
                )
              else
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpace.md,
                    children: [
                      FormNote(l10n.twoStepScan),
                      Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(AppSpace.sm),
                          child: SvgPicture.string(enrolling.qrSvg, width: 180, height: 180),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              '${l10n.twoStepKey}: ${enrolling.secret}',
                              style: const TextStyle(fontFamily: 'JetBrains Mono'),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.copy,
                            icon: const Icon(LucideIcons.copy, size: 18),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: enrolling.secret));
                              if (context.mounted) showMessage(context, l10n.copied);
                            },
                          ),
                        ],
                      ),
                      _CodeField(fieldKey: const Key('enrollCode'), controller: _code, onSubmit: _verify),
                      GlowButton.icon(
                        key: const Key('verifyTwoStep'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: _busy ? null : _verify,
                        icon: const Icon(LucideIcons.check, size: 20),
                        label: Text(l10n.twoStepVerify),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (require != null && org != null) ...[
          SectionHeader(title: l10n.workspace),
          GroupedCard(
            children: [
              SwitchListTile(
                key: const Key('requireTwoStep'),
                title: Text(l10n.requireTwoStep),
                subtitle: Text(l10n.requireTwoStepHelp),
                value: require,
                onChanged: (v) async {
                  await runGuarded(context, () => ref.read(backendProvider).setRequireTwoStep(org.id, v));
                  ref.invalidate(_requireTwoStepProvider);
                  ref.invalidate(organizationsProvider);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Shown after the password step when the account has two-step sign-in (route /two-step).
class TwoStepPromptScreen extends ConsumerStatefulWidget {
  const TwoStepPromptScreen({super.key});

  @override
  ConsumerState<TwoStepPromptScreen> createState() => _TwoStepPromptScreenState();
}

class _TwoStepPromptScreenState extends ConsumerState<TwoStepPromptScreen> {
  final _code = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).passTwoStep(_code.text);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(organizationsProvider);
      context.go('/bots');
    } else {
      _code.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.md,
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 40),
                  Text(l10n.twoStepPromptTitle, textAlign: TextAlign.center, style: context.textTheme.headlineSmall),
                  Text(l10n.twoStepPromptBody, textAlign: TextAlign.center),
                  _CodeField(fieldKey: const Key('signInCode'), controller: _code, onSubmit: _submit),
                  GlowButton(
                    key: const Key('submitCode'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _busy ? null : _submit,
                    child: Text(l10n.twoStepVerify),
                  ),
                  TextButton(
                    onPressed: () => runGuarded(context, ref.read(backendProvider).signOut),
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

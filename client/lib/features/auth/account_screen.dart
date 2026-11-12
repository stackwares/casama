import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/otp_code_field.dart';
import '../../ui/page.dart';
import '../../ui/progressive_fade.dart';
import '../../ui/revealable.dart';

/// A new password twice, and the emailed code when the session is too old to change it without
/// one (D-184). Shared by the reset screen and Settings → Account.
class _PasswordForm extends ConsumerStatefulWidget {
  const _PasswordForm({required this.onDone, required this.submitLabel});

  final VoidCallback onDone;
  final String submitLabel;

  @override
  ConsumerState<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<_PasswordForm> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _again = TextEditingController();
  final _code = TextEditingController();
  var _needsCode = false;
  var _codeInvalid = false;
  var _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_needsCode && _code.text.length != OtpCodeField.length) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    var done = false;
    try {
      await backend.setPassword(_password.text, code: _needsCode ? _code.text : null);
      done = true;
    } on ReauthenticationNeeded {
      if (!mounted) return;
      if (_needsCode) {
        setState(() => _codeInvalid = true);
      } else {
        // The first time: email a code and ask for it.
        await runGuarded(context, backend.sendReauthenticationCode);
        if (mounted) setState(() => _needsCode = true);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (done) {
      showSuccess(context, context.l10n.passwordSaved);
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Revealable(
              builder: (context, hidden, toggle) => TextFormField(
                key: const Key('newPassword'),
                controller: _password,
                textInputAction: TextInputAction.next,
                autofocus: true,
                obscureText: hidden,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  suffixIcon: toggle,
                ),
                validator: (v) => (v ?? '').length >= 6 ? null : l10n.passwordTooShort,
              ),
            ),
            Revealable(
              builder: (context, hidden, toggle) => TextFormField(
                key: const Key('newPasswordAgain'),
                controller: _again,
                obscureText: hidden,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: l10n.newPasswordAgain,
                  prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 20),
                  suffixIcon: toggle,
                ),
                validator: (v) => v == _password.text ? null : l10n.passwordsDontMatch,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            if (_needsCode) ...[
              FormNote(l10n.passwordCodeSent(ref.read(backendProvider).userEmail.orPlaceholder()), icon: LucideIcons.mailCheck),
              OtpCodeField(
                key: const Key('reauthCode'),
                controller: _code,
                label: l10n.emailCodeLabel,
                invalid: _codeInvalid,
                onChanged: (_) {
                  if (_codeInvalid) setState(() => _codeInvalid = false);
                },
                onCompleted: (_) => _submit(),
                onSubmitted: _submit,
              ),
            ],
            GlowButton(
              key: const Key('savePassword'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.onPrimary),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// After a reset link or code (route /new-password): choose the new password.
class NewPasswordScreen extends ConsumerWidget {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final statusBar = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: ProgressiveFade(child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            // Starts under the status bar, so content dissolves there as it scrolls up.
            padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg + statusBar, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                key: const Key('newPasswordScreen'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.md,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(LucideIcons.keyRound, size: 32, color: scheme.primary),
                    ),
                  ),
                  Text(
                    l10n.newPasswordTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  Text(
                    l10n.newPasswordBody,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  _PasswordForm(submitLabel: l10n.savePassword, onDone: () => context.go('/bots')),
                  TextButton(
                    key: const Key('skipNewPassword'),
                    style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                    onPressed: ref.read(backendProvider).skipNewPassword,
                    child: Text(l10n.notNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

/// Settings → Account (D-184): the email, the password, passkeys, and signing out everywhere.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  Future<void> _changeEmail() async {
    final l10n = context.l10n;
    final backend = ref.read(backendProvider);
    final email = await showTextPrompt(
      context,
      title: l10n.changeEmailTitle,
      subtitle: l10n.changeEmailHelp,
      label: l10n.newEmail,
      submitLabel: l10n.changeEmailSend,
      icon: LucideIcons.mail,
      fieldIcon: LucideIcons.atSign,
      keyboardType: TextInputType.emailAddress,
      fieldKey: const Key('newEmail'),
    );
    final value = email?.trim() ?? '';
    if (value.isEmpty || !mounted) return;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      showWarning(context, l10n.invalidEmail);
      return;
    }
    if (value.toLowerCase() == backend.userEmail?.toLowerCase()) return;
    final ok = await runGuarded(context, () async {
      await backend.changeEmail(value);
      return true;
    });
    if (ok == true && mounted) {
      setState(() {});
      showSuccess(context, l10n.changeEmailSent(value));
    }
  }

  Future<void> _password() => showAdaptiveSheet<void>(
    context: context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(sheet.l10n.passwordTitle, style: sheet.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          FormNote(sheet.l10n.passwordHelp),
          _PasswordForm(submitLabel: sheet.l10n.savePassword, onDone: () => Navigator.of(sheet).maybePop()),
        ],
      ),
    ),
  );

  Future<void> _signOutEverywhere() async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.signOutEverywhere,
      message: l10n.signOutEverywhereConfirm,
      confirmLabel: l10n.signOutEverywhere,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(context, ref.read(backendProvider).signOutEverywhere);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    final pending = backend.pendingEmail;
    final passkeys = ref.watch(authMethodsProvider).value?.passkeys == true;
    return SubPage(
      title: l10n.account,
      children: [
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('accountEmail'),
              icon: LucideIcons.mail,
              title: backend.userEmail.orPlaceholder(l10n.email),
              subtitle: pending == null ? l10n.changeEmailRow : l10n.changeEmailPending(pending),
              onTap: _changeEmail,
            ),
            GroupedTile(
              key: const Key('accountPassword'),
              icon: LucideIcons.lock,
              title: l10n.passwordTitle,
              subtitle: l10n.passwordRow,
              onTap: _password,
            ),
            if (passkeys)
              GroupedTile(
                key: const Key('accountPasskeys'),
                icon: LucideIcons.keyRound,
                title: l10n.passkeys,
                subtitle: l10n.passkeysRow,
                onTap: () => context.push('/settings/passkeys'),
              ),
          ],
        ),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('signOutEverywhere'),
              icon: LucideIcons.logOut,
              title: l10n.signOutEverywhere,
              subtitle: l10n.signOutEverywhereHelp,
              destructive: true,
              showChevron: false,
              onTap: _signOutEverywhere,
            ),
          ],
        ),
      ],
    );
  }
}

/// Once per device, after signing in: offer a passkey when the server has them and the account
/// has none yet (D-184). Quiet on any failure; it's only a suggestion.
Future<void> maybeSuggestPasskey(BuildContext context, WidgetRef ref) async {
  const key = 'passkey.suggested';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    final backend = ref.read(backendProvider);
    final methods = await ref.read(authMethodsProvider.future);
    if (!methods.passkeys || backend.newPasswordNeeded || backend.twoStepCodeNeeded) return;
    if ((await backend.passkeys()).isNotEmpty) return;
    await prefs.setBool(key, true);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final l10n = context.l10n;
  final add = await showConfirm(
    context: context,
    title: l10n.passkeySuggestTitle,
    message: l10n.passkeySuggestBody,
    confirmLabel: l10n.passkeyAdd,
  );
  if (!add || !context.mounted) return;
  final added = await runGuarded(context, () => ref.read(backendProvider).addPasskey());
  if (added == true && context.mounted) showSuccess(context, context.l10n.passkeyAdded);
}

/// Wraps the signed-in shell to run [maybeSuggestPasskey] once, a moment after it first shows.
class PasskeySuggestion extends ConsumerStatefulWidget {
  const PasskeySuggestion({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PasskeySuggestion> createState() => _PasskeySuggestionState();
}

class _PasskeySuggestionState extends ConsumerState<PasskeySuggestion> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Let the first screen settle (and the welcome flow start) before asking.
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) maybeSuggestPasskey(context, ref);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

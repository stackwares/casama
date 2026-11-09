import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/kasama_mark.dart';

/// Email and password, magic link, Google and Apple sign-in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    await runGuarded(context, () async {
      if (_signUp) {
        final signedIn = await backend.signUp(_email.text.trim(), _password.text);
        if (!signedIn && mounted) showMessage(context, context.l10n.confirmEmailSent);
      } else {
        await backend.signIn(_email.text.trim(), _password.text);
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _magicLink() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      showMessage(context, context.l10n.invalidEmail);
      return;
    }
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).sendMagicLink(email);
      return true;
    });
    if (ok == true && mounted) showMessage(context, context.l10n.magicLinkSent);
  }

  static bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _sso() async {
    final l10n = context.l10n;
    final email = await showDialog<String>(context: context, builder: (_) => _SsoDialog(title: l10n.continueWithSso, label: l10n.workEmail, cancel: l10n.cancel, ok: l10n.continueLabel));
    if (email == null || !email.contains('@') || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).signInWithSso(email));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final showApple = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final host = Uri.tryParse(ref.read(backendProvider).apiUrl)?.host ?? ref.read(backendProvider).apiUrl;
    Widget pill(Widget button) => SizedBox(height: 50, child: button);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF0F766E).withValues(alpha: context.isDark ? 0.5 : 0.3), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: const KasamaMark(size: 64),
                    ),
                  ).appCardEntrance(),
                  const SizedBox(height: AppSpace.xl),
                  AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: Text(
                      _signUp ? l10n.signUpTitle : l10n.signInTitle,
                      key: ValueKey(_signUp),
                      style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.signInTagline,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20)),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => _validEmail((v ?? '').trim()) ? null : l10n.invalidEmail,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextFormField(
                    key: const Key('password'),
                    controller: _password,
                    decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20)),
                    obscureText: true,
                    autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                    validator: (v) => (v ?? '').length >= 6 ? null : l10n.passwordTooShort,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpace.md),
                  pill(FilledButton(
                    key: const Key('submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.onPrimary))
                        : Text(_signUp ? l10n.signUp : l10n.signIn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  )),
                  const SizedBox(height: AppSpace.xxs),
                  TextButton(
                    key: const Key('toggleMode'),
                    onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                    child: Text(_signUp ? l10n.haveAccount : l10n.needAccount),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                        child: Text(l10n.orLabel, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                  ),
                  pill(OutlinedButton.icon(
                    onPressed: _busy ? null : () => runGuarded(context, () => ref.read(backendProvider).signInWithProvider('google')),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: Text(l10n.continueWithGoogle),
                  )),
                  if (showApple) ...[
                    const SizedBox(height: AppSpace.xs),
                    pill(OutlinedButton.icon(
                      onPressed: _busy ? null : () => runGuarded(context, () => ref.read(backendProvider).signInWithProvider('apple')),
                      icon: const Icon(Icons.apple_rounded, size: 22),
                      label: Text(l10n.continueWithApple),
                    )),
                  ],
                  const SizedBox(height: AppSpace.xs),
                  Wrap(alignment: WrapAlignment.center, children: [
                    TextButton.icon(
                      onPressed: _busy ? null : _magicLink,
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: Text(l10n.magicLink),
                    ),
                    TextButton.icon(
                      key: const Key('ssoSignIn'),
                      onPressed: _busy ? null : _sso,
                      icon: const Icon(Icons.business_outlined, size: 18),
                      label: Text(l10n.continueWithSso),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.lg),
                  // Self-hosted servers: point the app at your own Kasama (D-076).
                  Center(
                    child: ActionChip(
                      key: const Key('changeServer'),
                      avatar: Icon(Icons.dns_outlined, size: 16, color: scheme.onSurfaceVariant),
                      label: Text(l10n.serverIs(host), style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      onPressed: _busy
                          ? null
                          : () => changeServerDialog(context, ref.read(backendProvider).apiUrl,
                              title: l10n.server, label: l10n.serverAddress, cancel: l10n.cancel, connect: l10n.connect),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SsoDialog extends StatefulWidget {
  const _SsoDialog({required this.title, required this.label, required this.cancel, required this.ok});
  final String title, label, cancel, ok;
  @override
  State<_SsoDialog> createState() => _SsoDialogState();
}

class _SsoDialogState extends State<_SsoDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          key: const Key('ssoEmail'),
          controller: _c,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: widget.label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: Text(widget.ok)),
        ],
      );
}

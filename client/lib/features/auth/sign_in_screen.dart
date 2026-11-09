import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';

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
    final showApple = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Icon(Icons.groups_2_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _signUp ? l10n.signUpTitle : l10n.signInTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    decoration: InputDecoration(labelText: l10n.email),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => _validEmail((v ?? '').trim()) ? null : l10n.invalidEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('password'),
                    controller: _password,
                    decoration: InputDecoration(labelText: l10n.password),
                    obscureText: true,
                    autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                    validator: (v) => (v ?? '').length >= 6 ? null : l10n.passwordTooShort,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(_signUp ? l10n.signUp : l10n.signIn),
                  ),
                  TextButton(
                    key: const Key('toggleMode'),
                    onPressed: _busy ? null : () => setState(() => _signUp = !_signUp),
                    child: Text(_signUp ? l10n.haveAccount : l10n.needAccount),
                  ),
                  const Divider(height: 32),
                  OutlinedButton.icon(onPressed: _busy ? null : _magicLink, icon: const Icon(Icons.mail_outline), label: Text(l10n.magicLink)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => runGuarded(context, () => ref.read(backendProvider).signInWithProvider('google')),
                    icon: const Icon(Icons.g_mobiledata),
                    label: Text(l10n.continueWithGoogle),
                  ),
                  if (showApple) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => runGuarded(context, () => ref.read(backendProvider).signInWithProvider('apple')),
                      icon: const Icon(Icons.apple),
                      label: Text(l10n.continueWithApple),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('ssoSignIn'),
                    onPressed: _busy ? null : _sso,
                    icon: const Icon(Icons.business_outlined),
                    label: Text(l10n.continueWithSso),
                  ),
                  const SizedBox(height: 16),
                  // Self-hosted servers: point the app at your own Kasama (D-076).
                  TextButton.icon(
                    key: const Key('changeServer'),
                    onPressed: _busy
                        ? null
                        : () => changeServerDialog(context, ref.read(backendProvider).apiUrl,
                            title: l10n.server, label: l10n.serverAddress, cancel: l10n.cancel, connect: l10n.connect),
                    icon: const Icon(Icons.dns_outlined, size: 18),
                    label: Text(l10n.serverIs(Uri.tryParse(ref.read(backendProvider).apiUrl)?.host ?? ref.read(backendProvider).apiUrl)),
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

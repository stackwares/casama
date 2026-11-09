import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
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
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

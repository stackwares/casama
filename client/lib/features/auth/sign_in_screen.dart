import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/server_address.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/brand_sign_in_buttons.dart';
import '../../ui/form_sheet.dart';
import 'floating_mascots.dart';
import 'welcome_tagline.dart';
import '../../ui/glow_button.dart';
import '../../ui/otp_code_field.dart';
import '../../ui/revealable.dart';
import '../selfhost/local_server.dart';
import '../selfhost/local_server_sheet.dart';

/// The first screen: the bots floating around the name, and one button that opens the ways in.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  static Future<void> openOptions(BuildContext context) =>
      showAdaptiveSheet<void>(
        context: context,
        dialogMaxWidth: 460,
        builder: (_) => const SignInOptions(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Scaffold(
      // Plain, so the bots are the only thing moving on it.
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingMascots()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                // Spaced out when it fits; scrolls when large text or a small screen doesn't.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.xl,
                            0,
                            AppSpace.xl,
                            AppSpace.lg,
                          ),
                          child: Column(
                            children: [
                              const Spacer(flex: 5),
                              Text(
                                'Casama',
                                textAlign: TextAlign.center,
                                style: context.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              WelcomeTagline(
                                taglines: [
                                  l10n.signInTagline,
                                  l10n.signInTagline2,
                                  l10n.signInTagline3,
                                  l10n.signInTagline4,
                                  l10n.signInTagline5,
                                ],
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Spacer(flex: 6),
                              // At least 56 tall but free to grow, so large text sizes and longer
                              // translations wrap instead of being cut off.
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  key: const Key('openSignIn'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: scheme.onSurface,
                                    foregroundColor: scheme.surface,
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size.fromHeight(56),
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
                                    textStyle: context.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () => openOptions(context),
                                  child: Text(l10n.welcomeCta, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple and Google up front; email and password, a magic link, SSO and self-hosting folded behind reveals.
class SignInOptions extends ConsumerStatefulWidget {
  const SignInOptions({super.key});

  @override
  ConsumerState<SignInOptions> createState() => _SignInOptionsState();
}

class _SignInOptionsState extends ConsumerState<SignInOptions> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _signUp = false;
  var _busy = false;
  var _showEmail = false;
  var _showMore = false;
  var _usePassword = false;

  /// After a sign-in email goes out: where it went, the code typed from it, and when another may go.
  String? _sentTo;

  /// The email that went out is a password reset (its code signs in, then asks for a new password).
  var _resetting = false;
  final _code = TextEditingController();
  var _codeInvalid = false;
  var _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    await runGuarded(context, () async {
      if (_signUp) {
        final signedIn = await backend.signUp(
          _email.text.trim(),
          _password.text,
        );
        // The address needs confirming first: the same check-inbox step as a sign-in email
        // (tap the link, or type its code).
        if (!signedIn && mounted) {
          setState(() {
            _sentTo = _email.text.trim();
            _code.clear();
            _codeInvalid = false;
            _startResendCountdown();
          });
        }
      } else {
        await backend.signIn(_email.text.trim(), _password.text);
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _magicLink() async {
    if (_sentTo == null && !_form.currentState!.validate()) return;
    final email = _sentTo ?? _email.text.trim();
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      final backend = ref.read(backendProvider);
      await (_resetting ? backend.sendPasswordReset(email) : backend.sendMagicLink(email));
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) {
        final resent = _sentTo != null;
        _sentTo = email;
        _code.clear();
        _codeInvalid = false;
        _startResendCountdown();
        if (resent) showMessage(context, context.l10n.magicLinkSent);
      }
    });
  }

  // Supabase lets one sign-in email go out a minute; the button says when the next one can.
  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendIn = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verifyCode() async {
    final email = _sentTo;
    final code = _code.text;
    if (email == null || code.length != OtpCodeField.length || _busy) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      final backend = ref.read(backendProvider);
      await (_resetting ? backend.verifyPasswordResetCode(email, code) : backend.verifyEmailCode(email, code));
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeInvalid = ok != true;
    });
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _sentTo = null;
      _resetting = false;
      _resendIn = 0;
      _code.clear();
      _codeInvalid = false;
    });
  }

  /// Google or Apple opens a browser: one tap opens one, however fast the second comes.
  Future<void> _provider(String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    await runGuarded(
      context,
      () => ref.read(backendProvider).signInWithProvider(name),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _busy = false);
  }

  /// A reset email to the address typed above: its link or code signs in, then the app asks for a
  /// new password.
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!_validEmail(email)) {
      showMessage(context, context.l10n.invalidEmail);
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).sendPasswordReset(email);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) {
        _resetting = true;
        _sentTo = email;
        _code.clear();
        _codeInvalid = false;
        _startResendCountdown();
      }
    });
  }

  /// The system passkey sheet; closing it just leaves the options as they were.
  Future<void> _passkey() async {
    if (_busy) return;
    setState(() => _busy = true);
    await runGuarded(context, () => ref.read(backendProvider).signInWithPasskey());
    if (mounted) setState(() => _busy = false);
  }

  static bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _sso() async {
    final email = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => const _SsoForm(),
    );
    if (email == null || !email.contains('@') || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(backendProvider).signInWithSso(email),
    );
  }

  /// The step after a sign-in email: tap the link in it, or type its code here (another device,
  /// or the desktop app, where the link can't come back).
  Widget _checkInbox(BuildContext context, Widget Function(Widget) pill) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      key: const Key('checkInbox'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.sm),
        Icon(LucideIcons.mailCheck, size: 32, color: scheme.primary),
        const SizedBox(height: AppSpace.sm),
        Text(
          l10n.checkInboxTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.checkInboxBody(_sentTo!),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        OtpCodeField(
          key: const Key('emailCode'),
          controller: _code,
          label: l10n.emailCodeLabel,
          invalid: _codeInvalid,
          onChanged: (_) {
            if (_codeInvalid) setState(() => _codeInvalid = false);
          },
          onCompleted: (_) => _verifyCode(),
          onSubmitted: _verifyCode,
        ),
        const SizedBox(height: AppSpace.lg),
        pill(
          GlowButton(
            key: const Key('verifyCode'),
            onPressed: _busy ? null : _verifyCode,
            child: _busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
                    ),
                  )
                : Text(
                    l10n.signIn,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              key: const Key('resendLink'),
              onPressed: _busy || _resendIn > 0 ? null : _magicLink,
              child: Text(
                _resendIn > 0 ? l10n.resendLinkIn(_resendIn) : l10n.resendLink,
              ),
            ),
            TextButton(
              key: const Key('changeEmail'),
              onPressed: _busy ? null : _changeEmail,
              child: Text(l10n.useDifferentEmail),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final methods = ref.watch(authMethodsProvider).value ?? const AuthMethods();
    final showApple =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final host =
        Uri.tryParse(ref.read(backendProvider).apiUrl)?.host ??
        ref.read(backendProvider).apiUrl;
    Widget pill(Widget button) => SizedBox(height: 50, child: button);
    // Signed in (password, a link, Google or Apple): the sheet goes with the sign-in screen.
    ref.listen(signedInProvider, (_, next) {
      if (next.value == true && mounted) Navigator.of(context).maybePop();
    });
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The code is the whole step: the other ways in would push the boxes off a short window.
              if (_sentTo != null)
                _checkInbox(context, pill)
              else ...[
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: Text(
                    _signUp ? l10n.signUpTitle : l10n.signInTitle,
                    key: ValueKey(_signUp),
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                // Apple first where it lives, then Google: the two ways most people come in.
                if (showApple) ...[
                  AppleSignInButton(
                    key: const Key('appleSignIn'),
                    label: l10n.continueWithApple,
                    onPressed: _busy ? null : () => _provider('apple'),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                GoogleSignInButton(
                  key: const Key('googleSignIn'),
                  label: l10n.continueWithGoogle,
                  onPressed: _busy ? null : () => _provider('google'),
                ),
                const SizedBox(height: AppSpace.sm),
                // A passkey signs in an account that already has one, so not when signing up.
                if (methods.passkeys && !_signUp) ...[
                  SizedBox(
                    width: double.infinity,
                    child: pill(
                      OutlinedButton.icon(
                        key: const Key('passkeySignIn'),
                        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                        onPressed: _busy ? null : _passkey,
                        icon: const Icon(LucideIcons.keyRound, size: 20),
                        label: Text(l10n.signInWithPasskey),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                // Email and password stay folded away until asked for.
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_showEmail
                      ? SizedBox(
                          width: double.infinity,
                          child: pill(
                            OutlinedButton.icon(
                              key: const Key('continueWithEmail'),
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _showEmail = true),
                              icon: const Icon(LucideIcons.mail, size: 20),
                              label: Text(l10n.continueWithEmail),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpace.xs,
                                bottom: AppSpace.md,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.sm,
                                    ),
                                    child: Text(
                                      l10n.orLabel,
                                      style: context.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                            ),
                            TextFormField(
                              key: const Key('email'),
                              controller: _email,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                prefixIcon: const Icon(
                                  LucideIcons.atSign,
                                  size: 20,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: _usePassword
                                  ? TextInputAction.next
                                  : TextInputAction.send,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) => _validEmail((v ?? '').trim())
                                  ? null
                                  : l10n.invalidEmail,
                              onFieldSubmitted: _usePassword
                                  ? null
                                  : (_) => _magicLink(),
                            ),
                            // A sign-in link by default, no password to remember; a password for those who want one.
                            if (_usePassword) ...[
                              const SizedBox(height: AppSpace.sm),
                              Revealable(
                                builder: (context, hidden, toggle) =>
                                    TextFormField(
                                      key: const Key('password'),
                                      controller: _password,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.password,
                                        prefixIcon: const Icon(
                                          LucideIcons.lock,
                                          size: 20,
                                        ),
                                        suffixIcon: toggle,
                                      ),
                                      obscureText: hidden,
                                      autofillHints: [
                                        _signUp
                                            ? AutofillHints.newPassword
                                            : AutofillHints.password,
                                      ],
                                      validator: (v) => (v ?? '').length >= 6
                                          ? null
                                          : l10n.passwordTooShort,
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                              ),
                              if (!_signUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: const Key('forgotPassword'),
                                    onPressed: _busy ? null : _forgotPassword,
                                    child: Text(l10n.forgotPassword),
                                  ),
                                ),
                            ],
                            const SizedBox(height: AppSpace.md),
                            pill(
                              GlowButton(
                                key: Key(
                                  _usePassword ? 'submit' : 'sendMagicLink',
                                ),
                                onPressed: _busy
                                    ? null
                                    : (_usePassword ? _submit : _magicLink),
                                child: _busy
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : Text(
                                        _usePassword
                                            ? (_signUp
                                                  ? l10n.signUp
                                                  : l10n.signIn)
                                            : l10n.magicLink,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            if (_usePassword)
                              TextButton(
                                key: const Key('toggleMode'),
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _signUp = !_signUp),
                                child: Text(
                                  _signUp ? l10n.haveAccount : l10n.needAccount,
                                ),
                              ),
                            TextButton.icon(
                              key: const Key('usePassword'),
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _usePassword = !_usePassword;
                                      if (!_usePassword) _signUp = false;
                                    }),
                              icon: Icon(
                                _usePassword
                                    ? LucideIcons.mail
                                    : LucideIcons.lock,
                                size: 18,
                              ),
                              label: Text(
                                _usePassword
                                    ? l10n.useMagicLinkInstead
                                    : l10n.usePasswordInstead,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpace.sm),
                // SSO and self-hosting: for the few who need them, one tap away.
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_showMore
                      ? Center(
                          child: TextButton.icon(
                            key: const Key('moreSignInOptions'),
                            onPressed: _busy
                                ? null
                                : () => setState(() => _showMore = true),
                            icon: const Icon(LucideIcons.chevronDown, size: 18),
                            label: Text(l10n.moreSignInOptions),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(),
                            const SizedBox(height: AppSpace.xs),
                            // Only when the server has an identity provider set up.
                            if (methods.sso)
                              Center(
                                child: TextButton.icon(
                                  key: const Key('ssoSignIn'),
                                  onPressed: _busy ? null : _sso,
                                  icon: const Icon(
                                    LucideIcons.building2,
                                    size: 18,
                                  ),
                                  label: Text(l10n.continueWithSso),
                                ),
                              ),
                            // A server on this computer, in one click (D-147).
                            if (localServerSupported)
                              Center(
                                child: TextButton.icon(
                                  key: const Key('runLocalServer'),
                                  onPressed: _busy
                                      ? null
                                      : () => showAdaptiveSheet<void>(
                                          context: context,
                                          builder: (_) =>
                                              const LocalServerSheet(),
                                        ),
                                  icon: const Icon(
                                    LucideIcons.serverCog,
                                    size: 16,
                                  ),
                                  label: Text(l10n.localServer),
                                ),
                              ),
                            const SizedBox(height: AppSpace.xs),
                            // Self-hosted servers: point the app at your own Casama (D-076).
                            Center(
                              child: ActionChip(
                                key: const Key('changeServer'),
                                avatar: Icon(
                                  LucideIcons.server,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                label: Text(
                                  l10n.serverIs(host),
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => changeServerDialog(
                                        context,
                                        ref.read(backendProvider).apiUrl,
                                        title: l10n.server,
                                        label: l10n.serverAddress,
                                        cancel: l10n.cancel,
                                        connect: l10n.connect,
                                        help: l10n.serverHelp,
                                      ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SsoForm extends StatefulWidget {
  const _SsoForm();
  @override
  State<_SsoForm> createState() => _SsoFormState();
}

class _SsoFormState extends State<_SsoForm> {
  final _c = TextEditingController();
  var _invalid = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _c.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.building2,
      title: l10n.continueWithSso,
      subtitle: l10n.ssoHelp,
      submitLabel: l10n.continueLabel,
      cancelLabel: l10n.cancel,
      onSubmit: _submit,
      children: [
        TextField(
          key: const Key('ssoEmail'),
          controller: _c,
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: l10n.workEmail,
            hintText: 'you@company.com',
            prefixIcon: const Icon(LucideIcons.atSign, size: 20),
            errorText: _invalid ? l10n.invalidEmail : null,
          ),
          onChanged: (_) {
            if (_invalid) setState(() => _invalid = false);
          },
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

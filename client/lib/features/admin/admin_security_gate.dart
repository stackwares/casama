import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_security.dart';
import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/page.dart';

/// Leaving the app locks the console; a window merely losing focus doesn't. On a desktop or the
/// web, `inactive` only means another window has focus (a password manager, the mail with the
/// code), and on iOS it's the Face ID sheet for password autofill. The idle timer still runs then.
bool _leftApp(AppLifecycleState state) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.detached;

/// A fresh sign-in in a dialog, for owner actions anywhere in the app (and the console's own
/// confirmations). True once the person verified; [stillValid] can veto a late answer.
Future<bool> showAdminConfirmation(
  BuildContext context, {
  bool sensitive = true,
  bool Function()? stillValid,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        sensitive ? context.l10n.adminConfirmAction : context.l10n.adminUnlock,
      ),
      content: SizedBox(
        width: 360,
        child: AdminAuthentication(
          sensitive: sensitive,
          onVerified: () {
            if (stillValid?.call() ?? true) {
              Navigator.of(dialogContext).pop(true);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancel),
        ),
      ],
    ),
  );
  return accepted == true;
}

/// Console authentication is deliberately separate from the ordinary app session.
class AdminSecurityGate extends ConsumerStatefulWidget {
  const AdminSecurityGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AdminSecurityGate> createState() => _AdminSecurityGateState();
}

class _AdminSecurityGateState extends ConsumerState<AdminSecurityGate>
    with WidgetsBindingObserver {
  Timer? _idle;
  bool _unlocked = false;
  Future<bool>? _confirming;
  int _generation = 0;
  String? _identity;
  Backend? _backendIdentity;
  GoRouter? _router;
  String? _routePath;
  late final Future<bool> Function(bool) _authenticate = _confirm;
  bool _isUnlocked() =>
      mounted &&
      _unlocked &&
      identical(_backendIdentity, ref.read(backendProvider)) &&
      _identity == ref.read(backendProvider).userId;
  late final VoidCallback _lockCallback = _lock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdminSecurity.authenticate = _authenticate;
    AdminSecurity.isUnlocked = _isUnlocked;
    AdminSecurity.lock = _lockCallback;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routeInformationProvider.removeListener(_routeChanged);
      _router = router;
      _routePath = router?.routeInformationProvider.value.uri.path;
      router?.routeInformationProvider.addListener(_routeChanged);
    }
  }

  void _routeChanged() {
    if (_router?.routeInformationProvider.value.uri.path != _routePath) _lock();
  }

  void _activity() {
    if (!_unlocked) return;
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 5), _lock);
  }

  void _lock() {
    _idle?.cancel();
    _generation++;
    AdminSecurity.forgetVerification();
    if (mounted) {
      // Sensitive forms use root popup routes. Remove them too, so locking cannot
      // leave a quota form or confirmation visible above the locked console.
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route is! PopupRoute);
      setState(() => _unlocked = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leftApp(state)) _lock();
  }

  void _unlock() {
    _backendIdentity = ref.read(backendProvider);
    _identity = ref.read(backendProvider).userId;
    setState(() => _unlocked = true);
    _activity();
  }

  /// One dialog at a time: a second change asked for while it's open waits for the same answer
  /// instead of being dropped.
  Future<bool> _confirm(bool sensitive) =>
      _confirming ??= _ask(sensitive).whenComplete(() => _confirming = null);

  Future<bool> _ask(bool sensitive) async {
    if (!_isUnlocked()) return false;
    final generation = _generation;
    final identity = _identity;
    final accepted = await showAdminConfirmation(
      context,
      sensitive: sensitive,
      stillValid: () =>
          mounted &&
          generation == _generation &&
          _isUnlocked() &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    final valid =
        accepted &&
        mounted &&
        generation == _generation &&
        identity == ref.read(backendProvider).userId &&
        _isUnlocked();
    if (valid) _activity();
    return valid;
  }

  @override
  void dispose() {
    _idle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _router?.routeInformationProvider.removeListener(_routeChanged);
    if (identical(AdminSecurity.authenticate, _authenticate)) {
      AdminSecurity.authenticate = null;
      AdminSecurity.isUnlocked = null;
      AdminSecurity.lock = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = _generation;
    final backend = ref.watch(backendProvider);
    // A signed-out or changed identity immediately loses its console view.
    ref.listen(backendProvider, (previous, next) {
      if (!identical(previous, next)) _lock();
    });
    ref.listen(signedInProvider, (_, next) {
      if (next.value != true ||
          (_identity != null &&
              _identity != ref.read(backendProvider).userId)) {
        _lock();
      }
    });
    return Listener(
      onPointerDown: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      onPointerHover: (_) => _activity(),
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) _activity();
          return KeyEventResult.ignored;
        },
        child: _unlocked
            ? widget.child
            : SubPage(
                title: context.l10n.adminConsole,
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: AdminAuthentication(
                        key: ValueKey((backend, backend.userId)),
                        generation: generation,
                        showTwoStepTip: true,
                        onVerified: () {
                          if (mounted &&
                              generation == _generation &&
                              identical(backend, ref.read(backendProvider)) &&
                              WidgetsBinding.instance.lifecycleState ==
                                  AppLifecycleState.resumed) {
                            _unlock();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Password or emailed code, then the authenticator code when the account has two-step sign-in
/// (the server refuses admin work from a session that hasn't passed it).
class AdminAuthentication extends ConsumerStatefulWidget {
  const AdminAuthentication({
    super.key,
    required this.onVerified,
    this.sensitive = false,
    this.generation = 0,
    this.showTwoStepTip = false,
  });
  final int generation;
  final VoidCallback onVerified;
  final bool sensitive;
  final bool showTwoStepTip;

  @override
  ConsumerState<AdminAuthentication> createState() =>
      _AdminAuthenticationState();
}

class _AdminAuthenticationState extends ConsumerState<AdminAuthentication>
    with WidgetsBindingObserver {
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _twoStepCode = TextEditingController();
  bool _busy = false;
  late bool _sent = AdminSecurity.codeSentFor(_identity);
  bool _failed = false;
  // A session that signed in but still owes its code (a lock while the authenticator app was
  // open, say) starts at the code.
  late bool _twoStep = _backend.twoStepCodeNeeded;
  late final Backend _backend = ref.read(backendProvider);
  late final String? _identity = _backend.userId;
  late final String? _email = _backend.userEmail;
  late final Future<bool> _hasTwoStep = widget.showTwoStepTip
      ? _backend.twoStepFactors().then(
          (f) => f.isNotEmpty,
          onError: (_) => true,
        )
      : Future.value(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdminSecurity.authFormOpened();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leftApp(state)) {
      _password.clear();
      _code.clear();
      _twoStepCode.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password.dispose();
    _code.dispose();
    _twoStepCode.dispose();
    AdminSecurity.authFormClosed();
    super.dispose();
  }

  void _done() {
    AdminSecurity.verified(_identity);
    AdminSecurity.codeSentTo = null;
    widget.onVerified();
  }

  Future<void> _run(
    Future<void> Function(String email) action, {
    bool verify = false,
  }) async {
    final generation = widget.generation;
    final email = _email;
    if (_busy || email == null || _identity == null) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (_backend.userId != _identity) throw StateError('Account changed');
      await action(email);
      if (_backend.userId != _identity) {
        await _backend.signOut();
        throw StateError('Account changed');
      }
      if (mounted && verify && generation == widget.generation) {
        if (_backend.twoStepCodeNeeded) {
          setState(() => _twoStep = true);
        } else {
          _done();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      // Never leave a credential in a mounted form after a submission.
      if (mounted) {
        _password.clear();
        _code.clear();
        _twoStepCode.clear();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _passTwoStep() =>
      _run((_) => _backend.passTwoStep(_twoStepCode.text), verify: true);

  Widget _status(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (_failed)
        Text(
          context.l10n.adminAuthenticationFailed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_twoStep) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminTwoStepHelp),
          const SizedBox(height: 16),
          TextField(
            key: const Key('adminTwoStepCode'),
            controller: _twoStepCode,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(labelText: l10n.twoStepCode),
            onSubmitted: (_) => _passTwoStep(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('adminVerifyTwoStep'),
            onPressed: _busy ? null : _passTwoStep,
            child: Text(l10n.twoStepVerify),
          ),
          _status(context),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.sensitive ? l10n.adminConfirmActionHelp : l10n.adminLockedHelp,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('adminPassword'),
          controller: _password,
          enabled: !_busy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l10n.password),
          onSubmitted: (_) => _run(
            (email) => _backend.signIn(email, _password.text),
            verify: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('adminUnlockPassword'),
          onPressed: _busy || _email == null
              ? null
              : () => _run(
                  (email) => _backend.signIn(email, _password.text),
                  verify: true,
                ),
          child: Text(l10n.adminVerifyPassword),
        ),
        TextButton(
          key: const Key('adminSendCode'),
          onPressed: _busy || _email == null
              ? null
              : () => _run((email) async {
                  await _backend.sendMagicLink(email);
                  AdminSecurity.codeSentTo = _identity;
                  AdminSecurity.codeSentAt = DateTime.now();
                  if (mounted) setState(() => _sent = true);
                }),
          child: Text(l10n.adminSendCode),
        ),
        if (_sent) ...[
          Text(l10n.adminCodeSent),
          const SizedBox(height: 12),
          TextField(
            key: const Key('adminCode'),
            controller: _code,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(labelText: l10n.emailCodeLabel),
            onSubmitted: (_) => _run(
              (email) => _backend.verifyEmailCode(email, _code.text),
              verify: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('adminUnlockCode'),
            onPressed: _busy
                ? null
                : () => _run(
                    (email) => _backend.verifyEmailCode(email, _code.text),
                    verify: true,
                  ),
            child: Text(l10n.adminVerifyCode),
          ),
        ],
        _status(context),
        // An email inbox left open on the same device can unlock with a code; an authenticator
        // can't be read from here.
        FutureBuilder<bool>(
          future: _hasTwoStep,
          builder: (context, has) => has.data == false
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    l10n.adminTwoStepTip,
                    key: const Key('adminTwoStepTip'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart' show AdminPinState;
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/admin_device_key.dart';
import '../../core/admin_security.dart';
import '../../core/backend.dart';
import '../../core/passkeys.dart';
import '../../core/providers.dart';
import '../app_lock/app_lock.dart';
import '../app_lock/lock_screen.dart' show PinField;
import '../../core/telemetry.dart';
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
  bool allowPin = true,
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
          allowPin: allowPin,
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

/// A name for this phone in Admin → Security.
String _deviceName(BuildContext context) {
  final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
  final kind = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => tablet ? 'iPad' : 'iPhone',
    _ => tablet ? 'Android tablet' : 'Android phone',
  };
  final d = DateTime.now();
  return '$kind · ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Sets this phone up for the screen-lock check (D-453): a check that isn't the PIN (unless one
/// was just made), then Face ID or the passcode once to make the key. True when it's on.
Future<bool> enrollAdminDevice(BuildContext context, WidgetRef ref) async {
  final backend = ref.read(backendProvider);
  final me = backend.userId;
  if (!(AdminSecurity.recentlyVerified(me) && AdminSecurity.lastVerifiedMethod != 'pin')) {
    if (!await showAdminConfirmation(context, allowPin: false)) return false;
  }
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final name = _deviceName(context);
  final ok = await runGuarded(
    context,
    () => AdminSecurity.duringSystemSheet(
      () => ref
          .read(adminDeviceKeysProvider)
          .enroll(backend, name: name, reason: l10n.adminDeviceSetupReason),
    ),
  );
  if (ok == true && context.mounted) showSuccess(context, l10n.adminDeviceOn);
  return ok == true;
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
    final path = _router?.routeInformationProvider.value.uri.path;
    if (path != _routePath) _lock('route $_routePath -> $path');
  }

  void _activity() {
    if (!_unlocked) return;
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 5), () => _lock('idle'));
  }

  DateTime? _unlockedAt;

  void _lock([String reason = 'lock now']) {
    // A lock right after an unlock is the loop Oliver saw (D-453): report why, to find it.
    final since = _unlockedAt;
    if (_unlocked && since != null && DateTime.now().difference(since) < const Duration(seconds: 5)) {
      unawaited(
        Telemetry.captureException(
          StateError('Admin console locked right after unlocking: $reason'),
          StackTrace.current,
          warning: true,
          context: {'reason': reason},
        ),
      );
    }
    _unlockedAt = null;
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
    // A passkey or Face ID sheet can pause the app while it's up; that isn't leaving.
    if (_leftApp(state) && AdminSecurity.systemSheets == 0) _lock('left app ($state)');
  }

  void _unlock() {
    _backendIdentity = ref.read(backendProvider);
    _identity = ref.read(backendProvider).userId;
    _unlockedAt = DateTime.now();
    setState(() => _unlocked = true);
    _activity();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDeviceKey());
  }

  /// After a passkey or password check on a phone with a screen lock and no key yet: offer Face ID
  /// for next time (D-453). Not after the PIN, which can't add a device.
  Future<void> _offerDeviceKey() async {
    final backend = ref.read(backendProvider);
    final userId = backend.userId;
    final keys = ref.read(adminDeviceKeysProvider);
    final method = AdminSecurity.lastVerifiedMethod;
    if (userId == null || method == 'pin' || method == 'device' || method == null) return;
    if (!AdminSecurity.recentlyVerified(userId)) return;
    if (!await keys.available() ||
        await keys.keyId(userId) != null ||
        await keys.declined(userId)) {
      return;
    }
    if (!mounted || !_isUnlocked()) return;
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminDeviceOfferTitle),
        content: Text(l10n.adminDeviceOfferBody),
        actions: [
          TextButton(
            key: const Key('adminDeviceOfferNo'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.adminDeviceOfferNo),
          ),
          FilledButton(
            key: const Key('adminDeviceOfferYes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.adminDeviceOfferYes),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (yes != true) {
      if (yes == false) await keys.setDeclined(userId, true);
      return;
    }
    await enrollAdminDevice(context, ref);
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
      if (!identical(previous, next)) _lock('account changed');
    });
    ref.listen(signedInProvider, (_, next) {
      if (next.value != true ||
          (_identity != null &&
              _identity != ref.read(backendProvider).userId)) {
        _lock('signed out or switched');
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

/// A passkey, the admin PIN, or a password or emailed code (then the authenticator code when the
/// account has two-step sign-in; the server refuses admin work from a session that hasn't passed
/// it). A passkey or PIN is a check the server records on this sign-in session and counts as both
/// steps (D-452). On a phone set up for it, Face ID, a fingerprint or the device passcode signs a
/// challenge with a key in the phone's secure chip, and that is the whole check too (D-453).
class AdminAuthentication extends ConsumerStatefulWidget {
  const AdminAuthentication({
    super.key,
    required this.onVerified,
    this.sensitive = false,
    this.generation = 0,
    this.showTwoStepTip = false,
    this.allowPin = true,
  });
  final int generation;
  final VoidCallback onVerified;
  final bool sensitive;
  final bool showTwoStepTip;

  /// Off when changing the PIN itself: that takes a passkey or password.
  final bool allowPin;

  /// The last time a form opened Face ID by itself. A new lock screen within [autoGap] doesn't
  /// open it again, so nothing can turn into a loop of prompts (D-453).
  static DateTime? lastAutoDevice;
  static const autoGap = Duration(seconds: 30);

  @override
  ConsumerState<AdminAuthentication> createState() =>
      _AdminAuthenticationState();
}

class _AdminAuthenticationState extends ConsumerState<AdminAuthentication>
    with WidgetsBindingObserver {
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _twoStepCode = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  /// What a wrong PIN left: tries, or the PIN turned off.
  String? _pinNote;
  late Future<AdminPinState?> _pinState = _loadPin();

  Future<AdminPinState?> _loadPin() async {
    if (!widget.allowPin) return null;
    try {
      return await _backend.adminPinState();
    } catch (_) {
      return null;
    }
  }
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

  /// The account has a passkey this app can use here.
  late final Future<bool> _hasPasskey = () async {
    try {
      if (!(await ref.read(authMethodsProvider.future)).passkeys) return false;
      return (await _backend.passkeys()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }();

  /// Passkeys work here but the account has none yet (the lock screen suggests one).
  late final Future<bool> _suggestPasskey = widget.showTwoStepTip
      ? () async {
          try {
            return (await ref.read(authMethodsProvider.future)).passkeys &&
                !await _hasPasskey;
          } catch (_) {
            return false;
          }
        }()
      : Future.value(false);

  late final AdminDeviceKeys _keys = ref.read(adminDeviceKeysProvider);

  /// This phone has its key for this account (D-453).
  late final Future<bool> _deviceReady = () async {
    try {
      return await _keys.available() && await _keys.keyId(_identity) != null;
    } catch (_) {
      return false;
    }
  }();
  bool _devicePrompted = false;
  bool _deviceGone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdminSecurity.authFormOpened();
    // The device check opens by itself, once, when the form shows in the foreground.
    _deviceReady.then((ready) {
      if (ready &&
          mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _verifyWithDevice(auto: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leftApp(state) && AdminSecurity.systemSheets == 0) {
      _password.clear();
      _code.clear();
      _twoStepCode.clear();
      _pin.clear();
    }
    if (state == AppLifecycleState.resumed) {
      _deviceReady.then((ready) {
        if (ready && mounted) _verifyWithDevice(auto: true);
      });
    }
  }

  /// Runs a system sheet without the console (or the app lock, D-375) counting it as time away.
  Future<T> _sheet<T>(Future<T> Function() run) async {
    late T out;
    Object? error;
    StackTrace? stack;
    await AdminSecurity.duringSystemSheet(
      () => ref.read(appLockProvider.notifier).prompt(() async {
        try {
          out = await run();
        } catch (e, s) {
          error = e;
          stack = s;
        }
        return UnlockResult.ok;
      }),
    );
    if (error != null) Error.throwWithStackTrace(error!, stack!);
    return out;
  }

  /// Face ID, a fingerprint or the passcode signs the server's challenge with this phone's key
  /// (D-453): a check the server records on this session, as both steps.
  Future<void> _verifyWithDevice({bool auto = false}) async {
    if (auto) {
      final last = AdminAuthentication.lastAutoDevice;
      if (_devicePrompted ||
          _busy ||
          (last != null && DateTime.now().difference(last) < AdminAuthentication.autoGap)) {
        return;
      }
      AdminAuthentication.lastAutoDevice = DateTime.now();
    }
    _devicePrompted = true;
    final reason = context.l10n.adminDeviceReason;
    await _run((_) async {
      try {
        final at = await _sheet(() => _keys.check(_backend, reason: reason));
        if (at == null) throw const _Closed();
        AdminSecurity.checked(at);
      } on DeviceKeyProblem catch (e) {
        if (e.gone && mounted) setState(() => _deviceGone = true);
        if (mounted) showMessage(context, e.message);
        rethrow;
      }
    }, verify: true, method: 'device');
  }

  /// A passkey check the server records on this session (D-452): the session stays, and it counts
  /// as both steps.
  Future<void> _verifyWithPasskey() => _run((_) async {
    final at = await _sheet(_backend.adminPasskeyCheck);
    if (at == null) throw const _Closed();
    AdminSecurity.checked(at);
  }, verify: true, method: 'passkey');

  Future<void> _verifyWithPin() async {
    final pin = _pin.text;
    if (pin.length != 6) return;
    var wrong = false;
    await _run((_) async {
      try {
        AdminSecurity.checked(await _backend.adminPinCheck(pin));
      } catch (_) {
        wrong = true;
        rethrow;
      }
    }, verify: true, method: 'pin');
    if (!wrong || !mounted) return;
    // Show what's left, or that the PIN is off now.
    final state = await _loadPin();
    if (!mounted) return;
    setState(() {
      _pinState = Future.value(state);
      _pinNote = state == null || !state.set_
          ? context.l10n.adminPinTurnedOff
          : context.l10n.adminPinWrong(state.triesLeft);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _password.dispose();
    _code.dispose();
    _twoStepCode.dispose();
    _pin.dispose();
    AdminSecurity.authFormClosed();
    super.dispose();
  }

  void _done([String method = 'password']) {
    AdminSecurity.verified(_identity, method: method);
    AdminSecurity.codeSentTo = null;
    widget.onVerified();
  }

  Future<void> _run(
    Future<void> Function(String email) action, {
    bool verify = false,
    String? method,
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
        // A passkey or PIN check is both steps; a password or emailed code still owes the code.
        if (method == null && _backend.twoStepCodeNeeded) {
          setState(() => _twoStep = true);
        } else {
          _done(method ?? 'password');
        }
      }
    } on _Closed {
      // The person closed the system sheet: nothing failed.
    } on PasskeyProblem catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        showMessage(context, e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      // Never leave a credential in a mounted form after a submission.
      if (mounted) {
        _password.clear();
        _code.clear();
        _twoStepCode.clear();
        _pin.clear();
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
          // A passkey is both steps (D-452).
          FutureBuilder<bool>(
            future: _hasPasskey,
            builder: (context, has) => has.data == true
                ? TextButton.icon(
                    key: const Key('adminTwoStepPasskey'),
                    onPressed: _busy ? null : _verifyWithPasskey,
                    icon: const Icon(LucideIcons.keyRound),
                    label: Text(l10n.adminVerifyPasskey),
                  )
                : const SizedBox.shrink(),
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
        FutureBuilder<List<Object?>>(
          future: Future.wait<Object?>([_deviceReady, _hasPasskey, _pinState]),
          builder: (context, snap) {
            final device = snap.data?[0] == true && !_deviceGone;
            final passkey = snap.data?[1] == true;
            final pinState = snap.data?[2] as AdminPinState?;
            final pin = widget.allowPin && pinState?.set_ == true;
            if (!device && !passkey && !pin && _pinNote == null) {
              return const SizedBox.shrink();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (device)
                  FilledButton.icon(
                    key: const Key('adminUnlockDevice'),
                    onPressed: _busy ? null : _verifyWithDevice,
                    icon: const Icon(LucideIcons.fingerprint),
                    label: Text(l10n.adminUnlockDevice),
                  ),
                if (device && passkey) const SizedBox(height: 8),
                if (passkey)
                  (device ? FilledButton.tonalIcon : FilledButton.icon)(
                    key: const Key('adminPasskey'),
                    onPressed: _busy || _email == null
                        ? null
                        : _verifyWithPasskey,
                    icon: const Icon(LucideIcons.keyRound),
                    label: Text(l10n.adminVerifyPasskey),
                  ),
                if (pin) ...[
                  if (device || passkey) const SizedBox(height: 16),
                  Text(l10n.adminPinLabel),
                  const SizedBox(height: 8),
                  PinField(
                    key: const Key('adminPin'),
                    controller: _pin,
                    enabled: !_busy,
                    autofocus: !device && !passkey,
                    onComplete: (_) => _verifyWithPin(),
                  ),
                ],
                if (_pinNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _pinNote!,
                      key: const Key('adminPinNote'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.adminOrPassword,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
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
        FutureBuilder<bool>(
          future: _suggestPasskey,
          builder: (context, suggest) => suggest.data == true
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.adminPasskeyTip,
                    key: const Key('adminPasskeyTip'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The person closed a system sheet.
class _Closed implements Exception {
  const _Closed();
}

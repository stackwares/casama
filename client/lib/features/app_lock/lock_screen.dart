import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import 'app_lock.dart';
import 'confirm_identity.dart';
import 'pin_store.dart';

/// Phones and tablets: the app switcher shows a picture of the app, so the cover goes up as soon
/// as the app stops being in front. Computers and the web only cover a hidden window.
bool get _touchDevice =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// A computer: there, being behind another app counts as time away (see [AppLockController.isAway]).
bool get _computer =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

/// What unlocks this device, in the words its owner knows it by.
String deviceUnlockName(AppLocalizations l10n) =>
    switch (defaultTargetPlatform) {
      TargetPlatform.iOS => l10n.appLockDeviceIos,
      TargetPlatform.android => l10n.appLockDeviceAndroid,
      TargetPlatform.macOS => l10n.appLockDeviceMac,
      TargetPlatform.windows => l10n.appLockDeviceWindows,
      _ => l10n.appLockDeviceOther,
    };

/// The app lock over the whole app (D-375): the lock screen while locked, the setup a workspace
/// requires, and a plain cover while the app isn't in front. Under it, the app keeps its state but
/// draws nothing, takes no focus or taps, and its animations stop, so nothing behind the lock
/// shows or reacts. Links, notification taps and shares opened meanwhile still go to their page,
/// which is there once the person unlocks.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  AppLifecycleState? _state = WidgetsBinding.instance.lifecycleState;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (s) {
        ref.read(appLockProvider.notifier).lifecycle(s, computer: _computer);
        if (mounted) setState(() => _state = s);
      },
    );
    // Android's Recents picture and screenshot flags follow the saved settings from launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(AppLockNative.apply(ref.read(appLockSettingsProvider)));
      }
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  bool get _away {
    final s = _state;
    if (s == null || s == AppLifecycleState.resumed) return false;
    return _touchDevice ||
        s == AppLifecycleState.hidden ||
        s == AppLifecycleState.paused;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider).value == true;
    final settings = ref.watch(appLockSettingsProvider);
    final lock = ref.watch(appLockProvider);
    final active =
        signedIn && settings.activeFor(ref.watch(backendProvider).userId);
    final locked = active && lock.locked;
    // A workspace requires the lock and it's off: set it up first (after the sign-in's own steps).
    final setup =
        !active &&
        ref.watch(signInFinishedProvider) &&
        ref.watch(appLockRequiredByProvider) != null;
    final hide = locked || setup;
    final covered =
        active &&
        !hide &&
        _away &&
        !ref.read(appLockProvider.notifier).prompting;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: hide,
          child: Visibility(
            visible: !hide,
            maintainState: true,
            child: widget.child,
          ),
        ),
        if (locked)
          const _OwnNavigator(
            key: ValueKey('appLockLayer'),
            child: LockScreen(),
          )
        else if (setup)
          const _OwnNavigator(
            key: ValueKey('appLockSetupLayer'),
            child: AppLockRequiredScreen(),
          ),
        if (covered) const PrivacyCover(),
      ],
    );
  }
}

/// The lock's pages sit outside the app's router: a navigator of their own gives them sheets,
/// dialogs and text selection.
class _OwnNavigator extends StatelessWidget {
  const _OwnNavigator({super.key, required this.child});
  final Widget child;

  @override
  // The app's navigator owns the app's hero controller; this one has none.
  Widget build(BuildContext context) => HeroControllerScope.none(
    child: Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ),
  );
}

/// What shows in the app switcher (and over a hidden window) while the lock is on.
class PrivacyCover extends StatelessWidget {
  const PrivacyCover({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('appLockCover'),
      color: scheme.surface,
      child: Center(
        child: Icon(LucideIcons.lock, size: 40, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// The page shown while the app is locked.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  late final AppLifecycleListener _lifecycle;
  final _pin = TextEditingController();
  var _busy = false;
  var _unavailable = false;
  String? _error;

  /// The system prompt opens by itself once each time the app comes to the front, not again
  /// after the person closed it.
  var _asked = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _askOnce,
      onHide: () => _asked = false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = WidgetsBinding.instance.lifecycleState;
      if (s == null || s == AppLifecycleState.resumed) _askOnce();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _pin.dispose();
    super.dispose();
  }

  LockMethod get _method => ref.read(appLockSettingsProvider).method;

  void _askOnce() {
    // A passkey sheet on the web needs a click first; a PIN needs typing.
    if (_asked || !mounted || _method != LockMethod.device) return;
    _asked = true;
    unawaited(_unlock());
  }

  Future<void> _unlock({String? pin}) async {
    if (_busy) return;
    final l10n = context.l10n;
    final unlockers = ref.read(unlockersProvider);
    final backend = ref.read(backendProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await runGuarded(
      context,
      () => ref
          .read(appLockProvider.notifier)
          .unlock(
            () => switch (_method) {
              LockMethod.device => unlockers.device(l10n.appLockUnlockReason),
              LockMethod.pin => unlockers.pin(pin ?? ''),
              LockMethod.passkey => unlockers.passkey(
                backend.confirmWithPasskey,
              ),
            },
          ),
    );
    if (!mounted) return;
    final failures = ref.read(appLockProvider).failures;
    setState(() {
      _busy = false;
      switch (result) {
        case UnlockResult.failed:
          _error = _method == LockMethod.pin
              ? l10n.appLockPinWrong(
                  (maxPinFailures - failures).clamp(0, maxPinFailures),
                )
              : l10n.appLockFailed;
          _pin.clear();
        case UnlockResult.unavailable:
          _unavailable = true;
        case UnlockResult.ok || UnlockResult.cancelled || null:
          break;
      }
    });
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.signOut,
      message: l10n.appLockSignOutConfirm,
      confirmLabel: l10n.signOut,
      confirmKey: const Key('appLockConfirmSignOut'),
      destructive: true,
    );
    if (ok && mounted) {
      await runGuarded(context, ref.read(appLockProvider.notifier).signOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final method = ref.watch(appLockSettingsProvider.select((s) => s.method));
    final failures = ref.watch(appLockProvider.select((s) => s.failures));
    final pinStopped = method == LockMethod.pin && failures >= maxPinFailures;
    final ringing =
        (ref.watch(ringingCallsProvider).value ?? const []).isNotEmpty;
    final email = ref.read(backendProvider).userEmail;
    final note = _unavailable
        ? l10n.appLockUnavailable
        : pinStopped
        ? l10n.appLockPinStopped
        : _error;
    return Scaffold(
      key: const Key('appLockScreen'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.lock,
                        size: 32,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    l10n.appLockLocked,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (ringing) ...[
                    const SizedBox(height: AppSpace.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.phoneIncoming,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            l10n.appLockCallRinging,
                            key: const Key('appLockRinging'),
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  if (!_unavailable && !pinStopped)
                    if (method == LockMethod.pin)
                      PinField(
                        key: const Key('appLockPin'),
                        controller: _pin,
                        enabled: !_busy,
                        onComplete: (pin) => _unlock(pin: pin),
                      )
                    else
                      FilledButton.icon(
                        key: const Key('appLockUnlock'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _busy ? null : _unlock,
                        icon: Icon(
                          method == LockMethod.passkey
                              ? LucideIcons.keyRound
                              : LucideIcons.scanFace,
                          size: 20,
                        ),
                        label: Text(
                          method == LockMethod.passkey
                              ? l10n.appLockUnlockWithPasskey
                              : l10n.appLockUnlock,
                        ),
                      ),
                  if (!_unavailable &&
                      !pinStopped &&
                      method == LockMethod.device) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      l10n.appLockUnlockWith(deviceUnlockName(l10n)),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      note,
                      key: const Key('appLockNote'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: _unavailable || pinStopped
                            ? scheme.onSurface
                            : scheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  // Always there, so nobody is ever stuck behind a check that can't pass: signing
                  // out shows nothing, and signing in again is the way back.
                  TextButton(
                    key: const Key('appLockSignOut'),
                    onPressed: _busy ? null : _signOut,
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

/// A workspace requires the lock and it's off on this device (D-375).
class AppLockRequiredScreen extends ConsumerStatefulWidget {
  const AppLockRequiredScreen({super.key});

  @override
  ConsumerState<AppLockRequiredScreen> createState() =>
      _AppLockRequiredScreenState();
}

class _AppLockRequiredScreenState extends ConsumerState<AppLockRequiredScreen> {
  var _busy = false;

  Future<void> _turnOn() async {
    setState(() => _busy = true);
    await turnOnAppLock(context, ref);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.signOut,
      message: l10n.signOutConfirm,
      confirmLabel: l10n.signOut,
      destructive: true,
    );
    if (ok && mounted) {
      await runGuarded(context, ref.read(backendProvider).signOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final workspace = ref.watch(appLockRequiredByProvider) ?? '';
    // The web unlocks with a passkey: without passkeys on this server, there's no way to comply.
    final methods = ref.watch(authMethodsProvider);
    final noWay = kIsWeb && methods.hasValue && methods.value?.passkeys != true;
    return Scaffold(
      key: const Key('appLockRequired'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Icon(
                      LucideIcons.shieldCheck,
                      size: 44,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    l10n.appLockRequiredTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.appLockRequiredBody(workspace),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (noWay)
                    Text(
                      l10n.appLockRequiredNoWay,
                      key: const Key('appLockRequiredNoWay'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium,
                    )
                  else
                    FilledButton(
                      key: const Key('appLockRequiredTurnOn'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _busy ? null : _turnOn,
                      child: Text(l10n.appLockTurnOn),
                    ),
                  const SizedBox(height: AppSpace.md),
                  TextButton(
                    onPressed: _busy ? null : _signOut,
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

/// Six hidden digits; [onComplete] runs once all six are in.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.onComplete,
    this.enabled = true,
    this.autofocus = true,
  });
  final TextEditingController controller;
  final ValueChanged<String> onComplete;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    autofocus: autofocus,
    obscureText: true,
    textAlign: TextAlign.center,
    keyboardType: TextInputType.number,
    maxLength: PinStore.length,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(PinStore.length),
    ],
    style: context.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
    decoration: InputDecoration(
      hintText: context.l10n.appLockPinHint,
      counterText: '',
    ),
    onChanged: (v) {
      if (v.length == PinStore.length) onComplete(v);
    },
  );
}

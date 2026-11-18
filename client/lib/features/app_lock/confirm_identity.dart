import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import 'app_lock.dart';
import 'lock_screen.dart';
import 'pin_store.dart';

/// Turns the app lock on (D-375): picks this device's way to unlock, checks it once (or sets the
/// PIN), and saves. True when it's on.
Future<bool> turnOnAppLock(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final unlockers = ref.read(unlockersProvider);
  final lock = ref.read(appLockProvider.notifier);
  final backend = ref.read(backendProvider);
  final passkeysOn = (await ref.read(authMethodsProvider.future)).passkeys;
  final method = await unlockers.bestMethod(passkeysOn: passkeysOn);
  if (!context.mounted) return false;
  switch (method) {
    case null:
      showMessage(context, l10n.appLockNoWayHere);
      return false;
    case LockMethod.device:
      final result = await lock.prompt(
        () => unlockers.device(l10n.appLockTurnOnReason),
      );
      if (!context.mounted) return false;
      if (result != UnlockResult.ok) {
        if (result != UnlockResult.cancelled) {
          showMessage(context, l10n.appLockNotChecked);
        }
        return false;
      }
    case LockMethod.pin:
      final pin = await showPinSetup(context);
      if (pin == null || !context.mounted) return false;
      if (!await PinStore.save(pin)) {
        if (context.mounted) showMessage(context, l10n.appLockPinNotSaved);
        return false;
      }
    case LockMethod.passkey:
      // A passkey has to exist first; making one checks the person too.
      final existing = await runGuarded(context, backend.passkeys);
      if (existing == null || !context.mounted) return false;
      if (existing.isEmpty) {
        final added = await runGuarded(context, backend.addPasskey);
        if (added != true || !context.mounted) return false;
      }
      final result = await runGuarded(
        context,
        () => lock.prompt(() => unlockers.passkey(backend.confirmWithPasskey)),
      );
      if (!context.mounted) return false;
      if (result != UnlockResult.ok) {
        if (result != null && result != UnlockResult.cancelled) {
          showMessage(context, l10n.appLockNotChecked);
        }
        return false;
      }
  }
  final settings = ref.read(appLockSettingsProvider);
  await ref
      .read(appLockSettingsProvider.notifier)
      .save(
        settings.copyWith(
          enabled: true,
          method: method,
          userId: backend.userId,
        ),
      );
  return true;
}

/// Asks the person to prove it's them again before a risky action (D-375): deleting the account,
/// new keys, billing changes, exports, approving a high-risk request, taking over a computer.
/// Uses the app lock's way when it's on; otherwise this device's own unlock, a passkey on the web
/// when the person has one, or nothing where there's nothing to ask with. Off when the person
/// turned "Confirm risky actions" off, unless [always] (changing the lock itself). True to go
/// ahead.
Future<bool> confirmIdentity(
  BuildContext context,
  WidgetRef ref, {
  bool always = false,
}) async {
  final settings = ref.read(appLockSettingsProvider);
  if (!settings.askBeforeRisky && !always) return true;
  final l10n = context.l10n;
  final unlockers = ref.read(unlockersProvider);
  final lock = ref.read(appLockProvider.notifier);
  final backend = ref.read(backendProvider);
  final locked = settings.activeFor(backend.userId);
  LockMethod? method;
  if (locked) {
    method = settings.method;
  } else if (kIsWeb) {
    if ((await ref.read(authMethodsProvider.future)).passkeys) {
      try {
        if ((await backend.passkeys()).isNotEmpty) method = LockMethod.passkey;
      } catch (_) {}
    }
  } else if (await unlockers.deviceAvailable()) {
    method = LockMethod.device;
  } else if (await unlockers.pinSet()) {
    method = LockMethod.pin;
  }
  // Nothing on this device to ask with.
  if (method == null) return true;
  if (!context.mounted) return false;
  final UnlockResult? result;
  switch (method) {
    case LockMethod.device:
      result = await lock.prompt(
        () => unlockers.device(l10n.appLockConfirmReason),
      );
    case LockMethod.passkey:
      result = await runGuarded(
        context,
        () => lock.prompt(() => unlockers.passkey(backend.confirmWithPasskey)),
      );
    case LockMethod.pin:
      result = await showAdaptiveSheet<UnlockResult>(
        context: context,
        builder: (_) => const _PinCheckSheet(),
      );
  }
  if (!context.mounted) return false;
  switch (result) {
    case UnlockResult.ok:
      return true;
    // The lock is off and this device can't check right now: nothing to ask with.
    case UnlockResult.unavailable when !locked:
      return true;
    case UnlockResult.failed || UnlockResult.unavailable:
      showMessage(context, l10n.appLockNotChecked);
      return false;
    case UnlockResult.cancelled || null:
      return false;
  }
}

/// Choose a PIN, then enter it again. The PIN, or null when the person closed the sheet.
Future<String?> showPinSetup(BuildContext context) => showAdaptiveSheet<String>(
  context: context,
  builder: (_) => const _PinSetupSheet(),
);

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet();

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  final _field = TextEditingController();
  String? _first;
  var _mismatch = false;

  @override
  void initState() {
    super.initState();
    _field.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _entered(String pin) {
    final first = _first;
    if (first == null) {
      setState(() {
        _first = pin;
        _mismatch = false;
        _field.clear();
      });
    } else if (first == pin) {
      Navigator.of(context).pop(pin);
    } else {
      setState(() {
        _first = null;
        _mismatch = true;
        _field.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final again = _first != null;
    return FormSheet(
      icon: LucideIcons.keyRound,
      title: again ? l10n.appLockPinAgainTitle : l10n.appLockPinSetupTitle,
      subtitle: l10n.appLockPinSetupBody,
      submitLabel: l10n.appLockPinNext,
      onSubmit: _field.text.length == PinStore.length
          ? () => _entered(_field.text)
          : null,
      footer: _mismatch
          ? FormNote(l10n.appLockPinMismatch, color: context.colorScheme.error)
          : null,
      children: [
        // A new field for the second entry, so the keyboard and focus start fresh.
        PinField(
          key: ValueKey(again ? 'appLockPinAgain' : 'appLockPinNew'),
          controller: _field,
          onComplete: _entered,
        ),
      ],
    );
  }
}

/// The PIN before a risky action: answers [UnlockResult.ok] once it's right.
class _PinCheckSheet extends ConsumerStatefulWidget {
  const _PinCheckSheet();

  @override
  ConsumerState<_PinCheckSheet> createState() => _PinCheckSheetState();
}

class _PinCheckSheetState extends ConsumerState<_PinCheckSheet> {
  final _field = TextEditingController();
  var _busy = false;
  var _wrong = 0;

  @override
  void initState() {
    super.initState();
    _field.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _check(String pin) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref.read(unlockersProvider).pin(pin);
    if (!mounted) return;
    if (result == UnlockResult.ok || result == UnlockResult.unavailable) {
      Navigator.of(context).pop(result);
      return;
    }
    _wrong++;
    if (_wrong >= maxPinFailures) {
      Navigator.of(context).pop(UnlockResult.failed);
      return;
    }
    setState(() {
      _busy = false;
      _field.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.shieldCheck,
      title: l10n.appLockConfirmTitle,
      submitLabel: l10n.appLockPinNext,
      busy: _busy,
      onSubmit: _field.text.length == PinStore.length
          ? () => _check(_field.text)
          : null,
      footer: _wrong > 0
          ? FormNote(
              l10n.appLockPinWrong(maxPinFailures - _wrong),
              color: context.colorScheme.error,
            )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: PinField(
            key: const Key('appLockPinCheck'),
            controller: _field,
            enabled: !_busy,
            onComplete: _check,
          ),
        ),
      ],
    );
  }
}

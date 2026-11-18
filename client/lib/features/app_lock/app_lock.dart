import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/passkeys.dart';
import '../../core/providers.dart';
import 'pin_store.dart';
import 'session_store.dart';

/// The app lock (D-375): opening Casama asks for Face ID, Touch ID, a fingerprint, the device
/// passcode or Windows Hello. Where the system has none of those (Linux, Android 8), it asks for a
/// PIN kept in the system keychain. On the web it asks for one of the person's passkeys, which
/// the Auth server checks.
///
/// The lock is a cover over the app on this device. Someone who can read the app's files can
/// still read its offline cache; moving the sign-in into the keychain (see [AuthSessionStore]) is
/// what keeps the session itself out of plain files while the lock is on.

/// How long Casama can be away (in the background, minimised, or behind another app on a
/// computer) before it locks again.
enum LockAfter {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5)),
  fifteenMinutes(Duration(minutes: 15)),
  oneHour(Duration(hours: 1));

  const LockAfter(this.duration);
  final Duration duration;
}

/// What unlocks the app on this device.
enum LockMethod {
  /// Face ID, Touch ID, a fingerprint, the device passcode or Windows Hello.
  device,

  /// A six-digit PIN, where the system has no unlock of its own to offer.
  pin,

  /// One of the person's passkeys (the web).
  passkey,
}

/// The lock's settings on this device, for one account.
@immutable
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.method = LockMethod.device,
    this.after = LockAfter.oneMinute,
    this.askBeforeRisky = true,
    this.blockScreenshots = false,
    this.userId,
  });

  final bool enabled;
  final LockMethod method;
  final LockAfter after;

  /// Ask for the unlock again before risky actions (deleting the account, new keys, billing,
  /// exports, high-risk approvals, takeovers), with or without the lock.
  final bool askBeforeRisky;

  /// Android: no screenshots or screen recordings of the app.
  final bool blockScreenshots;

  /// The account the lock belongs to. Another account signing in on this device starts with the
  /// lock off, so it never meets someone else's PIN.
  final String? userId;

  /// The lock is on for [currentUser].
  bool activeFor(String? currentUser) =>
      enabled && userId != null && userId == currentUser;

  AppLockSettings copyWith({
    bool? enabled,
    LockMethod? method,
    LockAfter? after,
    bool? askBeforeRisky,
    bool? blockScreenshots,
    String? userId,
  }) => AppLockSettings(
    enabled: enabled ?? this.enabled,
    method: method ?? this.method,
    after: after ?? this.after,
    askBeforeRisky: askBeforeRisky ?? this.askBeforeRisky,
    blockScreenshots: blockScreenshots ?? this.blockScreenshots,
    userId: userId ?? this.userId,
  );

  /// The lock off, keeping the person's other choices.
  AppLockSettings get off =>
      AppLockSettings(after: after, askBeforeRisky: askBeforeRisky);

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'method': method.name,
    'after': after.name,
    'ask_before_risky': askBeforeRisky,
    'block_screenshots': blockScreenshots,
    'user_id': ?userId,
  };

  static AppLockSettings fromJson(Object? json) {
    if (json is! Map) return const AppLockSettings();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppLockSettings(
      enabled: json['enabled'] == true,
      method: pick(LockMethod.values, json['method'], LockMethod.device),
      after: pick(LockAfter.values, json['after'], LockAfter.oneMinute),
      askBeforeRisky: json['ask_before_risky'] != false,
      blockScreenshots: json['block_screenshots'] == true,
      userId: json['user_id'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppLockSettings &&
      other.enabled == enabled &&
      other.method == method &&
      other.after == after &&
      other.askBeforeRisky == askBeforeRisky &&
      other.blockScreenshots == blockScreenshots &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(
    enabled,
    method,
    after,
    askBeforeRisky,
    blockScreenshots,
    userId,
  );
}

/// The settings, saved on this device. Read before the first frame (see [preload]) so a locked
/// app never shows a frame of itself before the lock.
class AppLockSettingsNotifier extends Notifier<AppLockSettings> {
  static const prefKey = 'casama.appLock';
  static AppLockSettings? _preloaded;

  static Future<void> preload() async {
    try {
      _preloaded = _parse(
        (await SharedPreferences.getInstance()).getString(prefKey),
      );
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest() => _preloaded = null;

  static AppLockSettings _parse(String? raw) {
    if (raw == null) return const AppLockSettings();
    try {
      return AppLockSettings.fromJson(jsonDecode(raw));
    } catch (_) {
      return const AppLockSettings();
    }
  }

  /// The state just came from the disk, not from the person turning the lock on: a lock found
  /// this way locks at once.
  bool get loadedFromDisk => _loadedFromDisk;
  var _loadedFromDisk = false;

  @override
  AppLockSettings build() {
    if (_preloaded case final saved?) return saved;
    SharedPreferences.getInstance()
        .then((p) {
          if (!ref.mounted) return;
          final saved = _parse(p.getString(prefKey));
          _preloaded = saved;
          if (state == const AppLockSettings()) {
            _loadedFromDisk = true;
            try {
              state = saved;
            } finally {
              _loadedFromDisk = false;
            }
          }
        })
        .catchError((_) {});
    return const AppLockSettings();
  }

  Future<void> save(AppLockSettings next) async {
    state = next;
    _preloaded = next;
    try {
      await (await SharedPreferences.getInstance()).setString(
        prefKey,
        jsonEncode(next.toJson()),
      );
    } catch (_) {}
    // While the lock is on, the sign-in lives in the keychain rather than in plain preferences.
    unawaited(AuthSessionStore.instance?.useKeychain(next.enabled));
    unawaited(AppLockNative.apply(next));
  }
}

final appLockSettingsProvider =
    NotifierProvider<AppLockSettingsNotifier, AppLockSettings>(
      AppLockSettingsNotifier.new,
    );

/// The first workspace that requires the lock (D-375), or null. The app won't show any workspace
/// until the lock is on: one app shows them all.
final appLockRequiredByProvider = Provider<String?>((ref) {
  if (ref.watch(signedInProvider).value != true) return null;
  final orgs = ref.watch(organizationsProvider).value ?? const [];
  return orgs.where((o) => o.requireAppLock == true).firstOrNull?.name;
});

/// How an unlock went.
enum UnlockResult {
  ok,

  /// The check ran and didn't pass (a wrong PIN, a face or finger not recognised).
  failed,

  /// The person closed the prompt.
  cancelled,

  /// This device can't do it now (the passcode was removed, no passkey, no keychain).
  unavailable,
}

/// The ways to unlock this device offers. Overridden in tests.
class Unlockers {
  Unlockers({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();
  final LocalAuthentication _localAuth;

  /// The system can check the device's owner (Face ID, Touch ID, a fingerprint, the passcode or
  /// Windows Hello). Never on the web or Linux, and not on Android 8, where the system prompt
  /// needs a theme this app doesn't use.
  Future<bool> deviceAvailable() async {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS || TargetPlatform.macOS || TargetPlatform.windows:
        break;
      case TargetPlatform.android:
        if ((await AppLockNative.sdkInt() ?? 0) < 28) return false;
      default:
        return false;
    }
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// The way to unlock this device: the system's own where there is one, a passkey on the web,
  /// otherwise a PIN. Null on the web when this server or browser can't use passkeys.
  Future<LockMethod?> bestMethod({required bool passkeysOn}) async {
    if (kIsWeb) return passkeysOn ? LockMethod.passkey : null;
    return await deviceAvailable() ? LockMethod.device : LockMethod.pin;
  }

  Future<UnlockResult> device(String reason) async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.ok : UnlockResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.uiUnavailable ||
        LocalAuthExceptionCode.userRequestedFallback => UnlockResult.cancelled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled => UnlockResult.unavailable,
        _ => UnlockResult.failed,
      };
    } on PlatformException {
      return UnlockResult.failed;
    }
  }

  /// A PIN was set on this device (it can check before risky actions with the lock off).
  Future<bool> pinSet() => PinStore.exists();

  Future<UnlockResult> pin(String pin) async =>
      switch (await PinStore.verify(pin)) {
        true => UnlockResult.ok,
        false => UnlockResult.failed,
        null => UnlockResult.unavailable,
      };

  Future<UnlockResult> passkey(Future<bool?> Function() confirm) async {
    try {
      return switch (await confirm()) {
        true => UnlockResult.ok,
        false => UnlockResult.failed,
        null => UnlockResult.cancelled,
      };
    } on PasskeyProblem {
      return UnlockResult.unavailable;
    }
  }
}

final unlockersProvider = Provider<Unlockers>((ref) => Unlockers());

/// The lock right now.
@immutable
class LockState {
  const LockState({this.locked = false, this.failures = 0});
  final bool locked;

  /// Unlocks that didn't pass since the last one that did. Five wrong PINs stop the PIN pad: only
  /// signing out is left.
  final int failures;

  LockState copyWith({bool? locked, int? failures}) => LockState(
    locked: locked ?? this.locked,
    failures: failures ?? this.failures,
  );
}

/// Wrong PINs before the PIN pad stops and only signing out is left.
const maxPinFailures = 5;

/// Locks at launch and after the chosen time away; unlocks when the person passes the check.
class AppLockController extends Notifier<LockState> {
  static const _failuresKey = 'casama.appLock.failures';

  /// The clock, replaced in tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  DateTime? _awaySince;
  var _prompting = false;

  /// A system prompt (Face ID, Touch ID, Windows Hello, a passkey sheet) is open. Moving the app
  /// to the background for it isn't time away, and the privacy cover stays off.
  bool get prompting => _prompting;

  @override
  LockState build() {
    final backend = ref.read(backendProvider);
    final settings = ref.read(appLockSettingsProvider);
    ref.listen(appLockSettingsProvider, (prev, next) {
      if (!next.activeFor(ref.read(backendProvider).userId)) {
        _awaySince = null;
        if (state.locked || state.failures > 0) state = const LockState();
      } else if (ref.read(appLockSettingsProvider.notifier).loadedFromDisk) {
        // Read after the first frame (normally it's read before): locked, as at launch.
        if (ref.read(backendProvider).isSignedIn) {
          state = state.copyWith(locked: true);
        }
      } else if (prev?.enabled != true) {
        // Just turned on: this person is here, so it starts unlocked.
        _awaySince = null;
      }
    });
    ref.listen(signedInProvider, (prev, next) {
      final was = prev?.value;
      final now = next.value;
      if (now == false && was == true) {
        // Signed out (or the session ended): nothing to cover. The settings stay for next time.
        _awaySince = null;
        state = const LockState();
      } else if (now == true && was == false) {
        // A fresh sign-in is the check: open. Another account starts with the lock off.
        _awaySince = null;
        state = const LockState();
        final s = ref.read(appLockSettingsProvider);
        if (s.enabled && s.userId != ref.read(backendProvider).userId) {
          unawaited(_reset());
        }
      }
    });
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getInt(_failuresKey) ?? 0;
          if (ref.mounted && saved != state.failures) {
            state = state.copyWith(failures: saved);
          }
        })
        .catchError((_) {});
    return LockState(
      locked: backend.isSignedIn && settings.activeFor(backend.userId),
    );
  }

  bool get _active =>
      ref.read(signedInProvider).value != false &&
      ref
          .read(appLockSettingsProvider)
          .activeFor(ref.read(backendProvider).userId);

  /// Time away is the app in the background or minimised; on a computer, also behind another app
  /// (where the window stays visible to anyone passing by).
  static bool isAway(AppLifecycleState s, {required bool computer}) =>
      s == AppLifecycleState.hidden ||
      s == AppLifecycleState.paused ||
      (computer && s == AppLifecycleState.inactive);

  /// The app's lifecycle moved to [s].
  void lifecycle(AppLifecycleState s, {required bool computer}) {
    if (_prompting) return;
    if (isAway(s, computer: computer)) {
      _awaySince ??= now();
      return;
    }
    if (s != AppLifecycleState.resumed) return;
    final since = _awaySince;
    _awaySince = null;
    if (since == null || state.locked || !_active) return;
    if (now().difference(since) >=
        ref.read(appLockSettingsProvider).after.duration) {
      state = state.copyWith(locked: true);
    }
  }

  /// Locks now (Lock now in the menu, or a test).
  void lock() {
    if (_active) state = state.copyWith(locked: true);
  }

  /// Runs [check] with the lifecycle ignored, and unlocks when it passes.
  Future<UnlockResult> unlock(Future<UnlockResult> Function() check) async {
    final result = await prompt(check);
    if (!ref.mounted) return result;
    if (result == UnlockResult.ok) {
      _awaySince = null;
      state = const LockState();
      unawaited(_saveFailures(0));
    } else if (result == UnlockResult.failed) {
      final failures = state.failures + 1;
      state = state.copyWith(failures: failures);
      unawaited(_saveFailures(failures));
    }
    return result;
  }

  /// Runs a system prompt (also for a check before a risky action) without it counting as time
  /// away.
  Future<UnlockResult> prompt(Future<UnlockResult> Function() check) async {
    _prompting = true;
    try {
      return await check();
    } finally {
      _prompting = false;
      _awaySince = null;
    }
  }

  /// Signs out from the lock screen: the way back in when the check can't pass. The lock goes
  /// off with the PIN, so signing in again opens the app.
  Future<void> signOut() async {
    await _reset();
    await ref.read(backendProvider).signOut();
  }

  Future<void> _reset() async {
    final settings = ref.read(appLockSettingsProvider);
    await ref.read(appLockSettingsProvider.notifier).save(settings.off);
    await PinStore.clear();
    await _saveFailures(0);
    if (ref.mounted) state = const LockState();
  }

  Future<void> _saveFailures(int n) async {
    try {
      final p = await SharedPreferences.getInstance();
      n == 0 ? await p.remove(_failuresKey) : await p.setInt(_failuresKey, n);
    } catch (_) {}
  }
}

final appLockProvider = NotifierProvider<AppLockController, LockState>(
  AppLockController.new,
);

/// Android's window flags for the lock (MainActivity's `casama/app_lock` channel): the app's
/// picture in Recents is blank while the lock is on (Android 13+), and screenshots and screen
/// recordings show nothing when the person asks for that.
abstract final class AppLockNative {
  static const _channel = MethodChannel('casama/app_lock');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<int?> sdkInt() async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<int>('sdkInt');
    } catch (_) {
      return null;
    }
  }

  static Future<void> apply(AppLockSettings s) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('set', {
        'hideInRecents': s.enabled,
        'secure': s.enabled && s.blockScreenshots,
      });
    } catch (_) {}
  }
}

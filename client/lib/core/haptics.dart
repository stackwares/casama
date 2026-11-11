import 'package:flutter/foundation.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Haptics for key moments, in one place so the "can this device vibrate" check isn't repeated.
/// iOS plays the system patterns and follows the System Haptics switch. Android plays matching
/// patterns as touch feedback, which Android 13+ ties to the Touch feedback setting. Desktop and
/// web have no haptics: every call does nothing there.
class HapticsHelper {
  HapticsHelper._();

  static bool? _canVibrate;

  static Future<void> _vibrate(HapticsType type) async {
    try {
      _canVibrate ??= await Haptics.canVibrate();
    } catch (_) {
      // No haptics plugin here (a platform without one, or a widget test): stay silent.
      _canVibrate = false;
    }

    if (_canVibrate ?? false) {
      try {
        await Haptics.vibrate(type, usage: HapticsUsage.touch);
      } catch (_) {
        // A haptic that didn't play is not worth an error.
      }
    }
  }

  /// Forgets whether the device can vibrate, so a test can mock the plugin.
  @visibleForTesting
  static void debugReset() => _canVibrate = null;

  // Declarative shorthand for each type
  static Future<void> success() => _vibrate(HapticsType.success);
  static Future<void> warning() => _vibrate(HapticsType.warning);
  static Future<void> error() => _vibrate(HapticsType.error);
  static Future<void> light() => _vibrate(HapticsType.light);
  static Future<void> medium() => _vibrate(HapticsType.medium);
  static Future<void> heavy() => _vibrate(HapticsType.heavy);
  static Future<void> soft() => _vibrate(HapticsType.soft);
  static Future<void> selection() => _vibrate(HapticsType.selection);
}

/// [onChanged] for a switch, checkbox or dropdown that first plays [haptic] (a light tap unless
/// told otherwise). A null [onChanged] stays null, so a disabled control stays disabled.
ValueChanged<T>? hapticOnChanged<T>(ValueChanged<T>? onChanged, {Future<void> Function() haptic = HapticsHelper.light}) {
  if (onChanged == null) return null;
  return (T value) {
    haptic();
    onChanged(value);
  };
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../app_lock/app_lock.dart';

/// **Show details in widgets** (D-405 §10): with the app lock on, widgets show counts and general
/// words only, and their buttons open the app, until the person turns this on. Kept on this
/// device; off by default.
class WidgetDetails extends Notifier<bool> {
  static const prefKey = 'casama.widgets.details';

  @override
  bool build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getBool(prefKey) ?? false;
          if (ref.mounted && saved != state) state = saved;
        })
        .catchError((_) {});
    return false;
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(prefKey, on);
    } catch (_) {}
  }
}

final widgetDetailsProvider = NotifierProvider<WidgetDetails, bool>(WidgetDetails.new);

/// Widgets are private now: a workspace requires the app lock, or the lock is on and Show details
/// is off. Private widgets get a glance with the person's words taken out, and their acting
/// buttons (Run now, Do it, Allow, Deny) open the app instead.
final widgetsPrivateProvider = Provider<bool>((ref) {
  if (ref.watch(appLockRequiredByProvider) != null) return true;
  ref.watch(signedInProvider);
  final lockOn = ref.watch(appLockSettingsProvider).activeFor(ref.watch(backendProvider).userId);
  return lockOn && !ref.watch(widgetDetailsProvider);
});

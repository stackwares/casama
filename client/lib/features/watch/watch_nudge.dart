import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets.dart';
import '../../ui/toast.dart';
import '../widgets/widget_nudge.dart';
import 'watch_bridge.dart';
import 'watch_key_store.dart';

/// Whether the watch nudge may show here: on phones, and not under `flutter test` (other tests'
/// snackbars would gain one). Overridden in tests that check it.
final watchNudgeEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(watchBridgeSupportedProvider)) return false;
  try {
    return !Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return true;
  }
});

const watchNudgeShownKey = 'casama.watch.nudged';

/// One quiet nudge (D-410 §6.10): after the person answers a request on the phone, if a watch is
/// paired and Casama isn't signed in on it, a line that Casama is on the watch too, with a way to
/// Settings → Watch. Shown once on this device. True when it showed.
Future<bool> nudgeWatch(BuildContext context, WidgetRef ref) async {
  if (!ref.read(watchNudgeEnabledProvider)) return false;
  final bridge = ref.read(watchBridgeProvider);
  if (bridge == null) return false;
  // Everything that needs the context is taken now: a sheet may close while native code answers.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.maybeOf(context);
  if (messenger == null) return false;
  final snack = toastSnackBar(
    context,
    l10n.watchPhoneNudge,
    action: router == null
        ? null
        : SnackBarAction(
            label: l10n.widgetNudgeAction,
            onPressed: () => router.go('/settings/watch'),
          ),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(watchNudgeShownKey) == true) return false;
    final status = await bridge.status();
    if (status == null || !status.paired) return false;
    // Signed in from this phone already: nothing to say.
    if (status.installed && (await WatchKeyStore.load()).isNotEmpty) {
      return false;
    }
    await prefs.setBool(watchNudgeShownKey, true);
  } catch (_) {
    return false;
  }
  messenger.showSnackBar(snack);
  return true;
}

/// After a request is answered in the app: the watch's line if it applies, else the widgets'
/// (D-405), so two nudges never stack.
Future<void> nudgeAfterAnswer(BuildContext context, WidgetRef ref) async {
  if (await nudgeWatch(context, ref)) return;
  if (context.mounted) await nudgeWidget(context, ref, WidgetNudge.needsYou);
}

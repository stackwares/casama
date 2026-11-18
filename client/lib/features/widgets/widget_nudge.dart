import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets.dart';
import '../../ui/toast.dart';

/// Which widget the one nudge points to (D-405 §6.8).
enum WidgetNudge { needsYou, routines }

/// Whether the nudge may show here: on the platforms with widgets, and not under `flutter test`
/// (other tests' snackbars would gain one). Overridden in tests that check it.
final widgetNudgeEnabledProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  if (!const {TargetPlatform.iOS, TargetPlatform.android, TargetPlatform.macOS}.contains(defaultTargetPlatform)) return false;
  try {
    return !Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return true;
  }
});

/// One quiet nudge (§6.8): after the person's first answered request or first routine, a line
/// that the matching widget exists, with a way to Settings → Widgets. Shown once on this device,
/// whichever comes first.
Future<void> nudgeWidget(BuildContext context, WidgetRef ref, WidgetNudge which) async {
  if (!ref.read(widgetNudgeEnabledProvider)) return;
  // Everything that needs the context is taken now: a sheet may close while the flag is read.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.maybeOf(context);
  if (messenger == null) return;
  final snack = toastSnackBar(
    context,
    which == WidgetNudge.needsYou ? l10n.widgetNudgeNeedsYou : l10n.widgetNudgeRoutines,
    action: router == null ? null : SnackBarAction(label: l10n.widgetNudgeAction, onPressed: () => router.go('/settings/widgets')),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(nudgeShownKey) == true) return;
    await prefs.setBool(nudgeShownKey, true);
  } catch (_) {
    return;
  }
  messenger.showSnackBar(snack);
}

const nudgeShownKey = 'casama.widgets.nudged';

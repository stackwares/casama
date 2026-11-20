import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';

/// Switches a computer between the desktop and browser-only (headless), from wherever the person
/// is looking at it: its Screen tab or the live view's menu. A running computer restarts to
/// switch (files kept), so that asks first. [run] wraps the request (a screen's busy state);
/// without it the request runs guarded on its own. Returns whether it switched.
Future<bool> switchComputerProfile(
  BuildContext context,
  WidgetRef ref,
  Computer computer, {
  required bool toDesktop,
  Future<Computer?> Function(Future<Computer> Function() call)? run,
}) async {
  final l10n = context.l10n;
  final running =
      computer.state == ComputerState.running ||
      computer.state == ComputerState.idle;
  if (running) {
    final ok = await showConfirm(
      context: context,
      title: toDesktop ? l10n.switchToDesktop : l10n.switchToBrowserOnly,
      message: l10n.switchProfileConfirm,
      confirmLabel: l10n.switchProfileButton,
    );
    if (!ok || !context.mounted) return false;
  }
  Future<Computer> call() => ref
      .read(backendProvider)
      .updateComputer(computer.id, profile: toDesktop ? 'desktop' : 'headless');
  final done = run != null ? await run(call) : await runGuarded(context, call);
  ref.invalidate(computersProvider);
  if (done == null || !context.mounted) return false;
  HapticsHelper.success();
  showToast(
    context,
    toDesktop ? l10n.switchedToDesktopHere : l10n.switchedToBrowserOnly,
    kind: ToastKind.success,
  );
  return true;
}

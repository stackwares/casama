import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';

// Computer updates on the person's terms (D-360): a running computer on an older system says so,
// and the person picks the moment. It also updates by itself the next time it sleeps.

/// Whether [c] has a newer system waiting that the person can apply now.
bool computerUpdateWaiting(Computer c) =>
    c.updateAvailableSince != null &&
    c.kind != ComputerKindEnum.local &&
    (c.state == ComputerState.running || c.state == ComputerState.idle);

/// Whether a bot is working on [computerId] now (fresh bot statuses; false when unknown).
Future<bool> botWorkingOn(WidgetRef ref, String computerId) async {
  try {
    final org = ref.read(currentOrgProvider);
    if (org == null) return false;
    final computer = (ref.read(computersProvider).value ?? const <Computer>[])
        .where((c) => c.id == computerId)
        .firstOrNull;
    final bots = await ref.read(backendProvider).bots(org.id);
    return bots.any(
      (b) =>
          b.status == BotStatusEnum.working &&
          (b.defaultComputerId == computerId ||
              computer?.ownerBotId == b.id ||
              (b.defaultComputerId == null &&
                  computer?.kind != ComputerKindEnum.private)),
    );
  } catch (_) {
    return false;
  }
}

/// Asks, then restarts [c] on the newer system. A running command asks once more before it is
/// stopped. True when the computer was updated.
Future<bool> confirmComputerUpdate(
  BuildContext context,
  WidgetRef ref,
  Computer c,
) async {
  final l10n = context.l10n;
  final botWorking = await botWorkingOn(ref, c.id);
  if (!context.mounted) return false;
  final ok = await showConfirm(
    context: context,
    title: l10n.computerUpdateConfirmTitle,
    message: botWorking
        ? '${l10n.computerUpdateBody}\n\n${l10n.computerUpdateBotWorking}'
        : l10n.computerUpdateBody,
    confirmLabel: l10n.computerUpdateNow,
    icon: LucideIcons.download,
    confirmKey: const Key('confirmComputerUpdate'),
  );
  if (!ok || !context.mounted) return false;
  final backend = ref.read(backendProvider);
  Computer? done;
  try {
    done = await backend.applyComputerUpdate(c.id);
  } catch (e) {
    if (!context.mounted) return false;
    if (e is DioException && problemOf(e)?.code == 'computer_busy') {
      final anyway = await showConfirm(
        context: context,
        title: l10n.computerUpdateBusyTitle,
        message: l10n.computerUpdateBusyBody,
        confirmLabel: l10n.computerUpdateAnyway,
        destructive: true,
        confirmKey: const Key('confirmComputerUpdateAnyway'),
      );
      if (!anyway || !context.mounted) return false;
      done = await runGuarded(
        context,
        () => backend.applyComputerUpdate(c.id, force: true),
      );
    } else if (e is DioException && problemOf(e)?.code == 'no_update') {
      // Already up to date (it slept and woke meanwhile): nothing to say but the new state.
      ref.invalidate(computersProvider);
      return false;
    } else {
      showError(context, e);
      return false;
    }
  }
  ref.invalidate(computersProvider);
  if (done == null || !context.mounted) return false;
  showSuccess(context, l10n.computerUpdated);
  return true;
}

/// "Later" on the card hides it for a day on this device.
class _Later {
  static const _key = 'computer_update_later';
  static final _until = <String, DateTime>{};
  static var _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      for (final e in p.getStringList(_key) ?? const <String>[]) {
        final i = e.indexOf('@');
        final t = i > 0 ? int.tryParse(e.substring(i + 1)) : null;
        if (t != null) {
          _until[e.substring(0, i)] = DateTime.fromMillisecondsSinceEpoch(t);
        }
      }
    } catch (_) {}
  }

  static bool hidden(String id) => _until[id]?.isAfter(DateTime.now()) ?? false;

  static Future<void> hide(String id) async {
    final now = DateTime.now();
    _until[id] = now.add(const Duration(days: 1));
    _until.removeWhere((_, t) => t.isBefore(now));
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_key, [
        for (final e in _until.entries)
          '${e.key}@${e.value.millisecondsSinceEpoch}',
      ]);
    } catch (_) {}
  }
}

/// The card under a computer's header while a newer system waits: what updating does, with
/// Update now and Later. Never covers anything and never interrupts.
class ComputerUpdateCard extends ConsumerStatefulWidget {
  const ComputerUpdateCard({super.key, required this.computer});
  final Computer computer;

  @override
  ConsumerState<ComputerUpdateCard> createState() => _ComputerUpdateCardState();
}

class _ComputerUpdateCardState extends ConsumerState<ComputerUpdateCard> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (!_Later._loaded) {
      unawaited(
        _Later.load().then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  Future<void> _update() async {
    HapticsHelper.medium();
    setState(() => _busy = true);
    await confirmComputerUpdate(context, ref, widget.computer);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.computer;
    if (!computerUpdateWaiting(c) || _Later.hidden(c.id)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        AppSpace.xxs,
      ),
      child: AppCard(
        key: const Key('computerUpdateCard'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.download, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.computerUpdateTitle,
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.computerUpdateBody,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('computerUpdateLater'),
                  onPressed: _busy
                      ? null
                      : () async {
                          await _Later.hide(c.id);
                          if (mounted) setState(() {});
                        },
                  child: Text(l10n.computerUpdateLater),
                ),
                TextButton(
                  key: const Key('computerUpdateNow'),
                  onPressed: _busy ? null : _update,
                  child: Text(
                    _busy ? l10n.computerUpdating : l10n.computerUpdateNow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

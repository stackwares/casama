// While a person has a bot's screen and the bot waits for it, the chat offers what to do next:
// hand the screen back, or let the bot keep using its terminal and files meanwhile.
import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/haptics.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

/// Hands the screen back when this person holds it; otherwise opens Live View, where they can see
/// who has it. Returns the lease after the call, or null when nothing was done.
Future<Lease?> handBackScreen(
  BuildContext context,
  WidgetRef ref,
  String computerId, {
  required VoidCallback onOpenLive,
}) async {
  final backend = ref.read(backendProvider);
  final l10n = context.l10n;
  final lease = await runGuarded(context, () => backend.lease(computerId));
  if (lease == null || !context.mounted) return null;
  if (!_mine(lease)) {
    onOpenLive();
    return lease;
  }
  HapticsHelper.medium();
  final after = await runGuarded(
    context,
    () => backend.releaseLease(computerId),
  );
  if (after != null && context.mounted) {
    showSuccess(context, l10n.screenHandedBack);
  }
  return after;
}

bool _mine(Lease l) => l.you && l.holderType == LeaseHolderTypeEnum.user;
bool _someoneElse(Lease l) =>
    !l.you && l.holderType == LeaseHolderTypeEnum.user;

/// The buttons under "Paused: a person is in control of the screen". They follow the computer's
/// lease, not the bot's words: Hand Back (and the terminal switch) only when the screen is yours,
/// Open Live View when someone else has it, nothing once it's back with the bot.
class ScreenHeldActions extends ConsumerStatefulWidget {
  const ScreenHeldActions({
    super.key,
    required this.computerId,
    required this.onOpenLive,
  });
  final String computerId;
  final VoidCallback onOpenLive;

  @override
  ConsumerState<ScreenHeldActions> createState() => _ScreenHeldActionsState();
}

class _ScreenHeldActionsState extends ConsumerState<ScreenHeldActions> {
  Lease? _lease;
  var _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // The screen can come back from somewhere else (Live View, another device, the lease lapsing).
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final l = await ref.read(backendProvider).lease(widget.computerId);
      if (mounted) setState(() => _lease = l);
    } catch (_) {}
  }

  Future<void> _handBack() async {
    setState(() => _busy = true);
    final l = await handBackScreen(
      context,
      ref,
      widget.computerId,
      onOpenLive: widget.onOpenLive,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (l != null) _lease = l;
    });
  }

  Future<void> _allowShell() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final l = await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .takeLease(widget.computerId, allowShell: true),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (l != null) _lease = l;
    });
    if (l != null) showSuccess(context, l10n.liveShellOnNote);
  }

  @override
  Widget build(BuildContext context) {
    final lease = _lease;
    if (lease == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final List<Widget> actions;
    if (_mine(lease)) {
      actions = [
        FilledButton.tonalIcon(
          key: const Key('chatHandBack'),
          onPressed: _busy ? null : _handBack,
          icon: const Icon(LucideIcons.undo2, size: 16),
          label: Text(l10n.handBack),
        ),
        if (lease.allowShell != true)
          TextButton(
            key: const Key('chatAllowShell'),
            onPressed: _busy ? null : _allowShell,
            child: Text(l10n.letBotUseTerminal),
          ),
      ];
    } else if (_someoneElse(lease)) {
      actions = [
        Text(
          l10n.someoneElseInControl,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          key: const Key('chatOpenLive'),
          onPressed: widget.onOpenLive,
          child: Text(l10n.openLiveView),
        ),
      ];
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xxs,
        children: actions,
      ),
    );
  }
}

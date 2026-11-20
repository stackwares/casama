import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/billing.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/adaptive_modal.dart';

/// Saved resets (D-443): the first one the workspace holds, with its expiry, and Use Reset for
/// owners. When it can't be used, a line says why instead of the button.
class SavedResets extends ConsumerStatefulWidget {
  const SavedResets({super.key});
  @override
  ConsumerState<SavedResets> createState() => _SavedResetsState();
}

/// Why a saved reset can't be used now, in words. Unknown reasons (a newer server) read as
/// "not available" rather than breaking.
String savedResetReason(AppLocalizations words, String? reason) =>
    switch (reason) {
      'owner_required' => words.savedResetOwnerRequired,
      'paused' => words.savedResetPaused,
      'period_limit' => words.savedResetPeriodLimit,
      'nothing_to_refill' => words.savedResetNothingToRefill,
      'no_billing_period' => words.savedResetNoBillingPeriod,
      _ => words.savedResetUnavailable,
    };

/// What using [reset] will do, for the confirmation: the credits it refills, or, when there are
/// none to refill, the daily limit or computer hours it clears.
String savedResetEffect(AppLocalizations words, SavedLimitReset reset) {
  if (reset.refillUsd > 0) {
    return words.savedResetConfirm(reset.refillUsd.toStringAsFixed(2));
  }
  if (reset.resetDaily) return words.savedResetConfirmDaily;
  return words.savedResetConfirmComputer;
}

class _SavedResetsState extends ConsumerState<SavedResets> {
  bool busy = false;

  Future<void> _use(SavedLimitReset reset) async {
    final words = context.l10n;
    final confirmed = await showConfirm(
      context: context,
      title: words.savedResetConfirmTitle,
      message: savedResetEffect(words, reset),
      confirmLabel: words.savedResetUse,
      icon: LucideIcons.rotateCcw,
    );
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    await runGuarded(context, () async {
      final org = ref.read(currentOrgProvider);
      if (org == null) return;
      final res = await ref
          .read(backendProvider)
          .limitResets
          .redeemSavedLimitReset(id: org.id);
      final refilled = res.data?.refilledUsd ?? 0;
      ref.invalidate(billingProvider);
      ref.invalidate(billingUsageProvider);
      if (!mounted) return;
      showToast(
        context,
        refilled > 0
            ? words.savedResetDone('\$${refilled.toStringAsFixed(2)}')
            : words.savedResetDoneNoCredits,
        kind: ToastKind.success,
      );
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final resets = ref.watch(billingProvider).value?.resets ?? [];
    if (resets.isEmpty) return const SizedBox.shrink();
    final reset = resets.first;
    final words = context.l10n;
    final lines = [
      reset.message,
      words.savedResetExpiry(reset.expiresAt.toLocal().formattedExact(context)),
      if (!reset.canUse) savedResetReason(words, reset.unavailableReason),
    ];
    return ListTile(
      title: Text(words.savedResetAvailable(resets.length)),
      subtitle: Text(lines.join('\n')),
      trailing: reset.canUse
          ? FilledButton(
              onPressed: busy ? null : () => _use(reset),
              child: Text(words.savedResetUse),
            )
          : null,
    );
  }
}

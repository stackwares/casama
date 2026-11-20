import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/billing.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: _ResetCard(
        reset: resets.first,
        count: resets.length,
        busy: busy,
        onUse: () => _use(resets.first),
      ),
    );
  }
}

/// One saved reset as a card: what it is, what using it does, how long it keeps, and Use Reset.
/// The button sits beside the title on wide cards and spans the card on narrow ones, so the
/// message never gets squeezed into a thin column.
class _ResetCard extends StatelessWidget {
  const _ResetCard({required this.reset, required this.count, required this.busy, required this.onUse});
  final SavedLimitReset reset;
  final int count;
  final bool busy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final words = context.l10n;
    final scheme = context.colorScheme;
    final expires = reset.expiresAt.toLocal();
    final daysLeft = expires.difference(DateTime.now()).inHours ~/ 24;
    final soon = daysLeft <= 3;
    final accent = soon ? context.appColors.warning : scheme.primary;
    // The exact time only matters when it's close.
    final when = soon ? expires.formattedExact(context) : expires.formattedWeekdayDate(context);
    final effects = <(IconData, String)>[
      if (reset.refillUsd > 0) (LucideIcons.wallet, words.savedResetRefills('\$${reset.refillUsd.toStringAsFixed(2)}')),
      if (reset.resetDaily) (LucideIcons.sunrise, words.savedResetClearsDaily),
      if (reset.resetComputer) (LucideIcons.monitor, words.savedResetGivesHours),
    ];
    final muted = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.35);

    Widget button({bool wide = false}) => FilledButton.icon(
      key: const Key('useSavedReset'),
      style: FilledButton.styleFrom(
        minimumSize: Size(wide ? double.infinity : 0, 44),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
      onPressed: busy ? null : onUse,
      icon: busy
          ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
          : const Icon(LucideIcons.rotateCcw, size: 18),
      label: Text(words.savedResetUse),
    );

    final chip = daysLeft > 30
        ? null
        : Container(
            key: const Key('savedResetDaysLeft'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: context.isDark ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              words.savedResetDaysLeft(daysLeft < 0 ? 0 : daysLeft),
              style: context.textTheme.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w700),
            ),
          );

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 520;
        final header = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: context.isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: Icon(LucideIcons.rotateCcw, size: 22, color: scheme.primary),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Wrap(
                spacing: AppSpace.xs,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    words.savedResetAvailable(count),
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                  ?chip,
                ],
              ),
            ),
            if (wide && reset.canUse) ...[const SizedBox(width: AppSpace.md), button()],
          ],
        );
        return Container(
          key: const Key('savedResetCard'),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: scheme.primary.withValues(alpha: context.isDark ? 0.35 : 0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: context.isDark ? 0.16 : 0.08),
                scheme.primary.withValues(alpha: context.isDark ? 0.06 : 0.03),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (reset.message.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Text(reset.message.trim(), style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
              ],
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: 6,
                children: [
                  for (final (icon, text) in effects) _Fact(icon: icon, text: text),
                  _Fact(icon: LucideIcons.calendarClock, text: words.savedResetExpiry(when), color: soon ? accent : null),
                ],
              ),
              if (!reset.canUse) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(LucideIcons.info, size: 16, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(child: Text(savedResetReason(words, reset.unavailableReason), style: muted)),
                  ],
                ),
              ] else if (!wide) ...[
                const SizedBox(height: AppSpace.md),
                button(wide: true),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A small icon and a few words: what the reset does, or when it expires.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: context.textTheme.bodySmall?.copyWith(color: c, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

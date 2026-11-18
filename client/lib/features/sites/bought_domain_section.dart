import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../billing/billing_screen.dart' show openUrlProvider;
import 'domain_buying.dart';
import 'domains_providers.dart';

/// A bought domain's part of its screen (SITES-AND-DOMAINS-PLAN §7.8–§7.10): the registrant-email
/// step, an expired or lapsed line, **Renews on** with the price and **Renew Automatically**,
/// **Renew Now**, **DNS Records**, **Contact Details**, and for the owner **Move to Another
/// Registrar** and **Lock Again**.
class BoughtDomainSection extends ConsumerStatefulWidget {
  const BoughtDomainSection({
    super.key,
    required this.domain,
    required this.onChanged,
    required this.onReload,
  });
  final Domain domain;
  final void Function(Domain) onChanged;
  final Future<void> Function() onReload;

  @override
  ConsumerState<BoughtDomainSection> createState() =>
      _BoughtDomainSectionState();
}

class _BoughtDomainSectionState extends ConsumerState<BoughtDomainSection> {
  bool _renewing = false;
  bool _toggling = false;
  bool _sending = false;

  Domain get _d => widget.domain;

  Future<void> _setAutoRenew(bool on) async {
    setState(() => _toggling = true);
    final next = await runGuarded(
      context,
      () => ref.read(backendProvider).setDomainAutoRenew(_d.id, on),
    );
    if (!mounted) return;
    setState(() => _toggling = false);
    if (next != null) widget.onChanged(next);
  }

  Future<void> _renew() async {
    if (_renewing) return;
    setState(() => _renewing = true);
    try {
      final r = await ref.read(backendProvider).renewDomain(_d.id);
      if (!mounted) return;
      final url = r.checkoutUrl;
      if (url != null) {
        await ref.read(openUrlProvider)(url);
        if (mounted) {
          showToast(context, context.l10n.domainRenewPayInBrowser);
        }
      } else {
        showSuccess(context, context.l10n.domainRenewCharged);
        unawaited(widget.onReload());
      }
    } catch (e, st) {
      if (!mounted) return;
      // Past the late-renewal window: the server says how to reach support.
      if (problemCode(e) == 'restore_by_support') {
        showToast(context, errorText(context, e), kind: ToastKind.warning);
      } else {
        await runGuarded<void>(context, () => Future.error(e, st));
      }
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  Future<void> _sendAgain() async {
    setState(() => _sending = true);
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).resendDomainVerification(_d.id);
      return true;
    });
    if (!mounted) return;
    setState(() => _sending = false);
    if (done == true) showSuccess(context, context.l10n.domainVerifySent);
  }

  Future<void> _lockAgain() async {
    final next = await runGuarded(
      context,
      () => ref.read(backendProvider).lockDomain(_d.id),
    );
    if (next != null && mounted) {
      widget.onChanged(next);
      showSuccess(context, context.l10n.domainLocked);
    }
  }

  Future<void> _moveOut() async {
    final l10n = context.l10n;
    final typed = await showAdaptiveSheet<String>(
      context: context,
      builder: (_) => _ConfirmMoveSheet(name: _d.name),
    );
    if (typed == null || !mounted) return;
    final code = await _transferCode(typed);
    if (code == null || !mounted) return;
    // Shown once, then forgotten: the code lives only in this sheet.
    await showAdaptiveSheet<void>(
      context: context,
      builder: (c) => FormSheet(
        icon: LucideIcons.keyRound,
        title: l10n.domainTransferCodeTitle,
        subtitle: l10n.domainTransferCodeBody,
        submitLabel: l10n.doneLabel,
        submitKey: const Key('domainTransferCodeDone'),
        showCancel: false,
        onSubmit: () => Navigator.of(c).pop(),
        children: [
          CopyableValue(
            key: const Key('domainTransferCode'),
            label: l10n.domainTransferCode,
            value: code,
            copyKey: const Key('domainTransferCodeCopy'),
          ),
        ],
      ),
    );
    if (mounted) unawaited(widget.onReload());
  }

  /// Asks for the transfer code, signing in again once when the server wants a fresh sign-in.
  Future<String?> _transferCode(String typed, {bool retried = false}) async {
    try {
      return await ref.read(backendProvider).transferOutDomain(_d.id, typed);
    } catch (e, st) {
      if (!mounted) return null;
      final code = problemCode(e);
      if (code == 'reauthentication_needed' || problemStatus(e) == 401) {
        if (retried) {
          showError(context, e, st);
          return null;
        }
        final again = await showFreshSignIn(context, errorText(context, e));
        if (!again || !mounted) return null;
        return _transferCode(typed, retried: true);
      }
      if (code == 'transfer_locked' && _d.transferAfter != null) {
        showToast(
          context,
          context.l10n.domainMoveOutLocked(
            _d.transferAfter!.toLocal().formattedDate(context),
          ),
          kind: ToastKind.warning,
        );
        return null;
      }
      await runGuarded<void>(context, () => Future.error(e, st));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final d = _d;
    final org = ref.watch(currentOrgProvider);
    final owner = org?.role == OrgRole.owner;
    // Where this app can't take the payment (Android, App Store outside the US), nothing here may
    // buy or point to buying: no price, no Renew Now, and the switch only to turn renewals off.
    final canPay = ref.watch(canBuyDomainsProvider);
    final expires = d.expiresAt?.toLocal();
    final date = expires?.formattedDate(context);
    final status = d.registrarStatus;
    final price = d.renewPriceUsd;
    final transferAfter = d.transferAfter?.toLocal();
    final canMove =
        transferAfter == null || !DateTime.now().isBefore(transferAfter);
    final stateLine = switch (status) {
      'expired' when date != null => l10n.domainExpired(date),
      'lapsed' || 'gone' => l10n.domainLapsed,
      'suspended' => l10n.domainSuspendedLine,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.registrantVerified == false) ...[
          const SizedBox(height: AppSpace.md),
          AppCard(
            key: const Key('domainVerifyBanner'),
            borderColor: colors.warning.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.domainVerifyTitle,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(l10n.domainVerifyBody),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton(
                  key: const Key('domainVerifySendAgain'),
                  onPressed: _sending ? null : _sendAgain,
                  child: Text(l10n.domainVerifySendAgain),
                ),
              ],
            ),
          ),
        ],
        SectionHeader(title: l10n.domainRegistration),
        if (stateLine != null) ...[
          Text(
            stateLine,
            key: const Key('domainStateLine'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.negative,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        GroupedCard(
          children: [
            if (date != null)
              GroupedTile(
                key: const Key('domainRenewsOn'),
                icon: LucideIcons.calendarClock,
                title: d.autoRenew && status != 'expired'
                    ? l10n.domainRenewsOn(date)
                    : l10n.domainExpiresOn(date),
                subtitle: price == null || !canPay
                    ? null
                    : l10n.domainRenewPrice(domainUsd(context, price)),
                showChevron: false,
              ),
            if (canPay || d.autoRenew)
              GroupedTile(
                key: const Key('domainAutoRenewRow'),
                icon: LucideIcons.repeat,
                title: l10n.domainRenewAuto,
                subtitle: l10n.domainRenewAutoHelp,
                showChevron: false,
                trailing: Switch(
                  key: const Key('domainAutoRenew'),
                  value: d.autoRenew,
                  onChanged: _toggling || (!canPay && !d.autoRenew)
                      ? null
                      : _setAutoRenew,
                ),
              ),
            if (canPay)
              GroupedTile(
                key: const Key('domainRenewNow'),
                icon: LucideIcons.refreshCcw,
                title: l10n.domainRenewNow,
                trailing: _renewing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _renewing ? null : _renew,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('domainDnsRecords'),
              icon: LucideIcons.server,
              title: l10n.domainDnsRecords,
              subtitle: l10n.domainDnsRecordsHelp,
              onTap: () => unawaited(
                context.pushOnce(
                  '/settings/domains/${d.id}/records'
                  '?name=${Uri.encodeQueryComponent(d.name)}',
                ),
              ),
            ),
            GroupedTile(
              key: const Key('domainContactDetails'),
              icon: LucideIcons.idCard,
              title: l10n.domainContactTitle,
              onTap: () =>
                  unawaited(context.pushOnce('/settings/domains/contact')),
            ),
            if (owner) ...[
              if (!d.locked)
                GroupedTile(
                  key: const Key('domainLockAgain'),
                  icon: LucideIcons.lock,
                  title: l10n.domainLockAgain,
                  subtitle: l10n.domainUnlocked,
                  onTap: _lockAgain,
                ),
              GroupedTile(
                key: const Key('domainMoveOut'),
                icon: LucideIcons.arrowRightLeft,
                title: l10n.domainMoveOut,
                subtitle: canMove
                    ? l10n.domainMoveOutHelp
                    : l10n.domainMoveOutAfter(
                        transferAfter.formattedDate(context),
                      ),
                showChevron: canMove,
                onTap: canMove ? _moveOut : null,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Type the domain's name to get its transfer code; answers what was typed.
class _ConfirmMoveSheet extends StatefulWidget {
  const _ConfirmMoveSheet({required this.name});
  final String name;

  @override
  State<_ConfirmMoveSheet> createState() => _ConfirmMoveSheetState();
}

class _ConfirmMoveSheetState extends State<_ConfirmMoveSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typed = _c.text.trim().toLowerCase();
    final matches = typed == widget.name.toLowerCase();
    return FormSheet(
      icon: LucideIcons.arrowRightLeft,
      destructive: true,
      title: l10n.domainMoveOutTitle(widget.name),
      subtitle: l10n.domainMoveOutBody(widget.name),
      submitLabel: l10n.domainMoveOutConfirm,
      submitKey: const Key('domainMoveOutConfirm'),
      onSubmit: matches ? () => Navigator.of(context).pop(typed) : null,
      children: [
        TextField(
          key: const Key('domainMoveOutName'),
          controller: _c,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(hintText: widget.name),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

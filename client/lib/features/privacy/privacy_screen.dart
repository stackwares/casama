import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/number_format.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../core/analytics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

final _retentionProvider = FutureProvider<int?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  return org == null ? null : ref.watch(backendProvider).retentionDays(org.id);
});

/// Overridable in tests: hands the export to the platform (share sheet, save dialog, download).
final saveExportProvider = Provider<Future<void> Function(Uint8List bytes, String name, {Rect? origin})>(
  (ref) =>
      (bytes, name, {origin}) => shareFiles(
        [XFile.fromData(bytes, name: name, mimeType: 'application/zip')],
        names: [name],
        origin: origin,
      ),
);

/// Privacy (Phase 8, D-072): export your data, delete your account, and workspace retention.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});
  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  var _busy = false;

  final _exportKey = GlobalKey();

  Future<void> _export() async {
    // The share sheet points at the Export row on iPad and macOS.
    final anchor = _exportKey.currentContext;
    final origin = anchor == null ? null : shareOrigin(anchor);
    setState(() => _busy = true);
    final l10n = context.l10n;
    await runGuarded(context, () async {
      final bytes = await ref.read(backendProvider).exportMyData();
      final name = 'casama-export-${DateTime.now().toIso8601String().substring(0, 10)}.zip';
      await ref.read(saveExportProvider)(bytes, name, origin: origin);
      if (mounted) showSuccess(context, l10n.exportReady((bytes.length / 1024).humanizedCount(context.l10n.localeName, decimalDigits: 0)));
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final email = ref.read(backendProvider).userEmail ?? '';
    final ok = await showAdaptiveSheet<bool>(
      context: context,
      builder: (_) => _ConfirmDelete(email: email),
    );
    if (ok != true || !mounted) return;
    final r = await runGuarded(context, () => ref.read(backendProvider).deleteAccount(email));
    if (r != null && mounted) {
      await showAdaptiveSheet<void>(
        context: context,
        dialogMaxWidth: 460,
        builder: (c) => FormSheet(
          icon: LucideIcons.circleCheck,
          iconColor: context.appColors.positive,
          title: l10n.accountDeleted,
          subtitle: l10n.accountDeletedBody(r.purgeAfter.toLocal().formattedWeekdayDate(context)),
          submitLabel: l10n.close,
          showCancel: false,
          onSubmit: () => Navigator.pop(c),
          children: const [],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final org = ref.watch(currentOrgProvider);
    final isAdmin = org != null && org.role != OrgRole.member;
    final retention = ref.watch(_retentionProvider).value;
    final scheme = context.colorScheme;
    return SubPage(
      title: l10n.privacy,
      children: [
        FormNote(l10n.privacyIntro, icon: LucideIcons.shield),
        SectionHeader(title: l10n.yourData),
        GroupedCard(
          children: [
            KeyedSubtree(
              key: _exportKey,
              child: GroupedTile(
                key: const Key('exportData'),
                icon: LucideIcons.download,
                title: l10n.exportMyData,
                subtitle: l10n.exportMyDataHelp,
                onTap: _busy ? null : _export,
                trailing: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
              ),
            ),
            FutureBuilder<bool>(
              future: Analytics.isConsentEnabled(),
              builder: (context, snapshot) {
                final enabled = snapshot.data ?? true;
                return GroupedTile(
                  key: const Key('shareAnalyticsTile'),
                  icon: LucideIcons.chartColumn,
                  title: l10n.shareAnalytics,
                  subtitle: l10n.shareAnalyticsHelp,
                  trailing: Switch.adaptive(
                    key: const Key('shareAnalyticsSwitch'),
                    value: enabled,
                    onChanged: (val) async {
                      await Analytics.setConsentEnabled(val);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ],
        ),
        if (isAdmin) ...[
          SectionHeader(title: l10n.workspace),
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.history,
                title: l10n.runHistoryRetention,
                subtitle: l10n.runHistoryRetentionHelp,
                trailing: retention == null
                    ? null
                    : DropdownButton<int>(
                        key: const Key('retention'),
                        value: [30, 90, 180, 365, 730].contains(retention) ? retention : null,
                        hint: Text(l10n.days(retention)),
                        underline: const SizedBox.shrink(),
                        borderRadius: AppRadius.tileAll,
                        items: [
                          for (final d in [30, 90, 180, 365, 730]) DropdownMenuItem(value: d, child: Text(l10n.days(d))),
                        ],
                        onChanged: hapticOnChanged((d) async {
                          if (d == null) return;
                          await runGuarded(context, () => ref.read(backendProvider).setRetentionDays(org.id, d));
                          ref.invalidate(_retentionProvider);
                        }, haptic: HapticsHelper.selection),
                      ),
              ),
            ],
          ),
        ],
        SectionHeader(title: l10n.dangerZone),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('deleteAccount'),
              icon: LucideIcons.trash2,
              destructive: true,
              title: l10n.deleteAccount,
              subtitle: l10n.deleteAccountHelp,
              onTap: _busy ? null : _delete,
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmDelete extends StatefulWidget {
  const _ConfirmDelete({required this.email});
  final String email;
  @override
  State<_ConfirmDelete> createState() => _ConfirmDeleteState();
}

class _ConfirmDeleteState extends State<_ConfirmDelete> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = _c.text.trim().toLowerCase() == widget.email.toLowerCase();
    return FormSheet(
      icon: LucideIcons.trash2,
      destructive: true,
      title: l10n.deleteAccountQuestion,
      subtitle: l10n.deleteAccountConfirm(widget.email),
      submitLabel: l10n.deleteAccount,
      submitKey: const Key('confirmDelete'),
      onSubmit: matches ? () => Navigator.pop(context, true) : null,
      children: [
        TextField(
          key: const Key('confirmEmail'),
          controller: _c,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.email, hintText: widget.email, prefixIcon: const Icon(LucideIcons.atSign, size: 20)),
        ),
      ],
    );
  }
}

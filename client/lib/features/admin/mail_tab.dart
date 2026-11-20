import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';

final _adminMailProvider = FutureProvider.autoDispose<List<AdminMailAddress>>(
  (r) => r.watch(backendProvider).adminMailAddresses(),
);

/// Mails every workspace sent today and the day's ceiling (BOT-EMAIL-NEXT-PLAN §4).
final _adminMailSendingProvider = FutureProvider.autoDispose<({int sent, int? ceiling})>(
  (r) => r.watch(backendProvider).adminMailSending(),
);

final _adminMailReservedProvider = FutureProvider.autoDispose<List<String>>(
  (r) => r.watch(backendProvider).adminMailReservedNames(),
);

/// Admin console > Mail (BOT-EMAIL-PLAN Phase 3): every hosted address with its recent sending
/// health, pause/lift (lifting clears an automatic pause), and the instance's reserved names.
class AdminMailTab extends ConsumerWidget {
  const AdminMailTab({super.key});

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    AdminMailAddress a,
    String status,
  ) async {
    final l10n = context.l10n;
    final lifting = status == 'active';
    final ok = await showConfirm(
      context: context,
      title: lifting ? l10n.adminMailLiftTitle(a.address) : l10n.adminMailPauseTitle(a.address),
      message: a.autoPaused && lifting ? l10n.adminMailLiftBody : null,
      confirmLabel: lifting ? l10n.adminMailLift : l10n.adminMailPause,
      destructive: !lifting,
      confirmKey: const Key('confirmMailStatus'),
    );
    if (!ok || !context.mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(backendProvider).setMailAddressStatus(a.id, status),
    );
    if (done != null) ref.invalidate(_adminMailProvider);
  }

  Future<void> _reserved(BuildContext context, WidgetRef ref, List<String> current) async {
    final l10n = context.l10n;
    // Not disposed: the pop animation still builds with it (as in links_screen.dart).
    final c = TextEditingController(text: current.join('\n'));
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      builder: (s) => FormSheet(
        icon: LucideIcons.shieldAlert,
        title: l10n.adminMailReserved,
        subtitle: l10n.adminMailReservedHelp,
        submitLabel: l10n.save,
        submitKey: const Key('saveMailReserved'),
        onSubmit: () async {
          final names = c.text.split(RegExp(r'[\s,]+')).where((n) => n.isNotEmpty).toList();
          final done = await runGuarded(
            s,
            () => ref.read(backendProvider).setMailReservedNames(names),
          );
          if (done != null && s.mounted) Navigator.pop(s, true);
        },
        children: [
          TextField(
            key: const Key('mailReservedNames'),
            controller: c,
            maxLines: 5,
            decoration: InputDecoration(labelText: l10n.adminMailReserved),
          ),
        ],
      ),
    );
    if (saved == true) ref.invalidate(_adminMailReservedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reserved = ref.watch(_adminMailReservedProvider).value ?? const [];
    final sending = ref.watch(_adminMailSendingProvider).value;
    return AsyncView(
      value: ref.watch(_adminMailProvider),
      onRetry: () {
        ref.invalidate(_adminMailProvider);
        ref.invalidate(_adminMailSendingProvider);
      },
      data: (items) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GroupedCard(
              children: [
                if (sending != null)
                  GroupedTile(
                    key: const Key('mailSentToday'),
                    icon: LucideIcons.send,
                    iconColor: sending.ceiling != null && sending.sent >= sending.ceiling! * 0.8
                        ? Theme.of(context).colorScheme.error
                        : null,
                    title: sending.ceiling != null
                        ? l10n.adminMailSentToday(sending.sent, sending.ceiling!)
                        : l10n.adminMailSentTodayNoCeiling(sending.sent),
                  ),
                GroupedTile(
                  key: const Key('mailReserved'),
                  icon: LucideIcons.shieldAlert,
                  title: l10n.adminMailReserved,
                  subtitle: reserved.isEmpty ? l10n.adminMailReservedHelp : reserved.join(', '),
                  onTap: () => _reserved(context, ref, reserved),
                ),
              ],
            ),
          ),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GroupedCard(
                children: [
                  GroupedTile(
                    key: Key('adminMail-${a.id}'),
                    icon: a.autoPaused
                        ? LucideIcons.octagonPause
                        : a.status == AdminMailAddressStatusEnum.active
                            ? LucideIcons.mail
                            : LucideIcons.mailX,
                    iconColor: a.autoPaused ? Theme.of(context).colorScheme.error : null,
                    title: a.address,
                    subtitle:
                        '${a.botName} · ${a.orgName}\n${l10n.adminMailHealth(a.sent30d, a.bounced30d, a.complained30d)}${a.autoPaused ? '\n${l10n.adminMailAutoPaused}' : ''}',
                    trailing: a.status == AdminMailAddressStatusEnum.retired
                        ? null
                        : TextButton(
                            key: Key('adminMailStatus-${a.id}'),
                            onPressed: () => _setStatus(
                              context,
                              ref,
                              a,
                              a.status == AdminMailAddressStatusEnum.active ? 'paused' : 'active',
                            ),
                            child: Text(
                              a.status == AdminMailAddressStatusEnum.active
                                  ? l10n.adminMailPause
                                  : l10n.adminMailLift,
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

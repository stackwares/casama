import 'package:casama_sdk/casama_sdk.dart' show AdminPinState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/admin_security.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../app_lock/confirm_identity.dart' show showPinSetup;
import 'admin_security_gate.dart';

final adminPinProvider = FutureProvider.autoDispose<AdminPinState>(
  (ref) => ref.watch(backendProvider).adminPinState(),
);

/// Admin → Security (D-452): the owner's 6-digit admin PIN, one of the ways to unlock the console
/// and confirm changes. Setting, changing or removing it takes a passkey or the password, never
/// the PIN itself.
class AdminSecurityTab extends ConsumerWidget {
  const AdminSecurityTab({super.key});

  /// A fresh check that isn't the PIN, unless one was just made.
  static Future<bool> _confirmWithoutPin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final me = ref.read(backendProvider).userId;
    if (AdminSecurity.recentlyVerified(me) &&
        AdminSecurity.lastVerifiedMethod != 'pin') {
      return true;
    }
    return showAdminConfirmation(context, allowPin: false);
  }

  Future<void> _set(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final pin = await showPinSetup(context, subtitle: l10n.adminPinSetupBody);
    if (pin == null || !context.mounted) return;
    if (!await _confirmWithoutPin(context, ref) || !context.mounted) return;
    final saved = await runGuarded(
      context,
      () => ref.read(backendProvider).setAdminPin(pin),
    );
    ref.invalidate(adminPinProvider);
    if (saved != null && context.mounted)
      showMessage(context, l10n.adminPinSaved);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (!await _confirmWithoutPin(context, ref) || !context.mounted) return;
    final removed = await runGuarded(
      context,
      () => ref.read(backendProvider).removeAdminPin(),
    );
    ref.invalidate(adminPinProvider);
    if (removed != null && context.mounted)
      showMessage(context, l10n.adminPinRemoved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AsyncView(
      value: ref.watch(adminPinProvider),
      data: (state) => PageColumn(
        children: [
          SectionHeader(title: l10n.adminPinTitle),
          GroupedCard(
            children: [
              GroupedTile(
                key: const Key('adminPinSet'),
                icon: LucideIcons.keyRound,
                title: state.set_ ? l10n.adminPinChange : l10n.adminPinSet,
                subtitle: state.disabled
                    ? l10n.adminPinOffHelp
                    : l10n.adminPinHelp,
                onTap: () => _set(context, ref),
              ),
              if (state.set_)
                GroupedTile(
                  key: const Key('adminPinRemove'),
                  icon: LucideIcons.trash2,
                  title: l10n.adminPinRemove,
                  onTap: () => _remove(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

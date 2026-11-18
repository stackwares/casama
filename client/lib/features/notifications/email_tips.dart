import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/app_card.dart';

/// Tips and news by email (D-302): the welcome series and occasional product news. Emails about
/// the account, plan and purchases always go out, so they have no switch.
final emailTipsProvider = FutureProvider.autoDispose<bool?>((ref) async {
  try {
    return await ref.watch(backendProvider).emailTips();
  } catch (_) {
    // A server older than D-302: no row.
    return null;
  }
});

class EmailTipsTile extends ConsumerWidget {
  const EmailTipsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(emailTipsProvider).value;
    if (on == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    Future<void> set(bool v) async {
      HapticsHelper.light();
      await runGuarded(
        context,
        () => ref.read(backendProvider).setEmailTips(v),
      );
      ref.invalidate(emailTipsProvider);
    }

    return GroupedTile(
      key: const Key('settingsEmailTips'),
      icon: LucideIcons.mail,
      title: l10n.emailTips,
      subtitle: l10n.emailTipsHelp,
      onTap: () => set(!on),
      trailing: Switch(
        key: const Key('emailTipsSwitch'),
        value: on,
        onChanged: set,
      ),
    );
  }
}

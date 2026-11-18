import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../ui/app_card.dart';

/// Monthly gallery picks by email (D-315): opt-in, off by default. Null when the server doesn't
/// send them (older than D-315), so the switch stays out of sight.
final galleryDigestProvider = FutureProvider.autoDispose<bool?>((ref) async {
  try {
    return await ref.watch(backendProvider).emailGalleryDigest();
  } catch (_) {
    return null;
  }
});

class GalleryDigestTile extends ConsumerWidget {
  const GalleryDigestTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(galleryDigestProvider).value;
    if (on == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    Future<void> set(bool v) async {
      HapticsHelper.light();
      await runGuarded(
        context,
        () => ref.read(backendProvider).setEmailGalleryDigest(v),
      );
      ref.invalidate(galleryDigestProvider);
    }

    return GroupedTile(
      key: const Key('settingsGalleryDigest'),
      icon: LucideIcons.mailOpen,
      title: l10n.galleryDigestEmails,
      subtitle: l10n.galleryDigestHelp,
      onTap: () => set(!on),
      trailing: Switch(
        key: const Key('galleryDigestSwitch'),
        value: on,
        onChanged: set,
      ),
    );
  }
}

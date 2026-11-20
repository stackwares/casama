import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/date_format.dart';

class SavedResets extends ConsumerStatefulWidget {
  const SavedResets({super.key});
  @override
  ConsumerState<SavedResets> createState() => _SavedResetsState();
}

class _SavedResetsState extends ConsumerState<SavedResets> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final resets = ref.watch(billingProvider).value?.resets ?? [];
    if (resets.isEmpty) return const SizedBox.shrink();
    final reset = resets.first;
    final words = context.l10n;
    return ListTile(
      title: Text(words.savedResetAvailable(resets.length)),
      subtitle: Text(
        '${reset.message}\n${words.savedResetExpiry(reset.expiresAt.toLocal().formattedExact(context))}',
      ),
      trailing: reset.canUse
          ? FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(words.savedResetUse),
                          content: Text(
                            words.savedResetConfirm(
                              reset.refillUsd.toStringAsFixed(2),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(words.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(words.savedResetUse),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      setState(() => busy = true);
                      await runGuarded(context, () async {
                        final org = ref.read(currentOrgProvider);
                        if (org == null) return;
                        await ref
                            .read(backendProvider)
                            .limitResets
                            .redeemSavedLimitReset(id: org.id);
                        ref.invalidate(billingProvider);
                        ref.invalidate(billingUsageProvider);
                      });
                      if (mounted) setState(() => busy = false);
                    },
              child: Text(words.savedResetUse),
            )
          : null,
    );
  }
}

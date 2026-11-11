import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

/// The person's passkeys (refreshed after changes).
final passkeysProvider = FutureProvider.autoDispose<List<PasskeyInfo>>(
  (ref) => ref.watch(backendProvider).passkeys(),
);

/// Settings → Passkeys (D-183): sign in with Face ID, a fingerprint or the screen lock instead of
/// a password or an email. Each device or password manager keeps its own passkey.
class PasskeysScreen extends ConsumerStatefulWidget {
  const PasskeysScreen({super.key});

  @override
  ConsumerState<PasskeysScreen> createState() => _PasskeysScreenState();
}

class _PasskeysScreenState extends ConsumerState<PasskeysScreen> {
  var _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final added = await runGuarded(context, () => ref.read(backendProvider).addPasskey());
    if (!mounted) return;
    setState(() => _busy = false);
    if (added == true) {
      showMessage(context, context.l10n.passkeyAdded);
      ref.invalidate(passkeysProvider);
    }
  }

  Future<void> _rename(PasskeyInfo p) async {
    final l10n = context.l10n;
    final name = await showTextPrompt(
      context,
      title: l10n.passkeyRenameTitle,
      label: l10n.passkeyNameLabel,
      initial: p.name,
      submitLabel: l10n.save,
      icon: LucideIcons.keyRound,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).renamePasskey(p.id, name.trim()));
    ref.invalidate(passkeysProvider);
  }

  Future<void> _remove(PasskeyInfo p) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.passkeyRemove,
      message: l10n.passkeyRemoveConfirm(p.name),
      confirmLabel: l10n.passkeyRemove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).removePasskey(p.id));
    ref.invalidate(passkeysProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(passkeysProvider);
    return SubPage(
      title: l10n.passkeys,
      children: [
        FormNote(l10n.passkeysHelp, icon: LucideIcons.keyRound),
        AsyncView(
          value: items,
          onRetry: () => ref.invalidate(passkeysProvider),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              if (list.isNotEmpty)
                GroupedCard(
                  children: [
                    for (final p in list)
                      GroupedTile(
                        icon: LucideIcons.keyRound,
                        title: p.name,
                        subtitle: p.lastUsedAt == null
                            ? l10n.passkeyAddedOn(MaterialLocalizations.of(context).formatShortDate(p.createdAt.toLocal()))
                            : l10n.passkeyLastUsed(relativeTime(p.lastUsedAt!, context)),
                        onTap: () => _rename(p),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: Key('renamePasskey-${p.id}'),
                              tooltip: l10n.passkeyRename,
                              icon: const Icon(LucideIcons.pencil, size: 18),
                              onPressed: () => _rename(p),
                            ),
                            TextButton(
                              key: Key('removePasskey-${p.id}'),
                              onPressed: () => _remove(p),
                              child: Text(l10n.passkeyRemove),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              OutlinedButton.icon(
                key: const Key('addPasskey'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : _add,
                icon: const Icon(LucideIcons.plus, size: 20),
                label: Text(list.isEmpty ? l10n.passkeyAdd : l10n.passkeyAddAnother),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

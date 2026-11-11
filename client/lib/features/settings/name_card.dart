import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/glow_button.dart';
import 'about_you_screen.dart';

/// About you (D-169): people who signed up before the welcome chat asked for a name get this once,
/// above their bots. Saving or "Not now" records it on the server, so it never comes back.
class NameCard extends ConsumerStatefulWidget {
  const NameCard({super.key});

  @override
  ConsumerState<NameCard> createState() => _NameCardState();
}

class _NameCardState extends ConsumerState<NameCard> {
  final _name = TextEditingController();
  var _filled = false;
  var _done = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool save}) async {
    final about = ref.read(aboutYouProvider).value;
    if (about == null) return;
    setState(() => _busy = true);
    final backend = ref.read(backendProvider);
    final ok = await runGuarded(context, () async {
      if (save && _name.text.trim().isNotEmpty) {
        await backend.saveAboutYou(about.copyWith(preferredName: _name.text.trim()));
      } else {
        await backend.markNameAsked();
      }
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _done = true;
    });
    if (ok == true) ref.invalidate(aboutYouProvider);
  }

  @override
  Widget build(BuildContext context) {
    final about = ref.watch(aboutYouProvider).value;
    if (_done || about == null || about.nameAsked || (about.preferredName?.trim().isNotEmpty ?? false)) return const SizedBox.shrink();
    if (!_filled) {
      _filled = true;
      _name.text = about.name;
    }
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.gutter, AppSpace.xs),
      child: AppCard(
        key: const Key('nameCard'),
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.sm,
          children: [
            Row(
              children: [
                Icon(LucideIcons.userRound, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(l10n.whatToCallYou, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(l10n.nameCardHelp, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            TextField(
              key: const Key('nameCardField'),
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(counterText: ''),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _finish(save: true),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(key: const Key('nameCardLater'), onPressed: _busy ? null : () => _finish(save: false), child: Text(l10n.notNow)),
                const SizedBox(width: AppSpace.xs),
                GlowButton(key: const Key('nameCardSave'), onPressed: _busy || _name.text.trim().isEmpty ? null : () => _finish(save: true), child: Text(l10n.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

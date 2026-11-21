import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/casama_mark.dart';
import 'model_keys_screen.dart' show providerLabel;
import 'provider_picker.dart';

/// "Who runs your bots" as two cards side by side: Casama, with its mark, and your own provider,
/// with the logos of the keys you've added. The picked one gets the accent border and a check.
class WhoRunsChoice extends StatelessWidget {
  const WhoRunsChoice({
    super.key,
    required this.ownSelected,
    required this.casamaAvailable,
    required this.ownProviders,
    required this.onCasama,
    required this.onOwn,
  });
  final bool ownSelected;

  /// False when Casama's models are off for this plan: its card shows, dimmed, as paused.
  final bool casamaAvailable;

  /// The providers of the workspace's chat keys, for the own-provider card's logos.
  final List<ProviderId> ownProviders;
  final VoidCallback onCasama;
  final VoidCallback onOwn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final casama = _ChoiceCard(
      key: const Key('workspaceDefaultCasama'),
      selected: !ownSelected && casamaAvailable,
      enabled: casamaAvailable,
      art: const SizedBox(
        width: 44,
        height: 44,
        child: CasamaMark(size: 44, animate: false),
      ),
      title: l10n.whoRunsCasama,
      body: casamaAvailable
          ? l10n.whoRunsCasamaShort
          : l10n.whoRunsCasamaOffHelp,
      footIcon: LucideIcons.coins,
      foot: l10n.whoRunsCasamaCost,
      onTap: onCasama,
    );
    final own = _ChoiceCard(
      key: const Key('workspaceDefaultOwn'),
      selected: ownSelected,
      enabled: true,
      art: _LogoStack(ownProviders),
      title: l10n.whoRunsOwn,
      body: l10n.whoRunsOwnShort,
      footIcon: LucideIcons.badgeCheck,
      foot: l10n.whoRunsOwnCost,
      onTap: onOwn,
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 280
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.xs,
              children: [casama, own],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpace.xs,
                children: [
                  Expanded(child: casama),
                  Expanded(child: own),
                ],
              ),
            ),
    );
  }
}

/// The workspace's own keys as chips with their provider's logo, in place of a dropdown.
class OwnKeyChips extends StatelessWidget {
  const OwnKeyChips({
    super.key,
    required this.keys,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });
  final List<Credential> keys;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<Credential> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        Text(
          l10n.modelKey,
          style: context.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final k in keys)
              ChoiceChip(
                key: Key('workspaceDefaultKey-${k.id}'),
                selected: k.id == selectedId,
                showCheckmark: false,
                avatar: ProviderLogo(k.provider, size: 22),
                label: Text('${k.label} · ${providerLabel(k.provider)}'),
                // Only a non-admin's chips are disabled; the picked one stays bright.
                onSelected: !enabled
                    ? null
                    : (_) {
                        if (k.id == selectedId) return;
                        HapticsHelper.selection();
                        onSelected(k);
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.selected,
    required this.enabled,
    required this.art,
    required this.title,
    required this.body,
    required this.footIcon,
    required this.foot,
    required this.onTap,
  });
  final bool selected;
  final bool enabled;
  final Widget art;
  final String title;
  final String body;
  final IconData footIcon;
  final String foot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final fast = AppMotion.of(context, AppMotion.fast);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: fast,
        child: Material(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.45)
              : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.tileAll,
            side: BorderSide(
              color: selected ? scheme.primary : colors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    if (!selected) HapticsHelper.selection();
                    onTap();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: art,
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: fast,
                        curve: Curves.easeOutBack,
                        child: Icon(
                          LucideIcons.circleCheck,
                          size: 22,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Icon(footIcon, size: 14, color: scheme.primary),
                      const SizedBox(width: AppSpace.xxs),
                      Flexible(
                        child: Text(
                          foot,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to three provider logos, overlapping like a stack of cards. With no keys yet, the usual
/// model providers stand in, faded, as a hint of what can go here.
class _LogoStack extends StatelessWidget {
  const _LogoStack(this.providers);
  final List<ProviderId> providers;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const step = 22.0;
    final shown = providers.isEmpty
        ? const [ProviderId.openrouter, ProviderId.openai, ProviderId.anthropic]
        : providers.toSet().take(3).toList();
    final surface = context.colorScheme.surface;
    return Opacity(
      opacity: providers.isEmpty ? 0.5 : 1,
      child: SizedBox(
        height: 44,
        width: size + step * (shown.length - 1) + 4,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: step * i,
                child: DecoratedBox(
                  // A ring in the card's color separates the overlapping tiles.
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(size * 0.34),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ProviderLogo(shown[i], size: size),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../integrations/app_logo.dart';
import 'model_keys_screen.dart' show providerLabel;

/// A provider's brand mark on a tile: its bundled logo where there is one, else an icon for what
/// it does (search, data, a self-hosted server).
class ProviderLogo extends StatelessWidget {
  const ProviderLogo(this.provider, {super.key, this.size = 40});
  final ProviderId provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (String? mark, String? color, IconData? icon) = switch (provider) {
      ProviderId.openrouter => ('openrouter', '6467F2', null),
      ProviderId.openai || ProviderId.chatgpt => ('openai', '000000', null),
      ProviderId.anthropic => ('anthropic', 'D97757', null),
      ProviderId.google => ('google_gemini', '4E7CF6', null),
      ProviderId.xai => ('xai', '000000', null),
      ProviderId.braveSearch => ('brave', 'FB542B', null),
      ProviderId.googleMaps => ('google_maps', '34A853', null),
      ProviderId.mapbox => ('mapbox', '4264FB', null),
      ProviderId.tavily => (null, '1F6FEB', LucideIcons.search),
      ProviderId.parallel => (null, '2B2D42', LucideIcons.telescope),
      ProviderId.serper => (null, 'EA4335', LucideIcons.scanSearch),
      ProviderId.treg => (null, '0F9D76', LucideIcons.database),
      ProviderId.openaiCompatible => (null, null, LucideIcons.server),
    };
    return AppLogo(
      appId: mark,
      name: providerLabel(provider),
      color: color,
      icon: mark == null ? icon : null,
      size: size,
    );
  }
}

/// Picks the provider for a new key: model providers as logo tiles up front, and search, maps,
/// data and self-hosted servers folded under "More providers" (D-182). Replaces a long dropdown.
class ProviderPicker extends StatefulWidget {
  const ProviderPicker({
    super.key,
    required this.primary,
    required this.more,
    required this.value,
    required this.onChanged,
    required this.hint,
  });

  /// Shown up front (the chat-model providers).
  final List<ProviderId> primary;

  /// Folded under "More providers"; shown open when [primary] is empty.
  final List<ProviderId> more;
  final ProviderId value;
  final ValueChanged<ProviderId> onChanged;

  /// The short line under a provider's name.
  final String? Function(ProviderId) hint;

  @override
  State<ProviderPicker> createState() => _ProviderPickerState();
}

class _ProviderPickerState extends State<ProviderPicker> {
  // Open when the chosen provider is one of the folded ones, so the choice is always visible.
  late bool _moreOpen =
      widget.primary.isEmpty || widget.more.contains(widget.value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final foldable = widget.primary.isNotEmpty && widget.more.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [
        Text(
          l10n.provider,
          style: context.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.primary.isNotEmpty) _grid(widget.primary),
        if (foldable)
          InkWell(
            key: const Key('moreProviders'),
            borderRadius: AppRadius.rowAll,
            onTap: () {
              HapticsHelper.selection();
              setState(() => _moreOpen = !_moreOpen);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                children: [
                  Text(
                    l10n.moreProviders,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${widget.more.length}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  const Expanded(child: Divider()),
                  const SizedBox(width: AppSpace.xs),
                  AnimatedRotation(
                    turns: _moreOpen ? 0.5 : 0,
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: widget.more.isNotEmpty && (_moreOpen || !foldable)
              ? _grid(widget.more)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  // Upright tiles in rows of equal height: two across on a phone, more on wider screens.
  Widget _grid(List<ProviderId> providers) => LayoutBuilder(
    builder: (context, c) {
      const gap = AppSpace.xs;
      final columns = c.maxWidth >= 720 ? 4 : (c.maxWidth >= 480 ? 3 : 2);
      return Column(
        spacing: gap,
        children: [
          for (var i = 0; i < providers.length; i += columns)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  for (var j = i; j < i + columns; j++)
                    Expanded(
                      child: j >= providers.length
                          ? const SizedBox.shrink()
                          : _ProviderTile(
                              provider: providers[j],
                              hint: widget.hint(providers[j]),
                              selected: providers[j] == widget.value,
                              onTap: () {
                                final p = providers[j];
                                if (p == widget.value) return;
                                HapticsHelper.selection();
                                widget.onChanged(p);
                              },
                            ),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
  final ProviderId provider;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
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
          key: Key('provider-${provider.value}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProviderLogo(provider, size: 40),
                    const Spacer(),
                    AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: AppMotion.of(context, AppMotion.fast),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        LucideIcons.circleCheck,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  providerLabel(provider),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hint case final h? when h.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    h,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

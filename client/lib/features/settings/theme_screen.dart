import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/schemes.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import 'appearance_preview.dart';

String schemeFamilyLabel(BuildContext context, SchemeFamily f) {
  final l10n = context.l10n;
  return switch (f) {
    SchemeFamily.brand => 'Casama',
    SchemeFamily.purple => l10n.familyPurple,
    SchemeFamily.blue => l10n.familyBlue,
    SchemeFamily.teal => l10n.familyTeal,
    SchemeFamily.green => l10n.familyGreen,
    SchemeFamily.warm => l10n.familyWarm,
    SchemeFamily.red => l10n.familyRed,
    SchemeFamily.neutral => l10n.familyNeutral,
  };
}

/// Settings → Color scheme: every FlexColorScheme scheme plus Casama's own, with a live preview,
/// search and color families. Picking one applies it right away.
class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key});

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen> {
  final _search = TextEditingController();
  SchemeFamily? _family;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ThemeChoice> get _shown {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final c in themeChoices)
        if ((_family == null || c.family == _family) && (q.isEmpty || c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q))) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final shown = _shown;
    return SubPage(
      title: l10n.colorScheme,
      children: [
        const AppearancePreview(),
        const SizedBox(height: AppSpace.md),
        AppSegmentedControl<ThemeMode>(
          values: const [ThemeMode.light, ThemeMode.system, ThemeMode.dark],
          labels: {ThemeMode.light: l10n.themeLight, ThemeMode.system: l10n.themeSystem, ThemeMode.dark: l10n.themeDark},
          icons: const {ThemeMode.light: LucideIcons.sun, ThemeMode.system: LucideIcons.sunMoon, ThemeMode.dark: LucideIcons.moon},
          groupValue: appearance.mode,
          onValueChanged: notifier.setMode,
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          key: const Key('themeSearch'),
          controller: _search,
          decoration: InputDecoration(
            hintText: l10n.searchThemes,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in [null, ...SchemeFamily.values])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.xs),
                  child: ChoiceChip(
                    key: Key('family-${f?.name ?? 'all'}'),
                    selected: _family == f,
                    showCheckmark: false,
                    label: Text(f == null ? l10n.familyAll : schemeFamilyLabel(context, f)),
                    onSelected: (_) => setState(() => _family = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
            child: Text(
              l10n.noThemesFound,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 150).floor().clamp(2, 5);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpace.sm,
                  crossAxisSpacing: AppSpace.sm,
                  childAspectRatio: 0.92,
                ),
                itemCount: shown.length,
                itemBuilder: (context, i) =>
                    _SchemeTile(choice: shown[i], selected: shown[i].id == appearance.schemeId, onTap: () => notifier.setScheme(shown[i].id)),
              );
            },
          ),
      ],
    );
  }
}

/// One scheme: its colors as a tiny card, the name, and a check when it's the current one.
class _SchemeTile extends StatelessWidget {
  const _SchemeTile({required this.choice, required this.selected, required this.onTap});
  final ThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final brightness = Theme.of(context).brightness;
    final c = choice.colors(brightness);
    final dark = brightness == Brightness.dark;
    final card = dark ? Color.lerp(c.primaryContainer, Colors.black, 0.55)! : Color.lerp(c.primaryContainer, Colors.white, 0.45)!;
    return Semantics(
      button: true,
      selected: selected,
      label: choice.name,
      child: Material(
        color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? scheme.primary : context.appColors.hairline, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('scheme-${choice.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
                    child: Stack(
                      children: [
                        // A tiny chat: the bot's line in secondary, yours in primary.
                        Positioned(
                          left: 0,
                          top: 2,
                          child: Container(
                            width: 44,
                            height: 12,
                            decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 20,
                          child: Container(
                            width: 36,
                            height: 12,
                            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Row(
                            children: [
                              for (final dot in [c.primary, c.secondary, c.tertiary])
                                Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: dot,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: card, width: 2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (selected)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                              child: Icon(LucideIcons.check, size: 14, color: scheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  choice.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelLarge?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots in a scheme's primary, secondary and tertiary colors, for Settings rows.
class SchemeDots extends StatelessWidget {
  const SchemeDots({super.key, required this.colors, this.size = 14});
  final FlexSchemeColor colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = context.isDark ? context.colorScheme.surfaceContainerLow : context.colorScheme.surfaceContainerLowest;
    return SizedBox(
      width: size * 2.2,
      height: size,
      child: Stack(
        children: [
          for (final (i, c) in [colors.tertiary, colors.secondary, colors.primary].indexed)
            Positioned(
              left: (2 - i) * size * 0.6,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

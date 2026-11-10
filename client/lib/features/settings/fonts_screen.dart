import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/fonts.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';

enum _Role { heading, body }

/// Settings → Fonts: one font for headlines and one for everything else, from a short suggested
/// list or any Google Font. Each name is drawn in its own face; picking one applies it right away.
class FontsScreen extends ConsumerStatefulWidget {
  const FontsScreen({super.key});

  @override
  ConsumerState<FontsScreen> createState() => _FontsScreenState();
}

class _FontsScreenState extends ConsumerState<FontsScreen> {
  final _search = TextEditingController();
  var _role = _Role.heading;
  late final List<String> _all = allGoogleFonts()..sort();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final scheme = context.colorScheme;
    final current = _role == _Role.heading ? appearance.headingFont : appearance.bodyFont;
    final q = _search.text.trim().toLowerCase();
    final suggested = _role == _Role.heading ? curatedHeadingFonts : curatedBodyFonts;
    final List<String> shown = q.isEmpty ? suggested : [for (final f in _all) if (f.toLowerCase().contains(q)) f].take(60).toList();
    void pick(String family) => _role == _Role.heading ? notifier.setFonts(heading: family) : notifier.setFonts(body: family);
    final isDefault = appearance.headingFont == defaultHeadingFont && appearance.bodyFont == defaultBodyFont;

    return SubPage(
      title: l10n.fonts,
      children: [
        // The pair as it will look.
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.fontPreviewGreeting, style: context.textTheme.headlineMedium),
              const SizedBox(height: AppSpace.xs),
              Text(l10n.fontSample, style: context.textTheme.bodyLarge),
              const SizedBox(height: AppSpace.xxs),
              Text(
                '${appearance.headingFont} · ${appearance.bodyFont}',
                style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        AppSegmentedControl<_Role>(
          values: const [_Role.heading, _Role.body],
          labels: {_Role.heading: l10n.headingFont, _Role.body: l10n.bodyFont},
          icons: const {_Role.heading: LucideIcons.heading, _Role.body: LucideIcons.text},
          groupValue: _role,
          onValueChanged: (r) => setState(() => _role = r),
        ),
        const SizedBox(height: AppSpace.sm),
        FormNote(l10n.fontsHelp),
        const SizedBox(height: AppSpace.sm),
        TextField(
          key: const Key('fontSearch'),
          controller: _search,
          decoration: InputDecoration(
            hintText: l10n.searchFonts,
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
        const SizedBox(height: AppSpace.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs, vertical: AppSpace.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  q.isEmpty ? l10n.suggestedFonts : l10n.allFonts,
                  style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              if (!isDefault)
                TextButton(
                  key: const Key('resetFonts'),
                  onPressed: () => notifier.setFonts(heading: defaultHeadingFont, body: defaultBodyFont),
                  child: Text(l10n.resetFonts),
                ),
            ],
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
            child: Text(l10n.noFontsFound, textAlign: TextAlign.center, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.appColors.hairline),
            ),
            child: Column(
              children: [
                for (final (i, family) in shown.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: AppSpace.md, color: context.appColors.hairline),
                  _FontRow(
                    family: family,
                    heading: _role == _Role.heading,
                    selected: family == current,
                    bundled: bundledFonts.contains(family),
                    onTap: () => pick(family),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FontRow extends StatelessWidget {
  const _FontRow({required this.family, required this.heading, required this.selected, required this.bundled, required this.onTap});
  final String family;
  final bool heading;
  final bool selected;
  final bool bundled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = (heading ? context.textTheme.titleLarge : context.textTheme.bodyLarge)!.copyWith(
      fontWeight: heading ? FontWeight.w600 : FontWeight.w400,
      fontSize: heading ? 22 : 18,
      color: scheme.onSurface,
    );
    return InkWell(
      key: Key('font-$family'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(family, maxLines: 1, overflow: TextOverflow.ellipsis, style: fontStyle(family, base))),
            if (bundled) Icon(LucideIcons.hardDrive, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.sm),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: AppMotion.fast,
              child: Icon(LucideIcons.circleCheck, size: 20, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

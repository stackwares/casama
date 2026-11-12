import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// The pieces the search panel is drawn with (D-235): section headers, one row style for every
/// kind of result, and highlighted snippets.

/// A small uppercase section label, with an optional action at the end (Clear).
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader(this.label, {super.key, this.action});
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpace.md + AppSpace.xs, AppSpace.md, action == null ? AppSpace.md : AppSpace.xs, AppSpace.xxs),
    child: SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
          ?action,
        ],
      ),
    ),
  );
}

/// A rounded square with an icon: the mark of a result that isn't a bot.
class SearchIconTile extends StatelessWidget {
  const SearchIconTile(this.icon, {super.key, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colorScheme.onSurfaceVariant;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon)),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// One row: a mark, a title, an optional line or two under it, and a short note at the end. The
/// selected row (arrow keys, or the pointer over it) is tinted and shows the Enter key.
class SearchRowTile extends StatelessWidget {
  const SearchRowTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.showEnter = false,
    this.onTap,
    this.onHover,
  });

  final Widget leading;
  final String title;
  final InlineSpan? subtitle;
  final String? trailing;
  final bool selected;

  /// Whether the selected row shows ↵ (windows with a keyboard).
  final bool showEnter;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: MouseRegion(
        onEnter: onHover == null ? null : (_) => onHover!(),
        child: Material(
          color: selected ? scheme.primary.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.row),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.row),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm - 2, vertical: AppSpace.xs),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: onTap == null ? muted : null),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text.rich(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: muted, height: 1.35)),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpace.xs),
                    Text(trailing!, style: context.textTheme.labelSmall?.copyWith(color: muted, fontFeatures: AppText.tabular)),
                  ],
                  if (selected && showEnter && onTap != null) ...[
                    const SizedBox(width: AppSpace.xs),
                    _Key('↵', color: scheme.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A keycap, for the Enter hint on the selected row and the keyboard line under the list.
class _Key extends StatelessWidget {
  const _Key(this.label, {required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: color.withValues(alpha: 0.4)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

/// A snippet's spans, with the matched words (between « ») bold on a soft tint.
List<InlineSpan> snippetSpans(BuildContext context, String text) {
  final hit = TextStyle(
    fontWeight: FontWeight.w700,
    color: context.colorScheme.onSurface,
    backgroundColor: context.colorScheme.primary.withValues(alpha: 0.16),
  );
  final parts = text.split(RegExp('[«»]'));
  return [
    for (var i = 0; i < parts.length; i++)
      if (parts[i].isNotEmpty) TextSpan(text: parts[i], style: i.isOdd ? hit : null),
  ];
}

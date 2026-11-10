import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable_scale.dart';

/// Neutral card with a hairline border; the base surface for every section.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? context.appColors.hairline, width: borderWidth),
    );
    final content = Padding(padding: padding, child: child);
    return Padding(
      padding: margin,
      child: PressableScale(
        enabled: onTap != null,
        scale: 0.985,
        child: Semantics(
          button: onTap != null,
          child: Card(
            color: color ?? context.colorScheme.surfaceContainerLow,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: onTap == null ? content : InkWell(onTap: onTap, customBorder: shape, child: content),
          ),
        ),
      ),
    );
  }
}

/// Rows inside one rounded card with inset hairline dividers (settings, lists of a few items).
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children, this.dividerIndent = 60, this.margin = EdgeInsets.zero});

  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final rows = children.where((w) => w is! SizedBox || w.child != null).toList();
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[if (i > 0) Divider(indent: dividerIndent), rows[i]],
        ],
      ),
    );
  }
}

/// A settings-style row: a tinted icon tile, title, optional subtitle and trailing widget.
class GroupedTile extends StatelessWidget {
  const GroupedTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
    this.showChevron,
    this.leading,
  });

  final IconData icon;

  /// Replaces the icon tile (an avatar or a logo).
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;

  /// Defaults to true when the row navigates ([onTap] set, no [trailing]).
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tint = destructive ? scheme.error : (iconColor ?? scheme.primary);
    final chevron = showChevron ?? (onTap != null && trailing == null);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: context.isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.icon),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: tint),
                ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: destructive ? scheme.error : null),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(subtitle!, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.3)),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpace.xs), trailing!],
            if (chevron) Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// Sentence-case section title with an optional muted count and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.lg, AppSpace.xxs, AppSpace.xs),
  });

  final String title;
  final String? count;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.1);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  text: title,
                  children: [
                    if (count != null)
                      TextSpan(
                        text: '  $count',
                        style: TextStyle(color: context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontFeatures: AppText.tabular),
                      ),
                  ],
                ),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Sentence-case status text in its meaning color, optionally in a soft pill.
class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.text, required this.color, this.pill = false, this.icon});

  final String text;
  final Color color;
  final bool pill;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600, height: 1.15),
          ),
        ),
      ],
    );
    if (!pill) return label;
    return DecoratedBox(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), child: label),
    );
  }
}

/// Stadium search field used by pickers and filter sheets.
InputDecoration searchFieldDecoration(BuildContext context, String hint) {
  final scheme = context.colorScheme;
  const radius = BorderRadius.all(Radius.circular(40));
  const idle = OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none);
  final focused = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: scheme.primary, width: 1.5),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(LucideIcons.search, size: 22),
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withValues(alpha: context.isDark ? 0.7 : 0.55),
    isDense: true,
    border: idle,
    enabledBorder: idle,
    focusedBorder: focused,
    disabledBorder: idle,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
  );
}

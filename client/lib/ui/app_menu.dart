import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// An entry in an [AppMenuButton]: an action or a divider.
sealed class AppMenuEntry {
  const AppMenuEntry();
}

/// One action: icon, label, optional one-line hint, red when it destroys something.
class AppMenuItem extends AppMenuEntry {
  const AppMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.key,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final Key? key;
}

/// A thin line between groups of actions (put destructive ones last, after a divider).
class AppMenuDivider extends AppMenuEntry {
  const AppMenuDivider();
}

/// The "more actions" button on cards and rows: a ⋯ icon that opens a compact menu with leading
/// icons, grouped by dividers, destructive actions in red. Replaces PopupMenuButton with ListTile
/// children.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.entries,
    this.tooltip,
    this.icon = LucideIcons.ellipsisVertical,
  });

  final List<AppMenuEntry> entries;
  final String? tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // Drop leading, trailing and doubled dividers left by conditional entries.
    final items = <AppMenuEntry>[];
    for (final e in entries) {
      if (e is AppMenuDivider && (items.isEmpty || items.last is AppMenuDivider)) continue;
      items.add(e);
    }
    if (items.isNotEmpty && items.last is AppMenuDivider) items.removeLast();
    return MenuAnchor(
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      ),
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final e in items)
          switch (e) {
            AppMenuDivider() => const Divider(height: 9, indent: 12, endIndent: 12),
            AppMenuItem() => _item(context, e),
          },
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: scheme.onSurfaceVariant),
        onPressed: () {
          HapticsHelper.selection();
          controller.isOpen ? controller.close() : controller.open();
        },
      ),
    );
  }

  Widget _item(BuildContext context, AppMenuItem e) {
    final scheme = context.colorScheme;
    final color = e.destructive ? context.appColors.negative : null;
    return MenuItemButton(
      key: e.key,
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(220, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        foregroundColor: color,
        iconColor: color ?? scheme.onSurfaceVariant,
      ),
      leadingIcon: Icon(e.icon, size: 18),
      onPressed: e.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: AppSpace.sm),
          child: e.subtitle == null
              ? Text(e.label)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.label),
                    Text(
                      e.subtitle!,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../core/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';

/// One choice in a [PropertyRow]'s menu.
class PropertyOption<T> {
  const PropertyOption({
    required this.value,
    required this.label,
    this.color,
    this.selected = false,
    this.icon,
    this.key,
  });
  final T value;
  final String label;

  /// Tints the leading icon; defaults to the muted foreground.
  final Color? color;
  final bool selected;

  /// Leading icon; none when null and [color] is null too.
  final IconData? icon;
  final Key? key;
}

/// A settings-style row for picking one value: tinted icon tile, name, and the current value on
/// the right with an up-down chevron. Tapping the row opens a fixed-width menu tucked under the
/// value, inside the card's right edge, with a check on the current choice. Put these in a
/// [GroupedCard] instead of stacking dropdown fields.
class PropertyRow<T> extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
    this.iconColor,
    this.valueColor,
    this.subtitle,
    this.menuWidth = 240,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;

  /// The current value's label.
  final String value;
  final Color? valueColor;
  final List<PropertyOption<T>> options;
  final ValueChanged<T> onSelected;
  final double menuWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        style: const MenuStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: AppSpace.xs)),
        ),
        alignmentOffset: Offset(
          (constraints.maxWidth - menuWidth - AppSpace.xs).clamp(0, double.infinity),
          4,
        ),
        menuChildren: [
          for (final o in options)
            MenuItemButton(
              key: o.key,
              style: MenuItemButton.styleFrom(
                minimumSize: Size(menuWidth, 48),
                maximumSize: Size(menuWidth, 48),
              ),
              leadingIcon: o.icon == null && o.color == null
                  ? null
                  : Icon(o.icon ?? LucideIcons.circleDot, size: 16, color: o.color ?? scheme.onSurfaceVariant),
              trailingIcon: Icon(o.selected ? LucideIcons.check : null, size: 18),
              onPressed: () {
                HapticsHelper.selection();
                if (!o.selected) onSelected(o.value);
              },
              child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        builder: (context, controller, _) => GroupedTile(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          onTap: options.isEmpty ? null : () => controller.isOpen ? controller.close() : controller.open(),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: valueColor ?? scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronsUpDown, size: 16, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

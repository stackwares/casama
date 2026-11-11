import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One sliding segmented control for the whole app, whatever the platform, on the app's surfaces.
class AppSegmentedControl<T extends Object> extends StatelessWidget {
  const AppSegmentedControl({super.key, required this.values, required this.labels, required this.groupValue, required this.onValueChanged, this.icons});

  final List<T> values;
  final Map<T, String> labels;
  final Map<T, IconData>? icons;
  /// Null (or a value not in [values]) selects nothing, e.g. while a choice from elsewhere is picked.
  final T? groupValue;
  final ValueChanged<T>? onValueChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = context.isDark;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: values.contains(groupValue) ? groupValue : null,
        onValueChanged: (v) {
          if (v != null) onValueChanged?.call(v);
        },
        backgroundColor: scheme.surfaceContainerHigh,
        thumbColor: dark ? scheme.surfaceContainerHighest : Colors.white,
        children: {
          for (final v in values)
            v: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                if (icons?[v] != null) ...[
                  Icon(icons![v], size: 16, color: v == groupValue ? scheme.primary : scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    labels[v]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: v == groupValue ? FontWeight.w700 : FontWeight.w500,
                      color: v == groupValue ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ]),
            ),
        },
      ),
    );
  }
}

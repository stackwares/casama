import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// A card's or sheet's buttons, laid out so they never wrap into a ragged pile.
///
/// The main buttons ([actions], one or two, the main action last) share one row in equal
/// widths. When that row gets too tight (a narrow card, or large text), they stack full width
/// with the main action on top. Quieter choices ([extra], usually text buttons such as
/// "Always Allow" or "View Run") sit centered on their own line underneath.
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.actions, this.extra = const []})
    : assert(actions.length > 0 && actions.length <= 2);

  final List<Widget> actions;
  final List<Widget> extra;

  /// The narrowest a button may get in the shared row, at normal text size.
  static const double _minButtonWidth = 116;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final main = LayoutBuilder(
      builder: (context, box) {
        final count = actions.length;
        final each = (box.maxWidth - AppSpace.xs * (count - 1)) / count;
        if (count == 1 || each >= _minButtonWidth * scale) {
          return Row(
            spacing: AppSpace.xs,
            children: [for (final a in actions) Expanded(child: a)],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.xs,
          children: actions.reversed.toList(),
        );
      },
    );
    if (extra.isEmpty) return main;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        const SizedBox(height: AppSpace.xxs),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.xs,
          children: extra,
        ),
      ],
    );
  }
}

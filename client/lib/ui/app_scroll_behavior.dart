import 'package:material_ui/material_ui.dart';

/// Scrollbars on every vertical list, phones included (Flutter only adds them on desktop), so people
/// see where they are in a list and how much is left. Horizontal rows (chips, galleries) stay without
/// one. Don't also wrap lists in a Scrollbar by hand: two scrollbars on one list fight each other.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (axisDirectionToAxis(details.direction) == Axis.horizontal) return child;
    return Scrollbar(controller: details.controller, child: child);
  }
}

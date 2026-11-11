import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A chip, tab or swatch in a horizontal row that scrolls itself fully into view, centered, when it
/// becomes the selected one, whether tapped or picked from elsewhere. An item already selected when
/// the row first appears is brought into view too. Only the row scrolls, never the page around it;
/// outside a horizontal scroll view (a wrapping row on a wide window) it does nothing.
class RevealWhenSelected extends StatefulWidget {
  const RevealWhenSelected({super.key, required this.selected, required this.child});

  /// Whether this item is the row's current choice.
  final bool selected;
  final Widget child;

  @override
  State<RevealWhenSelected> createState() => _RevealWhenSelectedState();
}

class _RevealWhenSelectedState extends State<RevealWhenSelected> {
  @override
  void initState() {
    super.initState();
    // Only while the row lays out for the first time: an item rebuilt as the person scrolls (lazy
    // lists build items as they come near) must not pull the row back to it.
    final row = context.findAncestorStateOfType<ScrollableState>();
    if (widget.selected && row != null && !row.position.hasContentDimensions) _revealAfterLayout();
  }

  @override
  void didUpdateWidget(RevealWhenSelected oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _revealAfterLayout();
  }

  void _revealAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = context.findAncestorStateOfType<ScrollableState>();
      final item = context.findRenderObject();
      if (row == null || row.position.axis != Axis.horizontal || item == null || !item.attached) return;
      // The row's own position, not Scrollable.ensureVisible: that one also scrolls every scroll
      // view around the row, so the page would jump to center the row vertically.
      row.position.ensureVisible(item, alignment: 0.5, duration: AppMotion.of(context, const Duration(milliseconds: 200)), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

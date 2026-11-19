import 'package:material_ui/material_ui.dart';

import '../core/fold/fold.dart';

/// A page laid out around a fold (D-411). While a fold divides the page, [first] takes the half
/// before it (the top of a device propped up like a laptop, the left of one held like a book) and
/// [second] the half after it, and the band between them stays empty. Without a dividing fold the
/// page is [whole].
///
/// Put what is watched in [first] and what is touched in [second]: the top half of a propped-up
/// device is seen from a distance, and the bottom half lies under the hand.
///
/// It must fill its page from the top left corner (a Scaffold's body with no app bar): the fold
/// is measured from there.
class FoldSplit extends StatelessWidget {
  const FoldSplit({
    super.key,
    required this.first,
    required this.second,
    required this.whole,
  });
  final Widget first;
  final Widget second;
  final Widget whole;

  /// Whether a fold divides the page around [context] right now.
  static bool dividing(BuildContext context) =>
      FoldInfo.of(context).gap != null;

  @override
  Widget build(BuildContext context) {
    final info = FoldInfo.of(context);
    final gap = info.gap;
    if (gap == null) return whole;
    final media = MediaQuery.of(context);
    // Each half is its own little screen: the insets of the edges it touches, and no fold.
    MediaQueryData half({required bool before}) {
      final p = media.padding;
      final v = media.viewPadding;
      EdgeInsets cut(EdgeInsets e) => info.foldVertical
          ? e.copyWith(left: before ? e.left : 0, right: before ? 0 : e.right)
          : e.copyWith(top: before ? e.top : 0, bottom: before ? 0 : e.bottom);
      return media.copyWith(
        padding: cut(p),
        viewPadding: cut(v),
        // The keyboard comes up in the half under the hand; the other half never moves for it.
        viewInsets: before && !info.foldVertical
            ? media.viewInsets.copyWith(bottom: 0)
            : media.viewInsets,
        displayFeatures: const [],
      );
    }

    Widget part(Widget child, {required bool before}) => MediaQuery(
      data: half(before: before),
      child: FoldPane(rect: Rect.zero, child: child),
    );

    return Stack(
      children: [
        if (info.foldVertical) ...[
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: gap.left,
            child: part(first, before: true),
          ),
          Positioned(
            left: gap.right,
            top: 0,
            bottom: 0,
            right: 0,
            child: part(second, before: false),
          ),
        ] else ...[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: gap.top,
            child: part(first, before: true),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: gap.bottom,
            bottom: 0,
            child: part(second, before: false),
          ),
        ],
      ],
    );
  }
}

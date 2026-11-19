import 'package:material_ui/material_ui.dart';

import '../core/fold/fold.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'casama_mark.dart';

/// A page that isn't inside the app shell (sign-in, the welcome steps, the paywall), on a folding
/// phone (D-411). The shell keeps its own pages clear of the side strip and the fold; these pages
/// fill the window, so this does it for them:
///
/// - beside an iPhone Duo's side strip, the page stops where the strip starts;
/// - while a fold divides the window, the page takes the half you touch (the trailing half of a
///   device held like a book, the lower half of one propped up like a laptop) and Casama's mark
///   sits quietly on the other, so nothing you tap or read lies on the fold.
///
/// On every other window it is the page, unchanged.
class OutsideShell extends StatefulWidget {
  const OutsideShell({super.key, required this.child});
  final Widget child;

  @override
  State<OutsideShell> createState() => _OutsideShellState();
}

class _OutsideShellState extends State<OutsideShell> {
  /// The page keeps what was typed when the device is folded or opened around it.
  final _page = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final page = KeyedSubtree(key: _page, child: widget.child);
    final info = FoldInfo.of(context);
    final gap = info.gap;
    if (gap == null && !info.hasStrip) return page;
    final media = MediaQuery.of(context);
    final size = media.size;
    // Clear of the strip first.
    var where = Rect.fromLTRB(
      info.strip == StripSide.left ? info.stripWidth : 0,
      0,
      size.width - (info.strip == StripSide.right ? info.stripWidth : 0),
      size.height,
    );
    Rect? other;
    if (gap != null && info.foldVertical) {
      final before = Rect.fromLTRB(where.left, 0, gap.left, size.height);
      final after = Rect.fromLTRB(gap.right, 0, where.right, size.height);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      where = rtl ? before : after;
      other = rtl ? after : before;
    } else if (gap != null) {
      other = Rect.fromLTRB(where.left, 0, where.right, gap.top);
      where = Rect.fromLTRB(where.left, gap.bottom, where.right, size.height);
    }
    return Stack(
      children: [
        if (other != null)
          Positioned.fromRect(rect: other, child: const _MarkSide()),
        Positioned.fromRect(
          rect: where,
          child: MediaQuery(
            data: paneMedia(media, where),
            child: FoldPane(rect: where, child: page),
          ),
        ),
      ],
    );
  }
}

/// The half without the page: Casama's mark, quiet, so the half reads as part of the app.
class _MarkSide extends StatelessWidget {
  const _MarkSide();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Opacity(
        opacity: context.isDark ? 0.5 : 0.7,
        child: const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: CasamaMark(size: 84),
        ),
      ),
    ),
  );
}

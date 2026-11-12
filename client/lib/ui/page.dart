import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'shell_header.dart';

/// Widest a settings-style page grows before it centers. Rows of labels and switches stay at a
/// readable length; wide windows get more columns (see [kWidePageMaxWidth]), not longer rows.
const double kPageMaxWidth = 680;

/// Widest a browsing page (catalogs, galleries) or a two-column page grows before it centers.
const double kWidePageMaxWidth = 1240;

/// Window content width from which a page shows its sections in two columns.
const double kTwoColumnMinWidth = 1100;

/// Side padding for a list in [width]: phone gutters, centered at [maxWidth] on wide windows.
double pageSide(double width, {double maxWidth = kPageMaxWidth}) => AppSpace.gutter + AppBreakpoints.centeringInset(width, maxWidth: maxWidth);

/// A secondary screen (a Settings page, a bot's memory): the shell header over a centered column,
/// with the same width, gutters and bottom inset as Settings.
class SubPage extends StatelessWidget {
  const SubPage({super.key, required this.title, this.subtitle, this.actions = const [], this.children, this.body, this.maxWidth = kPageMaxWidth, this.bottom})
    : assert(children != null || body != null, 'give children or a body');

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Sections laid out in a centered, scrolling column.
  final List<Widget>? children;

  /// A custom body (empty and loading states fill the page); [PageColumn] centers its own lists.
  final Widget? body;
  final double maxWidth;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ShellHeader(title: title, subtitle: subtitle, actions: actions, bottom: bottom),
      body: body ?? PageColumn(maxWidth: maxWidth, children: children!),
    );
  }
}

/// A centered scrolling column of sections: gutters on phones, centered on wide windows.
class PageColumn extends StatelessWidget {
  const PageColumn({super.key, required this.children, this.maxWidth = kPageMaxWidth, this.top = AppSpace.xs});
  final List<Widget> children;
  final double maxWidth;
  final double top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: maxWidth);
        final side = AppSpace.gutter + inset;
        // The list itself is edge to edge and each section carries the side padding, so a
        // [PageBleed] section can reach the edges.
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(0, top, 0, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
          children: [
            for (var i = 0; i < children.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  left: children[i] is PageBleed ? inset : side,
                  right: children[i] is PageBleed ? inset : side,
                  // Cards placed one after another get a gap, so they never touch.
                  top: i > 0 && _isCard(children[i - 1]) && _isCard(children[i]) ? AppSpace.md : 0,
                ),
                child: children[i],
              ),
          ],
        );
      },
    );
  }
}

bool _isCard(Widget w) => w is GroupedCard || w is AppCard;

/// A section of a [PageColumn] (or [SubPage]) that reaches the page's edges instead of stopping at
/// its gutters: a horizontal list, so its items slide all the way to the edge of the screen. The
/// page skips its gutter for this child, so the list adds its own:
/// `padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter)`.
class PageBleed extends StatelessWidget {
  const PageBleed({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// A centered lazy list for long collections, with the page's width and gutters.
class PageListView extends StatelessWidget {
  const PageListView({super.key, required this.itemCount, required this.itemBuilder, this.maxWidth = kPageMaxWidth, this.header, this.physics});
  final ScrollPhysics? physics;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double maxWidth;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: maxWidth);
        final offset = header == null ? 0 : 1;
        return ListView.separated(
          physics: physics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
          itemCount: itemCount + offset,
          separatorBuilder: (_, i) => SizedBox(height: header != null && i == 0 ? AppSpace.md : AppSpace.xs),
          itemBuilder: (context, i) => header != null && i == 0 ? header! : itemBuilder(context, i - offset),
        );
      },
    );
  }
}

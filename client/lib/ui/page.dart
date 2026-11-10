import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'shell_header.dart';

/// Widest a settings-style page grows before it centers.
const double kPageMaxWidth = 680;

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
        final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: maxWidth);
        return ListView(padding: EdgeInsets.fromLTRB(side, top, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom), children: children);
      },
    );
  }
}

/// A centered lazy list for long collections, with the page's width and gutters.
class PageListView extends StatelessWidget {
  const PageListView({super.key, required this.itemCount, required this.itemBuilder, this.maxWidth = kPageMaxWidth, this.header});
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
          padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
          itemCount: itemCount + offset,
          separatorBuilder: (_, i) => SizedBox(height: header != null && i == 0 ? AppSpace.md : AppSpace.xs),
          itemBuilder: (context, i) => header != null && i == 0 ? header! : itemBuilder(context, i - offset),
        );
      },
    );
  }
}

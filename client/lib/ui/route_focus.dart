import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The item a link asked this screen to open or show, from its `?focus=` query (search links
/// there, D-235). Null outside a router (tests) or when the link names nothing.
String? routeFocus(BuildContext context) =>
    GoRouter.maybeOf(context)?.state.uri.queryParameters['focus'];

/// Calls [open] once, after the frame where [ready] first holds for [id]: a screen opens the item
/// a link named as soon as its list has loaded, and never again while it stays open.
class OpenOnce extends StatefulWidget {
  const OpenOnce({super.key, required this.id, required this.ready, required this.open, required this.child});

  final String? id;
  final bool ready;
  final void Function(String id) open;
  final Widget child;

  @override
  State<OpenOnce> createState() => _OpenOnceState();
}

class _OpenOnceState extends State<OpenOnce> {
  String? _done;

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    if (id != null && widget.ready && _done != id) {
      _done = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.open(id);
      });
    }
    return widget.child;
  }
}

/// Scrolls [child] into view and tints it for a moment: the item a link pointed at.
class FocusHighlight extends StatefulWidget {
  const FocusHighlight({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<FocusHighlight> createState() => _FocusHighlightState();
}

class _FocusHighlightState extends State<FocusHighlight> {
  var _lit = false;
  Timer? _off;

  @override
  void initState() {
    super.initState();
    if (!widget.active) return;
    _lit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(Scrollable.ensureVisible(context, alignment: 0.3, duration: AppMotion.of(context, AppMotion.duration)));
    });
    _off = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _lit = false);
    });
  }

  @override
  void dispose() {
    _off?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedContainer(
      key: const Key('focusedItem'),
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardAll,
        boxShadow: [
          if (_lit) BoxShadow(color: context.colorScheme.primary.withValues(alpha: 0.35), spreadRadius: 2),
        ],
      ),
      child: widget.child,
    );
  }
}

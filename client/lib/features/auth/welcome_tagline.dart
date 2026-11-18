import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// The line under the name on the welcome screen. It cycles through a few short taglines, sliding
/// each one up as it fades in.
///
/// It is always as tall as the longest tagline, so nothing below it moves when the text changes.
/// With reduced motion on it shows only the first one. Screen readers hear the first one once,
/// not every change.
class WelcomeTagline extends StatefulWidget {
  const WelcomeTagline({
    super.key,
    required this.taglines,
    this.style,
    this.interval = const Duration(milliseconds: 3800),
  });

  final List<String> taglines;
  final TextStyle? style;
  final Duration interval;

  @override
  State<WelcomeTagline> createState() => _WelcomeTaglineState();
}

class _WelcomeTaglineState extends State<WelcomeTagline> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(WelcomeTagline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.taglines.length) _index = 0;
    if (oldWidget.interval != widget.interval ||
        oldWidget.taglines.length != widget.taglines.length) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (widget.taglines.length < 2 || MediaQuery.disableAnimationsOf(context)) {
      _index = 0;
      return;
    }
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.taglines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Text _text(String value) =>
      Text(value, textAlign: TextAlign.center, style: widget.style);

  @override
  Widget build(BuildContext context) {
    if (widget.taglines.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: widget.taglines.first,
      child: ExcludeSemantics(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Invisible copies of every tagline, so the box is as tall as the longest one.
            for (final line in widget.taglines)
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _text(line),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                // The new line rises in from below; the old one keeps rising as it fades out.
                final entering = child.key == ValueKey(_index);
                final slide = Tween<Offset>(
                  begin: entering
                      ? const Offset(0, 0.35)
                      : const Offset(0, -0.35),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _text(widget.taglines[_index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

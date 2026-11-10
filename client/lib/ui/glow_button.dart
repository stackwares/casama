// The key is forwarded to the inner button on purpose (see below).
// ignore_for_file: use_key_in_widget_constructors, prefer_initializing_formals

import 'package:flutter/material.dart';

/// The app's main-action button: a [FilledButton] with a soft gradient, a light top edge and a
/// glow in its own color that lifts on hover and settles when pressed. Tonal, outlined and text
/// buttons stay flat, so the main action is always the one that shines.
class GlowButton extends StatelessWidget {
  // The key goes on the inner FilledButton, so finders and tests see the real button.
  const GlowButton({Key? key, required this.onPressed, required this.child, this.style, this.onLongPress, this.focusNode, this.autofocus = false})
    : _key = key,
      _icon = null;

  const GlowButton.icon({
    Key? key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.style,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
  }) : _key = key,
       _icon = icon,
       child = label;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final Widget child;
  final Widget? _icon;
  final Key? _key;
  final FocusNode? focusNode;
  final bool autofocus;

  static ButtonStyle glow(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? null : Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundBuilder: (context, states, child) {
        if (states.contains(WidgetState.disabled)) return child!;
        final base = color ?? scheme.primary;
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered) || states.contains(WidgetState.focused);
        final top = Color.lerp(base, Colors.white, dark ? 0.08 : 0.16)!;
        final bottom = Color.lerp(base, scheme.tertiary, 0.28)!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pressed ? [base, Color.lerp(bottom, Colors.black, 0.08)!] : [top, base, bottom],
            ),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: pressed ? 0.18 : (hovered ? 0.45 : 0.3)),
                blurRadius: pressed ? 6 : (hovered ? 20 : 14),
                offset: Offset(0, pressed ? 1 : (hovered ? 6 : 4)),
              ),
            ],
          ),
          // A light along the top edge, like a gloss.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.white.withValues(alpha: pressed ? 0.04 : (dark ? 0.12 : 0.2)),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom = style?.backgroundColor?.resolve(const {});
    final s = glow(context, color: custom).merge(style?.copyWith(backgroundColor: const WidgetStatePropertyAll(null)));
    return _icon == null
        ? FilledButton(key: _key, onPressed: onPressed, onLongPress: onLongPress, style: s, focusNode: focusNode, autofocus: autofocus, child: child)
        : FilledButton.icon(
            key: _key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            style: s,
            focusNode: focusNode,
            autofocus: autofocus,
            icon: _icon,
            label: child,
          );
  }
}

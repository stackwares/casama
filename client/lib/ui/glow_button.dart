// The key is forwarded to the inner button on purpose (see below).
// ignore_for_file: use_key_in_widget_constructors, prefer_initializing_formals

import 'package:flutter/material.dart';

/// The app's main-action button: a [FilledButton] in one solid color, a touch lighter at the
/// top, with a soft shadow in its own color that lifts on hover and settles when pressed. Tonal,
/// outlined and text buttons stay flat, so the main action is always the one that stands out.
///
/// Give it another color (a brand, or red for a destructive action) with [glow]'s `color`, or a
/// style with a background color; the text turns dark on light colors so it stays readable.
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
    final base = color ?? scheme.primary;
    final foreground = color == null
        ? scheme.onPrimary
        : (ThemeData.estimateBrightnessForColor(base) == Brightness.dark ? Colors.white : const Color(0xFF1B1B1F));
    return ButtonStyle(
      // Transparent so the gradient shows; disabled keeps the theme's flat disabled look.
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? null : Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? null : foreground),
      iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? null : foreground),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundBuilder: (context, states, child) {
        if (states.contains(WidgetState.disabled)) return child!;
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered) || states.contains(WidgetState.focused);
        // One hue: a little lighter at the top, a little deeper when pressed.
        final fill = pressed ? Color.lerp(base, Colors.black, 0.10)! : base;
        final top = pressed ? fill : Color.lerp(base, Colors.white, hovered ? 0.16 : 0.10)!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, fill]),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: pressed ? 0.14 : (hovered ? 0.34 : 0.24)),
                blurRadius: pressed ? 4 : (hovered ? 18 : 12),
                offset: Offset(0, pressed ? 1 : (hovered ? 6 : 4)),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // A style's background color is the button's color, except the transparent one glow() itself
    // sets (reading that as the color is what turned branded buttons a muddy grey). The style's own
    // settings win over the defaults, so a glow(context, color: brand) style keeps its brand.
    final custom = style?.backgroundColor?.resolve(const {});
    final color = custom == null || custom.a == 0 ? null : custom;
    final s = (style?.copyWith(backgroundColor: const WidgetStatePropertyAll(null)) ?? const ButtonStyle()).merge(glow(context, color: color));
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

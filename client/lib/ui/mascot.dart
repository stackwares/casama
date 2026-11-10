import 'dart:math';

import 'package:flutter/material.dart';

/// The Kasama cloud bots. Art lives in assets/mascots (rendered from assets/bots by
/// scripts/kasama-mascot-render.mjs): `<name>.webp` loops an 8 second animation, `<name>.png` is the still pose.
enum Mascot {
  winky('Winky'),
  sleepy('Sleepy'),
  starry('Starry'),
  lovey('Lovey'),
  cool('Cool'),
  thinker('Thinker'),
  giggly('Giggly'),
  shy('Shy'),
  focused('Focused'),
  wow('Wow');

  const Mascot(this.label);
  final String label;

  /// The bots that stand in for the app's own mark on front-facing screens.
  static const brand = [winky, giggly, thinker, wow];

  static const _prefix = 'mascot:';

  /// How a bot stores its icon in `avatar_url`.
  String get avatarValue => '$_prefix$name';

  String get stillAsset => 'assets/mascots/$name.png';
  String get animatedAsset => 'assets/mascots/$name.webp';

  /// The mascot a bot's `avatar_url` points at, or null for initials (or a real image URL).
  static Mascot? fromAvatar(String? avatarUrl) {
    if (avatarUrl == null || !avatarUrl.startsWith(_prefix)) return null;
    final key = avatarUrl.substring(_prefix.length);
    for (final m in values) {
      if (m.name == key) return m;
    }
    return null;
  }

  static Mascot random([Random? rng]) =>
      values[(rng ?? Random()).nextInt(values.length)];
}

/// One mascot, transparent, filling [size]. Animates unless [animate] is false or the system asks
/// for reduced motion.
class MascotImage extends StatelessWidget {
  const MascotImage(
    this.mascot, {
    super.key,
    required this.size,
    this.animate = true,
    this.semanticLabel,
  });

  final Mascot mascot;
  final double size;
  final bool animate;
  final String? semanticLabel;

  /// The art keeps a margin around the cloud for its hops and tail swings; scale it up a little so
  /// the cloud itself fills the box (the overflow is transparent).
  static const _zoom = 1.14;

  @override
  Widget build(BuildContext context) {
    final moving = animate && !MediaQuery.disableAnimationsOf(context);
    final drawn = size * _zoom;
    final px = (drawn * MediaQuery.devicePixelRatioOf(context)).round().clamp(
      16,
      192,
    );
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: drawn,
        maxHeight: drawn,
        child: Image.asset(
          moving ? mascot.animatedAsset : mascot.stillAsset,
          width: drawn,
          height: drawn,
          cacheWidth: px,
          cacheHeight: px,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        ),
      ),
    );
  }
}

/// Picks a bot's icon: its initials or one of the mascots. [value] is the bot's `avatar_url`.
class MascotPicker extends StatelessWidget {
  const MascotPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.initials,
    this.initialsLabel = 'Initials',
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  /// Shown on the initials choice.
  final String initials;
  final String initialsLabel;

  @override
  Widget build(BuildContext context) {
    final selected = Mascot.fromAvatar(value);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Choice(
          label: initialsLabel,
          selected: selected == null,
          onTap: () => onChanged(null),
          child: Text(
            initials,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final m in Mascot.values)
          _Choice(
            label: m.label,
            selected: m == selected,
            onTap: () => onChanged(m.avatarValue),
            child: MascotImage(m, size: 44, animate: m == selected),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 56, height: 56, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

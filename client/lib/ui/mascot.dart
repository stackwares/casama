import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:lottie/lottie.dart';

/// The Casama cloud bots. Art lives in assets/mascots, made from the SVGs in assets/bots:
/// `<name>.json` is the 8 second loop as Lottie (scripts/casama-mascot-lottie.py) and `<name>.png` the
/// still pose (scripts/casama-mascot-render.mjs).
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
  String get lottieAsset => 'assets/mascots/$name.json';

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

/// One mascot, transparent, filling [size]. Plays its Lottie loop at the screen's frame rate unless
/// [animate] is false or the system asks for reduced motion; the still pose shows until it loads.
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

  @override
  Widget build(BuildContext context) => _mascotArt(
    context,
    still: mascot.stillAsset,
    lottie: mascot.lottieAsset,
    size: size,
    animate: animate,
    semanticLabel: semanticLabel,
  );
}

/// The bot that isn't made yet: a pearl-white cloud that dozes, peeks at the New bot button, wakes,
/// tries on the bots' colours and beckons. Not one of the [Mascot]s and never a bot's icon; it
/// stands in on "no bots yet" screens. Same art pipeline (casama-blank*.svg in assets/bots).
class BlankBotImage extends StatelessWidget {
  const BlankBotImage({super.key, this.size = 128, this.animate = true});

  final double size;
  final bool animate;

  static const stillAsset = 'assets/mascots/blank.png';
  static const lottieAsset = 'assets/mascots/blank.json';

  @override
  Widget build(BuildContext context) => _mascotArt(
    context,
    still: stillAsset,
    lottie: lottieAsset,
    size: size,
    animate: animate,
  );
}

/// The art keeps a margin around the cloud for its hops and tail swings; scale it up a little so the
/// cloud itself fills the box (the overflow is transparent).
const _zoom = 1.14;

/// Big mascots follow the display (up to 120 fps); small ones draw at the loop's own 60 fps.
const _fullRateFrom = 64.0;

/// A mascot loop (Lottie) with its still pose standing in while it loads, when it fails, and when
/// [animate] is off or the system asks for reduced motion.
Widget _mascotArt(
  BuildContext context, {
  required String still,
  required String lottie,
  required double size,
  required bool animate,
  String? semanticLabel,
}) {
  final moving = animate && !MediaQuery.disableAnimationsOf(context);
  final drawn = size * _zoom;
  // Decoded once at the art's own 320 px and shared by every size it is drawn at, so the copy
  // decoded while the app connects (precacheStartupAssets) is the one every screen paints.
  final stillImage = Image.asset(
    still,
    width: drawn,
    height: drawn,
    gaplessPlayback: true,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
  Widget art;
  if (moving) {
    final loop = Lottie.asset(
      lottie,
      width: drawn,
      height: drawn,
      frameRate: size >= _fullRateFrom ? FrameRate.max : FrameRate.composition,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, composition) =>
          composition == null ? stillImage : child,
      errorBuilder: (context, error, stack) => stillImage,
    );
    // A playing loop repaints on each of its frames: on its own layer, it doesn't repaint the
    // screen around it.
    art = RepaintBoundary(child: ExcludeSemantics(child: loop));
  } else {
    art = stillImage;
  }
  if (semanticLabel != null) {
    art = Semantics(label: semanticLabel, image: true, child: art);
  }
  return SizedBox(
    width: size,
    height: size,
    child: OverflowBox(maxWidth: drawn, maxHeight: drawn, child: art),
  );
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

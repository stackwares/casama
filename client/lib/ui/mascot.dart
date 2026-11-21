import 'dart:math';
import 'dart:typed_data';

import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'ambient_motion.dart';
import 'bot_avatar.dart';
import 'edge_fade.dart';
import 'reveal_when_selected.dart';

/// The Casama cloud bots. Art lives in assets/mascots, made from the SVGs in assets/bots:
/// `<name>.json` is the 8 second loop as Lottie (scripts/casama-mascot-lottie.py) and `<name>.png` the
/// still pose (scripts/casama-mascot-render.mjs).
enum Mascot {
  winky('Winky', [Color(0xFF7A90FF), Color(0xFF7DE9F4)]),
  sleepy('Sleepy', [Color(0xFF7C83F2), Color(0xFFA59CF6)]),
  starry('Starry', [Color(0xFFFF9F43), Color(0xFFFFC94D)]),
  lovey('Lovey', [Color(0xFFFF6FAE), Color(0xFFFF9CC9)]),
  cool('Cool', [Color(0xFF14B8A6), Color(0xFF4FD1C5)]),
  thinker('Thinker', [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
  giggly('Giggly', [Color(0xFF22C55E), Color(0xFF4ADE80)]),
  shy('Shy', [Color(0xFFFB7185), Color(0xFFFDA4AF)]),
  focused('Focused', [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
  wow('Wow', [Color(0xFF8B5CF6), Color(0xFFA78BFA)]);

  const Mascot(this.label, this.colors);
  final String label;

  /// The mascot's own colors (its tail, from PAL in scripts/casama-cloud-svg.py), for anything drawn in
  /// the bot's color.
  final List<Color> colors;

  /// The bots that stand in for the app's own mark on front-facing screens.
  static const brand = [winky, giggly, thinker, wow];

  static const _prefix = 'mascot:';

  /// How a bot stores its icon in `avatar_url`.
  String get avatarValue => '$_prefix$name';

  String get stillAsset => 'assets/mascots/$name.webp';
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
    colors: mascot.colors,
  );
}

/// The bot that isn't made yet: a pearl-white cloud that dozes, peeks at the New bot button, wakes,
/// tries on the bots' colours and beckons. Not one of the [Mascot]s and never a bot's icon; it
/// stands in on "no bots yet" screens. Same art pipeline (casama-blank*.svg in assets/bots).
class BlankBotImage extends StatelessWidget {
  const BlankBotImage({super.key, this.size = 128, this.animate = true});

  final double size;
  final bool animate;

  static const stillAsset = 'assets/mascots/blank.webp';
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

/// A sheet's hero made of cloud bots, where a painted picture would be (`FormSheet.hero`): one bot
/// [size] across, or two or three side by side with the middle one in front and the others a size
/// smaller behind it ("a group", "people together"). They play their loops while looping motion is
/// on ([ambientMotionOn]).
class MascotHero extends StatelessWidget {
  const MascotHero(this.mascots, {super.key, this.size = 104});

  /// One to three different bots; any past three are left out.
  final List<Mascot> mascots;
  final double size;

  @override
  Widget build(BuildContext context) {
    final animate = ambientMotionOn(context);
    final mascots = this.mascots.toSet().take(3).toList();
    if (mascots.isEmpty) return SizedBox.square(dimension: size);
    final front = mascots.length == 2 ? mascots[0] : mascots[mascots.length ~/ 2];
    if (mascots.length == 1) {
      return ExcludeSemantics(child: MascotImage(front, size: size, animate: animate));
    }
    final side = size * 0.74;
    final behind = [
      for (final m in mascots)
        if (m != front) m,
    ];
    return ExcludeSemantics(
      child: SizedBox(
        width: size + side * (behind.length == 2 ? 1.2 : 0.75),
        height: size,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: behind.length == 2 ? Alignment.bottomLeft : Alignment.bottomRight,
              child: MascotImage(behind[0], size: side, animate: animate),
            ),
            if (behind.length == 2)
              Align(
                alignment: Alignment.bottomRight,
                child: MascotImage(behind[1], size: side, animate: animate),
              ),
            Align(
              alignment: behind.length == 2 ? Alignment.bottomCenter : Alignment.bottomLeft,
              child: MascotImage(front, size: size, animate: animate),
            ),
          ],
        ),
      ),
    );
  }
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
  List<Color>? colors,
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
    errorBuilder: (context, error, stack) {
      final tint = colors?.first ?? Theme.of(context).colorScheme.primary;
      return SizedBox.square(
        dimension: drawn,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors ?? [tint.withValues(alpha: 0.24), tint.withValues(alpha: 0.08)],
              ),
            ),
            child: SizedBox.square(dimension: drawn * 0.68),
          ),
        ),
      );
    },
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

/// Picks a bot's icon: its own picture, its initials or one of the mascots. [value] is the bot's
/// `avatar_url`.
class MascotPicker extends StatelessWidget {
  const MascotPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.initials,
    this.initialsLabel = 'Initials',
    this.scrollable = false,
    this.onPicture,
    this.pictureLabel = 'Picture',
    this.picture,
    this.picturePreview,
    this.pictureSelected,
    this.name = '',
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  /// Opens the picture choices (take, choose, draw, re-crop, remove). Unset: no Picture tile.
  final VoidCallback? onPicture;
  final String pictureLabel;

  /// The bot's saved picture (`image:<id>:<colours>`), shown on the Picture tile even while a
  /// mascot is picked, so it's one tap to go back to it.
  final String? picture;

  /// A picture cropped but not saved yet (a bot being made).
  final Uint8List? picturePreview;

  /// Whether the picture is the choice; defaults to [value] naming a picture.
  final bool? pictureSelected;

  /// The bot's name, for the picture tile's placeholder.
  final String name;

  /// Shown on the initials choice.
  final String initials;
  final String initialsLabel;

  /// One row that scrolls sideways (a compact form) instead of wrapping onto more lines.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final selected = Mascot.fromAvatar(value);
    final onPicture = this.onPicture;
    final shownPicture = BotPictureRef.parse(value) != null ? value : picture;
    final hasPicture = picturePreview != null || shownPicture != null;
    final pictureOn = onPicture != null && (pictureSelected ?? BotPictureRef.parse(value) != null);
    final choices = [
        if (onPicture != null)
          _Choice(
            key: const Key('mascotPicker-picture'),
            label: pictureLabel,
            selected: pictureOn,
            // A picture that isn't the choice right now: the first tap picks it again; the next
            // opens its choices. No picture yet: straight to the choices.
            onTap: hasPicture && !pictureOn && picturePreview == null && shownPicture != null
                ? () => onChanged(shownPicture)
                : onPicture,
            child: hasPicture
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      BotAvatar(name: name, avatar: shownPicture, preview: picturePreview, size: 40),
                      if (pictureOn)
                        PositionedDirectional(
                          end: -6,
                          bottom: -6,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 2),
                            ),
                            child: Icon(LucideIcons.pencil, size: 10, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                    ],
                  )
                : Icon(LucideIcons.imagePlus, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        _Choice(
          label: initialsLabel,
          selected: selected == null && !pictureOn,
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
    ];
    if (!scrollable) {
      return Wrap(spacing: 8, runSpacing: 8, children: choices);
    }
    return SizedBox(
      height: 60,
      child: EdgeFade(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final c in choices)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: RevealWhenSelected(
                  selected: c.selected,
                  child: Center(child: c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
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

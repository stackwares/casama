import 'dart:math' as math;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../core/media_cache.dart';
import '../theme/app_tokens.dart';
import 'ambient_motion.dart';
import 'mascot.dart';

/// Painted pictures bundled with the app (visuals/round-10), in `assets/art/<name>.webp`.
///
/// The names group by where they show: `library-*` (the empty Library's starters), `cat-*` (gallery
/// and bot-template categories), `wait-*` (the waitlist and invite-code sheets), `tasks-*` (the
/// empty board), `computer-*`, `project-*` (covers a project can pick), `plan-*` (paywall plans),
/// plus `invite` and `whatsnew`. Anything not listed here falls back to a drawn tile, so a missing
/// name never breaks a screen.
const paintedArt = {
  'library-game',
  'library-logo',
  'library-site',
  'library-video',
  'library-card',
  'library-report',
  'cat-work',
  'cat-research',
  'cat-build',
  'cat-create',
  'cat-life',
  'cat-writing',
  'cat-data',
  'cat-money',
  'wait-ticket',
  'wait-gift',
  'wait-hourglass',
  'wait-envelope',
  'invite',
  'whatsnew',
  'tasks-ticket',
  'tasks-project',
  'computer-empty',
  'computer-waking',
  'project-sailboat',
  'project-mountain',
  'project-seedling',
  'project-compass',
  'project-lantern',
  'project-telescope',
  'project-map',
  'project-chess',
  'plan-plus',
  'plan-pro',
  'plan-max',
};

/// The bundled asset for [name], or null when the app has no such picture.
String? paintedAsset(String? name) =>
    name != null && paintedArt.contains(name) ? 'assets/art/$name.webp' : null;

/// The painted picture for a gallery or template category (work, research, build, create, life,
/// writing, data, money), or null for any other.
String? categoryArt(String? category) => paintedAsset('cat-$category');

/// A seed's fallback gradient: one bot's two colors, the same bot for the same seed every time.
List<Color> paintedFallbackColors(String seed) {
  final n = seed.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff);
  return Mascot.values[n % Mascot.values.length].colors;
}

/// A painted picture that fills the box it's given (cropped to cover it): a bundled [asset] first,
/// then a [url] (a gallery item's cover), and when neither is there or one fails to load, a
/// gradient in [paintedFallbackColors] of [seed] with [icon] in the middle.
class PaintedArt extends StatelessWidget {
  const PaintedArt({
    super.key,
    required this.seed,
    this.asset,
    this.url,
    this.icon,
    this.iconScale = 0.42,
    this.alignment = Alignment.center,
    this.decodeWidth,
  });

  final String seed;
  final String? asset;
  final String? url;

  /// Drawn on the fallback tile only; null leaves the gradient plain.
  final IconData? icon;
  final double iconScale;
  final Alignment alignment;

  /// Decode at this many pixels wide instead of the box's own size (a blurred wash needs few).
  final int? decodeWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.max(
          box.hasBoundedWidth ? box.maxWidth : 0.0,
          box.hasBoundedHeight ? box.maxHeight : 0.0,
        );
        final decode =
            decodeWidth ??
            math.max(
              96,
              (side * MediaQuery.devicePixelRatioOf(context)).round(),
            );
        Widget fallback() => _Fallback(
          seed: seed,
          icon: icon,
          iconSize:
              math.min(
                box.hasBoundedWidth ? box.maxWidth : side,
                box.hasBoundedHeight ? box.maxHeight : side,
              ) *
              iconScale,
        );
        Widget fade(
          BuildContext context,
          Widget child,
          int? frame,
          bool sync,
        ) => sync
            ? child
            : AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppMotion.of(context, AppMotion.fast),
                child: child,
              );
        Widget network(String u) => Image(
          image: ResizeImage.resizeIfNeeded(
            decode,
            null,
            cachedNetworkImage(u),
          ),
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          frameBuilder: fade,
          errorBuilder: (_, _, _) => fallback(),
        );
        final Widget image;
        if (asset case final String a) {
          image = Image.asset(
            a,
            fit: BoxFit.cover,
            alignment: alignment,
            cacheWidth: decode,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            frameBuilder: fade,
            errorBuilder: (_, _, _) => url != null ? network(url!) : fallback(),
          );
        } else if (url case final String u) {
          image = network(u);
        } else {
          return SizedBox.expand(child: fallback());
        }
        return SizedBox.expand(
          child: ColoredBox(
            color: paintedFallbackColors(seed).first.withValues(alpha: 0.35),
            child: image,
          ),
        );
      },
    );
  }
}

/// [PaintedArt] cropped to a rounded square of [size].
class PaintedCover extends StatelessWidget {
  const PaintedCover({
    super.key,
    required this.size,
    required this.seed,
    this.asset,
    this.url,
    this.icon,
    this.radius,
  });

  final double size;
  final String seed;
  final String? asset;
  final String? url;
  final IconData? icon;

  /// Corner radius; defaults to about a quarter of [size], like an app icon.
  final double? radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius ?? size * 0.26),
    child: SizedBox.square(
      dimension: size,
      child: PaintedArt(seed: seed, asset: asset, url: url, icon: icon),
    ),
  );
}

/// A sheet's or card's hero: a painted picture in a soft rounded square with a gentle shadow,
/// [size] across. Used where a screen had a single large icon. With [float] it bobs softly (a few
/// pixels and a hair of tilt, a 4 s loop), still under Reduce Motion and when off screen.
class PaintedHero extends StatefulWidget {
  const PaintedHero({
    super.key,
    required this.name,
    this.size = 112,
    this.icon = LucideIcons.sparkles,
    this.float = false,
  });

  /// A [paintedArt] name.
  final String name;
  final double size;

  /// Drawn on the fallback tile if the picture is missing.
  final IconData icon;
  final bool float;

  static const floatPeriod = Duration(seconds: 4);

  @override
  State<PaintedHero> createState() => _PaintedHeroState();
}

class _PaintedHeroState extends State<PaintedHero>
    with SingleTickerProviderStateMixin {
  AnimationController? _float;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.float && ambientMotionOn(context);
    if (on && _float == null) {
      _float = AnimationController(
        vsync: this,
        duration: PaintedHero.floatPeriod,
      )..repeat();
    } else if (!on && _float != null) {
      _float!.dispose();
      _float = null;
    }
  }

  @override
  void dispose() {
    _float?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final hero = ExcludeSemantics(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.35 : 0.14,
                ),
                blurRadius: size * 0.22,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: PaintedCover(
            size: size,
            radius: size * 0.28,
            seed: widget.name,
            asset: paintedAsset(widget.name),
            icon: widget.icon,
          ),
        ),
      ),
    );
    final float = _float;
    if (float == null) return hero;
    return AnimatedBuilder(
      animation: float,
      child: hero,
      builder: (context, child) {
        final t = float.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * 4),
          child: Transform.rotate(
            angle: math.sin(t + 1.1) * 0.014,
            child: child,
          ),
        );
      },
    );
  }
}

/// A cover settling in as it appears: it fades in from a touch larger (1.04 to 1, 350 ms, ease
/// out). Pickers put it inside their own cross-fade, so a new pick replaces the old one smoothly.
/// Instant under Reduce Motion; it plays once, so it never keeps a list busy.
class CoverSettleIn extends StatelessWidget {
  const CoverSettleIn({super.key, required this.child});
  final Widget child;

  static const duration = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.of(context, duration),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.scale(scale: 1.04 - 0.04 * t, child: child),
    ),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.seed,
    required this.icon,
    required this.iconSize,
  });
  final String seed;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: paintedFallbackColors(seed),
      ),
    ),
    child: icon == null
        ? const SizedBox.expand()
        : Center(
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
  );
}

extension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// A section heading led by its category's painting: a small rounded cover, the title and a count.
/// Falls back to a drawn tile with [icon] when the category has no picture.
class PaintedSectionHeader extends StatelessWidget {
  const PaintedSectionHeader({
    super.key,
    required this.category,
    required this.title,
    this.count,
    this.icon,
  });

  final String category;
  final String title;
  final String? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxs,
        AppSpace.lg,
        AppSpace.xxs,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: PaintedCover(
              size: 40,
              radius: 11,
              seed: 'cat-$category',
              asset: categoryArt(category),
              icon: icon,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  text: title,
                  children: [
                    if (count != null)
                      TextSpan(
                        text: '  $count',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A category's painting as a small round chip avatar, or null when it has none.
Widget? paintedChipAvatar(String? category) {
  final asset = categoryArt(category);
  if (asset == null) return null;
  return ClipOval(
    child: SizedBox.square(
      dimension: 22,
      child: PaintedArt(seed: 'cat-$category', asset: asset),
    ),
  );
}

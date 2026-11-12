import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'motion.dart';
import 'page.dart';

/// The theme's own placeholder colors: bones are the surface with a breath of the accent, and
/// the shimmer is a lighter wash of the same tone, so loading looks like the theme (neutral on
/// Plain, orchid on Casama) instead of grey with a white flash.
({Color bone, Color highlight}) skeletonColors(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final dark = context.isDark;
  final bone = Color.alphaBlend(
    scheme.primary.withValues(alpha: dark ? 0.08 : 0.07),
    scheme.surfaceContainerHigh,
  );
  final highlight = Color.alphaBlend(
    scheme.primary.withValues(alpha: dark ? 0.10 : 0.05),
    Color.lerp(bone, dark ? scheme.onSurface : Colors.white, dark ? 0.10 : 0.65)!,
  );
  return (bone: bone, highlight: highlight);
}

/// A block in the shape of something that is still loading, in the theme's placeholder tone.
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: skeletonColors(context).bone,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// One shimmer across a group of bones. Reduce motion shows the bones still.
class SkeletonScope extends StatelessWidget {
  const SkeletonScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highlight = skeletonColors(context).highlight;
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Shimmer(color: highlight, child: child),
    );
  }
}

/// A bone that takes a share of the width it is given, so a placeholder line reads like text at
/// any screen size instead of a short stub.
class _Line extends StatelessWidget {
  const _Line(this.widthFactor, {this.height = 12, this.center = false});

  final double widthFactor;
  final double height;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: center ? Alignment.center : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: SkeletonBone(height: height),
      ),
    );
  }
}

/// The page column a skeleton stands in for: centered, no wider than the page it will become.
class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
        child: child,
      ),
    );
  }
}

/// Rows of an avatar and two lines, for a list that has not arrived yet.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  // Varied line lengths, so the rows read as different items rather than one stamped row.
  static const _titles = [0.58, 0.42, 0.66, 0.5, 0.62, 0.38];
  static const _subtitles = [0.86, 0.7, 0.78, 0.92, 0.64, 0.8];

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              const SkeletonBone(width: 44, height: 44, radius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Line(_titles[i % _titles.length], height: 14),
                    const SizedBox(height: 10),
                    _Line(_subtitles[i % _subtitles.length], height: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
    // A caller that passes its own padding is placing the rows inside something (a card, a
    // sheet) that already has its width; the default is a whole page, so it takes the page column.
    if (padding != null) {
      return SkeletonScope(child: Padding(padding: padding!, child: rows));
    }
    return SkeletonScope(
      child: _PageWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            0,
          ),
          child: rows,
        ),
      ),
    );
  }
}

/// An avatar, a title, a few lines and a card, for a page that is one thing.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonScope(
      child: _PageWidth(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xxl,
            AppSpace.gutter,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBone(width: 88, height: 88, radius: 44),
              SizedBox(height: AppSpace.lg),
              _Line(0.5, height: 20, center: true),
              SizedBox(height: AppSpace.sm),
              _Line(0.34, height: 12, center: true),
              SizedBox(height: AppSpace.xxl),
              _Line(1, height: 12),
              SizedBox(height: 10),
              _Line(0.92, height: 12),
              SizedBox(height: 10),
              _Line(0.64, height: 12),
              SizedBox(height: AppSpace.xl),
              SkeletonBone(height: 140, radius: AppRadius.card),
              SizedBox(height: AppSpace.md),
              SkeletonBone(height: 72, radius: AppRadius.card),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat bubbles of mixed widths, for a thread that is still opening.
class SkeletonMessages extends StatelessWidget {
  const SkeletonMessages({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bubble(double widthFactor, double height, {required bool end}) =>
        Align(
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: SkeletonBone(height: height, radius: AppRadius.card),
          ),
        );
    return SkeletonScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bubble(0.72, 56, end: false),
          const SizedBox(height: AppSpace.sm),
          bubble(0.46, 40, end: true),
          const SizedBox(height: AppSpace.sm),
          bubble(0.84, 72, end: false),
        ],
      ),
    );
  }
}

/// A grid of tiles, for a catalog or a photo picker that is still loading.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.count = 6,
    this.columns = 2,
    this.tileHeight = 100,
  });

  final int count;
  final int columns;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpace.sm,
          crossAxisSpacing: AppSpace.sm,
          mainAxisExtent: tileHeight,
        ),
        itemCount: count,
        itemBuilder: (_, _) =>
            const SkeletonBone(height: double.infinity, radius: AppRadius.card),
      ),
    );
  }
}

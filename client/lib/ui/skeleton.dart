import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'motion.dart';

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

/// Rows of an avatar and two lines, for a list that has not arrived yet.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.md,
              AppSpace.gutter,
              0,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              const Row(
                children: [
                  SkeletonBone(width: 46, height: 46, radius: 23),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: 148, height: 14),
                        SizedBox(height: 8),
                        SkeletonBone(width: 96, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A title, a few lines and a card, for a page that is one thing.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonScope(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xl,
          AppSpace.gutter,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: SkeletonBone(width: 72, height: 72, radius: 36)),
            SizedBox(height: AppSpace.lg),
            SkeletonBone(width: 180, height: 18),
            SizedBox(height: AppSpace.md),
            SkeletonBone(height: 12),
            SizedBox(height: 8),
            SkeletonBone(width: 240, height: 12),
            SizedBox(height: 8),
            SkeletonBone(width: 160, height: 12),
            SizedBox(height: AppSpace.lg),
            SkeletonBone(height: 120, radius: AppRadius.card),
          ],
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

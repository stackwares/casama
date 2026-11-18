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
    scheme.primary.withValues(alpha: dark ? 0.06 : 0.03),
    Color.lerp(bone, dark ? scheme.onSurface : Colors.white, dark ? 0.05 : 0.35)!,
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
      child: Shimmer(color: highlight, duration: const Duration(milliseconds: 2200), child: child),
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

// ---------------------------------------------------------------------------------------------
// Building blocks for skeletons that match the screen they stand in for. A screen composes these
// in the same order, widths and paddings as its real layout, so nothing jumps when data arrives.
// ---------------------------------------------------------------------------------------------

/// One line of text that hasn't arrived: exactly as tall as a line in [style] (an invisible line
/// of the real style sets the height), with a bone about as tall as its letters.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.style,
    this.widthFactor = 0.6,
    this.width,
    this.center = false,
    this.lines = 1,
  });

  /// The real text's style; null is the body text.
  final TextStyle? style;

  /// Share of the available width, unless [width] is given.
  final double widthFactor;
  final double? width;
  final bool center;

  /// Lines of a paragraph; the last one runs shorter.
  final int lines;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.bodyMedium!;
    Widget line(double factor) {
      final bone = LayoutBuilder(
        builder: (context, c) => SkeletonBone(
          height: (s.fontSize ?? 14) * 0.72,
          radius: 4,
          width: width ?? (c.maxWidth.isFinite ? c.maxWidth * factor : 120),
        ),
      );
      return Stack(
        alignment: center ? Alignment.center : AlignmentDirectional.centerStart,
        children: [
          ExcludeSemantics(
            child: Text(
              ' ',
              style: s.copyWith(color: Colors.transparent),
              maxLines: 1,
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: center
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
              child: bone,
            ),
          ),
        ],
      );
    }

    if (lines <= 1) return SizedBox(width: double.infinity, child: line(widthFactor));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines; i++)
          line(i == lines - 1 ? widthFactor * 0.7 : 0.94 - (i % 2) * 0.06),
      ],
    );
  }
}

/// A page of skeleton sections with [PageColumn]'s width, gutters and top inset, under one
/// shimmer. It doesn't scroll; what runs past the bottom is clipped.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({
    super.key,
    required this.children,
    this.maxWidth = kPageMaxWidth,
    this.top = AppSpace.xs,
  });

  final List<Widget> children;
  final double maxWidth;
  final double top;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side =
              AppSpace.gutter +
              AppBreakpoints.centeringInset(
                constraints.maxWidth,
                maxWidth: maxWidth,
              );
          return ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(side, top, side, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    // Cards one after another get PageColumn's gap.
                    if (i > 0 &&
                        _isSkeletonCard(children[i - 1]) &&
                        _isSkeletonCard(children[i]))
                      const SizedBox(height: AppSpace.md),
                    children[i],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

bool _isSkeletonCard(Widget w) => w is SkeletonGroupedCard || w is SkeletonCard;

/// A [SectionHeader] still loading: same padding and line height.
class SkeletonSectionHeader extends StatelessWidget {
  const SkeletonSectionHeader({
    super.key,
    this.width = 96,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.xxs,
      AppSpace.lg,
      AppSpace.xxs,
      AppSpace.xs,
    ),
  });

  final double width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );
    return Padding(
      padding: padding,
      child: SkeletonText(style: style, width: width),
    );
  }
}

/// What sits at a skeleton row's leading edge.
enum SkeletonLeading {
  /// [GroupedTile]'s 32-point tinted icon tile.
  icon,

  /// A round avatar.
  avatar,

  /// A rounded-square logo or thumbnail.
  square,

  none,
}

/// What sits at a skeleton row's trailing edge.
enum SkeletonTrailing { none, chevron, toggle, button, meta }

/// One row in a list: a leading mark, a title and an optional subtitle, and a trailing control.
/// Defaults match [GroupedTile].
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({
    super.key,
    this.leading = SkeletonLeading.icon,
    this.leadingSize,
    this.trailing = SkeletonTrailing.chevron,
    this.subtitle = true,
    this.subtitleLines = 1,
    this.titleStyle,
    this.subtitleStyle,
    this.titleWidth = 0.5,
    this.subtitleWidth = 0.78,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: 12,
    ),
    this.gap = AppSpace.sm,
  });

  final SkeletonLeading leading;
  final double? leadingSize;
  final SkeletonTrailing trailing;
  final bool subtitle;
  final int subtitleLines;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double titleWidth;
  final double subtitleWidth;
  final EdgeInsetsGeometry padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final size =
        leadingSize ?? (leading == SkeletonLeading.icon ? 32.0 : 40.0);
    final lead = switch (leading) {
      SkeletonLeading.icon => SkeletonBone(
        width: size,
        height: size,
        radius: AppRadius.icon,
      ),
      SkeletonLeading.avatar => SkeletonBone(
        width: size,
        height: size,
        radius: size / 2,
      ),
      SkeletonLeading.square => SkeletonBone(
        width: size,
        height: size,
        radius: size * 0.28,
      ),
      SkeletonLeading.none => null,
    };
    final trail = switch (trailing) {
      SkeletonTrailing.chevron => const SizedBox(
        width: 24,
        height: 24,
        child: Center(child: SkeletonBone(width: 8, height: 12, radius: 3)),
      ),
      SkeletonTrailing.toggle => const SkeletonBone(
        width: 52,
        height: 32,
        radius: AppRadius.pill,
      ),
      SkeletonTrailing.button => const SkeletonBone(
        width: 72,
        height: 32,
        radius: AppRadius.pill,
      ),
      SkeletonTrailing.meta => const SkeletonBone(width: 36, height: 10),
      SkeletonTrailing.none => null,
    };
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (lead != null) ...[lead, SizedBox(width: gap)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonText(
                  style:
                      titleStyle ??
                      text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  widthFactor: titleWidth,
                ),
                if (subtitle)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SkeletonText(
                      style:
                          subtitleStyle ?? text.bodySmall?.copyWith(height: 1.3),
                      widthFactor: subtitleWidth,
                      lines: subtitleLines,
                    ),
                  ),
              ],
            ),
          ),
          if (trail != null) ...[const SizedBox(width: AppSpace.xs), trail],
        ],
      ),
    );
  }
}

/// A [GroupedCard] still loading: the same card with [rows] (default: [GroupedTile]-shaped rows)
/// and its inset dividers.
class SkeletonGroupedCard extends StatelessWidget {
  const SkeletonGroupedCard({
    super.key,
    this.count = 3,
    this.rows,
    this.row = const SkeletonRow(),
    this.dividerIndent = 60,
  });

  /// Rows when [rows] isn't given, each a copy of [row] with varied line lengths.
  final int count;
  final SkeletonRow row;
  final List<Widget>? rows;
  final double dividerIndent;

  static const _titles = [0.46, 0.34, 0.58, 0.4, 0.52, 0.3];
  static const _subtitles = [0.72, 0.6, 0.84, 0.66, 0.78, 0.56];

  @override
  Widget build(BuildContext context) {
    final items =
        rows ??
        [
          for (var i = 0; i < count; i++)
            SkeletonRow(
              leading: row.leading,
              leadingSize: row.leadingSize,
              trailing: row.trailing,
              subtitle: row.subtitle,
              subtitleLines: row.subtitleLines,
              titleStyle: row.titleStyle,
              subtitleStyle: row.subtitleStyle,
              titleWidth: _titles[i % _titles.length],
              subtitleWidth: _subtitles[i % _subtitles.length],
              padding: row.padding,
              gap: row.gap,
            ),
        ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(indent: dividerIndent),
            items[i],
          ],
        ],
      ),
    );
  }
}

/// An [AppCard] still loading: the card's own surface, border and radius around skeleton content,
/// or a fixed [height] of empty card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.child,
    this.height,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.radius = AppRadius.card,
  });

  final Widget? child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        color: context.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: context.appColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

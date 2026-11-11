import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backend.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/fonts.dart';
import '../../theme/presets.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/edge_fade.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../skills/skill_visuals.dart';
import 'colors_panel.dart' show SchemeDots;
import 'gallery_looks.dart';
import 'gallery_previews.dart';

export 'gallery_previews.dart' show galleryHost;

/// The Gallery page: themes, color schemes, wallpapers and skills from the open gallery (D-184).
/// Skills and links into the gallery open it; looks also show beside the built-in ones in
/// Appearance and Customize (D-203).
/// Every look is drawn as a small Casama chat in its own colors, so people choose by seeing.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
    this.initialType,
    this.openType,
    this.openId,
  });

  /// `theme`, `scheme`, `wallpaper` or `skill`. Null shows everything.
  final String? initialType;
  final String? openType;
  final String? openId;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

const _types = ['theme', 'scheme', 'wallpaper', 'skill'];
const _gap = AppSpace.sm;

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
  'theme' => l10n.galleryThemes,
  'scheme' => l10n.gallerySchemes,
  'wallpaper' => l10n.galleryWallpapers,
  _ => l10n.gallerySkills,
};

String _typeName(AppLocalizations l10n, String type) => switch (type) {
  'theme' => l10n.galleryTypeTheme,
  'scheme' => l10n.galleryTypeScheme,
  'wallpaper' => l10n.galleryTypeWallpaper,
  _ => l10n.galleryTypeSkill,
};

/// Columns for a content [width]: cards keep a useful size, phones get two looks or three
/// wallpapers a row, wide windows more.
int _columns(String type, double width) {
  final (min, lo, hi) = switch (type) {
    'wallpaper' => (150.0, 3, 7),
    'skill' => (340.0, 1, 3),
    _ => (230.0, 2, 5),
  };
  return ((width + _gap) / (min + _gap)).floor().clamp(lo, hi);
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _search = TextEditingController();
  late String? _type = _types.contains(widget.initialType)
      ? widget.initialType
      : null;
  late Future<GalleryPage> _page = _load();

  /// The brightness previews are drawn in; null follows the app.
  Brightness? _brightness;
  var _opened = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Items that need something this app can't draw (a newer gallery feature) stay hidden.
  Future<GalleryPage> _load() async {
    final page = await ref.read(backendProvider).gallery();
    return GalleryPage(
      available: page.available,
      items: [for (final item in page.items) if (item.supported) item],
    );
  }

  void _retry() {
    final page = _load();
    setState(() {
      _page = page;
    });
  }

  void _showType(String? type) {
    setState(() {
      _type = type;
    });
  }

  List<GalleryItem> _filter(List<GalleryItem> all) {
    final q = _search.text.trim().toLowerCase();
    final found = [
      for (final item in all)
        if (q.isEmpty ||
            [
              item.name,
              item.authorName,
              item.id,
              item.description ?? '',
              item.category ?? '',
              ...item.tags,
            ].any((s) => s.toLowerCase().contains(q)))
          item,
    ];
    // Featured first, then by name, so the best of each kind leads its row.
    found.sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = _brightness ?? Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    return SubPage(
      title: l10n.gallery,
      maxWidth: kWidePageMaxWidth,
      actions: [
        HeaderIconButton(
          key: const Key('galleryBrightness'),
          icon: dark ? LucideIcons.sun : LucideIcons.moon,
          tooltip: dark ? l10n.galleryPreviewLight : l10n.galleryPreviewDark,
          onPressed: () => setState(() {
            _brightness = dark ? Brightness.light : Brightness.dark;
          }),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = pageSide(
            constraints.maxWidth,
            maxWidth: kWidePageMaxWidth,
          );
          final width = constraints.maxWidth - side * 2;
          return FutureBuilder<GalleryPage>(
            future: _page,
            builder: (context, snap) {
              final loading = snap.connectionState != ConnectionState.done;
              final failed =
                  !loading && (snap.hasError || snap.data?.available == false);
              final all = loading || failed
                  ? const <GalleryItem>[]
                  : snap.data!.items;
              if (!loading && !failed) _openLinked(context, all, brightness);
              final matches = _filter(all);
              Widget padded(Widget child) => Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: child,
              );
              final content = loading
                  ? _skeleton(width, side)
                  : failed
                  ? [
                      padded(
                        EmptyState(
                          icon: LucideIcons.cloudOff,
                          title: l10n.galleryOfflineTitle,
                          message: l10n.galleryOffline,
                          action: OutlinedButton.icon(
                            key: const Key('galleryRetry'),
                            onPressed: _retry,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            label: Text(l10n.retry),
                          ),
                        ),
                      ),
                    ]
                  : matches
                        .where((i) => _type == null || i.type == _type)
                        .isEmpty
                  ? [
                      padded(
                        EmptyState(
                          icon: LucideIcons.searchX,
                          message: _search.text.trim().isEmpty
                              ? l10n.galleryEmpty
                              : l10n.galleryNoMatches(_search.text.trim()),
                          action: _search.text.trim().isEmpty
                              ? null
                              : TextButton(
                                  onPressed: _search.clear,
                                  child: Text(l10n.galleryClearSearch),
                                ),
                        ),
                      ),
                    ]
                  : _type == null
                  ? _overview(context, matches, width, side, brightness)
                  : [
                      padded(
                        _grid(
                          context,
                          matches.where((i) => i.type == _type).toList(),
                          width,
                          brightness,
                        ),
                      ),
                    ];
              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  top: AppSpace.xs,
                  bottom: AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  padded(
                    TextField(
                      key: const Key('gallerySearch'),
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: searchFieldDecoration(context, l10n.search)
                          .copyWith(
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.galleryClearSearch,
                                    onPressed: _search.clear,
                                    icon: const Icon(LucideIcons.x, size: 18),
                                  ),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _typeChips(context, loading || failed ? null : matches, side),
                  const SizedBox(height: AppSpace.xs),
                  ...content,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _typeChips(
    BuildContext context,
    List<GalleryItem>? matches,
    double side,
  ) {
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    return EdgeFade(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Row(
        children: [
          for (final type in [null, ..._types]) ...[
            if (type != null) const SizedBox(width: AppSpace.xs),
            RevealWhenSelected(
              selected: _type == type,
              child: ChoiceChip(
                key: Key('galleryType-${type ?? 'all'}'),
                showCheckmark: false,
                selected: _type == type,
                onSelected: (_) => _showType(type),
                label: Text.rich(
                  TextSpan(
                    text: type == null ? l10n.galleryAll : _typeLabel(l10n, type),
                    children: [
                      if (matches != null)
                        TextSpan(
                          text:
                              '  ${type == null ? matches.length : matches.where((i) => i.type == type).length}',
                          style: TextStyle(
                            color: muted,
                            fontFeatures: AppText.tabular,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ));
  }

  /// Everything at once: the featured looks, then one row of each kind with "See all".
  List<Widget> _overview(
    BuildContext context,
    List<GalleryItem> matches,
    double width,
    double side,
    Brightness brightness,
  ) {
    final l10n = context.l10n;
    final compact = width < 600;
    final searching = _search.text.trim().isNotEmpty;
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: child,
    );
    final out = <Widget>[];
    if (!searching) {
      // One of each kind in turn, so the row shows the range rather than repeating the rows
      // below it.
      final byType = [
        for (final type in const ['theme', 'wallpaper', 'scheme'])
          matches.where((i) => i.type == type && i.featured).toList(),
      ];
      final featured = <GalleryItem>[
        for (var i = 0; i < 6; i++)
          for (final list in byType)
            if (i < list.length) list[i],
      ].take(6).toList();
      if (featured.isNotEmpty) {
        out.add(padded(SectionHeader(title: l10n.galleryFeatured)));
        final cardWidth = compact ? (width * 0.84).clamp(240.0, 340.0) : null;
        final cards = [
          for (final item in featured)
            _FeaturedCard(
              item: item,
              brightness: brightness,
              width: cardWidth,
              onTap: () => _open(context, item, brightness),
            ),
        ];
        out.add(
          compact
              ? _shelf(cards, side)
              : padded(
                  _rows(
                    cards.take(width >= 900 ? 3 : 2).toList(),
                    width >= 900 ? 3 : 2,
                  ),
                ),
        );
      }
    }
    for (final type in _types) {
      final list = matches.where((i) => i.type == type).toList();
      if (list.isEmpty) continue;
      out.add(
        padded(
          SectionHeader(
            title: _typeLabel(l10n, type),
            count: list.length.humanizedCount(context.l10n.localeName),
            trailing: TextButton(
              key: Key('gallerySeeAll-$type'),
              onPressed: () => _showType(type),
              child: Text(l10n.gallerySeeAll),
            ),
          ),
        ),
      );
      if (compact) {
        final cardWidth = switch (type) {
          'wallpaper' => 128.0,
          'skill' => (width * 0.84).clamp(260.0, 320.0),
          _ => 196.0,
        };
        out.add(
          _shelf([
            for (final item in list.take(12))
              _card(context, item, brightness, width: cardWidth),
          ], side),
        );
      } else {
        final columns = _columns(type, width);
        final shown = list
            .take(type == 'skill' ? columns * 2 : columns)
            .toList();
        out.add(padded(_grid(context, shown, width, brightness)));
      }
    }
    out.add(const SizedBox(height: AppSpace.xl));
    out.add(padded(const _Contribute()));
    return out;
  }

  Widget _shelf(List<Widget> cards, double side) => EdgeFade(child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: side),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, card) in cards.indexed) ...[
          if (i > 0) const SizedBox(width: _gap),
          card,
        ],
      ],
    ),
  ));

  Widget _grid(
    BuildContext context,
    List<GalleryItem> items,
    double width,
    Brightness brightness,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    final type = items.first.type;
    return _rows(
      [for (final item in items) _card(context, item, brightness)],
      _columns(type, width),
      stretch: type == 'skill',
    );
  }

  Widget _card(
    BuildContext context,
    GalleryItem item,
    Brightness brightness, {
    double? width,
  }) {
    void open() => _open(context, item, brightness);
    final card = switch (item.type) {
      'wallpaper' => _WallpaperCard(
        item: item,
        brightness: brightness,
        onTap: open,
      ),
      'skill' => _SkillCard(item: item, onTap: open),
      _ => _LookCard(item: item, brightness: brightness, onTap: open),
    };
    return width == null ? card : SizedBox(width: width, child: card);
  }

  List<Widget> _skeleton(double width, double side) {
    final compact = width < 600;
    final columns = _columns('theme', width);
    final cards = [
      for (var i = 0; i < (compact ? 4 : columns); i++) const _SkeletonCard(),
    ];
    return [
      for (var section = 0; section < 2; section++) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(
            side + AppSpace.xxs,
            AppSpace.lg,
            side,
            AppSpace.sm,
          ),
          child: const _Bar(width: 96, height: 14),
        ),
        compact
            ? _shelf([
                for (final c in cards) SizedBox(width: 196, child: c),
              ], side)
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: _rows(cards, columns),
              ),
      ],
    ];
  }

  /// Opens the item a link points at, once the list is in (or fetches it when it isn't listed).
  void _openLinked(
    BuildContext context,
    List<GalleryItem> all,
    Brightness brightness,
  ) {
    final id = widget.openId;
    final type = widget.openType;
    if (_opened || id == null || type == null) return;
    _opened = true;
    GalleryItem? found;
    for (final item in all) {
      if (item.id == id && item.type == type) found = item;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      var item = found;
      if (item == null) {
        try {
          item = await ref.read(backendProvider).galleryItem(type, id);
        } catch (e) {
          if (context.mounted) showError(context, e);
          return;
        }
      }
      if (context.mounted) await _open(context, item, brightness);
    });
  }

  Future<void> _open(
    BuildContext context,
    GalleryItem item,
    Brightness brightness,
  ) => showAdaptiveSheet<void>(
    context: context,
    dialogMaxWidth: 620,
    builder: (_) => _GalleryDetail(
      item: item,
      brightness: brightness,
      onTag: (tag) {
        _search.text = tag;
        _showType(null);
      },
    ),
  );
}

/// Equal columns, rows that end together; a short last row keeps its column widths.
Widget _rows(List<Widget> cards, int columns, {bool stretch = false}) {
  final rows = <Widget>[];
  for (var start = 0; start < cards.length; start += columns) {
    final row = Row(
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        for (var col = 0; col < columns; col++) ...[
          if (col > 0) const SizedBox(width: _gap),
          Expanded(
            child: start + col < cards.length
                ? cards[start + col]
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
    if (start > 0) rows.add(const SizedBox(height: _gap));
    rows.add(stretch ? IntrinsicHeight(child: row) : row);
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
}

/// The frame every gallery card shares; a thicker edge in the accent marks what's in use.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
    this.selected = false,
    this.padding = const EdgeInsets.all(7),
  });
  final Widget child;
  final VoidCallback onTap;
  final String label;
  final bool selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? scheme.primary : context.appColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _InUseBadge extends StatelessWidget {
  const _InUseBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 13, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              context.l10n.galleryInUse,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name and one quiet line under a card's picture. A contributor's name shows when it isn't
/// Casama's own; otherwise the line says what the item is.
class _CardCaption extends StatelessWidget {
  const _CardCaption({
    required this.item,
    required this.line,
    this.titleStyle,
    this.trailing,
  });
  final GalleryItem item;
  final String line;
  final TextStyle? titleStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    final community = item.authorName.isNotEmpty && item.authorName != 'Casama';
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 9, 5, 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      titleStyle ??
                      context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  community ? context.l10n.galleryBy(item.authorName) : line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

TextStyle? _headingStyle(
  BuildContext context,
  GalleryItem item,
  TextStyle? base,
) {
  final font = galleryHeadingFontOf(item);
  if (base == null || font == null) return base;
  return fontStyle(font, base);
}

/// A theme or a color scheme: the chat in its colors (a theme also in its fonts and background).
class _LookCard extends ConsumerWidget {
  const _LookCard({
    required this.item,
    required this.brightness,
    required this.onTap,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final look = GalleryLook.of(item, appearance, alone: true);
    final inUse = galleryInUse(item, appearance);
    final heading = galleryHeadingFontOf(item);
    final body = galleryBodyFontOf(item);
    return _CardFrame(
      key: Key('gallery-${item.type}-${item.id}'),
      label: item.name,
      selected: inUse,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile - 2),
                child: item.type == 'scheme'
                    ? GallerySchemeSwatch(
                        scheme: look.scheme,
                        brightness: brightness,
                        headingFont: look.headingFont,
                      )
                    : GalleryChatPreview(look: look, brightness: brightness),
              ),
              if (inUse)
                const Positioned(top: 7, right: 7, child: _InUseBadge()),
            ],
          ),
          _CardCaption(
            item: item,
            line: item.type == 'theme' && heading != null && body != null
                ? (heading == body ? heading : '$heading · $body')
                : l10n.galleryLightAndDark,
            titleStyle: _headingStyle(
              context,
              item,
              context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            trailing: SchemeDots(
              colors: look.scheme.colors(brightness),
              size: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _wallpaperLine(AppLocalizations l10n, GalleryItem item) {
  final spec = galleryWallpaperOf(item);
  if (spec == null || spec.photo != null) return l10n.galleryImage;
  return l10n.galleryPatternOn(
    spec.doodles != null ? l10n.galleryOwnDoodles : spec.pattern.label,
    spec.mesh != null ? l10n.galleryMeshGradient : spec.palette.label,
  );
}

/// A wallpaper on its own, phone-shaped.
class _WallpaperCard extends ConsumerWidget {
  const _WallpaperCard({
    required this.item,
    required this.brightness,
    required this.onTap,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final inUse = galleryInUse(item, appearance);
    return _CardFrame(
      key: Key('gallery-${item.type}-${item.id}'),
      label: item.name,
      selected: inUse,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile - 2),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GalleryWallpaperPreview(
                    item: item,
                    scheme: appearance.scheme,
                    brightness: brightness,
                  ),
                  if (inUse)
                    const Positioned(top: 7, right: 7, child: _InUseBadge()),
                ],
              ),
            ),
          ),
          _CardCaption(item: item, line: _wallpaperLine(context.l10n, item)),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.item, required this.onTap});
  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;
    final category = item.category;
    return _CardFrame(
      key: Key('gallery-${item.type}-${item.id}'),
      label: item.name,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkillIconTile(
            icon: skillIcon(icon: item.icon, category: category),
            color: skillCategoryColor(context, category),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: muted,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.xs),
                Text(
                  [
                    if (category != null) skillCategoryLabel(context, category),
                    if (item.authorName.isNotEmpty &&
                        item.authorName != 'Casama')
                      context.l10n.galleryBy(item.authorName),
                    item.license,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A wide card for the featured row: the whole look behind a chat, as it would be applied.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({
    required this.item,
    required this.brightness,
    required this.onTap,
    this.width,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final inUse = galleryInUse(item, appearance);
    final look = GalleryLook.of(item, appearance, alone: true, thumb: true);
    final card = _CardFrame(
      key: Key('galleryFeatured-${item.type}-${item.id}'),
      label: item.name,
      selected: inUse,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile - 2),
                child: GalleryChatPreview(
                  look: look,
                  brightness: brightness,
                  aspectRatio: 16 / 10,
                ),
              ),
              if (inUse)
                const Positioned(top: 8, right: 8, child: _InUseBadge()),
            ],
          ),
          _CardCaption(
            item: item,
            line: _typeName(l10n, item.type),
            titleStyle: _headingStyle(
              context,
              item,
              context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}

/// The final card shape with flat grey where the picture and the words will be.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.appColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.tile - 2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(5, 12, 5, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: 88, height: 12),
                  SizedBox(height: 7),
                  _Bar(width: 56, height: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way in for contributors, at the end of the gallery.
class _Contribute extends ConsumerWidget {
  const _Contribute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    void share() {
      final code = ThemePreset.fromAppearance(
        ref.read(appearanceProvider),
        id: 'shared',
        name: l10n.myThemes,
      ).toCode();
      launchUrl(galleryShareUri(code), mode: LaunchMode.externalApplication);
    }

    final button = OutlinedButton.icon(
      key: const Key('galleryContribute'),
      onPressed: share,
      icon: const Icon(LucideIcons.share, size: 18),
      label: Text(l10n.galleryShare),
    );
    final text = Text(
      l10n.galleryContribute,
      style: context.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 520
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: AppSpace.sm),
                button,
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: AppSpace.md),
                button,
              ],
            ),
    );
  }
}

/// One item, large: the look in light or dark, what it brings, and Use.
class _GalleryDetail extends ConsumerStatefulWidget {
  const _GalleryDetail({
    required this.item,
    required this.brightness,
    this.onTag,
  });
  final GalleryItem item;
  final Brightness brightness;

  /// Searches the gallery for a tag.
  final ValueChanged<String>? onTag;

  @override
  ConsumerState<_GalleryDetail> createState() => _GalleryDetailState();
}

class _GalleryDetailState extends ConsumerState<_GalleryDetail> {
  late var _brightness = widget.brightness;
  late var _item = widget.item;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final missing = _item.type == 'skill'
        ? _item.skillMd == null
        : _item.document == null;
    if (missing) _fetch();
  }

  Future<void> _fetch() async {
    try {
      final full = await ref
          .read(backendProvider)
          .galleryItem(_item.type, _item.id);
      if (mounted) {
        setState(() {
          _item = full;
        });
      }
    } catch (_) {
      // The list's copy is enough to show; Use fetches again.
    }
  }

  Future<void> _use() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
    });
    final done = await runGuarded<bool>(context, () async {
      final backend = ref.read(backendProvider);
      final missing = _item.type == 'skill' ? false : _item.document == null;
      final item = missing
          ? await backend.galleryItem(_item.type, _item.id)
          : _item;
      if (item.type == 'skill') {
        final org = ref.read(currentOrgProvider);
        if (org == null) return false;
        await backend.installGallerySkill(org.id, item.id);
      } else {
        await applyGalleryItem(ref, item);
      }
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    if (done == true) {
      showSuccess(
        context,
        _item.type == 'skill'
            ? l10n.galleryInstalled(_item.name)
            : l10n.galleryApplied(_item.name),
      );
      Navigator.of(context).pop();
    }
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(
        text: 'https://casama.ai/gallery/${_item.type}/${_item.id}',
      ),
    );
    showMessage(context, context.l10n.linkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final appearance = ref.watch(appearanceProvider);
    final item = _item;
    final isLook = item.type != 'skill';
    final inUse = isLook && galleryInUse(item, appearance);
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.medium;
    final look = isLook ? GalleryLook.of(item, appearance) : null;
    final title = _headingStyle(
      context,
      item,
      context.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    );

    // Use is drawn in the colors it applies, so the button previews them too.
    final tint = look != null && item.type != 'wallpaper'
        ? galleryColorScheme(look.scheme, Theme.of(context).brightness)
        : null;
    final use = GlowButton.icon(
      key: Key('galleryUse-${item.id}'),
      style: tint == null
          ? null
          : FilledButton.styleFrom(
              backgroundColor: tint.primary,
              foregroundColor: tint.onPrimary,
            ),
      onPressed: inUse || _busy ? null : _use,
      icon: Icon(
        inUse
            ? LucideIcons.check
            : (isLook ? LucideIcons.paintbrush : LucideIcons.download),
        size: 18,
      ),
      label: Text(
        inUse
            ? l10n.galleryInUse
            : (isLook ? l10n.galleryUse : l10n.galleryInstall),
      ),
    );
    final copy = OutlinedButton.icon(
      key: Key('galleryCopy-${item.id}'),
      onPressed: _copyLink,
      icon: const Icon(LucideIcons.link, size: 18),
      label: Text(l10n.copyLink),
    );
    final report = TextButton.icon(
      key: Key('galleryReport-${item.id}'),
      onPressed: () =>
          launchUrl(_reportUri(item), mode: LaunchMode.externalApplication),
      icon: const Icon(LucideIcons.flag, size: 16),
      label: Text(l10n.galleryReport),
      style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
    );

    final actions = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 50, child: use),
              const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 46, child: copy)),
                  const SizedBox(width: AppSpace.xs),
                  report,
                ],
              ),
            ],
          )
        : Row(
            children: [
              report,
              const Spacer(),
              copy,
              const SizedBox(width: AppSpace.xs),
              use,
            ],
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(child: _body(context, item, look, compact, title)),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: actions,
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    GalleryItem item,
    GalleryLook? look,
    bool compact,
    TextStyle? title,
  ) {
    final l10n = context.l10n;
    final isLook = look != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        compact ? 0 : AppSpace.xxs,
        AppSpace.lg,
        AppSpace.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (look != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: GalleryChatPreview(
                key: const Key('galleryPreview'),
                look: look,
                brightness: _brightness,
                aspectRatio: compact ? 4 / 3 : 16 / 9,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: SizedBox(
                width: 260,
                child: AppSegmentedControl<Brightness>(
                  key: const Key('galleryDetailBrightness'),
                  values: const [Brightness.light, Brightness.dark],
                  labels: {
                    Brightness.light: l10n.themeLight,
                    Brightness.dark: l10n.themeDark,
                  },
                  icons: const {
                    Brightness.light: LucideIcons.sun,
                    Brightness.dark: LucideIcons.moon,
                  },
                  groupValue: _brightness,
                  onValueChanged: (b) => setState(() {
                    _brightness = b;
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isLook) ...[
                SkillIconTile(
                  icon: skillIcon(icon: item.icon, category: item.category),
                  color: skillCategoryColor(context, item.category),
                  size: 56,
                ),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: title),
                    const SizedBox(height: AppSpace.xxs),
                    _MetaLine(item: item),
                  ],
                ),
              ),
            ],
          ),
          if (item.description != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              item.description!,
              style: context.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          ..._facts(context, item, look),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final tag in item.tags)
                  ActionChip(
                    key: Key('galleryTag-$tag'),
                    avatar: const Icon(LucideIcons.search, size: 14),
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onTag?.call(tag);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// What the item brings, row by row.
  List<Widget> _facts(
    BuildContext context,
    GalleryItem item,
    GalleryLook? look,
  ) {
    final l10n = context.l10n;
    switch (item.type) {
      case 'theme':
        final heading = galleryHeadingFontOf(item) ?? look!.headingFont;
        final body = galleryBodyFontOf(item) ?? look!.bodyFont;
        return [
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.palette,
                title: l10n.colorScheme,
                subtitle: l10n.galleryLightAndDark,
                trailing: SchemeDots(colors: look!.scheme.colors(_brightness)),
              ),
              GroupedTile(
                icon: LucideIcons.type,
                title: l10n.fonts,
                subtitle: heading == body ? heading : '$heading · $body',
              ),
              GroupedTile(
                icon: LucideIcons.image,
                title: l10n.background,
                subtitle: _wallpaperLine(l10n, item),
              ),
            ],
          ),
        ];
      case 'scheme':
        return [
          GroupedCard(
            children: [
              for (final b in const [Brightness.light, Brightness.dark])
                GroupedTile(
                  icon: b == Brightness.light
                      ? LucideIcons.sun
                      : LucideIcons.moon,
                  title: b == Brightness.light
                      ? l10n.themeLight
                      : l10n.themeDark,
                  trailing: _Swatches(
                    colors: galleryColorScheme(look!.scheme, b),
                  ),
                ),
            ],
          ),
        ];
      case 'wallpaper':
        return [
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.image,
                title: l10n.galleryBehindChats,
                subtitle: _wallpaperLine(l10n, item),
              ),
            ],
          ),
        ];
    }
    final md = item.skillMd;
    if (md == null) return const [];
    return [
      Text(
        l10n.galleryInstructions,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpace.xs),
      Container(
        key: const Key('gallerySkillInstructions'),
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHigh.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Text(
            _skillBody(md),
            style: AppText.mono.copyWith(fontSize: 12.5),
          ),
        ),
      ),
    ];
  }
}

/// SKILL.md without its front matter.
String _skillBody(String md) {
  final match = RegExp(r'^---\n[\s\S]*?\n---\n?').firstMatch(md);
  return (match == null ? md : md.substring(match.end)).trim();
}

/// "Theme · By Casama · CC0-1.0", the author a link when they have one.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.item});
  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    final style = context.textTheme.bodyMedium?.copyWith(color: muted);
    final url = item.authorUrl;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${_typeName(l10n, item.type)} · ', style: style),
        if (url == null)
          Text(l10n.galleryBy(item.authorName), style: style)
        else
          InkWell(
            onTap: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            child: Text(
              l10n.galleryBy(item.authorName),
              style: style?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: muted,
              ),
            ),
          ),
        Text(' · ${item.license}', style: style),
      ],
    );
  }
}

/// Five swatches of a scheme: primary, its container, secondary, tertiary and the surface.
class _Swatches extends StatelessWidget {
  const _Swatches({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final edge = context.appColors.hairline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, c) in [
          colors.primary,
          colors.primaryContainer,
          colors.secondary,
          colors.tertiary,
          colors.surface,
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 5),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: edge),
            ),
          ),
        ],
      ],
    );
  }
}

Uri _reportUri(
  GalleryItem item,
) => Uri.https('github.com', '/stackwares/casama-gallery/issues/new', {
  'title': 'Report ${item.type}/${item.id}',
  'body':
      'Please look at ${item.name} (${item.type}/${item.id}), by ${item.authorName}.\n',
});

/// The gallery's page for [item] (its picture, author, license and Use), from wherever a gallery
/// look is shown.
Future<void> showGalleryDetail(BuildContext context, GalleryItem item) =>
    showAdaptiveSheet<void>(
      context: context,
      dialogMaxWidth: 620,
      builder: (_) => _GalleryDetail(
        item: item,
        brightness: Theme.of(context).brightness,
      ),
    );

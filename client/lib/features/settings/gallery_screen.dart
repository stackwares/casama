import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'colors_panel.dart' show SchemeDots;
import 'gallery_looks.dart';
import 'gallery_previews.dart';
import 'package:casama_sdk/casama_sdk.dart' show ReportTarget;
import '../moderation/report_sheet.dart';
import '../gallery/gallery_cards.dart';
import '../gallery/gallery_data.dart';
import '../gallery/gallery_detail_parts.dart';
import '../gallery/gallery_install.dart';
import '../gallery/gallery_installed.dart';
import '../gallery/gallery_logic.dart';
import '../integrations/integrations_screen.dart' show connectedAppIdsProvider;
import '../packs/pack_preview_screen.dart' show PackAddTiles;
import '../packs/pack_logic.dart' show galleryPacksProvider;
import '../packs/packs_shelf.dart';
import '../../core/link_browser.dart';
import '../../core/remote_content.dart';

export 'gallery_previews.dart' show galleryHost;

/// The Gallery page: looks, skills, apps, bots, routines, plugins and starter sets from the open
/// gallery (D-184, D-315), with home rows, filters, one search across every kind, and an
/// Installed tab.
/// Skills and links into the gallery open it; looks also show beside the built-in ones in
/// Appearance and Customize (D-203).
/// Every look is drawn as a small Casama chat in its own colors, so people choose by seeing.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
    this.initialType,
    this.openType,
    this.openId,
    this.installed = false,
  });

  /// `theme`, `scheme`, `wallpaper`, `skill`, `app`, `bot`, `routine`, `plugin` or `set`. Null
  /// shows everything.
  final String? initialType;
  final String? openType;
  final String? openId;

  /// Opens on the Installed tab.
  final bool installed;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

const _types = galleryKinds;
const _gap = AppSpace.sm;

String _typeLabel(AppLocalizations l10n, String type) =>
    galleryKindLabel(l10n, type);

String _typeName(AppLocalizations l10n, String type) =>
    galleryKindName(l10n, type);

bool _isLook(String type) => galleryLookKinds.contains(type);

/// Columns for a content [width]: cards keep a useful size, phones get two looks or three
/// wallpapers a row, wide windows more.
int _columns(String type, double width) {
  final (min, lo, hi) = switch (type) {
    'wallpaper' => (150.0, 3, 7),
    'theme' || 'scheme' => (230.0, 2, 5),
    _ => (340.0, 1, 3),
  };
  return ((width + _gap) / (min + _gap)).floor().clamp(lo, hi);
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _search = TextEditingController();
  late String? _type = _types.contains(widget.initialType)
      ? widget.initialType
      : null;
  /// The filters over the kind chips: a category or tag, price, self-hosted, computer.
  var _filter = const GalleryFilter();
  late var _installedTab = widget.installed;

  /// Whether cards show "New" (not while most of the catalog counts as new).
  var _newShown = true;

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

  // The catalog hides what this app can't draw or is too old for (galleryCatalogProvider).
  void _retry() => ref.invalidate(galleryCatalogProvider);

  void _showType(String? type) {
    setState(() {
      _type = type;
    });
  }

  List<GalleryItem> _matching(List<GalleryItem> all) {
    final q = _search.text.trim();
    final filtered = _filter.apply(all);
    // One search across every kind, with synonyms; best matches first.
    if (q.isNotEmpty) {
      // The gallery's search words when the server sends them (D-372).
      final words = ref.watch(galleryListsProvider).value?.searchWords;
      return gallerySearch(filtered, q, searchWords: words);
    }
    // Featured first, then by name, so the best of each kind leads its row.
    return [...filtered]..sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = _brightness ?? Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final catalog = ref.watch(galleryCatalogProvider);
    final connected =
        ref.watch(connectedAppIdsProvider).value ?? const <String>{};
    return SubPage(
      title: l10n.gallery,
      maxWidth: kWidePageMaxWidth,
      actions: [
        if (!_installedTab)
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
          final loading = catalog.isLoading;
          final failed =
              !loading &&
              (catalog.hasError || catalog.value?.available == false);
          final all = loading || failed
              ? const <GalleryItem>[]
              : catalog.value!.items;
          if (!loading && !failed) _openLinked(context, all, brightness);
          final matches = _matching(all);
          final query = _search.text.trim();
          _newShown = galleryNewShown(all, DateTime.now());
          Widget padded(Widget child) => Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: child,
          );
          final content = _installedTab
              ? [
                  padded(
                    GroupedCard(
                      children: [
                        GroupedTile(
                          key: const Key('galleryInstalledPacks'),
                          icon: LucideIcons.package,
                          title: l10n.packsInstalledTitle,
                          subtitle: l10n.packsInstalledRow,
                          showChevron: true,
                          onTap: () => context.push('/settings/gallery/packs'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  GalleryInstalledView(
                    side: side,
                    onOpenItem: (type, id) =>
                        _openRef(context, all, type, id, brightness),
                  ),
                ]
              : loading
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
              : matches.where((i) => _type == null || i.type == _type).isEmpty
              ? [padded(_empty(context, query))]
              : _type == null
              ? _overview(context, matches, width, side, brightness, connected)
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: AppSpace.xs,
              bottom: AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              padded(
                AppSegmentedControl<bool>(
                  key: const Key('galleryTabs'),
                  values: const [false, true],
                  labels: {
                    false: l10n.galleryTabBrowse,
                    true: l10n.galleryTabInstalled,
                  },
                  icons: const {
                    false: LucideIcons.layoutGrid,
                    true: LucideIcons.packageCheck,
                  },
                  groupValue: _installedTab,
                  onValueChanged: (v) => setState(() {
                    _installedTab = v;
                  }),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              if (!_installedTab) ...[
                padded(
                  TextField(
                    key: const Key('gallerySearch'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration:
                        searchFieldDecoration(
                          context,
                          l10n.gallerySearchEverything,
                        ).copyWith(
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
                _typeChips(
                  context,
                  loading || failed ? null : matches,
                  {for (final i in all) i.type},
                  side,
                ),
                if (!loading && !failed) ...[
                  const SizedBox(height: AppSpace.xs),
                  _filterChips(context, all, side),
                ],
                const SizedBox(height: AppSpace.xs),
              ],
              ...content,
            ],
          );
        },
      ),
    );
  }

  /// Nothing matches: clear the search, ask for it on the requests board, or ask Casama to make it.
  Widget _empty(BuildContext context, String query) {
    final l10n = context.l10n;
    if (query.isEmpty && _filter.isEmpty) {
      return EmptyState(icon: LucideIcons.searchX, message: l10n.galleryEmpty);
    }
    return EmptyState(
      icon: LucideIcons.searchX,
      message: query.isEmpty
          ? l10n.galleryNoFilterMatches
          : l10n.galleryNoMatches(query),
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        children: [
          if (query.isNotEmpty) ...[
            FilledButton.tonalIcon(
              key: const Key('galleryRequestThis'),
              onPressed: () => context.push(
                Uri(
                  path: '/settings/gallery/requests/new',
                  queryParameters: {'title': query},
                ).toString(),
              ),
              icon: const Icon(LucideIcons.lightbulb, size: 18),
              label: Text(l10n.galleryRequestThis),
            ),
            OutlinedButton.icon(
              key: const Key('galleryAskCasama'),
              onPressed: () =>
                  galleryOpenChat(context, l10n.galleryAskPrompt(query)),
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(l10n.galleryAskCasama),
            ),
          ],
          TextButton(
            onPressed: () => setState(() {
              _search.clear();
              _filter = const GalleryFilter();
            }),
            child: Text(
              query.isEmpty ? l10n.galleryClearFilters : l10n.galleryClearSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChips(
    BuildContext context,
    List<GalleryItem>? matches,
    Set<String> present,
    double side,
  ) {
    final l10n = context.l10n;
    final muted = context.colorScheme.onSurfaceVariant;
    // Kinds this gallery has; the four first kinds always show, as before.
    final kinds = [
      for (final t in _types)
        if (present.contains(t) ||
            const {'theme', 'scheme', 'wallpaper', 'skill'}.contains(t))
          t,
    ];
    return EdgeFade(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Row(
        children: [
          for (final type in [null, ...kinds]) ...[
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

  /// Price, self-hosted, computer and the commonest categories and tags.
  Widget _filterChips(
    BuildContext context,
    List<GalleryItem> all,
    double side,
  ) {
    final l10n = context.l10n;
    final tags = galleryTopTags(all);
    Widget chip(String key, String label, bool selected, VoidCallback onTap) =>
        FilterChip(
          key: Key('galleryFilter-$key'),
          label: Text(label),
          selected: selected,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => setState(onTap),
        );
    final f = _filter;
    return EdgeFade(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: side),
      child: Row(
        spacing: AppSpace.xs,
        children: [
          chip('free', l10n.galleryFilterFree, f.price == GalleryPrice.free, () {
            _filter = f.copyWith(
              price: () => f.price == GalleryPrice.free ? null : GalleryPrice.free,
            );
          }),
          chip('plan', l10n.galleryFilterPlan, f.price == GalleryPrice.plan, () {
            _filter = f.copyWith(
              price: () => f.price == GalleryPrice.plan ? null : GalleryPrice.plan,
            );
          }),
          chip('selfhosted', l10n.galleryFilterSelfHosted, f.selfHosted, () {
            _filter = f.copyWith(selfHosted: !f.selfHosted);
          }),
          chip('computer', l10n.galleryFilterComputer, f.computer, () {
            _filter = f.copyWith(computer: !f.computer);
          }),
          for (final t in tags)
            chip('tag-$t', galleryTagLabel(context, t), f.tag == t, () {
              _filter = f.copyWith(tag: () => f.tag == t ? null : t);
            }),
        ],
      ),
    ));
  }

  /// Opens the item named by [type] and [id] (a retired item's replacement).
  Future<void> _openRef(
    BuildContext context,
    List<GalleryItem> all,
    String type,
    String id,
    Brightness brightness,
  ) async {
    var item = all.where((i) => i.type == type && i.id == id).firstOrNull;
    item ??= await runGuarded<GalleryItem>(
      context,
      () => ref.read(backendProvider).galleryItem(type, id),
    );
    if (item != null && context.mounted) await _open(context, item, brightness);
  }

  /// Everything at once: the home rows (picks, new, trending, most used, works with what you
  /// have, starter sets, seasonal), then one row of each kind with "See all". Rows with nothing
  /// to show are left out; searching or filtering shows only the kind rows.
  List<Widget> _overview(
    BuildContext context,
    List<GalleryItem> matches,
    double width,
    double side,
    Brightness brightness,
    Set<String> connected,
  ) {
    final l10n = context.l10n;
    final compact = width < 600;
    final browsing = _search.text.trim().isEmpty && _filter.isEmpty;
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: child,
    );
    final out = <Widget>[];
    if (browsing) {
      final rows = GalleryRows.from(
        matches,
        now: DateTime.now(),
        connected: connected,
      );
      if (rows.picks.isNotEmpty) {
        out.add(padded(SectionHeader(title: l10n.galleryRowPicks)));
        final cardWidth = compact ? (width * 0.84).clamp(240.0, 340.0) : null;
        final cards = [
          for (final item in rows.picks)
            _isLook(item.type)
                ? _FeaturedCard(
                    item: item,
                    brightness: brightness,
                    width: cardWidth,
                    note: item.pick,
                    onTap: () => _open(context, item, brightness),
                  )
                : SizedBox(
                    width: cardWidth,
                    child: GalleryItemCard(
                      key: Key('galleryPick-${item.type}-${item.id}'),
                      showNew: _newShown,
                      item: item,
                      note: item.pick,
                      onTap: () => _open(context, item, brightness),
                    ),
                  ),
        ];
        final columns = width >= 900 ? 3 : 2;
        out.add(
          compact
              ? _shelf(cards, side)
              : padded(_rows(cards.take(columns * 2).toList(), columns)),
        );
      }
      // Packs: bots, skills and routines that work together (docs/PLUGINS-AND-PACKS-PLAN.md).
      out.add(
        PacksShelf(
          side: side,
          width: width,
          onOpenSet: (id) => _openRef(context, matches, 'set', id, brightness),
        ),
      );
      void row(String key, String title, List<GalleryItem> items) {
        if (items.isEmpty) return;
        out.add(
          padded(
            SectionHeader(
              key: Key('galleryRow-$key'),
              title: title,
            ),
          ),
        );
        if (compact) {
          out.add(
            _shelf([
              for (final item in items)
                _card(
                  context,
                  item,
                  brightness,
                  width: switch (item.type) {
                    'wallpaper' => 128.0,
                    'theme' || 'scheme' => 196.0,
                    _ => (width * 0.84).clamp(260.0, 320.0),
                  },
                ),
            ], side),
          );
        } else {
          final columns = ((width + _gap) / (300 + _gap)).floor().clamp(2, 4);
          out.add(
            padded(
              _rows(
                [
                  for (final item in items.take(columns))
                    _card(context, item, brightness),
                ],
                columns,
              ),
            ),
          );
        }
      }

      row('new', l10n.galleryRowNew, rows.fresh);
      row('trending', l10n.galleryRowTrending, rows.trending);
      row('mostUsed', l10n.galleryRowMostUsed, rows.mostUsed);
      row('worksWith', l10n.galleryRowWorksWith, rows.worksWith);
      // The Packs shelf above holds starter sets too (packs plan, decision 3); a second row of them
      // only repeats it, so it shows only while the shelf has nothing.
      if ((ref.watch(galleryPacksProvider).value ?? const []).isEmpty) {
        row('sets', l10n.galleryRowSets, rows.sets);
      }
      row('seasonal', l10n.galleryRowSeasonal, rows.seasonal);
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
          'theme' || 'scheme' => 196.0,
          _ => (width * 0.84).clamp(260.0, 320.0),
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
            .take(_isLook(type) ? columns : columns * 2)
            .toList();
        out.add(padded(_grid(context, shown, width, brightness)));
      }
    }
    out.add(const SizedBox(height: AppSpace.xl));
    out.add(
      padded(
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('galleryRequestsLink'),
              icon: LucideIcons.lightbulb,
              title: l10n.galleryRequestsTitle,
              subtitle: l10n.galleryRequestsLinkHelp,
              showChevron: true,
              onTap: () => context.push('/settings/gallery/requests'),
            ),
            GroupedTile(
              key: const Key('gallerySubmissionsLink'),
              icon: LucideIcons.send,
              title: l10n.gallerySubmitStart,
              subtitle: l10n.gallerySubmissionsLinkHelp,
              showChevron: true,
              onTap: () => context.push('/settings/gallery/submissions'),
            ),
          ],
        ),
      ),
    );
    out.add(const SizedBox(height: AppSpace.lg));
    out.add(padded(const PackAddTiles()));
    out.add(const SizedBox(height: AppSpace.lg));
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
      stretch: !_isLook(type),
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
        showNew: _newShown,
      ),
      'theme' || 'scheme' => _LookCard(
        item: item,
        brightness: brightness,
        onTap: open,
        showNew: _newShown,
      ),
      _ => GalleryItemCard(item: item, onTap: open, showNew: _newShown),
    };
    return width == null ? card : SizedBox(width: width, child: card);
  }

  /// The overview before the gallery arrives: the featured row, then a row of themes with its
  /// "See all", in the same cards, widths and columns as [_overview].
  List<Widget> _skeleton(double width, double side) {
    final compact = width < 600;
    final columns = _columns('theme', width);
    final featuredColumns = width >= 900 ? 3 : 2;
    final featuredWidth = (width * 0.84).clamp(240.0, 340.0);
    final cards = [
      for (var i = 0; i < (compact ? 4 : columns); i++) const _SkeletonCard(),
    ];
    final featured = [
      for (var i = 0; i < (compact ? 2 : featuredColumns); i++)
        const _SkeletonCard(featured: true),
    ];
    Widget padded(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: side),
      child: child,
    );
    return [
      SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            padded(const SkeletonSectionHeader()),
            compact
                ? _shelf([
                    for (final c in featured)
                      SizedBox(width: featuredWidth, child: c),
                  ], side)
                : padded(_rows(featured, featuredColumns)),
            padded(const _SkeletonSeeAllHeader()),
            compact
                ? _shelf([
                    for (final c in cards) SizedBox(width: 196, child: c),
                  ], side)
                : padded(_rows(cards, columns)),
          ],
        ),
      ),
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
  });
  final Widget child;
  final VoidCallback onTap;
  final String label;
  final bool selected;

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
          child: Padding(padding: const EdgeInsets.all(7), child: child),
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
    this.showNew = true,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;
  final bool showNew;

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
              if (showNew && galleryIsNew(item, DateTime.now()))
                const Positioned(top: 7, left: 7, child: GalleryNewBadge()),
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
    this.showNew = true,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;
  final bool showNew;

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
                  if (showNew && galleryIsNew(item, DateTime.now()))
                    const Positioned(
                      top: 7,
                      left: 7,
                      child: GalleryNewBadge(),
                    ),
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

/// A wide card for the featured row: the whole look behind a chat, as it would be applied.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({
    required this.item,
    required this.brightness,
    required this.onTap,
    this.width,
    this.note,
  });
  final GalleryItem item;
  final Brightness brightness;
  final VoidCallback onTap;
  final double? width;

  /// Why it's a pick, in place of its kind.
  final String? note;

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
            line: note ?? _typeName(l10n, item.type),
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

/// A [SectionHeader] with a "See all" button, still loading.
class _SkeletonSeeAllHeader extends StatelessWidget {
  const _SkeletonSeeAllHeader();

  @override
  Widget build(BuildContext context) {
    // The text button's height at this density sets the header's height.
    final button = 48 + Theme.of(context).visualDensity.baseSizeAdjustment.dy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxs,
        AppSpace.lg,
        AppSpace.xxs,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: SkeletonText(
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              width: 96,
            ),
          ),
          SizedBox(
            height: button,
            width: 72,
            child: const Center(child: SkeletonBone(width: 48, height: 11)),
          ),
        ],
      ),
    );
  }
}

/// A [_LookCard] (or, [featured], a [_FeaturedCard]) still loading: the same frame, preview and
/// caption, with bones where the picture and the words will be.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.featured = false});

  final bool featured;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: featured ? 16 / 10 : 4 / 3,
              child: const SkeletonBone(radius: AppRadius.tile - 2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 9, 5, 3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkeletonText(
                          style: featured
                              ? text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )
                              : text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                          widthFactor: featured ? 0.5 : 0.7,
                        ),
                        const SizedBox(height: 1),
                        SkeletonText(
                          style: text.labelSmall,
                          widthFactor: featured ? 0.3 : 0.5,
                        ),
                      ],
                    ),
                  ),
                  if (featured)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: Center(
                        child: SkeletonBone(width: 7, height: 11, radius: 3),
                      ),
                    )
                  else
                    const SkeletonBone(width: 26, height: 12),
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
        : (_isLook(_item.type) || _item.type == 'set') &&
              _item.document == null;
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
    if (!_isLook(_item.type) && _item.type != 'skill') {
      // Routines, bots, apps, plugins and sets: the install steps (answers, needs, done).
      final done = await showGalleryInstall(
        context,
        ref,
        type: _item.type,
        id: _item.id,
      );
      if (done && mounted) Navigator.of(context).pop();
      return;
    }
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
    final isLook = _isLook(item.type);
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
            : (isLook
                  ? LucideIcons.paintbrush
                  : (item.type == 'skill'
                        ? LucideIcons.download
                        : LucideIcons.plus)),
        size: 18,
      ),
      label: Text(
        inUse
            ? l10n.galleryInUse
            : (isLook
                  ? l10n.galleryUse
                  : (item.type == 'skill'
                        ? l10n.galleryInstall
                        : l10n.galleryWizardAdd)),
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
      // In the app, not a GitHub issue (D-301): the stores want reporting without leaving.
      onPressed: () => showReportSheet(context, kind: ReportTarget.galleryItem, targetId: '${item.type}/${item.id}'),
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
                GalleryItemIcon(item: item, size: 56),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: title),
                    const SizedBox(height: AppSpace.xxs),
                    _MetaLine(item: item),
                    if (galleryStatsText(l10n, item.stats) case final String stats) ...[
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        stats,
                        key: const Key('galleryStats'),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
          if (item.pick != null) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              key: const Key('galleryPickNote'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.star,
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    item.pick!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          ..._facts(context, item, look),
          if (item.type == 'set') ..._setItems(context, item),
          if (item.access case final GalleryAccess access)
            GalleryAccessCard(access: access),
          if (item.examples.isNotEmpty)
            GalleryTryIt(examples: item.examples),
          GalleryProvenance(
            item: item,
            onOpenItem: (original) => showGalleryDetail(context, original),
          ),
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

  /// A starter set's items, each opening its own page.
  List<Widget> _setItems(BuildContext context, GalleryItem set) {
    final all = ref.watch(galleryCatalogProvider).value?.items ?? const [];
    final items = gallerySetItems(set, all);
    if (items.isEmpty) return const [];
    return [
      GroupedCard(
        children: [
          for (final i in items)
            GroupedTile(
              key: Key('gallerySetItem-${i.type}-${i.id}'),
              icon: galleryKindIcon(i.type),
              title: i.name,
              subtitle: _typeName(context.l10n, i.type),
              showChevron: true,
              onTap: () => showGalleryDetail(context, i),
            ),
        ],
      ),
    ];
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
                openWebLink(Uri.parse(url)),
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

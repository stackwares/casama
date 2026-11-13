import 'dart:async';
import 'dart:math' as math;

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/mascot.dart';
import '../../ui/page.dart';
import '../../ui/tab_reselect.dart';
import 'creation_detail.dart';
import 'creation_tile.dart';
import 'library_providers.dart';

/// The Library (D-274, LIBRARY-PLAN §5.2): everything bots made, newest first. Chips filter by
/// kind (only kinds the workspace has), a search box matches titles and bot names, pinned things
/// sit on their own shelf, and the rest falls under day headings. On a wide window a picked tile
/// opens beside the grid; elsewhere it opens its own page.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.kind, this.botId, this.query = ''});
  final CreationKind? kind;
  final String? botId;
  final String query;

  /// The detail opens beside the grid from this width of the Library's own area.
  static const splitWidth = 980.0;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late CreationKind? _kind = widget.kind;
  late final _search = TextEditingController(text: widget.query);
  late String _query = widget.query;
  Timer? _debounce;
  String? _selected;

  LibraryQuery get _q => (kind: _kind, botId: widget.botId, q: _query.trim());

  @override
  void didUpdateWidget(LibraryScreen old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _kind = widget.kind;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v);
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 800) {
      unawaited(ref.read(libraryProvider(_q).notifier).loadMore());
    }
    return false;
  }

  void _open(Creation c, bool split) {
    if (split) {
      setState(() => _selected = c.id);
    } else {
      context.push('/library/${c.id}');
    }
  }

  /// A starter from the empty Library: the bot talked to last, the request typed in, not sent.
  void _starter(String text) {
    final bots = ref.read(botsProvider).value ?? const <Bot>[];
    final bot = bots.firstOrNull;
    context.push(
      Uri(
        path: '/quick-ask',
        queryParameters: {'text': text, 'bot': ?bot?.id},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final page = ref.watch(libraryProvider(_q));
    final bot = widget.botId == null
        ? null
        : ref.watch(botProvider(widget.botId!));
    return PrimaryScrollController(
      controller: TabReselect.library,
      child: SubPage(
        title: l10n.library,
        subtitle: bot?.name,
        maxWidth: double.infinity,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final split = constraints.maxWidth >= LibraryScreen.splitWidth;
            final list = _list(context, page, split: split);
            if (!split || _selected == null) return list;
            return Row(
              children: [
                Expanded(child: list),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: context.appColors.hairline,
                ),
                SizedBox(
                  width: math.min(460, constraints.maxWidth * 0.42),
                  child: CreationDetailView(
                    key: ValueKey(_selected),
                    creationId: _selected!,
                    pane: true,
                    onClose: () => setState(() => _selected = null),
                    onChanged: (c, {removed = false}) {
                      ref
                          .read(libraryProvider(_q).notifier)
                          .replace(c, removed: removed);
                      if (removed) setState(() => _selected = null);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AsyncValue<LibraryPage> page, {
    required bool split,
  }) {
    final l10n = context.l10n;
    final kinds = page.value?.kinds ?? const <CreationKind>[];
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('librarySearch'),
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.librarySearchHint,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('clearLibrarySearch'),
                    tooltip: l10n.clearSearch,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
          onChanged: (v) {
            setState(() {});
            _onSearch(v);
          },
        ),
        if (kinds.length > 1 || _kind != null) ...[
          const SizedBox(height: AppSpace.sm),
          SingleChildScrollView(
            key: const Key('libraryChips'),
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: AppSpace.xs,
              children: [
                ChoiceChip(
                  key: const Key('libraryKind-all'),
                  label: Text(l10n.libraryFilterAll),
                  selected: _kind == null,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _kind = null),
                ),
                for (final k in CreationKind.values)
                  if (kinds.contains(k) || _kind == k)
                    ChoiceChip(
                      key: Key('libraryKind-${k.value}'),
                      avatar: Icon(creationIcon(k), size: 16),
                      label: Text(creationFilterName(l10n, k)),
                      selected: _kind == k,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
    return AsyncView(
      value: page,
      onRetry: () => ref.invalidate(libraryProvider(_q)),
      loading: const _LibrarySkeleton(),
      data: (data) {
        if (data.items.isEmpty) {
          final filtered =
              _kind != null || _query.trim().isNotEmpty || widget.botId != null;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            children: [
              if (filtered) header,
              const SizedBox(height: AppSpace.xl),
              filtered
                  ? EmptyState(
                      key: const Key('libraryNoMatch'),
                      icon: LucideIcons.searchX,
                      message: l10n.libraryNoMatch,
                    )
                  : EmptyState(
                      key: const Key('libraryEmpty'),
                      icon: LucideIcons.library,
                      mascot: Mascot.sleepy,
                      title: l10n.libraryEmptyTitle,
                      message: l10n.libraryEmptyBody,
                      action: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          for (final (key, label, prompt) in [
                            (
                              'game',
                              l10n.libraryStarterGame,
                              l10n.libraryStarterGamePrompt,
                            ),
                            (
                              'logo',
                              l10n.libraryStarterLogo,
                              l10n.libraryStarterLogoPrompt,
                            ),
                            (
                              'site',
                              l10n.libraryStarterSite,
                              l10n.libraryStarterSitePrompt,
                            ),
                          ])
                            ActionChip(
                              key: Key('libraryStarter-$key'),
                              label: Text(label),
                              onPressed: () => _starter(prompt),
                            ),
                        ],
                      ),
                    ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(libraryProvider(_q).future),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: LayoutBuilder(
              builder: (context, constraints) => CustomScrollView(
                key: const Key('libraryGrid'),
                primary: true,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.xs,
                      AppSpace.gutter,
                      AppSpace.sm,
                    ),
                    sliver: SliverToBoxAdapter(child: header),
                  ),
                  ..._sections(
                    context,
                    data,
                    constraints.maxWidth,
                    split: split,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom:
                          AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: data.loadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpace.md),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pinned first (All only), then Today, Yesterday, This week and Earlier.
  List<Widget> _sections(
    BuildContext context,
    LibraryPage data,
    double width, {
    required bool split,
  }) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pinned = _kind == null && _query.trim().isEmpty
        ? data.items.where((c) => c.pinned).toList()
        : const <Creation>[];
    final rest = pinned.isEmpty
        ? data.items
        : data.items.where((c) => !c.pinned).toList();
    final groups = <(String, List<Creation>)>[];
    void add(String title, Creation c) {
      if (groups.isEmpty || groups.last.$1 != title) groups.add((title, []));
      groups.last.$2.add(c);
    }

    for (final c in rest) {
      final t = c.createdAt.toLocal();
      final day = DateTime(t.year, t.month, t.day);
      final ago = today.difference(day).inDays;
      add(
        ago <= 0
            ? l10n.libraryToday
            : ago == 1
            ? l10n.libraryYesterday
            : ago < 7
            ? l10n.libraryThisWeek
            : l10n.libraryEarlier,
        c,
      );
    }
    return [
      if (pinned.isNotEmpty) ...[
        _heading(context, l10n.libraryPinned, 'pinned'),
        _grid(pinned, width, split: split),
      ],
      for (final (title, items) in groups) ...[
        _heading(context, title, title),
        _grid(items, width, split: split),
      ],
    ];
  }

  Widget _heading(BuildContext context, String title, String key) =>
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.md,
          AppSpace.gutter,
          AppSpace.xs,
        ),
        sliver: SliverToBoxAdapter(
          child: Text(
            title,
            key: Key('libraryHeading-$key'),
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  Widget _grid(List<Creation> items, double width, {required bool split}) {
    const gap = AppSpace.sm;
    final inner = width - AppSpace.gutter * 2;
    // Pictures and videos pack tighter than sites and documents.
    final tight = _kind == CreationKind.image || _kind == CreationKind.video;
    final cols = math.max(2, (inner / (tight ? 180 : 240)).floor());
    final tileWidth = (inner - gap * (cols - 1)) / cols;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          mainAxisExtent: tileWidth * 3 / 4 + 58 * textScale,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => CreationTile(
            creation: items[i],
            selected: items[i].id == _selected,
            onTap: () => _open(items[i], split),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

/// The Library while it loads: the search box, then tiles in the grid's shape.
class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - AppSpace.gutter * 2;
        final cols = math.max(2, (inner / 240).floor());
        return SkeletonPage(
          children: [
            const SkeletonBone(height: 48, radius: AppRadius.tile),
            const SizedBox(height: AppSpace.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              mainAxisSpacing: AppSpace.sm,
              crossAxisSpacing: AppSpace.sm,
              childAspectRatio: 0.95,
              children: [
                for (var i = 0; i < cols * 3; i++)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SkeletonBone(radius: AppRadius.card)),
                      SizedBox(height: AppSpace.xs),
                      SkeletonBone(height: 14, width: 120),
                      SizedBox(height: 4),
                      SkeletonBone(height: 12, width: 80),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

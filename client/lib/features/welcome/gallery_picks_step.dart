import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/edge_fade.dart';
import '../../ui/lucide_names.dart';
import '../../ui/painted_cover.dart';
import '../../ui/progressive_fade.dart';
import '../gallery/gallery_cards.dart'
    show GalleryItemIcon, galleryCoverAsset, galleryKindName;
import '../gallery/gallery_data.dart' show galleryCatalogProvider;
import '../gallery/gallery_install.dart' show applyGallerySetLooks;
import '../settings/about_you_screen.dart';
import '../settings/name_step.dart';

/// Whether this session showed the name step (About you, D-169). The picks step follows it only
/// on first run, never for people who answered the name long ago.
class _SawNameStep extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(signedInProvider);
    ref.listen<bool?>(nameStepNeededProvider, (_, needed) {
      if (needed == true) state = true;
    });
    return ref.read(nameStepNeededProvider) == true;
  }
}

final _sawNameStepProvider = NotifierProvider<_SawNameStep, bool>(
  _SawNameStep.new,
);

/// The picks step was finished (a set added or skipped) for this person on this device. Null
/// while it loads.
class GalleryPicksDone extends Notifier<bool?> {
  String get _key =>
      'gallery_picks_done.${ref.read(backendProvider).userId ?? ''}';

  @override
  bool? build() {
    ref.watch(signedInProvider);
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final done =
          (await SharedPreferences.getInstance()).getBool(_key) ?? false;
      if (state == null) state = done;
    } catch (_) {
      if (state == null) state = false;
    }
  }

  void finish() {
    state = true;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_key, true))
        .catchError((_) => false);
  }
}

final galleryPicksDoneProvider = NotifierProvider<GalleryPicksDone, bool?>(
  GalleryPicksDone.new,
);

/// The gallery's starter sets (D-315). Empty when the server has none or can't say.
final gallerySetsProvider = FutureProvider.autoDispose<List<GalleryItem>>((
  ref,
) async {
  try {
    return [
      for (final i in await ref.watch(backendProvider).gallerySets())
        if (!i.retired) i,
    ];
  } catch (_) {
    return const [];
  }
});

/// Whether "Picks for you" shows: right after this session's name step, once per person and
/// device, once a workspace exists to add to, and only when the gallery has starter sets.
final galleryPicksNeededProvider = Provider.autoDispose<bool>((ref) {
  if (!ref.watch(signInFinishedProvider)) return false;
  if (!ref.watch(_sawNameStepProvider)) return false;
  if (ref.watch(nameStepNeededProvider) != false) return false;
  if (ref.watch(galleryPicksDoneProvider) != false) return false;
  if (ref.watch(currentOrgIdProvider) == null) return false;
  return (ref.watch(gallerySetsProvider).value ?? const []).isNotEmpty;
});

/// Words in what the person shared that point at a set, by the set id words they match.
const _hints = <String, List<String>>{
  'founder': [
    'founder',
    'startup',
    'business',
    'company',
    'ceo',
    'entrepreneur',
    'sales',
    'investor',
  ],
  'writer': [
    'writer',
    'writing',
    'write',
    'author',
    'blog',
    'novel',
    'journalist',
    'editor',
    'content',
  ],
  'student': [
    'student',
    'school',
    'study',
    'studying',
    'university',
    'college',
    'class',
    'exam',
    'homework',
  ],
  'email': ['email', 'inbox', 'mail', 'gmail', 'outlook', 'busy', 'meetings'],
};

/// The words (three letters or more) in what the person told About you.
Set<String> _sharedWords(AboutYouView? about) => RegExp(r'[a-z]{3,}')
    .allMatches(
      [about?.about ?? '', about?.replyStyle ?? ''].join(' ').toLowerCase(),
    )
    .map((m) => m.group(0)!)
    .toSet();

/// How well [s] fits [words]: its own words that match, and its match words twice over.
int _fit(GalleryItem s, Set<String> words) {
  final own = RegExp(r'[a-z]{4,}')
      .allMatches(
        '${s.id} ${s.name} ${s.description ?? ''} ${s.tags.join(' ')}'
            .toLowerCase(),
      )
      .map((m) => m.group(0)!)
      .toSet();
  var score = own.intersection(words).length;
  // A set's gallery tags are its match words (D-372), so a new set matches without an app
  // build; the built-in hints stand in for sets from servers that don't tag them yet.
  final tags = {for (final t in s.tags) t.toLowerCase()};
  if (tags.length >= 3) {
    score += tags.where(words.contains).length * 2;
  } else {
    for (final e in _hints.entries) {
      if (s.id.contains(e.key) || s.name.toLowerCase().contains(e.key)) {
        score += e.value.where(words.contains).length * 2;
      }
    }
  }
  return score;
}

/// The starter set that best fits what the person told About you, and whether anything they
/// shared matched it. With no match: the first featured set, else the first set.
({GalleryItem set, bool matched}) starterPick(
  List<GalleryItem> sets,
  AboutYouView? about,
) {
  final words = _sharedWords(about);
  var best = sets.first;
  var bestScore = 0;
  for (final s in sets) {
    final score = _fit(s, words);
    if (score > bestScore ||
        (bestScore == 0 && score == 0 && s.featured && !best.featured)) {
      best = s;
      bestScore = score;
    }
  }
  return (set: best, matched: bestScore > 0);
}

/// The starter set that best fits what the person told About you; see [starterPick].
GalleryItem pickStarterSet(List<GalleryItem> sets, AboutYouView? about) =>
    starterPick(sets, about).set;

/// Kinds in the order a set's contents list them; looks (themes, schemes, wallpapers) count as one.
const _kindOrder = ['bot', 'skill', 'routine', 'app', 'plugin', 'look'];

String? _kindOf(String type) => switch (type) {
  'theme' || 'scheme' || 'wallpaper' => 'look',
  'bot' || 'skill' || 'routine' || 'app' || 'plugin' => type,
  _ => null,
};

int _kindRank(String type) {
  final i = _kindOrder.indexOf(_kindOf(type) ?? '');
  return i < 0 ? _kindOrder.length : i;
}

/// What [set] adds, bots first: the gallery's own items once the catalog has loaded, else items
/// named from their ids, so the list draws at once and sharpens when the catalog arrives.
List<GalleryItem> _setContents(GalleryItem set, List<GalleryItem> catalog) {
  final listed = set.document?['items'];
  if (listed is! List) return const [];
  final items = [
    for (final ref in listed)
      if (GalleryRef.fromJson(ref) case final GalleryRef r)
        catalog.where((i) => i.type == r.type && i.id == r.id).firstOrNull ??
            GalleryItem(
              id: r.id,
              type: r.type,
              name: _nameFromId(r.id),
              authorName: '',
              license: '',
            ),
  ];
  // A stable sort: each kind keeps the set's own order.
  final ranked = [for (final (i, item) in items.indexed) (i, item)]
    ..sort((a, b) {
      final byKind = _kindRank(a.$2.type).compareTo(_kindRank(b.$2.type));
      return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in ranked) item];
}

/// "decision-memo" → "Decision memo".
String _nameFromId(String id) {
  final words = id.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  return words.isEmpty ? id : '${words[0].toUpperCase()}${words.substring(1)}';
}

/// "2 bots · 4 skills · 2 apps".
String _contentsSummary(AppLocalizations l10n, List<GalleryItem> items) {
  final counts = <String, int>{};
  for (final i in items) {
    if (_kindOf(i.type) case final k?) counts[k] = (counts[k] ?? 0) + 1;
  }
  return [
    for (final k in _kindOrder)
      if (counts[k] case final n?)
        switch (k) {
          'bot' => l10n.galleryPicksBots(n),
          'skill' => l10n.galleryPicksSkills(n),
          'routine' => l10n.galleryPicksRoutines(n),
          'app' => l10n.galleryPicksApps(n),
          'plugin' => l10n.galleryPicksPlugins(n),
          _ => l10n.galleryPicksLooks(n),
        },
  ].join(' · ');
}

/// "Picks for you" (D-315), after "What should bots call you?" on first run: the gallery's starter
/// sets, the one that fits what the person shared first and pre-selected. Each set shows its cover
/// and, once picked, what it adds. Phones get one column with the picked set opened up; tablets and
/// desktops get the list beside a large preview of the picked set. Add installs it; Skip for now
/// leaves it. Either way it doesn't come back.
class GalleryPicksStep extends StatelessWidget {
  const GalleryPicksStep({super.key});

  // Its own overlay, like the name step: it sits above the app's navigator.
  @override
  Widget build(BuildContext context) => Overlay(
    initialEntries: [OverlayEntry(builder: (_) => const _PicksPage())],
  );
}

class _PicksPage extends ConsumerStatefulWidget {
  const _PicksPage();

  @override
  ConsumerState<_PicksPage> createState() => _PicksPageState();
}

class _PicksPageState extends ConsumerState<_PicksPage> {
  String? _chosen;
  var _busy = false;

  Future<void> _skip() async {
    Analytics.log('onboarding_step_done', {
      'step': 'gallery_picks',
      'action': 'skipped',
    });
    ref.read(galleryPicksDoneProvider.notifier).finish();
  }

  Future<void> _add(GalleryItem set) async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null || _busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await runGuarded(
      context,
      () => ref.read(backendProvider).installGallerySet(orgId, set.id),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) return;
    // The set's looks (`device`) are for this device.
    await applyGallerySetLooks(ref, result);
    if (!mounted) return;
    Analytics.log('onboarding_step_done', {
      'step': 'gallery_picks',
      'action': 'added',
      'choice': set.id,
    });
    HapticsHelper.success();
    ref.invalidate(skillsProvider);
    ref.read(galleryPicksDoneProvider.notifier).finish();
    final apps = result.missingApps.map((a) => a.name).join(', ');
    showSuccess(
      context,
      result.pending
          ? l10n.galleryPicksPending(set.name)
          : apps.isEmpty
          ? l10n.galleryPicksAdded(set.name)
          : l10n.galleryPicksAddedNeedsApps(set.name, apps),
    );
  }

  void _pick(GalleryItem set) {
    if (_busy) return;
    HapticsHelper.selection();
    setState(() => _chosen = set.id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final sets = ref.watch(gallerySetsProvider).value ?? const <GalleryItem>[];
    // Kept loaded for Add.
    ref.watch(currentOrgIdProvider);
    final about = ref.watch(aboutYouProvider).value;
    // Real names and icons for what each set adds; ids stand in until it loads.
    final catalog =
        ref.watch(galleryCatalogProvider).value?.items ?? const <GalleryItem>[];
    final pick = sets.isEmpty ? null : starterPick(sets, about);
    // The best fit leads the list.
    final ordered = [
      ?pick?.set,
      for (final s in sets)
        if (s.id != pick?.set.id) s,
    ];
    final chosen = sets.where((s) => s.id == _chosen).firstOrNull ?? pick?.set;
    final picks = _Picks(
      sets: ordered,
      chosen: chosen,
      bestMatch: pick != null && pick.matched ? pick.set.id : null,
      contents: chosen == null ? const [] : _setContents(chosen, catalog),
      busy: _busy,
      onPick: _pick,
      onAdd: chosen == null ? null : () => _add(chosen),
      onSkip: _skip,
    );
    return Scaffold(
      key: const Key('galleryPicksStep'),
      backgroundColor: scheme.surface,
      body: LayoutBuilder(
        builder: (context, box) =>
            box.maxWidth >= AppBreakpoints.split && box.maxHeight >= 600
            ? _WideLayout(picks: picks)
            : _CompactLayout(picks: picks),
      ),
    );
  }
}

/// Everything both layouts draw from.
class _Picks {
  const _Picks({
    required this.sets,
    required this.chosen,
    required this.bestMatch,
    required this.contents,
    required this.busy,
    required this.onPick,
    required this.onAdd,
    required this.onSkip,
  });

  /// The starter sets, best fit first.
  final List<GalleryItem> sets;
  final GalleryItem? chosen;

  /// The id of the set that matched what the person shared, if one did.
  final String? bestMatch;

  /// What [chosen] adds.
  final List<GalleryItem> contents;
  final bool busy;
  final ValueChanged<GalleryItem> onPick;
  final VoidCallback? onAdd;
  final VoidCallback onSkip;
}

/// Phones and narrow windows: the header, one column of sets with the picked one opened up, and
/// Add pinned at the bottom.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.picks});
  final _Picks picks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final statusBar = MediaQuery.paddingOf(context).top;
    // A phone held sideways: no fan, and the buttons side by side, so a set shows at once.
    final short = MediaQuery.sizeOf(context).height < 560;
    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ProgressiveFade(
                      child: ListView(
                        key: const Key('galleryPicksList'),
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.lg,
                          statusBar + (short ? AppSpace.md : AppSpace.xl),
                          AppSpace.lg,
                          AppSpace.xl,
                        ),
                        children: [
                          if (!short) ...[
                            _CoverFan(sets: picks.sets.take(3).toList()),
                            const SizedBox(height: AppSpace.lg),
                          ],
                          Text(
                            l10n.galleryPicksTitle,
                            textAlign: TextAlign.center,
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ).appCardEntrance(),
                          const SizedBox(height: AppSpace.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.xs,
                            ),
                            child: Text(
                              l10n.galleryPicksHelp,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ).appCardEntrance(),
                          SizedBox(height: short ? AppSpace.md : AppSpace.xl),
                          for (final (i, s) in picks.sets.indexed)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.sm,
                              ),
                              child: _SetCard(
                                set: s,
                                selected: s.id == picks.chosen?.id,
                                bestMatch: s.id == picks.bestMatch,
                                contents: s.id == picks.chosen?.id
                                    ? picks.contents
                                    : const [],
                                showContents: true,
                                onTap: picks.busy
                                    ? null
                                    : () => picks.onPick(s),
                              ),
                            ).appListItemEntrance(i + 2),
                        ],
                      ),
                    ),
                    // The list eases out under the buttons instead of ending in a hard line.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: AppSpace.xl,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.surface.withValues(alpha: 0),
                                scheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.xxs,
                  AppSpace.lg,
                  BottomPadding.of(
                    context,
                    minimum: short ? AppSpace.xs : AppSpace.md,
                  ),
                ),
                child: _Actions(picks: picks, inline: short),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablets and desktops: the header across the top, then a large preview of the picked set with
/// Add under it, beside the list of sets.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.picks});
  final _Picks picks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.galleryPicksTitle,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ).appCardEntrance(),
        const SizedBox(height: AppSpace.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            l10n.galleryPicksHelp,
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ).appCardEntrance(),
      ],
    );
    final preview = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Preview(
          set: picks.chosen,
          bestMatch:
              picks.chosen != null && picks.chosen!.id == picks.bestMatch,
          contents: picks.contents,
        ).appCardEntrance(),
        const SizedBox(height: AppSpace.lg),
        _Actions(picks: picks),
      ],
    );
    final list = ListView(
      key: const Key('galleryPicksList'),
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      children: [
        for (final (i, s) in picks.sets.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _SetCard(
              set: s,
              selected: s.id == picks.chosen?.id,
              bestMatch: s.id == picks.bestMatch,
              contents: const [],
              showContents: false,
              onTap: picks.busy ? null : () => picks.onPick(s),
            ),
          ).appListItemEntrance(i),
      ],
    );
    // The preview and Add stay put while the list scrolls beside them. The block stops growing
    // past a comfortable height and sits in the middle of a tall window, so nothing stretches.
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1184, maxHeight: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xxl + AppSpace.xs,
              AppSpace.xxl,
              AppSpace.xxl + AppSpace.xs,
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: AppSpace.xl),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: SingleChildScrollView(child: preview),
                      ),
                      const SizedBox(width: AppSpace.xxl),
                      Expanded(
                        flex: 12,
                        child: EdgeFade(extent: AppSpace.xl, child: list),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Add Founder kit" and "Skip for now".
class _Actions extends StatelessWidget {
  const _Actions({required this.picks, this.inline = false});
  final _Picks picks;

  /// Side by side, Skip first, for short screens.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final chosen = picks.chosen;
    final label = chosen == null
        ? l10n.galleryPicksAdd
        : l10n.galleryPicksAddNamed(chosen.name);
    final fast = AppMotion.of(context, AppMotion.fast);
    final add = FilledButton(
      key: const Key('galleryPicksAdd'),
      style: FilledButton.styleFrom(
        backgroundColor: scheme.onSurface,
        foregroundColor: scheme.surface,
        shape: const StadiumBorder(),
        minimumSize: Size.fromHeight(inline ? 48 : 56),
        textStyle: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      // Stays dark while adding (the spinner shows); taps then do nothing.
      onPressed: picks.onAdd == null
          ? null
          : () {
              if (!picks.busy) picks.onAdd!();
            },
      child: AnimatedSwitcher(
        duration: fast,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(a),
            child: child,
          ),
        ),
        child: picks.busy
            ? SizedBox.square(
                key: const ValueKey('busy'),
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: scheme.surface,
                ),
              )
            : Text(
                label,
                key: ValueKey(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
    final skip = TextButton(
      key: const Key('galleryPicksSkip'),
      onPressed: picks.busy ? null : picks.onSkip,
      style: TextButton.styleFrom(
        minimumSize: Size(120, inline ? 48 : 44),
        shape: const StadiumBorder(),
      ),
      child: Text(
        l10n.galleryPicksSkip,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (inline) {
      return Row(
        children: [
          skip,
          const SizedBox(width: AppSpace.sm),
          Expanded(child: add),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: double.infinity, child: add),
        const SizedBox(height: AppSpace.xxs),
        skip,
      ],
    );
  }
}

/// One starter set: its cover, name and line, and a check. Picked on a phone, it opens up to show
/// what it adds and scrolls so all of it is in view.
class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.set,
    required this.selected,
    required this.bestMatch,
    required this.contents,
    required this.showContents,
    required this.onTap,
  });
  final GalleryItem set;
  final bool selected;
  final bool bestMatch;
  final List<GalleryItem> contents;

  /// Whether the picked card lists [contents] (phones). The wide layout shows them in its preview.
  final bool showContents;
  final VoidCallback? onTap;

  void _reveal(BuildContext context) {
    if (!showContents) return;
    // After the card has opened up, so the whole of it fits.
    Future.delayed(AppMotion.of(context, AppMotion.duration), () {
      if (!context.mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: AppMotion.of(context, AppMotion.duration),
        curve: AppMotion.curve,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final duration = AppMotion.of(context, const Duration(milliseconds: 260));
    final radius = BorderRadius.circular(24);
    final base = scheme.surfaceContainerLow;
    final open = selected && showContents && contents.isNotEmpty;
    final description = set.description;
    return Semantics(
      selected: selected,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.07), base)
              : base,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: selected ? 0.14 : 0),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // The ring is drawn over the card, so picking doesn't move what's inside.
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: selected ? scheme.primary : context.appColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('galleryPicksSet-${set.id}'),
            borderRadius: radius,
            onTap: onTap == null
                ? null
                : () {
                    onTap!();
                    if (!selected) _reveal(context);
                  },
            child: AnimatedSize(
              duration: duration,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _SetCover(set: set, size: 64),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppSpace.xs,
                                runSpacing: AppSpace.xxs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    set.name,
                                    style: text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  if (bestMatch) const _BestMatchBadge(),
                                ],
                              ),
                              if (description != null && description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    description,
                                    maxLines: open ? null : 2,
                                    overflow: open
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    style: text.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        _Check(selected: selected),
                      ],
                    ),
                    if (open) ...[
                      const SizedBox(height: AppSpace.sm + 2),
                      _ContentsChips(items: contents),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The round check on each card: an outline, filled with a tick once picked.
class _Check extends StatelessWidget {
  const _Check({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: selected
          ? Container(
              key: const ValueKey(true),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.check, size: 16, color: scheme.onPrimary),
            )
          : Container(
              key: const ValueKey(false),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
            ),
    );
  }
}

/// "Best match", beside the set that fits what the person shared.
class _BestMatchBadge extends StatelessWidget {
  const _BestMatchBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      key: const Key('galleryPicksBestMatch'),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(7, 3, 9, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 12, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              context.l10n.galleryPicksBestMatch,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a picked set adds, on a phone: "4 skills · 2 routines · 2 apps" over a chip per item.
class _ContentsChips extends StatelessWidget {
  const _ContentsChips({required this.items});
  final List<GalleryItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: context.appColors.hairline),
        const SizedBox(height: AppSpace.sm),
        Text(
          _contentsSummary(context.l10n, items),
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpace.xs + 2),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in items)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: context.appColors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 10, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GalleryItemIcon(item: i, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          i.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The wide layout's preview of the picked set: its cover large on a soft wash of its own colors,
/// its name and line, and each thing it adds, grouped by kind.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.set,
    required this.bestMatch,
    required this.contents,
  });
  final GalleryItem? set;
  final bool bestMatch;
  final List<GalleryItem> contents;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(28);
    final set = this.set;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(color: context.appColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.duration),
          switchInCurve: AppMotion.curve,
          switchOutCurve: Curves.easeIn,
          // The outgoing set fades over the top while the panel takes the new one's height.
          layoutBuilder: (current, previous) => AnimatedSize(
            duration: AppMotion.of(context, AppMotion.duration),
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final p in previous)
                  Positioned(top: 0, left: 0, right: 0, child: p),
                ?current,
              ],
            ),
          ),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(a),
              child: child,
            ),
          ),
          child: set == null
              ? const SizedBox.shrink()
              : _PreviewBody(
                  key: ValueKey(set.id),
                  set: set,
                  bestMatch: bestMatch,
                  contents: contents,
                ),
        ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    super.key,
    required this.set,
    required this.bestMatch,
    required this.contents,
  });
  final GalleryItem set;
  final bool bestMatch;
  final List<GalleryItem> contents;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final description = set.description;
    return KeyedSubtree(
      key: Key('galleryPicksPreview-${set.id}'),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The panel cross-fades old to new (above); the new cover settles in from 1.04.
            CoverSettleIn(child: _PreviewBanner(set: set)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl + 4,
                AppSpace.lg,
                AppSpace.xl + 4,
                AppSpace.xl + 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        set.name,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (bestMatch) const _BestMatchBadge(),
                    ],
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      description,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (contents.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          l10n.galleryPicksInside,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            _contentsSummary(l10n, contents),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    LayoutBuilder(
                      builder: (context, box) {
                        // Two columns once each can hold a name comfortably.
                        final columns = box.maxWidth >= 420 ? 2 : 1;
                        final width =
                            (box.maxWidth - AppSpace.sm * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.xs,
                          children: [
                            for (final i in contents)
                              SizedBox(
                                width: width,
                                child: _ContentRow(item: i),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The picked set's cover centered on a blurred wash of itself, so the panel takes on its colors.
class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.set});
  final GalleryItem set;

  @override
  Widget build(BuildContext context) {
    final asset = galleryCoverAsset(set);
    final panel = context.colorScheme.surfaceContainerLow;
    return SizedBox(
      height: 216,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Transform.scale(
                scale: 1.4,
                child: PaintedArt(
                  seed: set.id,
                  asset: asset,
                  url: set.cover,
                  decodeWidth: 96,
                ),
              ),
            ),
            // A light veil keeps the wash soft, and its foot eases into the panel.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.6, 1],
                  colors: [
                    panel.withValues(alpha: 0.12),
                    panel.withValues(alpha: 0.2),
                    panel,
                  ],
                ),
              ),
            ),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _SetCover(set: set, size: 148, radius: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing a set adds, in the wide preview: its icon, name and kind.
class _ContentRow extends StatelessWidget {
  const _ContentRow({required this.item});
  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GalleryItemIcon(item: item, size: 34),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  galleryKindName(context.l10n, item.type),
                  maxLines: 1,
                  style: text.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three covers fanned like cards, the best fit in front, over the phone layout's title.
class _CoverFan extends StatelessWidget {
  const _CoverFan({required this.sets});

  /// Front first.
  final List<GalleryItem> sets;

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox(height: 96);
    Widget card(GalleryItem set, double size) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _SetCover(set: set, size: size),
    );
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.of(context, const Duration(milliseconds: 750)),
        curve: Curves.easeOutBack,
        builder: (context, t, _) => SizedBox(
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              for (final (i, side) in const [(1, -1.0), (2, 1.0)])
                if (i < sets.length)
                  Transform.translate(
                    offset: Offset(side * 56 * t, 8 * t),
                    child: Transform.rotate(
                      angle: side * 0.21 * t,
                      child: card(sets[i], 66),
                    ),
                  ),
              Transform.scale(
                scale: 0.9 + 0.1 * t,
                child: card(sets.first, 82),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A set's cover, cropped to a rounded square: its painted art (bundled, or the gallery's
/// `cover.webp`), or a tile in a bot's colors with its icon when it has none.
class _SetCover extends StatelessWidget {
  const _SetCover({required this.set, required this.size, this.radius});
  final GalleryItem set;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) => PaintedCover(
    size: size,
    radius: radius,
    seed: set.id,
    asset: galleryCoverAsset(set),
    url: set.cover,
    icon: lucideByName(set.icon) ?? LucideIcons.package,
  );
}

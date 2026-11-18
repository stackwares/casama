import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/lucide_names.dart';
import '../../ui/progressive_fade.dart';
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

/// The starter set that best fits what the person told About you; the first set when nothing does.
GalleryItem pickStarterSet(List<GalleryItem> sets, AboutYouView? about) {
  final text = [
    about?.about ?? '',
    about?.replyStyle ?? '',
  ].join(' ').toLowerCase();
  final words = RegExp(r'[a-z]{3,}')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toSet();
  var best = sets.first;
  var bestScore = 0;
  for (final s in sets) {
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
    if (score > bestScore ||
        (bestScore == 0 && score == 0 && s.featured && !best.featured)) {
      best = s;
      bestScore = score;
    }
  }
  return best;
}

/// "Picks for you" (D-315), after "What should bots call you?" on first run: the gallery's starter
/// sets with the one that fits pre-selected. Add this set installs it; Skip for now leaves it.
/// Either way it doesn't come back.
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
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final sets = ref.watch(gallerySetsProvider).value ?? const <GalleryItem>[];
    // Kept loaded for Add.
    ref.watch(currentOrgIdProvider);
    final about = ref.watch(aboutYouProvider).value;
    final chosen =
        sets.where((s) => s.id == _chosen).firstOrNull ??
        (sets.isEmpty ? null : pickStarterSet(sets, about));
    final statusBar = MediaQuery.paddingOf(context).top;
    return Scaffold(
      key: const Key('galleryPicksStep'),
      backgroundColor: scheme.surface,
      body: ProgressiveFade(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.xl,
                        statusBar + AppSpace.xxl,
                        AppSpace.xl,
                        AppSpace.md,
                      ),
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 36,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          l10n.galleryPicksTitle,
                          textAlign: TextAlign.center,
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          l10n.galleryPicksHelp,
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        for (final s in sets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                            child: _SetOption(
                              set: s,
                              selected: s.id == chosen?.id,
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _chosen = s.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.xl,
                      0,
                      AppSpace.xl,
                      BottomPadding.of(context, minimum: AppSpace.md),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('galleryPicksAdd'),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.onSurface,
                              foregroundColor: scheme.surface,
                              shape: const StadiumBorder(),
                              minimumSize: const Size.fromHeight(56),
                              textStyle: context.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            onPressed: _busy || chosen == null
                                ? null
                                : () => _add(chosen),
                            child: Text(l10n.galleryPicksAdd),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        TextButton(
                          key: const Key('galleryPicksSkip'),
                          onPressed: _busy ? null : _skip,
                          child: Text(
                            l10n.galleryPicksSkip,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetOption extends StatelessWidget {
  const _SetOption({
    required this.set,
    required this.selected,
    required this.onTap,
  });
  final GalleryItem set;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('galleryPicksSet-${set.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    lucideByName(set.icon) ?? LucideIcons.package,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.name,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (set.description case final d? when d.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            d,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(
                  selected ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:casama_sdk/casama_sdk.dart' show Bot, Routine;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backend.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/presets.dart';
import '../../theme/schemes.dart';
import '../../theme/wallpaper.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'gallery_cards.dart';
import 'gallery_detail_parts.dart' show galleryStatsText;

/// Something ready to send to the gallery: its kind, a name, the folder's files (besides
/// item.json, which the form fills) and the gallery item it came from, if any.
class GallerySubmitDraft {
  const GallerySubmitDraft({
    required this.type,
    required this.name,
    required this.files,
    this.remixOf,
    this.tags = const [],
  });

  /// `theme`, `scheme`, `wallpaper`, `skill`, `routine` or `bot`.
  final String type;
  final String name;
  final Map<String, String> files;
  final GalleryRef? remixOf;
  final List<String> tags;

  /// Licenses the gallery takes for this kind: looks are CC, the rest code-style licenses.
  List<String> get licenses =>
      const {'theme', 'scheme', 'wallpaper'}.contains(type)
      ? const ['CC0-1.0', 'CC-BY-4.0']
      : const ['Apache-2.0', 'MIT', 'CC0-1.0'];
}

String _json(Object? v) => const JsonEncoder.withIndent('  ').convert(v);

/// A gallery id from a name: lowercase words joined by dashes.
String gallerySlug(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.length > 40 ? slug.substring(0, 40) : slug;
}

Map<String, String> _seeds(ThemeChoice choice) => {
  'seed': hexFromColor(choice.data.light.primary),
};

Map<String, Object?> _schemeDoc(ThemeChoice choice) => {
  'light': _seeds(choice),
  'dark': {'seed': hexFromColor(choice.data.dark.primary)},
};

Map<String, Object?>? _wallpaperDoc(WallpaperSpec spec) {
  if (spec.photo != null) return null;
  return {
    'kind': spec.mesh != null ? 'mesh' : 'pattern',
    ...spec.toJson()
      ..remove('everywhere')
      ..remove('photo'),
  };
}

/// A saved theme as a gallery theme. Themes first used from the gallery credit it.
GallerySubmitDraft galleryDraftFromTheme(ThemePreset theme) {
  final choice = themeChoiceById(theme.schemeId);
  final wallpaper = _wallpaperDoc(theme.wallpaper);
  return GallerySubmitDraft(
    type: 'theme',
    name: theme.name,
    files: {
      'theme.json': _json({
        'v': 2,
        'scheme': _schemeDoc(choice),
        'headingFont': theme.headingFont,
        'bodyFont': theme.bodyFont,
        'wallpaper': ?wallpaper,
      }),
    },
    remixOf: theme.id.startsWith('gallery-')
        ? GalleryRef('theme', theme.id.substring('gallery-'.length))
        : null,
  );
}

/// The color scheme in use as a gallery scheme.
GallerySubmitDraft galleryDraftFromScheme(Appearance a, String name) {
  final id = a.schemeId;
  return GallerySubmitDraft(
    type: 'scheme',
    name: name,
    files: {'scheme.json': _json(_schemeDoc(a.scheme))},
    remixOf: id.startsWith('gallery:') && !id.startsWith('gallery:theme-')
        ? GalleryRef('scheme', id.substring('gallery:'.length))
        : null,
  );
}

/// The wallpaper in use as a gallery wallpaper (patterns and gradients only, no photos).
GallerySubmitDraft? galleryDraftFromWallpaper(WallpaperSpec spec, String name) {
  final doc = _wallpaperDoc(spec);
  if (doc == null) return null;
  return GallerySubmitDraft(
    type: 'wallpaper',
    name: name,
    files: {'wallpaper.json': _json(doc)},
  );
}

/// A workspace skill as a gallery skill (instructions only; skills with scripts can't be sent).
GallerySubmitDraft galleryDraftFromSkill(SkillView skill) {
  final front = [
    '---',
    'name: ${gallerySlug(skill.name)}',
    'description: ${skill.description.replaceAll('\n', ' ')}',
    '---',
    '',
  ].join('\n');
  final body = skill.bodyMd.trimLeft().startsWith('---')
      ? skill.bodyMd
      : '$front\n${skill.bodyMd}';
  final galleryId = skill.sourceRef['id'];
  return GallerySubmitDraft(
    type: 'skill',
    name: skill.name,
    files: {'SKILL.md': body},
    remixOf: skill.source == 'gallery' && galleryId is String
        ? GalleryRef('skill', galleryId)
        : null,
  );
}

GallerySubmitDraft galleryDraftFromRoutine(Routine routine) =>
    GallerySubmitDraft(
      type: 'routine',
      name: routine.name,
      files: {
        'routine.json': _json({
          'description': routine.name,
          'instructions_md': routine.instructionsMd,
          'schedule_cron': ?routine.scheduleCron,
        }),
      },
    );

GallerySubmitDraft galleryDraftFromBot(Bot bot) => GallerySubmitDraft(
  type: 'bot',
  name: bot.name,
  files: {
    'bot.json': _json({'description': bot.name, 'persona': bot.personaMd}),
  },
);

/// The form that sends [draft] to the gallery: name, tags and license. The server opens a pull
/// request in the person's display name (never their email). Returns the submission.
Future<GallerySubmission?> showGallerySubmit(
  BuildContext context, {
  required GallerySubmitDraft draft,
}) => showAdaptiveSheet<GallerySubmission>(
  context: context,
  dialogMaxWidth: 520,
  builder: (_) => _SubmitSheet(draft: draft),
);

class _SubmitSheet extends ConsumerStatefulWidget {
  const _SubmitSheet({required this.draft});
  final GallerySubmitDraft draft;

  @override
  ConsumerState<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends ConsumerState<_SubmitSheet> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _tags = TextEditingController(text: widget.draft.tags.join(', '));
  late var _license = widget.draft.licenses.first;
  var _busy = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 60) {
      setState(() {
        _nameError = l10n.gallerySubmitNameLength;
      });
      return;
    }
    final tags = [
      for (final t in _tags.text.split(','))
        if (gallerySlug(t).isNotEmpty) gallerySlug(t),
    ].take(6).toList();
    setState(() {
      _busy = true;
      _nameError = null;
    });
    final draft = widget.draft;
    try {
      final sub = await ref
          .read(backendProvider)
          .submitToGallery(
            type: draft.type,
            id: gallerySlug(name),
            item: {
              'name': name,
              'license': _license,
              'tags': tags,
              'version': 1,
              if (draft.remixOf != null) 'remix_of': draft.remixOf!.toJson(),
            },
            files: draft.files,
            remixOf: draft.remixOf,
          );
      if (mounted) Navigator.of(context).pop(sub);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
      showError(context, e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    return FormSheet(
      key: const Key('gallerySubmitSheet'),
      icon: LucideIcons.send,
      title: l10n.gallerySubmitTitle(galleryKindName(l10n, draft.type)),
      subtitle: l10n.gallerySubmitHelp,
      submitLabel: l10n.gallerySubmitSend,
      submitKey: const Key('gallerySubmitSend'),
      busy: _busy,
      onSubmit: _send,
      children: [
        TextField(
          key: const Key('gallerySubmitName'),
          controller: _name,
          maxLength: 60,
          decoration: InputDecoration(
            labelText: l10n.gallerySubmitName,
            errorText: _nameError,
          ),
        ),
        TextField(
          key: const Key('gallerySubmitTags'),
          controller: _tags,
          decoration: InputDecoration(
            labelText: l10n.gallerySubmitTags,
            helperText: l10n.gallerySubmitTagsHelp,
          ),
        ),
        DropdownButtonFormField<String>(
          key: const Key('gallerySubmitLicense'),
          initialValue: _license,
          decoration: InputDecoration(labelText: l10n.gallerySubmitLicense),
          items: [
            for (final lic in draft.licenses)
              DropdownMenuItem(value: lic, child: Text(lic)),
          ],
          onChanged: (v) => setState(() {
            _license = v ?? _license;
          }),
        ),
        if (draft.remixOf != null)
          Row(
            children: [
              Icon(
                LucideIcons.gitFork,
                size: 16,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  l10n.gallerySubmitRemix(draft.remixOf!.id),
                  key: const Key('gallerySubmitRemix'),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Things the person has made that could go to the gallery, to pick one.
Future<GallerySubmitDraft?> showGallerySubmitPicker(BuildContext context) =>
    showAdaptiveSheet<GallerySubmitDraft>(
      context: context,
      heightFactor: 0.8,
      dialogMaxWidth: 560,
      builder: (_) => const _SubmitPicker(),
    );

class _SubmitPicker extends ConsumerWidget {
  const _SubmitPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final themes = [
      for (final t in ref.watch(savedThemesProvider))
        if (!t.builtIn) t,
    ];
    final skills = [
      for (final s in ref.watch(skillsProvider).value ?? const <SkillView>[])
        if (s.source != 'catalog') s,
    ];
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final routines = <Routine>[
      for (final b in bots) ...?ref.watch(routinesProvider(b.id)).value,
    ];
    final wallpaper = galleryDraftFromWallpaper(
      appearance.wallpaper,
      l10n.gallerySubmitMyWallpaper,
    );
    void pick(GallerySubmitDraft d) => Navigator.of(context).pop(d);
    Widget group(String title, List<Widget> tiles) => tiles.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: title),
              GroupedCard(children: tiles),
            ],
          );
    return ListView(
      key: const Key('gallerySubmitPicker'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.xl,
      ),
      children: [
        SheetTitle(
          l10n.gallerySubmitPick,
          subtitle: l10n.gallerySubmitPickHelp,
        ),
        group(l10n.galleryLooksMine, [
          for (final t in themes)
            GroupedTile(
              key: Key('gallerySubmitTheme-${t.id}'),
              icon: galleryKindIcon('theme'),
              title: t.name,
              subtitle: l10n.galleryTypeTheme,
              onTap: () => pick(galleryDraftFromTheme(t)),
            ),
          GroupedTile(
            key: const Key('gallerySubmitScheme'),
            icon: galleryKindIcon('scheme'),
            title: appearance.scheme.name,
            subtitle: l10n.gallerySubmitCurrentScheme,
            onTap: () => pick(
              galleryDraftFromScheme(appearance, appearance.scheme.name),
            ),
          ),
          if (wallpaper != null)
            GroupedTile(
              key: const Key('gallerySubmitWallpaper'),
              icon: galleryKindIcon('wallpaper'),
              title: wallpaper.name,
              subtitle: l10n.gallerySubmitCurrentWallpaper,
              onTap: () => pick(wallpaper),
            ),
        ]),
        group(l10n.gallerySkills, [
          for (final s in skills)
            GroupedTile(
              key: Key('gallerySubmitSkill-${s.id}'),
              icon: galleryKindIcon('skill'),
              title: s.name,
              subtitle: s.description,
              onTap: () => pick(galleryDraftFromSkill(s)),
            ),
        ]),
        group(l10n.galleryKindRoutines, [
          for (final r in routines)
            GroupedTile(
              key: Key('gallerySubmitRoutine-${r.id}'),
              icon: galleryKindIcon('routine'),
              title: r.name,
              onTap: () => pick(galleryDraftFromRoutine(r)),
            ),
        ]),
        group(l10n.galleryKindBots, [
          for (final b in bots)
            GroupedTile(
              key: Key('gallerySubmitBot-${b.id}'),
              icon: galleryKindIcon('bot'),
              title: b.name,
              onTap: () => pick(galleryDraftFromBot(b)),
            ),
        ]),
      ],
    );
  }
}

/// Picks something, then sends it. Shows where it went.
Future<void> galleryStartSubmission(BuildContext context) async {
  final draft = await showGallerySubmitPicker(context);
  if (draft == null || !context.mounted) return;
  final sub = await showGallerySubmit(context, draft: draft);
  if (sub != null && context.mounted) {
    showSuccess(context, context.l10n.gallerySubmitted);
  }
}

final gallerySubmissionsProvider =
    FutureProvider.autoDispose<List<GallerySubmission>>(
      (ref) => ref.watch(backendProvider).gallerySubmissions(),
    );

final galleryMyItemsProvider = FutureProvider.autoDispose<List<GalleryMyItem>>(
  (ref) => ref.watch(backendProvider).galleryMyItems(),
);

String gallerySubmissionStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'merged' => l10n.gallerySubmissionMerged,
      'closed' => l10n.gallerySubmissionClosed,
      'failed' => l10n.gallerySubmissionFailed,
      _ => l10n.gallerySubmissionOpen,
    };

/// My submissions: what the person sent and where each pull request stands, and their items
/// in the gallery with the numbers only an author sees.
class GallerySubmissionsScreen extends ConsumerWidget {
  const GallerySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final subs = ref.watch(gallerySubmissionsProvider);
    final mine = ref.watch(galleryMyItemsProvider).value ?? const [];
    final list = subs.value ?? const <GallerySubmission>[];
    return SubPage(
      title: l10n.gallerySubmissionsTitle,
      children: [
        Text(
          l10n.gallerySubmissionsHelp,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('gallerySubmitStart'),
            onPressed: () async {
              await galleryStartSubmission(context);
              ref.invalidate(gallerySubmissionsProvider);
            },
            icon: const Icon(LucideIcons.send, size: 18),
            label: Text(l10n.gallerySubmitStart),
          ),
        ),
        if (mine.isNotEmpty) ...[
          SectionHeader(title: l10n.galleryMyItems),
          GroupedCard(
            children: [
              for (final i in mine)
                GroupedTile(
                  key: Key('galleryMyItem-${i.type}-${i.id}'),
                  icon: galleryKindIcon(i.type),
                  title: i.name,
                  subtitle: [
                    galleryKindName(l10n, i.type),
                    ?galleryStatsText(l10n, i.stats),
                    if (i.reportsOpen > 0)
                      l10n.galleryReportsOpen(i.reportsOpen),
                  ].join(' · '),
                  onTap: () =>
                      context.push('/settings/gallery/${i.type}/${i.id}'),
                ),
            ],
          ),
        ],
        SectionHeader(title: l10n.gallerySubmissionsSent),
        if (subs.isLoading && list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpace.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (subs.hasError && list.isEmpty)
          EmptyState(
            icon: LucideIcons.cloudOff,
            message: l10n.gallerySubmissionsError,
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(gallerySubmissionsProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.retry),
            ),
          )
        else if (list.isEmpty)
          EmptyState(
            icon: LucideIcons.send,
            message: l10n.gallerySubmissionsEmpty,
          )
        else
          GroupedCard(
            children: [
              for (final s in list)
                GroupedTile(
                  key: Key('gallerySubmission-${s.id}'),
                  icon: galleryKindIcon(s.type),
                  title: s.name ?? s.itemKey,
                  subtitle: [
                    gallerySubmissionStatus(l10n, s.status),
                    if (s.createdAt != null)
                      s.createdAt!.toLocal().formattedDate(context),
                  ].join(' · '),
                  showChevron: s.prUrl != null,
                  onTap: s.prUrl == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(s.prUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

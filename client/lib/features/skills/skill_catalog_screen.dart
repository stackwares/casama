import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../chat/widgets/chat_markdown.dart';
import 'skill_visuals.dart';
import '../../core/analytics.dart';

/// Settings → Skills → Skill catalog (D-104): the bundled skills on their own page, grouped by
/// category, with search, a detail sheet and install to the workspace or one bot.

final skillCatalogProvider = FutureProvider.autoDispose<SkillCatalog>(
  (ref) => ref.watch(backendProvider).skillCatalog(),
);

/// Opens the catalog page (a route in the app; a plain push where there is no router).
Future<void> openSkillCatalog(BuildContext context) async {
  if (GoRouter.maybeOf(context) != null) {
    await context.push('/settings/skills/catalog');
  } else {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/settings/skills/catalog'),
        builder: (_) => const SkillCatalogScreen(),
      ),
    );
  }
}

/// Where a catalog skill is installed: null is the whole workspace, otherwise bot ids.
Set<String?> catalogInstallTargets(CatalogSkill s, List<SkillView> installed) =>
    {
      for (final v in installed)
        if ((v.source == 'catalog' && v.sourceRef['id'] == s.id) ||
            v.name == s.name)
          v.botId,
    };

/// The icon and tint for an installed skill: its catalog icon when it came from the catalog.
(IconData, Color) installedSkillLook(
  BuildContext context,
  SkillView v,
  SkillCatalog? catalog,
) {
  final fromCatalog = v.source == 'catalog'
      ? catalog?.items.where((c) => c.id == v.sourceRef['id']).firstOrNull
      : null;
  final category = fromCatalog?.category ?? v.category;
  return (
    skillIcon(icon: fromCatalog?.icon, category: category),
    skillCategoryColor(context, category),
  );
}

class SkillCatalogScreen extends ConsumerStatefulWidget {
  const SkillCatalogScreen({super.key});

  @override
  ConsumerState<SkillCatalogScreen> createState() => _SkillCatalogScreenState();
}

class _SkillCatalogScreenState extends ConsumerState<SkillCatalogScreen> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(skillCatalogProvider);
    return SubPage(
      title: l10n.skillCatalog,
      subtitle: l10n.skillCatalogSubtitle,
      body: AsyncView(
        value: catalog,
        onRetry: () => ref.invalidate(skillCatalogProvider),
        loading: const _CatalogSkeleton(),
        data: (cat) => PageColumn(
          maxWidth: kWidePageMaxWidth,
          children: _browse(context, cat),
        ),
      ),
    );
  }

  List<Widget> _browse(BuildContext context, SkillCatalog cat) {
    final l10n = context.l10n;
    final installed = ref.watch(skillsProvider).value ?? const <SkillView>[];
    // Loaded up front, so Install knows which bots it could go to.
    ref.watch(botsProvider);
    final q = _search.text.trim().toLowerCase();
    final categories = [
      for (final c in cat.categories)
        if (cat.items.any((s) => s.category == c)) c,
    ];
    final shown = [
      for (final s in cat.items)
        if ((_category == null || s.category == _category) &&
            (q.isEmpty ||
                '${s.name} ${skillTitle(s.name)} ${s.description} ${skillCategoryLabel(context, s.category)}'
                    .toLowerCase()
                    .contains(q)))
          s,
    ];
    final filtering = q.isNotEmpty || _category != null;
    Widget grid(List<CatalogSkill> items) => _SkillGrid(
      children: [
        for (final s in items)
          _SkillTile(
            skill: s,
            targets: catalogInstallTargets(s, installed),
            onOpen: () => _openDetail(s),
            onInstall: () => installCatalogSkill(context, ref, s),
          ),
      ],
    );
    return [
        TextField(
          key: const Key('catalogSearch'),
          controller: _search,
          decoration: InputDecoration(
            hintText: l10n.searchSkills,
            prefixIcon: const Icon(LucideIcons.search, size: 20),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.sm),
        PageBleed(child: SizedBox(
          height: 38,
          child: EdgeFade(child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                  child: RevealWhenSelected(selected: _category == c, child: ChoiceChip(
                    key: Key('category-${c ?? 'all'}'),
                    showCheckmark: false,
                    avatar: c == null
                        ? null
                        : Icon(
                            skillCategoryIcon(c),
                            size: 16,
                            color: skillCategoryColor(context, c),
                          ),
                    selected: _category == c,
                    label: Text(
                      c == null ? l10n.all : skillCategoryLabel(context, c),
                    ),
                    onSelected: (_) => setState(() => _category = c),
                  )),
                ),
            ],
          )),
        )),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
            child: Text(
              l10n.noResults,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (filtering) ...[
          SectionHeader(title: l10n.skillCount(shown.length)),
          grid(shown),
        ] else
          // Browsing: one section per category, in the catalog's order.
          for (final c in categories) ...[
            SectionHeader(
              key: Key('section-$c'),
              title: skillCategoryLabel(context, c),
              count: shown.where((s) => s.category == c).length.humanizedCount(context.l10n.localeName),
            ),
            grid([
              for (final s in shown)
                if (s.category == c) s,
            ]),
          ],
        const SizedBox(height: AppSpace.xl),
    ];
  }

  Future<void> _openDetail(CatalogSkill s) => showAdaptiveSheet<void>(
    context: context,
    heightFactor: 0.85,
    dialogMaxWidth: 640,
    builder: (_) => _SkillDetail(skill: s),
  );
}

/// Installs [s], asking where when there is more than one place it could go.
Future<void> installCatalogSkill(
  BuildContext context,
  WidgetRef ref,
  CatalogSkill s,
) async {
  final l10n = context.l10n;
  final org = ref.read(currentOrgProvider);
  if (org == null) return;
  final installed = ref.read(skillsProvider).value ?? const <SkillView>[];
  final taken = catalogInstallTargets(s, installed);
  final bots = ref.read(botsProvider).value ?? const <Bot>[];
  final open = <String?>[
    if (!taken.contains(null)) null,
    for (final b in bots)
      if (!taken.contains(b.id)) b.id,
  ];
  if (open.isEmpty) {
    showMessage(context, l10n.skillAlreadyEverywhere);
    return;
  }
  // No bots yet: the workspace is the only place, so skip the question.
  final String? botId;
  if (bots.isEmpty) {
    botId = null;
  } else {
    final picked = await showAdaptiveSheet<_Target>(
      context: context,
      contentPadsBottom: true,
      builder: (_) => _TargetPicker(skill: s, bots: bots, taken: taken),
    );
    if (picked == null) return;
    botId = picked.botId;
  }
  if (!context.mounted) return;
  final ok = await runGuarded(context, () async {
    await ref
        .read(backendProvider)
        .installCatalogSkill(org.id, s.id, botId: botId);
    return true;
  });
  if (ok == true && context.mounted) {
    ref.invalidate(skillsProvider);
    Analytics.log('skill_installed', {'source': 'catalog', 'skill_id': s.name});
    showSuccess(context, l10n.skillInstalled(skillTitle(s.name)));
  }
}

/// One to four columns, as wide as the window allows.
class _SkillGrid extends StatelessWidget {
  const _SkillGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth > 1120
          ? 4
          : (c.maxWidth > 820 ? 3 : (c.maxWidth > 560 ? 2 : 1));
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: AppSpace.sm,
        crossAxisSpacing: AppSpace.sm,
        // Room for a title and two lines of description; a single column needs less.
        childAspectRatio:
            (c.maxWidth - (columns - 1) * AppSpace.sm) /
            columns /
            (columns == 1 ? 96 : 104),
        children: children,
      );
    },
  );
}

/// The catalog still loading: the search field, the category chips, then category sections of
/// skill tiles in the same grid.
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      maxWidth: kWidePageMaxWidth,
      children: [
        SkeletonBone(height: 52, radius: 14),
        SizedBox(height: AppSpace.sm),
        SizedBox(
          height: 38,
          child: Row(
            spacing: AppSpace.xs,
            children: [
              SkeletonBone(width: 48, height: 32, radius: 8),
              SkeletonBone(width: 96, height: 32, radius: 8),
              SkeletonBone(width: 84, height: 32, radius: 8),
              SkeletonBone(width: 104, height: 32, radius: 8),
            ],
          ),
        ),
        SkeletonSectionHeader(width: 110),
        _SkillGridSkeleton(count: 4),
        SkeletonSectionHeader(width: 90),
        _SkillGridSkeleton(count: 4),
      ],
    );
  }
}

/// A [_SkillGrid] of [_SkillTile]s still loading: icon tile, title, two lines and Install.
class _SkillGridSkeleton extends StatelessWidget {
  const _SkillGridSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.appColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
        child: Row(
          children: [
            const SkeletonBone(width: 48, height: 48, radius: AppRadius.icon + 2),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonText(style: text.titleSmall, widthFactor: 0.5),
                  const SizedBox(height: 2),
                  SkeletonText(style: text.bodySmall?.copyWith(height: 1.3), lines: 2, widthFactor: 0.8),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            const SizedBox(width: 72, height: 40, child: Center(child: SkeletonBone(width: 44, height: 12))),
          ],
        ),
      ),
    );
    return _SkillGrid(children: [for (var i = 0; i < count; i++) tile]);
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.targets,
    required this.onOpen,
    required this.onInstall,
  });
  final CatalogSkill skill;
  final Set<String?> targets;
  final VoidCallback onOpen;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = skillCategoryColor(context, skill.category);
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: context.appColors.hairline),
      ),
      color: context.isDark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLowest,
      child: InkWell(
        key: Key('catalog-${skill.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.xs,
            AppSpace.sm,
          ),
          child: Row(
            children: [
              SkillIconTile(
                icon: skillIcon(icon: skill.icon, category: skill.category),
                color: color,
                size: 48,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skillTitle(skill.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skill.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              targets.isEmpty
                  ? TextButton(
                      key: Key('install-${skill.id}'),
                      onPressed: onInstall,
                      child: Text(context.l10n.install),
                    )
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpace.sm,
                      ),
                      child: Tooltip(
                        message: context.l10n.skillInstalledBadge,
                        child: Icon(
                          LucideIcons.circleCheck,
                          key: Key('installed-${skill.id}'),
                          size: 20,
                          color: context.appColors.positive,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Everything about one catalog skill, with install.
class _SkillDetail extends ConsumerWidget {
  const _SkillDetail({required this.skill});
  final CatalogSkill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final installed = ref.watch(skillsProvider).value ?? const <SkillView>[];
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final targets = catalogInstallTargets(skill, installed);
    final names = [
      if (targets.contains(null)) l10n.wholeWorkspace,
      for (final b in bots)
        if (targets.contains(b.id)) b.name,
    ];
    final everywhere =
        targets.contains(null) && bots.every((b) => targets.contains(b.id));
    final color = skillCategoryColor(context, skill.category);
    final body = _bodyOf(skill.skillMd);
    return FormSheet(
      icon: skillIcon(icon: skill.icon, category: skill.category),
      iconColor: color,
      title: skillTitle(skill.name),
      subtitle: skill.description,
      submitLabel: everywhere ? l10n.skillInstalledBadge : l10n.install,
      submitKey: const Key('detailInstall'),
      cancelLabel: MaterialLocalizations.of(context).closeButtonLabel,
      onSubmit: everywhere
          ? null
          : () => installCatalogSkill(context, ref, skill),
      children: [
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            Chip(
              avatar: Icon(
                skillCategoryIcon(skill.category),
                size: 16,
                color: color,
              ),
              label: Text(skillCategoryLabel(context, skill.category)),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text(
                '/${skill.name}',
                style: AppText.mono.copyWith(fontSize: 13),
              ),
              visualDensity: VisualDensity.compact,
            ),
            if (skill.files.isNotEmpty)
              Chip(
                avatar: const Icon(LucideIcons.files, size: 16),
                label: Text(l10n.skillFiles(skill.files.length)),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (names.isNotEmpty)
          FormNote(
            l10n.skillInstalledFor(names.join(', ')),
            icon: LucideIcons.circleCheck,
            color: context.appColors.positive,
          ),
        FormNote(l10n.skillUseHint(skill.name), icon: LucideIcons.sparkles),
        if (body.isNotEmpty) ...[
          Text(l10n.skillInstructions, style: context.textTheme.titleSmall),
          Container(
            key: const Key('skillInstructions'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: context.appColors.codeBackground,
              borderRadius: AppRadius.tileAll,
            ),
            child: ChatMarkdown(data: body),
          ),
        ],
        if (skill.files.isNotEmpty)
          for (final f in skill.files)
            Row(
              spacing: AppSpace.xs,
              children: [
                Icon(
                  LucideIcons.fileCode,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(f, style: AppText.mono.copyWith(fontSize: 13)),
                ),
              ],
            ),
      ],
    );
  }

  /// The instructions without the front matter.
  static String _bodyOf(String? md) {
    if (md == null) return '';
    final m = RegExp(r'^﻿?---\r?\n[\s\S]*?\r?\n---\r?\n?').firstMatch(md);
    return (m == null ? md : md.substring(m.end)).trim();
  }
}

/// The picked install target; [botId] null is the whole workspace.
class _Target {
  const _Target(this.botId);
  final String? botId;
}

class _TargetPicker extends StatelessWidget {
  const _TargetPicker({
    required this.skill,
    required this.bots,
    required this.taken,
  });
  final CatalogSkill skill;
  final List<Bot> bots;
  final Set<String?> taken;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget row({
      required Key key,
      required IconData icon,
      required String title,
      required String? botId,
    }) {
      final done = taken.contains(botId);
      return GroupedTile(
        key: key,
        icon: icon,
        title: title,
        subtitle: done ? l10n.skillInstalledBadge : null,
        iconColor: done ? context.colorScheme.onSurfaceVariant : null,
        trailing: done
            ? Icon(
                LucideIcons.check,
                size: 18,
                color: context.appColors.positive,
              )
            : null,
        onTap: done ? null : () => Navigator.pop(context, _Target(botId)),
      );
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            Text(
              l10n.installSkillFor(skillTitle(skill.name)),
              style: context.textTheme.titleLarge,
            ),
            GroupedCard(
              children: [
                row(
                  key: const Key('installTarget-workspace'),
                  icon: LucideIcons.building2,
                  title: l10n.wholeWorkspace,
                  botId: null,
                ),
                for (final b in bots)
                  row(
                    key: Key('installTarget-${b.id}'),
                    icon: LucideIcons.bot,
                    title: b.name,
                    botId: b.id,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

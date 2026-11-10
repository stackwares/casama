import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bot_avatar.dart';

/// The Lucide icon a persona names (kebab-case, from the server's templates).
IconData personaIcon(String? name) => switch (name) {
  'briefcase' => LucideIcons.briefcase,
  'mail-check' => LucideIcons.mailCheck,
  'radar' => LucideIcons.radar,
  'user-search' => LucideIcons.userSearch,
  'receipt' => LucideIcons.receipt,
  'network' => LucideIcons.network,
  'newspaper' => LucideIcons.newspaper,
  'life-buoy' => LucideIcons.lifeBuoy,
  'handshake' => LucideIcons.handshake,
  'kanban' => LucideIcons.kanban,
  'activity' => LucideIcons.activity,
  'search' => LucideIcons.search,
  'chart-column' => LucideIcons.chartColumn,
  'graduation-cap' => LucideIcons.graduationCap,
  'code' => LucideIcons.code,
  'bug' => LucideIcons.bug,
  'palette' => LucideIcons.palette,
  'pen-line' => LucideIcons.penLine,
  'megaphone' => LucideIcons.megaphone,
  'calendar-heart' => LucideIcons.calendarHeart,
  'languages' => LucideIcons.languages,
  'plane' => LucideIcons.plane,
  'piggy-bank' => LucideIcons.piggyBank,
  'dumbbell' => LucideIcons.dumbbell,
  'chef-hat' => LucideIcons.chefHat,
  _ => LucideIcons.sparkles,
};

String _categoryLabel(BuildContext context, TemplateCategoryEnum? c) {
  final l10n = context.l10n;
  return switch (c) {
    TemplateCategoryEnum.work => l10n.personaWork,
    TemplateCategoryEnum.research => l10n.personaResearch,
    TemplateCategoryEnum.build => l10n.personaBuild,
    TemplateCategoryEnum.create => l10n.personaCreate,
    TemplateCategoryEnum.life => l10n.personaLife,
    _ => l10n.personaOther,
  };
}

/// Opens the persona gallery. Returns the chosen template, or [PersonaChoice.blank] for a blank
/// bot; null when dismissed.
Future<PersonaChoice?> showPersonaGallery(BuildContext context, {String? selected, bool allowBlank = true}) =>
    showAdaptiveSheet<PersonaChoice>(
      context: context,
      heightFactor: 0.9,
      dialogMaxWidth: 760,
      builder: (_) => _PersonaGallery(selected: selected, allowBlank: allowBlank),
    );

/// What the gallery returns: a template, or none for a blank bot.
class PersonaChoice {
  const PersonaChoice(this.template);
  static const blank = PersonaChoice(null);
  final Template? template;
}

/// Starter personas (instructions, skills, routines, a mascot) shown as a field that opens a
/// searchable gallery; null means a blank bot.
class TemplatePicker extends ConsumerWidget {
  const TemplatePicker({super.key, required this.selected, required this.onChanged});
  final String? selected;
  final void Function(Template? template) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final templates = ref.watch(templatesProvider).value ?? const <Template>[];
    if (templates.isEmpty) return const SizedBox.shrink();
    Template? current;
    for (final t in templates) {
      if (t.id == selected) current = t;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.startFrom, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.xs),
        Material(
          color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            side: BorderSide(color: current == null ? context.appColors.hairline : scheme.primary.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('personaPicker'),
            onTap: () async {
              final choice = await showPersonaGallery(context, selected: selected);
              if (choice != null) onChanged(choice.template);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: Row(
                children: [
                  _PersonaIcon(template: current, size: 44),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current?.name ?? l10n.blankBot, style: context.textTheme.titleSmall),
                        Text(
                          current == null
                              ? l10n.blankBotHelp
                              : [
                                  current.description,
                                  if (current.routines.isNotEmpty) l10n.templateIncludesRoutines(current.routines.map((r) => r.name).join(', ')),
                                ].join(' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(l10n.browse, style: context.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                  Icon(LucideIcons.chevronRight, size: 18, color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonaIcon extends StatelessWidget {
  const _PersonaIcon({required this.template, this.size = 44});
  final Template? template;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final t = template;
    if (t?.mascot != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          BotAvatar(name: t!.name, avatar: 'mascot:${t.mascot}', size: size, animate: false),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(personaIcon(t.icon), size: size * 0.22, color: scheme.onPrimary),
            ),
          ),
        ],
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(t == null ? LucideIcons.filePlus2 : personaIcon(t.icon), size: size * 0.45, color: scheme.primary),
    );
  }
}

class _PersonaGallery extends ConsumerStatefulWidget {
  const _PersonaGallery({required this.selected, required this.allowBlank});
  final String? selected;
  final bool allowBlank;

  @override
  ConsumerState<_PersonaGallery> createState() => _PersonaGalleryState();
}

class _PersonaGalleryState extends ConsumerState<_PersonaGallery> {
  final _search = TextEditingController();
  TemplateCategoryEnum? _category;
  Template? _preview;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final all = ref.watch(templatesProvider).value ?? const <Template>[];
    final q = _search.text.trim().toLowerCase();
    final shown = [
      for (final t in all)
        if ((_category == null || t.category == _category) &&
            (q.isEmpty || '${t.name} ${t.description} ${t.persona ?? ''}'.toLowerCase().contains(q)))
          t,
    ];
    final categories = {for (final t in all) t.category}.whereType<TemplateCategoryEnum>().toList();
    final preview = _preview;
    if (preview != null) return _Preview(template: preview, onBack: () => setState(() => _preview = null));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.choosePersona, style: context.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(l10n.choosePersonaHelp, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpace.md),
          TextField(
            key: const Key('personaSearch'),
            controller: _search,
            decoration: InputDecoration(hintText: l10n.searchPersonas, prefixIcon: const Icon(LucideIcons.search, size: 20)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in [null, ...categories])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: ChoiceChip(
                      key: Key('personaCategory-${c?.name ?? 'all'}'),
                      showCheckmark: false,
                      selected: _category == c,
                      label: Text(c == null ? l10n.familyAll : _categoryLabel(context, c)),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth > 560 ? 2 : 1;
                final tiles = <Widget>[
                  if (widget.allowBlank && q.isEmpty && _category == null)
                    _GalleryTile(
                      key: const Key('template-blank'),
                      template: null,
                      selected: widget.selected == null,
                      onTap: () => Navigator.pop(context, PersonaChoice.blank),
                    ),
                  for (final t in shown)
                    _GalleryTile(
                      key: Key('template-${t.id}'),
                      template: t,
                      selected: widget.selected == t.id,
                      onTap: () => Navigator.pop(context, PersonaChoice(t)),
                      onPreview: () => setState(() => _preview = t),
                    ),
                ];
                if (tiles.isEmpty) {
                  return Center(child: Text(l10n.noPersonasFound, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpace.sm,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisExtent: 104,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (_, i) => tiles[i],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({super.key, required this.template, required this.selected, required this.onTap, this.onPreview});
  final Template? template;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final t = template;
    return Material(
      color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: selected ? scheme.primary : context.appColors.hairline, width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
          child: Row(
            children: [
              _PersonaIcon(template: t, size: 48),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(t?.name ?? l10n.blankBot, style: context.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                        if (t != null && t.routines.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: t.routines.map((r) => r.name).join(', '),
                            child: Icon(LucideIcons.alarmClock, size: 14, color: scheme.tertiary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t?.description ?? l10n.blankBotHelp,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onPreview != null)
                IconButton(
                  key: Key('templatePreview-${t!.id}'),
                  tooltip: l10n.previewPersona,
                  icon: Icon(LucideIcons.eye, size: 18, color: scheme.onSurfaceVariant),
                  onPressed: onPreview,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A persona's full instructions, what it comes with, and things to ask it.
class _Preview extends StatelessWidget {
  const _Preview({required this.template, required this.onBack});
  final Template template;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final t = template;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xs, AppSpace.lg, 0),
          child: Row(
            children: [
              IconButton(tooltip: MaterialLocalizations.of(context).backButtonTooltip, icon: const Icon(LucideIcons.arrowLeft), onPressed: onBack),
              const SizedBox(width: AppSpace.xs),
              _PersonaIcon(template: t, size: 40),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(t.name, style: context.textTheme.headlineSmall)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
            children: [
              Text(t.description, style: context.textTheme.bodyLarge),
              const SizedBox(height: AppSpace.md),
              Text(l10n.personaInstructions, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.xs),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: context.appColors.codeBackground,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border.all(color: context.appColors.hairline),
                ),
                child: SelectableText(t.persona ?? '', style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
              if (t.skills.isNotEmpty || t.routines.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final s in t.skills) Chip(avatar: const Icon(LucideIcons.bookOpen, size: 14), label: Text(s)),
                    for (final r in t.routines) Chip(avatar: const Icon(LucideIcons.alarmClock, size: 14), label: Text(r.name)),
                  ],
                ),
              ],
              if ((t.starters ?? const []).isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text(l10n.personaTryAsking, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppSpace.xs),
                for (final s in t.starters!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(LucideIcons.messageCircle, size: 16, color: scheme.primary),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(child: Text(s, style: context.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: FilledButton.icon(
            key: const Key('usePersona'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context, PersonaChoice(t)),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.usePersona(t.name)),
          ),
        ),
      ],
    );
  }
}

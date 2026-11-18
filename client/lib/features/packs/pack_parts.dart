import 'package:casama_sdk/casama_sdk.dart'
    show PackPreview, PackItemKind, PackReach, PluginServerInfoTypeEnum, PackLookPreviewTypeEnum;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/display_text.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../integrations/app_logo.dart';
import '../skills/skill_visuals.dart';
import 'pack_logic.dart';

/// "Reviewed", or "Not reviewed by Casama" in the warning color.
class PackReviewBadge extends StatelessWidget {
  const PackReviewBadge({super.key, required this.reviewed, this.compact = false});
  final bool reviewed;

  /// Cards show only the Reviewed badge; the detail shows both.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!reviewed && compact) return const SizedBox.shrink();
    final scheme = context.colorScheme;
    final color = reviewed ? scheme.primary : scheme.error;
    return DecoratedBox(
      key: Key(reviewed ? 'packReviewed' : 'packNotReviewed'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(reviewed ? LucideIcons.badgeCheck : LucideIcons.shieldAlert, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              reviewed ? l10n.packReviewed : l10n.packNotReviewed,
              style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top of a pack's detail: icon, name, summary, who made it and where it lives.
class PackHeader extends StatelessWidget {
  const PackHeader({super.key, required this.preview});
  final PackPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = preview;
    final muted = context.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkillIconTile(icon: packIcon(p.icon), color: context.colorScheme.primary, size: 52),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(p.title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (p.summary.isNotEmpty) Text(p.summary, style: context.textTheme.bodyMedium),
              Text(
                [
                  if (p.author case final a? when a.isNotEmpty) l10n.galleryBy(a),
                  packSourceLine(l10n, p.source_, p.commit),
                  if (p.version case final v? when v.isNotEmpty) v,
                ].where((s) => s.isNotEmpty).join(' · '),
                style: context.textTheme.labelSmall?.copyWith(color: muted),
              ),
              PackReviewBadge(reviewed: p.reviewed),
            ],
          ),
        ),
      ],
    );
  }
}

/// One thing a pack adds, as the detail and the wizard list it.
class PackEntry {
  const PackEntry({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.details,
    this.leading,
  });
  final PackItemKind kind;

  /// The id the server's `skip` reads (a skill's name, a look's `type/id`, `tools`).
  final String id;
  final String title;
  final String? subtitle;

  /// Full instructions, one tap away.
  final String? details;
  final Widget? leading;

  String get key => '${kind.value}:$id';
}

/// Everything in a preview, grouped by kind, in the order the server installs them.
Map<PackItemKind, List<PackEntry>> packEntries(BuildContext context, PackPreview p) {
  final l10n = context.l10n;
  return {
    PackItemKind.bot: [
      for (final b in p.bots)
        PackEntry(
          kind: PackItemKind.bot,
          id: b.id,
          title: b.name,
          subtitle: b.description.isEmpty ? null : b.description,
          details: b.persona.isEmpty ? null : b.persona,
        ),
    ],
    PackItemKind.skill: [
      for (final s in p.skills)
        PackEntry(
          kind: PackItemKind.skill,
          id: s.name,
          title: s.name,
          subtitle: [
            if (s.description.isNotEmpty) s.description,
            if (s.scope.value == 'workspace') l10n.packSkillForWorkspace,
            if (s.runsScripts) l10n.packSkillRunsScripts,
          ].join(' · '),
        ),
    ],
    PackItemKind.routine: [
      for (final r in p.routines)
        PackEntry(
          kind: PackItemKind.routine,
          id: r.id,
          title: r.name,
          subtitle: [
            if (r.description.isNotEmpty) r.description,
            l10n.packRoutineRuns(r.runsPerWeek.round()),
            if (r.bot case final b? when b.isNotEmpty) p.bots.where((x) => x.id == b).firstOrNull?.name ?? b,
          ].join(' · '),
          details: r.instructionsMd.isEmpty ? null : r.instructionsMd,
        ),
    ],
    PackItemKind.app: [
      for (final a in p.apps)
        PackEntry(
          kind: PackItemKind.app,
          id: a.id,
          title: a.name,
          subtitle: [if (a.description.isNotEmpty) a.description, l10n.packAppHost(a.host)].join(' · '),
          leading: AppLogo(appId: a.id, name: a.name, color: a.color, size: 28),
        ),
    ],
    PackItemKind.tools: [
      if (p.servers.isNotEmpty)
        PackEntry(
          kind: PackItemKind.tools,
          id: 'tools',
          title: p.servers.map((s) => s.key).join(', '),
          subtitle: [
            for (final s in p.servers)
              s.type == PluginServerInfoTypeEnum.stdio
                  ? l10n.pluginStdio([s.command.orPlaceholder(), ...s.args].join(' '))
                  : l10n.packToolRemote(s.url.orPlaceholder()),
          ].join('\n'),
        ),
    ],
    PackItemKind.include: [
      for (final i in p.includes)
        PackEntry(
          kind: PackItemKind.include,
          id: i.url ?? '${i.type}/${i.id ?? ''}',
          title: i.name,
          subtitle: i.found ? i.type : '${i.type} · ${l10n.packIncludeMissing}',
        ),
    ],
    PackItemKind.look: [
      for (final k in p.looks)
        PackEntry(
          kind: PackItemKind.look,
          id: '${k.type.value}/${k.id}',
          title: k.name,
          subtitle: switch (k.type) {
            PackLookPreviewTypeEnum.theme => l10n.galleryTypeTheme,
            PackLookPreviewTypeEnum.scheme => l10n.galleryTypeScheme,
            PackLookPreviewTypeEnum.wallpaper => l10n.galleryTypeWallpaper,
          },
        ),
    ],
  };
}

/// What a pack adds, grouped by kind. With [skipped] and [onToggle] each row has a checkbox.
class PackContentsList extends StatelessWidget {
  const PackContentsList({super.key, required this.preview, this.skipped, this.onToggle});
  final PackPreview preview;
  final Set<String>? skipped;
  final void Function(PackEntry entry, bool on)? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = packEntries(context, preview);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: kind, value: entries) in groups.entries)
          if (entries.isNotEmpty) ...[
            SectionHeader(title: packKindTitle(l10n, kind), count: '${entries.length}'),
            GroupedCard(children: [for (final e in entries) _row(context, e)]),
          ],
      ],
    );
  }

  Widget _row(BuildContext context, PackEntry e) {
    final skipped = this.skipped;
    final toggle = onToggle;
    final on = skipped == null || !skipped.contains(e.key);
    final details = e.details;
    final trailing = toggle == null
        ? null
        : Checkbox(key: Key('packItem-${e.key}'), value: on, onChanged: (v) => toggle(e, v ?? false));
    if (details != null) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('packEntry-${e.key}'),
          leading: e.leading ?? Icon(packKindIcon(e.kind), size: 20),
          title: Text(e.title),
          subtitle: e.subtitle == null || e.subtitle!.isEmpty ? null : Text(e.subtitle!),
          trailing: trailing,
          childrenPadding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [SelectableText(details, style: context.textTheme.bodySmall)],
        ),
      );
    }
    return GroupedTile(
      key: Key('packEntry-${e.key}'),
      icon: packKindIcon(e.kind),
      leading: e.leading,
      title: e.title,
      subtitle: e.subtitle == null || e.subtitle!.isEmpty ? null : e.subtitle,
      trailing: trailing,
      onTap: toggle == null ? null : () => toggle(e, !on),
    );
  }
}

/// What a pack can reach, with the warning for packs Casama hasn't reviewed.
class PackReachCard extends StatelessWidget {
  const PackReachCard({super.key, required this.reach, required this.reviewed, this.warnings = const []});
  final PackReach reach;
  final bool reviewed;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = context.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        GroupedCard(
          key: const Key('packReach'),
          children: [for (final r in packReachRows(l10n, reach)) GroupedTile(icon: r.icon, title: r.text)],
        ),
        Text(
          l10n.packReachHelp,
          style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
        if (!reviewed)
          FormNote(
            l10n.packUnreviewedWarning,
            key: const Key('packUnreviewedWarning'),
            icon: LucideIcons.shieldAlert,
            color: error,
          ),
        for (final w in warnings) FormNote(w, icon: LucideIcons.triangleAlert, color: error),
      ],
    );
  }
}

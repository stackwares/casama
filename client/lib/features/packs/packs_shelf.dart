import 'package:casama_sdk/casama_sdk.dart' show GalleryPack, GalleryPackKindEnum;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/edge_fade.dart';
import '../skills/skill_visuals.dart';
import 'pack_logic.dart';
import 'pack_parts.dart';
import 'pack_preview_screen.dart';

/// The Packs shelf on the gallery page (docs/PLUGINS-AND-PACKS-PLAN.md B.9): reviewed packs from
/// the plugin directory and starter sets, featured first. Nothing shows while it loads, when the
/// gallery is offline, or when it has none. Starter sets open the existing set install.
class PacksShelf extends ConsumerWidget {
  const PacksShelf({super.key, required this.side, required this.width, required this.onOpenSet});
  final double side;
  final double width;
  final void Function(String id) onOpenSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final packs = ref.watch(galleryPacksProvider).value ?? const <GalleryPack>[];
    if (packs.isEmpty) return const SizedBox.shrink();
    final cardWidth = (width * 0.84).clamp(260.0, 320.0);
    void open(GalleryPack p) {
      if (p.kind == GalleryPackKindEnum.set_) {
        onOpenSet(p.id);
      } else {
        context.push(packPreviewLocation(galleryId: p.id));
      }
    }

    return Column(
      key: const Key('packsShelf'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: SectionHeader(key: const Key('galleryRow-packs'), title: l10n.packsShelfTitle),
        ),
        EdgeFade(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, p) in packs.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.sm),
                  SizedBox(
                    width: cardWidth,
                    child: PackCard(pack: p, onTap: () => open(p)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A card on the Packs shelf: icon, name, Reviewed, one line about it, and what it holds.
class PackCard extends StatelessWidget {
  const PackCard({super.key, required this.pack, required this.onTap});
  final GalleryPack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final p = pack;
    final c = p.contents;
    final contents = p.kind == GalleryPackKindEnum.set_
        ? [
            l10n.packStarterSet,
            if (p.setItems case final items? when items.isNotEmpty) l10n.packCountItems(items.length),
          ].join(' · ')
        : c == null
        ? ''
        : packContentsLine(
            l10n,
            bots: c.bots,
            skills: c.skills,
            routines: c.routines,
            apps: c.apps,
            looks: c.looks,
            tools: c.tools,
          );
    return Semantics(
      button: true,
      label: p.name,
      child: Material(
        key: Key('packCard-${p.kind.value}-${p.id}'),
        color: context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: context.appColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkillIconTile(icon: packIcon(p.icon), color: scheme.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (p.reviewed) ...[
                            const SizedBox(width: AppSpace.xs),
                            const PackReviewBadge(reviewed: true, compact: true),
                          ],
                        ],
                      ),
                      if (p.summary.isNotEmpty)
                        Text(
                          p.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (contents.isNotEmpty) contents,
                          if (p.author.name.isNotEmpty && p.author.name != 'Casama') l10n.galleryBy(p.author.name),
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(color: muted),
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

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/media_cache.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../library/creation_tile.dart';
import 'projects_screen.dart';

/// Whether a project plans for approval and works by itself (D-113). Servers from before light
/// projects (D-295) don't say, and every project there does.
bool projectIsAutonomous(Project p) => p.autonomous ?? true;

/// The same for a project's detail.
bool projectDetailIsAutonomous(ProjectDetail p) => p.autonomous ?? true;

/// One project on a shelf: a small cover (the newest thing made for it), its name, and how many
/// things it holds. Kept low, so the Library's own grid stays the main thing on a phone.
class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project, required this.onTap});
  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final p = project;
    final count = p.creationsCount ?? 0;
    return Semantics(
      button: true,
      label: '${l10n.creationProjectLabel}, ${p.title}',
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: context.appColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('projectTile-${p.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xs),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                  child: SizedBox.square(
                    dimension: 44,
                    child: _MiniCover(creation: p.latestCreation),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l10n.projectThings(count),
                          // One being worked on needs no word; a waiting or finished one says so.
                          if (p.status != ProjectStatus.active)
                            projectStatusLabel(context, p.status),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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
    );
  }
}

/// A project's small cover: the picture of the newest thing made for it, else that thing's glyph,
/// else a folder. (The Library's drawn covers carry a title, which doesn't fit this small.)
class _MiniCover extends ConsumerWidget {
  const _MiniCover({required this.creation});
  final Creation? creation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final c = creation;
    final glyph = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          c == null
              ? LucideIcons.folderKanban
              : creationIcon(c.kind, label: c.label),
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    if (c == null || !c.hasCover) return glyph;
    final backend = ref.watch(backendProvider);
    return Image(
      image: cachedNetworkImage(
        '${backend.creationCoverUrl(c.id)}?v=${c.version}',
        headers: backend.authHeaders,
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) =>
          sync || frame != null ? child : glyph,
      errorBuilder: (_, _, _) => glyph,
    );
  }
}

/// The Library's Projects shelf (D-295): one card per project that isn't cancelled, the ones being
/// worked on first, scrolling sideways. Nothing at all while the workspace has no projects.
class ProjectShelf extends ConsumerWidget {
  const ProjectShelf({super.key});

  static const _cardWidth = 216.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final projects = (ref.watch(projectsProvider).value ?? const <Project>[])
        .where((p) => p.status != ProjectStatus.cancelled)
        .toList();
    if (projects.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      key: const Key('projectShelf'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.projects,
                key: const Key('libraryHeading-projects'),
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const Key('allProjects'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => context.push('/projects'),
              child: Text(l10n.projectSeeAll),
            ),
          ],
        ),
        SizedBox(
          // The 44-high cover and its padding, with room for larger text.
          height: 20 + 44 * (textScale < 1 ? 1 : textScale),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
            itemBuilder: (context, i) => SizedBox(
              width: _cardWidth,
              child: ProjectTile(
                project: projects[i],
                onTap: () => context.push('/projects/${projects[i].id}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

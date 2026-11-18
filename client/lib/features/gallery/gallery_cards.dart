import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/lucide_names.dart';
import '../bots/template_picker.dart' show personaIcon;
import '../integrations/app_logo.dart';
import '../skills/skill_visuals.dart';
import 'gallery_logic.dart';

/// A kind's plural name, for chips and rows.
String galleryKindLabel(AppLocalizations l10n, String type) => switch (type) {
  'theme' => l10n.galleryThemes,
  'scheme' => l10n.gallerySchemes,
  'wallpaper' => l10n.galleryWallpapers,
  'app' => l10n.galleryKindApps,
  'bot' => l10n.galleryKindBots,
  'routine' => l10n.galleryKindRoutines,
  'plugin' => l10n.galleryKindPlugins,
  'set' => l10n.galleryKindSets,
  _ => l10n.gallerySkills,
};

/// A kind's name for one item.
String galleryKindName(AppLocalizations l10n, String type) => switch (type) {
  'theme' => l10n.galleryTypeTheme,
  'scheme' => l10n.galleryTypeScheme,
  'wallpaper' => l10n.galleryTypeWallpaper,
  'app' => l10n.galleryKindApp,
  'bot' => l10n.galleryKindBot,
  'routine' => l10n.galleryKindRoutine,
  'plugin' => l10n.galleryKindPlugin,
  'set' => l10n.galleryKindSet,
  _ => l10n.galleryTypeSkill,
};

/// A category or tag as a chip label: "life-admin" → "Life admin".
String galleryTagLabel(BuildContext context, String tag) {
  final words = tag.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  return words.isEmpty ? tag : '${words[0].toUpperCase()}${words.substring(1)}';
}

IconData galleryKindIcon(String type) => switch (type) {
  'theme' => LucideIcons.palette,
  'scheme' => LucideIcons.swatchBook,
  'wallpaper' => LucideIcons.image,
  'app' => LucideIcons.blocks,
  'bot' => LucideIcons.bot,
  'routine' => LucideIcons.repeat,
  'plugin' => LucideIcons.puzzle,
  'set' => LucideIcons.package,
  _ => LucideIcons.sparkles,
};

/// The icon tile for an item that isn't a look: an app's logo, a skill's category tile, or the
/// item's own Lucide icon.
class GalleryItemIcon extends StatelessWidget {
  const GalleryItemIcon({super.key, required this.item, this.size = 44});
  final GalleryItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final doc = item.document ?? const <String, Object?>{};
    final category = item.category ?? doc['category'] as String?;
    final iconName = item.icon ?? doc['icon'] as String?;
    if (item.type == 'app') {
      return AppLogo(
        appId: item.id,
        name: item.name,
        color: doc['color'] as String?,
        size: size,
      );
    }
    final icon = switch (item.type) {
      'skill' => skillIcon(icon: iconName, category: category),
      'bot' => personaIcon(iconName),
      _ => lucideByName(iconName) ?? galleryKindIcon(item.type),
    };
    return SkillIconTile(
      icon: icon,
      color: skillCategoryColor(context, category),
      size: size,
    );
  }
}

/// "New" on a card added in the last 30 days.
class GalleryNewBadge extends StatelessWidget {
  const GalleryNewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          context.l10n.galleryNewBadge,
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A card for anything that isn't a look: skills, apps, bots, routines, plugins and sets. Icon,
/// name, one or two lines of what it does, and a quiet line with its kind, category and author.
class GalleryItemCard extends StatelessWidget {
  const GalleryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.note,
    this.now,
    this.showNew = true,
  });
  final GalleryItem item;
  final VoidCallback onTap;

  /// A line in place of the description, such as a pick's note.
  final String? note;

  /// Today, for the New badge (tests pass one).
  final DateTime? now;

  /// False while "New" means nothing (see [galleryNewShown]).
  final bool showNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final category = item.category ?? item.document?['category'] as String?;
    final description = note ?? item.description;
    final fresh = showNew && galleryIsNew(item, now ?? DateTime.now());
    return Semantics(
      button: true,
      label: item.name,
      child: Material(
        key: Key('gallery-${item.type}-${item.id}'),
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
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
                GalleryItemIcon(item: item),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (fresh) ...[
                            const SizedBox(width: AppSpace.xs),
                            const GalleryNewBadge(),
                          ],
                        ],
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.35,
                            fontStyle: note != null ? FontStyle.italic : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        [
                          if (item.type != 'skill')
                            galleryKindName(l10n, item.type)
                          else if (category != null)
                            skillCategoryLabel(context, category),
                          if (item.authorName.isNotEmpty &&
                              item.authorName != 'Casama')
                            l10n.galleryBy(item.authorName),
                          if (item.type == 'skill') item.license,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: muted,
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

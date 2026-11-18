import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/page.dart';
import '../settings/gallery_screen.dart' show showGalleryDetail;
import 'gallery_cards.dart';
import 'gallery_data.dart';
import 'gallery_logic.dart';
import '../../core/link_browser.dart';

/// The items an author made, by their handle (or their name as a slug), and their link.
class GalleryAuthorScreen extends ConsumerWidget {
  const GalleryAuthorScreen({super.key, required this.handle});
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(galleryCatalogProvider);
    final items = [
      for (final i in catalog.value?.items ?? const <GalleryItem>[])
        if (galleryAuthorKey(i) == handle) i,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final first = items.firstOrNull;
    final name = first?.authorName ?? handle;
    final url = items.map((i) => i.authorUrl).nonNulls.firstOrNull;
    final kinds = <String>{for (final i in items) i.type};
    return SubPage(
      title: name,
      maxWidth: kWidePageMaxWidth,
      children: [
        if (catalog.isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpace.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          EmptyState(icon: LucideIcons.userX, message: l10n.galleryAuthorEmpty)
        else ...[
          Text(
            l10n.galleryAuthorCount(items.length),
            key: const Key('galleryAuthorCount'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          if (url != null) ...[
            const SizedBox(height: AppSpace.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('galleryAuthorUrl'),
                onPressed: () => openWebLink(Uri.parse(url)),
                icon: const Icon(LucideIcons.externalLink, size: 16),
                label: Text(Uri.tryParse(url)?.host ?? url),
              ),
            ),
          ],
          for (final kind in galleryKinds)
            if (kinds.contains(kind)) ...[
              SectionHeader(title: galleryKindLabel(l10n, kind)),
              for (final i in items.where((i) => i.type == kind))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: GalleryItemCard(
                    item: i,
                    onTap: () => showGalleryDetail(context, i),
                  ),
                ),
            ],
        ],
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../theme/appearance.dart';
import '../../theme/presets.dart';
import 'gallery_previews.dart';
import '../../core/analytics.dart';

/// The looks in the open gallery (D-184): themes, color schemes and wallpapers, featured first.
/// Appearance and Customize show them next to the built-in ones, so the gallery is one more
/// source of looks rather than another place to go. Items that need something this app can't
/// draw (a newer gallery feature) stay hidden. Loaded once per session; an offline or switched
/// off gallery is an empty list.
final galleryLooksProvider = FutureProvider<List<GalleryItem>>((ref) async {
  final page = await ref.watch(backendProvider).gallery();
  if (!page.available) return const [];
  final looks = [
    for (final item in page.items)
      if (item.supported && item.type != 'skill') item,
  ];
  looks.sort((a, b) {
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return looks;
});

/// Applies a gallery look, fetching its document first when the list didn't carry it.
Future<void> useGalleryLook(WidgetRef ref, GalleryItem item) async {
  final full = item.document == null
      ? await ref.read(backendProvider).galleryItem(item.type, item.id)
      : item;
  await applyGalleryItem(ref, full);
}

/// The id a gallery theme is kept under in the saved themes once it's been used.
String gallerySavedThemeId(GalleryItem item) => 'gallery-${item.id}';

/// Applies a gallery theme, scheme or wallpaper on this device. A theme is also kept with the
/// saved themes, so it stays one tap away when the gallery is offline.
Future<void> applyGalleryItem(WidgetRef ref, GalleryItem item) async {
  final notifier = ref.read(appearanceProvider.notifier);
  final current = ref.read(appearanceProvider);
  final everywhere = current.wallpaper.everywhere;
  switch (item.type) {
    case 'scheme':
      final choice = galleryChoiceOf(item);
      if (choice != null) await notifier.applyGalleryScheme(choice);
    case 'wallpaper':
      final spec = galleryWallpaperOf(item);
      if (spec != null) {
        await notifier.setWallpaper(spec.copyWith(everywhere: everywhere));
      }
    case 'theme':
      final choice = galleryChoiceOf(item);
      final look = GalleryLook.of(item, current);
      final wallpaper = (galleryWallpaperOf(item) ?? current.wallpaper)
          .copyWith(everywhere: everywhere);
      Analytics.feature('gallery_look');
      await notifier.apply(
        schemeId: look.scheme.id,
        gallery: choice != null && choice.id.startsWith('gallery:')
            ? choice
            : null,
        headingFont: look.headingFont,
        bodyFont: look.bodyFont,
        wallpaper: wallpaper,
        // A gallery theme is colorful; it brings effects back after Plain.
        fewerEffects: false,
      );
      await ref
          .read(savedThemesProvider.notifier)
          .add(
            ThemePreset(
              id: gallerySavedThemeId(item),
              name: item.name,
              schemeId: look.scheme.id,
              headingFont: look.headingFont,
              bodyFont: look.bodyFont,
              wallpaper: wallpaper,
            ),
          );
  }
}

/// A new gallery submission on GitHub with [code] filled in.
Uri galleryShareUri(String code) => Uri.https(
  'github.com',
  '/stackwares/casama-gallery/issues/new',
  {'title': 'Share a theme', 'body': '```\n$code\n```\n'},
);

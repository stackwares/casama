import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_api/casama_api.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/smooth_network_image.dart';

/// A photo someone chose in [PhotoPicker].
class PickedPhoto {
  const PickedPhoto({
    required this.url,
    required this.author,
    required this.authorUrl,
  });
  final String url;
  final String author;
  final String authorUrl;
}

/// Wallpaper photos from the server's photo source (Unsplash), searchable, with the
/// photographer's name on each. Choosing one reports the download, as Unsplash asks.
class PhotoPicker extends ConsumerStatefulWidget {
  const PhotoPicker({super.key});

  @override
  ConsumerState<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends ConsumerState<PhotoPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  Future<List<WallpaperPhoto>>? _photos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final photos = ref
        .read(backendProvider)
        .searchWallpapers(query: _search.text);
    // The assignment's value is the future. A block keeps that out of setState's return value.
    setState(() {
      _photos = photos;
    });
  }

  void _choose(WallpaperPhoto p) {
    // Fire and forget: a failed count shouldn't stop someone from using the photo.
    unawaited(
      ref
          .read(backendProvider)
          .trackWallpaperDownload(p.downloadLocation)
          .catchError((_) {}),
    );
    Navigator.pop(
      context,
      PickedPhoto(url: p.url, author: p.author, authorUrl: p.authorUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.browsePhotos, style: context.textTheme.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('photoSearch'),
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchPhotos,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 450), _load);
            },
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: FutureBuilder<List<WallpaperPhoto>>(
              future: _photos,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.photosUnavailable,
                          style: context.textTheme.bodyMedium,
                        ),
                        TextButton(onPressed: _load, child: Text(l10n.retry)),
                      ],
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noPhotos,
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, c) => GridView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: BottomPadding.of(context, minimum: AppSpace.lg)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (c.maxWidth / 160).floor().clamp(2, 5),
                      mainAxisSpacing: AppSpace.xs,
                      crossAxisSpacing: AppSpace.xs,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Material(
                          color: _hex(p.color) ?? scheme.surfaceContainer,
                          child: InkWell(
                            key: Key('photo-${p.id}'),
                            onTap: () => _choose(p),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SmoothNetworkImage(
                                  p.thumbUrl,
                                  placeholderColor: _hex(p.color) ?? scheme.surfaceContainer,
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      14,
                                      8,
                                      6,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black54,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      p.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Text(
              l10n.photosFromUnsplash,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color? _hex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/local_image.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/wallpaper.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'appearance_preview.dart';
import 'photo_picker.dart';

/// Settings → Background: the wallpaper behind every screen, Telegram style. A doodle pattern,
/// soft gradient colors, how strong the pattern is, and whether it shows everywhere.
class BackgroundScreen extends ConsumerWidget {
  const BackgroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final spec = ref.watch(appearanceProvider).wallpaper;
    final notifier = ref.read(appearanceProvider.notifier);
    void set(WallpaperSpec s) => notifier.setWallpaper(s);
    WallpaperTheme preview(WallpaperSpec s) => WallpaperTheme.of(s.copyWith(everywhere: true), scheme);

    return SubPage(
      title: l10n.background,
      children: [
        AppearancePreview(wallpaper: preview(spec), height: 220),
        SectionHeader(title: l10n.backgroundPhoto),
        _PhotoSection(spec: spec, onChanged: set),
        SectionHeader(title: l10n.backgroundPattern),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WallpaperPattern.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
            itemBuilder: (context, i) {
              final p = WallpaperPattern.values[i];
              return _Swatch(
                key: Key('pattern-${p.name}'),
                label: p.label,
                selected: spec.pattern == p,
                onTap: () => set(spec.copyWith(pattern: p, intensity: spec.intensity == 0 ? 0.5 : null)),
                child: Wallpaper(
                  force: true,
                  specOverride: preview(spec.copyWith(pattern: p, intensity: 0.75)),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
        SectionHeader(title: l10n.backgroundColors),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.sm,
          children: [
            for (final c in WallpaperPalette.values)
              _Swatch(
                key: Key('palette-${c.name}'),
                label: c == WallpaperPalette.theme ? l10n.backgroundThemeColors : c.label,
                selected: spec.palette == c,
                width: 76,
                height: 64,
                onTap: () => set(spec.copyWith(palette: c)),
                child: Wallpaper(
                  force: true,
                  specOverride: preview(spec.copyWith(palette: c, pattern: WallpaperPattern.none, clearPhoto: true)),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
        SectionHeader(title: l10n.patternStrength),
        AppCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xxs, AppSpace.sm, AppSpace.xxs),
          child: Row(
            children: [
              Icon(LucideIcons.sparkle, size: 16, color: scheme.onSurfaceVariant),
              Expanded(
                child: Slider(
                  key: const Key('patternStrength'),
                  value: spec.intensity,
                  onChanged: spec.pattern == WallpaperPattern.none ? null : (v) => set(spec.copyWith(intensity: v)),
                ),
              ),
              Icon(LucideIcons.sparkles, size: 22, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        FormSwitch(
          key: const Key('wallpaperEverywhere'),
          icon: LucideIcons.layers,
          title: l10n.wallpaperEverywhere,
          subtitle: l10n.wallpaperEverywhereHelp,
          value: spec.everywhere,
          onChanged: (v) => set(spec.copyWith(everywhere: v)),
        ),
        const SizedBox(height: AppSpace.md),
        Center(
          child: TextButton.icon(
            onPressed: spec == const WallpaperSpec() ? null : () => set(const WallpaperSpec()),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: Text(l10n.resetBackground),
          ),
        ),
      ],
    );
  }
}

/// A choice shown as a little picture with its name; the chosen one gets an accent ring.
class _Swatch extends StatelessWidget {
  const _Swatch({super.key, required this.label, required this.selected, required this.onTap, required this.child, this.width = 84, this.height = 84});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.fast),
                width: width,
                height: height,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? scheme.primary : context.appColors.hairline, width: selected ? 2.5 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      if (selected)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                            child: Icon(LucideIcons.check, size: 12, color: scheme.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Your own photo, or one from the server's photo source, under the pattern; with blur and dim.
class _PhotoSection extends ConsumerWidget {
  const _PhotoSection({required this.spec, required this.onChanged});
  final WallpaperSpec spec;
  final void Function(WallpaperSpec) onChanged;

  Future<void> _pickOwn(BuildContext context) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 85);
      if (x == null) return;
      final ext = x.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final stored = await storeLocalImage(await x.readAsBytes(), ext: ext);
      onChanged(spec.copyWith(photo: stored).copyWithCredit(null, null));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _browse(BuildContext context, WidgetRef ref) async {
    final photo = await showAdaptiveSheet<PickedPhoto>(context: context, heightFactor: 0.9, builder: (_) => const PhotoPicker());
    if (photo == null) return;
    onChanged(spec.copyWith(photo: photo.url).copyWithCredit(photo.author, photo.authorUrl));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final remote = ref.watch(backendProvider).wallpapersEnabled;
    final photo = spec.photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            OutlinedButton.icon(
              key: const Key('pickPhoto'),
              onPressed: () => _pickOwn(context),
              icon: const Icon(LucideIcons.imagePlus, size: 18),
              label: Text(l10n.yourPhoto),
            ),
            if (remote)
              OutlinedButton.icon(
                key: const Key('browsePhotos'),
                onPressed: () => _browse(context, ref),
                icon: const Icon(LucideIcons.images, size: 18),
                label: Text(l10n.browsePhotos),
              ),
            if (photo != null)
              TextButton.icon(
                key: const Key('removePhoto'),
                onPressed: () => onChanged(spec.copyWith(clearPhoto: true)),
                icon: const Icon(LucideIcons.x, size: 18),
                label: Text(l10n.removePhoto),
              ),
          ],
        ),
        if (photo == null) ...[
          const SizedBox(height: AppSpace.xs),
          FormNote(l10n.photoHelp),
        ] else ...[
          if ((spec.photoCredit ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs, left: AppSpace.xxs),
              child: InkWell(
                onTap: spec.photoCreditUrl == null ? null : () => launchUrl(Uri.parse(spec.photoCreditUrl!), mode: LaunchMode.externalApplication),
                child: Text(
                  l10n.photoBy(spec.photoCredit!),
                  style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, decoration: TextDecoration.underline),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          AppCard(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xxs, AppSpace.sm, AppSpace.xxs),
            child: Column(
              children: [
                for (final (label, key, value, apply) in [
                  (l10n.photoBlur, 'photoBlur', spec.photoBlur, (double v) => spec.copyWith(photoBlur: v)),
                  (l10n.photoDim, 'photoDim', spec.photoDim, (double v) => spec.copyWith(photoDim: v)),
                ])
                  Row(
                    children: [
                      SizedBox(width: 56, child: Text(label, style: context.textTheme.bodyMedium)),
                      Expanded(child: Slider(key: Key(key), value: value, onChanged: (v) => onChanged(apply(v)))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

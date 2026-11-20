import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../core/remote_content.dart';
import '../../ui/lucide_names.dart';
import '../../ui/painted_cover.dart';

/// The empty Library: the shelf as it will look, filled with things to ask for. Each cover is drawn
/// like a real creation's (a tint, a glyph, a title) and opens quick ask with the request typed in;
/// the last row asks for anything else.
class LibraryStarters extends ConsumerWidget {
  const LibraryStarters({super.key, required this.onPick});

  /// The request to type in; empty for "something else".
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final builtIn = [
      (
        'game',
        LucideIcons.gamepad2,
        265.0,
        l10n.libraryStarterGame,
        l10n.libraryStarterGamePrompt,
      ),
      (
        'logo',
        LucideIcons.image,
        330.0,
        l10n.libraryStarterLogo,
        l10n.libraryStarterLogoPrompt,
      ),
      (
        'site',
        LucideIcons.globe,
        210.0,
        l10n.libraryStarterSite,
        l10n.libraryStarterSitePrompt,
      ),
      (
        'video',
        LucideIcons.film,
        15.0,
        l10n.libraryStarterVideo,
        l10n.libraryStarterVideoPrompt,
      ),
      (
        'card',
        LucideIcons.partyPopper,
        40.0,
        l10n.libraryStarterCard,
        l10n.libraryStarterCardPrompt,
      ),
      (
        'report',
        LucideIcons.fileText,
        150.0,
        l10n.libraryStarterReport,
        l10n.libraryStarterReportPrompt,
      ),
    ];
    // The gallery's starters when the server sends them (D-372), in English only; a cover keeps
    // its built-in icon when the app doesn't ship the one named.
    final fromGallery = galleryTextFits(context)
        ? ref.watch(galleryListsProvider).value?.starters?.library_
        : null;
    final starters = fromGallery == null || fromGallery.isEmpty
        ? builtIn
        : [
            for (final s in fromGallery)
              (
                s.id,
                lucideByName(s.icon) ??
                    builtIn.where((b) => b.$1 == s.id).firstOrNull?.$2 ??
                    LucideIcons.sparkles,
                s.hue.toDouble(),
                s.label,
                s.prompt,
              ),
          ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.libraryEmptyTitle,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.libraryEmptyBody,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 3 : 2;
                const gap = AppSpace.sm;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (i, (key, icon, hue, label, prompt)) in starters.indexed)
                      SizedBox(
                        width: width,
                        child: _StarterCover(
                          key: Key('libraryStarter-$key'),
                          icon: icon,
                          hue: hue,
                          label: label,
                          art: paintedAsset('library-$key'),
                          onTap: () => onPick(prompt),
                        ),
                      ).appListItemEntrance(i),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpace.sm),
            Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('libraryStarter-else'),
                onTap: () {
                  HapticsHelper.selection();
                  onPick('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          l10n.libraryStarterElse,
                          style: text.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.arrowUp,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterCover extends StatelessWidget {
  const _StarterCover({
    super.key,
    required this.icon,
    required this.hue,
    required this.label,
    required this.onTap,
    this.art,
  });
  final IconData icon;
  final double hue;
  final String label;
  final VoidCallback onTap;

  /// A painted picture (visuals/round-10) for the built-in starters; others keep the drawn tint.
  final String? art;

  @override
  Widget build(BuildContext context) {
    if (art != null) return _painted(context, art!);
    final dark = context.isDark;
    // The drawn cover's tints (creation_tile.dart), so the shelf looks the way it will when full.
    final top = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.30 : 0.82).toColor();
    final bottom = HSLColor.fromAHSL(
      1,
      (hue + 28) % 360,
      0.50,
      dark ? 0.22 : 0.70,
    ).toColor();
    final ink = dark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.72);
    return Semantics(
      button: true,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Material(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [top, bottom],
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticsHelper.selection();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 24, color: ink),
                        const Spacer(),
                        Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: ink.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The painted cover: the picture fills the tile, and its label sits on a soft dark foot.
  Widget _painted(BuildContext context, String asset) {
    return Semantics(
      button: true,
      label: label,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Material(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PaintedArt(seed: label, asset: asset, icon: icon),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1],
                    colors: [Color(0x00000000), Color(0x8C000000)],
                  ),
                ),
              ),
              Positioned(
                top: AppSpace.xs,
                right: AppSpace.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: Color(0xDD1C1C1E),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpace.sm,
                right: AppSpace.sm,
                bottom: AppSpace.sm,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    HapticsHelper.selection();
                    onTap();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

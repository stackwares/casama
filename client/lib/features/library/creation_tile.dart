import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/media_cache.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// The glyph for a kind of creation.
IconData creationIcon(CreationKind kind, {String? label}) => switch (kind) {
  CreationKind.page =>
    (label ?? '').toLowerCase() == 'game'
        ? LucideIcons.gamepad2
        : LucideIcons.globe,
  CreationKind.image => LucideIcons.image,
  CreationKind.video => LucideIcons.film,
  CreationKind.audio => LucideIcons.audioLines,
  CreationKind.document => LucideIcons.fileText,
  CreationKind.file => LucideIcons.file,
};

/// The word on a tile's pill: the bot's own label (Site, Game, Report…) or the kind.
String creationKindLabel(AppLocalizations l10n, Creation c) {
  final label = c.label?.trim();
  if (label != null && label.isNotEmpty) return label;
  return creationKindName(l10n, c.kind);
}

String creationKindName(AppLocalizations l10n, CreationKind kind) =>
    switch (kind) {
      CreationKind.page => l10n.creationKindPage,
      CreationKind.image => l10n.creationKindImage,
      CreationKind.video => l10n.creationKindVideo,
      CreationKind.audio => l10n.creationKindAudio,
      CreationKind.document => l10n.creationKindDocument,
      CreationKind.file => l10n.creationKindFile,
    };

/// The chip that filters to a kind.
String creationFilterName(AppLocalizations l10n, CreationKind kind) =>
    switch (kind) {
      CreationKind.page => l10n.libraryFilterPages,
      CreationKind.image => l10n.libraryFilterImages,
      CreationKind.video => l10n.libraryFilterVideos,
      CreationKind.audio => l10n.libraryFilterAudio,
      CreationKind.document => l10n.libraryFilterDocuments,
      CreationKind.file => l10n.libraryFilterFiles,
    };

/// A creation's picture: its cover from the server when it has one (a picture is its own cover, a
/// video a frame), else a drawn one. A cover that fails to load falls back to the drawn one.
class CreationCover extends ConsumerWidget {
  const CreationCover({super.key, required this.creation, this.big = false});
  final Creation creation;

  /// The detail view's preview: a larger glyph and title.
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawn = DrawnCover(creation: creation, big: big);
    if (!creation.hasCover) return drawn;
    final backend = ref.watch(backendProvider);
    // The version in the address, so a changed creation doesn't show a stale cover.
    final url =
        '${backend.creationCoverUrl(creation.id)}?v=${creation.version}';
    return Image(
      key: Key('creationCoverImage-${creation.id}'),
      image: cachedNetworkImage(url, headers: backend.authHeaders),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) =>
          sync || frame != null ? child : drawn,
      errorBuilder: (_, _, _) => drawn,
    );
  }
}

/// A cover for anything without a picture yet (LIBRARY-PLAN §7): a tint picked from the id, the
/// kind's glyph and the title, so tiles stay apart at a glance.
class DrawnCover extends StatelessWidget {
  const DrawnCover({super.key, required this.creation, this.big = false});
  final Creation creation;
  final bool big;

  static const _hues = [210.0, 265.0, 330.0, 15.0, 40.0, 150.0, 185.0, 290.0];

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final hue =
        _hues[creation.id.codeUnits.fold<int>(
              0,
              (a, b) => (a * 31 + b) & 0x7fffffff,
            ) %
            _hues.length];
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
    return DecoratedBox(
      key: Key('drawnCover-${creation.id}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(big ? AppSpace.lg : AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              creationIcon(creation.kind, label: creation.label),
              size: big ? 40 : 22,
              color: ink,
            ),
            const Spacer(),
            Text(
              creation.title,
              maxLines: big ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (big
                          ? context.textTheme.headlineSmall
                          : context.textTheme.labelLarge)
                      ?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One thing in the Library grid: a 4:3 cover, the title, the bot and when, and a kind pill.
class CreationTile extends StatelessWidget {
  const CreationTile({
    super.key,
    required this.creation,
    required this.onTap,
    this.selected = false,
  });
  final Creation creation;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final c = creation;
    final duration = c.durationS == null
        ? null
        : Duration(milliseconds: (c.durationS! * 1000).round());
    String clock(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      button: true,
      label: '${creationKindLabel(l10n, c)}, ${c.title}',
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(
            color: selected ? scheme.primary : context.appColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('creation-${c.id}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CreationCover(creation: c),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _Pill(
                        icon: creationIcon(c.kind, label: c.label),
                        text: duration == null
                            ? creationKindLabel(l10n, c)
                            : '${creationKindLabel(l10n, c)} · ${clock(duration)}',
                      ),
                    ),
                    if (c.pinned)
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: _Pill(icon: LucideIcons.pin),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.xs,
                  AppSpace.sm,
                  AppSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if ((c.botName ?? '').isNotEmpty) c.botName!,
                        relativeTime(c.createdAt, context),
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, this.text});
  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: text == null ? 6 : 8,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            if (text != null) ...[
              const SizedBox(width: 4),
              Text(
                text!,
                style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

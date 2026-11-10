import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/wallpaper.dart';
import '../../ui/bot_avatar.dart';

/// A small chat drawn over a wallpaper: how a scheme or background will look before you leave
/// the page. [wallpaper] previews a background choice; without it the applied one is shown.
class AppearancePreview extends StatelessWidget {
  const AppearancePreview({super.key, this.wallpaper, this.height = 196, this.compact = false});
  final WallpaperTheme? wallpaper;
  final double height;

  /// Tile-sized: bubbles only, no names.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final dark = context.isDark;
    final radius = BorderRadius.circular(compact ? 14 : 22);
    final bubble = TextStyle(fontSize: compact ? 9 : 14, height: 1.3, color: scheme.onSurface);
    Widget bot(String text) => Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 12, vertical: compact ? 5 : 9),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(compact ? 3 : 6),
          topRight: Radius.circular(compact ? 10 : 18),
          bottomLeft: Radius.circular(compact ? 10 : 18),
          bottomRight: Radius.circular(compact ? 10 : 18),
        ),
      ),
      child: Text(text, style: bubble),
    );
    Widget me(String text) => Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 12, vertical: compact ? 5 : 9),
      decoration: BoxDecoration(
        color: Color.alphaBlend(scheme.primary.withValues(alpha: dark ? 0.32 : 0.18), dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(compact ? 10 : 18),
          topRight: Radius.circular(compact ? 10 : 18),
          bottomLeft: Radius.circular(compact ? 10 : 18),
          bottomRight: Radius.circular(compact ? 3 : 6),
        ),
      ),
      child: Text(text, style: bubble),
    );
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Wallpaper(
          force: true,
          specOverride: wallpaper,
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(alignment: Alignment.centerRight, child: me(compact ? l10n.previewHi : l10n.previewAsk)),
                SizedBox(height: compact ? 5 : 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!compact) ...[const BotAvatar(name: 'Kasama', size: 26), const SizedBox(width: 8)],
                    Flexible(child: bot(compact ? l10n.previewOnIt : l10n.previewDone)),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.appColors.hairline),
                          ),
                          child: Text(l10n.previewMessage, style: bubble.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                        child: Icon(LucideIcons.arrowUp, size: 18, color: scheme.onPrimary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

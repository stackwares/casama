import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics.dart';
import '../../../core/link_browser.dart';
import '../../../core/providers.dart';
import '../../../core/remote_config.dart';
import '../../../core/remote_content.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/app_card.dart';

/// The intro film (D-390) on YouTube. The addresses are remote links (D-372), so a new cut is set
/// in Admin → App settings (`intro_video`, `intro_video_vertical`) without an app release; these
/// are the fallbacks.
const kIntroVideoUrl = 'https://www.youtube.com/watch?v=cype-154_p0';
const kIntroVideoVerticalUrl = 'https://www.youtube.com/shorts/-WthSEA26ag';

/// The film for this screen: the 9:16 cut on a phone held upright, 16:9 everywhere else (the same
/// rule as casama.ai's film dialog).
Uri introVideoUri(Size screen) {
  final upright = screen.height > screen.width && screen.width <= 600;
  return upright
      ? remoteUri(
          'intro_video_vertical',
          remoteLink('intro_video', kIntroVideoVerticalUrl),
        )
      : remoteUri('intro_video', kIntroVideoUrl);
}

/// Opens the film in the browser picked in Settings (the in-app browser tab, never a WebView).
Future<void> openIntroVideo(BuildContext context, String surface) {
  Analytics.log('intro_video_opened', {'surface': surface});
  return openWebLink(introVideoUri(MediaQuery.sizeOf(context)));
}

/// One optional row in a new person's empty chats: "See how Casama works". It goes once they've
/// watched it, closed it, or had a few chats with this bot. `intro_video` in remote flags turns
/// it off everywhere.
class IntroVideoTile extends ConsumerStatefulWidget {
  const IntroVideoTile({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<IntroVideoTile> createState() => _IntroVideoTileState();
}

class _IntroVideoTileState extends ConsumerState<IntroVideoTile> {
  static const _prefKey = 'introVideo.done';

  /// Unknown until the saved choice is read, so the row doesn't flash in and out.
  bool? _done;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) {
          if (mounted) setState(() => _done = p.getBool(_prefKey) ?? false);
        })
        .catchError((_) {
          if (mounted) setState(() => _done = false);
        });
  }

  Future<void> _finish() async {
    setState(() => _done = true);
    try {
      await (await SharedPreferences.getInstance()).setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_done != false || !remoteFlag(ref, 'intro_video', fallback: true))
      return const SizedBox.shrink();
    final chats = ref.watch(conversationsProvider(widget.botId)).value?.length;
    if (chats == null || chats >= 3) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        key: const Key('introVideo'),
        onTap: () {
          openIntroVideo(context, 'empty_chat');
          _finish();
        },
        radius: AppRadius.tile,
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.play, size: 16, color: scheme.onPrimary),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.introVideoTitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  Text(
                    l10n.introVideoSubtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('dismissIntroVideo'),
              tooltip: l10n.dismiss,
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Analytics.log('intro_video_dismissed', const {});
                _finish();
              },
            ),
          ],
        ),
      ),
    );
  }
}

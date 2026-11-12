import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/backend.dart';
import '../../../core/media_cache.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'attachment_view.dart';
import 'chat_picture.dart';
import 'media_kind.dart';

/// An image a bot wrote into its reply (`![alt](src)`): web pictures and pictures on the bot's
/// computer (`media/cat.png`, `workspace/chart.png`) show like attached ones, bounded and tappable;
/// one that can't load becomes a small chip with its description.
class ChatMarkdownImage extends StatelessWidget {
  const ChatMarkdownImage({super.key, required this.src, this.alt = ''});
  final String src;
  final String alt;

  @override
  Widget build(BuildContext context) {
    final lower = src.toLowerCase();
    final name = Uri.tryParse(src)?.pathSegments.lastOrNull ?? src;
    final kind = mediaKindOf(name);
    Widget chip(BuildContext context) =>
        _BrokenImageChip(alt: alt.isNotEmpty ? alt : name);
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (kind == MediaKind.svg) {
        return ClipRRect(
          borderRadius: AppRadius.tileAll,
          child: ColoredBox(
            color: skeletonColors(context).bone,
            child: SvgPicture.network(
              src,
              width: kChatImageMaxWidth,
              height: kChatImageMaxWidth * 0.75,
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) => chip(context),
            ),
          ),
        );
      }
      return ChatPicture(
        kind: kind == MediaKind.gif ? MediaKind.gif : MediaKind.image,
        url: src,
        semanticLabel: alt,
        fallback: chip,
        onTap: () => showImageViewer(context, cachedNetworkImage(src)),
      );
    }
    final path = computerPathFromLink(src);
    final computerId = FileLinkScope.maybeOf(context)?.computerId;
    if (path == null || computerId == null || !isPicture(kind)) {
      return chip(context);
    }
    final ref = AttachmentRef(
      path: path,
      name: name,
      mimeType: mimeFor(name),
      size: 0,
    );
    return PictureAttachment(
      attachment: ref,
      computerId: computerId,
      onTap: () => openChatFile(context, path),
    );
  }
}

class _BrokenImageChip extends StatelessWidget {
  const _BrokenImageChip({required this.alt});
  final String alt;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      key: const Key('markdownImageChip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.rowAll,
        border: Border.all(color: context.appColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.imageOff, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              alt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A picture full screen on black, pinch to zoom; tap the close button or press back to leave.
Future<void> showImageViewer(BuildContext context, ImageProvider image) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 6,
                  child: Center(
                    child: Image(
                      image: image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, _) => Text(
                        context.l10n.imageCouldNotLoad,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

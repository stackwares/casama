import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/backend.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import '../../pages/pages_screen.dart';
import 'chat_audio.dart';
import 'chat_pdf.dart';
import 'chat_picture.dart';
import 'chat_video.dart';
import 'media_kind.dart';

/// One file in a chat, shown the way its kind reads best: pictures at their own shape, videos and
/// sounds as players, PDFs with their first page, and everything else as a file card. A tap opens
/// the full preview. Chat media (`media:<id>`, D-205) needs no computer; computer files need the
/// chat's [FileLinkScope] computer to show more than a card.
class AttachmentView extends ConsumerWidget {
  const AttachmentView({super.key, required this.attachment});
  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = attachment;
    if (a.isPage) return PageCard(attachment: a);
    final computerId = FileLinkScope.maybeOf(context)?.computerId;
    final path = a.isChatMedia
        ? a.path
        : (computerPathFromLink(a.path) ?? a.path);
    final canLoad = a.isChatMedia || computerId != null;
    void open() =>
        openChatFile(context, path, name: a.isChatMedia ? a.name : null);
    final kind = attachmentKind(a);
    if (canLoad) {
      switch (kind) {
        case MediaKind.image || MediaKind.gif || MediaKind.svg:
          return PictureAttachment(
            attachment: a,
            computerId: computerId,
            onTap: open,
          );
        case MediaKind.video:
          return ChatVideo(attachment: a, computerId: computerId);
        case MediaKind.audio:
          return ChatAudio(attachment: a, computerId: computerId);
        case MediaKind.pdf:
          return ChatPdfCard(
            attachment: a,
            computerId: computerId,
            onTap: open,
          );
        case MediaKind.office || MediaKind.other:
          break;
      }
    }
    return FileCard(attachment: a, onTap: open);
  }
}

/// A picture attachment: loads its bytes (computer or chat media) into a [ChatPicture].
class PictureAttachment extends ConsumerWidget {
  const PictureAttachment({
    super.key,
    required this.attachment,
    required this.computerId,
    required this.onTap,
    this.fit,
  });
  final AttachmentRef attachment;
  final String? computerId;
  final VoidCallback onTap;
  final Size? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = attachment;
    final path = a.isChatMedia
        ? a.path
        : (computerPathFromLink(a.path) ?? a.path);
    final data = ref.watch(computerFileProvider((computerId ?? '', path)));
    return Tooltip(
      message: attachmentLabel(context.l10n, a),
      child: ChatPicture(
        kind: attachmentKind(a),
        bytes: data.value,
        width: a.width,
        height: a.height,
        fit: fit,
        onTap: onTap,
        tapKey: attachmentKey(a.path),
        semanticLabel: attachmentLabel(context.l10n, a),
        fallback: data.hasError
            ? (_) => FileCard(attachment: a, onTap: onTap)
            : null,
      ),
    );
  }
}

/// A file as a card: its type icon, name and size.
class FileCard extends StatelessWidget {
  const FileCard({super.key, required this.attachment, required this.onTap});
  final AttachmentRef attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rowAll,
        side: BorderSide(color: context.appColors.hairline),
      ),
      child: InkWell(
        key: attachmentKey(attachment.path),
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: AppRadius.rowAll),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                alignment: Alignment.center,
                child: Icon(
                  fileIconFor(attachment.name),
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachmentLabel(context.l10n, attachment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        _typeLabel(attachment.name),
                        if (attachment.size > 0)
                          formatBytes(attachment.size, context.l10n.localeName),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: context.textTheme.labelSmall?.copyWith(
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

/// A page the bot published (`page:<id>`): its title, and a tap opens it in the browser through a
/// single-use view link, the same way Pages does.
class PageCard extends ConsumerWidget {
  const PageCard({super.key, required this.attachment});
  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final title = attachment.name.trim().isEmpty ? context.l10n.pages : attachment.name.trim();
    Future<void> open() async {
      final url = await runGuarded(context, () => ref.read(backendProvider).pageViewLink(attachment.pageId!));
      if (url != null) await ref.read(pageOpenerProvider)(Uri.parse(url));
    }

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rowAll,
        side: BorderSide(color: context.appColors.hairline),
      ),
      child: InkWell(
        key: Key('pageCard-${attachment.pageId}'),
        onTap: open,
        customBorder: RoundedRectangleBorder(borderRadius: AppRadius.rowAll),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.globe, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: AppSpace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      context.l10n.pageCardOpen,
                      style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(LucideIcons.externalLink, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _typeLabel(String name) =>
    name.contains('.') ? name.split('.').last.toUpperCase() : '';

/// A message's files together: one picture at its own shape, several in a tidy two-column grid
/// (the fourth shows "+N" when there are more), then players and cards.
class MediaGroup extends StatelessWidget {
  const MediaGroup({
    super.key,
    required this.files,
    this.alignment = WrapAlignment.start,
  });
  final List<AttachmentRef> files;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final computerId = FileLinkScope.maybeOf(context)?.computerId;
    bool showsAsPicture(AttachmentRef a) =>
        isPicture(attachmentKind(a)) && (a.isChatMedia || computerId != null);
    final pictures = files.where(showsAsPicture).toList();
    final others = files.where((a) => !showsAsPicture(a)).toList();
    final end = alignment == WrapAlignment.end;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.xs,
      children: [
        if (pictures.length == 1)
          AttachmentView(attachment: pictures.single)
        else if (pictures.length > 1)
          _PictureGrid(pictures: pictures, computerId: computerId),
        if (others.isNotEmpty)
          Wrap(
            alignment: alignment,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [for (final a in others) AttachmentView(attachment: a)],
          ),
      ],
    );
  }
}

class _PictureGrid extends StatelessWidget {
  const _PictureGrid({required this.pictures, required this.computerId});
  final List<AttachmentRef> pictures;
  final String? computerId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 4.0;
      final width = math.min(kChatImageMaxWidth + 60, constraints.maxWidth);
      final side = (width - gap) / 2;
      final shown = pictures.take(4).toList();
      final more = pictures.length - shown.length;
      return SizedBox(
        width: width,
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < shown.length; i++)
              Stack(
                children: [
                  PictureAttachment(
                    attachment: shown[i],
                    computerId: computerId,
                    fit: Size.square(side),
                    onTap: () => openChatFile(
                      context,
                      shown[i].isChatMedia
                          ? shown[i].path
                          : (computerPathFromLink(shown[i].path) ??
                                shown[i].path),
                      name: shown[i].isChatMedia ? shown[i].name : null,
                    ),
                  ),
                  if (i == 3 && more > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: AppRadius.tileAll,
                          ),
                          child: Center(
                            child: Text(
                              '+$more',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
